import 'package:angular/src/core/linker/view_type.dart';
import 'package:angular_compiler/cli.dart';

import '../compile_metadata.dart'
    show
        CompileTokenMap,
        CompileDirectiveMetadata,
        CompileIdentifierMetadata,
        CompileTokenMetadata,
        CompileQueryMetadata,
        CompileProviderMetadata;
import '../identifiers.dart' show Identifiers, identifierToken;
import '../output/output_ast.dart' as o;
import '../template_ast.dart'
    show TemplateAst, ProviderAst, ProviderAstType, ReferenceAst, ElementAst;
import 'compile_query.dart' show CompileQuery, addQueryToTokenMap;
import 'compile_view.dart' show CompileView, NodeReference;
import 'ir/provider_source.dart';
import 'ir/providers_node.dart';
import 'view_compiler_utils.dart'
    show
        createDiTokenExpression,
        injectFromViewParentInjector,
        getPropertyInView,
        getViewFactoryName,
        toTemplateExtension;

/// Compiled node in the view (such as text node) that is not an element.
class CompileNode {
  /// Parent of node.
  final CompileElement parent;
  final CompileView view;
  final int nodeIndex;

  /// Expression that resolves to reference to instance of of node.
  final NodeReference renderNode;

  /// Source location in template.
  final TemplateAst sourceAst;

  CompileNode(
      this.parent, this.view, this.nodeIndex, this.renderNode, this.sourceAst);

  /// Whether node is the root of the view.
  bool get isRootElement => view != parent.view;
}

/// Compiled element in the view.
class CompileElement extends CompileNode implements ProvidersNodeHost {
  // If true, we know for sure it is html and not svg or other type
  // so we can create code for more exact type HtmlElement.
  final bool isHtmlElement;
  // CompileElement either is an html element or is an angular component.
  // This member is populated when element is host of a component.
  final CompileDirectiveMetadata component;
  final List<CompileDirectiveMetadata> _directives;
  List<ProviderAst> _resolvedProvidersArray;
  final bool hasViewContainer;
  final bool hasEmbeddedView;
  final bool hasTemplateRefQuery;
  final bool isInlined;
  final bool isDeferredComponent;

  /// Reference to optional view container created for this element.
  o.ReadClassMemberExpr appViewContainer;
  o.Expression elementRef;

  /// Expression that contains reference to componentView (root View class).
  o.Expression _compViewExpr;

  var _queryCount = 0;
  final _queries = new CompileTokenMap<List<CompileQuery>>();
  ProvidersNode _providers;

  List<List<o.Expression>> contentNodesByNgContentIndex;
  CompileView embeddedView;
  List<ProviderSource> directiveInstances;
  Map<String, CompileTokenMetadata> referenceTokens;
  // If compile element is a template and has #ref resolving to TemplateRef
  // this is set so we create a class field member for the template reference.
  bool _publishesTemplateRef = false;

  CompileElement(
      CompileElement parent,
      CompileView view,
      int nodeIndex,
      NodeReference renderNode,
      TemplateAst sourceAst,
      this.component,
      this._directives,
      this._resolvedProvidersArray,
      this.hasViewContainer,
      this.hasEmbeddedView,
      List<ReferenceAst> references,
      {this.isHtmlElement: false,
      this.hasTemplateRefQuery: false,
      this.isInlined: false,
      this.isDeferredComponent: false})
      : super(parent, view, nodeIndex, renderNode, sourceAst) {
    _providers = new ProvidersNode(this, parent?._providers,
        view == null || view.viewType == ViewType.HOST);
    if (references.isNotEmpty) {
      referenceTokens = <String, CompileTokenMetadata>{};
      int referenceCount = references.length;
      for (int r = 0; r < referenceCount; r++) {
        var ref = references[r];
        referenceTokens[ref.name] = ref.value;
      }
    }
    // Create new ElementRef(_el_#) expression and provide as instance.
    elementRef = o
        .importExpr(Identifiers.ElementRef)
        .instantiate([renderNode.toReadExpr()]);

    _providers.add(Identifiers.ElementRefToken, this.elementRef);
    _providers.add(Identifiers.ElementToken, renderNode.toReadExpr());
    _providers.add(Identifiers.HtmlElementToken, renderNode.toReadExpr());
    var readInjectorExpr =
        new o.InvokeMemberMethodExpr('injector', [o.literal(this.nodeIndex)]);
    _providers.add(Identifiers.InjectorToken, readInjectorExpr);

    if ((hasViewContainer || hasEmbeddedView) && !isInlined) {
      appViewContainer = view.createViewContainer(renderNode, nodeIndex,
          !hasViewContainer, isRootElement ? null : parent.nodeIndex);
      _providers.add(Identifiers.ViewContainerToken, appViewContainer);
    }
  }

