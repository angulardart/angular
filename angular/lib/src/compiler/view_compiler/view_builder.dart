import 'package:source_span/source_span.dart';
import 'package:angular/src/compiler/output/output_ast.dart';
import 'package:angular/src/core/app_view_consts.dart' show namespaceUris;
import 'package:angular/src/core/change_detection/change_detection.dart'
    show
        ChangeDetectorState,
        ChangeDetectionStrategy,
        isDefaultChangeDetectionStrategy;
import 'package:angular/src/core/linker/view_type.dart';
import 'package:angular/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular_compiler/angular_compiler.dart';

import '../compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompileTypeMetadata,
        CompileIdentifierMetadata;
import '../expression_parser/parser.dart' show Parser;
import '../html_events.dart';
import '../identifiers.dart' show Identifiers, identifierToken;
import '../logging.dart';
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
        ReferenceAst,
        TemplateAst,
        TemplateAstVisitor,
        VariableAst,
        TextAst,
        templateVisitAll;
import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_method.dart';
import 'compile_view.dart';
import 'constants.dart'
    show
        appViewRootElementName,
        createEnumExpression,
        changeDetectionStrategyToConst,
        parentRenderNodeVar,
        DetectChangesVars,
        EventHandlerVars,
        InjectMethodVars,
        ViewConstructorVars,
        ViewProperties;
import 'event_binder.dart' show convertStmtIntoExpression;
import 'expression_converter.dart';
import 'parse_utils.dart';
import 'perf_profiler.dart';
import 'view_compiler_utils.dart'
    show
        astAttribListToMap,
        cachedParentIndexVarName,
        createFlatArray,
        createDebugInfoTokenExpression,
        createDbgElementCall,
        createSetAttributeStatement,
        componentFromDirectives,
        getParentRenderNode,
        identifierFromTagName,
        mergeHtmlAndDirectiveAttrs,
        ViewCompileDependency;

var rootSelectorVar = o.variable("rootSelector");
var NOT_THROW_ON_CHANGES = o.not(o.importExpr(Identifiers.throwOnChanges));

class ViewBuilderVisitor implements TemplateAstVisitor {
  final CompileView view;
  final Parser parser;
  final List<ViewCompileDependency> targetDependencies;
  final StylesCompileResult stylesCompileResult;

  int nestedViewCount = 0;

  /// Local variable name used to refer to document. null if not created yet.
  static final defaultDocVarName = 'doc';
  String docVarName;

  ViewBuilderVisitor(this.view, this.parser, this.targetDependencies,
      this.stylesCompileResult);

  bool _isRootNode(CompileElement parent) {
    return !identical(parent.view, this.view);
  }

  void _addRootNodeAndProject(
      CompileNode node, num ngContentIndex, CompileElement parent) {
    var vcAppEl = (node is CompileElement && node.hasViewContainer)
        ? node.appViewContainer
        : null;
    if (_isRootNode(parent)) {
      // store appElement as root node only for ViewContainers
      if (view.viewType != ViewType.COMPONENT) {
        view.rootNodesOrViewContainers
            .add(vcAppEl ?? node.renderNode.toReadExpr());
      }
    } else if (parent.component != null && ngContentIndex != null) {
      parent.addContentNode(
          ngContentIndex, vcAppEl ?? node.renderNode.toReadExpr());
    }
  }

  dynamic visitBoundText(BoundTextAst ast, dynamic context) {
    CompileElement parent = context;
    int nodeIndex = view.nodes.length;
    NodeReference renderNode = view.createBoundTextNode(parent, nodeIndex, ast);
    var compileNode = new CompileNode(parent, view, nodeIndex, renderNode, ast);
    view.nodes.add(compileNode);
    _addRootNodeAndProject(compileNode, ast.ngContentIndex, parent);
    return null;
  }

  dynamic visitText(TextAst ast, dynamic context) {
    CompileElement parent = context;
    int nodeIndex = view.nodes.length;
    NodeReference renderNode =
        view.createTextNode(parent, nodeIndex, ast.value, ast);
    var compileNode = new CompileNode(parent, view, nodeIndex, renderNode, ast);
    view.nodes.add(compileNode);
    _addRootNodeAndProject(compileNode, ast.ngContentIndex, parent);
    return null;
  }

