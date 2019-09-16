import 'package:angular/src/core/change_detection.dart';
import 'package:angular_compiler/cli.dart';

import '../compile_metadata.dart'
    show
        CompileTokenMap,
        CompileDirectiveMetadata,
        CompileIdentifierMetadata,
        CompileTokenMetadata,
        CompileQueryMetadata,
        CompileProviderMetadata;
import '../i18n/message.dart';
import '../identifiers.dart' show Identifiers, identifierToken;
import '../output/output_ast.dart' as o;
import '../template_ast.dart'
    show TemplateAst, ProviderAst, ProviderAstType, ReferenceAst, ElementAst;
import 'compile_query.dart' show CompileQuery, addQueryToTokenMap;
import 'compile_view.dart' show CompileView, NodeReference;
import 'ir/provider_resolver.dart';
import 'ir/provider_source.dart';
import 'provider_forest.dart' show ProviderInstance, ProviderNode;
import 'view_compiler_utils.dart' show toTemplateExtension;

/// Compiled node in the view (such as text node) that is not an element.
class CompileNode {
  /// Parent of node.
  final CompileElement parent;
  final CompileView view;
  final int nodeIndex;

  /// Expression that resolves to reference to instance of of node.
  final NodeReference renderNode;

  CompileNode(
    this.parent,
    this.view,
    this.nodeIndex,
    this.renderNode,
  );

  /// Whether node is the root of the view.
  bool get isRootElement => view != parent.view;
}

/// Compiled element in the view.
class CompileElement extends CompileNode implements ProviderResolverHost {
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
  final bool isDeferredComponent;

  /// Source location in template.
  final TemplateAst sourceAst;

  /// Reference to optional view container created for this element.
  o.ReadClassMemberExpr appViewContainer;
  o.Expression elementRef;

  /// Expression that contains reference to componentView (root View class).
  final o.Expression componentView;

  var _queryCount = 0;
  final _queries = CompileTokenMap<List<CompileQuery>>();
  ProviderResolver _providers;

  List<List<o.Expression>> contentNodesByNgContentIndex;
  CompileView embeddedView;
  List<ProviderSource> directiveInstances;
  Map<String, CompileTokenMetadata> referenceTokens;
  // If compile element is a template and has #ref resolving to TemplateRef
  // this is set so we create a class field member for the template reference.
  var _publishesTemplateRef = false;

