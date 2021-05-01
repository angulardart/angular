import 'package:source_span/source_span.dart';
import 'package:angular/src/meta.dart';
import 'package:angular_compiler/v2/context.dart';

import 'compile_metadata.dart'
    show
        CompileDiDependencyMetadata,
        CompileDirectiveMetadata,
        CompileDirectiveMetadataType,
        CompileProviderMetadata,
        CompileQueryMetadata,
        CompileTokenMap,
        CompileTokenMetadata,
        CompileTypeMetadata;
import 'identifiers.dart' show Identifiers, identifierToken;
import 'template_ast.dart'
    show
        ReferenceAst,
        AttrAst,
        AttributeValue,
        DirectiveAst,
        ProviderAst,
        ProviderAstType,
        ElementProviderUsage;

/// Per component level context used to parse template using
/// TemplateParseVisitor.
class ProviderViewContext {
  final CompileDirectiveMetadata component;
  final SourceSpan sourceSpan;

  /// List of queries defined on the component used to detect which providers
  /// should be eagerly created at runtime initialization.
  late CompileTokenMap<List<CompileQueryMetadata>> viewQueries;

  /// List of tokens provided by component.
  late CompileTokenMap<bool> viewProviders;

  ProviderViewContext(this.component, this.sourceSpan) {
    viewQueries = _getViewQueries(component);
    viewProviders = CompileTokenMap<bool>();
    var normalizedViewProviders = _normalizeProviders(
      component.viewProviders,
      sourceSpan,
    );
    // Deduplicate providers by token.
    for (var provider in normalizedViewProviders) {
      if (viewProviders.get(provider.token!) == null) {
        viewProviders.add(provider.token!, true);
      }
    }
  }
}

class ProviderElementContext implements ElementProviderUsage {
  final ProviderViewContext _rootProviderContext;
  final ProviderElementContext? _parent;
  // True if parent is template or template has bindings.
  final bool _isViewRoot;
  final List<DirectiveAst> _directiveAsts;
  final SourceSpan? _sourceSpan;
  late CompileTokenMap<List<CompileQueryMetadata>> _contentQueries;
  final _transformedProviders = CompileTokenMap<ProviderAst>();
  final _seenProviders = CompileTokenMap<bool>();
  late CompileTokenMap<ProviderAst> _allProviders;
  final _attrs = <String, AttributeValue<Object>>{};
  bool _requiresViewContainer = false;

  /// A container for all @Attribute dependencies.
  final attributeDeps = <String>{};

  ProviderElementContext(
      this._rootProviderContext,
      this._parent,
      this._isViewRoot,
      this._directiveAsts,
      List<AttrAst> attrs,
      List<ReferenceAst> refs,
      this._sourceSpan) {
    for (var attrAst in attrs) {
      _attrs[attrAst.name] = attrAst.value;
    }
    final directivesMeta = _directiveMetadataFromAst(_directiveAsts);
    // Make a list of all providers required by union of all directives
    // including components themselves.
    final resolver = _ProviderResolver(directivesMeta, _sourceSpan);
    _allProviders = resolver.resolve();

    // Get content queries since we need to eagerly create providers to serve
    // values for component @ContentChild/@ContentChildren at ngOnInit time.
    _contentQueries = _getContentQueries(directivesMeta);
    var queriedTokens = CompileTokenMap<bool>();
    for (var provider in _allProviders.values) {
      _addQueryReadsTo(provider.token, queriedTokens);
    }
    // For each #ref, add the read type as a token to queries.
    for (var refAst in refs) {
      _addQueryReadsTo(CompileTokenMetadata(value: refAst.name), queriedTokens);
    }
    // If any content query asks to read ViewContainerRef, mark
    // ProviderElementContext to require view container.
    if (queriedTokens.get(identifierToken(Identifiers.ViewContainerRef)) !=
        null) {
      _requiresViewContainer = true;
    }
    // Create the providers that we know are eager first.
    for (var provider in _allProviders.values) {
      var eager = provider.eager || queriedTokens.get(provider.token) != null;
      if (eager) {
        _getOrCreateLocalProvider(provider.providerType, provider.token,
            eager: true);
      }
    }
  }