  dynamic visitNgContent(NgContentAst ast, dynamic context) {
    CompileElement parent = context;
    // The projected nodes originate from a different view, so we don't
    // have debug information for them.
    this.view.createMethod.resetDebugInfo(null, ast);
    var parentRenderNode = getParentRenderNode(view, parent);
    // AppView.projectableNodes property contains the list of nodes
    // to project for each NgContent.
    // Creates a call to project(parentNode, nodeIndex).
    var nodesExpression = ViewProperties.projectableNodes.key(
        o.literal(ast.index),
        new o.ArrayType(o.importType(Identifiers.HTML_NODE)));
    if (!identical(parentRenderNode, o.NULL_EXPR)) {
      view.createMethod.addStmt(new o.InvokeMemberMethodExpr(
          'project', [parentRenderNode, o.literal(ast.index)]).toStmt());
    } else if (this._isRootNode(parent)) {
      if (!identical(this.view.viewType, ViewType.COMPONENT)) {
        // store root nodes only for embedded/host views
        this.view.rootNodesOrViewContainers.add(nodesExpression);
      }
    } else {
      if (parent.component != null && ast.ngContentIndex != null) {
        parent.addContentNode(ast.ngContentIndex, nodesExpression);
      }
    }
    return null;
  }

  dynamic visitElement(ElementAst ast, dynamic context) {
    CompileElement parent = context;
    var nodeIndex = view.nodes.length;

    bool isHostRootView = nodeIndex == 0 && view.viewType == ViewType.HOST;
    NodeReference elementRef = isHostRootView
        ? new NodeReference.appViewRoot()
        : new NodeReference(parent, nodeIndex, ast);

    var directives = <CompileDirectiveMetadata>[];
    for (var dir in ast.directives) directives.add(dir.directive);
    CompileDirectiveMetadata component = componentFromDirectives(directives);

    if (component != null) {
      bool isDeferred = false;
      isDeferred = nodeIndex == 0 &&
          (view.declarationElement.sourceAst is EmbeddedTemplateAst) &&
          (view.declarationElement.sourceAst as EmbeddedTemplateAst)
              .hasDeferredComponent;
      _visitComponentElement(
          parent, nodeIndex, component, elementRef, directives, ast,
          isDeferred: isDeferred);
    } else {
      _visitHtmlElement(parent, nodeIndex, elementRef, directives, ast);
    }
    return null;
  }

  void _visitComponentElement(
      CompileElement parent,
      int nodeIndex,
      CompileDirectiveMetadata component,
      NodeReference elementRef,
      List<CompileDirectiveMetadata> directives,
      ElementAst ast,
      {bool isDeferred: false}) {
    AppViewReference compAppViewExpr = view.createAppView(parent, component,
        elementRef, nodeIndex, isDeferred, ast, targetDependencies);

    bool isHtmlElement;
    bool isHostRootView = nodeIndex == 0 && view.viewType == ViewType.HOST;
    if (isHostRootView) {
      // Assign root element created by viewfactory call to our own root.
      view.createMethod.addStmt(elementRef
          .toWriteExpr(
              compAppViewExpr.toReadExpr().prop(appViewRootElementName))
          .toStmt());
      if (view.genConfig.genDebugInfo) {
        view.createMethod.addStmt(createDbgIndexElementCall(
            elementRef.toReadExpr(), view.nodes.length, ast));
      }
      isHtmlElement = false;
    } else {
      isHtmlElement = detectHtmlElementFromTagName(ast.name);
      var parentRenderNodeExpr = getParentRenderNode(view, parent);
      final generateDebugInfo = view.genConfig.genDebugInfo;
      view.createMethod.addStmt(elementRef
          .toWriteExpr(
              compAppViewExpr.toReadExpr().prop(appViewRootElementName))
          .toStmt());
      if (parentRenderNodeExpr != null && parentRenderNodeExpr != o.NULL_EXPR) {
        // Write code to append to parent node.
        view.createMethod.addStmt(parentRenderNodeExpr
            .callMethod('append', [elementRef.toReadExpr()]).toStmt());
      }
      if (generateDebugInfo) {
        view.createMethod.addStmt(createDbgElementCall(
            elementRef.toReadExpr(), view.nodes.length, ast));
      }
    }

    if (view.viewType != ViewType.HOST) {
      _writeLiteralAttributeValues(
          ast, elementRef.toReadExpr(), directives, view.createMethod);
    }

    if (!isHostRootView &&
        view.component.template.encapsulation == ViewEncapsulation.Emulated) {
      // Set ng_content class for CSS shim.
      String shimMethod = 'addShimC';
      o.Expression shimClassExpr =
          new o.InvokeMemberMethodExpr(shimMethod, [elementRef.toReadExpr()]);
      view.createMethod.addStmt(shimClassExpr.toStmt());
    }

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
        logger,
        isHtmlElement: isHtmlElement,
        hasTemplateRefQuery: parent.hasTemplateRefQuery);

