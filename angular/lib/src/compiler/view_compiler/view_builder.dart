import 'package:meta/meta.dart';
import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/compile_metadata.dart'
    show CompileDirectiveMetadata;
import 'package:angular/src/compiler/expression_parser/parser.dart' show Parser;
import 'package:angular/src/compiler/identifiers.dart' show Identifiers;
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/semantic_analysis/binding_converter.dart'
    show
        convertHostAttributeToBinding,
        convertHostListenerToBinding,
        convertToBinding;
import 'package:angular/src/compiler/template_ast.dart';
import 'package:angular/src/compiler/view_compiler/bound_value_converter.dart';
import 'package:angular/src/compiler/view_compiler/update_statement_visitor.dart';
import 'package:angular/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy;
import 'package:angular/src/core/linker/view_type.dart';
import 'package:angular_compiler/cli.dart';

import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_view.dart';
import 'constants.dart'
    show
        createEnumExpression,
        changeDetectionStrategyToConst,
        parentRenderNodeVar,
        DetectChangesVars,
        ViewConstructorVars,
        ViewProperties;
import 'perf_profiler.dart';
import 'provider_forest.dart' show ProviderForest, ProviderNode;
import 'view_compiler_utils.dart'
    show
        createFlatArray,
        detectHtmlElementFromTagName,
        identifierFromTagName,
        maybeCachedCtxDeclarationStatement,
        mergeHtmlAndDirectiveAttributes,
        namespaceUris;
import 'view_style_linker.dart';

class ViewBuilderVisitor implements TemplateAstVisitor<void, CompileElement> {
  final CompileView _view;

  /// A stack used to collect providers from each visited element.
  ///
  ///   * Before visiting an element's children, a new entry will be pushed to
  ///   the stack.
  ///
  ///   * Upon visiting each child, a provider node is appended to the top entry
  ///   in the stack.
  ///
  ///   * After visiting an element's children, the top entry of the stack is
  ///   popped and used to populate the current provider node's children.
  ///
  /// Collecting providers in this manner allows us to process them in their
  /// entirety, separately from this visitor.
  final _providerStack = <List<ProviderNode>>[[]];

  /// This is `true` if this is visiting nodes that will be projected into
  /// another view.
  bool _visitingProjectedContent = false;

  int _nestedViewCount = 0;

  ViewBuilderVisitor(this._view);

  /// The dependency injection hierarchy constructed from visiting a view.
  ProviderForest get providers => ProviderForest.from(_providerStack.first);

  void _addRootNodeAndProject(
      CompileNode node, int ngContentIndex, CompileElement parent) {
    var vcAppEl = (node is CompileElement && node.hasViewContainer)
        ? node.appViewContainer
        : null;
    if (_isRootNode(parent)) {
      // store appElement as root node only for ViewContainers
      if (_view.viewType != ViewType.component) {
        _view.rootNodesOrViewContainers
            .add(vcAppEl ?? node.renderNode.toReadExpr());
      }
    } else if (parent.component != null && ngContentIndex != null) {
      parent.addContentNode(
          ngContentIndex, vcAppEl ?? node.renderNode.toReadExpr());
    }
  }

  @override
  void visitBoundText(BoundTextAst ast, CompileElement parent) {
    if (_maybeSkipNode(parent, ast.ngContentIndex)) {
      _deadCodeWarning("Bound text node (${ast.value})", ast, parent);
      return;
    }
    _visitText(
      convertToBinding(ast, _view.component.analyzedClass),
      parent,
      ast.ngContentIndex,
    );
  }

  @override
  void visitText(TextAst ast, CompileElement parent) {
    if (_maybeSkipNode(parent, ast.ngContentIndex)) {
      if (ast.value.trim() != '') {
        _deadCodeWarning("Non-empty text node (${ast.value})", ast, parent);
      }
      return;
    }
    _visitText(convertToBinding(ast, null), parent, ast.ngContentIndex);
  }

  @override
  void visitI18nText(I18nTextAst ast, CompileElement parent) {
    _visitText(convertToBinding(ast, null), parent, ast.ngContentIndex);
  }

  bool _maybeSkipNode(CompileElement parent, ngContentIndex) {
    if (!_isRootNode(parent) &&
        parent.component != null &&
        ngContentIndex == null) {
      // Keep the list of nodes in sync with the tree.
      _view.nodes.add(null);
      return true;
    }
    return false;
  }

