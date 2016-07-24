import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show isPresent, isBlank, isArray;

import "compile_metadata.dart"
    show
        CompileTypeMetadata,
        CompileTokenMap,
        CompileQueryMetadata,
        CompileTokenMetadata,
        CompileProviderMetadata,
        CompileDirectiveMetadata,
        CompileDiDependencyMetadata;
import "identifiers.dart" show Identifiers, identifierToken;
import "parse_util.dart" show ParseSourceSpan, ParseError;
import "template_ast.dart"
    show ReferenceAst, AttrAst, DirectiveAst, ProviderAst, ProviderAstType;

class ProviderError extends ParseError {
  ProviderError(String message, ParseSourceSpan span) : super(span, message) {
    /* super call moved to initializer */;
  }
}

class ProviderViewContext {
  CompileDirectiveMetadata component;
  ParseSourceSpan sourceSpan;
  /**
   * @internal
   */
  CompileTokenMap<List<CompileQueryMetadata>> viewQueries;
  /**
   * @internal
   */
  CompileTokenMap<bool> viewProviders;
  List<ProviderError> errors = [];
  ProviderViewContext(this.component, this.sourceSpan) {
    this.viewQueries = _getViewQueries(component);
    this.viewProviders = new CompileTokenMap<bool>();
    _normalizeProviders(component.viewProviders, sourceSpan, this.errors)
        .forEach((provider) {
      if (isBlank(this.viewProviders.get(provider.token))) {
        this.viewProviders.add(provider.token, true);
      }
    });
  }
}

class ProviderElementContext {
  ProviderViewContext _viewContext;
  ProviderElementContext _parent;
  bool _isViewRoot;
  List<DirectiveAst> _directiveAsts;
  ParseSourceSpan _sourceSpan;
  CompileTokenMap<List<CompileQueryMetadata>> _contentQueries;
  var _transformedProviders = new CompileTokenMap<ProviderAst>();
  var _seenProviders = new CompileTokenMap<bool>();
  CompileTokenMap<ProviderAst> _allProviders;
  Map<String, String> _attrs;
  bool _hasViewContainer = false;
  ProviderElementContext(
      this._viewContext,
      this._parent,
      this._isViewRoot,
      this._directiveAsts,
      List<AttrAst> attrs,
      List<ReferenceAst> refs,
      this._sourceSpan) {
    this._attrs = {};
    attrs.forEach((attrAst) => this._attrs[attrAst.name] = attrAst.value);
    var directivesMeta =
        _directiveAsts.map((directiveAst) => directiveAst.directive).toList();
    this._allProviders = _resolveProvidersFromDirectives(
        directivesMeta, _sourceSpan, _viewContext.errors);
    this._contentQueries = _getContentQueries(directivesMeta);
    var queriedTokens = new CompileTokenMap<bool>();
    this._allProviders.values().forEach((provider) {
      this._addQueryReadsTo(provider.token, queriedTokens);
    });
    refs.forEach((refAst) {
      this._addQueryReadsTo(
          new CompileTokenMetadata(value: refAst.name), queriedTokens);
    });
    if (isPresent(
        queriedTokens.get(identifierToken(Identifiers.ViewContainerRef)))) {
      this._hasViewContainer = true;
    }
    // create the providers that we know are eager first
    this._allProviders.values().forEach((provider) {
      var eager =
          provider.eager || isPresent(queriedTokens.get(provider.token));
      if (eager) {
        this._getOrCreateLocalProvider(
            provider.providerType, provider.token, true);
      }
    });
  }
  afterElement() {
    // collect lazy providers
    this._allProviders.values().forEach((provider) {
      this._getOrCreateLocalProvider(
          provider.providerType, provider.token, false);
    });
  }

  List<ProviderAst> get transformProviders {
    return this._transformedProviders.values();
  }

  List<DirectiveAst> get transformedDirectiveAsts {
    var sortedProviderTypes = this
        ._transformedProviders
        .values()
        .map((provider) => provider.token.identifier)
        .toList();
    var sortedDirectives = ListWrapper.clone(this._directiveAsts);
    ListWrapper.sort(
        sortedDirectives,
        (dir1, dir2) =>
            sortedProviderTypes.indexOf(dir1.directive.type) -
            sortedProviderTypes.indexOf(dir2.directive.type));
    return sortedDirectives;
  }

