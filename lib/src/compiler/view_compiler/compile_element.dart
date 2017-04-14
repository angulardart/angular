import "../compile_metadata.dart"
    show
        CompileTokenMap,
        CompileDirectiveMetadata,
        CompileIdentifierMetadata,
        CompileTokenMetadata,
        CompileQueryMetadata,
        CompileProviderMetadata,
        CompileDiDependencyMetadata;
import "../identifiers.dart" show Identifiers, identifierToken;
import "../output/output_ast.dart" as o;
import "../template_ast.dart"
    show TemplateAst, ProviderAst, ProviderAstType, ReferenceAst;
import "compile_method.dart" show CompileMethod;
import "compile_query.dart"
    show CompileQuery, createQueryListField, addQueryToTokenMap;
import "compile_view.dart" show CompileView;
import "constants.dart" show InjectMethodVars;
import "view_compiler_utils.dart"
    show
        getPropertyInView,
        getViewFactoryName,
        createDiTokenExpression,
        injectFromViewParentInjector,
        convertValueToOutputAst;

/// Compiled node in the view (such as text node) that is not an element.
class CompileNode {
  /// Parent of node.
  final CompileElement parent;
  final CompileView view;
  final int nodeIndex;

  /// Expression that resolves to reference to instance of of node.
  final o.Expression renderNode;

  /// Source location in template.
  final TemplateAst sourceAst;

  CompileNode(
      this.parent, this.view, this.nodeIndex, this.renderNode, this.sourceAst);

  /// Whether node is the root of the view.
  bool get isRootElement => view != parent.view;
}

/// Compiled element in the view.
class CompileElement extends CompileNode {
  final String renderNodeFieldName;
  // If true, we know for sure it is html and not svg or other type
  // so we can create code for more exact type HtmlElement.
  final bool isHtmlElement;
  CompileDirectiveMetadata component;
  List<CompileDirectiveMetadata> _directives;
  List<ProviderAst> _resolvedProvidersArray;
  final bool hasViewContainer;
  final bool hasEmbeddedView;
  final bool hasTemplateRefQuery;

  /// Expression that contains reference to componentView.
  o.Expression compViewExpr;
  o.ReadClassMemberExpr appViewContainer;
  o.Expression elementRef;
  var _instances = new CompileTokenMap<o.Expression>();

  /// We track which providers are just 'useExisting' for another provider on
  /// this component. This way, we can detect when we don't need to generate
  /// a getter for them.
  var _aliases = new CompileTokenMap<List<CompileTokenMetadata>>();
  var _aliasedProviders = new CompileTokenMap<CompileTokenMetadata>();
  CompileTokenMap<ProviderAst> _resolvedProviders;
  var _queryCount = 0;
  var _queries = new CompileTokenMap<List<CompileQuery>>();
  List<List<o.Expression>> contentNodesByNgContentIndex;
  CompileView embeddedView;
  List<o.Expression> directiveInstances;
  Map<String, CompileTokenMetadata> referenceTokens;
  // If compile element is a template and has #ref resolving to TemplateRef
  // this is set so we create a class field member for the template reference.
  bool _publishesTemplateRef = false;

  CompileElement(
      CompileElement parent,
      CompileView view,
      int nodeIndex,
      o.Expression renderNode,
      this.renderNodeFieldName,
      TemplateAst sourceAst,
      this.component,
      this._directives,
      this._resolvedProvidersArray,
      this.hasViewContainer,
      this.hasEmbeddedView,
      List<ReferenceAst> references,
      {this.isHtmlElement: false,
      this.hasTemplateRefQuery: false})
      : super(parent, view, nodeIndex, renderNode, sourceAst) {
    if (references.isNotEmpty) {
      referenceTokens = <String, CompileTokenMetadata>{};
      int referenceCount = references.length;
      for (int r = 0; r < referenceCount; r++) {
        var ref = references[r];
        referenceTokens[ref.name] = ref.value;
      }
    }
    elementRef =
        o.importExpr(Identifiers.ElementRef).instantiate([this.renderNode]);
    _instances.add(identifierToken(Identifiers.ElementRef), this.elementRef);
    var readInjectorExpr =
        new o.InvokeMemberMethodExpr('injector', [o.literal(this.nodeIndex)]);
    _instances.add(identifierToken(Identifiers.Injector), readInjectorExpr);
    if (hasViewContainer || hasEmbeddedView) {
      _createViewContainer();
    }
  }

  CompileElement.root()
      : this(
            null, null, null, null, null, null, null, [], [], false, false, []);

