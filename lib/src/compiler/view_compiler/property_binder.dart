library angular2.src.compiler.view_compiler.property_binder;

import "package:angular2/src/core/change_detection/constants.dart"
    show isDefaultChangeDetectionStrategy;
import "package:angular2/src/core/metadata/lifecycle_hooks.dart"
    show LifecycleHooks;
import "package:angular2/src/core/security.dart";
import "package:angular2/src/facade/lang.dart" show isBlank, isPresent;

import "../expression_parser/ast.dart" as cdAst;
import "../identifiers.dart" show Identifiers;
import "../output/output_ast.dart" as o;
import "../template_ast.dart"
    show
    BoundTextAst,
    BoundElementPropertyAst,
    DirectiveAst,
    PropertyBindingType;
import "../util.dart" show camelCaseToDashCase;
import "compile_binding.dart" show CompileBinding;
import "compile_element.dart" show CompileElement, CompileNode;
import "compile_method.dart" show CompileMethod;
import "compile_view.dart" show CompileView;
import "constants.dart" show DetectChangesVars, ViewProperties;
import "expression_converter.dart" show convertCdExpressionToIr;

o.ReadPropExpr createBindFieldExpr(num exprIndex) {
  return o.THIS_EXPR.prop('''_expr_${ exprIndex}''');
}

o.ReadVarExpr createCurrValueExpr(num exprIndex) {
  return o.variable('''currVal_${ exprIndex}''');
}

void bind(
    CompileView view,
    o.ReadVarExpr currValExpr,
    o.ReadPropExpr fieldExpr,
    cdAst.AST parsedExpression,
    o.Expression context,
    List<o.Statement> actions,
    CompileMethod method) {
  var checkExpression = convertCdExpressionToIr(
      view, context, parsedExpression, DetectChangesVars.valUnwrapper);
  if (isBlank(checkExpression.expression)) {
    // e.g. an empty expression was given
    return;
  }
  view.fields
      .add(new o.ClassField(fieldExpr.name, null, [o.StmtModifier.Private]));
  view.createMethod.addStmt(o.THIS_EXPR
      .prop(fieldExpr.name)
      .set(o.importExpr(Identifiers.uninitialized))
      .toStmt());
  if (checkExpression.needsValueUnwrapper) {
    var initValueUnwrapperStmt =
        DetectChangesVars.valUnwrapper.callMethod("reset", []).toStmt();
    method.addStmt(initValueUnwrapperStmt);
  }
  method.addStmt(currValExpr
      .set(checkExpression.expression)
      .toDeclStmt(null, [o.StmtModifier.Final]));
  o.Expression condition = o
      .importExpr(Identifiers.checkBinding)
      .callFn([DetectChangesVars.throwOnChange, fieldExpr, currValExpr]);
  if (checkExpression.needsValueUnwrapper) {
    condition =
        DetectChangesVars.valUnwrapper.prop("hasWrappedValue").or(condition);
  }
  method.addStmt(new o.IfStmt(
      condition,
      new List.from(actions)
        ..addAll(
            [o.THIS_EXPR.prop(fieldExpr.name).set(currValExpr).toStmt()])));
}

bindRenderText(
    BoundTextAst boundText, CompileNode compileNode, CompileView view) {
  var bindingIndex = view.bindings.length;
  view.bindings.add(new CompileBinding(compileNode, boundText));
  var currValExpr = createCurrValueExpr(bindingIndex);
  var valueField = createBindFieldExpr(bindingIndex);
  view.detectChangesRenderPropertiesMethod
      .resetDebugInfo(compileNode.nodeIndex, boundText);
  bind(
      view,
      currValExpr,
      valueField,
      boundText.value,
      o.THIS_EXPR.prop("context"),
      [
        o.THIS_EXPR.prop("renderer").callMethod(
            "setText", [compileNode.renderNode, currValExpr]).toStmt()
      ],
      view.detectChangesRenderPropertiesMethod);
}

bindAndWriteToRenderer(List<BoundElementPropertyAst> boundProps,
    o.Expression context, CompileElement compileElement) {
  var view = compileElement.view;
  var renderNode = compileElement.renderNode;
  boundProps.forEach((boundProp) {
    var bindingIndex = view.bindings.length;
    view.bindings.add(new CompileBinding(compileElement, boundProp));
    view.detectChangesRenderPropertiesMethod
        .resetDebugInfo(compileElement.nodeIndex, boundProp);
    var fieldExpr = createBindFieldExpr(bindingIndex);
    var currValExpr = createCurrValueExpr(bindingIndex);
    String renderMethod;
    o.Expression renderValue = sanitizedValue(boundProp, currValExpr);
    var updateStmts = <o.Statement>[];
    switch (boundProp.type) {
      case PropertyBindingType.Property:
        renderMethod = "setElementProperty";
        if (view.genConfig.logBindingUpdate) {
          updateStmts.add(
              logBindingUpdateStmt(renderNode, boundProp.name, currValExpr));
        }
        break;
      case PropertyBindingType.Attribute:
        renderMethod = "setElementAttribute";
        renderValue = renderValue
            .isBlank()
            .conditional(o.NULL_EXPR, renderValue.callMethod("toString", []));
        break;
      case PropertyBindingType.Class:
        renderMethod = "setElementClass";
        break;
      case PropertyBindingType.Style:
        renderMethod = "setElementStyle";
        o.Expression strValue = renderValue.callMethod("toString", []);
        if (isPresent(boundProp.unit)) {
          strValue = strValue.plus(o.literal(boundProp.unit));
        }
        renderValue = renderValue.isBlank().conditional(o.NULL_EXPR, strValue);
        break;
    }
    updateStmts.add(o.THIS_EXPR.prop("renderer").callMethod(renderMethod,
        [renderNode, o.literal(boundProp.name), renderValue]).toStmt());
    bind(view, currValExpr, fieldExpr, boundProp.value, context, updateStmts,
        view.detectChangesRenderPropertiesMethod);
  });
}