  void _deadCodeWarning(
      String nodeDescription, TemplateAst ast, CompileElement parent) {
    logWarning(ast.sourceSpan.message("Dead code in template: "
        "$nodeDescription is a child of a non-projecting "
        "component (${parent.component.selector}) and will not "
        "be added to the DOM."));
  }

  void _visitText(
      ir.Binding binding, CompileElement parent, int ngContentIndex) {
    int nodeIndex = _view.nodes.length;
    NodeReference renderNode = _nodeReference(binding, parent, nodeIndex);
    var compileNode = CompileNode(parent, _view, nodeIndex, renderNode);
    _view.nodes.add(compileNode);
    _addRootNodeAndProject(compileNode, ngContentIndex, parent);
  }

  NodeReference _nodeReference(
      ir.Binding binding, CompileElement parent, int nodeIndex) {
    int nodeIndex = _view.nodes.length;
    if (binding.target is ir.TextBinding) {
      return _view.createTextBinding(binding.source, parent, nodeIndex);
    } else if (binding.target is ir.HtmlBinding) {
      return _view.createHtml(binding.source, parent, nodeIndex);
    } else {
      throw ArgumentError.value(
          binding.target, 'binding.target', 'Unsupported binding target.');
    }
  }

  @override
  void visitNgContainer(NgContainerAst ast, CompileElement parent) {
    templateVisitAll(this, ast.children, parent);
  }

  @override
  void visitNgContent(NgContentAst ast, CompileElement parent) {
    _view.projectNodesIntoElement(parent, ast.index, ast);
  }

  @override
  void visitElement(ElementAst ast, CompileElement parent) {
    int nodeIndex = _view.nodes.length;

    final elementRef = _elementReference(ast, nodeIndex);

    var directives = _toCompileMetadata(ast.directives);
    CompileDirectiveMetadata component = _componentFromDirectives(directives);

    if (component != null) {
      bool isDeferred = nodeIndex == 0 && _viewHasDeferredComponent;
      _visitComponentElement(
          parent, nodeIndex, component, elementRef, directives, ast,
          isDeferred: isDeferred);
    } else {
      _visitHtmlElement(parent, nodeIndex, elementRef, directives, ast);
    }
  }

  NodeReference _elementReference(ElementAst ast, int nodeIndex) {
    return NodeReference(
      _view.storage,
      o.importType(identifierFromTagName(ast.name)),
      nodeIndex,
    );
  }

  CompileDirectiveMetadata _componentFromDirectives(
          List<CompileDirectiveMetadata> directives) =>
      directives.firstWhere((directive) => directive.isComponent,
          orElse: () => null);

  /// Should be called before visiting the children of [element].
  void _beforeChildren(CompileElement element) {
    element.beforeChildren();
    _providerStack.add([]);
  }

  /// Should be called after visiting the children of [element].
  void _afterChildren(CompileElement element) {
    final childNodeCount = _view.nodes.length - element.nodeIndex - 1;
    element.afterChildren(childNodeCount);
    final childProviderNodes = _providerStack.removeLast();
    final providerNode =
        element.createProviderNode(childNodeCount, childProviderNodes);
    _providerStack.last.add(providerNode);
  }

  bool get _viewHasDeferredComponent =>
      (_view.declarationElement.sourceAst is EmbeddedTemplateAst) &&
      (_view.declarationElement.sourceAst as EmbeddedTemplateAst)
          .hasDeferredComponent;

