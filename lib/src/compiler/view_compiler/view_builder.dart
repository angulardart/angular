import "package:angular2/src/core/change_detection/change_detection.dart"
    show ChangeDetectionStrategy, isDefaultChangeDetectionStrategy;
import "package:angular2/src/core/linker/view_type.dart" show ViewType;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, StringMapWrapper, SetWrapper;
import "package:angular2/src/facade/lang.dart" show isPresent, StringWrapper;

import "../compile_metadata.dart"
    show CompileIdentifierMetadata, CompileDirectiveMetadata;
import "../identifiers.dart" show Identifiers, identifierToken;
import "../output/output_ast.dart" as o;
import "../template_ast.dart"
    show
        TemplateAst,
        TemplateAstVisitor,
        NgContentAst,
        EmbeddedTemplateAst,
        ElementAst,
        ReferenceAst,
        VariableAst,
        BoundEventAst,
        BoundElementPropertyAst,
        AttrAst,
        BoundTextAst,
        TextAst,
        DirectiveAst,
        BoundDirectivePropertyAst,
        templateVisitAll;
import "compile_element.dart" show CompileElement, CompileNode;
import "compile_view.dart" show CompileView;
import "constants.dart"
    show
        ViewConstructorVars,
        InjectMethodVars,
        DetectChangesVars,
        ViewTypeEnum,
        ViewEncapsulationEnum,
        ChangeDetectionStrategyEnum,
        ViewProperties;
import "util.dart"
    show getViewFactoryName, createFlatArray, createDiTokenExpression;

const IMPLICIT_TEMPLATE_VAR = "\$implicit";
const CLASS_ATTR = "class";
const STYLE_ATTR = "style";
var parentRenderNodeVar = o.variable("parentRenderNode");
var rootSelectorVar = o.variable("rootSelector");
var NOT_THROW_ON_CHANGES = o.not(o.importExpr(Identifiers.throwOnChanges));

class ViewCompileDependency {
  CompileDirectiveMetadata comp;
  CompileIdentifierMetadata factoryPlaceholder;
  ViewCompileDependency(this.comp, this.factoryPlaceholder) {}
}

num buildView(CompileView view, List<TemplateAst> template,
    List<ViewCompileDependency> targetDependencies) {
  var builderVisitor = new ViewBuilderVisitor(view, targetDependencies);
  templateVisitAll(
      builderVisitor,
      template,
      view.declarationElement.isNull()
          ? view.declarationElement
          : view.declarationElement.parent);
  return builderVisitor.nestedViewCount;
}

finishView(CompileView view, List<o.Statement> targetStatements) {
  view.afterNodes();
  createViewTopLevelStmts(view, targetStatements);
  view.nodes.forEach((node) {
    if (node is CompileElement && isPresent(node.embeddedView)) {
      finishView(node.embeddedView, targetStatements);
    }
  });
}

class ViewBuilderVisitor implements TemplateAstVisitor {
  CompileView view;
  List<ViewCompileDependency> targetDependencies;
  num nestedViewCount = 0;
  ViewBuilderVisitor(this.view, this.targetDependencies);

  bool _isRootNode(CompileElement parent) {
    return !identical(parent.view, this.view);
  }

  _addRootNodeAndProject(
      CompileNode node, num ngContentIndex, CompileElement parent) {
    var vcAppEl = (node is CompileElement && node.hasViewContainer)
        ? node.appElement
        : null;
    if (this._isRootNode(parent)) {
      // store appElement as root node only for ViewContainers
      if (!identical(this.view.viewType, ViewType.COMPONENT)) {
        this
            .view
            .rootNodesOrAppElements
            .add(isPresent(vcAppEl) ? vcAppEl : node.renderNode);
      }
    } else if (isPresent(parent.component) && isPresent(ngContentIndex)) {
      parent.addContentNode(
          ngContentIndex, isPresent(vcAppEl) ? vcAppEl : node.renderNode);
    }
  }

