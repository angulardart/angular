import 'package:angular2/src/core/change_detection/constants.dart'
    show isDefaultChangeDetectionStrategy;
import 'package:angular2/src/core/metadata/lifecycle_hooks.dart'
    show LifecycleHooks;
import 'package:angular2/src/core/security.dart';

import '../expression_parser/ast.dart' as ast;
import '../identifiers.dart' show Identifiers;
import '../output/output_ast.dart' as o;
import '../template_ast.dart'
    show
        BoundTextAst,
        BoundElementPropertyAst,
        DirectiveAst,
        PropertyBindingType;
import "../compiler_utils.dart" show camelCaseToDashCase;
import 'view_compiler_utils.dart' show NAMESPACE_URIS, createSetAttributeParams;
import 'expression_converter.dart' show convertCdExpressionToIr;
import 'compile_binding.dart' show CompileBinding;
import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_method.dart' show CompileMethod;
import 'compile_view.dart' show CompileView;
import 'constants.dart' show DetectChangesVars;

o.ReadClassMemberExpr createBindFieldExpr(num exprIndex) =>
    new o.ReadClassMemberExpr('_expr_${exprIndex}');

o.ReadVarExpr createCurrValueExpr(num exprIndex) =>
    o.variable('currVal_${exprIndex}');

void bind(
    CompileView view,
    o.ReadVarExpr currValExpr,
    o.ReadClassMemberExpr fieldExpr,
    ast.AST parsedExpression,
    o.Expression context,
    List<o.Statement> actions,
    CompileMethod method) {
  var checkExpression = convertCdExpressionToIr(
      view, context, parsedExpression, DetectChangesVars.valUnwrapper);
  if (checkExpression.expression == null) {
    // e.g. an empty expression was given
    return;
  }
  view.fields.add(new o.ClassField(fieldExpr.name,
      modifiers: const [o.StmtModifier.Private],
      initializer: o.importExpr(Identifiers.uninitialized)));
  if (checkExpression.needsValueUnwrapper) {
    var initValueUnwrapperStmt =
        DetectChangesVars.valUnwrapper.callMethod('reset', []).toStmt();
    method.addStmt(initValueUnwrapperStmt);
  }
  method.addStmt(currValExpr
      .set(checkExpression.expression)
      .toDeclStmt(null, [o.StmtModifier.Final]));
  o.Expression condition =
      o.importExpr(Identifiers.checkBinding).callFn([fieldExpr, currValExpr]);
  if (checkExpression.needsValueUnwrapper) {
    condition =
        DetectChangesVars.valUnwrapper.prop('hasWrappedValue').or(condition);
  }
  method.addStmt(new o.IfStmt(
      condition,
      new List.from(actions)
        ..addAll([
          new o.WriteClassMemberExpr(fieldExpr.name, currValExpr).toStmt()
        ])));
}

void bindRenderText(
    BoundTextAst boundText, CompileNode compileNode, CompileView view) {
  var bindingIndex = view.bindings.length;
  view.bindings.add(new CompileBinding(compileNode, boundText));
  // Expression for current value of expression when value is re-read.
  var currValExpr = createCurrValueExpr(bindingIndex);
  // Expression that points to _expr_## stored value.
  var valueField = createBindFieldExpr(bindingIndex);
  view.detectChangesRenderPropertiesMethod
      .resetDebugInfo(compileNode.nodeIndex, boundText);
  bind(
      view,
      currValExpr,
      valueField,
      boundText.value,
      new o.ReadClassMemberExpr('ctx'),
      [compileNode.renderNode.prop('text').set(currValExpr).toStmt()],
      view.detectChangesRenderPropertiesMethod);
}