  void _visitComponentElement(
      CompileElement parent,
      int nodeIndex,
      CompileDirectiveMetadata component,
      NodeReference elementRef,
      List<CompileDirectiveMetadata> directives,
      ElementAst ast,
      {bool isDeferred = false}) {
    AppViewReference compAppViewRef = _view.createComponentNodeAndAppend(
        component, parent, elementRef, nodeIndex, ast,
        isDeferred: isDeferred);

    if (_view.viewType == ViewType.host) {
      // For host views, override the getter that returns the hosted component
      // view. This is used only to fufill an experimental debug API.
      _view.getters.add(
        o.ClassGetter(
          'hostedComponentView',
          [o.ReturnStatement(compAppViewRef.toReadExpr())],
          o.importType(Identifiers.AppView, [o.VOID_TYPE]),
          null,
          [o.importExpr(Identifiers.dartCoreOverride)],
        ),
      );
    }

    var isHtmlElement = detectHtmlElementFromTagName(ast.name);

    if (_view.viewType != ViewType.host) {
      var mergedBindings = mergeHtmlAndDirectiveAttributes(
        ast,
        directives,
      );
      _view.writeLiteralAttributeValues(
        ast.name,
        elementRef,
        mergedBindings,
        isHtmlElement: isHtmlElement,
      );
    }

    _view.shimCssForNode(elementRef, nodeIndex, Identifiers.HTML_HTML_ELEMENT);

    final compAppViewExpr = compAppViewRef.toReadExpr();
    final compileElement = CompileElement(
      parent,
      _view,
      nodeIndex,
      elementRef,
      ast,
      component,
      directives,
      ast.providers,
      ast.hasViewContainer,
      false,
      ast.references,
      componentView: compAppViewExpr,
      hasTemplateRefQuery: parent.hasTemplateRefQuery,
      isHtmlElement: isHtmlElement,
      isDeferredComponent: isDeferred,
    );

    _view.addViewChild(compAppViewExpr);
    _view.nodes.add(compileElement);
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);

    _beforeChildren(compileElement);
    bool oldVisitingProjectedContent = _visitingProjectedContent;
    _visitingProjectedContent = true;
    templateVisitAll(this, ast.children, compileElement);
    _visitingProjectedContent = oldVisitingProjectedContent;
    _afterChildren(compileElement);

    o.Expression projectables;
    if (_view.component.type.isHost) {
      projectables = ViewProperties.projectedNodes;
    } else {
      projectables = o.literalArr(compileElement.contentNodesByNgContentIndex
          .map((nodes) => createFlatArray(nodes))
          .toList());
    }
    var componentInstance = compileElement.getComponent();
    _view.createAppView(compAppViewRef, componentInstance, projectables);
  }

  void _visitHtmlElement(
      CompileElement parent,
      int nodeIndex,
      NodeReference elementRef,
      List<CompileDirectiveMetadata> directives,
      ElementAst ast) {
    String tagName = ast.name;
    // Create element or elementNS. AST encodes svg path element as
    // @svg:path.
    bool isNamespacedElement = tagName.startsWith('@') && tagName.contains(':');
    if (isNamespacedElement) {
      var nameParts = ast.name.substring(1).split(':');
      String ns = namespaceUris[nameParts[0]];
      _view.createElementNs(
          parent, elementRef, nodeIndex, ns, nameParts[1], ast);
    } else {
      _view.createElement(parent, elementRef, nodeIndex, tagName, ast);
    }
    var isHtmlElement = detectHtmlElementFromTagName(tagName);
    var mergedBindings = mergeHtmlAndDirectiveAttributes(
      ast,
      directives,
    );
    _view.writeLiteralAttributeValues(
      ast.name,
      elementRef,
      mergedBindings,
      isHtmlElement: isHtmlElement,
    );

    // Set ng_content class for CSS shim.
    var elementType = _view.isRootNodeOfHost(nodeIndex)
        ? Identifiers.HTML_HTML_ELEMENT
        : identifierFromTagName(ast.name);
    _view.shimCssForNode(elementRef, nodeIndex, elementType);

    var compileElement = CompileElement(
        parent,
        _view,
        nodeIndex,
        elementRef,
        ast,
        null,
        directives,
        ast.providers,
        ast.hasViewContainer,
        false,
        ast.references,
        isHtmlElement: isHtmlElement,
        hasTemplateRefQuery: parent.hasTemplateRefQuery);

    _view.nodes.add(compileElement);
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    _beforeChildren(compileElement);
    templateVisitAll(this, ast.children, compileElement);
    _afterChildren(compileElement);
  }

  @override
  void visitEmbeddedTemplate(EmbeddedTemplateAst ast, CompileElement parent) {
    var nodeIndex = _view.nodes.length;
    NodeReference nodeReference =
        _view.createViewContainerAnchor(parent, nodeIndex, ast);
    var directives = _toCompileMetadata(ast.directives);
    var compileElement = CompileElement(
      parent,
      _view,
      nodeIndex,
      nodeReference,
      ast,
      null,
      directives,
      ast.providers,
      ast.hasViewContainer,
      true,
      ast.references,
      hasTemplateRefQuery: parent.hasTemplateRefQuery,
    );
    _view.nodes.add(compileElement);
    _nestedViewCount++;
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);

    CompileDirectiveMetadata metadata = CompileDirectiveMetadata.from(
        _view.component,
        analyzedClass: AnalyzedClass.from(_view.component.analyzedClass,
            additionalLocals: Map.fromIterable(ast.variables,
                key: (v) => (v as VariableAst).name,
                value: (v) => (v as VariableAst).dartType)));

    var embeddedView = CompileView(
      metadata,
      _view.genConfig,
      _view.directiveTypes,
      _view.pipeMetas,
      o.NULL_EXPR,
      _view.viewIndex + _nestedViewCount,
      compileElement,
      ast.variables,
      _view.deferredModules,
    );

    _beforeChildren(compileElement);

    // Create a visitor for embedded view and visit all nodes.
    var embeddedViewVisitor = ViewBuilderVisitor(embeddedView);
    templateVisitAll(
        embeddedViewVisitor,
        ast.children,
        embeddedView.declarationElement.parent ??
            embeddedView.declarationElement);
    _nestedViewCount += embeddedViewVisitor._nestedViewCount;

    _afterChildren(compileElement);
    embeddedView.providers = embeddedViewVisitor.providers;

    if (ast.hasDeferredComponent) {
      _view.deferLoadEmbeddedTemplate(embeddedView, compileElement);
    }
  }

  List<CompileDirectiveMetadata> _toCompileMetadata(
          List<DirectiveAst> directives) =>
      directives.map((directiveAst) => directiveAst.directive).toList();

  @override
  void visitAttr(AttrAst ast, CompileElement parent) {}

  @override
  void visitDirective(DirectiveAst ast, CompileElement parent) {}

  @override
  void visitEvent(BoundEventAst ast, CompileElement parent) {}

  @override
  void visitReference(ReferenceAst ast, CompileElement parent) {}

  @override
  void visitVariable(VariableAst ast, CompileElement parent) {}

  @override
  void visitDirectiveProperty(
      BoundDirectivePropertyAst ast, CompileElement parent) {}

  @override
  void visitElementProperty(
      BoundElementPropertyAst ast, CompileElement parent) {}

  @override
  void visitProvider(ProviderAst ast, CompileElement parent) {}

  bool _isRootNode(CompileElement parent) {
    return !identical(parent.view, _view);
  }
}