  bool get transformedHasViewContainer {
    return this._hasViewContainer;
  }

  _addQueryReadsTo(
      CompileTokenMetadata token, CompileTokenMap<bool> queryReadTokens) {
    this._getQueriesFor(token).forEach((query) {
      var queryReadToken = isPresent(query.read) ? query.read : token;
      if (isBlank(queryReadTokens.get(queryReadToken))) {
        queryReadTokens.add(queryReadToken, true);
      }
    });
  }

  List<CompileQueryMetadata> _getQueriesFor(CompileTokenMetadata token) {
    List<CompileQueryMetadata> result = [];
    ProviderElementContext currentEl = this;
    var distance = 0;
    List<CompileQueryMetadata> queries;
    while (!identical(currentEl, null)) {
      queries = currentEl._contentQueries.get(token);
      if (isPresent(queries)) {
        ListWrapper.addAll(
            result,
            queries
                .where((query) => query.descendants || distance <= 1)
                .toList());
      }
      if (currentEl._directiveAsts.length > 0) {
        distance++;
      }
      currentEl = currentEl._parent;
    }
    queries = this._viewContext.viewQueries.get(token);
    if (isPresent(queries)) {
      ListWrapper.addAll(result, queries);
    }
    return result;
  }

  ProviderAst _getOrCreateLocalProvider(ProviderAstType requestingProviderType,
      CompileTokenMetadata token, bool eager) {
    var resolvedProvider = this._allProviders.get(token);
    if (isBlank(resolvedProvider) ||
        ((identical(requestingProviderType, ProviderAstType.Directive) ||
                identical(
                    requestingProviderType, ProviderAstType.PublicService)) &&
            identical(resolvedProvider.providerType,
                ProviderAstType.PrivateService)) ||
        ((identical(requestingProviderType, ProviderAstType.PrivateService) ||
                identical(
                    requestingProviderType, ProviderAstType.PublicService)) &&
            identical(
                resolvedProvider.providerType, ProviderAstType.Builtin))) {
      return null;
    }
    var transformedProviderAst = this._transformedProviders.get(token);
    if (isPresent(transformedProviderAst)) {
      return transformedProviderAst;
    }
    if (isPresent(this._seenProviders.get(token))) {
      this._viewContext.errors.add(new ProviderError(
          '''Cannot instantiate cyclic dependency! ${ token . name}''',
          this._sourceSpan));
      return null;
    }
    this._seenProviders.add(token, true);
    List<CompileProviderMetadata> transformedProviders =
        resolvedProvider.providers.map((provider) {
      var transformedUseValue = provider.useValue;
      var transformedUseExisting = provider.useExisting;
      List<CompileDiDependencyMetadata> transformedDeps;
      if (isPresent(provider.useExisting)) {
        var existingDiDep = this._getDependency(
            resolvedProvider.providerType,
            new CompileDiDependencyMetadata(token: provider.useExisting),
            eager);
        if (isPresent(existingDiDep.token)) {
          transformedUseExisting = existingDiDep.token;
        } else {
          transformedUseExisting = null;
          transformedUseValue = existingDiDep.value;
        }
      } else if (isPresent(provider.useFactory)) {
        var deps = isPresent(provider.deps)
            ? provider.deps
            : provider.useFactory.diDeps;
        transformedDeps = deps
            .map((dep) =>
                this._getDependency(resolvedProvider.providerType, dep, eager))
            .toList();
      } else if (isPresent(provider.useClass)) {
        var deps =
            isPresent(provider.deps) ? provider.deps : provider.useClass.diDeps;
        transformedDeps = deps
            .map((dep) =>
                this._getDependency(resolvedProvider.providerType, dep, eager))
            .toList();
      }
      return _transformProvider(provider,
          useExisting: transformedUseExisting,
          useValue: transformedUseValue,
          deps: transformedDeps) as CompileProviderMetadata;
    }).toList();
    transformedProviderAst = _transformProviderAst(resolvedProvider,
        eager: eager, providers: transformedProviders);
    this._transformedProviders.add(token, transformedProviderAst);
    return transformedProviderAst;
  }