  CompileElement.root()
      : this(null, null, null, new NodeReference.appViewRoot(), null, null, [],
            [], false, false, []);

  set componentView(o.Expression componentViewExpr) {
    _compViewExpr = componentViewExpr;
    int indexCount = component.template.ngContentSelectors.length;
    contentNodesByNgContentIndex = new List<List<o.Expression>>(indexCount);
    for (var i = 0; i < indexCount; i++) {
      contentNodesByNgContentIndex[i] = <o.Expression>[];
    }
  }

  /// Returns expression with reference to root component view.
  o.Expression get componentView => _compViewExpr;

  void setEmbeddedView(CompileView view) {
    if (!isInlined) {
      if (appViewContainer == null) {
        throw new StateError('Expecting appView container to host view');
      }
      if (view.viewFactory == null) {
        throw new StateError('Expecting viewFactory initialization before '
            'embedding view');
      }
    }
    embeddedView = view;
    if (view != null && !view.isInlined) {
      var createTemplateRefExpr = o
          .importExpr(Identifiers.TemplateRef)
          .instantiate([this.appViewContainer, view.viewFactory],
              o.importType(Identifiers.TemplateRef));
      var provider = new CompileProviderMetadata(
          token: identifierToken(Identifiers.TemplateRef),
          useValue: createTemplateRefExpr);

      bool isReachable = false;
      if (_getQueriesFor(Identifiers.TemplateRefToken).isNotEmpty) {
        isReachable = true;
      }
      // Add TemplateRef as first provider as it does not have deps on other
      // providers
      _resolvedProvidersArray
        ..insert(
            0,
            new ProviderAst(
              provider.token,
              false,
              [provider],
              ProviderAstType.Builtin,
              this.sourceAst.sourceSpan,
              eager: true,
              dynamicallyReachable: isReachable,
            ));
    }
  }

