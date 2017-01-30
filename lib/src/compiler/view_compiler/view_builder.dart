import "package:angular2/src/core/change_detection/change_detection.dart"
    show ChangeDetectionStrategy, isDefaultChangeDetectionStrategy;
import "package:angular2/src/core/linker/view_type.dart";
import 'package:angular2/src/core/linker/app_view_utils.dart'
    show NAMESPACE_URIS;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;
import "../compile_metadata.dart"
    show CompileIdentifierMetadata, CompileDirectiveMetadata;
import "../identifiers.dart" show Identifiers, identifierToken;
import "../output/output_ast.dart" as o;
import "../style_compiler.dart" show StylesCompileResult;
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
import 'property_binder.dart';
import "view_compiler_utils.dart"
    show
        getViewFactoryName,
        createFlatArray,
        createDiTokenExpression,
        createSetAttributeParams,
        TEMPLATE_COMMENT_TEXT;

const IMPLICIT_TEMPLATE_VAR = "\$implicit";
const CLASS_ATTR = "class";
const STYLE_ATTR = "style";
var parentRenderNodeVar = o.variable("parentRenderNode");
var rootSelectorVar = o.variable("rootSelector");
var NOT_THROW_ON_CHANGES = o.not(o.importExpr(Identifiers.throwOnChanges));

/// Component dependency and associated identifier.
class ViewCompileDependency {
  CompileDirectiveMetadata comp;
  CompileIdentifierMetadata factoryPlaceholder;
  ViewCompileDependency(this.comp, this.factoryPlaceholder);
}

class ViewBuilderVisitor implements TemplateAstVisitor {
  final CompileView view;
  final List<ViewCompileDependency> targetDependencies;
  final StylesCompileResult stylesCompileResult;
  static Map<String, CompileIdentifierMetadata> tagNameToIdentifier;

  int nestedViewCount = 0;

  /// Local variable name used to refer to document. null if not created yet.
  static final defaultDocVarName = 'doc';
  String docVarName;

