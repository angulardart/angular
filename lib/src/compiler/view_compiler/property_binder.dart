import 'package:angular2/src/core/change_detection/constants.dart'
    show isDefaultChangeDetectionStrategy, ChangeDetectionStrategy;
import 'package:angular2/src/core/metadata/lifecycle_hooks.dart'
    show LifecycleHooks;
import 'package:angular2/src/core/security.dart';
import 'package:angular2/src/transform/common/names.dart'
    show toTemplateExtension;

import "../compile_metadata.dart";
import '../expression_parser/ast.dart' as ast;
import '../identifiers.dart' show Identifiers;
import '../output/output_ast.dart' as o;
import '../template_ast.dart'
    show
        BoundTextAst,
        BoundElementPropertyAst,
        DirectiveAst,
        PropertyBindingType;
import 'compile_binding.dart' show CompileBinding;
import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_method.dart' show CompileMethod;
import 'compile_view.dart' show CompileView;
import 'constants.dart' show DetectChangesVars;
import 'expression_converter.dart' show convertCdExpressionToIr;
import 'view_builder.dart' show buildUpdaterFunctionName;
import 'view_compiler_utils.dart' show createSetAttributeParams;
import 'package:angular2/src/core/linker/app_view_utils.dart'
    show NAMESPACE_URIS;

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
    CompileMethod method,
    {o.OutputType fieldType}) {
  var checkExpression = convertCdExpressionToIr(
      view,
      context,
      parsedExpression,
      DetectChangesVars.valUnwrapper,
      view.component.template.preserveWhitespace);
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
        updateStmts.add(new o.InvokeMemberMethodExpr(
                'setProp', [renderNode, o.literal(boundProp.name), renderValue])
            .toStmt());
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
  var isStatefulComp = directiveAst.directive.isComponent &&
      directiveAst.directive.changeDetection ==
          ChangeDetectionStrategy.Stateful;
  if (calcChangesMap) {
    detectChangesInInputsMethod
        .addStmt(DetectChangesVars.changes.set(o.NULL_EXPR).toStmt());
  }
  if (!isStatefulComp && isOnPushComp) {
    detectChangesInInputsMethod
        .addStmt(DetectChangesVars.changed.set(o.literal(false)).toStmt());
  }
  // directiveAst contains the target directive we are updating.
  // input is a BoundPropertyAst that contains binding metadata.
  for (var input in directiveAst.inputs) {
    var bindingIndex = view.bindings.length;
    view.bindings.add(new CompileBinding(compileElement, input));
    detectChangesInInputsMethod.resetDebugInfo(compileElement.nodeIndex, input);
    var fieldExpr = createBindFieldExpr(bindingIndex);
    var currValExpr = createCurrValueExpr(bindingIndex);
    var statements = <o.Statement>[];

    // Optimization specifically for NgIf. Since the directive already performs
    // change detection we can directly update it's input.
    // TODO: generalize to SingleInputDirective mixin.
    if (directiveAst.directive.identifier.name == 'NgIf' &&
        input.directiveName == 'ngIf') {
      var checkExpression = convertCdExpressionToIr(
          view,
          new o.ReadClassMemberExpr('ctx'),
          input.value,
          DetectChangesVars.valUnwrapper,
          view.component.template.preserveWhitespace);
      detectChangesInInputsMethod.addStmt(directiveInstance
          .prop(input.directiveName)
          .set(checkExpression.expression)
          .toStmt());
      if (view.genConfig.logBindingUpdate) {
        detectChangesInInputsMethod.addStmt(logBindingUpdateStmt(
            compileElement.renderNode,
            input.directiveName,
            checkExpression.expression));
      }
      continue;
    }
    if (isStatefulComp) {
      // Since we are not going to call markAsCheckOnce anymore we need to
      // generate a call to property updater that will invoke setState() on the
      // component if value has changed.
      String updaterFunctionName = buildUpdaterFunctionName(
          directiveAst.directive.type.name, input.directiveName);
      var updateFuncExpr = o.importExpr(new CompileIdentifierMetadata(
          name: updaterFunctionName,
          moduleUrl:
              toTemplateExtension(directiveAst.directive.identifier.moduleUrl),
          prefix: directiveAst.directive.identifier.prefix));
      statements.add(updateFuncExpr
          .callFn([directiveInstance, fieldExpr, currValExpr]).toStmt());
    } else {
      // Set property on directiveInstance to new value.
      statements.add(directiveInstance
          .prop(input.directiveName)
          .set(currValExpr)
          .toStmt());
    }
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
    if (!isStatefulComp && isOnPushComp) {
      statements.add(DetectChangesVars.changed.set(o.literal(true)).toStmt());
    }
    if (view.genConfig.logBindingUpdate) {
      statements.add(logBindingUpdateStmt(
          compileElement.renderNode, input.directiveName, currValExpr));
    }
    // Execute actions and assign result to fieldExpr which hold previous value.
    String inputTypeName = directiveAst.directive.inputTypes != null
        ? directiveAst.directive.inputTypes[input.directiveName]
        : null;
    var inputType = inputTypeName != null
        ? o.importType(new CompileIdentifierMetadata(name: inputTypeName))
        : null;
    if (isStatefulComp) {
      bindToUpdateMethod(
          view,
          currValExpr,
          fieldExpr,
          input.value,
          new o.ReadClassMemberExpr('ctx'),
          statements,
          detectChangesInInputsMethod,
          fieldType: inputType);
    } else {
      bind(
          view,
          currValExpr,
          fieldExpr,
          input.value,
          new o.ReadClassMemberExpr('ctx'),
          statements,
          detectChangesInInputsMethod,
          fieldType: inputType);
    }
  }
  if (!isStatefulComp && isOnPushComp) {
    detectChangesInInputsMethod
        .addStmt(new o.IfStmt(DetectChangesVars.changed, [
      compileElement.appViewContainer
          .prop('componentView')
          .callMethod('markAsCheckOnce', []).toStmt()
    ]));
  }
}