/// Generates output ast for a CompileView and returns a [ClassStmt] for the
/// view of embedded template.
o.ClassStmt createViewClass(
  CompileView view,
  Parser parser,
) {
  final viewConstructor = _createViewClassConstructor(view);
  final viewMethods = <o.ClassMethod>[
    o.ClassMethod(
      "build",
      [],
      _generateBuildMethod(view, parser),
      o.importType(Identifiers.ComponentRef,
          // The 'HOST' view is the only implementation that actually returns
          // a ComponentRef, the rest statically declare they do but in
          // reality return `null`. There is no way to fix this without
          // creating new sub-class-able AppView types:
          // https://github.com/dart-lang/angular/issues/1421
          [_getContextType(view)]),
      null,
      [o.importExpr(Identifiers.dartCoreOverride)],
    ),
    view.writeInjectorGetMethod(),
    o.ClassMethod(
      "detectChangesInternal",
      [],
      view.writeChangeDetectionStatements(),
      null,
      null,
      [o.importExpr(Identifiers.dartCoreOverride)],
    ),
    o.ClassMethod(
      "dirtyParentQueriesInternal",
      [],
      view.dirtyParentQueriesMethod.finish(),
      null,
      null,
      [o.importExpr(Identifiers.dartCoreOverride)],
    ),
    o.ClassMethod(
      "destroyInternal",
      [],
      _generateDestroyMethod(view),
      null,
      null,
      [o.importExpr(Identifiers.dartCoreOverride)],
    )
  ]..addAll(view.methods);
  if (view.detectHostChangesMethod != null) {
    final methodStatements = view.detectHostChangesMethod.finish();
    viewMethods.add(o.ClassMethod(
        'detectHostChanges',
        [o.FnParam(DetectChangesVars.firstCheck.name, o.BOOL_TYPE)],
        []
          ..addAll(
              maybeCachedCtxDeclarationStatement(statements: methodStatements))
          ..addAll(methodStatements)));
  }
  for (final method in viewMethods) {
    if (method.body != null) {
      NodeReferenceStorageVisitor.visitScopedStatements(method.body);
    }
  }
  for (final getter in view.getters) {
    if (getter.body != null) {
      NodeReferenceStorageVisitor.visitScopedStatements(getter.body);
    }
  }
  final viewClass = o.ClassStmt(
    view.className,
    o.importExpr(Identifiers.AppView, typeParams: [_getContextType(view)]),
    view.storage.fields,
    view.getters,
    viewConstructor,
    viewMethods
        .where((method) => method.body != null && method.body.isNotEmpty)
        .toList(),
    typeParameters: view.component.originType.typeParameters,
  );
  initStyleEncapsulation(view, viewClass);
  return viewClass;
}

