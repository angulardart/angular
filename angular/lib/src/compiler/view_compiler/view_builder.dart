import 'package:angular/src/compiler/output/output_ast.dart';
import 'package:angular/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy, isDefaultChangeDetectionStrategy;
import 'package:angular/src/core/linker/view_type.dart';
import 'package:angular/src/core/app_view_consts.dart' show namespaceUris;
import 'package:angular_compiler/cli.dart';
import 'package:meta/meta.dart';

import '../compile_metadata.dart'
    show CompileDirectiveMetadata, CompileTypeMetadata;
import '../expression_parser/parser.dart' show Parser;
import '../html_events.dart';
import '../identifiers.dart' show Identifiers, identifierToken;
import '../is_pure_html.dart';
import '../output/output_ast.dart' as o;
import '../provider_parser.dart' show ngIfTokenMetadata, ngForTokenMetadata;
import '../style_compiler.dart' show StylesCompileResult;
import '../template_ast.dart'
    show
        AttrAst,
        BoundDirectivePropertyAst,
        BoundElementPropertyAst,
        BoundEventAst,
        BoundTextAst,
        DirectiveAst,
        ElementAst,
        EmbeddedTemplateAst,
        NgContentAst,
        ProviderAst,
        ReferenceAst,
        TemplateAstVisitor,
        TextAst,
        VariableAst,
        templateVisitAll;
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
        createDebugInfoTokenExpression,
        createSetAttributeStatement,
        detectHtmlElementFromTagName,
        componentFromDirectives,
        identifierFromTagName;

var rootSelectorVar = o.variable("rootSelector");

class ViewBuilderVisitor implements TemplateAstVisitor<void, CompileElement> {
  final CompileView view;
  final StylesCompileResult stylesCompileResult;

  /// This is `true` if this is building a view that will be inlined into it's
  /// parent view.
  final bool isInlinedView;

  /// This is `true` if this is visiting nodes that will be projected into
  /// another view.
  bool visitingProjectedContent = false;

  int nestedViewCount = 0;

  /// Local variable name used to refer to document. null if not created yet.
  static final defaultDocVarName = 'doc';
  String docVarName;

  ViewBuilderVisitor(
    this.view,
    this.stylesCompileResult, {
    this.isInlinedView: false,
  });

  bool _isRootNode(CompileElement parent) {
    return !identical(parent.view, this.view);
  }

  void _addRootNodeAndProject(
      CompileNode node, int ngContentIndex, CompileElement parent) {
    var vcAppEl = (node is CompileElement && node.hasViewContainer)
        ? node.appViewContainer
        : null;
    if (_isRootNode(parent)) {
      // store appElement as root node only for ViewContainers
      if (view.viewType != ViewType.component) {
        view.rootNodesOrViewContainers
            .add(vcAppEl ?? node.renderNode.toReadExpr());
      }
    } else if (parent.component != null && ngContentIndex != null) {
      parent.addContentNode(
          ngContentIndex, vcAppEl ?? node.renderNode.toReadExpr());
    }
  }

  void visitBoundText(BoundTextAst ast, CompileElement parent) {
    int nodeIndex = view.nodes.length;
    NodeReference renderNode = view.createBoundTextNode(parent, nodeIndex, ast);
    var compileNode = new CompileNode(parent, view, nodeIndex, renderNode, ast);
    view.nodes.add(compileNode);
    _addRootNodeAndProject(compileNode, ast.ngContentIndex, parent);
  }

  void visitText(TextAst ast, CompileElement parent) {
    int nodeIndex = view.nodes.length;
    NodeReference renderNode =
        view.createTextNode(parent, nodeIndex, ast.value, ast);
    var compileNode = new CompileNode(parent, view, nodeIndex, renderNode, ast);
    view.nodes.add(compileNode);
    _addRootNodeAndProject(compileNode, ast.ngContentIndex, parent);
  }

  void visitNgContent(NgContentAst ast, CompileElement parent) {
    view.projectNodesIntoElement(parent, ast.index, ast);
  }