  ViewBuilderVisitor(
      this.view, this.targetDependencies, this.stylesCompileResult) {
    tagNameToIdentifier ??= {
      'a': Identifiers.HTML_ANCHOR_ELEMENT,
      'area': Identifiers.HTML_AREA_ELEMENT,
      'audio': Identifiers.HTML_AUDIO_ELEMENT,
      'button': Identifiers.HTML_BUTTON_ELEMENT,
      'canvas': Identifiers.HTML_CANVAS_ELEMENT,
      'form': Identifiers.HTML_FORM_ELEMENT,
      'iframe': Identifiers.HTML_IFRAME_ELEMENT,
      'input': Identifiers.HTML_INPUT_ELEMENT,
      'image': Identifiers.HTML_IMAGE_ELEMENT,
      'media': Identifiers.HTML_MEDIA_ELEMENT,
      'menu': Identifiers.HTML_MENU_ELEMENT,
      'ol': Identifiers.HTML_OLIST_ELEMENT,
      'option': Identifiers.HTML_OPTION_ELEMENT,
      'col': Identifiers.HTML_TABLE_COL_ELEMENT,
      'row': Identifiers.HTML_TABLE_ROW_ELEMENT,
      'select': Identifiers.HTML_SELECT_ELEMENT,
      'table': Identifiers.HTML_TABLE_ELEMENT,
      'text': Identifiers.HTML_TEXT_NODE,
      'textarea': Identifiers.HTML_TEXTAREA_ELEMENT,
      'ul': Identifiers.HTML_ULIST_ELEMENT,
    };
  }

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
        view.rootNodesOrViewContainers.add(vcAppEl ?? node.renderNode);
      }
    } else if (parent.component != null && ngContentIndex != null) {
      parent.addContentNode(ngContentIndex, vcAppEl ?? node.renderNode);
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
      return parent.component != null &&
              !identical(parent.component.template.encapsulation,
                  ViewEncapsulation.Native)
          ? o.NULL_EXPR
          : parent.renderNode;
    }
  }

  dynamic visitBoundText(BoundTextAst ast, dynamic context) {
    CompileElement parent = context;
    return this._visitText(ast, "", ast.ngContentIndex, parent, isBound: true);
  }

  dynamic visitText(TextAst ast, dynamic context) {
    CompileElement parent = context;
    return this
        ._visitText(ast, ast.value, ast.ngContentIndex, parent, isBound: false);
  }

  o.Expression _visitText(
      TemplateAst ast, String value, num ngContentIndex, CompileElement parent,
      {bool isBound}) {
    var fieldName = '_text_${this.view.nodes.length}';
    o.Expression renderNode;
    // If Text field is bound, we need access to the renderNode beyond
    // createInternal method and write reference to class member.
    // Otherwise we can create a local variable and not balloon class prototype.
    if (isBound) {
      view.fields.add(new o.ClassField(fieldName,
          outputType: o.importType(Identifiers.HTML_TEXT_NODE),
          modifiers: const [o.StmtModifier.Private]));
      renderNode = new o.ReadClassMemberExpr(fieldName);
    } else {
      view.createMethod.addStmt(new o.DeclareVarStmt(
          fieldName,
          o
              .importExpr(Identifiers.HTML_TEXT_NODE)
              .instantiate([o.literal(value)]),
          o.importType(Identifiers.HTML_TEXT_NODE)));
      renderNode = new o.ReadVarExpr(fieldName);
    }
    var compileNode =
        new CompileNode(parent, view, this.view.nodes.length, renderNode, ast);
    var parentRenderNodeExpr = _getParentRenderNode(parent);
    if (isBound) {
      var createRenderNodeExpr = new o.ReadClassMemberExpr(fieldName).set(o
          .importExpr(Identifiers.HTML_TEXT_NODE)
          .instantiate([o.literal(value)]));
      view.nodes.add(compileNode);
      view.createMethod.addStmt(createRenderNodeExpr.toStmt());
    } else {
      view.nodes.add(compileNode);
    }
    if (parentRenderNodeExpr != null && parentRenderNodeExpr != o.NULL_EXPR) {
      // Write append code.
      view.createMethod.addStmt(
          parentRenderNodeExpr.callMethod('append', [renderNode]).toStmt());
    }
    if (view.genConfig.genDebugInfo) {
      view.createMethod.addStmt(
          createDbgElementCall(renderNode, view.nodes.length - 1, ast));
    }
    _addRootNodeAndProject(compileNode, ngContentIndex, parent);
    return renderNode;
  }

  dynamic visitNgContent(NgContentAst ast, dynamic context) {
    CompileElement parent = context;
    // The projected nodes originate from a different view, so we don't
    // have debug information for them.
    this.view.createMethod.resetDebugInfo(null, ast);
    var parentRenderNode = this._getParentRenderNode(parent);
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

  /// Returns strongly typed html elements to improve code generation.
  CompileIdentifierMetadata identifierFromTagName(String name) {
    var elementType = tagNameToIdentifier[name.toLowerCase()];
    elementType ??= Identifiers.HTML_ELEMENT;
    // TODO: classify as HtmlElement or SvgElement to improve further.
    return elementType;
  }

  dynamic visitElement(ElementAst ast, dynamic context) {
    CompileElement parent = context;
    var nodeIndex = view.nodes.length;
    var fieldName = '_el_${nodeIndex}';
    bool isHostRootView = nodeIndex == 0 && view.viewType == ViewType.HOST;
    var elementType = isHostRootView
        ? Identifiers.HTML_ELEMENT
        : identifierFromTagName(ast.name);
    view.fields.add(new o.ClassField(fieldName,
        outputType: o.importType(elementType),
        modifiers: const [o.StmtModifier.Private]));

    var debugContextExpr = view.createMethod.resetDebugInfoExpr(nodeIndex, ast);

    var createRenderNodeExpr;
    o.Expression tagNameExpr = o.literal(ast.name);
    bool isHtmlElement;
    if (isHostRootView) {
      createRenderNodeExpr = new o.InvokeMemberMethodExpr(
          'selectOrCreateHostElement',
          [tagNameExpr, rootSelectorVar, debugContextExpr]);
      view.createMethod.addStmt(
          new o.WriteClassMemberExpr(fieldName, createRenderNodeExpr).toStmt());
      isHtmlElement = false;
    } else {
      isHtmlElement = detectHtmlElementFromTagName(ast.name);
      var parentRenderNodeExpr = _getParentRenderNode(parent);
      // Create element or elementNS. AST encodes svg path element as @svg:path.
      if (ast.name.startsWith('@') && ast.name.contains(':')) {
        var nameParts = ast.name.substring(1).split(':');
        String ns = NAMESPACE_URIS[nameParts[0]];
        createRenderNodeExpr = o
            .importExpr(Identifiers.HTML_DOCUMENT)
            .callMethod(
                'createElementNS', [o.literal(ns), o.literal(nameParts[1])]);
      } else {
        // No namespace just call [document.createElement].
        if (docVarName == null) {
          view.createMethod.addStmt(_createLocalDocumentVar());
        }
        createRenderNodeExpr = new o.ReadVarExpr(docVarName)
            .callMethod('createElement', [tagNameExpr]);
      }
      view.createMethod.addStmt(
          new o.WriteClassMemberExpr(fieldName, createRenderNodeExpr).toStmt());

      if (parentRenderNodeExpr != null && parentRenderNodeExpr != o.NULL_EXPR) {
        // Write append code.
        view.createMethod.addStmt(parentRenderNodeExpr.callMethod(
            'append', [new o.ReadClassMemberExpr(fieldName)]).toStmt());
      }
      if (view.genConfig.genDebugInfo) {
        view.createMethod.addStmt(createDbgElementCall(
            new o.ReadClassMemberExpr(fieldName), view.nodes.length, ast));
      }
    }

    var renderNode = new o.ReadClassMemberExpr(fieldName);

    List<CompileDirectiveMetadata> directives = _directivesFromElementAst(ast);
    CompileDirectiveMetadata component = _componentFromDirectives(directives);
    var htmlAttrs = _readHtmlAttrs(ast.attrs);

    // Create statements to initialize literal attribute values.
    var attrNameAndValues = _mergeHtmlAndDirectiveAttrs(htmlAttrs, directives);
    for (var i = 0; i < attrNameAndValues.length; i++) {
      o.Statement stmt = _createSetAttributeStatement(ast.name, fieldName,
          attrNameAndValues[i][0], attrNameAndValues[i][1]);
      view.createMethod.addStmt(stmt);
    }

    if (!isHostRootView &&
        view.component.template.encapsulation == ViewEncapsulation.Emulated) {
      // Set ng_content class for CSS shim.
      o.Expression shimClassExpr = new o.InvokeMemberMethodExpr(
          'addShimC', [new o.ReadClassMemberExpr(fieldName)]);
      view.createMethod.addStmt(shimClassExpr.toStmt());
    }

    var compileElement = new CompileElement(
        parent,
        this.view,
        nodeIndex,
        renderNode,
        fieldName,
        ast,
        component,
        directives,
        ast.providers,
        ast.hasViewContainer,
        false,
        ast.references,
        isHtmlElement: isHtmlElement);
    view.nodes.add(compileElement);
    o.Expression compViewExpr;
    if (component != null) {
      var nestedComponentIdentifier =
          new CompileIdentifierMetadata(name: getViewFactoryName(component, 0));
      this
          .targetDependencies
          .add(new ViewCompileDependency(component, nestedComponentIdentifier));
      String compViewName = '_compView_${nodeIndex}';
      compViewExpr = new o.ReadClassMemberExpr(compViewName);
      view.fields.add(new o.ClassField(compViewName,
          outputType: o.importType(
              Identifiers.AppView, [o.importType(component.type)])));
      compileElement.componentView = compViewExpr;
      view.viewChildren.add(compViewExpr);
      view.createMethod.addStmt(new o.WriteClassMemberExpr(
              compViewName,
              o
                  .importExpr(nestedComponentIdentifier)
                  .callFn([o.THIS_EXPR, o.literal(nodeIndex), renderNode]))
          .toStmt());
    }
    compileElement.beforeChildren();
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    templateVisitAll(this, ast.children, compileElement);
    compileElement.afterChildren(this.view.nodes.length - nodeIndex - 1);
    if (compViewExpr != null) {
      o.Expression codeGenContentNodes;
      if (this.view.component.type.isHost) {
        codeGenContentNodes = ViewProperties.projectableNodes;
      } else {
        codeGenContentNodes = o.literalArr(compileElement
            .contentNodesByNgContentIndex
            .map((nodes) => createFlatArray(nodes))
            .toList());
      }

      view.createMethod.addStmt(compViewExpr.callMethod('create', [
        compileElement.getComponent(),
        codeGenContentNodes,
        o.NULL_EXPR
      ]).toStmt());
    }
    return null;
  }

  List<CompileDirectiveMetadata> _directivesFromElementAst(ElementAst ast) {
    var directives = <CompileDirectiveMetadata>[];
    for (DirectiveAst directiveAst in ast.directives) {
      directives.add(directiveAst.directive);
    }
    return directives;
  }

  CompileDirectiveMetadata _componentFromDirectives(
      List<CompileDirectiveMetadata> directives) {
    for (CompileDirectiveMetadata directive in directives) {
      if (directive.isComponent) return directive;
    }
    return null;
  }

  o.Statement _createLocalDocumentVar() {
    docVarName = defaultDocVarName;
    return new o.DeclareVarStmt(
        docVarName, o.importExpr(Identifiers.HTML_DOCUMENT));
  }

  o.Statement _createSetAttributeStatement(String astNodeName,
      String elementFieldName, String attrName, String attrValue) {
    var attrNs;
    if (attrName.startsWith('@') && attrName.contains(':')) {
      var nameParts = attrName.substring(1).split(':');
      attrNs = NAMESPACE_URIS[nameParts[0]];
      attrName = nameParts[1];
    }

    /// Optimization for common attributes. Call dart:html directly without
    /// going through setAttr wrapper.
    if (attrNs == null) {
      switch (attrName) {
        case 'class':
          // Remove check below after SVGSVGElement DDC bug is fixed b2/32931607
          bool hasNamespace =
              astNodeName.startsWith('@') || astNodeName.contains(':');
          if (!hasNamespace) {
            return new o.ReadClassMemberExpr(elementFieldName)
                .prop('className')
                .set(o.literal(attrValue))
                .toStmt();
          }
          break;
        case 'tabindex':
          try {
            int tabValue = int.parse(attrValue);
            return new o.ReadClassMemberExpr(elementFieldName)
                .prop('tabIndex')
                .set(o.literal(tabValue))
                .toStmt();
          } catch (_) {
            // fallthrough to default handler since index is not int.
          }
          break;
        default:
          break;
      }
    }
    var params = createSetAttributeParams(
        elementFieldName, attrNs, attrName, o.literal(attrValue));
    return new o.InvokeMemberMethodExpr(
            attrNs == null ? "createAttr" : "setAttrNS", params)
        .toStmt();
  }

  String attributeNameToDartHtmlMember(String attrName) {
    switch (attrName) {
      case 'class':
        return 'className';
      case 'tabindex':
        return 'tabIndex';
      default:
        return null;
    }
  }

  o.Statement createDbgElementCall(
      o.Expression nodeExpr, int nodeIndex, TemplateAst ast) {
    var sourceLocation = ast?.sourceSpan?.start;
    return new o.InvokeMemberMethodExpr('dbgElm', [
      nodeExpr,
      o.literal(nodeIndex),
      sourceLocation == null ? o.NULL_EXPR : o.literal(sourceLocation.line),
      sourceLocation == null ? o.NULL_EXPR : o.literal(sourceLocation.column)
    ]).toStmt();
  }

  dynamic visitEmbeddedTemplate(EmbeddedTemplateAst ast, dynamic context) {
    CompileElement parent = context;
    // When logging updates, we need to create anchor as a field to be able
    // to update the comment, otherwise we can create simple local field.
    bool createFieldForAnchor = view.genConfig.logBindingUpdate;
    var nodeIndex = this.view.nodes.length;
    var fieldName = '_anchor_${nodeIndex}';
    o.Expression anchorVarExpr;
    // Create a comment to serve as anchor for template.
    if (createFieldForAnchor) {
      view.fields.add(new o.ClassField(fieldName,
          outputType: o.importType(Identifiers.HTML_COMMENT_NODE),
          modifiers: const [o.StmtModifier.Private]));
      anchorVarExpr = new o.ReadClassMemberExpr(fieldName);
      var createAnchorNodeExpr = new o.WriteClassMemberExpr(
          fieldName,
          o
              .importExpr(Identifiers.HTML_COMMENT_NODE)
              .instantiate([o.literal(TEMPLATE_COMMENT_TEXT)]));
      view.createMethod.addStmt(createAnchorNodeExpr.toStmt());
    } else {
      var readVarExp = o.variable(fieldName);
      anchorVarExpr = readVarExp;
      var createAnchorNodeExpr = readVarExp.set(o
          .importExpr(Identifiers.HTML_COMMENT_NODE)
          .instantiate([o.literal(TEMPLATE_COMMENT_TEXT)]));
      view.createMethod.addStmt(createAnchorNodeExpr.toDeclStmt());
    }
    var addCommentStmt = _getParentRenderNode(parent)
        .callMethod('append', [anchorVarExpr], checked: true)
        .toStmt();

    view.createMethod.addStmt(addCommentStmt);

    if (view.genConfig.genDebugInfo) {
      view.createMethod
          .addStmt(createDbgElementCall(anchorVarExpr, nodeIndex, ast));
    }

    var renderNode = anchorVarExpr;
    var templateVariableBindings = ast.variables
        .map((VariableAst varAst) => [
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
        fieldName,
        ast,
        null,
        directives,
        ast.providers,
        ast.hasViewContainer,
        true,
        ast.references);
    view.nodes.add(compileElement);
    nestedViewCount++;
    var embeddedView = new CompileView(
        view.component,
        view.genConfig,
        view.pipeMetas,
        o.NULL_EXPR,
        view.viewIndex + nestedViewCount,
        compileElement,
        templateVariableBindings);

    // Create a visitor for embedded view and visit all nodes.
    var embeddedViewVisitor = new ViewBuilderVisitor(
        embeddedView, targetDependencies, stylesCompileResult);
    templateVisitAll(
        embeddedViewVisitor,
        ast.children,
        embeddedView.declarationElement.hasRenderNode
            ? embeddedView.declarationElement.parent
            : embeddedView.declarationElement);
    nestedViewCount += embeddedViewVisitor.nestedViewCount;

    compileElement.beforeChildren();
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
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
  declaredHtmlAttrs.forEach((key, value) => result[key] = value);
  directives.forEach((directiveMeta) {
    directiveMeta.hostAttributes.forEach((name, value) {
      var prevValue = result[name];
      result[name] = prevValue != null
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
  var entryArray = <List<String>>[];
  data.forEach((String name, String value) {
    entryArray.add([name, value]);
  });
  // We need to sort to get a defined output order
  // for tests and for caching generated artifacts...
  entryArray.sort((entry1, entry2) => entry1[0].compareTo(entry2[0]));
  var keyValueArray = <List<String>>[];
  entryArray.forEach((entry) {
    keyValueArray.add([entry[0], entry[1]]);
  });
  return keyValueArray;
}

o.Expression createStaticNodeDebugInfo(CompileNode node) {
  var compileElement = node is CompileElement ? node : null;
  List<o.Expression> providerTokens = [];
  o.Expression componentToken = o.NULL_EXPR;
  var varTokenEntries = <List>[];
  if (compileElement != null) {
    providerTokens = compileElement.getProviderTokens();
    if (compileElement.component != null) {
      componentToken = createDiTokenExpression(
          identifierToken(compileElement.component.type));
    }

    compileElement.referenceTokens?.forEach((String varName, token) {
      varTokenEntries.add([
        varName,
        token != null ? createDiTokenExpression(token) : o.NULL_EXPR
      ]);
    });
  }
  // Optimize StaticNodeDebugInfo(const [],null,const <String, dynamic>{}), case
  // by writing out null.
  if (providerTokens.isEmpty &&
      componentToken == o.NULL_EXPR &&
      varTokenEntries.isEmpty) {
    return o.NULL_EXPR;
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

o.ClassStmt createViewClass(CompileView view, o.Expression nodeDebugInfosVar) {
  var emptyTemplateVariableBindings = view.templateVariableBindings
      .map((List entry) => [entry[0], o.NULL_EXPR])
      .toList();
  var viewConstructorArgs = [
    new o.FnParam(ViewConstructorVars.parentView.name,
        o.importType(Identifiers.AppView, [o.DYNAMIC_TYPE])),
    new o.FnParam(ViewConstructorVars.parentIndex.name, o.NUMBER_TYPE),
    new o.FnParam(ViewConstructorVars.parentElement.name, o.DYNAMIC_TYPE)
  ];
  var superConstructorArgs = [
    o.variable(view.className),
    ViewTypeEnum.fromValue(view.viewType),
    o.literalMap(emptyTemplateVariableBindings),
    ViewConstructorVars.parentView,
    ViewConstructorVars.parentIndex,
    ViewConstructorVars.parentElement,
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
        o.importType(Identifiers.ComponentRef, null)),
    new o.ClassMethod(
        "injectorGetInternal",
        [
          new o.FnParam(InjectMethodVars.token.name, o.DYNAMIC_TYPE),
          new o.FnParam(InjectMethodVars.requestNodeIndex.name, o.INT_TYPE),
          new o.FnParam(InjectMethodVars.notFoundResult.name, o.DYNAMIC_TYPE)
        ],
        addReturnValuefNotEmpty(
            view.injectorGetMethod.finish(), InjectMethodVars.notFoundResult),
        o.DYNAMIC_TYPE),
    new o.ClassMethod(
        "detectChangesInternal", [], generateDetectChangesMethod(view)),
    new o.ClassMethod("dirtyParentQueriesInternal", [],
        view.dirtyParentQueriesMethod.finish()),
    new o.ClassMethod("destroyInternal", [], generateDestroyMethod(view))
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
          .where((o.ClassMethod method) =>
              method.body != null && method.body.length > 0)
          .toList() as List<o.ClassMethod>);

  if (view.viewIndex == 0) {
    var renderTypeExpr = _constructRenderType(view, viewClass, viewConstructor);
    viewConstructor.body.add(
        new o.InvokeMemberMethodExpr('setupComponentType', [renderTypeExpr])
            .toStmt());
  } else {
    viewConstructor.body.add(new o.WriteClassMemberExpr(
            'componentType',
            new o.ReadStaticMemberExpr('renderType',
                sourceClass: view.componentView.classType))
        .toStmt());
  }
  return viewClass;
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
  String renderTypeVarName = 'renderType';
  o.Expression renderCompTypeVar =
      new o.ReadStaticMemberExpr(renderTypeVarName);

  o.Statement initRenderTypeStatement = new o.WriteStaticMemberExpr(
          renderTypeVarName,
          o
              .importExpr(Identifiers.appViewUtils)
              .callMethod("createRenderType", [
            o.literal(view.genConfig.genDebugInfo ? templateUrlInfo : ''),
            o.literal(view.component.template.ngContentSelectors.length),
            ViewEncapsulationEnum
                .fromValue(view.component.template.encapsulation),
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
    statements.add(child.callMethod('destroyNestedViews', []).toStmt());
  }
  for (o.Expression child in view.viewChildren) {
    statements.add(child.callMethod('destroy', []).toStmt());
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
    new o.FnParam(ViewConstructorVars.parentElement.name, o.DYNAMIC_TYPE)
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

List<o.Statement> generateCreateMethod(CompileView view) {
  o.Expression parentRenderNodeExpr = o.NULL_EXPR;
  var parentRenderNodeStmts = <o.Statement>[];
  bool isComponent = view.viewType == ViewType.COMPONENT;
  if (isComponent) {
    if (view.component.template.encapsulation == ViewEncapsulation.Native) {
      parentRenderNodeExpr = new o.InvokeMemberMethodExpr(
          "createViewShadowRoot", [new o.ReadClassMemberExpr('parentElement')]);
    } else {
      parentRenderNodeExpr = new o.InvokeMemberMethodExpr(
          "initViewRoot", [new o.ReadClassMemberExpr('parentElement')]);
    }
    parentRenderNodeStmts = [
      parentRenderNodeVar.set(parentRenderNodeExpr).toDeclStmt(
          o.importType(Identifiers.HTML_NODE), [o.StmtModifier.Final])
    ];
  }

  var statements = <o.Statement>[];
  statements.addAll(parentRenderNodeStmts);
  statements.addAll(view.createMethod.finish());
  var renderNodes = view.nodes.map((node) {
    return node.renderNode;
  }).toList();

  statements.add(new o.InvokeMemberMethodExpr('init', [
    createFlatArray(view.rootNodesOrViewContainers),
    o.literalArr(renderNodes),
    o.literalArr(view.subscriptions)
  ]).toStmt());

  if (isComponent &&
      view.viewIndex == 0 &&
      view.component.changeDetection == ChangeDetectionStrategy.Stateful) {
    // Connect ComponentState callback to view.
    statements.add((new o.ReadClassMemberExpr('ctx')
            .prop('stateChangeCallback')
            .set(new o.ReadClassMemberExpr('markStateChanged')))
        .toStmt());
  }

  o.Expression resultExpr;
  if (identical(view.viewType, ViewType.HOST)) {
    var hostElement = view.nodes[0] as CompileElement;
    resultExpr = o.importExpr(Identifiers.ComponentRef).instantiate([
      o.literal(hostElement.nodeIndex),
      o.THIS_EXPR,
      hostElement.renderNode,
      hostElement.getComponent()
    ]);
  } else {
    resultExpr = o.NULL_EXPR;
  }
  statements.add(new o.ReturnStatement(resultExpr));
  return statements;
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
  if (afterContentStmts.length > 0) {
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
  if (readVars.contains(DetectChangesVars.changed.name)) {
    varStmts.add(
        DetectChangesVars.changed.set(o.literal(true)).toDeclStmt(o.BOOL_TYPE));
  }
  if (readVars.contains(DetectChangesVars.changes.name)) {
    varStmts.add(new o.DeclareVarStmt(DetectChangesVars.changes.name, null,
        new o.MapType(o.importType(Identifiers.SimpleChange))));
  }
  if (readVars.contains(DetectChangesVars.valUnwrapper.name)) {
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

Set<String> tagNameSet;

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
  if (tagNameSet == null) {
    tagNameSet = new Set<String>();
    for (String name in htmlTagNames) tagNameSet.add(name);
  }
  return tagNameSet.contains(tagName);
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
  String inputTypeName = view.component.inputTypes != null
      ? view.component.inputTypes[inputName]
      : null;
  var inputType = inputTypeName != null
      ? o.importType(new CompileIdentifierMetadata(name: inputTypeName))
      : null;
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
    if (inputTypeName != null && isPrimitiveTypeName(inputTypeName.trim())) {
      conditionExpr = new o.ReadVarExpr(prevValueVarName)
          .notIdentical(new o.ReadVarExpr(inputName));
    } else {
      conditionExpr = new o.ReadVarExpr(prevValueVarName)
          .notEquals(new o.ReadVarExpr(inputName));
    }
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