/// For each bound property, creates code to update the binding.
///
/// Example:
///     this.debug(4,2,5);
///     final currVal_1 = this.context.someBoolValue;
///     if (import6.checkBinding(this._expr_1,currVal_1)) {
///       this.renderer.setElementClass(this._el_4,'disabled',currVal_1);
///       this._expr_1 = currVal_1;
///     }
void bindAndWriteToRenderer(List<BoundElementPropertyAst> boundProps,
    o.Expression context, CompileElement compileElement) {
  var view = compileElement.view;
  var renderNode = compileElement.renderNode;
  boundProps.forEach((boundProp) {
    var bindingIndex = view.bindings.length;

    // Add to view bindings collection.
    view.bindings.add(new CompileBinding(compileElement, boundProp));

    // Generate call to this.debug(index, column, row);
    view.detectChangesRenderPropertiesMethod
        .resetDebugInfo(compileElement.nodeIndex, boundProp);

    // Expression that points to _expr_## stored value.
    var fieldExpr = createBindFieldExpr(bindingIndex);

    // Expression for current value of expression when value is re-read.
    var currValExpr = createCurrValueExpr(bindingIndex);

    String renderMethod;
    // Wraps current value with sanitization call if necessary.
    o.Expression renderValue = sanitizedValue(boundProp, currValExpr);

    var updateStmts = <o.Statement>[];
    switch (boundProp.type) {
      case PropertyBindingType.Property:
        renderMethod = 'setElementProperty';
        // If user asked for logging bindings, generate code to log them.
        if (view.genConfig.logBindingUpdate) {
          updateStmts.add(
              logBindingUpdateStmt(renderNode, boundProp.name, currValExpr));
        }
        updateStmts.add(new o.ReadClassMemberExpr('renderer').callMethod(
            renderMethod,
            [renderNode, o.literal(boundProp.name), renderValue]).toStmt());
        break;
      case PropertyBindingType.Attribute:
        // For attributes convert value to a string.
        // TODO: Once we have analyzer summaries and know the type is already
        // String short-circuit
        renderValue = renderValue
            .isBlank()
            .conditional(o.NULL_EXPR, renderValue.callMethod('toString', []));

        var attrNs;
        String attrName = boundProp.name;
        if (attrName.startsWith('@') && attrName.contains(':')) {
          var nameParts = attrName.substring(1).split(':');
          attrNs = NAMESPACE_URIS[nameParts[0]];
          attrName = nameParts[1];
        }
        var params = createSetAttributeParams(
            compileElement.renderNodeFieldName, attrNs, attrName, renderValue);

        updateStmts.add(new o.InvokeMemberMethodExpr(
                attrNs == null ? 'setAttr' : 'setAttrNS', params)
            .toStmt());
        break;
      case PropertyBindingType.Class:
        renderMethod =
            compileElement.isHtmlElement ? 'updateClass' : 'updateElemClass';
        updateStmts.add(new o.InvokeMemberMethodExpr(renderMethod, [
          compileElement.renderNode,
          o.literal(boundProp.name),
          renderValue
        ]).toStmt());
        break;
      case PropertyBindingType.Style:
        // value = value?.toString().
        o.Expression styleValueExpr =
            currValExpr.callMethod('toString', [], checked: true);
        // Add units for style value if defined in template.
        if (boundProp.unit != null) {
          styleValueExpr = styleValueExpr.isBlank().conditional(
              o.NULL_EXPR, styleValueExpr.plus(o.literal(boundProp.unit)));
        }
        // Call Element.style.setProperty(propName, value);
        o.Expression updateStyleExpr = compileElement.renderNode
            .prop('style')
            .callMethod(
                'setProperty', [o.literal(boundProp.name), styleValueExpr]);
        updateStmts.add(updateStyleExpr.toStmt());
        break;
    }
    bind(view, currValExpr, fieldExpr, boundProp.value, context, updateStmts,
        view.detectChangesRenderPropertiesMethod);
  });
}

o.Expression sanitizedValue(
    BoundElementPropertyAst boundProp, o.Expression renderValue) {
  String methodName;
  switch (boundProp.securityContext) {
    case TemplateSecurityContext.none:
      return renderValue; // No sanitization needed.
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
  var ctx = o.importExpr(Identifiers.appViewUtils).prop('sanitizer');
  return ctx.callMethod(methodName, [renderValue]);
}

void bindRenderInputs(
    List<BoundElementPropertyAst> boundProps, CompileElement compileElement) {
  bindAndWriteToRenderer(
      boundProps, new o.ReadClassMemberExpr('ctx'), compileElement);
}

void bindDirectiveHostProps(DirectiveAst directiveAst,
    o.Expression directiveInstance, CompileElement compileElement) {
  bindAndWriteToRenderer(
      directiveAst.hostProperties, directiveInstance, compileElement);
}

void bindDirectiveInputs(DirectiveAst directiveAst,
    o.Expression directiveInstance, CompileElement compileElement) {
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
    bind(
        view,
        currValExpr,
        fieldExpr,
        input.value,
        new o.ReadClassMemberExpr('ctx'),
        statements,
        detectChangesInInputsMethod);
  });
  if (isOnPushComp) {
    detectChangesInInputsMethod
        .addStmt(new o.IfStmt(DetectChangesVars.changed, [
      compileElement.appElement
          .prop('componentView')
          .callMethod('markAsCheckOnce', []).toStmt()
    ]));
  }
}

o.Statement logBindingUpdateStmt(
    o.Expression renderNode, String propName, o.Expression value) {
  return o.THIS_EXPR.prop('renderer').callMethod('setBindingDebugInfo', [
    renderNode,
    o.literal('ng-reflect-${ camelCaseToDashCase ( propName )}'),
    value.isBlank().conditional(o.NULL_EXPR, value.callMethod('toString', []))
  ]).toStmt();
}
