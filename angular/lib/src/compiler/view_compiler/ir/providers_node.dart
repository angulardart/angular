import '../../compile_metadata.dart';
import '../../output/output_ast.dart' as o;
import '../../template_ast.dart';
import '../../view_compiler/view_compiler_utils.dart';

/// Resolves and builds Providers for a single compile element that represents
/// a template node.
class ProvidersNode {
  final ProvidersNodeHost _host;
  final ProvidersNode _parent;

  final List<CompileDirectiveMetadata> _directives;

  /// Maps from a provider token to expression that will return instance
  /// at runtime. Builtin(s) are populated eagerly, ProviderAst based
  /// instances are added on demand.
  final _instances = new CompileTokenMap<o.Expression>();

  /// We track which providers are just 'useExisting' for another provider on
  /// this component. This way, we can detect when we don't need to generate
  /// a getter for them.
  final _aliases = new CompileTokenMap<List<CompileTokenMetadata>>();
  final _aliasedProviders = new CompileTokenMap<CompileTokenMetadata>();

  final CompileTokenMap<ProviderAst> _resolvedProviders =
      new CompileTokenMap<ProviderAst>();

  ProvidersNode(this._host, this._parent, this._directives);

  bool containsLocalProvider(CompileTokenMetadata token) =>
      _instances.containsKey(token);

  o.Expression buildReadExpr(CompileTokenMetadata token) =>
      _instances.get(token);

  bool isAliasedProvider(CompileTokenMetadata token) =>
      _aliasedProviders.containsKey(token);

  List<CompileTokenMetadata> getAliases(CompileTokenMetadata providerToken) =>
      _aliases.get(providerToken);

  /// Adds a builtin local provider for a template node.
  void add(CompileTokenMetadata token, o.Expression providerValue) {
    _instances.add(token, providerValue);
  }

  void addDirectiveProviders(
      final List<ProviderAst> providerList, bool componentIsDeferred) {
    // Create a lookup map from token to provider.
    for (ProviderAst provider in providerList) {
      _resolvedProviders.add(provider.token, provider);
    }
    // Create all the provider instances, some in the view constructor (eager),
    // some as getters (eager=false). We rely on the fact that they are
    // already sorted topologically.
    for (ProviderAst resolvedProvider in providerList) {
      if (resolvedProvider.providerType ==
          ProviderAstType.FunctionalDirective) {
        continue;
      }
      var providerValueExpressions = <o.Expression>[];
      var isLocalAlias = false;
      CompileDirectiveMetadata directiveMetadata;
      for (var provider in resolvedProvider.providers) {
        o.Expression providerValue;
        if (provider.useExisting != null) {
          // If this provider is just an alias for another provider on this
          // component, we don't need to generate a getter.
          if (_instances.containsKey(provider.useExisting) &&
              !resolvedProvider.eager &&
              !resolvedProvider.multiProvider) {
            isLocalAlias = true;
            break;
          }
          // Given the token and visibility defined by providerType,
          // get value based on existing expression mapped to token.
          providerValue = _getDependency(resolvedProvider.providerType,
              new CompileDiDependencyMetadata(token: provider.useExisting),
              requestOrigin:
                  resolvedProvider.implementedByDirectiveWithNoVisibility
                      ? provider.token
                      : null);
          directiveMetadata = null;
        } else if (provider.useFactory != null) {
          var parameters = <o.Expression>[];
          for (var paramDep in provider.deps ?? provider.useFactory.diDeps) {
            parameters
                .add(_getDependency(resolvedProvider.providerType, paramDep));
          }
          providerValue = o.importExpr(provider.useFactory).callFn(parameters);
        } else if (provider.useClass != null) {
          var paramDeps = provider.deps ?? provider.useClass.diDeps;
          // Resolve constructor parameters for class.
          var parameters = <o.Expression>[];
          for (var paramDep in paramDeps) {
            parameters
                .add(_getDependency(resolvedProvider.providerType, paramDep));
          }
          var classType = provider.useClass.identifier;
          // Check if class is a directive.
          for (var dir in _directives) {
            if (dir.identifier == classType) {
              directiveMetadata = dir;
              break;
            }
          }
          providerValue = o
              .importExpr(provider.useClass)
              .instantiate(parameters, o.importType(provider.useClass));
        } else {
          providerValue = convertValueToOutputAst(provider.useValue);
        }
        providerValueExpressions.add(providerValue);
      }
      if (isLocalAlias) {
        // This provider is just an alias for an existing field/instance
        // on the same view class, so just add the existing reference for this
        // token.
        var provider = resolvedProvider.providers.single;
        var alias = provider.useExisting;
        if (_aliasedProviders.containsKey(alias)) {
          alias = _aliasedProviders.get(alias);
        }
        if (!_aliases.containsKey(alias)) {
          _aliases.add(alias, <CompileTokenMetadata>[]);
        }
        _aliases.get(alias).add(provider.token);
        _aliasedProviders.add(resolvedProvider.token, alias);
        _instances.add(resolvedProvider.token, _instances.get(alias));
      } else {
        _instances.add(
            resolvedProvider.token,
            _host.createProviderInstance(
                resolvedProvider,
                directiveMetadata,
                providerValueExpressions,
                componentIsDeferred,
                _instances.size));
      }
    }
  }

