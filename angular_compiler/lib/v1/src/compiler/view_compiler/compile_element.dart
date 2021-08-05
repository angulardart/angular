import 'package:angular/src/meta.dart';

import '../compile_metadata.dart'
    show
        CompileTokenMap,
        CompileDirectiveMetadata,
        CompileTokenMetadata,
        CompileQueryMetadata,
        CompileProviderMetadata;
import '../i18n/message.dart';
import '../identifiers.dart' show Identifiers, identifierToken;
import '../output/output_ast.dart' as o;
import '../template_ast.dart'
    show TemplateAst, ProviderAst, ProviderAstType, ReferenceAst;
import 'compile_query.dart' show CompileQuery, addQueryToTokenMap;
import 'compile_view.dart' show CompileView, NodeReference;
import 'ir/provider_resolver.dart';
import 'ir/provider_source.dart';
import 'provider_forest.dart' show ProviderInstance, ProviderNode;

/// Compiled node in the view (such as text node) that is not an element.
class CompileNode {
  /// Parent of node.
  final CompileElement? parent;
  final CompileView? view;
  final int? nodeIndex;

  /// Expression that resolves to reference to instance of of node.
  final NodeReference renderNode;

  CompileNode(
    this.parent,
    this.view,
    this.nodeIndex,
    this.renderNode,
  );

  /// Whether node is the root of the view.
  bool get isRootElement => view != parent!.view;
}

/// Compiled element in the view.
class CompileElement extends CompileNode implements ProviderResolverHost {
  // If true, we know for sure it is html and not svg or other type
  // so we can create code for more exact type HtmlElement.
  final bool isHtmlElement;
  // CompileElement either is an html element or is an angular component.
  // This member is populated when element is host of a component.
  final CompileDirectiveMetadata? component;
  final List<CompileDirectiveMetadata> _directives;
  List<ProviderAst> _resolvedProvidersArray;
  final bool hasViewContainer;
  final bool hasEmbeddedView;
  final bool hasTemplateRefQuery;

  /// Source location in template.
  final TemplateAst? sourceAst;

  /// Reference to optional view container created for this element.
  o.ReadClassMemberExpr? appViewContainer;
  late o.Expression elementRef;

  /// Expression that contains reference to componentView (root View class).
  final o.Expression? componentView;

  var _queryCount = 0;
  final _queries = CompileTokenMap<List<CompileQuery>>();
  late ProviderResolver _providers;

  List<List<o.Expression>> contentNodesByNgContentIndex = [];
  CompileView? embeddedView;
  late List<ProviderSource?> directiveInstances;
  Map<String, CompileTokenMetadata?> referenceTokens = {};
  // If compile element is a template and has #ref resolving to TemplateRef
  // this is set so we create a class field member for the template reference.
  var _publishesTemplateRef = false;

  /// References to the directives on this element.
  ///
  /// This begins empty and accumulates references to directive instances as
  /// they're generated. The results can be used after calling [beforeChildren].
  final _directiveInstances = <o.Expression>[];