  void beforeChildren() {
    if (hasViewContainer &&
        !_providers.containsLocalProvider(Identifiers.ViewContainerRefToken)) {
      _providers.add(Identifiers.ViewContainerRefToken, appViewContainer);
    }

    if (referenceTokens != null) {
      referenceTokens.forEach((String varName, token) {
        if (token != null && token.equalsTo(Identifiers.TemplateRefToken)) {
          _publishesTemplateRef = true;
        }
      });
    }

    // Access builtins with special visibility.
    if (component != null) {
      _providers.add(
          Identifiers.ChangeDetectorRefToken, _compViewExpr.prop('ref'));
    } else {
      _providers.add(
          Identifiers.ChangeDetectorRefToken, new o.ReadClassMemberExpr('ref'));
    }

    // ComponentLoader is currently just an alias for ViewContainerRef with
    // a smaller API that is also usable outside of the context of a
    // structural directive.
    if (appViewContainer != null) {
      _providers.add(Identifiers.ComponentLoaderToken, appViewContainer);
    }
    _providers.addDirectiveProviders(_resolvedProvidersArray, _directives);

    directiveInstances = <ProviderSource>[];
    for (var directive in _directives) {
      var directiveInstance = _providers.get(identifierToken(directive.type));
      directiveInstances.add(directiveInstance);
      for (var queryMeta in directive.queries) {
        _addQuery(queryMeta, directiveInstance);
      }
    }

    List<_QueryWithRead> queriesWithReads = [];
    for (var resolvedProvider in _resolvedProvidersArray) {
      var queriesForProvider = _getQueriesFor(resolvedProvider.token);
      queriesWithReads.addAll(queriesForProvider
          .map((query) => new _QueryWithRead(query, resolvedProvider.token)));
    }

    // For each reference token create CompileTokenMetadata to read query.
    if (referenceTokens != null) {
      referenceTokens.forEach((String varName, token) {
        var varValue = token != null
            ? _providers.get(token).build()
            : renderNode.toReadExpr();
        view.nameResolver.addLocal(varName, varValue);
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
        // query for an identifier.
        //
        // TODO: add test for coverage, only target using this is
        // acx2/components/charts/bar_chart/examples:examples
        value = _providers.get(queryWithRead.read)?.build();
      } else {
        // query for a reference
        var token = (referenceTokens != null)
            ? referenceTokens[queryWithRead.read.value]
            : null;
        // If we can't find a valid query type, then we fall back to ElementRef.
        //
        // HOWEVER, if specifically typed as Element or HtmlElement, use that.
        value = token != null
            ? _providers.get(token)?.build()
            : queryWithRead.query.metadata.isElementType
                ? renderNode.toReadExpr()
                : elementRef;
      }
      if (value != null) {
        queryWithRead.query.addQueryResult(this.view, value);
      }
    }
  }

  bool get publishesTemplateRef => _publishesTemplateRef;

  void afterChildren(int childNodeCount) {
    for (ProviderAst resolvedProvider in _resolvedProvidersArray) {
      if (resolvedProvider.providerType ==
          ProviderAstType.FunctionalDirective) {
        o.Expression invokeExpression = _providers
            .createFunctionalDirectiveSource(resolvedProvider)
            .build();
        // Add functional directive invocation.
        view.callFunctionalDirective(invokeExpression);
        continue;
      }

      if (!resolvedProvider.dynamicallyReachable ||
          _providers.isAliasedProvider(resolvedProvider.token)) continue;

      // Note: afterChildren is called after recursing into children.
      // This is good so that an injector match in an element that is closer to
      // a requesting element matches first.
      var providerExpr = _providers.get(resolvedProvider.token).build();
      var aliases = _providers.getAliases(resolvedProvider.token);

      // Note: view providers are only visible on the injector of that element.
      // This is not fully correct as the rules during codegen don't allow a
      // directive to get hold of a view provider on the same element. We still
      // do this semantic as it simplifies our model to having only one runtime
      // injector per element.
      var providerChildNodeCount =
          resolvedProvider.providerType == ProviderAstType.PrivateService
              ? 0
              : childNodeCount;
      view.addInjectable(nodeIndex, providerChildNodeCount, resolvedProvider,
          providerExpr, aliases);
    }
    for (List<CompileQuery> queries in _queries.values) {
      for (CompileQuery query in queries) {
        view.updateQueryAtStartup(query);
        view.updateContentQuery(query);
      }
    }
  }

  void writeDeferredLoader(CompileView embeddedView,
      o.Expression viewContainerExpr, List<o.Statement> stmts) {
    CompileElement deferredElement = embeddedView.nodes[0] as CompileElement;
    CompileDirectiveMetadata deferredMeta = deferredElement.component;
    if (deferredMeta == null) {
      ElementAst elemAst = deferredElement.sourceAst;
      throwFailure('Cannot defer Unknown component type <${elemAst.name}>');
    }
    String deferredModuleUrl = deferredMeta.identifier.moduleUrl;
    String prefix = embeddedView.deferredModules[deferredModuleUrl];
    String templatePrefix;
    if (prefix == null) {
      prefix = 'deflib${embeddedView.deferredModules.length}';
      embeddedView.deferredModules[deferredModuleUrl] = prefix;
      templatePrefix = 'deflib${view.deferredModules.length}';
      embeddedView.deferredModules[toTemplateExtension(deferredModuleUrl)] =
          templatePrefix;
    } else {
      templatePrefix =
          embeddedView.deferredModules[toTemplateExtension(deferredModuleUrl)];
    }

    CompileIdentifierMetadata prefixedId = new CompileIdentifierMetadata(
        name: 'loadLibrary', prefix: prefix, emitPrefix: true);
    CompileIdentifierMetadata nestedComponentId = new CompileIdentifierMetadata(
        name: getViewFactoryName(deferredElement.component, 0));
    CompileIdentifierMetadata templatePrefixId = new CompileIdentifierMetadata(
        name: 'loadLibrary', prefix: templatePrefix, emitPrefix: true);

    CompileIdentifierMetadata templateInitializer =
        new CompileIdentifierMetadata(
            name: 'initReflector',
            moduleUrl: nestedComponentId.moduleUrl,
            prefix: templatePrefix,
            emitPrefix: true,
            value: nestedComponentId.value);

    var templateRefExpr = _providers.get(Identifiers.TemplateRefToken).build();

    final args = [
      o.importDeferred(prefixedId),
      o.importDeferred(templatePrefixId),
      viewContainerExpr,
      templateRefExpr,
    ];

    // If "fastBoot" is not being used, we need to emit more information.
    if (!view.genConfig.useFastBoot) {
      final initReflectorExpr = new o.FunctionExpr(const [], <o.Statement>[
        o.importDeferred(templateInitializer).callFn(const []).toStmt()
      ], null);
      args.add(initReflectorExpr);
    }

    stmts.add(new o.InvokeMemberMethodExpr('loadDeferred', args).toStmt());
  }

  void addContentNode(int ngContentIndex, o.Expression nodeExpr) {
    contentNodesByNgContentIndex[ngContentIndex].add(nodeExpr);
  }

  o.Expression getComponent() => component != null
      ? _providers.get(identifierToken(component.type)).build()
      : null;

  // NodeProvidersHost implementation.
  @override
  ProviderSource createProviderInstance(
      ProviderAst resolvedProvider,
      CompileDirectiveMetadata directiveMetadata,
      List<ProviderSource> providerSources,
      int uniqueId) {
    // Create a new field property for this provider.
    var propName = '_${resolvedProvider.token.name}_${nodeIndex}_$uniqueId';
    List<o.Expression> providerValueExpressions =
        providerSources.map((ProviderSource s) => s.build()).toList();
    o.Expression providerExpr = view.createProvider(
        propName,
        directiveMetadata,
        resolvedProvider,
        providerValueExpressions,
        resolvedProvider.multiProvider,
        resolvedProvider.eager,
        this,
        forceDynamic:
            (resolvedProvider.providerType == ProviderAstType.Component) &&
                isDeferredComponent);
    return new LiteralValueSource(resolvedProvider.token, providerExpr);
  }

  @override
  ProviderSource createDynamicInjectionSource(ProvidersNode providersNode,
      ProviderSource source, CompileTokenMetadata token, bool optional) {
    // If request was made on a service resolving to a private directive,
    // use requested dependency to call injectorGet instead of directive
    // that redirects using useExisting type provider.
    var value = source?.build();
    value ??= injectFromViewParentInjector(view, token, optional);
    CompileElement currElement = this;
    while (currElement != null) {
      if (currElement._providers == providersNode) break;
      currElement = currElement.parent;
    }
    var viewRelativeExpression =
        getPropertyInView(value, view, currElement.view);
    return new LiteralValueSource(token, viewRelativeExpression);
  }

  List<o.Expression> getProviderTokens() {
    return _resolvedProvidersArray
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
        result.addAll(queries.where(
          (query) => query.metadata.descendants || distance <= 1,
        ));
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
    CompileQueryMetadata metadata,
    ProviderSource directiveInstance,
  ) {
    final query = new CompileQuery(
      metadata: metadata,
      storage: view.storage,
      queryRoot: view,
      boundDirective: directiveInstance,
      nodeIndex: nodeIndex,
      queryIndex: _queryCount,
    );
    _queryCount++;
    addQueryToTokenMap(this._queries, query);
    return query;
  }
}

class _QueryWithRead {
  CompileQuery query;
  CompileTokenMetadata read;
  _QueryWithRead(this.query, CompileTokenMetadata match) {
    read = query.metadata.read ?? match;
  }
}