  o.Expression _getParentRenderNode(CompileElement parent) {
    if (this._isRootNode(parent)) {
      if (identical(this.view.viewType, ViewType.COMPONENT)) {
        return parentRenderNodeVar;
      } else {
        // root node of an embedded/host view
        return o.NULL_EXPR;
      }
    } else {
      return isPresent(parent.component) &&
          !identical(parent.component.template.encapsulation,
              ViewEncapsulation.Native) ? o.NULL_EXPR : parent.renderNode;
    }
  }

  dynamic visitBoundText(BoundTextAst ast, dynamic context) {
    CompileElement parent = context;
    return this._visitText(ast, "", ast.ngContentIndex, parent);
  }

  dynamic visitText(TextAst ast, dynamic context) {
    CompileElement parent = context;
    return this._visitText(ast, ast.value, ast.ngContentIndex, parent);
  }

  o.Expression _visitText(TemplateAst ast, String value, num ngContentIndex,
      CompileElement parent) {
    var fieldName = '''_text_${ this . view . nodes . length}''';
    this.view.fields.add(new o.ClassField(
        fieldName,
        o.importType(this.view.genConfig.renderTypes.renderText),
        [o.StmtModifier.Private]));
    var renderNode = o.THIS_EXPR.prop(fieldName);
    var compileNode = new CompileNode(
        parent, this.view, this.view.nodes.length, renderNode, ast);
    var createRenderNode = o.THIS_EXPR
        .prop(fieldName)
        .set(ViewProperties.renderer.callMethod("createText", [
          this._getParentRenderNode(parent),
          o.literal(value),
          this.view.createMethod.resetDebugInfoExpr(this.view.nodes.length, ast)
        ]))
        .toStmt();
    this.view.nodes.add(compileNode);
    this.view.createMethod.addStmt(createRenderNode);
    this._addRootNodeAndProject(compileNode, ngContentIndex, parent);
    return renderNode;
  }

  dynamic visitNgContent(NgContentAst ast, dynamic context) {
    CompileElement parent = context;
    // the projected nodes originate from a different view, so we don't

    // have debug information for them...
    this.view.createMethod.resetDebugInfo(null, ast);
    var parentRenderNode = this._getParentRenderNode(parent);
    var nodesExpression = ViewProperties.projectableNodes.key(
        o.literal(ast.index),
        new o.ArrayType(
            o.importType(this.view.genConfig.renderTypes.renderNode)));
    if (!identical(parentRenderNode, o.NULL_EXPR)) {
      this
          .view
          .createMethod
          .addStmt(ViewProperties.renderer.callMethod("projectNodes", [
            parentRenderNode,
            o
                .importExpr(Identifiers.flattenNestedViewRenderNodes)
                .callFn([nodesExpression])
          ]).toStmt());
    } else if (this._isRootNode(parent)) {
      if (!identical(this.view.viewType, ViewType.COMPONENT)) {
        // store root nodes only for embedded/host views
        this.view.rootNodesOrAppElements.add(nodesExpression);
      }
    } else {
      if (isPresent(parent.component) && isPresent(ast.ngContentIndex)) {
        parent.addContentNode(ast.ngContentIndex, nodesExpression);
      }
    }
    return null;
  }

