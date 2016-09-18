import "../compile_metadata.dart"
    show
        CompileTokenMap,
        CompileDirectiveMetadata,
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
    show CompileQuery, createQueryList, addQueryToTokenMap;
import "compile_view.dart" show CompileView;
import "constants.dart" show InjectMethodVars;
import "view_compiler_utils.dart"
    show
        getPropertyInView,
        createDiTokenExpression,
        injectFromViewParentInjector,
        convertValueToOutputAst;

/// Compiled node in the view (such as text node) that is not an element.
class CompileNode {
  /// Parent of node.
  final CompileElement parent;
  final CompileView view;
  final num nodeIndex;

  /// Expression that resolves to reference to instance of of node.
  final o.Expression renderNode;

  /// Source location in template.
  final TemplateAst sourceAst;

  CompileNode(
      this.parent, this.view, this.nodeIndex, this.renderNode, this.sourceAst);

  /// Returns true if there is a reference to this node in the view.
  bool get hasRenderNode => renderNode != null;

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
  bool hasViewContainer;
  bool hasEmbeddedView;

  o.Expression _compViewExpr;
  o.ReadClassMemberExpr appElement;
  o.Expression elementRef;
  o.Expression injector;
  var _instances = new CompileTokenMap<o.Expression>();
  CompileTokenMap<ProviderAst> _resolvedProviders;
  var _queryCount = 0;
  var _queries = new CompileTokenMap<List<CompileQuery>>();
  List<o.Expression> _componentConstructorViewQueryLists = [];
  List<List<o.Expression>> contentNodesByNgContentIndex;
  CompileView embeddedView;
  List<o.Expression> directiveInstances;
  Map<String, CompileTokenMetadata> referenceTokens;