  List<CompileDirectiveMetadata> _directiveMetadataFromAst(
      List<DirectiveAst> asts) {
    final directives = <CompileDirectiveMetadata>[];
    for (var directiveAst in asts) {
      directives.add(directiveAst.directive);
    }
    return directives;
  }

  void afterElement() {
    // Collect lazy providers (provider itself not eager and not queried).
    for (var provider in _allProviders.values) {
      _getOrCreateLocalProvider(provider.providerType, provider.token,
          eager: false);
    }
  }

  List<ProviderAst> get transformProviders {
    return _transformedProviders.values;
  }

  List<DirectiveAst> get transformedDirectiveAsts {
    final providers = _transformedProviders.values
        .map((provider) => provider.token.identifier)
        .toList();
    // Directives must be sorted according to the dependency graph between them.
    // For example, if directive A depends on directive B, then directive B must
    // be instantiated before A so that it's available for injection into A.
    return List.of(_directiveAsts)
      ..sort((a, b) =>
          providers.indexOf(a.directive.type) -
          providers.indexOf(b.directive.type));
  }

  @override
  bool get requiresViewContainer => _requiresViewContainer;

  @override
  bool hasNonLocalRequest(ProviderAst providerAst) => true;

  void _addQueryReadsTo(
      CompileTokenMetadata token, CompileTokenMap<bool> queryReadTokens) {
    for (var query in _getQueriesFor(token)) {
      var queryReadToken = query.read ?? token;
      if (queryReadTokens.get(queryReadToken) == null) {
        queryReadTokens.add(queryReadToken, true);
      }
    }
  }

  List<CompileQueryMetadata> _getQueriesFor(CompileTokenMetadata token) {
    var result = <CompileQueryMetadata>[];
    ProviderElementContext? currentEl = this;
    var distance = 0;
    List<CompileQueryMetadata>? queries;
    while (!identical(currentEl, null)) {
      queries = currentEl._contentQueries.get(token);
      if (queries != null) {
        result.addAll(queries
            .where((query) => query.descendants || distance <= 1)
            .toList());
      }
      if (currentEl._directiveAsts.isNotEmpty) {
        distance++;
      }
      currentEl = currentEl._parent;
    }
    queries = _rootProviderContext.viewQueries.get(token);
    if (queries != null) {
      result.addAll(queries);
    }
    return result;
  }