  CompileDiDependencyMetadata _getLocalDependency(
      ProviderAstType requestingProviderType, CompileDiDependencyMetadata dep,
      [bool eager = null]) {
    if (dep.isAttribute) {
      var attrValue = this._attrs[dep.token.value];
      return new CompileDiDependencyMetadata(isValue: true, value: attrValue);
    }
    if (isPresent(dep.query) || isPresent(dep.viewQuery)) {
      return dep;
    }
    if (isPresent(dep.token)) {
      // access builtints
      if ((identical(requestingProviderType, ProviderAstType.Directive) ||
          identical(requestingProviderType, ProviderAstType.Component))) {
        if (dep.token.equalsTo(identifierToken(Identifiers.Renderer)) ||
            dep.token.equalsTo(identifierToken(Identifiers.ElementRef)) ||
            dep.token
                .equalsTo(identifierToken(Identifiers.ChangeDetectorRef)) ||
            dep.token.equalsTo(identifierToken(Identifiers.TemplateRef))) {
          return dep;
        }
        if (dep.token.equalsTo(identifierToken(Identifiers.ViewContainerRef))) {
          this._hasViewContainer = true;
        }
      }
      // access the injector
      if (dep.token.equalsTo(identifierToken(Identifiers.Injector))) {
        return dep;
      }
      // access providers
      if (isPresent(this._getOrCreateLocalProvider(
          requestingProviderType, dep.token, eager))) {
        return dep;
      }
    }
    return null;
  }

  CompileDiDependencyMetadata _getDependency(
      ProviderAstType requestingProviderType, CompileDiDependencyMetadata dep,
      [bool eager = null]) {
    ProviderElementContext currElement = this;
    bool currEager = eager;
    CompileDiDependencyMetadata result = null;
    if (!dep.isSkipSelf) {
      result = this._getLocalDependency(requestingProviderType, dep, eager);
    }
    if (dep.isSelf) {
      if (isBlank(result) && dep.isOptional) {
        result = new CompileDiDependencyMetadata(isValue: true, value: null);
      }
    } else {
      // check parent elements
      while (isBlank(result) && isPresent(currElement._parent)) {
        var prevElement = currElement;
        currElement = currElement._parent;
        if (prevElement._isViewRoot) {
          currEager = false;
        }
        result = currElement._getLocalDependency(
            ProviderAstType.PublicService, dep, currEager);
      }
      // check @Host restriction
      if (isBlank(result)) {
        if (!dep.isHost ||
            this._viewContext.component.type.isHost ||
            identifierToken(this._viewContext.component.type)
                .equalsTo(dep.token) ||
            isPresent(this._viewContext.viewProviders.get(dep.token))) {
          result = dep;
        } else {
          result = dep.isOptional
              ? result =
                  new CompileDiDependencyMetadata(isValue: true, value: null)
              : null;
        }
      }
    }
    if (isBlank(result)) {
      this._viewContext.errors.add(new ProviderError(
          '''No provider for ${ dep . token . name}''', this._sourceSpan));
    }
    return result;
  }
}

class AppProviderParser {
  ParseSourceSpan _sourceSpan;
  var _transformedProviders = new CompileTokenMap<ProviderAst>();
  var _seenProviders = new CompileTokenMap<bool>();
  CompileTokenMap<ProviderAst> _allProviders;
  List<ProviderError> _errors = [];
  AppProviderParser(this._sourceSpan, List<dynamic> providers) {
    this._allProviders = new CompileTokenMap<ProviderAst>();
    _resolveProviders(
        _normalizeProviders(providers, this._sourceSpan, this._errors),
        ProviderAstType.PublicService,
        false,
        this._sourceSpan,
        this._errors,
        this._allProviders);
  }
  List<ProviderAst> parse() {
    this._allProviders.values().forEach((provider) {
      this._getOrCreateLocalProvider(provider.token, provider.eager);
    });
    if (this._errors.length > 0) {
      var errorString = this._errors.join("\n");
      throw new BaseException('''Provider parse errors:
${ errorString}''');
    }
    return this._transformedProviders.values();
  }

