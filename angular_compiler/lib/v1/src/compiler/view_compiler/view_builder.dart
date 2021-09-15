import 'package:collection/collection.dart' show IterableExtension;
import 'package:angular/src/meta.dart';
import 'package:angular_compiler/v1/cli.dart';
import 'package:angular_compiler/v1/src/compiler/analyzed_class.dart';
import 'package:angular_compiler/v1/src/compiler/compile_metadata.dart'
    show CompileDirectiveMetadata;
import 'package:angular_compiler/v1/src/compiler/expression_parser/ast.dart';
import 'package:angular_compiler/v1/src/compiler/expression_parser/parser.dart'
    show ExpressionParser;
import 'package:angular_compiler/v1/src/compiler/identifiers.dart';
import 'package:angular_compiler/v1/src/compiler/ir/model.dart' as ir;
import 'package:angular_compiler/v1/src/compiler/output/output_ast.dart' as o;
import 'package:angular_compiler/v1/src/compiler/selector.dart';
import 'package:angular_compiler/v1/src/compiler/semantic_analysis/binding_converter.dart'
    show
        convertHostAttributeToBinding,
        convertHostListenerToBinding,
        convertToBinding;
import 'package:angular_compiler/v1/src/compiler/template_ast.dart';
import 'package:angular_compiler/v1/src/compiler/view_compiler/bound_value_converter.dart';
import 'package:angular_compiler/v1/src/compiler/view_compiler/update_statement_visitor.dart';
import 'package:angular_compiler/v1/src/compiler/view_type.dart';
import 'package:angular_compiler/v2/context.dart';

import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_view.dart';
import 'constants.dart'
    show
        changeDetectionStrategyToConst,
        parentRenderNodeVar,
        DetectChangesVars,
        ViewConstructorVars;
import 'provider_forest.dart' show ProviderForest, ProviderNode;
import 'view_compiler_utils.dart'
    show
        createFlatArrayForProjectNodes,
        detectHtmlElementFromTagName,
        identifierFromTagName,
        maybeCachedCtxDeclarationStatement,
        mergeHtmlAndDirectiveAttributes,
        namespaceUris,
        unsafeCast;
import 'view_style_linker.dart';