  ProviderAst? _getOrCreateLocalProvider(
      ProviderAstType requestingProviderType, CompileTokenMetadata token,
      {required bool eager}) {
    var resolvedProvider = _allProviders.get(token);
    if (resolvedProvider == null ||
        (((requestingProviderType == ProviderAstType.Directive) ||
                (requestingProviderType == ProviderAstType.PublicService)) &&
            (resolvedProvider.providerType ==
                ProviderAstType.PrivateService)) ||
        (((requestingProviderType == ProviderAstType.PrivateService) ||
                (requestingProviderType == ProviderAstType.PublicService)) &&
            (resolvedProvider.providerType == ProviderAstType.Builtin))) {
      return null;
    }
    var transformedProviderAst = _transformedProviders.get(token);
    if (transformedProviderAst != null) {
      return transformedProviderAst;
    }
    if (_seenProviders.get(token) != null) {
      CompileContext.current.reportAndRecover(BuildError.forSourceSpan(
        _sourceSpan!,
        'Cannot instantiate cyclic dependency! ${token.name}',
      ));
      return null;
    }
    _seenProviders.add(token, true);

    // For this token, transform and collect list of providers,
    // List will have length > 1 if multi:true and we have multiple providers.
    var transformedProviders = <CompileProviderMetadata>[];
    for (var provider in resolvedProvider.providers) {
      var transformedUseValue = provider.useValue;
      var transformedUseExisting = provider.useExisting;
      List<CompileDiDependencyMetadata>? transformedDeps;
      if (provider.useExisting != null) {
        var existingDiDep = _getDependency(resolvedProvider.providerType,
            CompileDiDependencyMetadata(token: provider.useExisting), eager)!;
        if (existingDiDep.token != null) {
          transformedUseExisting = existingDiDep.token;
        } else {
          transformedUseExisting = null;
          transformedUseValue = existingDiDep.value;
        }
      } else if (provider.useFactory != null) {
        var dependencies = provider.deps ?? provider.useFactory!.diDeps;
        transformedDeps = [];
        for (var dependency in dependencies) {
          var dep =
              _getDependency(resolvedProvider.providerType, dependency!, eager);
          if (dep != null) {
            transformedDeps.add(dep);
          }
        }
      } else if (provider.useClass != null) {
        var dependencies = provider.deps ?? provider.useClass!.diDeps;
        transformedDeps = [];
        for (var dependency in dependencies) {
          var dep =
              _getDependency(resolvedProvider.providerType, dependency!, eager);
          if (dep != null) {
            transformedDeps.add(dep);
          }
        }
      }
      transformedProviders.add(_transformProvider(provider,
          useExisting: transformedUseExisting,
          useValue: transformedUseValue,
          deps: transformedDeps));
    }

    /// Create a clone of the ProviderAst using new eager parameter.
    transformedProviderAst = _transformProviderAst(resolvedProvider,
        forceEager: eager, providers: transformedProviders);
    _transformedProviders.add(token, transformedProviderAst);
    return transformedProviderAst;
  }

  CompileDiDependencyMetadata? _getLocalDependency(
      ProviderAstType requestingProviderType,
      CompileDiDependencyMetadata dep,
      bool eager) {
    if (dep.isAttribute) {
      _registerAttributeValueForMissingDirectivesCheck(dep);
      // Could be a literal attribute (String), internationalized attribute
      // (I18nMessage), or null if there was no matching attribute.
      final attributeValue = _attrs[dep.token!.value as String]?.value;
      return CompileDiDependencyMetadata(isValue: true, value: attributeValue);
    }
    var token = dep.token;
    if (token != null) {
      // access built-ins
      if (requestingProviderType == ProviderAstType.Directive ||
          requestingProviderType == ProviderAstType.Component) {
        if (token.equalsTo(Identifiers.ElementRefToken) ||
            token.equalsTo(Identifiers.HtmlElementToken) ||
            token.equalsTo(Identifiers.ElementToken) ||
            token.equalsTo(Identifiers.ChangeDetectorRefToken) ||
            token.equalsTo(Identifiers.NgContentRefToken) ||
            token.equalsTo(Identifiers.TemplateRefToken)) {
          return dep;
        }
        if (token.equalsTo(Identifiers.ViewContainerRefToken)) {
          _requiresViewContainer = true;
        }
        if (token.equalsTo(Identifiers.ComponentLoaderToken)) {
          _requiresViewContainer = true;
          return dep;
        }
      }
      // access the injector
      if (token.equalsTo(Identifiers.InjectorToken)) {
        return dep;
      }
      // access providers
      if (_getOrCreateLocalProvider(requestingProviderType, token,
              eager: eager) !=
          null) {
        return dep;
      }
    }
    return null;
  }

  void _registerAttributeValueForMissingDirectivesCheck(
      CompileDiDependencyMetadata dep) {
    final attributeName = dep.token!.value! as String;
    attributeDeps.add(attributeName);
  }