  ProviderAst _getOrCreateLocalProvider(
      CompileTokenMetadata token, bool eager) {
    var resolvedProvider = this._allProviders.get(token);
    if (isBlank(resolvedProvider)) {
      return null;
    }
    var transformedProviderAst = this._transformedProviders.get(token);
    if (isPresent(transformedProviderAst)) {
      return transformedProviderAst;
    }
    if (isPresent(this._seenProviders.get(token))) {
      this._errors.add(new ProviderError(
          'Cannot instantiate cyclic dependency! ${token.name}',
          this._sourceSpan));
      return null;
    }
    this._seenProviders.add(token, true);
    List<CompileProviderMetadata> transformedProviders =
        resolvedProvider.providers.map((provider) {
      var transformedUseValue = provider.useValue;
      var transformedUseExisting = provider.useExisting;
      List<CompileDiDependencyMetadata> transformedDeps;
      if (isPresent(provider.useExisting)) {
        var existingDiDep = this._getDependency(
            new CompileDiDependencyMetadata(token: provider.useExisting),
            eager);
        if (isPresent(existingDiDep.token)) {
          transformedUseExisting = existingDiDep.token;
        } else {
          transformedUseExisting = null;
          transformedUseValue = existingDiDep.value;
        }
      } else if (isPresent(provider.useFactory)) {
        var deps = isPresent(provider.deps)
            ? provider.deps
            : provider.useFactory.diDeps;
        transformedDeps =
            deps.map((dep) => this._getDependency(dep, eager)).toList();
      } else if (isPresent(provider.useClass)) {
        var deps =
            isPresent(provider.deps) ? provider.deps : provider.useClass.diDeps;
        transformedDeps =
            deps.map((dep) => this._getDependency(dep, eager)).toList();
      }
      return _transformProvider(provider,
          useExisting: transformedUseExisting,
          useValue: transformedUseValue,
          deps: transformedDeps) as CompileProviderMetadata;
    }).toList();
    transformedProviderAst = _transformProviderAst(resolvedProvider,
        eager: eager, providers: transformedProviders);
    this._transformedProviders.add(token, transformedProviderAst);
    return transformedProviderAst;
  }

  CompileDiDependencyMetadata _getDependency(CompileDiDependencyMetadata dep,
      [bool eager = null]) {
    var foundLocal = false;
    if (!dep.isSkipSelf && isPresent(dep.token)) {
      // access the injector
      if (dep.token.equalsTo(identifierToken(Identifiers.Injector))) {
        foundLocal = true;
      } else if (isPresent(this._getOrCreateLocalProvider(dep.token, eager))) {
        foundLocal = true;
      }
    }
    CompileDiDependencyMetadata result = dep;
    if (dep.isSelf && !foundLocal) {
      if (dep.isOptional) {
        result = new CompileDiDependencyMetadata(isValue: true, value: null);
      } else {
        this._errors.add(new ProviderError(
            '''No provider for ${ dep . token . name}''', this._sourceSpan));
      }
    }
    return result;
  }
}

_transformProvider(CompileProviderMetadata provider,
    {CompileTokenMetadata useExisting,
    dynamic useValue,
    List<CompileDiDependencyMetadata> deps}) {
  return new CompileProviderMetadata(
      token: provider.token,
      useClass: provider.useClass,
      useExisting: useExisting,
      useFactory: provider.useFactory,
      useValue: useValue,
      useProperty: provider.useProperty,
      deps: deps,
      multi: provider.multi);
}

ProviderAst _transformProviderAst(ProviderAst provider,
    {bool eager, List<CompileProviderMetadata> providers}) {
  return new ProviderAst(
      provider.token,
      provider.multiProvider,
      provider.eager || eager,
      providers,
      provider.providerType,
      provider.sourceSpan);
}

List<CompileProviderMetadata> _normalizeProviders(
    List<
        dynamic /* CompileProviderMetadata | CompileTypeMetadata | List < dynamic > */ > providers,
    ParseSourceSpan sourceSpan,
    List<ParseError> targetErrors,
    [List<CompileProviderMetadata> targetProviders = null]) {
  if (isBlank(targetProviders)) {
    targetProviders = [];
  }
  if (isPresent(providers)) {
    providers.forEach((provider) {
      if (isArray(provider)) {
        _normalizeProviders((provider as List<dynamic>), sourceSpan,
            targetErrors, targetProviders);
      } else {
        CompileProviderMetadata normalizeProvider;
        if (provider is CompileProviderMetadata) {
          normalizeProvider = provider;
        } else if (provider is CompileTypeMetadata) {
          normalizeProvider = new CompileProviderMetadata(
              token: new CompileTokenMetadata(identifier: provider),
              useClass: provider);
        } else {
          targetErrors.add(new ProviderError(
              '''Unknown provider type ${ provider}''', sourceSpan));
        }
        if (isPresent(normalizeProvider)) {
          targetProviders.add(normalizeProvider);
        }
      }
    });
  }
  return targetProviders;
}

