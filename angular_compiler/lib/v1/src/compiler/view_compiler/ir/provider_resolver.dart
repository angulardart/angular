import '../../compile_metadata.dart';
import '../../i18n/message.dart';
import '../../output/output_ast.dart' as o;
import '../../template_ast.dart';
import '../../view_compiler/compile_element.dart';
import '../../view_compiler/view_compiler_utils.dart';
import 'provider_source.dart';

/// Resolves providers for a compiled template element.
///
/// Users may configure multiple providers with the same token on a given
/// element, as well as configure tokens to act as an alias to another existing
/// provider. It's the [ProviderResolver]'s responsibility given such a
/// configuration to reconcile overridden providers and collect aliases.
class ProviderResolver {
  /// The element hosting this resolver.
  final ProviderResolverHost _host;

  /// The resolver of [_host]'s parent.
  ///
  /// This may be used to resolve tokens that aren't provided by this resolver.
  final ProviderResolver? _parent;

  /// Maps from a provider token to expression that will return instance
  /// at runtime. Builtin(s) are populated eagerly, ProviderAst based
  /// instances are added on demand.
  final _instances = CompileTokenMap<ProviderSource>();

  /// We track which providers are just 'useExisting' for another provider on
  /// this component. This way, we can detect when we don't need to generate
  /// a getter for them.
  final _aliases = CompileTokenMap<List<CompileTokenMetadata>>();
  final _aliasedProviders = CompileTokenMap<CompileTokenMetadata>();
  final _resolvedProviders = CompileTokenMap<ProviderAst>();

  ProviderResolver(this._host, this._parent);

  bool containsLocalProvider(CompileTokenMetadata token) =>
      _instances.containsKey(token);

  bool isAliasedProvider(CompileTokenMetadata token) =>
      _aliasedProviders.containsKey(token);

  List<CompileTokenMetadata>? getAliases(CompileTokenMetadata providerToken) =>
      _aliases.get(providerToken);

  /// Adds a builtin local provider for a template node.
  void add(CompileTokenMetadata token, o.Expression providerValue) {
    _instances.add(token, BuiltInSource(token, providerValue));
  }

  ProviderSource? get(CompileTokenMetadata token) => _instances.get(token);

  /// Given a list of directives (and component itself), adds providers for
  /// each directive at this node. Code generators that want to build
  /// instances can handle the createProviderInstance callback on the
  /// host interface.
  void addDirectiveProviders(
    final List<ProviderAst> providerList,
    final List<CompileDirectiveMetadata> directives,
  ) {
    // Create a lookup map from token to provider.
    for (var provider in providerList) {
      _resolvedProviders.add(provider.token, provider);
    }
    // Create all the provider instances, some in the view constructor (eager),
    // some as getters (eager=false). We rely on the fact that they are
    // already sorted topologically.
    for (var resolvedProvider in providerList) {
      // One or more(multi) sources when built will return provider value
      // expressions.
      var providerSources = <ProviderSource>[];
      var isLocalAlias = false;
      CompileDirectiveMetadata? directiveMetadata;
      for (var provider in resolvedProvider.providers) {
        ProviderSource providerSource;
        if (provider.useExisting != null) {
          // If this provider is just an alias for another provider on this
          // component, we don't need to generate a getter.
          if (_instances.containsKey(provider.useExisting!) &&
              !resolvedProvider.multiProvider) {
            isLocalAlias = true;
            break;
          }
          // Given the token and visibility defined by providerType,
          // get value based on existing expression mapped to token.
          providerSource = _getDependency(
              CompileDiDependencyMetadata(token: provider.useExisting));
          directiveMetadata = null;
        } else if (provider.useFactory != null) {
          providerSource =
              _addFactoryProvider(provider, resolvedProvider.providerType);
        } else if (provider.useClass != null) {
          var classType = provider.useClass!.identifier;
          providerSource = _addClassProvider(
            provider,
            resolvedProvider.providerType,
          );
          // Check if class is a directive and keep track of directiveMetadata
          // for the directive so we can determine if the provider has
          // an associated change detector class.
          for (var dir in directives) {
            if (dir.identifier == classType) {
              directiveMetadata = dir;
              break;
            }
          }
        } else {
          providerSource = ExpressionProviderSource(
              provider.token!, convertValueToOutputAst(provider.useValue));
        }
        providerSources.add(providerSource);
      }
      if (isLocalAlias) {
        // This provider is just an alias for an existing field/instance
        // on the same view class, so just add the existing reference for this
        // token.
        var provider = resolvedProvider.providers.single;
        var alias = provider.useExisting!;
        if (_aliasedProviders.containsKey(alias)) {
          alias = _aliasedProviders.get(alias)!;
        }
        if (!_aliases.containsKey(alias)) {
          _aliases.add(alias, <CompileTokenMetadata>[]);
        }
        _aliases.get(alias)!.add(provider.token!);
        _aliasedProviders.add(resolvedProvider.token, alias);
        _instances.add(resolvedProvider.token, _instances.get(alias)!);
      } else {
        var token = resolvedProvider.token;
        _instances.add(
            token,
            _host.createProviderInstance(resolvedProvider, directiveMetadata,
                providerSources, _instances.length));
      }
    }
  }