o.Constructor _createViewClassConstructor(CompileView view) {
  var viewConstructorArgs = [
    o.FnParam(
      ViewConstructorVars.parentView.name,
      o.importType(Identifiers.RenderView),
    ),
    o.FnParam(ViewConstructorVars.parentIndex.name, o.INT_TYPE)
  ];
  var superConstructorArgs = [
    createEnumExpression(Identifiers.ViewType, view.viewType),
    ViewConstructorVars.parentView,
    ViewConstructorVars.parentIndex,
    changeDetectionStrategyToConst(_getChangeDetectionMode(view))
  ];
  final ctor = o.Constructor(
    params: viewConstructorArgs,
    initializers: [o.SUPER_EXPR.callFn(superConstructorArgs).toStmt()],
  );
  if (view.viewType == ViewType.component && view.viewIndex == 0) {
    // No namespace just call [document.createElement].
    String tagName = _tagNameFromComponentSelector(view.component.selector);
    if (tagName.isEmpty) {
      throwFailure('Component selector is missing tag name in '
          '${view.component.identifier.name} '
          'selector:${view.component.selector}');
    }
    var createRootElementExpr = o
        .importExpr(Identifiers.HTML_DOCUMENT)
        .callMethod('createElement', [o.literal(tagName)]);

    var appView = NodeReference.appViewRoot();

    ctor.body.add(appView.toWriteStmt(createRootElementExpr));

    // Write literal attribute values on element.
    CompileDirectiveMetadata componentMeta = view.component;
    componentMeta.hostAttributes.forEach((name, value) {
      var binding = convertHostAttributeToBinding(
          name, value, view.component.analyzedClass);
      var statement = view.createAttributeStatement(
        binding,
        tagName,
        appView,
        isHtmlElement: detectHtmlElementFromTagName(tagName),
      );
      ctor.body.add(statement);
    });
    if (view.genConfig.profileFor != Profile.none) {
      genProfileSetup(ctor.body);
    }
  }
  return ctor;
}

String _tagNameFromComponentSelector(String selector) {
  int pos = selector.indexOf(':');
  if (pos != -1) selector = selector.substring(0, pos);
  pos = selector.indexOf('[');
  if (pos != -1) selector = selector.substring(0, pos);
  pos = selector.indexOf('(');
  if (pos != -1) selector = selector.substring(0, pos);
  // Some users have invalid space before selector in @Component, trim so
  // that document.createElement call doesn't fail.
  return selector.trim();
}

List<o.Statement> _generateDestroyMethod(CompileView view) {
  var statements = <o.Statement>[];
  for (o.Expression child in view.viewContainers) {
    statements.add(child.callMethod('destroyNestedViews', []).toStmt());
  }
  for (o.Expression child in view.viewChildren) {
    statements.add(child.callMethod('destroyInternalState', []).toStmt());
  }
  statements.addAll(view.destroyMethod.finish());
  return statements;
}

/// Creates a factory function that instantiates a view.
///
/// ```
/// AppView<SomeComponent> viewFactory_SomeComponentHost0() {
///   return ViewSomeComponentHost0();
/// }
/// ```
o.Statement createViewFactory(CompileView view, o.ClassStmt viewClass) {
  switch (view.viewType) {
    case ViewType.embedded:
      return _createEmbeddedViewFactory(view, viewClass);
    case ViewType.host:
      return _createHostViewFactory(view, viewClass);
    default:
      throw StateError(
          'Can\'t create factory for view type "${view.viewType}"');
  }
}