  CompileDiDependencyMetadata? _getDependency(
      ProviderAstType requestingProviderType,
      CompileDiDependencyMetadata dep,
      bool eager) {
    ProviderElementContext? currElement = this;
    var currEager = eager;
    CompileDiDependencyMetadata? result;
    if (!dep.isSkipSelf) {
      result = _getLocalDependency(requestingProviderType, dep, eager);
      if (result != null) return result;
    }
    if (dep.isSelf) {
      if (dep.isOptional) {
        result = CompileDiDependencyMetadata(isValue: true, value: null);
      }
    } else {
      // check parent elements
      while (result == null && currElement!._parent != null) {
        var prevElement = currElement;
        currElement = currElement._parent;
        if (prevElement._isViewRoot) {
          currEager = false;
        }
        result = currElement!
            ._getLocalDependency(ProviderAstType.PublicService, dep, currEager);
      }
      // check @Host restriction
      if (result == null) {
        if (!dep.isHost ||
            _rootProviderContext.component.type!.isHost ||
            identifierToken(_rootProviderContext.component.type)
                .equalsTo(dep.token!) ||
            _rootProviderContext.viewProviders.get(dep.token!) != null) {
          result = dep;
        } else {
          result = dep.isOptional
              ? result = CompileDiDependencyMetadata(isValue: true, value: null)
              : null;
        }
      }
    }
    if (result == null) {
      CompileContext.current.reportAndRecover(BuildError.forSourceSpan(
        _sourceSpan!,
        'No provider for ${dep.token!.name}',
      ));
    }
    return result;
  }
}

CompileProviderMetadata _transformProvider(CompileProviderMetadata provider,
    {CompileTokenMetadata? useExisting,
    dynamic useValue,
    List<CompileDiDependencyMetadata>? deps}) {
  return CompileProviderMetadata(
    token: provider.token,
    useClass: provider.useClass,
    useExisting: useExisting,
    useFactory: provider.useFactory,
    useValue: useValue,
    deps: deps,
    multi: provider.multi,
    typeArgument: provider.typeArgument,
  );
}

/// Creates a new provider ast node by overriding eager and providers members
/// of existing ProviderAst.
ProviderAst _transformProviderAst(ProviderAst provider,
    {bool? forceEager, required List<CompileProviderMetadata> providers}) {
  return ProviderAst(
    provider.token,
    provider.multiProvider,
    providers,
    provider.providerType,
    provider.sourceSpan,
    eager: provider.eager || forceEager!,
    isReferencedOutsideBuild: provider.isReferencedOutsideBuild,
    visibleForInjection: provider.visibleForInjection,
    typeArgument: provider.typeArgument,
  );
}

// Flattens list of lists of providers and converts entries that contain Type to
// CompileProviderMetadata with useClass.
List<CompileProviderMetadata> _normalizeProviders(
  /* CompileProviderMetadata | CompileTypeMetadata | List <Object> */
  List<Object>? providers,
  SourceSpan? sourceSpan, [
  List<CompileProviderMetadata>? targetProviders,
]) {
  targetProviders ??= <CompileProviderMetadata>[];
  if (providers != null) {
    for (var provider in providers) {
      if (provider is List<Object>) {
        _normalizeProviders(provider, sourceSpan, targetProviders);
      } else {
        CompileProviderMetadata? normalizeProvider;
        if (provider is CompileProviderMetadata) {
          normalizeProvider = provider;
        } else if (provider is CompileTypeMetadata) {
          normalizeProvider = CompileProviderMetadata(
            token: CompileTokenMetadata(identifier: provider),
            useClass: provider,
          );
        } else {
          CompileContext.current.reportAndRecover(BuildError.forSourceSpan(
            sourceSpan!,
            'Unknown provider type $provider',
          ));
        }
        if (normalizeProvider != null) {
          targetProviders.add(normalizeProvider);
        }
      }
    }
  }
  return targetProviders;
}

/// Given an ordered list of directives and components, builds a map from
/// token to provider.
///
/// Creates a ProviderAst for each directive and then resolves
/// each provider for components followed by providers for directives.
class _ProviderResolver {
  final List<CompileDirectiveMetadata> directives;
  final SourceSpan? sourceSpan;
  late CompileTokenMap<ProviderAst> _providersByToken;

  _ProviderResolver(this.directives, this.sourceSpan);