  ProviderSource _addFactoryProvider(
      CompileProviderMetadata provider, ProviderAstType providerType) {
    var parameters = <ProviderSource>[];
    for (var paramDep in provider.deps ?? provider.useFactory!.diDeps) {
      parameters.add(_getDependency(paramDep!));
    }
    return FactoryProviderSource(
        provider.token!, provider.useFactory, parameters);
  }

  ProviderSource _addClassProvider(
    CompileProviderMetadata provider,
    ProviderAstType providerType, {
    List<o.OutputType> typeArguments = const [],
  }) {
    var paramDeps = provider.deps ?? provider.useClass!.diDeps;
    // Resolve constructor parameters for class.
    var parameters = <ProviderSource>[];
    for (var paramDep in paramDeps) {
      parameters.add(_getDependency(paramDep!));
    }
    return ClassProviderSource(
      provider.token!,
      provider.useClass,
      parameters,
      typeArguments: typeArguments,
    );
  }

  ProviderSource? _getLocalDependency(CompileTokenMetadata? token) {
    return token != null ? _instances.get(token) : null;
  }

  ProviderSource _getDependency(CompileDiDependencyMetadata dep) {
    ProviderResolver? currProviders = this;
    ProviderSource? result;
    if (dep.isValue) {
      final value = dep.value;
      // This is a bit of a hack, but it's much simpler than refactoring the
      // entire compiler to expect `CompileDiDependencyMetadata.value` already
      // be an `o.Expression` (and it's already dynamic).
      if (value is I18nMessage) {
        // Value is an injected `@i18n:` attribute value.
        final message = _host.createI18nMessage(value);
        result = ExpressionProviderSource(dep.token, message);
      } else {
        // Value is a literal primitive, such as an injected attribute value.
        result = ExpressionProviderSource(dep.token, o.literal(dep.value));
      }
    }
    if (result == null && !dep.isSkipSelf) {
      result = _getLocalDependency(dep.token);
    }
    // check parent elements
    while (result == null && currProviders!._parent!._parent != null) {
      currProviders = currProviders._parent;
      result = currProviders!._getLocalDependency(dep.token);
    }
    // Ask host to build a ProviderSource that injects the instance
    // dynamically through injectorGet call.
    return _host.createDynamicInjectionSource(
      currProviders,
      result,
      dep.token,
      dep.isOptional,
    );
  }
}

/// Interface to be implemented by [ProviderResolver] users.
abstract class ProviderResolverHost {
  /// Creates an eager instance for a provider and returns reference to source.
  ProviderSource createProviderInstance(
      ProviderAst resolvedProvider,
      CompileDirectiveMetadata? directiveMetadata,
      List<ProviderSource> providerValueExpressions,
      int uniqueId);