o.Expression sanitizedValue(BoundElementPropertyAst boundProp,
    o.Expression renderValue) {
  String methodName;
  switch (boundProp.securityContext) {
    case TemplateSecurityContext.none:
      return renderValue;  // No sanitization needed.
    case TemplateSecurityContext.html:
      methodName = 'sanitizeHtml';
      break;
    case TemplateSecurityContext.style:
      methodName = 'sanitizeStyle';
      break;
    case TemplateSecurityContext.script:
      methodName = 'sanitizeScript';
      break;
    case TemplateSecurityContext.url:
      methodName = 'sanitizeUrl';
      break;
    case TemplateSecurityContext.resourceUrl:
      methodName = 'sanitizeResourceUrl';
      break;
    default:
      throw new ArgumentError('internal error, unexpected '
          'TemplateSecurityContext ${boundProp.securityContext}.');
  }
  var ctx = ViewProperties.viewUtils.prop('sanitizer');
  return ctx.callMethod(methodName, [renderValue]);
}


void bindRenderInputs(
    List<BoundElementPropertyAst> boundProps, CompileElement compileElement) {
  bindAndWriteToRenderer(
      boundProps, o.THIS_EXPR.prop("context"), compileElement);
}

void bindDirectiveHostProps(DirectiveAst directiveAst,
    o.Expression directiveInstance, CompileElement compileElement) {
  bindAndWriteToRenderer(
      directiveAst.hostProperties, directiveInstance, compileElement);
}

bindDirectiveInputs(DirectiveAst directiveAst, o.Expression directiveInstance,
    CompileElement compileElement) {
  if (identical(directiveAst.inputs.length, 0)) {
    return;
  }
  var view = compileElement.view;
  var detectChangesInInputsMethod = view.detectChangesInInputsMethod;
  detectChangesInInputsMethod.resetDebugInfo(
      compileElement.nodeIndex, compileElement.sourceAst);
  var lifecycleHooks = directiveAst.directive.lifecycleHooks;
  var calcChangesMap =
      !identical(lifecycleHooks.indexOf(LifecycleHooks.OnChanges), -1);
  var isOnPushComp = directiveAst.directive.isComponent &&
      !isDefaultChangeDetectionStrategy(directiveAst.directive.changeDetection);
  if (calcChangesMap) {
    detectChangesInInputsMethod
        .addStmt(DetectChangesVars.changes.set(o.NULL_EXPR).toStmt());
  }
  if (isOnPushComp) {
    detectChangesInInputsMethod
        .addStmt(DetectChangesVars.changed.set(o.literal(false)).toStmt());
  }
  directiveAst.inputs.forEach((input) {
    var bindingIndex = view.bindings.length;
    view.bindings.add(new CompileBinding(compileElement, input));
    detectChangesInInputsMethod.resetDebugInfo(compileElement.nodeIndex, input);
    var fieldExpr = createBindFieldExpr(bindingIndex);
    var currValExpr = createCurrValueExpr(bindingIndex);
    List<o.Statement> statements = [
      directiveInstance.prop(input.directiveName).set(currValExpr).toStmt()
    ];
    if (calcChangesMap) {
      statements
          .add(new o.IfStmt(DetectChangesVars.changes.identical(o.NULL_EXPR), [
        DetectChangesVars.changes
            .set(o.literalMap(
                [], new o.MapType(o.importType(Identifiers.SimpleChange))))
            .toStmt()
      ]));
      statements.add(DetectChangesVars.changes
          .key(o.literal(input.directiveName))
          .set(o
              .importExpr(Identifiers.SimpleChange)
              .instantiate([fieldExpr, currValExpr]))
          .toStmt());
    }
    if (isOnPushComp) {
      statements.add(DetectChangesVars.changed.set(o.literal(true)).toStmt());
    }
    if (view.genConfig.logBindingUpdate) {
      statements.add(logBindingUpdateStmt(
          compileElement.renderNode, input.directiveName, currValExpr));
    }
    bind(view, currValExpr, fieldExpr, input.value, o.THIS_EXPR.prop("context"),
        statements, detectChangesInInputsMethod);
  });
  if (isOnPushComp) {
    detectChangesInInputsMethod
        .addStmt(new o.IfStmt(DetectChangesVars.changed, [
      compileElement.appElement
          .prop("componentView")
          .callMethod("markAsCheckOnce", []).toStmt()
    ]));
  }
}

o.Statement logBindingUpdateStmt(
    o.Expression renderNode, String propName, o.Expression value) {
  return o.THIS_EXPR.prop("renderer").callMethod("setBindingDebugInfo", [
    renderNode,
    o.literal('''ng-reflect-${ camelCaseToDashCase ( propName )}'''),
    value.isBlank().conditional(o.NULL_EXPR, value.callMethod("toString", []))
  ]).toStmt();
}