CompileTokenMap<ProviderAst> _resolveProvidersFromDirectives(
    List<CompileDirectiveMetadata> directives,
    ParseSourceSpan sourceSpan,
    List<ParseError> targetErrors) {
  var providersByToken = new CompileTokenMap<ProviderAst>();
  directives.forEach((directive) {
    var dirProvider = new CompileProviderMetadata(
        token: new CompileTokenMetadata(identifier: directive.type),
        useClass: directive.type);
    _resolveProviders(
        [dirProvider],
        directive.isComponent
            ? ProviderAstType.Component
            : ProviderAstType.Directive,
        true,
        sourceSpan,
        targetErrors,
        providersByToken);
  });
  // Note: directives need to be able to overwrite providers of a component!
  var directivesWithComponentFirst =
      (new List.from(directives.where((dir) => dir.isComponent).toList())
        ..addAll(directives.where((dir) => !dir.isComponent).toList()));
  directivesWithComponentFirst.forEach((directive) {
    _resolveProviders(
        _normalizeProviders(directive.providers, sourceSpan, targetErrors),
        ProviderAstType.PublicService,
        false,
        sourceSpan,
        targetErrors,
        providersByToken);
    _resolveProviders(
        _normalizeProviders(directive.viewProviders, sourceSpan, targetErrors),
        ProviderAstType.PrivateService,
        false,
        sourceSpan,
        targetErrors,
        providersByToken);
  });
  return providersByToken;
}

_resolveProviders(
    List<CompileProviderMetadata> providers,
    ProviderAstType providerType,
    bool eager,
    ParseSourceSpan sourceSpan,
    List<ParseError> targetErrors,
    CompileTokenMap<ProviderAst> targetProvidersByToken) {
  providers.forEach((provider) {
    var resolvedProvider = targetProvidersByToken.get(provider.token);
    if (isPresent(resolvedProvider) &&
        !identical(resolvedProvider.multiProvider, provider.multi)) {
      targetErrors.add(new ProviderError(
          '''Mixing multi and non multi provider is not possible for token ${ resolvedProvider . token . name}''',
          sourceSpan));
    }
    if (isBlank(resolvedProvider)) {
      resolvedProvider = new ProviderAst(provider.token, provider.multi, eager,
          [provider], providerType, sourceSpan);
      targetProvidersByToken.add(provider.token, resolvedProvider);
    } else {
      if (!provider.multi) {
        ListWrapper.clear(resolvedProvider.providers);
      }
      resolvedProvider.providers.add(provider);
    }
  });
}

CompileTokenMap<List<CompileQueryMetadata>> _getViewQueries(
    CompileDirectiveMetadata component) {
  var viewQueries = new CompileTokenMap<List<CompileQueryMetadata>>();
  if (isPresent(component.viewQueries)) {
    component.viewQueries
        .forEach((query) => _addQueryToTokenMap(viewQueries, query));
  }
  component.type.diDeps.forEach((dep) {
    if (isPresent(dep.viewQuery)) {
      _addQueryToTokenMap(viewQueries, dep.viewQuery);
    }
  });
  return viewQueries;
}

CompileTokenMap<List<CompileQueryMetadata>> _getContentQueries(
    List<CompileDirectiveMetadata> directives) {
  var contentQueries = new CompileTokenMap<List<CompileQueryMetadata>>();
  directives.forEach((directive) {
    if (isPresent(directive.queries)) {
      directive.queries
          .forEach((query) => _addQueryToTokenMap(contentQueries, query));
    }
    directive.type.diDeps.forEach((dep) {
      if (isPresent(dep.query)) {
        _addQueryToTokenMap(contentQueries, dep.query);
      }
    });
  });
  return contentQueries;
}

_addQueryToTokenMap(CompileTokenMap<List<CompileQueryMetadata>> map,
    CompileQueryMetadata query) {
  query.selectors.forEach((CompileTokenMetadata token) {
    var entry = map.get(token);
    if (isBlank(entry)) {
      entry = [];
      map.add(token, entry);
    }
    entry.add(query);
  });
}