void bindToUpdateMethod(
    CompileView view,
    o.ReadVarExpr currValExpr,
    o.ReadClassMemberExpr fieldExpr,
    ast.AST parsedExpression,
    o.Expression context,
    List<o.Statement> actions,
    CompileMethod method,
    {o.OutputType fieldType}) {
  var checkExpression = convertCdExpressionToIr(
      view,
      context,
      parsedExpression,
      DetectChangesVars.valUnwrapper,
      view.component.template.preserveWhitespace);
  if (checkExpression.expression == null) {
    // e.g. an empty expression was given
    return;
  }
  // Add class field to store previous value.
  bool isPrimitive = _isPrimitiveFieldType(fieldType);
  view.fields.add(new o.ClassField(fieldExpr.name,
      outputType: isPrimitive ? fieldType : null,
      modifiers: const [o.StmtModifier.Private]));
  if (checkExpression.needsValueUnwrapper) {
    var initValueUnwrapperStmt =
        DetectChangesVars.valUnwrapper.callMethod('reset', []).toStmt();
    method.addStmt(initValueUnwrapperStmt);
  }
  // Generate: final currVal_0 = ctx.expression.
  method.addStmt(currValExpr
      .set(checkExpression.expression)
      .toDeclStmt(null, [o.StmtModifier.Final]));

  // If we have only setter action, we can simply call updater and assign
  // newValue to previous value.
  if (checkExpression.needsValueUnwrapper == false && actions.length == 1) {
    method.addStmt(actions.first);
    method.addStmt(
        new o.WriteClassMemberExpr(fieldExpr.name, currValExpr).toStmt());
  } else {
    // Otherwise use traditional checkBinding call.
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
}

o.Statement logBindingUpdateStmt(
    o.Expression renderNode, String propName, o.Expression value) {
  return new o.InvokeMemberMethodExpr('setBindingDebugInfo', [
    renderNode,
    o.literal('ng-reflect-${propName}'),
    value.isBlank().conditional(o.NULL_EXPR, value.callMethod('toString', []))
  ]).toStmt();
}

bool _isPrimitiveFieldType(o.OutputType type) {
  if (type == o.BOOL_TYPE ||
      type == o.INT_TYPE ||
      type == o.DOUBLE_TYPE ||
      type == o.NUMBER_TYPE ||
      type == o.STRING_TYPE) return true;
  if (type is o.ExternalType) {
    String name = type.value.name;
    return isPrimitiveTypeName(name.trim());
  }
  return false;
}

bool isPrimitiveTypeName(String typeName) {
  switch (typeName) {
    case 'bool':
    case 'int':
    case 'num':
    case 'bool':
    case 'String':
      return true;
  }
  return false;
}
