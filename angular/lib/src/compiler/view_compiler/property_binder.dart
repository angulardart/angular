import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/core/change_detection/constants.dart'
    show isDefaultChangeDetectionStrategy, ChangeDetectionStrategy;
import 'package:angular/src/core/linker/app_view_utils.dart'
    show NAMESPACE_URIS;
import "package:angular/src/core/linker/view_type.dart";
import 'package:angular/src/core/metadata/lifecycle_hooks.dart'
    show LifecycleHooks;
import "package:angular/src/core/metadata/view.dart" show ViewEncapsulation;
import 'package:angular/src/core/security.dart';
import 'package:angular/src/transform/common/names.dart'
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
import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_method.dart' show CompileMethod;
import 'compile_view.dart' show CompileView;
import 'constants.dart' show DetectChangesVars;
import 'expression_converter.dart'
    show ExpressionWithWrappedValueInfo, convertCdExpressionToIr;
import 'view_builder.dart' show buildUpdaterFunctionName;
import 'view_compiler_utils.dart' show createSetAttributeParams;

o.ReadClassMemberExpr createBindFieldExpr(num exprIndex) =>
    new o.ReadClassMemberExpr('_expr_$exprIndex');

o.ReadVarExpr createCurrValueExpr(num exprIndex) =>
    o.variable('currVal_$exprIndex');