  void visitElement(ElementAst ast, CompileElement parent) {
    int nodeIndex = view.nodes.length;

    bool isHostRootView = nodeIndex == 0 && view.viewType == ViewType.host;
    NodeReference elementRef;
    if (isHostRootView) {
      elementRef = new NodeReference.appViewRoot();
    } else if (view.isInlined) {
      elementRef = new NodeReference.inlinedNode(
          parent, view.declarationElement.nodeIndex, nodeIndex);
    } else {
      elementRef = new NodeReference(parent, nodeIndex);
    }

    var directives = <CompileDirectiveMetadata>[];
    for (var dir in ast.directives) directives.add(dir.directive);
    CompileDirectiveMetadata component = componentFromDirectives(directives);

    if (component != null) {
      bool isDeferred = nodeIndex == 0 &&
          (view.declarationElement.sourceAst is EmbeddedTemplateAst) &&
          (view.declarationElement.sourceAst as EmbeddedTemplateAst)
              .hasDeferredComponent;
      _visitComponentElement(
          parent, nodeIndex, component, elementRef, directives, ast,
          isDeferred: isDeferred);
    } else {
      _visitHtmlElement(parent, nodeIndex, elementRef, directives, ast);
    }
  }

  void _visitComponentElement(
      CompileElement parent,
      int nodeIndex,
      CompileDirectiveMetadata component,
      NodeReference elementRef,
      List<CompileDirectiveMetadata> directives,
      ElementAst ast,
      {bool isDeferred: false}) {
    AppViewReference compAppViewExpr = view.createComponentNodeAndAppend(
        component, parent, elementRef, nodeIndex, ast,
        isDeferred: isDeferred);

    if (view.viewType != ViewType.host) {
      view.writeLiteralAttributeValues(ast, elementRef, nodeIndex, directives);
    }

    view.shimCssForNode(elementRef, nodeIndex, Identifiers.HTML_HTML_ELEMENT);

    var compileElement = new CompileElement(
        parent,
        this.view,
        nodeIndex,
        elementRef,
        ast,
        component,
        directives,
        ast.providers,
        ast.hasViewContainer,
        false,
        ast.references,
        isHtmlElement: detectHtmlElementFromTagName(ast.name),
        hasTemplateRefQuery: parent.hasTemplateRefQuery,
        isDeferredComponent: isDeferred);

    view.nodes.add(compileElement);

    if (component != null) {
      compileElement.componentView = compAppViewExpr.toReadExpr();
      view.addViewChild(compAppViewExpr.toReadExpr());
    }

    // beforeChildren() -> _prepareProviderInstances will create the actual
    // directive and component instances.
    compileElement.beforeChildren();
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    bool oldVisitingProjectedContent = visitingProjectedContent;
    visitingProjectedContent = true;
    templateVisitAll(this, ast.children, compileElement);
    visitingProjectedContent = oldVisitingProjectedContent;

    compileElement.afterChildren(view.nodes.length - nodeIndex - 1);

    o.Expression projectables;
    if (view.component.type.isHost) {
      projectables = ViewProperties.projectableNodes;
    } else {
      projectables = o.literalArr(compileElement.contentNodesByNgContentIndex
          .map((nodes) => createFlatArray(nodes))
          .toList());
    }
    var componentInstance = compileElement.getComponent();
    view.createAppView(compAppViewExpr, componentInstance, projectables);
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
      view.createElementNs(
          parent, elementRef, nodeIndex, ns, nameParts[1], ast);
    } else {
      view.createElement(parent, elementRef, nodeIndex, tagName, ast);
    }

    view.writeLiteralAttributeValues(ast, elementRef, nodeIndex, directives);

    bool isHostRootView = nodeIndex == 0 && view.viewType == ViewType.host;
    // Set ng_content class for CSS shim.
    var elementType = isHostRootView
        ? Identifiers.HTML_HTML_ELEMENT
        : identifierFromTagName(ast.name);
    view.shimCssForNode(elementRef, nodeIndex, elementType);

