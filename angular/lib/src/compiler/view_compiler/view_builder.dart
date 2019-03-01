import 'package:meta/meta.dart';
import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/compile_metadata.dart'
    show CompileDirectiveMetadata;
import 'package:angular/src/compiler/expression_parser/parser.dart' show Parser;
import 'package:angular/src/compiler/html_events.dart';
import 'package:angular/src/compiler/identifiers.dart' show Identifiers;
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/template_ast.dart';
import 'package:angular/src/compiler/template_parser/is_pure_html.dart';
import 'package:angular/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy, isDefaultChangeDetectionStrategy;
import 'package:angular/src/core/linker/view_type.dart';
import 'package:angular_compiler/cli.dart';

import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_view.dart';
import 'constants.dart'
    show
        appViewRootElementName,
        createEnumExpression,
        changeDetectionStrategyToConst,
        parentRenderNodeVar,
        DetectChangesVars,
        EventHandlerVars,
        ViewConstructorVars,
        ViewProperties;
import 'event_binder.dart' show convertStmtIntoExpression;
import 'expression_converter.dart';
import 'parse_utils.dart';
import 'perf_profiler.dart';
import 'view_compiler_utils.dart'
    show
        cachedParentIndexVarName,
        createFlatArray,
        detectHtmlElementFromTagName,
        identifierFromTagName,
        mergeHtmlAndDirectiveAttributes,
        namespaceUris;
import 'view_style_linker.dart';

class ViewBuilderVisitor implements TemplateAstVisitor<void, CompileElement> {
  final CompileView _view;

  /// This is `true` if this is visiting nodes that will be projected into
  /// another view.
  bool _visitingProjectedContent = false;

  int _nestedViewCount = 0;