  void _createViewContainer() {
    var fieldName = '_appEl_${nodeIndex}';
    var parentNodeIndex = isRootElement ? null : parent.nodeIndex;

    // Create instance field for app element.
    view.fields.add(new o.ClassField(fieldName,
        outputType: o.importType(Identifiers.ViewContainer),
        modifiers: [o.StmtModifier.Private]));

    // Write code to create an instance of ViewContainer.
    // Example:
    //     this._appEl_2 = new import7.ViewContainer(2,0,this,this._anchor_2);
    var statement = new o.WriteClassMemberExpr(
        fieldName,
        o.importExpr(Identifiers.ViewContainer).instantiate([
          o.literal(nodeIndex),
          o.literal(parentNodeIndex),
          o.THIS_EXPR,
          renderNode
        ])).toStmt();
    view.createMethod.addStmt(statement);
    appViewContainer = new o.ReadClassMemberExpr(fieldName);
    _instances.add(
        identifierToken(Identifiers.ViewContainer), appViewContainer);
    if (hasViewContainer) {
      view.viewContainers.add(appViewContainer);
    }
  }

  set componentView(o.Expression compViewExpr) {
    this.compViewExpr = compViewExpr;
    int indexCount = component.template.ngContentSelectors.length;
    contentNodesByNgContentIndex = new List<List<o.Expression>>(indexCount);
    for (var i = 0; i < indexCount; i++) {
      this.contentNodesByNgContentIndex[i] = <o.Expression>[];
    }
  }

  o.Expression get componentView => compViewExpr;

  void setEmbeddedView(CompileView view) {
    embeddedView = view;
    if (view != null) {
      var createTemplateRefExpr = o
          .importExpr(Identifiers.TemplateRef)
          .instantiate([this.appViewContainer, view.viewFactory],
              o.importType(Identifiers.TemplateRef));
      var provider = new CompileProviderMetadata(
          token: identifierToken(Identifiers.TemplateRef),
          useValue: createTemplateRefExpr);

      bool isReachable = false;
      if (_getQueriesFor(identifierToken(Identifiers.TemplateRef)).isNotEmpty) {
        isReachable = true;
      }
      // Add TemplateRef as first provider as it does not have deps on other
      // providers
      _resolvedProvidersArray
        ..insert(
            0,
            new ProviderAst(provider.token, false, [provider],
                ProviderAstType.Builtin, this.sourceAst.sourceSpan,
                eager: true, dynamicallyReachable: isReachable));
    }
  }

  void beforeChildren(bool componentIsDeferred) {
    if (hasViewContainer) {
      _instances.add(
          identifierToken(Identifiers.ViewContainerRef), appViewContainer);
    }

    if (referenceTokens != null) {
      referenceTokens.forEach((String varName, token) {
        if (token != null &&
            token.equalsTo(identifierToken(Identifiers.TemplateRef))) {
          _publishesTemplateRef = true;
        }
      });
    }

    _prepareProviderInstances(componentIsDeferred);

    directiveInstances = <o.Expression>[];
    for (var directive in _directives) {
      var directiveInstance = _instances.get(identifierToken(directive.type));
      directiveInstances.add(directiveInstance);
      directive.queries.forEach((queryMeta) {
        _addQuery(queryMeta, directiveInstance);
      });
    }

    List<_QueryWithRead> queriesWithReads = [];
    for (var resolvedProvider in _resolvedProviders.values) {
      var queriesForProvider = _getQueriesFor(resolvedProvider.token);
      queriesWithReads.addAll(queriesForProvider
          .map((query) => new _QueryWithRead(query, resolvedProvider.token)));
    }

    // For each reference token create CompileTokenMetadata to read query.
    if (referenceTokens != null) {
      referenceTokens.forEach((String varName, token) {
        var varValue = token != null ? _instances.get(token) : renderNode;
        view.locals[varName] = varValue;
        var varToken = new CompileTokenMetadata(value: varName);
        queriesWithReads.addAll(_getQueriesFor(varToken)
            .map((query) => new _QueryWithRead(query, varToken)));
      });
    }

    // For all @ViewChild(... read: Type) and references that map to locals,
    // resolve value.
    for (_QueryWithRead queryWithRead in queriesWithReads) {
      o.Expression value;
      if (queryWithRead.read.identifier != null) {
        // query for an identifier
        value = _instances.get(queryWithRead.read);
      } else {
        // query for a reference
        var token = (referenceTokens != null)
            ? referenceTokens[queryWithRead.read.value]
            : null;
        // elementRef contains expression of the form new ElementRef(...).
        value = token != null ? _instances.get(token) : elementRef;
      }
      if (value != null) {
        queryWithRead.query.addValue(value, this.view);
      }
    }
  }