    var compileElement = new CompileElement(
        parent,
        this.view,
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

    view.nodes.add(compileElement);
    // beforeChildren() -> _prepareProviderInstances will create the actual
    // directive and component instances.
    compileElement.beforeChildren();
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    templateVisitAll(this, ast.children, compileElement);
    compileElement.afterChildren(view.nodes.length - nodeIndex - 1);
  }

  void visitEmbeddedTemplate(EmbeddedTemplateAst ast, CompileElement parent) {
    var nodeIndex = view.nodes.length;
    var isPureHtml = !visitingProjectedContent && _isPureHtml(ast);
    if (isPureHtml) {
      view.hasInlinedView = true;
    }
    NodeReference nodeReference =
        view.createViewContainerAnchor(parent, nodeIndex, ast, isPureHtml);
    var directives =
        ast.directives.map((directiveAst) => directiveAst.directive).toList();
    var compileElement = new CompileElement(
        parent,
        this.view,
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
    view.nodes.add(compileElement);
    nestedViewCount++;
    var embeddedView = new CompileView(
        view.component,
        view.genConfig,
        view.pipeMetas,
        o.NULL_EXPR,
        view.viewIndex + nestedViewCount,
        compileElement,
        ast.variables,
        view.deferredModules,
        isInlined: isPureHtml);

    // Create a visitor for embedded view and visit all nodes.
    var embeddedViewVisitor = new ViewBuilderVisitor(
        embeddedView, stylesCompileResult,
        isInlinedView: isPureHtml);
    templateVisitAll(
        embeddedViewVisitor,
        ast.children,
        embeddedView.declarationElement.parent ??
            embeddedView.declarationElement);
    nestedViewCount += embeddedViewVisitor.nestedViewCount;

    if (!isPureHtml) {
      compileElement.beforeChildren();
    }
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    if (!isPureHtml) {
      compileElement.afterChildren(0);
    }
    if (ast.hasDeferredComponent) {
      view.deferLoadEmbeddedTemplate(embeddedView, compileElement);
    }
  }

  void visitAttr(AttrAst ast, CompileElement parent) {}

  void visitDirective(DirectiveAst ast, CompileElement parent) {}

  void visitEvent(BoundEventAst ast, CompileElement parent) {}

  void visitReference(ReferenceAst ast, CompileElement parent) {}

  void visitVariable(VariableAst ast, CompileElement parent) {}

  void visitDirectiveProperty(
      BoundDirectivePropertyAst ast, CompileElement parent) {}

  void visitElementProperty(
      BoundElementPropertyAst ast, CompileElement parent) {}

  void visitProvider(ProviderAst ast, CompileElement parent) {}
}

o.Expression createStaticNodeDebugInfo(CompileNode node) {
  var compileElement = node is CompileElement ? node : null;
  List<o.Expression> providerTokens = [];
  o.Expression componentToken = o.NULL_EXPR;
  var varTokenEntries = <List>[];
  if (compileElement != null) {
    providerTokens = compileElement.getProviderTokens();
    if (compileElement.component != null) {
      componentToken = createDebugInfoTokenExpression(
          identifierToken(compileElement.component.type));
    }
    compileElement.referenceTokens?.forEach((String varName, token) {
      // Skip generating debug info for NgIf/NgFor since they are not
      // reachable through injection anymore.
      if (token == null ||
          !(token.equalsTo(ngIfTokenMetadata) ||
              token.equalsTo(ngForTokenMetadata))) {
        varTokenEntries.add([
          varName,
          token != null ? createDebugInfoTokenExpression(token) : o.NULL_EXPR
        ]);
      }
    });
  }
  // Optimize StaticNodeDebugInfo(const [],null,const <String, dynamic>{}), case
  // by writing out null.
  if (providerTokens.isEmpty &&
      componentToken == o.NULL_EXPR &&
      varTokenEntries.isEmpty) {
    return o.NULL_EXPR;
  }
  return o.importExpr(Identifiers.StaticNodeDebugInfo).instantiate([
    o.literalArr(providerTokens, new o.ArrayType(o.DYNAMIC_TYPE)),
    componentToken,
    o.literalMap(varTokenEntries, new o.MapType(o.DYNAMIC_TYPE))
  ], o.importType(Identifiers.StaticNodeDebugInfo, null));
}

/// Generates output ast for a CompileView and returns a [ClassStmt] for the
/// view of embedded template.
o.ClassStmt createViewClass(
    CompileView view, o.Expression nodeDebugInfosVar, Parser parser) {
  var viewConstructor = _createViewClassConstructor(view, nodeDebugInfosVar);
  var viewMethods = <o.ClassMethod>[
    new o.ClassMethod(
        "build",
        [],
        generateBuildMethod(view, parser),
        o.importType(
          Identifiers.ComponentRef,
          // The 'HOST' view is a <dynamic> view that "hosts" the actual
          // component view, therefore it is not typed.
          view.viewType != ViewType.host
              ? [o.importType(view.component.type)]
              : const [],
        ),
        null,
        ['override']),
    view.writeInjectorGetMethod(),
    new o.ClassMethod("detectChangesInternal", [],
        view.writeChangeDetectionStatements(), null, null, ['override']),
    new o.ClassMethod("dirtyParentQueriesInternal", [],
        view.dirtyParentQueriesMethod.finish(), null, null, ['override']),
    new o.ClassMethod("destroyInternal", [], generateDestroyMethod(view), null,
        null, ['override'])
  ]..addAll(view.eventHandlerMethods);
  if (view.detectHostChangesMethod != null) {
    viewMethods.add(new o.ClassMethod(
        'detectHostChanges',
        [new o.FnParam(DetectChangesVars.firstCheck.name, o.BOOL_TYPE)],
        view.detectHostChangesMethod.finish()));
  }
  var superClass = view.genConfig.genDebugInfo
      ? Identifiers.DebugAppView
      : Identifiers.AppView;
  var viewClass = new o.ClassStmt(
      view.className,
      o.importExpr(superClass, typeParams: [getContextType(view)]),
      view.storage.fields,
      view.getters,
      viewConstructor,
      viewMethods
          .where((method) => method.body != null && method.body.isNotEmpty)
          .toList());
  if (view.viewType != ViewType.host) {
    _addRenderTypeCtorInitialization(view, viewClass);
  }
  return viewClass;
}

o.ClassMethod _createViewClassConstructor(
    CompileView view, o.Expression nodeDebugInfosVar) {
  var emptyTemplateVariableBindings = view.templateVariables
      .map((variable) => [variable.value, o.NULL_EXPR])
      .toList();
  var viewConstructorArgs = [
    new o.FnParam(ViewConstructorVars.parentView.name,
        o.importType(Identifiers.AppView, [o.DYNAMIC_TYPE])),
    new o.FnParam(ViewConstructorVars.parentIndex.name, o.INT_TYPE)
  ];
  var superConstructorArgs = [
    createEnumExpression(Identifiers.ViewType, view.viewType),
    o.literalMap(emptyTemplateVariableBindings),
    ViewConstructorVars.parentView,
    ViewConstructorVars.parentIndex,
    changeDetectionStrategyToConst(getChangeDetectionMode(view))
  ];
  if (view.genConfig.genDebugInfo) {
    superConstructorArgs.add(nodeDebugInfosVar);
  }
  o.ClassMethod ctor = new o.ClassMethod(null, viewConstructorArgs,
      [o.SUPER_EXPR.callFn(superConstructorArgs).toStmt()]);
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

    ctor.body.add(new o.WriteClassMemberExpr(
            appViewRootElementName, createRootElementExpr)
        .toStmt());

    // Write literal attribute values on element.
    CompileDirectiveMetadata componentMeta = view.component;
    componentMeta.hostAttributes.forEach((String name, String value) {
      o.Statement stmt = createSetAttributeStatement(
          tagName, o.variable(appViewRootElementName), name, value);
      ctor.body.add(stmt);
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

void _addRenderTypeCtorInitialization(CompileView view, o.ClassStmt viewClass) {
  var viewConstructor = viewClass.constructorMethod;

  /// Add render type.
  if (view.viewIndex == 0) {
    var renderTypeExpr = _constructRenderType(view, viewClass, viewConstructor);
    viewConstructor.body.add(
        new o.InvokeMemberMethodExpr('setupComponentType', [renderTypeExpr])
            .toStmt());
  } else {
    viewConstructor.body.add(new o.WriteClassMemberExpr(
            'componentType',
            new o.ReadStaticMemberExpr('_renderType',
                sourceClass: view.componentView.classType))
        .toStmt());
  }
}

// Writes code to initial RenderComponentType for component.
o.Expression _constructRenderType(
    CompileView view, o.ClassStmt viewClass, o.ClassMethod viewConstructor) {
  assert(view.viewIndex == 0);
  var templateUrlInfo;
  if (view.component.template.templateUrl == view.component.type.moduleUrl) {
    templateUrlInfo = '${view.component.type.moduleUrl} '
        'class ${view.component.type.name} - inline template';
  } else {
    templateUrlInfo = view.component.template.templateUrl;
  }

  // renderType static to hold RenderComponentType instance.
  String renderTypeVarName = '_renderType';
  o.Expression renderCompTypeVar =
      new o.ReadStaticMemberExpr(renderTypeVarName);

  o.Statement initRenderTypeStatement = new o.WriteStaticMemberExpr(
          renderTypeVarName,
          o
              .importExpr(Identifiers.appViewUtils)
              .callMethod("createRenderType", [
            o.literal(view.genConfig.genDebugInfo ? templateUrlInfo : ''),
            createEnumExpression(Identifiers.ViewEncapsulation,
                view.component.template.encapsulation),
            view.styles
          ]),
          checkIfNull: true)
      .toStmt();

  viewConstructor.body.add(initRenderTypeStatement);

  viewClass.fields.add(new o.ClassField(renderTypeVarName,
      modifiers: [o.StmtModifier.Static],
      outputType: o.importType(Identifiers.RenderComponentType)));

  return renderCompTypeVar;
}

List<o.Statement> generateDestroyMethod(CompileView view) {
  var statements = <o.Statement>[];
  for (o.Expression child in view.viewContainers) {
    statements.add(
        child.callMethod('destroyNestedViews', [], checked: true).toStmt());
  }
  for (o.Expression child in view.viewChildren) {
    statements.add(child.callMethod('destroy', [], checked: true).toStmt());
  }
  statements.addAll(view.destroyMethod.finish());
  return statements;
}

o.Statement createInputUpdateFunction(
    CompileView view, o.ClassStmt viewClass, o.ReadVarExpr renderCompTypeVar) {
  return null;
}

o.Statement createViewFactory(CompileView view, o.ClassStmt viewClass) {
  var viewFactoryArgs = [
    new o.FnParam(ViewConstructorVars.parentView.name,
        o.importType(Identifiers.AppView, [o.DYNAMIC_TYPE])),
    new o.FnParam(ViewConstructorVars.parentIndex.name, o.INT_TYPE),
  ];
  var initRenderCompTypeStmts = [];
  o.OutputType factoryReturnType;
  if (view.viewType == ViewType.host) {
    factoryReturnType = o.importType(Identifiers.AppView);
  } else {
    factoryReturnType =
        o.importType(Identifiers.AppView, [o.importType(view.component.type)]);
  }
  return o
      .fn(
          viewFactoryArgs,
          (new List.from(initRenderCompTypeStmts)
            ..addAll([
              new o.ReturnStatement(o.variable(viewClass.name).instantiate(
                  viewClass.constructorMethod.params
                      .map((o.FnParam param) => o.variable(param.name))
                      .toList()))
            ])),
          factoryReturnType)
      .toDeclStmt(view.viewFactory.name, [o.StmtModifier.Final]);
}

List<o.Statement> generateBuildMethod(CompileView view, Parser parser) {
  // Hoist the `rootEl` class field as `_rootEl` locally for Dart2JS.
  o.ReadVarExpr cachedRootEl;
  final parentRenderNodeStmts = <o.Statement>[];
  final isComponent = view.viewType == ViewType.component;
  if (isComponent) {
    cachedRootEl = o.variable('_rootEl');
    parentRenderNodeStmts.add(cachedRootEl
        .set(new o.ReadClassMemberExpr(appViewRootElementName))
        .toDeclStmt(null, [o.StmtModifier.Final]));
    final nodeType = o.importType(Identifiers.HTML_HTML_ELEMENT);
    final parentRenderNodeExpr = new o.InvokeMemberMethodExpr(
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
        .set(new o.ReadClassMemberExpr('ctx'))
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
    final notNullAssignment = notNull.set(new o.FunctionExpr(
      [new o.FnParam('i')],
      [new o.ReturnStatement(o.variable('i').notEquals(o.NULL_EXPR))],
    ));
    statements.add(notNullAssignment.toDeclStmt(null, [o.StmtModifier.Final]));
    final notNullSubscriptions =
        subscriptions.callMethod('where', [notNull]).callMethod('toList', []);
    initParams.add(notNullSubscriptions);
  } else {
    initParams.add(subscriptions);
  }

  // In DEBUG mode we call:
  //
  // init(rootNodes, subscriptions, renderNodes);
  //
  // In RELEASE mode we call:
  //
  // init(rootNodes, subscriptions);
  // or init0 if we have a single root node with no subscriptions.
  o.Expression renderNodesArrayExpr;
  if (view.genConfig.genDebugInfo) {
    final renderNodes =
        view.nodes.map((node) => node.renderNode.toReadExpr()).toList();
    renderNodesArrayExpr = o.literalArr(renderNodes);
    initParams.add(renderNodesArrayExpr);
  }

  if (rootElements is o.LiteralArrayExpr &&
      rootElements.entries.length == 1 &&
      subscriptions == o.NULL_EXPR) {
    if (view.genConfig.genDebugInfo) {
      statements.add(new o.InvokeMemberMethodExpr(
              'init0Dbg', [rootElements.entries[0], renderNodesArrayExpr])
          .toStmt());
    } else {
      statements.add(
          new o.InvokeMemberMethodExpr('init0', [rootElements.entries[0]])
              .toStmt());
    }
  } else {
    statements.add(new o.InvokeMemberMethodExpr('init', initParams).toStmt());
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
            .set(new o.ReadClassMemberExpr('markStateChanged')))
        .toStmt());
  }

  o.Expression resultExpr;
  if (identical(view.viewType, ViewType.host)) {
    if (view.nodes.isEmpty) {
      throwFailure('Template parser has crashed for ${view.className}');
    }
    var hostElement = view.nodes[0] as CompileElement;
    resultExpr = o.importExpr(Identifiers.ComponentRef).instantiate(
          [
            o.literal(hostElement.nodeIndex),
            o.THIS_EXPR,
            hostElement.renderNode.toReadExpr(),
            hostElement.getComponent()
          ],
          null,
          [o.importType(view.component.originType.type)],
        );
  } else {
    resultExpr = o.NULL_EXPR;
  }
  if (view.genConfig.profileFor == Profile.build) {
    genProfileBuildEnd(view, statements);
  }
  statements.add(new o.ReturnStatement(resultExpr));

  var readVars = o.findReadVarNames(statements);
  if (readVars.contains(cachedParentIndexVarName)) {
    statements.insert(
        0,
        new o.DeclareVarStmt(cachedParentIndexVarName,
            new ReadClassMemberExpr('viewData').prop('parentIndex')));
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
      var context = new o.ReadClassMemberExpr('ctx');
      var actionStmts = convertCdStatementToIr(
          view.nameResolver, context, handlerAst, component);
      var actionExpr = convertStmtIntoExpression(actionStmts.last);
      List<o.Statement> stmts = <o.Statement>[
        new o.ReturnStatement(actionExpr)
      ];
      String methodName = '_handle_${sanitizeEventName(eventName)}__';
      view.eventHandlerMethods.add(new o.ClassMethod(
          methodName,
          [new o.FnParam(EventHandlerVars.event.name, o.importType(null))],
          stmts,
          o.BOOL_TYPE,
          [o.StmtModifier.Private]));
      handlerExpr = new o.ReadClassMemberExpr(methodName);
      numArgs = 1;
    } else {
      var context = DetectChangesVars.cachedCtx;
      var actionStmts = convertCdStatementToIr(
          view.nameResolver, context, handlerAst, component);
      var actionExpr = convertStmtIntoExpression(actionStmts.last);
      assert(actionExpr is o.InvokeMethodExpr);
      var callExpr = actionExpr as o.InvokeMethodExpr;
      handlerExpr = new o.ReadPropExpr(callExpr.receiver, callExpr.name);
      numArgs = handlerType == HandlerType.simpleNoArgs ? 0 : 1;
    }

    final wrappedHandlerExpr = new o.InvokeMemberMethodExpr(
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

o.OutputType getContextType(CompileView view) {
  var typeMeta = view.component.type;
  return typeMeta.isHost ? o.DYNAMIC_TYPE : o.importType(typeMeta);
}

int getChangeDetectionMode(CompileView view) {
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

/// Writes proxy for setting an @Input property.
void writeInputUpdaters(CompileView view, List<o.Statement> targetStatements) {
  var writtenInputs = new Set<String>();
  if (view.component.changeDetection == ChangeDetectionStrategy.Stateful) {
    for (String input in view.component.inputs.keys) {
      if (!writtenInputs.contains(input)) {
        writtenInputs.add(input);
        writeInputUpdater(view, input, targetStatements);
      }
    }
  }
}

void writeInputUpdater(
    CompileView view, String inputName, List<o.Statement> targetStatements) {
  var prevValueVarName = 'prev$inputName';
  CompileTypeMetadata inputTypeMeta = view.component.inputTypes != null
      ? view.component.inputTypes[inputName]
      : null;
  var inputType = inputTypeMeta != null ? o.importType(inputTypeMeta) : null;
  var arguments = [
    new o.FnParam('component', getContextType(view)),
    new o.FnParam(prevValueVarName, inputType),
    new o.FnParam(inputName, inputType)
  ];
  String name = buildUpdaterFunctionName(view.component.type.name, inputName);
  var statements = <o.Statement>[];
  const String changedBoolVarName = 'changed';
  o.Expression conditionExpr;
  var prevValueExpr = new o.ReadVarExpr(prevValueVarName);
  var newValueExpr = new o.ReadVarExpr(inputName);
  if (view.genConfig.genDebugInfo) {
    // In debug mode call checkBinding so throwOnChanges is checked for
    // stabilization.
    conditionExpr = o
        .importExpr(Identifiers.checkBinding)
        .callFn([prevValueExpr, newValueExpr]);
  } else {
    conditionExpr = new o.ReadVarExpr(prevValueVarName)
        .notIdentical(new o.ReadVarExpr(inputName));
  }
  // Generates: bool changed = !identical(prevValue, newValue);
  statements.add(o
      .variable(changedBoolVarName, o.BOOL_TYPE)
      .set(conditionExpr)
      .toDeclStmt(o.BOOL_TYPE));
  // Generates: if (changed) {
  //               component.property = newValue;
  //               setState() //optional
  //            }
  var updateStatements = <o.Statement>[];
  updateStatements.add(new o.ReadVarExpr('component')
      .prop(inputName)
      .set(newValueExpr)
      .toStmt());
  o.Statement conditionalUpdateStatement =
      new o.IfStmt(new o.ReadVarExpr(changedBoolVarName), updateStatements);
  statements.add(conditionalUpdateStatement);
  // Generates: return changed;
  statements.add(new o.ReturnStatement(new o.ReadVarExpr(changedBoolVarName)));
  // Add function decl as top level statement.
  targetStatements
      .add(o.fn(arguments, statements, o.BOOL_TYPE).toDeclStmt(name));
}

final _pureHtmlVisitor = new IsPureHtmlVisitor();

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