o.Statement _createEmbeddedViewFactory(
    CompileView view, o.ClassStmt viewClass) {
  final parentViewType = o.importType(Identifiers.RenderView);
  final parameters = [
    o.FnParam(ViewConstructorVars.parentView.name, parentViewType),
    o.FnParam(ViewConstructorVars.parentIndex.name, o.INT_TYPE),
  ];
  // Unlike host view factories, the return type of an embedded view factory
  // doesn't need to include its component type. This is because we only need
  // access to the API of `AppView` itself to insert and remove embedded views
  // into view containers. Note that for generic embedded views, we can no
  // longer infer the generic type arguments of the constructor from the return
  // type, and must specify it within the function body.
  //
  //    AppView<void> viewFactory_FooComponent1<T>(...) {
  //      return ViewComponent1<T>(...);
  //    }
  //
  // We intentionally make this distinction as an optimization. Any time we take
  // a method tear-off (which we do every time an embedded view is used),
  // dart2js has to encode the return type of the method in the tear-off so that
  // it can be type checked properly.
  //
  // When two or more methods share the same type signature, their type encoding
  // can reference the same signatures. By removing the component type from the
  // return type of all embedded view factories, we allow all of them to share
  // the same type signature, instead of each one being unique, thus reducing
  // code size.
  final returnType = o.importType(Identifiers.AppView, [o.VOID_TYPE]);
  final constructorTypeArguments =
      viewClass.typeParameters.map((t) => t.toType()).toList();
  final body = [
    o.ReturnStatement(o.variable(viewClass.name).instantiate(
        parameters.map((p) => o.variable(p.name)).toList(),
        genericTypes: constructorTypeArguments)),
  ];
  return o.DeclareFunctionStmt(
    view.viewFactoryName,
    parameters,
    body,
    type: returnType,
    typeParameters: viewClass.typeParameters,
  );
}

o.Statement _createHostViewFactory(CompileView view, o.ClassStmt viewClass) {
  // For host view factories, the returned `AppView` must include the component
  // type as a type argument:
  //
  //    AppView<FooComponent> viewFactory_FooComponentHost0() { ... }
  //
  // This includes any generic type parameters the component itself might have.
  // Note how the generic type arguments of the constructor are inferred from
  // the return type.
  //
  //    AppView<BarComponent<T>> viewFactory_BarComponentHost0<T>() {
  //      return _ViewBarComponentHost0(null, null);
  //    }
  final returnTypeTypeArguments = [_getContextType(view)];
  final returnType = o.importType(Identifiers.AppView, returnTypeTypeArguments);
  // Note that for host views, and parent view and parent index are always null.
  final body = [
    o.ReturnStatement(
      o.variable(viewClass.name).instantiate([
        o.NULL_EXPR,
        o.NULL_EXPR,
      ]),
    ),
  ];
  return o.DeclareFunctionStmt(
    view.viewFactoryName,
    [], // No parameters.
    body,
    type: returnType,
    typeParameters: viewClass.typeParameters,
  );
}