    view.nodes.add(compileElement);

    if (component != null) {
      compileElement.componentView = compAppViewExpr.toReadExpr();
      view.addViewChild(compAppViewExpr.toReadExpr());
    }

    // beforeChildren() -> _prepareProviderInstances will create the actual
    // directive and component instances.
    compileElement.beforeChildren(isDeferred);
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    templateVisitAll(this, ast.children, compileElement);
    compileElement.afterChildren(view.nodes.length - nodeIndex - 1);

    if (compAppViewExpr != null) {
      o.Expression codeGenContentNodes;
      if (this.view.component.type.isHost) {
        codeGenContentNodes = ViewProperties.projectableNodes;
      } else {
        codeGenContentNodes = o.literalArr(compileElement
            .contentNodesByNgContentIndex
            .map((nodes) => createFlatArray(nodes))
            .toList());
      }
      view.createMethod.addStmt(compAppViewExpr.toReadExpr().callMethod(
          'create',
          [compileElement.getComponent(), codeGenContentNodes]).toStmt());
    }
  }

  void _visitHtmlElement(
      CompileElement parent,
      int nodeIndex,
      NodeReference elementRef,
      List<CompileDirectiveMetadata> directives,
      ElementAst ast) {
    var createRenderNodeExpr;

    String tagName = ast.name;
    var parentRenderNodeExpr = getParentRenderNode(view, parent);
    final generateDebugInfo = view.genConfig.genDebugInfo;

    bool isHostRoot = nodeIndex == 0 && view.viewType == ViewType.HOST;
    if (!isHostRoot) {
      // TODO: move to compile_view.
      String name = (elementRef.toReadExpr() as o.ReadClassMemberExpr).name;
      view.nameResolver.addField(new o.ClassField(name,
          outputType: o.importType(identifierFromTagName(tagName)),
          modifiers: const [o.StmtModifier.Private]));
    }

    // Create element or elementNS. AST encodes svg path element as
    // @svg:path.
    bool isNamespacedElement = tagName.startsWith('@') && tagName.contains(':');
    if (isNamespacedElement) {
      var nameParts = tagName.substring(1).split(':');
      String ns = namespaceUris[nameParts[0]];
      createRenderNodeExpr = o.importExpr(Identifiers.HTML_DOCUMENT).callMethod(
          'createElementNS', [o.literal(ns), o.literal(nameParts[1])]);
      view.createMethod
          .addStmt(elementRef.toWriteExpr(createRenderNodeExpr).toStmt());
      if (parentRenderNodeExpr != null && parentRenderNodeExpr != o.NULL_EXPR) {
        // Write code to append to parent node.
        view.createMethod.addStmt(parentRenderNodeExpr
            .callMethod('append', [elementRef.toReadExpr()]).toStmt());
      }
      if (generateDebugInfo) {
        view.createMethod.addStmt(createDbgElementCall(
            elementRef.toReadExpr(), view.nodes.length, ast));
      }
    } else {
      // Generate code to create Html element, append to parent and
      // optionally add dbg info in single call.
      _createElementAndAppend(tagName, parentRenderNodeExpr, elementRef,
          generateDebugInfo, ast.sourceSpan, nodeIndex);
    }

    _writeLiteralAttributeValues(
        ast, elementRef.toReadExpr(), directives, view.createMethod);

    bool isHostRootView = nodeIndex == 0 && view.viewType == ViewType.HOST;
    if (!isHostRootView &&
        view.component.template.encapsulation == ViewEncapsulation.Emulated) {
      // Set ng_content class for CSS shim.
      var elementType = isHostRootView
          ? Identifiers.HTML_HTML_ELEMENT
          : identifierFromTagName(ast.name);
      String shimMethod =
          elementType != Identifiers.HTML_ELEMENT ? 'addShimC' : 'addShimE';
      o.Expression shimClassExpr =
          new o.InvokeMemberMethodExpr(shimMethod, [elementRef.toReadExpr()]);
      view.createMethod.addStmt(shimClassExpr.toStmt());
    }

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
        logger,
        isHtmlElement: detectHtmlElementFromTagName(tagName),
        hasTemplateRefQuery: parent.hasTemplateRefQuery);

    view.nodes.add(compileElement);
    // beforeChildren() -> _prepareProviderInstances will create the actual
    // directive and component instances.
    compileElement.beforeChildren(false);
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    templateVisitAll(this, ast.children, compileElement);
    compileElement.afterChildren(view.nodes.length - nodeIndex - 1);
  }

  void _createElementAndAppend(
      String tagName,
      o.Expression parent,
      NodeReference elementRef,
      bool generateDebugInfo,
      SourceSpan debugSpan,
      int debugNodeIndex) {
    // No namespace just call [document.createElement].
    if (docVarName == null) {
      view.createMethod.addStmt(_createLocalDocumentVar());
    }
    if (parent != null && parent != o.NULL_EXPR) {
      o.Expression createExpr;
      List<o.Expression> createParams;
      if (generateDebugInfo) {
        createParams = <o.Expression>[
          o.THIS_EXPR,
          new o.ReadVarExpr(docVarName)
        ];
      } else {
        createParams = <o.Expression>[new ReadVarExpr(docVarName)];
      }

      CompileIdentifierMetadata createAndAppendMethod;
      switch (tagName) {
        case 'div':
          createAndAppendMethod = generateDebugInfo
              ? Identifiers.createDivAndAppendDbg
              : Identifiers.createDivAndAppend;
          break;
        case 'span':
          createAndAppendMethod = generateDebugInfo
              ? Identifiers.createSpanAndAppendDbg
              : Identifiers.createSpanAndAppend;
          break;
        default:
          createAndAppendMethod = generateDebugInfo
              ? Identifiers.createAndAppendDbg
              : Identifiers.createAndAppend;
          createParams.add(o.literal(tagName));
          break;
      }
      createParams.add(parent);
      if (generateDebugInfo) {
        createParams.addAll([
          o.literal(debugNodeIndex),
          debugSpan?.start == null
              ? o.NULL_EXPR
              : o.literal(debugSpan.start.line),
          debugSpan?.start == null
              ? o.NULL_EXPR
              : o.literal(debugSpan.start.column)
        ]);
      }
      createExpr = o.importExpr(createAndAppendMethod).callFn(createParams);
      view.createMethod.addStmt(elementRef.toWriteExpr(createExpr).toStmt());
    } else {
      // No parent node, just create element and assign.
      var createRenderNodeExpr = new o.ReadVarExpr(docVarName)
          .callMethod('createElement', [o.literal(tagName)]);
      view.createMethod
          .addStmt(elementRef.toWriteExpr(createRenderNodeExpr).toStmt());
      if (generateDebugInfo) {
        view.createMethod.addStmt(o.importExpr(Identifiers.dbgElm).callFn([
          o.THIS_EXPR,
          elementRef.toReadExpr(),
          o.literal(debugNodeIndex),
          debugSpan?.start == null
              ? o.NULL_EXPR
              : o.literal(debugSpan.start.line),
          debugSpan?.start == null
              ? o.NULL_EXPR
              : o.literal(debugSpan.start.column)
        ]).toStmt());
      }
    }
  }

  o.Statement _createLocalDocumentVar() {
    docVarName = defaultDocVarName;
    return new o.DeclareVarStmt(
        docVarName, o.importExpr(Identifiers.HTML_DOCUMENT));
  }

  o.Statement createDbgIndexElementCall(
      o.Expression nodeExpr, int nodeIndex, TemplateAst ast) {
    return new o.InvokeMemberMethodExpr(
        'dbgIdx', [nodeExpr, o.literal(nodeIndex)]).toStmt();
  }

  dynamic visitEmbeddedTemplate(EmbeddedTemplateAst ast, dynamic context) {
    CompileElement parent = context;
    // When logging updates, we need to create anchor as a field to be able
    // to update the comment, otherwise we can create simple local field.
    var nodeIndex = this.view.nodes.length;
    NodeReference nodeReference =
        view.createViewContainerAnchor(parent, nodeIndex, ast);
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
        logger,
        hasTemplateRefQuery: parent.hasTemplateRefQuery);
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
        view.deferredModules);

    // Create a visitor for embedded view and visit all nodes.
    var embeddedViewVisitor = new ViewBuilderVisitor(
        embeddedView, parser, targetDependencies, stylesCompileResult);
    templateVisitAll(
        embeddedViewVisitor,
        ast.children,
        embeddedView.declarationElement.parent ??
            embeddedView.declarationElement);
    nestedViewCount += embeddedViewVisitor.nestedViewCount;

    compileElement.beforeChildren(false);
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    compileElement.afterChildren(0);
    if (ast.hasDeferredComponent) {
      var statements = <o.Statement>[];
      compileElement.writeDeferredLoader(
          embeddedView, compileElement.appViewContainer, statements);
      view.createMethod.addStmts(statements);
      view.detectChangesRenderPropertiesMethod.addStmt(compileElement
          .appViewContainer
          .callMethod('detectChangesInNestedViews', const []).toStmt());
    }
    return null;
  }

  dynamic visitAttr(AttrAst ast, dynamic ctx) {
    return null;
  }

  dynamic visitDirective(DirectiveAst ast, dynamic ctx) {
    return null;
  }

  dynamic visitEvent(BoundEventAst ast, dynamic context) {
    return null;
  }

  dynamic visitReference(ReferenceAst ast, dynamic ctx) {
    return null;
  }

  dynamic visitVariable(VariableAst ast, dynamic ctx) {
    return null;
  }

  dynamic visitDirectiveProperty(
      BoundDirectivePropertyAst ast, dynamic context) {
    return null;
  }

  dynamic visitElementProperty(BoundElementPropertyAst ast, dynamic context) {
    return null;
  }
}