  CompileElement(
    CompileElement parent,
    CompileView view,
    int nodeIndex,
    NodeReference renderNode,
    this.sourceAst,
    this.component,
    this._directives,
    this._resolvedProvidersArray,
    this.hasViewContainer,
    this.hasEmbeddedView,
    List<ReferenceAst> references, {
    this.componentView,
    this.hasTemplateRefQuery = false,
    this.isHtmlElement = false,
    this.isDeferredComponent = false,
  }) : super(parent, view, nodeIndex, renderNode) {
    _providers = ProviderResolver(this, parent?._providers);
    if (references.isNotEmpty) {
      referenceTokens = <String, CompileTokenMetadata>{};
      for (final reference in references) {
        final token = reference.value;
        referenceTokens[reference.name] = token;
        _publishesTemplateRef = _publishesTemplateRef ||
            token != null && token.equalsTo(Identifiers.TemplateRefToken);
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
        o.InvokeMemberMethodExpr('injector', [o.literal(this.nodeIndex)]);
    _providers.add(Identifiers.InjectorToken, readInjectorExpr);

    if (hasViewContainer || hasEmbeddedView) {
      appViewContainer = view.createViewContainer(
        renderNode,
        nodeIndex,
        !hasViewContainer,
        isRootElement ? null : parent.nodeIndex,
      );
      _providers.add(Identifiers.ViewContainerToken, appViewContainer);
    }

    // This logic was copied from the setter for `componentView`, which was
    // removed when `componentView` was made final (as there was no need for it
    // to ever be reassigned).
    if (componentView != null) {
      final indexCount = component.template.ngContentSelectors.length;
      contentNodesByNgContentIndex = List(indexCount);
      for (var i = 0; i < indexCount; i++) {
        contentNodesByNgContentIndex[i] = [];
      }
    }
  }

  /// Returns the [CompileElement] where [resolver] originates from.
  ///
  /// May be used to find the correct parent view (in nested views).
  CompileElement findElementByResolver(ProviderResolver resolver) {
    // TODO: [ProviderResolver._host] *is* the `CompileElement`.
    // We should take this into account during the pipeline refactor.
    var current = this;
    while (current?._providers != resolver) {
      current = current.parent;
    }
    return current;
  }

  CompileElement.root()
      : this(null, null, null, NodeReference.rootElement(), null, null, [], [],
            false, false, []);

  void setEmbeddedView(CompileView view) {
    // TODO(b/128427013): Remove these exceptions, they are likely never hit.
    if (appViewContainer == null) {
      throw StateError('Expecting appView container to host view');
    }
    if (view.viewFactory == null) {
      throw StateError('Expecting viewFactory initialization before '
          'embedding view');
    }
    embeddedView = view;
    if (view != null) {
      var createTemplateRefExpr = o
          .importExpr(Identifiers.TemplateRef)
          .instantiate([this.appViewContainer, view.viewFactory],
              type: o.importType(Identifiers.TemplateRef));
      var provider = CompileProviderMetadata(
          token: identifierToken(Identifiers.TemplateRef),
          useValue: createTemplateRefExpr);

      final isReferencedOutsideBuild = _publishesTemplateRef ||
          _getQueriesFor(Identifiers.TemplateRefToken).isNotEmpty;
      // Add TemplateRef as first provider as it does not have deps on other
      // providers
      _resolvedProvidersArray.insert(
        0,
        ProviderAst(
          provider.token,
          false,
          [provider],
          ProviderAstType.Builtin,
          this.sourceAst.sourceSpan,
          eager: true,
          isReferencedOutsideBuild: isReferencedOutsideBuild,
        ),
      );
    }
  }

  void beforeChildren() {
    if (hasViewContainer &&
        !_providers.containsLocalProvider(Identifiers.ViewContainerRefToken)) {
      _providers.add(Identifiers.ViewContainerRefToken, appViewContainer);
    }

    // Access builtins with special visibility.
    _providers.add(
        Identifiers.ChangeDetectorRefToken, componentView ?? o.THIS_EXPR);

    // ComponentLoader is currently just an alias for ViewContainerRef with
    // a smaller API that is also usable outside of the context of a
    // structural directive.
    if (appViewContainer != null) {
      _providers.add(Identifiers.ComponentLoaderToken, appViewContainer);
    }

    // If this element represents a deferred generic component and its type
    // arguments are specified, forward the type arguments to be used to
    // instantiate the provider. Normally we rely on the field type of the
    // provider to specify type arguments, but the field type of deferred
    // components must be dynamic since the component type is deferred.
    final deferredComponentTypeArguments = isDeferredComponent
        ? view.lookupTypeArgumentsOf(component.originType, sourceAst)
        : <o.OutputType>[];
    if (deferredComponentTypeArguments.isNotEmpty) {
      _providers.addDirectiveProviders(
        _resolvedProvidersArray,
        _directives,
        deferredComponent: component.identifier,
        deferredComponentTypeArguments: deferredComponentTypeArguments,
      );
    } else {
      _providers.addDirectiveProviders(_resolvedProvidersArray, _directives);
    }

    directiveInstances = <ProviderSource>[];
    for (var directive in _directives) {
      var directiveInstance = getDirectiveSource(directive);
      directiveInstances.add(directiveInstance);
      for (var queryMeta in directive.queries) {
        _addQuery(queryMeta, directiveInstance);
      }
    }

    List<_QueryWithRead> queriesWithReads = [];
    for (var resolvedProvider in _resolvedProvidersArray) {
      var queriesForProvider = _getQueriesFor(resolvedProvider.token);
      queriesWithReads.addAll(queriesForProvider
          .map((query) => _QueryWithRead(query, resolvedProvider.token)));
    }

    // For each reference token create CompileTokenMetadata to read query.
    if (referenceTokens != null) {
      referenceTokens.forEach((String varName, token) {
        var varValue = token != null
            ? _providers.get(token).build()
            : renderNode.toReadExpr();
        view.nameResolver.addLocal(varName, varValue);
        var varToken = CompileTokenMetadata(value: varName);
        queriesWithReads.addAll(_getQueriesFor(varToken)
            .map((query) => _QueryWithRead(query, varToken)));
      });
    }

    // For all @ViewChild(... read: Type) and references that map to locals,
    // resolve value.
    for (_QueryWithRead queryWithRead in queriesWithReads) {
      o.Expression value;
      o.Expression changeDetectorRef;

      if (queryWithRead.read.identifier != null) {
        // Query for an identifier.
        var providerSource = _providers.get(queryWithRead.read);
        if (providerSource != null) {
          value = providerSource.build();
          changeDetectorRef = providerSource.buildChangeDetectorRef();
        }
      } else {
        // Query for a reference.
        var token = referenceTokens != null
            ? referenceTokens[queryWithRead.read.value]
            : null;
        if (token != null) {
          var providerSource = _providers.get(token);
          if (providerSource != null) {
            value = providerSource.build();
            changeDetectorRef = providerSource.buildChangeDetectorRef();
          }
        } else {
          // If we can't find a valid query type, then we fall back to
          // ElementRef. HOWEVER, if specifically typed as Element or
          // HtmlElement, use that.
          value = queryWithRead.query.metadata.isElementType
              ? renderNode.toReadExpr()
              : elementRef;
        }
      }

      if (value != null) {
        queryWithRead.query.addQueryResult(view, value, changeDetectorRef);
      }
    }
  }

  bool get publishesTemplateRef => _publishesTemplateRef;

  /// Creates the unique provider instances provided by this element.
  ///
  /// Normal providers are added to [providers], while view providers are added
  /// to [viewProviders] (there are known bugs with this process b/127379145).
  void _createProviderInstances(
    List<ProviderInstance> providers,
    List<ProviderInstance> viewProviders,
  ) {
    for (final provider in _resolvedProvidersArray) {
      final token = provider.token;

      // Skip any providers that are backed by a functional directive (these are
      // never injectable) or are an alias for an existing provider (aliases are
      // handled by the existing provider).
      if (provider.providerType == ProviderAstType.FunctionalDirective ||
          _providers.isAliasedProvider(token)) {
        continue;
      }

      // Aggregate all tokens that this provider statisfies.
      final tokens = <CompileTokenMetadata>[];
      if (provider.visibleForInjection) {
        tokens.add(token);
      }
      final aliases = _providers.getAliases(token);
      if (aliases != null) {
        tokens.addAll(aliases);
      }

      // Skip this provider if it satisfies no dependencies (i.e. a directive
      // that's not visible for injection and has no aliases).
      if (tokens.isEmpty) continue;

      final expression = _providers.get(token).build();
      final instance = ProviderInstance(tokens, expression);
      if (provider.providerType == ProviderAstType.PrivateService) {
        viewProviders.add(instance);
      } else {
        providers.add(instance);
      }
    }
  }

  /// Creates a [ProviderNode] for this element.
  ///
  /// Note that [childNodeCount] can be greater than [children.length], as it
  /// counts nodes that can't produce providers such as HTML text and comments.
  ProviderNode createProviderNode(
      int childNodeCount, List<ProviderNode> children) {
    final providers = <ProviderInstance>[];
    if (childNodeCount == 0) {
      // If there aren't any child nodes, both regular and view providers are
      // injectable within the same range ([nodeIndex, nodeIndex]), so they can
      // both be added to the same `ProviderNode`.
      _createProviderInstances(providers, providers);
    } else {
      // Otherwise view providers must be added to their own `ProviderNode`.
      // This node is added as a child because its restricted range ([nodeIndex,
      // nodeIndex]) lies within the range for normal providers ([nodeIndex,
      // nodeIndex + childNodeCount]).
      final viewProviders = <ProviderInstance>[];
      _createProviderInstances(providers, viewProviders);
      if (viewProviders.isNotEmpty) {
        children.add(ProviderNode(
          nodeIndex,
          nodeIndex,
          providers: viewProviders,
        ));
      }
    }
    return ProviderNode(
      nodeIndex,
      nodeIndex + childNodeCount,
      providers: providers,
      children: children,
    );
  }

  void afterChildren(int childNodeCount) {
    // Add functional directive invocations.
    for (ProviderAst resolvedProvider in _resolvedProvidersArray) {
      if (resolvedProvider.providerType ==
          ProviderAstType.FunctionalDirective) {
        o.Expression invokeExpression = _providers
            .createFunctionalDirectiveSource(resolvedProvider)
            .build();
        view.callFunctionalDirective(invokeExpression);
      }
    }
    for (List<CompileQuery> queries in _queries.values) {
      for (CompileQuery query in queries) {
        view.updateQueryAtStartup(query);
        view.updateContentQuery(query);
      }
    }
  }

  /// Returns code that performs defer loading (i.e. invokes `loadDeferred(..)`.
  o.Expression writeDeferredLoader(
    CompileView embeddedView,
    o.Expression viewContainerExpr,
  ) {
    CompileElement deferredElement = embeddedView.nodes[0] as CompileElement;
    CompileDirectiveMetadata deferredMeta = deferredElement.component;
    if (deferredMeta == null) {
      var elemAst = deferredElement.sourceAst as ElementAst;
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

    CompileIdentifierMetadata prefixedId = CompileIdentifierMetadata(
        name: 'loadLibrary', prefix: prefix, emitPrefix: true);
    CompileIdentifierMetadata templatePrefixId = CompileIdentifierMetadata(
        name: 'loadLibrary', prefix: templatePrefix, emitPrefix: true);

    var templateRefExpr = _providers.get(Identifiers.TemplateRefToken).build();

    final args = [
      o.importDeferred(prefixedId),
      o.importDeferred(templatePrefixId),
      viewContainerExpr,
      templateRefExpr,
    ];

    return o.importExpr(Identifiers.loadDeferred).callFn(args);
  }

  void addContentNode(int ngContentIndex, o.Expression nodeExpr) {
    contentNodesByNgContentIndex[ngContentIndex].add(nodeExpr);
  }

  o.Expression getComponent() => getDirectiveSource(component)?.build();

  ProviderSource getDirectiveSource(CompileDirectiveMetadata directive) =>
      directive != null
          ? _providers.get(identifierToken(directive.type))
          : null;

  // NodeProvidersHost implementation.
  @override
  ProviderSource createProviderInstance(
    ProviderAst resolvedProvider,
    CompileDirectiveMetadata directiveMetadata,
    List<ProviderSource> providerSources,
    int uniqueId,
  ) {
    // Create a new field property for this provider.
    final propName = '_${resolvedProvider.token.name}_${nodeIndex}_$uniqueId';
    final providerValueExpressions =
        providerSources.map((s) => s.build()).toList();

    var forceDynamic = false;
    o.Expression changeDetectorRefExpr;

    if (resolvedProvider.providerType == ProviderAstType.Component) {
      forceDynamic = isDeferredComponent;
      if (directiveMetadata.changeDetection == ChangeDetectionStrategy.OnPush) {
        changeDetectorRefExpr = componentView;
      }
    }

    final providerExpr = view.createProvider(
      propName,
      directiveMetadata,
      resolvedProvider,
      providerValueExpressions,
      resolvedProvider.multiProvider,
      resolvedProvider.eager,
      this,
      forceDynamic: forceDynamic,
    );

    return ExpressionProviderSource(
      resolvedProvider.token,
      providerExpr,
      changeDetectorRef: changeDetectorRefExpr,
    );
  }

  @override
  ProviderSource createDynamicInjectionSource(
    ProviderResolver providersNode,
    ProviderSource source,
    CompileTokenMetadata token,
    bool optional,
  ) {
    return DynamicProviderSource(
      token,
      this,
      providersNode,
      source,
      isOptional: optional,
    );
  }

  @override
  o.Expression createI18nMessage(I18nMessage message) =>
      view.createI18nMessage(message);

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
      if (currentEl._directives.isNotEmpty) {
        distance++;
      }
      currentEl = currentEl.parent;
    }
    queries = view.componentView.viewQueries.get(token);
    if (queries != null) result.addAll(queries);
    return result;
  }

  CompileQuery _addQuery(
    CompileQueryMetadata metadata,
    ProviderSource directiveInstance,
  ) {
    final query = CompileQuery(
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