  bool get publishesTemplateRef => _publishesTemplateRef;

  void _prepareProviderInstances(bool componentIsDeferred) {
    // Create a lookup map from token to provider.
    _resolvedProviders = new CompileTokenMap<ProviderAst>();
    for (ProviderAst provider in _resolvedProvidersArray) {
      _resolvedProviders.add(provider.token, provider);
    }
    // Create all the provider instances, some in the view constructor (eager),
    // some as getters (eager=false). We rely on the fact that they are
    // already sorted topologically.
    for (ProviderAst resolvedProvider in _resolvedProviders.values) {
      var providerValueExpressions = <o.Expression>[];
      var isLocalAlias = false;
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
          providerValue = _getDependency(resolvedProvider.providerType,
              new CompileDiDependencyMetadata(token: provider.useExisting));
        } else if (provider.useFactory != null) {
          var deps = provider.deps ?? provider.useFactory.diDeps;
          var depsExpr = deps
              .map((dep) => _getDependency(resolvedProvider.providerType, dep))
              .toList();
          providerValue = o.importExpr(provider.useFactory).callFn(depsExpr);
        } else if (provider.useClass != null) {
          var deps = provider.deps ?? provider.useClass.diDeps;
          var depsExpr = deps
              .map((dep) => _getDependency(resolvedProvider.providerType, dep))
              .toList();
          providerValue = o
              .importExpr(provider.useClass)
              .instantiate(depsExpr, o.importType(provider.useClass));
        } else {
          providerValue = convertValueToOutputAst(provider.useValue);
        }
        providerValueExpressions.add(providerValue);
      }
      if (isLocalAlias) {
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
        var propName =
            '_${resolvedProvider.token.name}_${nodeIndex}_${_instances.size}';
        var instance = createProviderProperty(
            propName,
            resolvedProvider,
            providerValueExpressions,
            resolvedProvider.multiProvider,
            resolvedProvider.eager,
            this,
            forceDynamic:
                (resolvedProvider.providerType == ProviderAstType.Component) &&
                    componentIsDeferred);
        _instances.add(resolvedProvider.token, instance);
      }
    }
  }

  void afterChildren(int childNodeCount) {
    for (ProviderAst resolvedProvider in _resolvedProviders.values) {
      if (!resolvedProvider.dynamicallyReachable ||
          !resolvedProvider.visibleToViewHierarchy ||
          _aliasedProviders.containsKey(resolvedProvider.token)) continue;

      // Note: afterChildren is called after recursing into children.
      // This is good so that an injector match in an element that is closer to
      // a requesting element matches first.
      var providerExpr = _instances.get(resolvedProvider.token);

      var aliases = _aliases.get(resolvedProvider.token);

      // Note: view providers are only visible on the injector of that element.
      // This is not fully correct as the rules during codegen don't allow a
      // directive to get hold of a view provider on the same element. We still
      // do this semantic as it simplifies our model to having only one runtime
      // injector per element.
      var providerChildNodeCount =
          resolvedProvider.providerType == ProviderAstType.PrivateService
              ? 0
              : childNodeCount;
      view.injectorGetMethod.addStmt(_createInjectInternalCondition(nodeIndex,
          providerChildNodeCount, resolvedProvider, providerExpr, aliases));
    }
    for (List<CompileQuery> queries in _queries.values) {
      for (CompileQuery query in queries) {
        query.generateImmediateUpdate(view.createMethod);
        query.generateDynamicUpdate(view.updateContentQueriesMethod);
      }
    }
  }

  void writeDeferredLoader(CompileView embeddedView,
      o.Expression viewContainerExpr, List<o.Statement> stmts) {
    CompileElement deferredElement = embeddedView.nodes[0] as CompileElement;
    CompileDirectiveMetadata deferredMeta = deferredElement.component;
    String deferredModuleUrl = deferredMeta.identifier.moduleUrl;
    String prefix = deferredMeta.identifier.prefix ??
        embeddedView.deferredModules[deferredModuleUrl];
    String templatePrefix;
    if (prefix == null) {
      prefix = 'deflib${embeddedView.deferredModules.length}';
      embeddedView.deferredModules[deferredModuleUrl] = prefix;
      templatePrefix = 'deflib${view.deferredModules.length}';
      embeddedView.deferredModules[_toTemplateExtension(deferredModuleUrl)] =
          templatePrefix;
    }

    CompileIdentifierMetadata componentId = deferredMeta.identifier;
    CompileIdentifierMetadata prefixedId = new CompileIdentifierMetadata(
        runtime: componentId.runtime,
        runtimeCallback: componentId.runtimeCallback,
        name: '',
        moduleUrl: componentId.moduleUrl,
        prefix: prefix,
        emitPrefix: true,
        value: componentId.value);

    CompileIdentifierMetadata nestedComponentId = new CompileIdentifierMetadata(
        name: getViewFactoryName(deferredElement.component, 0));
    CompileIdentifierMetadata templatePrefixId = new CompileIdentifierMetadata(
        runtime: nestedComponentId.runtime,
        runtimeCallback: nestedComponentId.runtimeCallback,
        name: 'loadLibrary',
        moduleUrl: nestedComponentId.moduleUrl,
        prefix: templatePrefix,
        emitPrefix: true,
        value: nestedComponentId.value);

    CompileIdentifierMetadata templateInitializer =
        new CompileIdentifierMetadata(
            runtime: nestedComponentId.runtime,
            runtimeCallback: nestedComponentId.runtimeCallback,
            name: 'initReflector',
            moduleUrl: nestedComponentId.moduleUrl,
            prefix: templatePrefix,
            emitPrefix: true,
            value: nestedComponentId.value);

    var templateRefExpr =
        _instances.get(identifierToken(Identifiers.TemplateRef));

    var initializerExpr = new o.FunctionExpr(const [], <o.Statement>[
      o.importDeferred(templateInitializer).callFn(const []).toStmt()
    ], null);

    stmts.add(new o.InvokeMemberMethodExpr('loadDeferred', [
      o.importDeferred(prefixedId).prop('loadLibrary'),
      o.importDeferred(templatePrefixId),
      viewContainerExpr,
      templateRefExpr,
      initializerExpr
    ]).toStmt());
  }

  String _toTemplateExtension(String moduleUrl) {
    if (!moduleUrl.endsWith('.dart')) return moduleUrl;
    return moduleUrl.substring(0, moduleUrl.length - 5) + '.template.dart';
  }

  void addContentNode(num ngContentIndex, o.Expression nodeExpr) {
    contentNodesByNgContentIndex[ngContentIndex].add(nodeExpr);
  }

  o.Expression getComponent() => component != null
      ? _instances.get(identifierToken(component.type))
      : null;

  List<o.Expression> getProviderTokens() {
    return _resolvedProviders.values
        .map((resolvedProvider) =>
            createDiTokenExpression(resolvedProvider.token))
        .toList();
  }

  List<CompileQuery> _getQueriesFor(CompileTokenMetadata token) {
    List<CompileQuery> result = [];
    CompileElement currentEl = this;
    var distance = 0;
    List<CompileQuery> queries;
    while (currentEl.parent != null) {
      queries = currentEl._queries.get(token);
      if (queries != null) {
        result.addAll(
            queries.where((query) => query.meta.descendants || distance <= 1));
      }
      if (currentEl._directives.length > 0) {
        distance++;
      }
      currentEl = currentEl.parent;
    }
    queries = this.view.componentView.viewQueries.get(token);
    if (queries != null) result.addAll(queries);
    return result;
  }

  CompileQuery _addQuery(
      CompileQueryMetadata queryMeta, o.Expression directiveInstance) {
    var propName =
        '_query_${queryMeta.selectors[0].name}_${nodeIndex}_${_queryCount++}';
    var queryList =
        createQueryListField(queryMeta, directiveInstance, propName, view);
    var query = new CompileQuery(queryMeta, queryList, directiveInstance, view);
    addQueryToTokenMap(this._queries, query);
    return query;
  }

  o.Expression _getLocalDependency(
      ProviderAstType requestingProviderType, CompileDiDependencyMetadata dep) {
    o.Expression result;
    if (dep.token != null) {
      // access builtins with special visibility
      if (dep.token.equalsTo(identifierToken(Identifiers.ChangeDetectorRef))) {
        if (identical(requestingProviderType, ProviderAstType.Component)) {
          return compViewExpr.prop("ref");
        } else {
          return new o.ReadClassMemberExpr('ref');
        }
      }
      // access regular providers on the element
      result ??= _instances.get(dep.token);
    }
    return result;
  }

  o.Expression _getDependency(
      ProviderAstType requestingProviderType, CompileDiDependencyMetadata dep) {
    CompileElement currElement = this;
    var result;
    if (dep.isValue) {
      result = o.literal(dep.value);
    }
    if (result == null && !dep.isSkipSelf) {
      result = _getLocalDependency(requestingProviderType, dep);
    }

    // check parent elements
    while (result == null && currElement.parent.parent != null) {
      currElement = currElement.parent;
      result = currElement._getLocalDependency(ProviderAstType.PublicService,
          new CompileDiDependencyMetadata(token: dep.token));
    }
    result ??= injectFromViewParentInjector(view, dep.token, dep.isOptional);
    result ??= o.NULL_EXPR;
    return getPropertyInView(result, view, currElement.view);
  }
}