/// Generates code to bind template expression.
///
/// Called from:
///   bindRenderInputs, bindDirectiveHostProps
///       bindAndWriteToRenderer
///   Element/EmbeddedTemplate visitor
///       bindDirectiveInputs
///   ViewBinderVisitor
///       bindRenderText
///
/// If expression result is a literal/const/final code
/// is added to literalMethod as output to be executed only
/// once when component is created.
/// Otherwise statements are added to method to be executed on
/// each change detection cycle.
void bind(
    CompileView view,
    o.ReadVarExpr currValExpr,
    o.ReadClassMemberExpr fieldExpr,
    ast.AST parsedExpression,
    o.Expression context,
    List<o.Statement> actions,
    CompileMethod method,
    CompileMethod literalMethod,
    {o.OutputType fieldType}) {
  var checkExpression = convertCdExpressionToIr(
      view,
      context,
      parsedExpression,
      DetectChangesVars.valUnwrapper,
      view.component.template.preserveWhitespace);
  if (context is o.ReadVarExpr &&
      context.name == '_ctx' &&
      checkExpression.anyExplicit) {
    view.cacheCtxInDetectChangesMethod = true;
  }
  if (isImmutable(
      checkExpression.expression, context, view.component.analyzedClass)) {
    // If the expression is a literal, it will never change, so we can run it
    // once on the first change detection.
    _bindLiteral(checkExpression, literalMethod, actions, currValExpr.name,
        fieldExpr.name);
    return;
  }
  if (checkExpression.expression == null) {
    // e.g. an empty expression was given
    return;
  }
  bool isPrimitive = _isPrimitiveFieldType(fieldType);
  view.fields.add(new o.ClassField(fieldExpr.name,
      modifiers: const [o.StmtModifier.Private],
      outputType: isPrimitive ? fieldType : null));
  if (checkExpression.needsValueUnwrapper) {
    var initValueUnwrapperStmt =
        DetectChangesVars.valUnwrapper.callMethod('reset', []).toStmt();
    method.addStmt(initValueUnwrapperStmt);
  }
  method.addStmt(currValExpr
      .set(checkExpression.expression)
      .toDeclStmt(null, [o.StmtModifier.Final]));
  o.Expression condition;
  if (view.genConfig.genDebugInfo) {
    condition =
        o.importExpr(Identifiers.checkBinding).callFn([fieldExpr, currValExpr]);
  } else {
    condition = new o.NotExpr(o
        .importExpr(Identifiers.looseIdentical)
        .callFn([fieldExpr, currValExpr]));
  }
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

/// The same as [bind], but we know that [checkExpression] is a literal.
///
/// This means we don't need to create a change detection field or check if it
/// has changed. We know for sure that there will only be one transition from
/// [null] to whatever the value of [checkExpression] is. So we can just output
/// the [actions] and run them once on the first change detection run.
void _bindLiteral(
    ExpressionWithWrappedValueInfo checkExpression,
    CompileMethod method,
    List<o.Statement> actions,
    String currValName,
    String fieldName) {
  if (checkExpression.expression == o.NULL_EXPR) {
    // In this case, there is no transition, since change detection variables
    // are initialized to null.
    return;
  }

  var mappedActions = actions
      // Replace all 'currVal_X' with the actual expression
      .map((stmt) => o.replaceVarInStatement(
          currValName, checkExpression.expression, stmt))
      // Replace all 'expr_X' with 'null'
      .map((stmt) => o.replaceVarInStatement(fieldName, o.NULL_EXPR, stmt));
  // TODO(het): Don't check for null if it's unnecessary:
  //   - if the expression is a literal
  //   - if the expression is a method tear-off
  //   - if the expression has a known, non-null value
  method.addStmt(new o.IfStmt(
      checkExpression.expression.notIdentical(o.NULL_EXPR),
      mappedActions.toList()));
}

void bindRenderText(
    BoundTextAst boundText, CompileNode compileNode, CompileView view) {
  int bindingIndex = view.addBinding(compileNode, boundText);
  // Expression for current value of expression when value is re-read.
  var currValExpr = createCurrValueExpr(bindingIndex);
  // Expression that points to _expr_## stored value.
  var valueField = createBindFieldExpr(bindingIndex);
  var dynamicRenderMethod = new CompileMethod(view);
  dynamicRenderMethod.resetDebugInfo(compileNode.nodeIndex, boundText);
  var constantRenderMethod = new CompileMethod(view);
  bind(
      view,
      currValExpr,
      valueField,
      boundText.value,
      o.variable('_ctx'),
      [compileNode.renderNode.prop('text').set(currValExpr).toStmt()],
      dynamicRenderMethod,
      constantRenderMethod);
  if (!constantRenderMethod.isEmpty) {
    view.detectChangesRenderPropertiesMethod.addStmt(new o.IfStmt(
        DetectChangesVars.firstCheck, constantRenderMethod.finish()));
  }
  if (!dynamicRenderMethod.isEmpty) {
    view.detectChangesRenderPropertiesMethod
        .addStmts(dynamicRenderMethod.finish());
  }
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
void bindAndWriteToRenderer(
    List<BoundElementPropertyAst> boundProps,
    o.Expression context,
    CompileView compileView,
    CompileElement compileElement,
    CompileMethod targetMethod,
    {bool updatingHost: false}) {
  var view = compileView;
  var renderNode = compileElement.renderNode;
  var dynamicPropertiesMethod = new CompileMethod(view);
  var constantPropertiesMethod = new CompileMethod(view);
  boundProps.forEach((boundProp) {
    // Add to view bindings collection.
    int bindingIndex = view.addBinding(compileElement, boundProp);

    // Generate call to this.debug(index, column, row);
    dynamicPropertiesMethod.resetDebugInfo(compileElement.nodeIndex, boundProp);

    // Expression that points to _expr_## stored value.
    var fieldExpr = createBindFieldExpr(bindingIndex);

    // Expression for current value of expression when value is re-read.
    var currValExpr = createCurrValueExpr(bindingIndex);

    String renderMethod;
    o.OutputType fieldType;
    // Wraps current value with sanitization call if necessary.
    o.Expression renderValue = sanitizedValue(boundProp, currValExpr);

    var updateStmts = <o.Statement>[];
    switch (boundProp.type) {
      case PropertyBindingType.Property:
        renderMethod = 'setElementProperty';
        // If user asked for logging bindings, generate code to log them.
        if (boundProp.name == 'className') {
          // Handle className special case for class="binding".
          updateStmts.addAll(_createSetClassNameStmt(
              compileElement, renderValue,
              updatingHost: updatingHost));
          fieldType = o.STRING_TYPE;
        } else {
          updateStmts.add(new o.InvokeMemberMethodExpr('setProp',
              [renderNode, o.literal(boundProp.name), renderValue]).toStmt());
        }
        break;
      case PropertyBindingType.Attribute:
        var attrNs;
        String attrName = boundProp.name;
        if (attrName.startsWith('@') && attrName.contains(':')) {
          var nameParts = attrName.substring(1).split(':');
          attrNs = NAMESPACE_URIS[nameParts[0]];
          attrName = nameParts[1];
        }

        if (attrName == 'class') {
          // Handle [attr.class].
          updateStmts.addAll(_createSetClassNameStmt(
              compileElement, renderValue,
              updatingHost: updatingHost));
        } else {
          // For attributes other than class convert value to a string.
          // TODO: Once we have analyzer summaries and know the type is already
          // String short-circuit.
          renderValue =
              renderValue.callMethod('toString', const [], checked: true);

          var params = createSetAttributeParams(
              compileElement.renderNodeFieldName,
              attrNs,
              attrName,
              renderValue);

          updateStmts.add(new o.InvokeMemberMethodExpr(
                  attrNs == null ? 'setAttr' : 'setAttrNS', params)
              .toStmt());
        }
        break;
      case PropertyBindingType.Class:
        fieldType = o.BOOL_TYPE;
        renderMethod =
            compileElement.isHtmlElement ? 'updateClass' : 'updateElemClass';
        updateStmts.add(new o.InvokeMemberMethodExpr(renderMethod,
            [renderNode, o.literal(boundProp.name), renderValue]).toStmt());
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
        o.Expression updateStyleExpr = renderNode.prop('style').callMethod(
            'setProperty', [o.literal(boundProp.name), styleValueExpr]);
        updateStmts.add(updateStyleExpr.toStmt());
        break;
    }

    bind(view, currValExpr, fieldExpr, boundProp.value, context, updateStmts,
        dynamicPropertiesMethod, constantPropertiesMethod,
        fieldType: fieldType);
  });
  if (!constantPropertiesMethod.isEmpty) {
    targetMethod.addStmt(new o.IfStmt(
        DetectChangesVars.firstCheck, constantPropertiesMethod.finish()));
  }
  if (!dynamicPropertiesMethod.isEmpty) {
    targetMethod.addStmts(dynamicPropertiesMethod.finish());
  }
}

List<o.Statement> _createSetClassNameStmt(
    CompileElement compileElement, o.Expression renderValue,
    {bool updatingHost: false}) {
  var updateStmts = <o.Statement>[];
  var renderNode = compileElement.renderNode;
  // TODO: upgrade to codebuilder / build string interpolation to
  // move into single expression.
  updateStmts.add(renderNode.prop('className').set(renderValue).toStmt());
  var view = compileElement.view;
  bool isHostRootView =
      compileElement.nodeIndex == 0 && view.viewType == ViewType.HOST;
  // _ngcontent- class should be applied to every element other than host's
  // main node.
  if (!isHostRootView &&
      view != null &&
      view.component.template.encapsulation == ViewEncapsulation.Emulated) {
    updateStmts
        .add((new o.InvokeMemberMethodExpr('addShimC', [renderNode])).toStmt());
  }
  // Since we are overriding component className above with bound value we need
  // to add host class.
  if (compileElement.component != null) {
    updateStmts.add(
        (compileElement.componentView.callMethod('addShimH', [renderNode]))
            .toStmt());
  } else if (updatingHost) {
    updateStmts
        .add(new o.InvokeMemberMethodExpr('addShimH', [renderNode]).toStmt());
  }
  return updateStmts;
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
  bindAndWriteToRenderer(boundProps, o.variable('_ctx'), compileElement.view,
      compileElement, compileElement.view.detectChangesRenderPropertiesMethod);
}

void bindDirectiveHostProps(DirectiveAst directiveAst,
    o.Expression directiveInstance, CompileElement compileElement) {
  if (directiveAst.directive.isComponent) {
    // Component level host properties are change detected inside the component
    // itself inside detectHostChanges method, no need to generate code
    // at call-site.
    if (directiveAst.hostProperties.isNotEmpty) {
      var callDetectHostPropertiesExpr = compileElement.compViewExpr
          .callMethod('detectHostChanges', [DetectChangesVars.firstCheck]);
      compileElement.view.detectChangesRenderPropertiesMethod
          .addStmt(callDetectHostPropertiesExpr.toStmt());
    }
    return;
  }
  bindAndWriteToRenderer(
      directiveAst.hostProperties,
      directiveInstance,
      compileElement.view,
      compileElement,
      compileElement.view.detectChangesRenderPropertiesMethod);
}

void bindDirectiveInputs(DirectiveAst directiveAst,
    o.Expression directiveInstance, CompileElement compileElement) {
  if (identical(directiveAst.inputs.length, 0)) {
    return;
  }
  var view = compileElement.view;
  var detectChangesInInputsMethod = view.detectChangesInInputsMethod;
  var dynamicInputsMethod = new CompileMethod(view);
  var constantInputsMethod = new CompileMethod(view);
  dynamicInputsMethod.resetDebugInfo(
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
    var bindingIndex = view.addBinding(compileElement, input);
    dynamicInputsMethod.resetDebugInfo(compileElement.nodeIndex, input);
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
          o.variable('_ctx'),
          input.value,
          DetectChangesVars.valUnwrapper,
          view.component.template.preserveWhitespace);
      if (checkExpression.anyExplicit) {
        view.cacheCtxInDetectChangesMethod = true;
      }
      dynamicInputsMethod.addStmt(directiveInstance
          .prop(input.directiveName)
          .set(checkExpression.expression)
          .toStmt());
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
    // Execute actions and assign result to fieldExpr which hold previous value.
    String inputTypeName = directiveAst.directive.inputTypes != null
        ? directiveAst.directive.inputTypes[input.directiveName]
        : null;
    var inputType = inputTypeName != null
        ? o.importType(new CompileIdentifierMetadata(name: inputTypeName))
        : null;
    if (isStatefulComp) {
      bindToUpdateMethod(view, currValExpr, fieldExpr, input.value,
          o.variable('_ctx'), statements, dynamicInputsMethod,
          fieldType: inputType);
    } else {
      bind(view, currValExpr, fieldExpr, input.value, o.variable('_ctx'),
          statements, dynamicInputsMethod, constantInputsMethod,
          fieldType: inputType);
    }
  }
  if (!constantInputsMethod.isEmpty) {
    detectChangesInInputsMethod.addStmt(new o.IfStmt(
        DetectChangesVars.firstCheck, constantInputsMethod.finish()));
  }
  if (!dynamicInputsMethod.isEmpty) {
    detectChangesInInputsMethod.addStmts(dynamicInputsMethod.finish());
  }
  if (!isStatefulComp && isOnPushComp) {
    detectChangesInInputsMethod.addStmt(new o.IfStmt(
        DetectChangesVars.changed, [
      compileElement.compViewExpr.callMethod('markAsCheckOnce', []).toStmt()
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
  if (context is o.ReadVarExpr &&
      context.name == '_ctx' &&
      checkExpression.anyExplicit) {
    view.cacheCtxInDetectChangesMethod = true;
  }
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
    o.Expression condition;
    if (view.genConfig.genDebugInfo) {
      condition = o
          .importExpr(Identifiers.checkBinding)
          .callFn([fieldExpr, currValExpr]);
    } else {
      condition = new o.NotExpr(o
          .importExpr(Identifiers.looseIdentical)
          .callFn([fieldExpr, currValExpr]));
    }

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
    o.literal('ng-reflect-$propName'),
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