List<o.Statement> _generateBuildMethod(CompileView view, Parser parser) {
  final parentRenderNodeStmts = <o.Statement>[];
  final isComponent = view.viewType == ViewType.component;
  if (isComponent) {
    final nodeType = o.importType(Identifiers.HTML_HTML_ELEMENT);
    final parentRenderNodeExpr =
        o.InvokeMemberMethodExpr('initViewRoot', const []);
    parentRenderNodeStmts.add(parentRenderNodeVar
        .set(parentRenderNodeExpr)
        .toDeclStmt(nodeType, [o.StmtModifier.Final]));
  }

  var statements = <o.Statement>[];
  var profileStartStatements = <o.Statement>[];
  var declStatements = <o.Statement>[];
  if (view.genConfig.profileFor == Profile.build) {
    genProfileBuildStart(view, profileStartStatements);
  }

  bool isComponentRoot = isComponent && view.viewIndex == 0;

  statements.addAll(parentRenderNodeStmts);
  view.writeBuildStatements(statements);

  final rootElements = createFlatArray(
    view.rootNodesOrViewContainers,
    constForEmpty: true,
  );
  final initParams = [rootElements];
  final subscriptions = view.subscriptions.isEmpty
      ? o.NULL_EXPR
      : o.literalArr(view.subscriptions, null);

  if (view.subscribesToMockLike) {
    // Mock-like directives may have null subscriptions which must be
    // filtered out to prevent an exception when they are later cancelled.
    final notNull = o.variable('notNull');
    final notNullAssignment = notNull.set(o.FunctionExpr(
      [o.FnParam('i')],
      [o.ReturnStatement(o.variable('i').notEquals(o.NULL_EXPR))],
    ));
    statements.add(notNullAssignment.toDeclStmt(null, [o.StmtModifier.Final]));
    final notNullSubscriptions =
        subscriptions.callMethod('where', [notNull]).callMethod('toList', []);
    initParams.add(notNullSubscriptions);
  } else {
    initParams.add(subscriptions);
  }

  if (rootElements is o.LiteralArrayExpr &&
      rootElements.entries.length <= 1 &&
      subscriptions == o.NULL_EXPR) {
    if (rootElements.entries.isEmpty) {
      statements.add(
        o.InvokeMemberMethodExpr('init0', const []).toStmt(),
      );
    } else {
      statements.add(
        o.InvokeMemberMethodExpr('init1', [rootElements.entries[0]]).toStmt(),
      );
    }
  } else {
    statements.add(o.InvokeMemberMethodExpr('init', initParams).toStmt());
  }

  if (isComponentRoot) {
    _writeComponentHostEventListeners(
      view,
      parser,
      statements,
      rootEl: parentRenderNodeVar,
    );
  }

  if (isComponentRoot &&
      view.component.changeDetection == ChangeDetectionStrategy.Stateful) {
    // Connect ComponentState callback to view.
    final setCallback = DetectChangesVars.internalSetStateChanged.callFn([
      DetectChangesVars.cachedCtx,
      o.ReadClassMemberExpr('markForCheck'),
    ]);
    statements.add(setCallback.toStmt());
  }

  if (view.genConfig.profileFor == Profile.build) {
    genProfileBuildEnd(view, statements);
  }

  if (identical(view.viewType, ViewType.host)) {
    if (view.nodes.isEmpty) {
      throwFailure('Template parser has crashed for ${view.className}');
    }
    var hostElement = view.nodes[0] as CompileElement;
    statements.add(
      o.ReturnStatement(
        o.importExpr(Identifiers.ComponentRef).instantiate([
          o.THIS_EXPR,
          hostElement.renderNode.toReadExpr(),
          hostElement.getComponent(),
        ]),
      ),
    );
    // Rely on the implicit `return null` for non host views. This reduces the
    // size of output from dart2js.
  }

  declStatements
      .addAll(maybeCachedCtxDeclarationStatement(statements: statements));
  return []
    ..addAll(profileStartStatements)
    ..addAll(declStatements)
    ..addAll(statements);
}

/// Writes shared event handler wiring for events that are directly defined
/// on host property of @Component annotation.
void _writeComponentHostEventListeners(
  CompileView view,
  Parser parser,
  List<o.Statement> statements, {
  @required o.Expression rootEl,
}) {
  CompileDirectiveMetadata component = view.component;
  var converter = BoundValueConverter.forView(view);
  for (String eventName in component.hostListeners.keys) {
    var boundEvent = _parseEvent(component, eventName, parser);

    o.Expression handlerExpr =
        converter.convertSourceToExpression(boundEvent.source, null);

    statements.add(bindingToUpdateStatement(
      boundEvent,
      rootEl,
      null,
      false,
      handlerExpr,
    ));
  }
}

ir.Binding _parseEvent(
    CompileDirectiveMetadata component, String eventName, Parser parser) {
  String handlerSource = component.hostListeners[eventName];
  var handlerAst = parser.parseAction(handlerSource, '', component.exports);
  var boundEvent = convertHostListenerToBinding(eventName, handlerAst);
  return boundEvent;
}

o.OutputType _getContextType(CompileView view) {
  // TODO(matanl): Cleanup in https://github.com/dart-lang/angular/issues/1421.
  final originType = view.component.originType;
  if (originType != null) {
    return o.importType(
      originType,
      originType.typeParameters.map((t) => t.toType()).toList(),
    );
  }
  return o.DYNAMIC_TYPE;
}

int _getChangeDetectionMode(CompileView view) {
  return view.viewType == ViewType.component &&
          view.component.changeDetection != ChangeDetectionStrategy.Default
      ? ChangeDetectionStrategy.CheckOnce
      : ChangeDetectionStrategy.CheckAlways;
}