/// IMPORTANT: See the comment on [CompileView.nodes].
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
      CompileNode node, int? ngContentIndex, CompileElement parent) {
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
      _deadCodeWarning('Bound text node (${ast.value})', ast, parent);
      return;
    }
    _visitText(
      convertToBinding(ast, compileDirectiveMetadata: _view.component),
      parent,
      ast.ngContentIndex,
    );
  }

  @override
  void visitText(TextAst ast, CompileElement parent) {
    if (_maybeSkipNode(parent, ast.ngContentIndex)) {
      if (ast.value.trim() != '') {
        _deadCodeWarning('Non-empty text node (${ast.value})', ast, parent);
      }
      return;
    }
    _visitText(
      convertToBinding(ast, compileDirectiveMetadata: _view.component),
      parent,
      ast.ngContentIndex,
    );
  }

  @override
  void visitI18nText(I18nTextAst ast, CompileElement parent) {
    _visitText(
      convertToBinding(ast, compileDirectiveMetadata: _view.component),
      parent,
      ast.ngContentIndex,
    );
  }

  bool _maybeSkipNode(CompileElement parent, int? ngContentIndex) {
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
    logWarning(ast.sourceSpan.message('Dead code in template: '
        '$nodeDescription is a child of a non-projecting '
        'component (${parent.component!.selector}) and will not '
        'be added to the DOM.'));
  }

  void _visitText(
      ir.Binding binding, CompileElement parent, int? ngContentIndex) {
    var nodeIndex = _view.nodes.length;
    var renderNode = _nodeReference(binding, parent, nodeIndex);
    var compileNode = CompileNode(parent, _view, nodeIndex, renderNode);
    _view.nodes.add(compileNode);
    _addRootNodeAndProject(compileNode, ngContentIndex, parent);
  }

  NodeReference _nodeReference(
      ir.Binding binding, CompileElement parent, int nodeIndex) {
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
    _view.projectNodesIntoElement(parent, ast.index, ast.ngContentIndex);
    final reference = ast.reference;
    if (reference != null) {
      final provider = _view.createNgContentRefProvider(ast.index);
      final providerAst = ProviderAst(
        provider.token!,
        false,
        [provider],
        ProviderAstType.Builtin,
        ast.sourceSpan,
        eager: true,
      );
      var compileElement = CompileElement(
          parent,
          _view,
          ast.index,
          NodeReference.ngContent(_view.storage, ast.index),
          ast,
          null,
          [],
          [providerAst],
          false,
          false,
          [reference]);

      _view.nodes.add(compileElement);

      // Binds reference in <ng-content> to ViewComponent.
      _beforeChildren(compileElement);
    }
  }

  @override
  void visitElement(ElementAst ast, CompileElement parent) {
    var nodeIndex = _view.nodes.length;
    var directives = _toCompileMetadata(ast.directives);
    var component = _componentFromDirectives(directives);

    final elementRef = _elementReference(
      ast,
      nodeIndex,
      isComponent: component != null,
    );

    if (component != null) {
      _visitComponentElement(
        parent,
        nodeIndex,
        component,
        elementRef,
        directives,
        ast,
      );
    } else {
      _visitHtmlElement(
        parent,
        nodeIndex,
        elementRef,
        directives,
        ast,
      );
    }
  }

  NodeReference _elementReference(
    ElementAst ast,
    int nodeIndex, {
    required bool isComponent,
  }) {
    return NodeReference(
      _view.storage,
      // Root elements of a component are always an HtmlElement.
      isComponent
          ? o.importType(Identifiers.HTML_HTML_ELEMENT)
          : o.importType(identifierFromTagName(ast.name)),
      nodeIndex,
    );
  }

  CompileDirectiveMetadata? _componentFromDirectives(
          List<CompileDirectiveMetadata> directives) =>
      directives.firstWhereOrNull((directive) => directive.isComponent);

  /// Should be called before visiting the children of [element].
  void _beforeChildren(CompileElement element) {
    element.beforeChildren();
    _providerStack.add([]);
  }

  /// Should be called after visiting the children of [element].
  void _afterChildren(CompileElement element) {
    final childNodeCount = _view.nodes.length - element.nodeIndex! - 1;
    element.afterChildren(childNodeCount);
    final childProviderNodes = _providerStack.removeLast();
    final providerNode =
        element.createProviderNode(childNodeCount, childProviderNodes);
    _providerStack.last.add(providerNode);
  }

  void _visitComponentElement(
    CompileElement parent,
    int nodeIndex,
    CompileDirectiveMetadata component,
    NodeReference elementRef,
    List<CompileDirectiveMetadata> directives,
    ElementAst ast,
  ) {
    final componentViewExpr = _view.createComponentNodeAndAppend(
      _view.component,
      component,
      parent,
      elementRef,
      nodeIndex,
      ast,
    );

    var isHtmlElement = detectHtmlElementFromTagName(ast.name);

    final isHostView = _view.viewType == ViewType.host;

    if (!isHostView) {
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
      componentView: componentViewExpr,
      hasTemplateRefQuery: parent.hasTemplateRefQuery,
      isHtmlElement: isHtmlElement,
    );

    _view.addViewChild(compileElement);
    _view.nodes.add(compileElement);
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);

    _beforeChildren(compileElement);
    var oldVisitingProjectedContent = _visitingProjectedContent;
    _visitingProjectedContent = true;
    templateVisitAll(this, ast.children, compileElement);
    _visitingProjectedContent = oldVisitingProjectedContent;
    _afterChildren(compileElement);

    // Only component and embedded views need to generate code to create child
    // component views. Host views always have exactly one child component view,
    // which is created by hand-written code in `HostView.create()`.
    if (!isHostView) {
      final componentInstance = compileElement.getComponent()!;
      final projectedNodes = o.literalArr(
        compileElement.contentNodesByNgContentIndex
            .map(createFlatArrayForProjectNodes)
            .toList(),
      );
      _view.createComponentView(
        componentViewExpr,
        componentInstance,
        projectedNodes,
      );
    }
  }

  void _visitHtmlElement(
      CompileElement parent,
      int nodeIndex,
      NodeReference elementRef,
      List<CompileDirectiveMetadata> directives,
      ElementAst ast) {
    var tagName = ast.name;
    // Create element or elementNS. AST encodes svg path element as
    // @svg:path.
    var isNamespacedElement = tagName.startsWith('@') && tagName.contains(':');
    if (isNamespacedElement) {
      var nameParts = ast.name.substring(1).split(':');
      var ns = namespaceUris[nameParts[0]];
      _view.createElementNs(
          parent, elementRef, nodeIndex, ns, nameParts[1], ast);
    } else {
      _view.createElement(parent, elementRef, tagName, ast);
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
    var nodeReference = _view.createViewContainerAnchor(parent, nodeIndex, ast);
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

    var metadata = CompileDirectiveMetadata.from(_view.component,
        analyzedClass: AnalyzedClass.from(_view.component.analyzedClass!,
            additionalLocals: {
              for (var v in ast.variables) v.name: v.dartType,
            }));

    var embeddedView = CompileView(
      metadata,
      _view.genConfig,
      _view.directiveTypes,
      _view.pipeMetas,
      o.NULL_EXPR,
      _view.viewIndex + _nestedViewCount,
      compileElement,
      ast.variables,
      _view.genConfig.enableDataDebugSource,
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
  void visitDirectiveEvent(BoundDirectiveEventAst ast, CompileElement parent) {}

  @override
  void visitElementProperty(
      BoundElementPropertyAst ast, CompileElement parent) {}

  @override
  void visitProvider(ProviderAst ast, CompileElement parent) {}

  bool _isRootNode(CompileElement parent) {
    return !identical(parent.view, _view);
  }
}

/// Generates a class AST for a [view].
o.ClassStmt createViewClass(CompileView view, ExpressionParser parser) {
  final viewConstructor = _createViewConstructor(view);
  final viewMethods = [
    o.ClassMethod(
      'build',
      [],
      _generateBuildMethod(view, parser),
      null,
      null,
      [o.importExpr(Identifiers.dartCoreOverride)],
    ),
    view.writeInjectorGetMethod(),
    if (view.component.isChangeDetectionLink)
      o.ClassMethod(
        'detectChangesInCheckAlwaysViews',
        [],
        view.writeCheckAlwaysChangeDetectionStatements(),
        null,
        null,
        [o.importExpr(Identifiers.dartCoreOverride)],
      ),
    o.ClassMethod(
      'detectChangesInternal',
      [],
      view.writeChangeDetectionStatements(),
      null,
      null,
      [o.importExpr(Identifiers.dartCoreOverride)],
    ),
    if (view.viewType == ViewType.embedded)
      o.ClassMethod(
        'dirtyParentQueriesInternal',
        [],
        view.dirtyParentQueriesMethod.finish(),
        null,
        null,
        [o.importExpr(Identifiers.dartCoreOverride)],
      ),
    o.ClassMethod(
      'destroyInternal',
      [],
      _generateDestroyMethod(view),
      null,
      null,
      [o.importExpr(Identifiers.dartCoreOverride)],
    ),
    ...view.methods,
  ];
  if (view.viewType == ViewType.component &&
      view.detectHostChangesMethod != null) {
    final methodStatements = view.detectHostChangesMethod!.finish();
    viewMethods.add(
      o.ClassMethod(
        'detectHostChanges',
        [o.FnParam(DetectChangesVars.firstCheck.name!, o.BOOL_TYPE)],
        [
          ...maybeCachedCtxDeclarationStatement(statements: methodStatements),
          ...methodStatements,
        ],
      ),
    );
  }
  for (final method in viewMethods) {
    NodeReferenceStorageVisitor.visitScopedStatements(
        method.body as List<o.Statement>);
  }
  for (final getter in view.getters) {
    NodeReferenceStorageVisitor.visitScopedStatements(getter.body);
  }
  final viewClass = o.ClassStmt(
    view.className,
    _createParentClassExpr(view),
    view.storage.fields,
    view.getters,
    viewConstructor,
    viewMethods.where((method) => method.body.isNotEmpty).toList(),
    typeParameters: view.component.originType!.typeParameters,
  );
  initStyleEncapsulation(view, viewClass);
  return viewClass;
}

/// Generates a constructor AST for [view].
o.Constructor? _createViewConstructor(CompileView view) {
  switch (view.viewType) {
    case ViewType.component:
      return _createComponentViewConstructor(view);
    case ViewType.embedded:
      return _createEmbeddedViewConstructor(view);
    case ViewType.host:
      // Host views have no constructor parameters, thus don't require an
      // explicit constructor.
      return null;
    default:
      throw StateError('Unsupported $ViewType: ${view.viewType}');
  }
}

o.Constructor _createComponentViewConstructor(CompileView view) {
  final tagName = _tagNameFromComponentSelector(view.component.selector!);
  if (tagName.isEmpty) {
    throw BuildError.withoutContext(
      'Component selector is missing tag name in '
      '${view.component.identifier!.name} '
      'selector:${view.component.selector}',
    );
  }
  final rootElementRef = NodeReference.rootElement();
  final createRootElementExpr = o
      .importExpr(Identifiers.HTML_DOCUMENT)
      .callMethod('createElement', [o.literal(tagName)]);
  final body = [
    rootElementRef.toWriteStmt(unsafeCast(createRootElementExpr)),
  ];
  // Write literal attribute values on element.
  view.component.hostAttributes.forEach((name, value) {
    var binding = convertHostAttributeToBinding(
        name, ASTWithSource.missingSource(value), view.component);
    var statements = view.createAttributeStatements(
      binding,
      tagName,
      rootElementRef,
      isHtmlElement: detectHtmlElementFromTagName(tagName),
    );
    body.addAll(statements);
  });
  return o.Constructor(
    params: [
      o.FnParam(
        ViewConstructorVars.parentView.name!,
        o.importType(Views.view),
      ),
      o.FnParam(
        ViewConstructorVars.parentIndex.name!,
        o.INT_TYPE,
      ),
    ],
    initializers: [
      o.SUPER_EXPR.callFn([
        ViewConstructorVars.parentView,
        ViewConstructorVars.parentIndex,
        changeDetectionStrategyToConst(_getChangeDetectionMode(view)),
      ]).toStmt()
    ],
    body: body,
  );
}

o.Constructor _createEmbeddedViewConstructor(CompileView view) {
  return o.Constructor(
    params: [
      o.FnParam(
        ViewConstructorVars.parentView.name!,
        o.importType(Views.renderView),
      ),
      o.FnParam(
        ViewConstructorVars.parentIndex.name!,
        o.INT_TYPE,
      ),
    ],
    initializers: [
      o.SUPER_EXPR.callFn([
        ViewConstructorVars.parentView,
        ViewConstructorVars.parentIndex,
      ]).toStmt(),
    ],
  );
}

/// Creates the superclass that [view] derives.
o.Expression _createParentClassExpr(CompileView view) {
  final typeArgs = [contextType(view)];
  switch (view.viewType) {
    case ViewType.component:
      return o.importExpr(Views.componentView, typeParams: typeArgs);
    case ViewType.embedded:
      return o.importExpr(Views.embeddedView, typeParams: typeArgs);
    case ViewType.host:
      return o.importExpr(Views.hostView, typeParams: typeArgs);
    default:
      throw StateError('Unsupported $ViewType: ${view.viewType}');
  }
}

String _tagNameFromComponentSelector(String selector) {
  final selectors = CssSelector.parse(selector);
  // Return the first parsed element selector.
  for (final selector in selectors) {
    final element = selector.element;
    if (element != null) return element;
  }
  // TODO(b/144125308): should we throw here if there's no element selector?
  // Otherwise, just return the original selector as-is.
  // Some users have invalid space before selector in @Component, trim so
  // that document.createElement call doesn't fail.
  return selector.trim();
}

List<o.Statement> _generateDestroyMethod(CompileView view) {
  return [
    for (var viewContainer in view.viewContainers)
      viewContainer.callMethod('destroyNestedViews', []).toStmt(),
    // Host views handle calling `destroyInternalState()` on their sole
    // child component view.
    if (view.viewType != ViewType.host)
      for (var viewChild in view.viewChildren)
        viewChild.componentView!
            .callMethod('destroyInternalState', []).toStmt(),
    ...view.destroyMethod.finish(),
  ];
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
  final parentViewType = o.importType(Views.renderView);
  final parameters = [
    o.FnParam(ViewConstructorVars.parentView.name!, parentViewType),
    o.FnParam(ViewConstructorVars.parentIndex.name!, o.INT_TYPE),
  ];
  // Unlike host view factories, the return type of an embedded view factory
  // doesn't need to include its component type. This is because we only need
  // access to the API of `EmbeddedView` itself to insert and remove embedded
  // views into view containers. Note that for generic embedded views, we can no
  // longer infer the generic type arguments of the constructor from the return
  // type, and must specify it within the function body.
  //
  //    EmbeddedView<void> viewFactory_FooComponent1<T>(...) {
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
  final returnType = o.importType(Views.embeddedView, [o.VOID_TYPE]);
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
  // For host view factories, the returned `HostView` must include the component
  // type as a type argument:
  //
  //    HostView<FooComponent> viewFactory_FooComponentHost0() { ... }
  //
  // This includes any generic type parameters the component itself might have.
  // Note how the generic type arguments of the constructor are inferred from
  // the return type.
  //
  //    HostView<BarComponent<T>> viewFactory_BarComponentHost0<T>() {
  //      return _ViewBarComponentHost0();
  //    }
  final returnTypeTypeArguments = [contextType(view)];
  final returnType = o.importType(Views.hostView, returnTypeTypeArguments);
  final body = [
    o.ReturnStatement(
      o.variable(viewClass.name).instantiate([]),
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

List<o.Statement> _generateBuildMethod(
  CompileView view,
  ExpressionParser parser,
) {
  final parentRenderNodeStmts = <o.Statement>[];
  final isComponent = view.viewType == ViewType.component;
  if (isComponent) {
    final parentRenderNodeExpr = o.InvokeMemberMethodExpr(
      'initViewRoot',
      const [],
    );
    parentRenderNodeStmts.add(
      parentRenderNodeVar.set(parentRenderNodeExpr).toDeclStmt(
        null,
        [o.StmtModifier.Final],
      ),
    );
  }

  final statements = <o.Statement>[];

  statements.addAll(parentRenderNodeStmts);
  view.writeBuildStatements(statements);

  final initStatement = _generateInitStatement(view);
  if (initStatement != null) {
    statements.add(initStatement);
  }

  if (isComponent) {
    _writeComponentHostEventListeners(
      view,
      parser,
      statements,
      rootEl: parentRenderNodeVar,
    );
  }

  if (identical(view.viewType, ViewType.host)) {
    if (view.nodes.isEmpty) {
      throw BuildError.withoutContext(
        'Template parser has crashed for ${view.className}',
      );
    }
  }

  return [
    ...maybeCachedCtxDeclarationStatement(statements: statements),
    ...statements,
  ];
}

/// Returns a statement, if necessary, to record subscriptions or root nodes.
///
/// Returns null if no statement is necessary.
o.Statement? _generateInitStatement(CompileView view) {
  switch (view.viewType) {
    case ViewType.component:
      // Component views have no root nodes, so we only need to record
      // subscriptions if present.
      if (view.subscriptions.isNotEmpty) {
        return o.InvokeMemberMethodExpr('initSubscriptions', [
          _maybeFilterSubscriptions(view),
        ]).toStmt();
      }
      return null;
    case ViewType.embedded:
      final rootNodesExpr = createFlatArrayForProjectNodes(
        view.rootNodesOrViewContainers,
        constForEmpty: true,
      );
      // Embedded views may have any number of root nodes and subscriptions.
      if (rootNodesExpr is o.LiteralArrayExpr &&
          rootNodesExpr.entries.length == 1 &&
          view.subscriptions.isEmpty) {
        // Optimized method for embedded views with a single root node and no
        // subscriptions to avoid the cost of inlining any list allocations.
        return o.InvokeMemberMethodExpr('initRootNode', [
          rootNodesExpr.entries.single,
        ]).toStmt();
      } else {
        return o.InvokeMemberMethodExpr(
          'initRootNodesAndSubscriptions',
          [
            unsafeCast(rootNodesExpr),
            _maybeFilterSubscriptions(view),
          ],
        ).toStmt();
      }
    case ViewType.host:
      return o.InvokeMemberMethodExpr('initRootNode', [
        // Host views should have exactly one root node.
        view.rootNodesOrViewContainers.single,
      ]).toStmt();
    default:
      throw StateError('Unsupported $ViewType: ${view.viewType}');
  }
}

/// Returns [view.subscriptions], filtered for nulls if any are mock-like.
///
/// Normally it's assumed that directive outputs are non-null. However, when a
/// directive is mock-like, meaning it overrides [Object.noSuchMethod], any of
/// its outputs could now be null. This is prevalent in tests, where complex
/// directives are commonly mocked. In such a case, any null outputs will result
/// in null subscriptions which must be filtered so that the view doesn't
/// attempt to cancel them when it's destroyed.
///
/// Returns a null expression if there are no subscriptions.
o.Expression _maybeFilterSubscriptions(CompileView view) {
  if (view.subscriptions.isEmpty) {
    return o.NULL_EXPR;
  }
  final subscriptionsExpr = o.literalArr(view.subscriptions);
  if (view.subscribesToMockLike) {
    // Mock-like directives may have null subscriptions which must be
    // filtered out to prevent an exception when they are later cancelled.
    return subscriptionsExpr.callMethod('where', [
      o.FunctionExpr(
        [o.FnParam('i')],
        [o.ReturnStatement(o.variable('i').notEquals(o.NULL_EXPR))],
      )
    ]).callMethod('toList', []);
  }
  return subscriptionsExpr;
}

/// Writes shared event handler wiring for events that are directly defined
/// on host property of @Component annotation.
void _writeComponentHostEventListeners(
  CompileView view,
  ExpressionParser parser,
  List<o.Statement> statements, {
  required o.Expression rootEl,
}) {
  var component = view.component;
  var converter = BoundValueConverter.forView(view);
  for (var eventName in component.hostListeners.keys) {
    var boundEvent = _parseEvent(component, eventName, parser);

    var handlerExpr = converter.convertSourceToExpression(
        boundEvent.source, boundEvent.target.type)!;

    statements.addAll(bindingToUpdateStatements(
      boundEvent,
      rootEl,
      null,
      false,
      handlerExpr,
    ));
  }
}

ir.Binding _parseEvent(CompileDirectiveMetadata component, String eventName,
    ExpressionParser parser) {
  var handlerSource = component.hostListeners[eventName];
  var handlerAst = parser.parseAction(handlerSource, '', component.exports);
  var boundEvent = convertHostListenerToBinding(eventName, handlerAst);
  return boundEvent;
}

o.OutputType contextType(CompileView view) {
  final type = view.component.originType!;
  return o.importType(
    type,
    type.typeParameters.map((t) => t.toType()).toList(),
  )!;
}

int _getChangeDetectionMode(CompileView view) {
  return view.viewType == ViewType.component &&
          view.component.changeDetection != ChangeDetectionStrategy.Default
      ? ChangeDetectionStrategy.CheckOnce
      : ChangeDetectionStrategy.CheckAlways;
}