/// Writes literal attribute values on the element itself and those
/// contributed from directives on the ast node.
///
/// !Component level attributes are excluded since we want to avoid per
//  call site duplication.
void _writeLiteralAttributeValues(ElementAst ast, o.Expression renderNode,
    List<CompileDirectiveMetadata> directives, CompileMethod method) {
  var htmlAttrs = astAttribListToMap(ast.attrs);
  // Create statements to initialize literal attribute values.
  // For example, a directive may have hostAttributes setting class name.
  var attrNameAndValues =
      mergeHtmlAndDirectiveAttrs(htmlAttrs, directives, excludeComponent: true);
  for (int i = 0, len = attrNameAndValues.length; i < len; i++) {
    o.Statement stmt = createSetAttributeStatement(
        ast.name, renderNode, attrNameAndValues[i][0], attrNameAndValues[i][1]);
    method.addStmt(stmt);
  }
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
          view.viewType != ViewType.HOST
              ? [o.importType(view.component.type)]
              : const [],
        ),
        null,
        ['override']),
    new o.ClassMethod(
        "injectorGetInternal",
        [
          new o.FnParam(InjectMethodVars.token.name, o.DYNAMIC_TYPE),
          new o.FnParam(InjectMethodVars.nodeIndex.name, o.INT_TYPE),
          new o.FnParam(InjectMethodVars.notFoundResult.name, o.DYNAMIC_TYPE)
        ],
        addReturnValueIfNotEmpty(
            view.injectorGetMethod.finish(), InjectMethodVars.notFoundResult),
        o.DYNAMIC_TYPE,
        null,
        ['override']),
    new o.ClassMethod("detectChangesInternal", [],
        generateDetectChangesMethod(view), null, null, ['override']),
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
      view.nameResolver.fields,
      view.getters,
      viewConstructor,
      viewMethods
          .where((method) => method.body != null && method.body.isNotEmpty)
          .toList());
  _addRenderTypeCtorInitialization(view, viewClass);
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
    new o.FnParam(ViewConstructorVars.parentIndex.name, o.NUMBER_TYPE)
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
  if (view.viewType == ViewType.COMPONENT && view.viewIndex == 0) {
    // No namespace just call [document.createElement].
    String tagName = _tagNameFromComponentSelector(view.component.selector);
    if (tagName.isEmpty) {
      logger.severe('Component selector is missing tag name in '
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
    new o.FnParam(ViewConstructorVars.parentIndex.name, o.NUMBER_TYPE),
  ];
  var initRenderCompTypeStmts = [];
  var factoryReturnType;
  if (view.viewType == ViewType.HOST) {
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
  o.Expression parentRenderNodeExpr = o.NULL_EXPR;
  var parentRenderNodeStmts = <o.Statement>[];
  bool isComponent = view.viewType == ViewType.COMPONENT;
  if (isComponent) {
    final nodeType = o.importType(Identifiers.HTML_HTML_ELEMENT);
    parentRenderNodeExpr = new o.InvokeMemberMethodExpr(
        "initViewRoot", [new o.ReadClassMemberExpr(appViewRootElementName)]);
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
    var contextType = view.viewType != ViewType.HOST
        ? o.importType(view.component.type)
        : null;
    statements.add(DetectChangesVars.cachedCtx
        .set(new o.ReadClassMemberExpr('ctx'))
        .toDeclStmt(contextType, [o.StmtModifier.Final]));
  }

  statements.addAll(parentRenderNodeStmts);
  statements.addAll(view.createMethod.finish());

  final rootElements = createFlatArray(view.rootNodesOrViewContainers);
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
  var renderNodesArrayExpr;
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
    _writeComponentHostEventListeners(view, parser, statements);
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
  if (identical(view.viewType, ViewType.HOST)) {
    if (view.nodes.isEmpty) {
      logger.severe('Template parser has crashed for ${view.className}');
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
    CompileView view, Parser parser, List<o.Statement> statements) {
  CompileDirectiveMetadata component = view.component;
  for (String eventName in component.hostListeners.keys) {
    String handlerSource = component.hostListeners[eventName];
    var handlerAst = parser.parseAction(handlerSource, '', component.exports);
    HandlerType handlerType = handlerTypeFromExpression(handlerAst);
    var handlerExpr;
    var numArgs;
    if (handlerType == HandlerType.notSimple) {
      var context = new o.ReadClassMemberExpr('ctx');
      var actionExpr = convertStmtIntoExpression(
          convertCdStatementToIr(view.nameResolver, context, handlerAst, false)
              .last);
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
      var actionExpr = convertStmtIntoExpression(
          convertCdStatementToIr(view.nameResolver, context, handlerAst, false)
              .last);
      assert(actionExpr is o.InvokeMethodExpr);
      var callExpr = actionExpr as o.InvokeMethodExpr;
      handlerExpr = new o.ReadPropExpr(callExpr.receiver, callExpr.name);
      numArgs = handlerType == HandlerType.simpleNoArgs ? 0 : 1;
    }

    final wrappedHandlerExpr =
        new o.InvokeMemberMethodExpr('eventHandler$numArgs', [handlerExpr]);
    final rootElExpr = new o.ReadClassMemberExpr(appViewRootElementName);

    var listenExpr;
    if (isNativeHtmlEvent(eventName)) {
      listenExpr = rootElExpr.callMethod(
          'addEventListener', [o.literal(eventName), wrappedHandlerExpr]);
    } else {
      final appViewUtilsExpr = o.importExpr(Identifiers.appViewUtils);
      final eventManagerExpr = appViewUtilsExpr.prop('eventManager');
      listenExpr = eventManagerExpr.callMethod('addEventListener',
          [rootElExpr, o.literal(eventName), wrappedHandlerExpr]);
    }
    statements.add(listenExpr.toStmt());
  }
}

List<o.Statement> generateDetectChangesMethod(CompileView view) {
  var stmts = <o.Statement>[];
  if (view.detectChangesInInputsMethod.isEmpty &&
      view.updateContentQueriesMethod.isEmpty &&
      view.afterContentLifecycleCallbacksMethod.isEmpty &&
      view.detectChangesRenderPropertiesMethod.isEmpty &&
      view.updateViewQueriesMethod.isEmpty &&
      view.afterViewLifecycleCallbacksMethod.isEmpty &&
      view.viewChildren.isEmpty &&
      view.viewContainers.isEmpty) {
    return stmts;
  }

  if (view.genConfig.profileFor == Profile.build) {
    genProfileCdStart(view, stmts);
  }

  // Add @Input change detectors.
  stmts.addAll(view.detectChangesInInputsMethod.finish());

  // Add content child change detection calls.
  for (o.Expression contentChild in view.viewContainers) {
    stmts.add(
        contentChild.callMethod('detectChangesInNestedViews', []).toStmt());
  }

  // Add Content query updates.
  List<o.Statement> afterContentStmts =
      (new List.from(view.updateContentQueriesMethod.finish())
        ..addAll(view.afterContentLifecycleCallbacksMethod.finish()));
  if (afterContentStmts.isNotEmpty) {
    if (view.genConfig.genDebugInfo) {
      stmts.add(new o.IfStmt(NOT_THROW_ON_CHANGES, afterContentStmts));
    } else {
      stmts.addAll(afterContentStmts);
    }
  }

  // Add render properties change detectors.
  stmts.addAll(view.detectChangesRenderPropertiesMethod.finish());

  // Add view child change detection calls.
  for (o.Expression viewChild in view.viewChildren) {
    stmts.add(viewChild.callMethod('detectChanges', []).toStmt());
  }

  List<o.Statement> afterViewStmts =
      (new List.from(view.updateViewQueriesMethod.finish())
        ..addAll(view.afterViewLifecycleCallbacksMethod.finish()));
  if (afterViewStmts.length > 0) {
    if (view.genConfig.genDebugInfo) {
      stmts.add(new o.IfStmt(NOT_THROW_ON_CHANGES, afterViewStmts));
    } else {
      stmts.addAll(afterViewStmts);
    }
  }
  var varStmts = [];
  var readVars = o.findReadVarNames(stmts);
  if (readVars.contains(cachedParentIndexVarName)) {
    varStmts.add(new o.DeclareVarStmt(cachedParentIndexVarName,
        new ReadClassMemberExpr('viewData').prop('parentIndex')));
  }
  if (readVars.contains(DetectChangesVars.cachedCtx.name)) {
    // Cache [ctx] class field member as typed [_ctx] local for change detection
    // code to consume.
    var contextType = view.viewType != ViewType.HOST
        ? o.importType(view.component.type)
        : null;
    varStmts.add(o
        .variable(DetectChangesVars.cachedCtx.name)
        .set(new o.ReadClassMemberExpr('ctx'))
        .toDeclStmt(contextType, [o.StmtModifier.Final]));
  }
  if (readVars.contains(DetectChangesVars.changed.name)) {
    varStmts.add(
        DetectChangesVars.changed.set(o.literal(true)).toDeclStmt(o.BOOL_TYPE));
  }
  if (readVars.contains(DetectChangesVars.changes.name) ||
      view.requiresOnChangesCall) {
    varStmts.add(new o.DeclareVarStmt(DetectChangesVars.changes.name, null,
        new o.MapType(o.importType(Identifiers.SimpleChange))));
  }
  if (readVars.contains(DetectChangesVars.firstCheck.name)) {
    varStmts.add(new o.DeclareVarStmt(
        DetectChangesVars.firstCheck.name,
        o.THIS_EXPR
            .prop('cdState')
            .equals(o.literal(ChangeDetectorState.NeverChecked)),
        o.BOOL_TYPE));
  }
  if (view.genConfig.profileFor == Profile.build) {
    genProfileCdEnd(view, stmts);
  }
  return (new List.from(varStmts)..addAll(stmts));
}

List<o.Statement> addReturnValueIfNotEmpty(
    List<o.Statement> statements, o.Expression value) {
  if (statements.length > 0) {
    return (new List.from(statements)..addAll([new o.ReturnStatement(value)]));
  } else {
    return statements;
  }
}

o.OutputType getContextType(CompileView view) {
  var typeMeta = view.component.type;
  return typeMeta.isHost ? o.DYNAMIC_TYPE : o.importType(typeMeta);
}

int getChangeDetectionMode(CompileView view) {
  int mode;
  if (identical(view.viewType, ViewType.COMPONENT)) {
    mode = isDefaultChangeDetectionStrategy(view.component.changeDetection)
        ? ChangeDetectionStrategy.CheckAlways
        : ChangeDetectionStrategy.CheckOnce;
  } else {
    mode = ChangeDetectionStrategy.CheckAlways;
  }
  return mode;
}

Set<String> _tagNameSet;

/// Returns true if tag name is HtmlElement.
///
/// Returns false if tag name is svg element or other. Used for optimizations.
/// Should not generate false positives but returning false when unknown is
/// fine since code will fallback to general Element case.
bool detectHtmlElementFromTagName(String tagName) {
  const htmlTagNames = const <String>[
    'a',
    'abbr',
    'acronym',
    'address',
    'applet',
    'area',
    'article',
    'aside',
    'audio',
    'b',
    'base',
    'basefont',
    'bdi',
    'bdo',
    'bgsound',
    'big',
    'blockquote',
    'body',
    'br',
    'button',
    'canvas',
    'caption',
    'center',
    'cite',
    'code',
    'col',
    'colgroup',
    'command',
    'data',
    'datalist',
    'dd',
    'del',
    'details',
    'dfn',
    'dialog',
    'dir',
    'div',
    'dl',
    'dt',
    'element',
    'em',
    'embed',
    'fieldset',
    'figcaption',
    'figure',
    'font',
    'footer',
    'form',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'head',
    'header',
    'hr',
    'i',
    'iframe',
    'img',
    'input',
    'ins',
    'kbd',
    'keygen',
    'label',
    'legend',
    'li',
    'link',
    'listing',
    'main',
    'map',
    'mark',
    'menu',
    'menuitem',
    'meta',
    'meter',
    'nav',
    'object',
    'ol',
    'optgroup',
    'option',
    'output',
    'p',
    'param',
    'picture',
    'pre',
    'progress',
    'q',
    'rp',
    'rt',
    'rtc',
    'ruby',
    's',
    'samp',
    'script',
    'section',
    'select',
    'shadow',
    'small',
    'source',
    'span',
    'strong',
    'style',
    'sub',
    'summary',
    'sup',
    'table',
    'tbody',
    'td',
    'template',
    'textarea',
    'tfoot',
    'th',
    'thead',
    'time',
    'title',
    'tr',
    'track',
    'tt',
    'u',
    'ul',
    'var',
    'video',
    'wbr'
  ];
  if (_tagNameSet == null) {
    _tagNameSet = new Set<String>();
    for (String name in htmlTagNames) {
      _tagNameSet.add(name);
    }
  }
  return _tagNameSet.contains(tagName);
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

/// Constructs name of global function that can be used to update an input
/// on a component with change detection.
String buildUpdaterFunctionName(String typeName, String inputName) =>
    'set' + typeName + r'$' + inputName;