  dynamic visitElement(ElementAst ast, dynamic context) {
    CompileElement parent = context;
    var nodeIndex = this.view.nodes.length;
    var createRenderNodeExpr;
    var debugContextExpr =
        this.view.createMethod.resetDebugInfoExpr(nodeIndex, ast);
    if (identical(nodeIndex, 0) &&
        identical(this.view.viewType, ViewType.HOST)) {
      createRenderNodeExpr = o.THIS_EXPR.callMethod("selectOrCreateHostElement",
          [o.literal(ast.name), rootSelectorVar, debugContextExpr]);
    } else {
      createRenderNodeExpr = ViewProperties.renderer.callMethod(
          "createElement", [
        this._getParentRenderNode(parent),
        o.literal(ast.name),
        debugContextExpr
      ]);
    }
    var fieldName = '''_el_${ nodeIndex}''';
    this.view.fields.add(new o.ClassField(
        fieldName,
        o.importType(this.view.genConfig.renderTypes.renderElement),
        [o.StmtModifier.Private]));
    this.view.createMethod.addStmt(
        o.THIS_EXPR.prop(fieldName).set(createRenderNodeExpr).toStmt());
    var renderNode = o.THIS_EXPR.prop(fieldName);
    var directives =
        ast.directives.map((directiveAst) => directiveAst.directive).toList();
    var component = directives.firstWhere((directive) => directive.isComponent,
        orElse: () => null);
    var htmlAttrs = _readHtmlAttrs(ast.attrs);
    var attrNameAndValues = _mergeHtmlAndDirectiveAttrs(htmlAttrs, directives);
    for (var i = 0; i < attrNameAndValues.length; i++) {
      var attrName = attrNameAndValues[i][0];
      var attrValue = attrNameAndValues[i][1];
      this.view.createMethod.addStmt(ViewProperties.renderer.callMethod(
          "setElementAttribute",
          [renderNode, o.literal(attrName), o.literal(attrValue)]).toStmt());
    }
    var compileElement = new CompileElement(
        parent,
        this.view,
        nodeIndex,
        renderNode,
        ast,
        component,
        directives,
        ast.providers,
        ast.hasViewContainer,
        false,
        ast.references);
    this.view.nodes.add(compileElement);
    o.ReadVarExpr compViewExpr = null;
    if (isPresent(component)) {
      var nestedComponentIdentifier =
          new CompileIdentifierMetadata(name: getViewFactoryName(component, 0));
      this
          .targetDependencies
          .add(new ViewCompileDependency(component, nestedComponentIdentifier));
      compViewExpr = o.variable('''compView_${ nodeIndex}''');
      compileElement.setComponentView(compViewExpr);
      this.view.createMethod.addStmt(compViewExpr
          .set(o.importExpr(nestedComponentIdentifier).callFn([
            ViewProperties.viewUtils,
            compileElement.injector,
            compileElement.appElement
          ]))
          .toDeclStmt());
    }
    compileElement.beforeChildren();
    this._addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    templateVisitAll(this, ast.children, compileElement);
    compileElement.afterChildren(this.view.nodes.length - nodeIndex - 1);
    if (isPresent(compViewExpr)) {
      var codeGenContentNodes;
      if (this.view.component.type.isHost) {
        codeGenContentNodes = ViewProperties.projectableNodes;
      } else {
        codeGenContentNodes = o.literalArr(compileElement
            .contentNodesByNgContentIndex
            .map((nodes) => createFlatArray(nodes))
            .toList());
      }
      this.view.createMethod.addStmt(compViewExpr
          .callMethod("create", [codeGenContentNodes, o.NULL_EXPR]).toStmt());
    }
    return null;
  }