  CompileElement(
    CompileElement? parent,
    CompileView? view,
    int? nodeIndex,
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
  }) : super(parent, view, nodeIndex, renderNode) {
    _providers = ProviderResolver(this, parent?._providers);
    if (references.isNotEmpty) {
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

    _providers.add(Identifiers.ElementRefToken, elementRef);
    _providers.add(Identifiers.ElementToken, renderNode.toReadExpr());
    _providers.add(Identifiers.HtmlElementToken, renderNode.toReadExpr());
    var readInjectorExpr =
        o.InvokeMemberMethodExpr('injector', [o.literal(this.nodeIndex)]);
    _providers.add(Identifiers.InjectorToken, readInjectorExpr);

    if (hasViewContainer || hasEmbeddedView) {
      appViewContainer = view!.createViewContainer(
        renderNode,
        nodeIndex!,
        !hasViewContainer,
        isRootElement ? null : parent!.nodeIndex,
      );
      _providers.add(Identifiers.ViewContainerToken, appViewContainer!);
    }

    // This logic was copied from the setter for `componentView`, which was
    // removed when `componentView` was made final (as there was no need for it
    // to ever be reassigned).
    if (componentView != null) {
      final indexCount = component!.template!.ngContentSelectors.length;
      for (var i = 0; i < indexCount; i++) {
        contentNodesByNgContentIndex.add([]);
      }
    }
  }

  /// Returns the [CompileElement] where [resolver] originates from.
  ///
  /// May be used to find the correct parent view (in nested views).
  CompileElement? findElementByResolver(ProviderResolver? resolver) {
    // TODO: [ProviderResolver._host] *is* the `CompileElement`.
    // We should take this into account during the pipeline refactor.
    CompileElement? current = this;
    while (current?._providers != resolver) {
      current = current!.parent;
    }
    return current;
  }

  CompileElement.root()
      : this(null, null, null, NodeReference.rootElement(), null, null, [], [],
            false, false, []);

  void setEmbeddedView(CompileView view) {
    if (appViewContainer == null) {
      throw StateError('Expected appViewContainer to be set.');
    }
    embeddedView = view;
    var createTemplateRefExpr = o
        .importExpr(Identifiers.TemplateRef)
        .instantiate([appViewContainer!, view.viewFactory],
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
        provider.token!,
        false,
        [provider],
        ProviderAstType.Builtin,
        sourceAst!.sourceSpan,
        eager: true,
        isReferencedOutsideBuild: isReferencedOutsideBuild,
      ),
    );
  }

  void beforeChildren() {
    if (hasViewContainer &&
        !_providers.containsLocalProvider(Identifiers.ViewContainerRefToken)) {
      _providers.add(Identifiers.ViewContainerRefToken, appViewContainer!);
    }

    // Access builtins with special visibility.
    _providers.add(
        Identifiers.ChangeDetectorRefToken, componentView ?? o.THIS_EXPR);

    // ComponentLoader is currently just an alias for ViewContainerRef with
    // a smaller API that is also usable outside of the context of a
    // structural directive.
    if (appViewContainer != null) {
      _providers.add(Identifiers.ComponentLoaderToken, appViewContainer!);
    }

    _providers.addDirectiveProviders(_resolvedProvidersArray, _directives);
    view!.registerDirectives(this, _directiveInstances);

    directiveInstances = <ProviderSource?>[];
    for (var directive in _directives) {
      var directiveInstance = getDirectiveSource(directive);
      directiveInstances.add(directiveInstance);
      for (var queryMeta in directive.queries) {
        _addQuery(queryMeta, directiveInstance);
      }
    }

    var queriesWithReads = <_QueryWithRead>[];
    for (var resolvedProvider in _resolvedProvidersArray) {
      var queriesForProvider = _getQueriesFor(resolvedProvider.token);
      queriesWithReads.addAll(queriesForProvider
          .map((query) => _QueryWithRead(query, resolvedProvider.token)));
    }

    // For each reference token create CompileTokenMetadata to read query.
    if (referenceTokens.isNotEmpty) {
      referenceTokens.forEach((String varName, token) {
        var varValue = token != null
            ? _providers.get(token)!.build()
            : renderNode.toReadExpr();
        view!.nameResolver.addLocal(varName, varValue);
        var varToken = CompileTokenMetadata(value: varName);
        queriesWithReads.addAll(_getQueriesFor(varToken)
            .map((query) => _QueryWithRead(query, varToken)));
      });
    }

    // For all @ViewChild(... read: Type) and references that map to locals,
    // resolve value.
    for (var queryWithRead in queriesWithReads) {
      o.Expression? value;
      o.Expression? changeDetectorRef;

      if (queryWithRead.read.identifier != null) {
        // Query for an identifier.
        var providerSource = _providers.get(queryWithRead.read);
        if (providerSource != null) {
          value = providerSource.build();
          changeDetectorRef = providerSource.buildChangeDetectorRef();
        }
      } else {
        // Query for a reference.
        var token = referenceTokens.isNotEmpty
            ? referenceTokens[queryWithRead.read.value as String]
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
        queryWithRead.query.addQueryResult(view!, value, changeDetectorRef);
      }
    }
  }

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
      // Skip any providers that are an alias for an existing provider (aliases
      // are handled by the existing provider).
      if (_providers.isAliasedProvider(token)) {
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

      final expression = _providers.get(token)!.build();
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
    final nodeIndex = this.nodeIndex!;
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
    for (var queries in _queries.values) {
      for (var query in queries) {
        final view = this.view!;
        view.updateQueryAtStartup(query);
        view.updateContentQuery(query);
      }
    }
  }

  void addContentNode(int ngContentIndex, o.Expression nodeExpr) {
    contentNodesByNgContentIndex[ngContentIndex].add(nodeExpr);
  }

  o.Expression? getComponent() => getDirectiveSource(component)?.build();

  ProviderSource? getDirectiveSource(CompileDirectiveMetadata? directive) =>
      directive != null
          ? _providers.get(identifierToken(directive.type))
          : null;

  // NodeProvidersHost implementation.
  @override
  ProviderSource createProviderInstance(
    ProviderAst resolvedProvider,
    CompileDirectiveMetadata? directiveMetadata,
    List<ProviderSource> providerSources,
    int uniqueId,
  ) {
    // Create a new field property for this provider.
    final propName = '_${resolvedProvider.token.name}_${nodeIndex}_$uniqueId';
    final providerValueExpressions = providerSources
        .map((s) => s.build())
        .whereType<o.Expression>()
        .toList();

    o.Expression? changeDetectorRefExpr;

    if (resolvedProvider.providerType == ProviderAstType.Component) {
      if (directiveMetadata?.changeDetection ==
          ChangeDetectionStrategy.OnPush) {
        changeDetectorRefExpr = componentView;
      }
    }

    final providerExpr = view!.createProvider(
      propName,
      directiveMetadata,
      resolvedProvider,
      providerValueExpressions,
      resolvedProvider.multiProvider,
      resolvedProvider.eager,
      this,
    );

    /// Accumulate directive instances on this element for later use.
    if (resolvedProvider.providerType == ProviderAstType.Directive) {
      _directiveInstances.add(providerExpr);
    }

    return ExpressionProviderSource(
      resolvedProvider.token,
      providerExpr,
      changeDetectorRef: changeDetectorRefExpr,
    );
  }

  @override
  ProviderSource createDynamicInjectionSource(
    ProviderResolver? providersNode,
    ProviderSource? source,
    CompileTokenMetadata? token,
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
      view!.createI18nMessage(message);

  List<CompileQuery> _getQueriesFor(CompileTokenMetadata token) {
    var result = <CompileQuery>[];
    var currentEl = this;
    var distance = 0;
    List<CompileQuery>? queries;
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
      currentEl = currentEl.parent!;
    }
    queries = view!.componentView.viewQueries.get(token);
    if (queries != null) result.addAll(queries);
    return result;
  }

  CompileQuery _addQuery(
    CompileQueryMetadata metadata,
    ProviderSource? directiveInstance,
  ) {
    final query = CompileQuery(
      metadata: metadata,
      storage: view!.storage,
      queryRoot: view!,
      boundDirective: directiveInstance,
      nodeIndex: nodeIndex,
      queryIndex: _queryCount,
    );
    _queryCount++;
    addQueryToTokenMap(_queries, query);
    return query;
  }
}

class _QueryWithRead {
  CompileQuery query;
  late CompileTokenMetadata read;
  _QueryWithRead(this.query, CompileTokenMetadata match) {
    read = query.metadata.read ?? match;
  }
}