o.Statement _createInjectInternalCondition(
    int nodeIndex,
    int childNodeCount,
    ProviderAst provider,
    o.Expression providerExpr,
    List<CompileTokenMetadata> aliases) {
  var indexCondition;
  if (childNodeCount > 0) {
    indexCondition = o
        .literal(nodeIndex)
        .lowerEquals(InjectMethodVars.nodeIndex)
        .and(InjectMethodVars.nodeIndex
            .lowerEquals(o.literal(nodeIndex + childNodeCount)));
  } else {
    indexCondition = o.literal(nodeIndex).equals(InjectMethodVars.nodeIndex);
  }
  o.Expression tokenCondition =
      InjectMethodVars.token.identical(createDiTokenExpression(provider.token));
  if (aliases != null) {
    for (var alias in aliases) {
      tokenCondition = tokenCondition
          .or(InjectMethodVars.token.identical(createDiTokenExpression(alias)));
    }
  }

  return new o.IfStmt(tokenCondition.and(indexCondition),
      [new o.ReturnStatement(providerExpr)]);
}

/// Creates a class field and assigns the resolvedProviderValueExpr.
///
/// Eager Example:
///   _TemplateRef_9_4 = new TemplateRef(_appEl_9,viewFactory_SampleComponent7);
///
/// Lazy:
///
/// TemplateRef _TemplateRef_9_4;
///
o.Expression createProviderProperty(
    String propName,
    ProviderAst provider,
    List<o.Expression> providerValueExpressions,
    bool isMulti,
    bool isEager,
    CompileElement compileElement,
    {bool forceDynamic: false}) {
  var view = compileElement.view;
  var resolvedProviderValueExpr;
  var type;
  if (isMulti) {
    resolvedProviderValueExpr = o.literalArr(providerValueExpressions);
    type = new o.ArrayType(o.DYNAMIC_TYPE);
  } else {
    resolvedProviderValueExpr = providerValueExpressions[0];
    type = providerValueExpressions[0].type;
  }

  type ??= o.DYNAMIC_TYPE;

  if (isEager) {
    if (compileElement.publishesTemplateRef ||
        compileElement.hasTemplateRefQuery ||
        provider.dynamicallyReachable) {
      view.fields.add(new o.ClassField(propName,
          outputType: forceDynamic ? o.DYNAMIC_TYPE : type,
          modifiers: const [o.StmtModifier.Private]));
      view.createMethod.addStmt(
          new o.WriteClassMemberExpr(propName, resolvedProviderValueExpr)
              .toStmt());
    } else {
      // Since provider is not dynamically reachable and we only need
      // the provider locally in build, create a local var.
      var localVar = o.variable(propName, forceDynamic ? o.DYNAMIC_TYPE : type);
      view.createMethod
          .addStmt(localVar.set(resolvedProviderValueExpr).toDeclStmt());
      return localVar;
    }
  } else {
    var internalField = '_$propName';
    view.fields.add(new o.ClassField(internalField,
        outputType: forceDynamic ? o.DYNAMIC_TYPE : type,
        modifiers: const [o.StmtModifier.Private]));
    var getter = new CompileMethod(view);
    getter.resetDebugInfo(compileElement.nodeIndex, compileElement.sourceAst);
    // Note: Equals is important for JS so that it also checks the undefined case!
    getter.addStmt(new o.IfStmt(
        new o.ReadClassMemberExpr(internalField).isBlank(), [
      new o.WriteClassMemberExpr(internalField, resolvedProviderValueExpr)
          .toStmt()
    ]));
    getter.addStmt(
        new o.ReturnStatement(new o.ReadClassMemberExpr(internalField)));
    view.getters.add(new o.ClassGetter(
        propName, getter.finish(), forceDynamic ? o.DYNAMIC_TYPE : type));
  }
  return new o.ReadClassMemberExpr(propName);
}

class _QueryWithRead {
  CompileQuery query;
  CompileTokenMetadata read;
  _QueryWithRead(this.query, CompileTokenMetadata match) {
    read = query.meta.read ?? match;
  }
}