  o.Expression _getLocalDependency(
      ProviderAstType requestingProviderType, CompileTokenMetadata token) {
    if (token == null) return null;

    // Access regular providers on the element. For provider instances with an
    // associated provider AST, ensure the provider is visible for injection.
    final providerAst = _resolvedProviders.get(token);
    if (providerAst == null || providerAst.visibleForInjection) {
      return _instances.get(token);
    }

    return null;
  }

  o.Expression _getDependency(
      ProviderAstType requestingProviderType, CompileDiDependencyMetadata dep,
      {CompileTokenMetadata requestOrigin}) {
    ProvidersNode currProviders = this;
    o.Expression result;
    if (dep.isValue) {
      result = o.literal(dep.value);
    }
    if (result == null && !dep.isSkipSelf) {
      result = _getLocalDependency(requestingProviderType, dep.token);
    }

    // check parent elements
    while (result == null && currProviders._parent._parent != null) {
      currProviders = currProviders._parent;
      result = currProviders._getLocalDependency(
          ProviderAstType.PublicService, dep.token);
    }

    // If component has a service with useExisting: provider pointing to itself,
    // we need to search for providerAst using the service interface but
    // query _instances with the component type to get correct instance.
    // [requestOrigin] below points to the service whereas dep.token will
    // reference the component type.
    if (result == null && requestOrigin != null) {
      currProviders = this;
      if (!dep.isSkipSelf) {
        final providerAst = _resolvedProviders.get(requestOrigin);
        if (providerAst == null ||
            providerAst.visibleForInjection ||
            // This condition is only reached when a component implements a
            // directive that's applied to its host element, and provides itself
            // in place of the directive. In this case we don't care if the
            // request origin (the directive itself) is visible, since this
            // wouldn't prevent you from applying the directive in the absence
            // of the component.
            requestingProviderType == ProviderAstType.Directive) {
          result = _instances.get(dep.token);
        }
      }
      // See if we have local dependency to origin service.
      while (result == null && currProviders._parent._parent != null) {
        currProviders = currProviders._parent;
        final providerAst = currProviders._resolvedProviders.get(requestOrigin);
        if (providerAst == null || providerAst.visibleForInjection) {
          result = currProviders._instances.get(dep.token);
        }
      }
    }

    return _host.buildInjectFromParentExpr(
        currProviders, result, requestOrigin ?? dep.token, dep.isOptional);
  }

  /// Creates an expression that calls a functional directive.
  o.Expression createFunctionalDirectiveExpression(ProviderAst provider) {
    // Add functional directive invocation.
    // Get function parameter dependencies.
    final parameters = <o.Expression>[];
    final mainProvider = provider.providers.first;
    for (var dep in mainProvider.deps) {
      parameters.add(_getDependency(provider.providerType, dep));
    }
    return o.importExpr(mainProvider.useClass).callFn(parameters);
  }
}

/// Interface to be implemented by NodeProviders users.
abstract class ProvidersNodeHost {
  /// Creates an instance for a provider and returns referencing expression.
  o.Expression createProviderInstance(
      ProviderAst resolvedProvider,
      CompileDirectiveMetadata directiveMetadata,
      List<o.Expression> providerValueExpressions,
      bool componentIsDeferred,
      int uniqueId);

  /// Creates expression to call injectorGet on parent view that contains source
  /// NodeProviders.
  o.Expression buildInjectFromParentExpr(ProvidersNode source,
      o.Expression value, CompileTokenMetadata token, bool optional);
}
