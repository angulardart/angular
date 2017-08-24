import 'package:source_span/source_span.dart';
import 'package:angular/src/compiler/output/output_ast.dart';
import 'package:angular/src/core/change_detection/change_detection.dart'
    show
        ChangeDetectorState,
        ChangeDetectionStrategy,
        isDefaultChangeDetectionStrategy;
import 'package:angular/src/core/linker/app_view_utils.dart'
    show NAMESPACE_URIS;
import 'package:angular/src/core/linker/view_type.dart';
import 'package:angular/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular_compiler/angular_compiler.dart';

import '../compile_metadata.dart'
    show
        CompileIdentifierMetadata,
        CompileDirectiveMetadata,
        CompileTypeMetadata;
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
        getViewFactoryName,
        createFlatArray,
        createDebugInfoTokenExpression,
        createSetAttributeParams,
        componentFromDirectives;

const IMPLICIT_TEMPLATE_VAR = "\$implicit";
const CLASS_ATTR = "class";
const STYLE_ATTR = "style";
var cloneAnchorNodeExpr =
    o.importExpr(Identifiers.ngAnchor).callMethod('clone', [o.literal(false)]);
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
  final Parser parser;
  final List<ViewCompileDependency> targetDependencies;
  final StylesCompileResult stylesCompileResult;
  static Map<String, CompileIdentifierMetadata> tagNameToIdentifier;

  int nestedViewCount = 0;

  /// Local variable name used to refer to document. null if not created yet.
  static final defaultDocVarName = 'doc';
  String docVarName;

  ViewBuilderVisitor(this.view, this.parser, this.targetDependencies,
      this.stylesCompileResult) {
    tagNameToIdentifier ??= {
      'a': Identifiers.HTML_ANCHOR_ELEMENT,
      'area': Identifiers.HTML_AREA_ELEMENT,
      'audio': Identifiers.HTML_AUDIO_ELEMENT,
      'button': Identifiers.HTML_BUTTON_ELEMENT,
      'canvas': Identifiers.HTML_CANVAS_ELEMENT,
      'div': Identifiers.HTML_DIV_ELEMENT,
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
      return parent.component != null ? o.NULL_EXPR : parent.renderNode;
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
    // build method and write reference to class member.
    // Otherwise we can create a local variable and not balloon class prototype.
    if (isBound) {
      view.nameResolver.addField(new o.ClassField(fieldName,
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
    String tagName = name.toLowerCase();
    var elementType = tagNameToIdentifier[tagName];
    elementType ??= Identifiers.HTML_ELEMENT;
    // TODO: classify as HtmlElement or SvgElement to improve further.
    return elementType;
  }

  dynamic visitElement(ElementAst ast, dynamic context) {
    CompileElement parent = context;
    var nodeIndex = view.nodes.length;

    bool isRootHostElement = nodeIndex == 0 && view.viewType == ViewType.HOST;
    var fieldName =
        isRootHostElement ? appViewRootElementName : '_el_$nodeIndex';

    bool isHostRootView = nodeIndex == 0 && view.viewType == ViewType.HOST;
    var elementType = isHostRootView
        ? Identifiers.HTML_HTML_ELEMENT
        : identifierFromTagName(ast.name);

    if (!isRootHostElement) {
      view.nameResolver.addField(new o.ClassField(fieldName,
          outputType: o.importType(elementType),
          modifiers: const [o.StmtModifier.Private]));
    }

    var directives = <CompileDirectiveMetadata>[];
    for (var dir in ast.directives) directives.add(dir.directive);
    CompileDirectiveMetadata component = componentFromDirectives(directives);

    o.Expression compViewExpr;
    bool isDeferred = false;
    if (component != null) {
      isDeferred = nodeIndex == 0 &&
          (view.declarationElement.sourceAst is EmbeddedTemplateAst) &&
          (view.declarationElement.sourceAst as EmbeddedTemplateAst)
              .hasDeferredComponent;

      String compViewName = '_compView_$nodeIndex';
      compViewExpr = new o.ReadClassMemberExpr(compViewName);

      CompileIdentifierMetadata componentViewIdentifier =
          new CompileIdentifierMetadata(name: 'View${component.type.name}0');
      targetDependencies
          .add(new ViewCompileDependency(component, componentViewIdentifier));

      var viewType = isDeferred
          ? o.importType(Identifiers.AppView, null)
          : o.importType(componentViewIdentifier);
      view.nameResolver
          .addField(new o.ClassField(compViewName, outputType: viewType));

      if (isDeferred) {
        // When deferred, we use AppView<dynamic> as type to store instance
        // of component and create the instance using:
        // deferredLibName.viewFactory_SomeComponent(...)
        CompileIdentifierMetadata nestedComponentIdentifier =
            new CompileIdentifierMetadata(
                name: getViewFactoryName(component, 0));
        targetDependencies.add(
            new ViewCompileDependency(component, nestedComponentIdentifier));

        var importExpr = o.importExpr(nestedComponentIdentifier);
        view.createMethod.addStmt(new o.WriteClassMemberExpr(compViewName,
            importExpr.callFn([o.THIS_EXPR, o.literal(nodeIndex)])).toStmt());
      } else {
        // Create instance of component using ViewSomeComponent0 AppView.
        var createComponentInstanceExpr = o
            .importExpr(componentViewIdentifier)
            .instantiate([o.THIS_EXPR, o.literal(nodeIndex)]);
        view.createMethod.addStmt(new o.WriteClassMemberExpr(
                compViewName, createComponentInstanceExpr)
            .toStmt());
      }
    }

    var createRenderNodeExpr;
    o.Expression tagNameExpr = o.literal(ast.name);
    bool isHtmlElement;
    if (isHostRootView) {
      // Assign root element created by viewfactory call to our own root.
      view.createMethod.addStmt(new o.WriteClassMemberExpr(
              fieldName, compViewExpr.prop(appViewRootElementName))
          .toStmt());
      if (view.genConfig.genDebugInfo) {
        view.createMethod.addStmt(createDbgIndexElementCall(
            new o.ReadClassMemberExpr(fieldName), view.nodes.length, ast));
      }
      isHtmlElement = false;
    } else {
      isHtmlElement = detectHtmlElementFromTagName(ast.name);
      var parentRenderNodeExpr = _getParentRenderNode(parent);
      final generateDebugInfo = view.genConfig.genDebugInfo;
      if (component == null) {
        // Create element or elementNS. AST encodes svg path element as
        // @svg:path.
        bool isNamespacedElement =
            ast.name.startsWith('@') && ast.name.contains(':');
        if (isNamespacedElement) {
          var nameParts = ast.name.substring(1).split(':');
          String ns = NAMESPACE_URIS[nameParts[0]];
          createRenderNodeExpr = o
              .importExpr(Identifiers.HTML_DOCUMENT)
              .callMethod(
                  'createElementNS', [o.literal(ns), o.literal(nameParts[1])]);
          view.createMethod.addStmt(
              new o.WriteClassMemberExpr(fieldName, createRenderNodeExpr)
                  .toStmt());
          if (parentRenderNodeExpr != null &&
              parentRenderNodeExpr != o.NULL_EXPR) {
            // Write code to append to parent node.
            view.createMethod.addStmt(parentRenderNodeExpr.callMethod(
                'append', [new o.ReadClassMemberExpr(fieldName)]).toStmt());
          }
          if (generateDebugInfo) {
            view.createMethod.addStmt(createDbgElementCall(
                new o.ReadClassMemberExpr(fieldName), view.nodes.length, ast));
          }
        } else {
          // Generate code to create Html element, append to parent and
          // optionally add dbg info in single call.
          _createElementAndAppend(tagNameExpr, parentRenderNodeExpr, fieldName,
              generateDebugInfo, ast.sourceSpan, nodeIndex);
        }
      } else {
        view.createMethod.addStmt(new o.WriteClassMemberExpr(
                fieldName, compViewExpr.prop(appViewRootElementName))
            .toStmt());
        if (parentRenderNodeExpr != null &&
            parentRenderNodeExpr != o.NULL_EXPR) {
          // Write code to append to parent node.
          view.createMethod.addStmt(parentRenderNodeExpr.callMethod(
              'append', [new o.ReadClassMemberExpr(fieldName)]).toStmt());
        }
        if (generateDebugInfo) {
          view.createMethod.addStmt(createDbgElementCall(
              new o.ReadClassMemberExpr(fieldName), view.nodes.length, ast));
        }
      }
    }

    var renderNode = new o.ReadClassMemberExpr(fieldName);

    _writeLiteralAttributeValues(ast, fieldName, directives, view.createMethod);

    if (!isHostRootView &&
        view.component.template.encapsulation == ViewEncapsulation.Emulated) {
      // Set ng_content class for CSS shim.
      String shimMethod =
          elementType != Identifiers.HTML_ELEMENT || (component != null)
              ? 'addShimC'
              : 'addShimE';
      o.Expression shimClassExpr = new o.InvokeMemberMethodExpr(
          shimMethod, [new o.ReadClassMemberExpr(fieldName)]);
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
        logger,
        isHtmlElement: isHtmlElement,
        hasTemplateRefQuery: parent.hasTemplateRefQuery);
    view.nodes.add(compileElement);

    if (component != null) {
      compileElement.componentView = compViewExpr;
      view.addViewChild(compViewExpr);
    }

    // beforeChildren() -> _prepareProviderInstances will create the actual
    // directive and component instances.
    compileElement.beforeChildren(isDeferred);
    _addRootNodeAndProject(compileElement, ast.ngContentIndex, parent);
    templateVisitAll(this, ast.children, compileElement);
    compileElement.afterChildren(view.nodes.length - nodeIndex - 1);

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

      view.createMethod.addStmt(compViewExpr.callMethod('create',
          [compileElement.getComponent(), codeGenContentNodes]).toStmt());
    }
    return null;
  }

  void _createElementAndAppend(
      o.Expression tagName,
      o.Expression parent,
      String targetFieldName,
      bool generateDebugInfo,
      SourceSpan debugSpan,
      int debugNodeIndex) {
    // No namespace just call [document.createElement].
    if (docVarName == null) {
      view.createMethod.addStmt(_createLocalDocumentVar());
    }
    if (parent != null && parent != o.NULL_EXPR) {
      o.Expression createExpr;
      if (generateDebugInfo) {
        createExpr = o.importExpr(Identifiers.createAndAppendDbg).callFn([
          o.THIS_EXPR,
          new o.ReadVarExpr(docVarName),
          tagName,
          parent,
          o.literal(debugNodeIndex),
          debugSpan?.start == null
              ? o.NULL_EXPR
              : o.literal(debugSpan.start.line),
          debugSpan?.start == null
              ? o.NULL_EXPR
              : o.literal(debugSpan.start.column)
        ]);
      } else {
        createExpr = o
            .importExpr(Identifiers.createAndAppend)
            .callFn([new o.ReadVarExpr(docVarName), tagName, parent]);
      }
      view.createMethod.addStmt(
          new o.WriteClassMemberExpr(targetFieldName, createExpr).toStmt());
    } else {
      // No parent node, just create element and assign.
      var createRenderNodeExpr =
          new o.ReadVarExpr(docVarName).callMethod('createElement', [tagName]);
      view.createMethod.addStmt(
          new o.WriteClassMemberExpr(targetFieldName, createRenderNodeExpr)
              .toStmt());
      if (generateDebugInfo) {
        view.createMethod.addStmt(o.importExpr(Identifiers.dbgElm).callFn([
          o.THIS_EXPR,
          new o.ReadClassMemberExpr(targetFieldName),
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
    return o.importExpr(Identifiers.dbgElm).callFn([
      o.THIS_EXPR,
      nodeExpr,
      o.literal(nodeIndex),
      sourceLocation == null ? o.NULL_EXPR : o.literal(sourceLocation.line),
      sourceLocation == null ? o.NULL_EXPR : o.literal(sourceLocation.column)
    ]).toStmt();
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
    var fieldName = '_anchor_$nodeIndex';
    o.Expression anchorVarExpr;
    var readVarExpr = o.variable(fieldName);
    anchorVarExpr = readVarExpr;
    var assignCloneAnchorNodeExpr = readVarExpr.set(cloneAnchorNodeExpr);
    view.createMethod.addStmt(assignCloneAnchorNodeExpr.toDeclStmt());
    var parentNode = _getParentRenderNode(parent);
    if (parentNode != o.NULL_EXPR) {
      var addCommentStmt =
          parentNode.callMethod('append', [anchorVarExpr]).toStmt();
      view.createMethod.addStmt(addCommentStmt);
    }

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
        templateVariableBindings,
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

// Reads hostAttributes from each directive and merges with declaredHtmlAttrs
// to return a single map from name to value(expression).
List<List<String>> _mergeHtmlAndDirectiveAttrs(
    Map<String, String> declaredHtmlAttrs,
    List<CompileDirectiveMetadata> directives,
    {bool excludeComponent: false}) {
  Map<String, String> result = {};
  var mergeCount = <String, int>{};
  declaredHtmlAttrs.forEach((name, value) {
    result[name] = value;
    if (mergeCount.containsKey(name)) {
      mergeCount[name]++;
    } else {
      mergeCount[name] = 1;
    }
  });
  for (CompileDirectiveMetadata directiveMeta in directives) {
    directiveMeta.hostAttributes.forEach((name, value) {
      if (mergeCount.containsKey(name)) {
        mergeCount[name]++;
      } else {
        mergeCount[name] = 1;
      }
    });
  }
  for (CompileDirectiveMetadata directiveMeta in directives) {
    bool isComponent = directiveMeta.isComponent;
    for (String name in directiveMeta.hostAttributes.keys) {
      var value = directiveMeta.hostAttributes[name];
      if (excludeComponent &&
          isComponent &&
          !((name == CLASS_ATTR || name == STYLE_ATTR) &&
              mergeCount[name] > 1)) {
        continue;
      }
      var prevValue = result[name];
      result[name] = prevValue != null
          ? mergeAttributeValue(name, prevValue, value)
          : value;
    }
  }
  return mapToKeyValueArray(result);
}

Map<String, String> _attribListToMap(List<AttrAst> attrs) {
  Map<String, String> htmlAttrs = {};
  for (AttrAst attr in attrs) {
    htmlAttrs[attr.name] = attr.value;
  }
  return htmlAttrs;
}

String mergeAttributeValue(
    String attrName, String attrValue1, String attrValue2) {
  if (attrName == CLASS_ATTR || attrName == STYLE_ATTR) {
    return '$attrValue1 $attrValue2';
  } else {
    return attrValue2;
  }
}

/// Writes literal attribute values on the element itself and those
/// contributed from directives on the ast node.
///
/// !Component level attributes are excluded since we want to avoid per
//  call site duplication.
void _writeLiteralAttributeValues(ElementAst ast, String elementFieldName,
    List<CompileDirectiveMetadata> directives, CompileMethod method) {
  var htmlAttrs = _attribListToMap(ast.attrs);
  // Create statements to initialize literal attribute values.
  // For example, a directive may have hostAttributes setting class name.
  var attrNameAndValues = _mergeHtmlAndDirectiveAttrs(htmlAttrs, directives,
      excludeComponent: true);
  for (int i = 0, len = attrNameAndValues.length; i < len; i++) {
    o.Statement stmt = _createSetAttributeStatement(ast.name, elementFieldName,
        attrNameAndValues[i][0], attrNameAndValues[i][1]);
    method.addStmt(stmt);
  }
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

List<List<String>> mapToKeyValueArray(Map<String, String> data) {
  var entryArray = <List<String>>[];
  data.forEach((String name, String value) {
    entryArray.add([name, value]);
  });
  // We need to sort to get a defined output order
  // for tests and for caching generated artifacts...
  entryArray.sort((entry1, entry2) => entry1[0].compareTo(entry2[0]));
  var keyValueArray = <List<String>>[];
  for (var entry in entryArray) {
    keyValueArray.add([entry[0], entry[1]]);
  }
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
  var viewMethods = (new List.from([
    new o.ClassMethod("build", [], generateBuildMethod(view, parser),
        o.importType(Identifiers.ComponentRef, null), null, ['override']),
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
  ])
    ..addAll(view.eventHandlerMethods));
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
          .where((o.ClassMethod method) =>
              method.body != null && method.body.length > 0)
          .toList() as List<o.ClassMethod>);
  _addRenderTypeCtorInitialization(view, viewClass);
  return viewClass;
}

o.ClassMethod _createViewClassConstructor(
    CompileView view, o.Expression nodeDebugInfosVar) {
  var emptyTemplateVariableBindings = view.templateVariableBindings
      .map((List entry) => [entry[0], o.NULL_EXPR])
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
      o.Statement stmt = _createSetAttributeStatement(
          tagName, appViewRootElementName, name, value);
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

  final initParams = [createFlatArray(view.rootNodesOrViewContainers)];
  final subscriptions = o.literalArr(
    view.subscriptions,
    view.subscriptions.isEmpty
        ? new o.ArrayType(null, const [o.TypeModifier.Const])
        : null,
  );

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
  if (view.genConfig.genDebugInfo) {
    final renderNodes = view.nodes.map((node) => node.renderNode).toList();
    initParams.add(o.literalArr(renderNodes));
  }

  statements.add(new o.InvokeMemberMethodExpr('init', initParams).toStmt());

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
  if (view.genConfig.profileFor == Profile.build) {
    genProfileBuildEnd(view, statements);
  }
  statements.add(new o.ReturnStatement(resultExpr));
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
  if (readVars.contains(DetectChangesVars.valUnwrapper.name)) {
    varStmts.add(DetectChangesVars.valUnwrapper
        .set(o.importExpr(Identifiers.ValueUnwrapper).instantiate([]))
        .toDeclStmt(null, [o.StmtModifier.Final]));
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