  /// Creates ProviderSource to call injectorGet on parent view that contains
  /// source NodeProviders.
  ProviderSource createDynamicInjectionSource(ProviderResolver? source,
      ProviderSource? value, CompileTokenMetadata? token, bool optional);

  /// Creates an expression that returns the internationalized [message].
  o.Expression createI18nMessage(I18nMessage message);
}

class BuiltInSource extends ProviderSource {
  final o.Expression _value;

  BuiltInSource(CompileTokenMetadata token, this._value) : super(token);

  @override
  o.Expression build() => _value;
}

/// A provider source for arbitrary expressions.
///
/// This is used to provide simple literal values and locally available
/// expressions.
class ExpressionProviderSource extends ProviderSource {
  final o.Expression _value;
  final o.Expression? _changeDetectorRef;

  ExpressionProviderSource(
    CompileTokenMetadata? token,
    this._value, {
    o.Expression? changeDetectorRef,
  })  : _changeDetectorRef = changeDetectorRef,
        super(token);

  @override
  o.Expression build() => _value;

  @override
  o.Expression? buildChangeDetectorRef() => _changeDetectorRef;
}

bool _hasDynamicDependencies(Iterable<ProviderSource> sources) {
  for (final source in sources) {
    if (source.hasDynamicDependencies) {
      return true;
    }
  }
  return false;
}

class FactoryProviderSource extends ProviderSource {
  final CompileFactoryMetadata? _factory;
  final List<ProviderSource> _parameters;

  FactoryProviderSource(
      CompileTokenMetadata token, this._factory, this._parameters)
      : super(token);

  @override
  o.Expression build() {
    var paramExpressions = <o.Expression>[];
    for (var s in _parameters) {
      paramExpressions.add(s.build());
    }
    final create = o.importExpr(_factory!).callFn(paramExpressions);
    if (hasDynamicDependencies) {
      return debugInjectorWrap(createDiTokenExpression(token!), create);
    }
    return create;
  }

  @override
  bool get hasDynamicDependencies => _hasDynamicDependencies(_parameters);
}

class ClassProviderSource extends ProviderSource {
  final CompileTypeMetadata? _classType;
  final List<ProviderSource> _parameters;
  final List<o.OutputType> _typeArguments;

  ClassProviderSource(
    CompileTokenMetadata token,
    this._classType,
    this._parameters, {
    List<o.OutputType> typeArguments = const [],
  })  : _typeArguments = typeArguments,
        super(token);

  @override
  o.Expression build() {
    var paramExpressions = <o.Expression>[];
    for (var s in _parameters) {
      paramExpressions.add(s.build());
    }
    final clazz = o.importExpr(_classType!);
    final create = clazz.instantiate(
      paramExpressions,
      type: o.importType(_classType),
      genericTypes: _typeArguments,
    );
    if (hasDynamicDependencies) {
      return debugInjectorWrap(createDiTokenExpression(token!), create);
    }
    return create;
  }

  @override
  bool get hasDynamicDependencies => _hasDynamicDependencies(_parameters);
}

/// Source for injectable values resolved by dynamic lookup (`injectorGet`).
class DynamicProviderSource extends ProviderSource {
  final CompileElement _element;
  final ProviderResolver? _resolver;
  final ProviderSource? _source;
  final bool _isOptional;

  DynamicProviderSource(
    CompileTokenMetadata? token,
    this._element,
    this._resolver,
    this._source, {
    required bool isOptional,
  })  : _isOptional = isOptional,
        super(token);

  @override
  o.Expression build() {
    final value = _source?.build() ?? _injectFromViewParent();
    final parent = _element.findElementByResolver(_resolver)!;
    return getPropertyInView(value, _element.view!, parent.view!);
  }

  o.Expression _injectFromViewParent() {
    return injectFromViewParentInjector(_element.view!, token!, _isOptional);
  }

  @override
  bool get hasDynamicDependencies => _source?.hasDynamicDependencies != false;
}