  ViewBuilderVisitor(this._view);

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
        ir.Binding(
            source: ir.BoundExpression(
                ast.value, ast.sourceSpan, _view.component.analyzedClass),
            target: ir.TextBinding()),
        parent,
        ast.ngContentIndex);
  }

  @override
  void visitText(TextAst ast, CompileElement parent) {
    if (_maybeSkipNode(parent, ast.ngContentIndex)) {
      if (ast.value.trim() != '') {
        _deadCodeWarning("Non-empty text node (${ast.value})", ast, parent);
      }
      return;
    }
    _visitText(
        ir.Binding(
            source: ir.StringLiteral(ast.value), target: ir.TextBinding()),
        parent,
        ast.ngContentIndex);
  }

  @override
  void visitI18nText(I18nTextAst ast, CompileElement parent) {
    _visitText(
        ir.Binding(
            source: ir.BoundI18nMessage(ast.value),
            target:
                ast.value.containsHtml ? ir.HtmlBinding() : ir.TextBinding()),
        parent,
        ast.ngContentIndex);
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
    final type = o.importType(identifierFromTagName(ast.name));
    if (_view.isRootNodeOfHost(nodeIndex)) {
      return NodeReference.appViewRoot();
    } else if (_view.isInlined) {
      return NodeReference.inlinedNode(
          _view.storage, type, _view.declarationElement.nodeIndex, nodeIndex);
    } else {
      return NodeReference(_view.storage, type, nodeIndex);
    }
  }

  CompileDirectiveMetadata _componentFromDirectives(
          List<CompileDirectiveMetadata> directives) =>
      directives.firstWhere((directive) => directive.isComponent,
          orElse: () => null);

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

    if (_view.viewType != ViewType.host) {
      var mergedBindings = mergeHtmlAndDirectiveAttributes(
          ast, directives, _view.component.analyzedClass);
      _view.writeLiteralAttributeValues(ast.name, elementRef, mergedBindings);
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
      isHtmlElement: detectHtmlElementFromTagName(ast.name),
      isDeferredComponent: isDeferred,
    );

    _view.addViewChild(compAppViewExpr);
    _view.nodes.add(compileElement);

    // beforeChildren() -> _prepareProviderInstances will create the actual
    // directive and component instances.
    compileElement.beforeChildren();
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    bool oldVisitingProjectedContent = _visitingProjectedContent;
    _visitingProjectedContent = true;
    templateVisitAll(this, ast.children, compileElement);
    _visitingProjectedContent = oldVisitingProjectedContent;

    compileElement.afterChildren(_view.nodes.length - nodeIndex - 1);

    o.Expression projectables;
    if (_view.component.type.isHost) {
      projectables = ViewProperties.projectableNodes;
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

    var mergedBindings = mergeHtmlAndDirectiveAttributes(
        ast, directives, _view.component.analyzedClass);
    _view.writeLiteralAttributeValues(ast.name, elementRef, mergedBindings);

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
        isHtmlElement: detectHtmlElementFromTagName(tagName),
        hasTemplateRefQuery: parent.hasTemplateRefQuery);

    _view.nodes.add(compileElement);
    // beforeChildren() -> _prepareProviderInstances will create the actual
    // directive and component instances.
    compileElement.beforeChildren();
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    templateVisitAll(this, ast.children, compileElement);
    compileElement.afterChildren(_view.nodes.length - nodeIndex - 1);
  }

  @override
  void visitEmbeddedTemplate(EmbeddedTemplateAst ast, CompileElement parent) {
    var nodeIndex = _view.nodes.length;
    var isPureHtml = !_visitingProjectedContent && _isPureHtml(ast);
    if (isPureHtml) {
      _view.hasInlinedView = true;
    }
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
        isInlined: isPureHtml);
    _view.nodes.add(compileElement);
    _nestedViewCount++;

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
        isInlined: isPureHtml);

    // Create a visitor for embedded view and visit all nodes.
    var embeddedViewVisitor = ViewBuilderVisitor(embeddedView);
    templateVisitAll(
        embeddedViewVisitor,
        ast.children,
        embeddedView.declarationElement.parent ??
            embeddedView.declarationElement);
    _nestedViewCount += embeddedViewVisitor._nestedViewCount;

    if (!isPureHtml) {
      compileElement.beforeChildren();
    }
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    if (!isPureHtml) {
      compileElement.afterChildren(0);
    }
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
    viewMethods.add(o.ClassMethod(
        'detectHostChanges',
        [o.FnParam(DetectChangesVars.firstCheck.name, o.BOOL_TYPE)],
        view.detectHostChangesMethod.finish()));
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
    o.FnParam(ViewConstructorVars.parentView.name,
        o.importType(Identifiers.AppView, [o.DYNAMIC_TYPE])),
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

    ctor.body.add(
        o.WriteClassMemberExpr(appViewRootElementName, createRootElementExpr)
            .toStmt());

    // Write literal attribute values on element.
    CompileDirectiveMetadata componentMeta = view.component;
    componentMeta.hostAttributes.forEach((name, value) {
      var binding = ir.Binding(
          source: ir.BoundExpression(value, null, view.component.analyzedClass),
          target: ir.AttributeBinding(name));
      var statement = view.createAttributeStatement(
        binding.source,
        binding.target as ir.AttributeBinding,
        tagName,
        o.variable(appViewRootElementName),
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
    statements.add(child.callMethod('destroy', []).toStmt());
  }
  statements.addAll(view.destroyMethod.finish());
  return statements;
}

/// Creates a factory function that instantiates a view.
///
/// ```
/// AppView<SomeComponent> viewFactory_SomeComponentHost0(
///   AppView<dynamic> parentView,
///   int parentIndex,
/// ) {
///   return ViewSomeComponentHost0(parentView, parentIndex);
/// }
/// ```
o.Statement createViewFactory(CompileView view, o.ClassStmt viewClass) {
  final parentViewType = o.importType(Identifiers.AppView, [o.DYNAMIC_TYPE]);
  final parameters = [
    o.FnParam(ViewConstructorVars.parentView.name, parentViewType),
    o.FnParam(ViewConstructorVars.parentIndex.name, o.INT_TYPE),
  ];
  // For component and host view factories, the returned `AppView` must include
  // the component type as a type argument:
  //
  //     AppView<FooComponent> viewFactory_FooComponent0(...) { ... }
  //
  // This includes any generic type parameters the component itself might have.
  // Note how the generic type arguments of the constructor are inferred from
  // the return type.
  //
  //   AppView<BarComponent<T>> viewFactory_FooComponent0<T>(...) {
  //     return ViewFooComponent0(...);
  //   }
  //
  // In contrast, the return type of an embedded view factory doesn't need to
  // include its component type. This is because we only need access to the API
  // of `AppView` itself to insert and remove embedded views into view
  // containers. Note that for generic embedded views, we can no longer infer
  // the generic type arguments of the constructor from the return type.
  //
  //   AppView<void> viewFactory_FooComponent1<T>(...) {
  //     return ViewComponent1<T>(...);
  //   }
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
  List<o.OutputType> constructorTypeArguments;
  List<o.OutputType> returnTypeTypeArguments;
  if (view.viewType == ViewType.embedded) {
    constructorTypeArguments =
        viewClass.typeParameters.map((t) => t.toType()).toList();
    returnTypeTypeArguments = [o.VOID_TYPE];
  } else {
    returnTypeTypeArguments = [_getContextType(view)];
  }
  final body = [
    o.ReturnStatement(o.variable(viewClass.name).instantiate(
        parameters.map((p) => o.variable(p.name)).toList(),
        genericTypes: constructorTypeArguments)),
  ];
  final returnType = o.importType(Identifiers.AppView, returnTypeTypeArguments);
  return o.DeclareFunctionStmt(
    view.viewFactoryName,
    parameters,
    body,
    type: returnType,
    typeParameters: viewClass.typeParameters,
  );
}

List<o.Statement> _generateBuildMethod(CompileView view, Parser parser) {
  // Hoist the `rootEl` class field as `_rootEl` locally for Dart2JS.
  o.ReadVarExpr cachedRootEl;
  final parentRenderNodeStmts = <o.Statement>[];
  final isComponent = view.viewType == ViewType.component;
  if (isComponent) {
    cachedRootEl = o.variable('_rootEl');
    parentRenderNodeStmts.add(cachedRootEl
        .set(o.ReadClassMemberExpr(appViewRootElementName))
        .toDeclStmt(null, [o.StmtModifier.Final]));
    final nodeType = o.importType(Identifiers.HTML_HTML_ELEMENT);
    final parentRenderNodeExpr = o.InvokeMemberMethodExpr(
      "initViewRoot",
      [cachedRootEl],
    );
    parentRenderNodeStmts.add(parentRenderNodeVar
        .set(parentRenderNodeExpr)
        .toDeclStmt(nodeType, [o.StmtModifier.Final]));
  }

  var statements = <o.Statement>[];
  if (view.genConfig.profileFor == Profile.build) {
    genProfileBuildStart(view, statements);
  }

  bool isComponentRoot = isComponent && view.viewIndex == 0;

  if (isComponentRoot &&
      (view.component.changeDetection == ChangeDetectionStrategy.Stateful ||
          view.component.hostListeners.isNotEmpty)) {
    // Cache [ctx] class field member as typed [_ctx] local for change detection
    // code to consume.
    var contextType = view.viewType != ViewType.host
        ? o.importType(view.component.type)
        : null;
    statements.add(DetectChangesVars.cachedCtx
        .set(o.ReadClassMemberExpr('ctx'))
        .toDeclStmt(contextType, [o.StmtModifier.Final]));
  }

  statements.addAll(parentRenderNodeStmts);
  view.writeBuildStatements(statements);

  final rootElements = createFlatArray(view.rootNodesOrViewContainers,
      constForEmpty: !view.hasInlinedView);
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

  // In RELEASE mode we call:
  //
  // init(rootNodes, subscriptions);
  // or init0 if we have a single root node with no subscriptions.
  if (rootElements is o.LiteralArrayExpr &&
      rootElements.entries.length == 1 &&
      subscriptions == o.NULL_EXPR) {
    statements.add(
        o.InvokeMemberMethodExpr('init0', [rootElements.entries[0]]).toStmt());
  } else {
    statements.add(o.InvokeMemberMethodExpr('init', initParams).toStmt());
  }

  if (isComponentRoot) {
    _writeComponentHostEventListeners(
      view,
      parser,
      statements,
      rootEl: cachedRootEl,
    );
  }

  if (isComponentRoot &&
      view.component.changeDetection == ChangeDetectionStrategy.Stateful) {
    // Connect ComponentState callback to view.
    statements.add((DetectChangesVars.cachedCtx
            .prop('stateChangeCallback')
            .set(o.ReadClassMemberExpr('markStateChanged')))
        .toStmt());
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
        o.ReturnStatement(o.importExpr(Identifiers.ComponentRef).instantiate(
      [
        o.literal(hostElement.nodeIndex),
        o.THIS_EXPR,
        hostElement.renderNode.toReadExpr(),
        hostElement.getComponent()
      ],
    )));
    // Rely on the implicit `return null` for non host views. This reduces the
    // size of output from dart2js.
  }

  var readVars = o.findReadVarNames(statements);
  if (readVars.contains(cachedParentIndexVarName)) {
    statements.insert(
        0,
        o.DeclareVarStmt(cachedParentIndexVarName,
            o.ReadClassMemberExpr('viewData').prop('parentIndex')));
  }
  return statements;
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
  for (String eventName in component.hostListeners.keys) {
    String handlerSource = component.hostListeners[eventName];
    var handlerAst = parser.parseAction(handlerSource, '', component.exports);
    HandlerType handlerType = handlerTypeFromExpression(handlerAst);
    o.Expression handlerExpr;
    int numArgs;
    if (handlerType == HandlerType.notSimple) {
      var context = o.ReadClassMemberExpr('ctx');
      var actionStmts = convertCdStatementToIr(
        view.nameResolver,
        context,
        handlerAst,
        // The only way a host listener could fail expression conversion is if
        // the arguments specified in the `HostListener` annotation are invalid,
        // but we don't have its source span to provide here.
        null,
        component,
      );
      var actionExpr = convertStmtIntoExpression(actionStmts.last);
      List<o.Statement> stmts = <o.Statement>[o.ReturnStatement(actionExpr)];
      String methodName = '_handle_${sanitizeEventName(eventName)}__';
      view.methods.add(o.ClassMethod(
          methodName,
          [o.FnParam(EventHandlerVars.event.name, o.importType(null))],
          stmts,
          o.BOOL_TYPE,
          [o.StmtModifier.Private]));
      handlerExpr = o.ReadClassMemberExpr(methodName);
      numArgs = 1;
    } else {
      var context = DetectChangesVars.cachedCtx;
      var actionStmts = convertCdStatementToIr(
        view.nameResolver,
        context,
        handlerAst,
        // The only way a host listener could fail expression conversion is if
        // the arguments specified in the `HostListener` annotation are invalid,
        // but we don't have its source span to provide here.
        null,
        component,
      );
      var actionExpr = convertStmtIntoExpression(actionStmts.last);
      assert(actionExpr is o.InvokeMethodExpr);
      var callExpr = actionExpr as o.InvokeMethodExpr;
      handlerExpr = o.ReadPropExpr(callExpr.receiver, callExpr.name);
      numArgs = handlerType == HandlerType.simpleNoArgs ? 0 : 1;
    }

    final wrappedHandlerExpr = o.InvokeMemberMethodExpr(
      'eventHandler$numArgs',
      [handlerExpr],
    );

    o.Expression listenExpr;
    if (isNativeHtmlEvent(eventName)) {
      listenExpr = rootEl.callMethod(
        'addEventListener',
        [o.literal(eventName), wrappedHandlerExpr],
      );
    } else {
      final appViewUtilsExpr = o.importExpr(Identifiers.appViewUtils);
      final eventManagerExpr = appViewUtilsExpr.prop('eventManager');
      listenExpr = eventManagerExpr.callMethod(
        'addEventListener',
        [rootEl, o.literal(eventName), wrappedHandlerExpr],
      );
    }
    statements.add(listenExpr.toStmt());
  }
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
  int mode;
  if (identical(view.viewType, ViewType.component)) {
    mode = isDefaultChangeDetectionStrategy(view.component.changeDetection)
        ? ChangeDetectionStrategy.CheckAlways
        : ChangeDetectionStrategy.CheckOnce;
  } else {
    mode = ChangeDetectionStrategy.CheckAlways;
  }
  return mode;
}

final _pureHtmlVisitor = IsPureHtmlVisitor();

bool _isPureHtml(EmbeddedTemplateAst ast) {
  if (ast.directives.length != 1) return false;
  var isNgIf = ast.directives.single.directive.identifier.name == 'NgIf';
  if (!isNgIf) return false;

  return ast.children.every((t) => t.visit(_pureHtmlVisitor, null));
}

/// Constructs name of global function that can be used to update an input
/// on a component with change detection.
String buildUpdaterFunctionName(String typeName, String inputName) =>
    'set' + typeName + r'$' + inputName;