  CompileElement(
      CompileElement parent,
      CompileView view,
      num nodeIndex,
      o.Expression renderNode,
      this.renderNodeFieldName,
      TemplateAst sourceAst,
      this.component,
      this._directives,
      this._resolvedProvidersArray,
      this.hasViewContainer,
      this.hasEmbeddedView,
      List<ReferenceAst> references,
      {this.isHtmlElement: false})
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
    injector = o.THIS_EXPR.callMethod("injector", [o.literal(this.nodeIndex)]);
    _instances.add(identifierToken(Identifiers.Injector), this.injector);
    _instances.add(
        identifierToken(Identifiers.Renderer), o.THIS_EXPR.prop("renderer"));
    if (hasViewContainer || hasEmbeddedView || component != null) {
      this._createAppElement();
    }
  }

  CompileElement.root()
      : this(
            null, null, null, null, null, null, null, [], [], false, false, []);

  void _createAppElement() {
    var fieldName = '_appEl_${nodeIndex}';
    var parentNodeIndex = isRootElement ? null : parent.nodeIndex;

    // Create instance field for app element.
    view.fields.add(new o.ClassField(fieldName,
        outputType: o.importType(Identifiers.AppElement),
        modifiers: [o.StmtModifier.Private]));

    // Write code to create an instance of AppElement.
    // Example: this._appEl_2 = new import7.AppElement(2,0,this,this._anchor_2);
    var statement = new o.WriteClassMemberExpr(
        fieldName,
        o.importExpr(Identifiers.AppElement).instantiate([
          o.literal(nodeIndex),
          o.literal(parentNodeIndex),
          o.THIS_EXPR,
          renderNode
        ])).toStmt();
    view.createMethod.addStmt(statement);
    appElement = new o.ReadClassMemberExpr(fieldName);
    _instances.add(identifierToken(Identifiers.AppElement), appElement);
  }

  void setComponentView(o.Expression compViewExpr) {
    _compViewExpr = compViewExpr;
    int indexCount = component.template.ngContentSelectors.length;
    contentNodesByNgContentIndex = new List<List<o.Expression>>(indexCount);
    for (var i = 0; i < indexCount; i++) {
      this.contentNodesByNgContentIndex[i] = <o.Expression>[];
    }
  }

  void setEmbeddedView(CompileView view) {
    embeddedView = view;
    if (view != null) {
      var createTemplateRefExpr = o
          .importExpr(Identifiers.TemplateRef)
          .instantiate([this.appElement, view.viewFactory]);
      var provider = new CompileProviderMetadata(
          token: identifierToken(Identifiers.TemplateRef),
          useValue: createTemplateRefExpr);
      // Add TemplateRef as first provider as it does not have deps on other
      // providers
      _resolvedProvidersArray
        ..insert(
            0,
            new ProviderAst(provider.token, false, true, [provider],
                ProviderAstType.Builtin, this.sourceAst.sourceSpan));
    }
  }

  void beforeChildren() {
    if (hasViewContainer) {
      _instances.add(identifierToken(Identifiers.ViewContainerRef),
          this.appElement.prop("vcRef"));
    }
    _resolvedProviders = new CompileTokenMap<ProviderAst>();
    _resolvedProvidersArray.forEach(
        (provider) => _resolvedProviders.add(provider.token, provider));

    // create all the provider instances, some in the view constructor,
    // some as getters. We rely on the fact that they are already sorted
    // topologically.
    _resolvedProviders.values().forEach((resolvedProvider) {
      var providerValueExpressions = resolvedProvider.providers.map((provider) {
        o.Expression providerValue;
        if (provider.useExisting != null) {
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
        if (provider.useProperty != null) {
          providerValue = providerValue.prop(provider.useProperty);
        }
        return providerValue;
      }).toList();
      var propName =
          '_${resolvedProvider.token.name}_${nodeIndex}_${_instances.size}';
      var instance = createProviderProperty(
          propName,
          resolvedProvider,
          providerValueExpressions,
          resolvedProvider.multiProvider,
          resolvedProvider.eager,
          this);
      this._instances.add(resolvedProvider.token, instance);
    });

    directiveInstances = <o.Expression>[];
    for (var directive in _directives) {
      var directiveInstance = _instances.get(identifierToken(directive.type));
      directiveInstances.add(directiveInstance);
      directive.queries.forEach((queryMeta) {
        _addQuery(queryMeta, directiveInstance);
      });
    }

    List<_QueryWithRead> queriesWithReads = [];
    _resolvedProviders.values().forEach((resolvedProvider) {
      var queriesForProvider = this._getQueriesFor(resolvedProvider.token);
      queriesWithReads.addAll(queriesForProvider
          .map((query) => new _QueryWithRead(query, resolvedProvider.token)));
    });

    if (referenceTokens != null) {
      referenceTokens.forEach((String varName, token) {
        var varValue = token != null ? _instances.get(token) : renderNode;
        view.locals[varName] = varValue;
        var varToken = new CompileTokenMetadata(value: varName);
        queriesWithReads.addAll(_getQueriesFor(varToken)
            .map((query) => new _QueryWithRead(query, varToken)));
      });
    }

    queriesWithReads.forEach((queryWithRead) {
      o.Expression value;
      if (queryWithRead.read.identifier != null) {
        // query for an identifier
        value = _instances.get(queryWithRead.read);
      } else {
        // query for a reference
        var token = (referenceTokens != null)
            ? referenceTokens[queryWithRead.read.value]
            : null;
        value = token != null ? _instances.get(token) : elementRef;
      }
      if (value != null) {
        queryWithRead.query.addValue(value, this.view);
      }
    });

    if (component != null) {
      var componentConstructorViewQueryList =
          o.literalArr(_componentConstructorViewQueryLists);
      var compExpr = getComponent() ?? o.NULL_EXPR;
      view.createMethod.addStmt(this.appElement.callMethod("initComponent", [
        compExpr,
        componentConstructorViewQueryList,
        _compViewExpr
      ]).toStmt());
    }
  }

  void afterChildren(num childNodeCount) {
    _resolvedProviders.values().forEach((resolvedProvider) {
      // Note: afterChildren is called after recursing into children.
      // This is good so that an injector match in an element that is closer to
      // a requesting element matches first.
      var providerExpr = _instances.get(resolvedProvider.token);

      // Note: view providers are only visible on the injector of that element.
      // This is not fully correct as the rules during codegen don't allow a
      // directive to get hold of a view provdier on the same element. We still
      // do this semantic as it simplifies our model to having only one runtime
      // injector per element.
      var providerChildNodeCount =
          resolvedProvider.providerType == ProviderAstType.PrivateService
              ? 0
              : childNodeCount;
      view.injectorGetMethod.addStmt(createInjectInternalCondition(
          nodeIndex, providerChildNodeCount, resolvedProvider, providerExpr));
    });
    _queries.values().forEach((queries) => queries.forEach((query) => query
        .afterChildren(view.createMethod, view.updateContentQueriesMethod)));
  }

  void addContentNode(num ngContentIndex, o.Expression nodeExpr) {
    contentNodesByNgContentIndex[ngContentIndex].add(nodeExpr);
  }

  o.Expression getComponent() => component != null
      ? _instances.get(identifierToken(component.type))
      : null;

  List<o.Expression> getProviderTokens() {
    return _resolvedProviders
        .values()
        .map((resolvedProvider) =>
            createDiTokenExpression(resolvedProvider.token))
        .toList();
  }

  List<CompileQuery> _getQueriesFor(CompileTokenMetadata token) {
    List<CompileQuery> result = [];
    CompileElement currentEl = this;
    var distance = 0;
    List<CompileQuery> queries;
    while (currentEl.hasRenderNode) {
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
        createQueryList(queryMeta, directiveInstance, propName, view);
    var query = new CompileQuery(queryMeta, queryList, directiveInstance, view);
    addQueryToTokenMap(this._queries, query);
    return query;
  }

  o.Expression _getLocalDependency(
      ProviderAstType requestingProviderType, CompileDiDependencyMetadata dep) {
    o.Expression result;
    // constructor content query
    if (result == null && dep.query != null) {
      result = _addQuery(dep.query, null).queryList;
    }
    // constructor view query
    if (result == null && dep.viewQuery != null) {
      result = createQueryList(
          dep.viewQuery,
          null,
          '_viewQuery_${dep.viewQuery.selectors[0].name}_'
          '${nodeIndex}_${_componentConstructorViewQueryLists.length}',
          view);
      _componentConstructorViewQueryLists.add(result);
    }

    if (dep.token != null) {
      // access builtins with special visibility
      if (result == null) {
        if (dep.token
            .equalsTo(identifierToken(Identifiers.ChangeDetectorRef))) {
          if (identical(requestingProviderType, ProviderAstType.Component)) {
            return _compViewExpr.prop("ref");
          } else {
            return new o.ReadClassMemberExpr('ref');
          }
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
    while (result == null && currElement.parent.hasRenderNode) {
      currElement = currElement.parent;
      result = currElement._getLocalDependency(ProviderAstType.PublicService,
          new CompileDiDependencyMetadata(token: dep.token));
    }
    result ??= injectFromViewParentInjector(dep.token, dep.isOptional);
    result ??= o.NULL_EXPR;
    return getPropertyInView(result, view, currElement.view);
  }
}

o.Statement createInjectInternalCondition(num nodeIndex, num childNodeCount,
    ProviderAst provider, o.Expression providerExpr) {
  var indexCondition;
  if (childNodeCount > 0) {
    indexCondition = o
        .literal(nodeIndex)
        .lowerEquals(InjectMethodVars.requestNodeIndex)
        .and(InjectMethodVars.requestNodeIndex
            .lowerEquals(o.literal(nodeIndex + childNodeCount)));
  } else {
    indexCondition =
        o.literal(nodeIndex).identical(InjectMethodVars.requestNodeIndex);
  }
  return new o.IfStmt(
      InjectMethodVars.token
          .identical(createDiTokenExpression(provider.token))
          .and(indexCondition),
      [new o.ReturnStatement(providerExpr)]);
}

o.Expression createProviderProperty(
    String propName,
    ProviderAst provider,
    List<o.Expression> providerValueExpressions,
    bool isMulti,
    bool isEager,
    CompileElement compileElement) {
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
    view.fields.add(new o.ClassField(propName,
        outputType: type, modifiers: const [o.StmtModifier.Private]));
    view.createMethod.addStmt(
        new o.WriteClassMemberExpr(propName, resolvedProviderValueExpr)
            .toStmt());
  } else {
    var internalField = '_${propName}';
    view.fields.add(new o.ClassField(internalField,
        outputType: type, modifiers: const [o.StmtModifier.Private]));
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
    view.getters.add(new o.ClassGetter(propName, getter.finish(), type));
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