  dynamic visitEmbeddedTemplate(EmbeddedTemplateAst ast, dynamic context) {
    CompileElement parent = context;
    var nodeIndex = this.view.nodes.length;
    var fieldName = '''_anchor_${ nodeIndex}''';
    this.view.fields.add(new o.ClassField(
        fieldName,
        o.importType(this.view.genConfig.renderTypes.renderComment),
        [o.StmtModifier.Private]));
    this.view.createMethod.addStmt(o.THIS_EXPR
        .prop(fieldName)
        .set(ViewProperties.renderer.callMethod("createTemplateAnchor", [
          this._getParentRenderNode(parent),
          this.view.createMethod.resetDebugInfoExpr(nodeIndex, ast)
        ]))
        .toStmt());
    var renderNode = o.THIS_EXPR.prop(fieldName);
    var templateVariableBindings = ast.variables
        .map((varAst) => [
              varAst.value.length > 0 ? varAst.value : IMPLICIT_TEMPLATE_VAR,
              varAst.name
            ])
        .toList();
    var directives =
        ast.directives.map((directiveAst) => directiveAst.directive).toList();
    var compileElement = new CompileElement(
        parent,
        this.view,
        nodeIndex,
        renderNode,
        ast,
        null,
        directives,
        ast.providers,
        ast.hasViewContainer,
        true,
        ast.references);
    this.view.nodes.add(compileElement);
    this.nestedViewCount++;
    var embeddedView = new CompileView(
        this.view.component,
        this.view.genConfig,
        this.view.pipeMetas,
        o.NULL_EXPR,
        this.view.viewIndex + this.nestedViewCount,
        compileElement,
        templateVariableBindings);
    this.nestedViewCount +=
        buildView(embeddedView, ast.children, this.targetDependencies);
    compileElement.beforeChildren();
    this._addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    compileElement.afterChildren(0);
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

List<List<String>> _mergeHtmlAndDirectiveAttrs(
    Map<String, String> declaredHtmlAttrs,
    List<CompileDirectiveMetadata> directives) {
  Map<String, String> result = {};
  StringMapWrapper.forEach(declaredHtmlAttrs, (value, key) {
    result[key] = value;
  });
  directives.forEach((directiveMeta) {
    StringMapWrapper.forEach(directiveMeta.hostAttributes, (value, name) {
      var prevValue = result[name];
      result[name] = isPresent(prevValue)
          ? mergeAttributeValue(name, prevValue, value)
          : value;
    });
  });
  return mapToKeyValueArray(result);
}

Map<String, String> _readHtmlAttrs(List<AttrAst> attrs) {
  Map<String, String> htmlAttrs = {};
  attrs.forEach((ast) {
    htmlAttrs[ast.name] = ast.value;
  });
  return htmlAttrs;
}

String mergeAttributeValue(
    String attrName, String attrValue1, String attrValue2) {
  if (attrName == CLASS_ATTR || attrName == STYLE_ATTR) {
    return '''${ attrValue1} ${ attrValue2}''';
  } else {
    return attrValue2;
  }
}

List<List<String>> mapToKeyValueArray(Map<String, String> data) {
  var entryArray = [];
  StringMapWrapper.forEach(data, (value, name) {
    entryArray.add([name, value]);
  });
  // We need to sort to get a defined output order

  // for tests and for caching generated artifacts...
  ListWrapper.sort(entryArray,
      (entry1, entry2) => StringWrapper.compare(entry1[0], entry2[0]));
  var keyValueArray = <List<String>>[];
  entryArray.forEach((entry) {
    keyValueArray.add([entry[0], entry[1]]);
  });
  return keyValueArray;
}

createViewTopLevelStmts(CompileView view, List<o.Statement> targetStatements) {
  o.Expression nodeDebugInfosVar = o.NULL_EXPR;
  if (view.genConfig.genDebugInfo) {
    // Create top level node debug info.
    // Example:
    // const List<StaticNodeDebugInfo> nodeDebugInfos_MyAppComponent0 = const [
    //     const StaticNodeDebugInfo(const [],null,const <String, dynamic>{}),
    //     const StaticNodeDebugInfo(const [],null,const <String, dynamic>{}),
    //     const StaticNodeDebugInfo(const [
    //       import1.AcxDarkTheme,
    //       import2.MaterialButtonComponent,
    //       import3.ButtonDirective
    //     ]
    //     ,import2.MaterialButtonComponent,const <String, dynamic>{}),
    // const StaticNodeDebugInfo(const [],null,const <String, dynamic>{}),
    // ...
    nodeDebugInfosVar = o.variable(
        'nodeDebugInfos_${view.component.type.name}${view.viewIndex}');
    targetStatements.add(((nodeDebugInfosVar as o.ReadVarExpr))
        .set(o.literalArr(
            view.nodes.map(createStaticNodeDebugInfo).toList(),
            new o.ArrayType(new o.ExternalType(Identifiers.StaticNodeDebugInfo),
                [o.TypeModifier.Const])))
        .toDeclStmt(null, [o.StmtModifier.Final]));
  }
  o.ReadVarExpr renderCompTypeVar =
      o.variable('''renderType_${ view . component . type . name}''');
  if (identical(view.viewIndex, 0)) {
    targetStatements.add(renderCompTypeVar
        .set(o.NULL_EXPR)
        .toDeclStmt(o.importType(Identifiers.RenderComponentType)));
  }
  var viewClass = createViewClass(view, renderCompTypeVar, nodeDebugInfosVar);
  targetStatements.add(viewClass);
  targetStatements.add(createViewFactory(view, viewClass, renderCompTypeVar));
}

o.Expression createStaticNodeDebugInfo(CompileNode node) {
  var compileElement = node is CompileElement ? node : null;
  List<o.Expression> providerTokens = [];
  o.Expression componentToken = o.NULL_EXPR;
  var varTokenEntries = <List<dynamic>>[];
  if (isPresent(compileElement)) {
    providerTokens = compileElement.getProviderTokens();
    if (isPresent(compileElement.component)) {
      componentToken = createDiTokenExpression(
          identifierToken(compileElement.component.type));
    }
    StringMapWrapper.forEach(compileElement.referenceTokens, (token, varName) {
      varTokenEntries.add([
        varName,
        token != null ? createDiTokenExpression(token) : o.NULL_EXPR
      ]);
    });
  }
  return o.importExpr(Identifiers.StaticNodeDebugInfo).instantiate(
      [
        o.literalArr(providerTokens,
            new o.ArrayType(o.DYNAMIC_TYPE, [o.TypeModifier.Const])),
        componentToken,
        o.literalMap(varTokenEntries,
            new o.MapType(o.DYNAMIC_TYPE, [o.TypeModifier.Const]))
      ],
      o.importType(
          Identifiers.StaticNodeDebugInfo, null, [o.TypeModifier.Const]));
}

o.ClassStmt createViewClass(CompileView view, o.ReadVarExpr renderCompTypeVar,
    o.Expression nodeDebugInfosVar) {
  var emptyTemplateVariableBindings = view.templateVariableBindings
      .map((entry) => [entry[0], o.NULL_EXPR])
      .toList();
  var viewConstructorArgs = [
    new o.FnParam(ViewConstructorVars.viewUtils.name,
        o.importType(Identifiers.ViewUtils)),
    new o.FnParam(ViewConstructorVars.parentInjector.name,
        o.importType(Identifiers.Injector)),
    new o.FnParam(ViewConstructorVars.declarationEl.name,
        o.importType(Identifiers.AppElement))
  ];
  var superConstructorArgs = [
    o.variable(view.className),
    renderCompTypeVar,
    ViewTypeEnum.fromValue(view.viewType),
    o.literalMap(emptyTemplateVariableBindings),
    ViewConstructorVars.viewUtils,
    ViewConstructorVars.parentInjector,
    ViewConstructorVars.declarationEl,
    ChangeDetectionStrategyEnum.fromValue(getChangeDetectionMode(view))
  ];
  if (view.genConfig.genDebugInfo) {
    superConstructorArgs.add(nodeDebugInfosVar);
  }
  var viewConstructor = new o.ClassMethod(null, viewConstructorArgs,
      [o.SUPER_EXPR.callFn(superConstructorArgs).toStmt()]);
  var viewMethods = (new List.from([
    new o.ClassMethod(
        "createInternal",
        [new o.FnParam(rootSelectorVar.name, o.DYNAMIC_TYPE)],
        generateCreateMethod(view),
        o.importType(Identifiers.AppElement)),
    new o.ClassMethod(
        "injectorGetInternal",
        [
          new o.FnParam(InjectMethodVars.token.name, o.DYNAMIC_TYPE),
          // Note: Can't use o.INT_TYPE here as the method in AppView uses number
          new o.FnParam(InjectMethodVars.requestNodeIndex.name, o.NUMBER_TYPE),
          new o.FnParam(InjectMethodVars.notFoundResult.name, o.DYNAMIC_TYPE)
        ],
        addReturnValuefNotEmpty(
            view.injectorGetMethod.finish(), InjectMethodVars.notFoundResult),
        o.DYNAMIC_TYPE),
    new o.ClassMethod(
        "detectChangesInternal", [], generateDetectChangesMethod(view)),
    new o.ClassMethod("dirtyParentQueriesInternal", [],
        view.dirtyParentQueriesMethod.finish()),
    new o.ClassMethod("destroyInternal", [], view.destroyMethod.finish())
  ])..addAll(view.eventHandlerMethods));
  var superClass = view.genConfig.genDebugInfo
      ? Identifiers.DebugAppView
      : Identifiers.AppView;
  var viewClass = new o.ClassStmt(
      view.className,
      o.importExpr(superClass, [getContextType(view)]),
      view.fields,
      view.getters,
      viewConstructor,
      viewMethods
          .where((o.ClassMethod method) => method.body.length > 0)
          .toList() as List<o.ClassMethod>);
  return viewClass;
}

o.Statement createViewFactory(
    CompileView view, o.ClassStmt viewClass, o.ReadVarExpr renderCompTypeVar) {
  var viewFactoryArgs = [
    new o.FnParam(ViewConstructorVars.viewUtils.name,
        o.importType(Identifiers.ViewUtils)),
    new o.FnParam(ViewConstructorVars.parentInjector.name,
        o.importType(Identifiers.Injector)),
    new o.FnParam(ViewConstructorVars.declarationEl.name,
        o.importType(Identifiers.AppElement))
  ];
  var initRenderCompTypeStmts = [];
  var templateUrlInfo;
  if (view.component.template.templateUrl == view.component.type.moduleUrl) {
    templateUrlInfo =
        '''${ view . component . type . moduleUrl} class ${ view . component . type . name} - inline template''';
  } else {
    templateUrlInfo = view.component.template.templateUrl;
  }
  if (identical(view.viewIndex, 0)) {
    initRenderCompTypeStmts = [
      new o.IfStmt(renderCompTypeVar.identical(o.NULL_EXPR), [
        renderCompTypeVar
            .set(ViewConstructorVars.viewUtils
                .callMethod("createRenderComponentType", [
              o.literal(templateUrlInfo),
              o.literal(view.component.template.ngContentSelectors.length),
              ViewEncapsulationEnum
                  .fromValue(view.component.template.encapsulation),
              view.styles
            ]))
            .toStmt()
      ])
    ];
  }
  return o
      .fn(
          viewFactoryArgs,
          (new List.from(initRenderCompTypeStmts)
            ..addAll([
              new o.ReturnStatement(o.variable(viewClass.name).instantiate(
                  viewClass.constructorMethod.params
                      .map((param) => o.variable(param.name))
                      .toList()))
            ])),
          o.importType(Identifiers.AppView, [getContextType(view)]))
      .toDeclStmt(view.viewFactory.name, [o.StmtModifier.Final]);
}

List<o.Statement> generateCreateMethod(CompileView view) {
  o.Expression parentRenderNodeExpr = o.NULL_EXPR;
  var parentRenderNodeStmts = [];
  if (identical(view.viewType, ViewType.COMPONENT)) {
    parentRenderNodeExpr = ViewProperties.renderer.callMethod("createViewRoot",
        [o.THIS_EXPR.prop("declarationAppElement").prop("nativeElement")]);
    parentRenderNodeStmts = [
      parentRenderNodeVar.set(parentRenderNodeExpr).toDeclStmt(
          o.importType(view.genConfig.renderTypes.renderNode),
          [o.StmtModifier.Final])
    ];
  }
  o.Expression resultExpr;
  if (identical(view.viewType, ViewType.HOST)) {
    resultExpr = ((view.nodes[0] as CompileElement)).appElement;
  } else {
    resultExpr = o.NULL_EXPR;
  }
  return (new List.from(
      (new List.from(parentRenderNodeStmts)
        ..addAll(view.createMethod.finish())))
    ..addAll([
      o.THIS_EXPR.callMethod("init", [
        createFlatArray(view.rootNodesOrAppElements),
        o.literalArr(view.nodes.map((node) => node.renderNode).toList()),
        o.literalArr(view.disposables),
        o.literalArr(view.subscriptions)
      ]).toStmt(),
      new o.ReturnStatement(resultExpr)
    ]));
}

List<o.Statement> generateDetectChangesMethod(CompileView view) {
  var stmts = <o.Statement>[];
  if (view.detectChangesInInputsMethod.isEmpty() &&
      view.updateContentQueriesMethod.isEmpty() &&
      view.afterContentLifecycleCallbacksMethod.isEmpty() &&
      view.detectChangesRenderPropertiesMethod.isEmpty() &&
      view.updateViewQueriesMethod.isEmpty() &&
      view.afterViewLifecycleCallbacksMethod.isEmpty()) {
    return stmts;
  }
  ListWrapper.addAll(stmts, view.detectChangesInInputsMethod.finish());
  stmts
      .add(o.THIS_EXPR.callMethod("detectContentChildrenChanges", []).toStmt());
  List<o.Statement> afterContentStmts =
      (new List.from(view.updateContentQueriesMethod.finish())
        ..addAll(view.afterContentLifecycleCallbacksMethod.finish()));
  if (afterContentStmts.length > 0) {
    stmts.add(new o.IfStmt(NOT_THROW_ON_CHANGES, afterContentStmts));
  }
  ListWrapper.addAll(stmts, view.detectChangesRenderPropertiesMethod.finish());
  stmts.add(o.THIS_EXPR.callMethod("detectViewChildrenChanges", []).toStmt());
  List<o.Statement> afterViewStmts =
      (new List.from(view.updateViewQueriesMethod.finish())
        ..addAll(view.afterViewLifecycleCallbacksMethod.finish()));
  if (afterViewStmts.length > 0) {
    stmts.add(new o.IfStmt(NOT_THROW_ON_CHANGES, afterViewStmts));
  }
  var varStmts = [];
  var readVars = o.findReadVarNames(stmts);
  if (SetWrapper.has(readVars, DetectChangesVars.changed.name)) {
    varStmts.add(
        DetectChangesVars.changed.set(o.literal(true)).toDeclStmt(o.BOOL_TYPE));
  }
  if (SetWrapper.has(readVars, DetectChangesVars.changes.name)) {
    varStmts.add(DetectChangesVars.changes
        .set(o.NULL_EXPR)
        .toDeclStmt(new o.MapType(o.importType(Identifiers.SimpleChange))));
  }
  if (SetWrapper.has(readVars, DetectChangesVars.valUnwrapper.name)) {
    varStmts.add(DetectChangesVars.valUnwrapper
        .set(o.importExpr(Identifiers.ValueUnwrapper).instantiate([]))
        .toDeclStmt(null, [o.StmtModifier.Final]));
  }
  return (new List.from(varStmts)..addAll(stmts));
}

List<o.Statement> addReturnValuefNotEmpty(
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

ChangeDetectionStrategy getChangeDetectionMode(CompileView view) {
  ChangeDetectionStrategy mode;
  if (identical(view.viewType, ViewType.COMPONENT)) {
    mode = isDefaultChangeDetectionStrategy(view.component.changeDetection)
        ? ChangeDetectionStrategy.CheckAlways
        : ChangeDetectionStrategy.CheckOnce;
  } else {
    mode = ChangeDetectionStrategy.CheckAlways;
  }
  return mode;
}