  CompileTokenMap<ProviderAst> resolve() {
    _providersByToken = CompileTokenMap<ProviderAst>();
    for (var directive in directives) {
      var dirProvider = CompileProviderMetadata(
          token: CompileTokenMetadata(identifier: directive.type),
          useClass: directive.type,
          visibility: directive.visibility);
      final providerAstType =
          _providerAstTypeFromMetadataType(directive.metadataType);
      _resolveProviders([dirProvider], providerAstType, eager: true);
    }
    // Note: We need an ordered list where components preceded directives so
    // directives are able to overwrite providers of a component!
    var orderedList = <CompileDirectiveMetadata>[];
    for (var dir in directives) {
      if (dir.isComponent) orderedList.add(dir);
    }
    for (var dir in directives) {
      if (!dir.isComponent) orderedList.add(dir);
    }
    for (var directive in orderedList) {
      _resolveProviders(
        _normalizeProviders(directive.providers, sourceSpan),
        ProviderAstType.PublicService,
        eager: false,
      );
      _resolveProviders(
        _normalizeProviders(directive.viewProviders, sourceSpan),
        ProviderAstType.PrivateService,
        eager: false,
      );
    }
    return _providersByToken;
  }

  // Updates tokenMap by creating new ProviderAst or by adding/replacing new entry
  // for existing ProviderAst.
  void _resolveProviders(
    List<CompileProviderMetadata> providers,
    ProviderAstType providerType, {
    required bool eager,
  }) {
    for (var provider in providers) {
      var resolvedProvider = _providersByToken.get(provider.token!);
      if (resolvedProvider != null &&
          resolvedProvider.multiProvider != provider.multi) {
        CompileContext.current.reportAndRecover(BuildError.forSourceSpan(
          sourceSpan!,
          'Mixing multi and non multi provider is not possible for token '
          '${resolvedProvider.token.name}',
        ));
      }
      if (resolvedProvider == null) {
        resolvedProvider = ProviderAst(
          provider.token!,
          provider.multi,
          [provider],
          providerType,
          sourceSpan!,
          eager: eager,
          typeArgument: provider.typeArgument,
          visibleForInjection: provider.visibility == Visibility.all,
        );
        _providersByToken.add(provider.token!, resolvedProvider);
      } else {
        if (!provider.multi) {
          // Overwrite existing provider.
          resolvedProvider.providers.clear();
        }
        resolvedProvider.providers.add(provider);
      }
    }
  }
}

CompileTokenMap<List<CompileQueryMetadata>> _getViewQueries(
    CompileDirectiveMetadata component) {
  var viewQueries = CompileTokenMap<List<CompileQueryMetadata>>();
  for (var query in component.viewQueries) {
    _addQueryToTokenMap(viewQueries, query);
  }
  return viewQueries;
}

CompileTokenMap<List<CompileQueryMetadata>> _getContentQueries(
    List<CompileDirectiveMetadata> directives) {
  var contentQueries = CompileTokenMap<List<CompileQueryMetadata>>();
  for (var directive in directives) {
    for (var query in directive.queries) {
      _addQueryToTokenMap(contentQueries, query);
    }
  }
  return contentQueries;
}

void _addQueryToTokenMap(CompileTokenMap<List<CompileQueryMetadata>> map,
    CompileQueryMetadata query) {
  for (var token in query.selectors!) {
    var entry = map.get(token);
    if (entry == null) {
      entry = [];
      map.add(token, entry);
    }
    entry.add(query);
  }
}

ProviderAstType _providerAstTypeFromMetadataType(
  CompileDirectiveMetadataType? type,
) {
  switch (type) {
    case CompileDirectiveMetadataType.Component:
      return ProviderAstType.Component;
    case CompileDirectiveMetadataType.Directive:
      return ProviderAstType.Directive;
    default:
      throw ArgumentError("Can't create '$ProviderAstType' from '$type'");
  }
}

final CompileTokenMetadata ngIfTokenMetadata =
    identifierToken(Identifiers.NG_IF_DIRECTIVE);
final CompileTokenMetadata ngForTokenMetadata =
    identifierToken(Identifiers.NG_FOR_DIRECTIVE);
