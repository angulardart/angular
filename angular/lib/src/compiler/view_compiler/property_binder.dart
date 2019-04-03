import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/identifiers.dart' show Identifiers;
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/template_ast.dart'
    show
        BoundElementPropertyAst,
        BoundExpression,
        BoundI18nMessage,
        BoundValue,
        DirectiveAst,
        PropertyBindingType;
import 'package:angular/src/core/change_detection/constants.dart'
    show ChangeDetectionStrategy;
import 'package:angular/src/core/linker/view_type.dart';
import 'package:angular/src/core/metadata/lifecycle_hooks.dart'
    show LifecycleHooks;

import 'bound_value_converter.dart';
import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_method.dart' show CompileMethod;
import 'compile_view.dart' show CompileView, NodeReference;
import 'constants.dart' show DetectChangesVars;
import 'ir/view_storage.dart';
import 'update_statement_visitor.dart' show bindingToUpdateStatement;
import 'view_compiler_utils.dart' show unwrapDirective, unwrapDirectiveInstance;
import 'view_name_resolver.dart';

o.ReadClassMemberExpr _createBindFieldExpr(num exprIndex) =>
    o.ReadClassMemberExpr('_expr_$exprIndex');

o.ReadVarExpr _createCurrValueExpr(num exprIndex) =>
    o.variable('currVal_$exprIndex');

/// Generates code to bind template expression.
///
/// If [checkExpression] is immutable, code is added to [literalMethod] to be
/// executed once when the component is created. Otherwise statements are added
/// to [method] to be executed on each change detection cycle.
void _bind(
  ViewStorage storage,
  o.ReadVarExpr currValExpr,
  o.ReadClassMemberExpr fieldExpr,
  o.Expression checkExpression,
  bool isImmutable,
  bool isNullable,
  List<o.Statement> actions,
  CompileMethod method,
  CompileMethod literalMethod, {
  o.OutputType fieldType,
  bool isHostComponent = false,
  o.Expression fieldExprInitializer,
}) {
  if (isImmutable) {
    // If the expression is immutable, it will never change, so we can run it
    // once on the first change detection.
    if (!isHostComponent) {
      _bindLiteral(checkExpression, actions, currValExpr.name, fieldExpr.name,
          literalMethod, isNullable);
    }
    return;
  }
  if (checkExpression == null) {
    // e.g. an empty expression was given
    return;
  }
  bool isPrimitive = _isPrimitiveFieldType(fieldType);
  ViewStorageItem previousValueField = storage.allocate(fieldExpr.name,
      modifiers: const [o.StmtModifier.Private],
      initializer: fieldExprInitializer,
      outputType: isPrimitive ? fieldType : null);
  method.addStmt(currValExpr
      .set(checkExpression)
      .toDeclStmt(null, [o.StmtModifier.Final]));
  method.addStmt(o.IfStmt(
      o.importExpr(Identifiers.checkBinding).callFn([fieldExpr, currValExpr]),
      List.from(actions)
        ..addAll([
          storage.buildWriteExpr(previousValueField, currValExpr).toStmt()
        ])));
}

/// The same as [_bind], but we know that [checkExpression] is a literal.
///
/// This means we don't need to create a change detection field or check if it
/// has changed. We know for sure that there will only be one transition from
/// [null] to whatever the value of [checkExpression] is. So we can just output
/// the [actions] and run them once on the first change detection run.
void _bindLiteral(
    o.Expression checkExpression,
    List<o.Statement> actions,
    String currValName,
    String fieldName,
    CompileMethod method,
    bool isNullable) {
  if (checkExpression == o.NULL_EXPR ||
      (checkExpression is o.LiteralExpr && checkExpression.value == null)) {
    // In this case, there is no transition, since change detection variables
    // are initialized to null.
    return;
  }

  var mappedActions = actions
      // Replace all 'currVal_X' with the actual expression
      .map(
          (stmt) => o.replaceVarInStatement(currValName, checkExpression, stmt))
      // Replace all 'expr_X' with 'null'
      .map((stmt) => o.replaceVarInStatement(fieldName, o.NULL_EXPR, stmt));
  if (isNullable) {
    method.addStmt(o.IfStmt(
        checkExpression.notIdentical(o.NULL_EXPR), mappedActions.toList()));
  } else {
    method.addStmts(mappedActions.toList());
  }
}

void bindRenderText(
    ir.Binding binding, CompileNode compileNode, CompileView view) {
  if (binding.source.isImmutable) {
    // We already set the value to the text node at creation
    return;
  }

  var checkExpression =
      BoundValueConverter.forView(view, DetectChangesVars.cachedCtx)
          .convertSourceToExpression(binding.source, null);
  var updateStmt = bindingToUpdateStatement(
      binding, o.THIS_EXPR, compileNode.renderNode, false, checkExpression);
  view.detectChangesRenderPropertiesMethod.addStmt(updateStmt);
}

/// For each bound property, creates code to update the binding.
///
/// Example:
///     final currVal_1 = this.context.someBoolValue;
///     if (import6.checkBinding(this._expr_1,currVal_1)) {
///       this.renderer.setElementClass(this._el_4,'disabled',currVal_1);
///       this._expr_1 = currVal_1;
///     }
void bindAndWriteToRenderer(
  List<BoundElementPropertyAst> boundProps,
  BoundValueConverter converter,
  o.Expression appViewInstance,
  NodeReference renderNode,
  bool isHtmlElement,
  ViewNameResolver nameResolver,
  ViewStorage storage,
  CompileMethod targetMethod, {
  bool isHostComponent = false,
}) {
  final dynamicPropertiesMethod = CompileMethod();
  final constantPropertiesMethod = CompileMethod();
  for (var boundProp in boundProps) {
    var binding = _convertToIr(boundProp, converter.analyzedClass);
    // Add to view bindings collection.
    int bindingIndex = nameResolver.createUniqueBindIndex();

    // Expression that points to _expr_## stored value.
    var fieldExpr = _createBindFieldExpr(bindingIndex);

    // Expression for current value of expression when value is re-read.
    var currValExpr = _createCurrValueExpr(bindingIndex);

    var updateStmts = <o.Statement>[
      bindingToUpdateStatement(
        binding,
        appViewInstance,
        renderNode,
        isHtmlElement,
        currValExpr,
      )
    ];

    final fieldType = _fieldType(binding.target);
    final checkExpression =
        converter.convertSourceToExpression(binding.source, fieldType);
    _bind(
      storage,
      currValExpr,
      fieldExpr,
      checkExpression,
      binding.source.isImmutable,
      binding.source.isNullable,
      updateStmts,
      dynamicPropertiesMethod,
      constantPropertiesMethod,
      fieldType: fieldType,
      isHostComponent: isHostComponent,
    );
  }
  if (constantPropertiesMethod.isNotEmpty) {
    targetMethod.addStmtsIfFirstCheck(constantPropertiesMethod.finish());
  }
  if (dynamicPropertiesMethod.isNotEmpty) {
    targetMethod.addStmts(dynamicPropertiesMethod.finish());
  }
}

ir.Binding _convertToIr(
        BoundElementPropertyAst boundProp, AnalyzedClass analyzedClass) =>
    ir.Binding(
        source: _boundValueToIr(boundProp, analyzedClass),
        target: _propertyToIr(boundProp));

ir.BindingTarget _propertyToIr(BoundElementPropertyAst boundProp) {
  switch (boundProp.type) {
    case PropertyBindingType.property:
      if (boundProp.name == 'className') {
        return ir.ClassBinding();
      }
      return ir.PropertyBinding(boundProp.name, boundProp.securityContext);
    case PropertyBindingType.attribute:
      if (boundProp.name == 'class') {
        return ir.ClassBinding();
      }
      return ir.AttributeBinding(boundProp.name,
          namespace: boundProp.namespace,
          isConditional: _isConditionalAttribute(boundProp),
          securityContext: boundProp.securityContext);
    case PropertyBindingType.cssClass:
      return ir.ClassBinding(name: boundProp.name);
    case PropertyBindingType.style:
      return ir.StyleBinding(boundProp.name, boundProp.unit);
  }
  return null;
}

ir.BindingSource _boundValueToIr(
    BoundElementPropertyAst boundProp, AnalyzedClass analyzedClass) {
  final value = boundProp.value;
  if (value is BoundExpression) {
    return ir.BoundExpression(
        value.expression, boundProp.sourceSpan, analyzedClass);
  } else if (value is BoundI18nMessage) {
    return ir.BoundI18nMessage(value.message);
  }
  throw ArgumentError.value(value, 'value', 'Unknown $BoundValue type.');
}

bool _isConditionalAttribute(BoundElementPropertyAst boundProp) =>
    boundProp.unit == 'if';

o.OutputType _fieldType(ir.BindingTarget target) {
  if (target is ir.ClassBinding) {
    return target.name == null ? o.STRING_TYPE : o.BOOL_TYPE;
  }
  return null;
}

void bindRenderInputs(
    List<BoundElementPropertyAst> boundProps, CompileElement compileElement) {
  var appViewInstance = compileElement.component == null
      ? o.THIS_EXPR
      : compileElement.componentView;
  var renderNode = compileElement.renderNode;
  var view = compileElement.view;
  var implicitReceiver = DetectChangesVars.cachedCtx;
  var converter = BoundValueConverter.forView(view, implicitReceiver);
  bindAndWriteToRenderer(
    boundProps,
    converter,
    appViewInstance,
    renderNode,
    compileElement.isHtmlElement,
    view.nameResolver,
    view.storage,
    view.detectChangesRenderPropertiesMethod,
  );
}

// Component or directive level host properties are change detected inside
// the component itself inside detectHostChanges method, no need to
// generate code at call-site.
void bindDirectiveHostProps(DirectiveAst directiveAst,
    o.Expression directiveInstance, CompileElement compileElement) {
  if (directiveAst.hostProperties.isEmpty) return;
  var directive = directiveAst.directive;
  bool isComponent = directive.isComponent;
  var isStatefulDirective = !directive.isComponent &&
      directive.changeDetection == ChangeDetectionStrategy.Stateful;

  var target = isComponent
      ? compileElement.componentView
      : unwrapDirective(directiveInstance);
  o.Expression callDetectHostPropertiesExpr;
  if (isComponent) {
    callDetectHostPropertiesExpr =
        target.callMethod('detectHostChanges', [DetectChangesVars.firstCheck]);
  } else {
    if (isStatefulDirective) return;
    if (unwrapDirectiveInstance(directiveInstance) == null) return;
    callDetectHostPropertiesExpr = target.callMethod('detectHostChanges', [
      compileElement.component != null
          ? compileElement.componentView
          : o.THIS_EXPR,
      compileElement.renderNode.toReadExpr()
    ]);
  }
  compileElement.view.detectChangesRenderPropertiesMethod
      .addStmt(callDetectHostPropertiesExpr.toStmt());
}

void bindDirectiveInputs(DirectiveAst directiveAst,
    o.Expression directiveInstance, CompileElement compileElement,
    {bool isHostComponent = false}) {
  var directive = directiveAst.directive;
  if (directive.inputs.isEmpty) {
    return;
  }

  var view = compileElement.view;
  var converter =
      BoundValueConverter.forView(view, DetectChangesVars.cachedCtx);
  var detectChangesInInputsMethod = view.detectChangesInInputsMethod;
  var dynamicInputsMethod = CompileMethod();
  var constantInputsMethod = CompileMethod();
  var lifecycleHooks = directive.lifecycleHooks;
  bool calcChangesMap = lifecycleHooks.contains(LifecycleHooks.onChanges);
  bool calcChangedState = lifecycleHooks.contains(LifecycleHooks.afterChanges);
  var isOnPushComp = directive.isComponent &&
      directive.changeDetection == ChangeDetectionStrategy.OnPush;
  var isStateful =
      directive.changeDetection == ChangeDetectionStrategy.Stateful;

  if (calcChangesMap) {
    // We need to reinitialize changes, otherwise a second change
    // detection cycle would cause extra ngOnChanges call.
    view.requiresOnChangesCall = true;
    detectChangesInInputsMethod
        .addStmt(DetectChangesVars.changes.set(o.NULL_EXPR).toStmt());
  }
  if (calcChangedState) {
    view.requiresAfterChangesCall = true;
  }

  // We want to call AfterChanges lifecycle only if we detect a change,
  // unlike OnChanges, we don't need to collect a map of SimpleChange(s)
  // therefore we keep track of changes using bool changed variable.
  // At the beginning of change detecting inputs we reset this flag to false,
  // and then set it to true if any of it's inputs change.
  if ((isOnPushComp || calcChangedState) && view.viewType != ViewType.host) {
    detectChangesInInputsMethod
        .addStmt(DetectChangesVars.changed.set(o.literal(false)).toStmt());
  }
  // directiveAst contains the target directive we are updating.
  // input is a BoundPropertyAst that contains binding metadata.
  for (var input in directiveAst.inputs) {
    var bindingIndex = view.nameResolver.createUniqueBindIndex();
    var fieldExpr = _createBindFieldExpr(bindingIndex);
    var currValExpr = _createCurrValueExpr(bindingIndex);
    var statements = <o.Statement>[];

    // Optimization specifically for NgIf. Since the directive already performs
    // change detection we can directly update it's input.
    // TODO: generalize to SingleInputDirective mixin.
    if (directive.identifier.name == 'NgIf' && input.directiveName == 'ngIf') {
      var checkExpression = converter.convertToExpression(
          input.value, input.sourceSpan, o.BOOL_TYPE);
      dynamicInputsMethod.addStmt(directiveInstance
          .prop(input.directiveName)
          .set(checkExpression)
          .toStmt());
      continue;
    }
    if (isStateful) {
      var fieldType = o.importType(directive.inputTypes[input.directiveName]);
      var checkExpression = converter.convertToExpression(
          input.value, input.sourceSpan, fieldType);
      if (converter.isImmutable(input.value)) {
        constantInputsMethod.addStmt(directiveInstance
            .prop(input.directiveName)
            .set(checkExpression)
            .toStmt());
      } else {
        dynamicInputsMethod.addStmt(directiveInstance
            .prop(input.directiveName)
            .set(checkExpression)
            .toStmt());
      }
      continue;
    } else {
      // Set property on directiveInstance to new value.
      statements.add(directiveInstance
          .prop(input.directiveName)
          .set(currValExpr)
          .toStmt());
    }
    if (calcChangesMap) {
      statements.add(o.WriteIfNullExpr(
              DetectChangesVars.changes.name,
              o.literalMap(
                  [], o.MapType(o.importType(Identifiers.SimpleChange))))
          .toStmt());
      statements.add(DetectChangesVars.changes
          .key(o.literal(input.directiveName))
          .set(o
              .importExpr(Identifiers.SimpleChange)
              .instantiate([fieldExpr, currValExpr]))
          .toStmt());
    }
    if (isOnPushComp || calcChangedState) {
      statements.add(DetectChangesVars.changed.set(o.literal(true)).toStmt());
    }
    // Execute actions and assign result to fieldExpr which hold previous value.
    CompileTypeMetadata inputTypeMeta = directive.inputTypes != null
        ? directive.inputTypes[input.directiveName]
        : null;
    var inputType = inputTypeMeta != null
        ? o.importType(inputTypeMeta, inputTypeMeta.typeArguments)
        : null;
    var expression =
        converter.convertToExpression(input.value, input.sourceSpan, inputType);

    _bind(
      view.storage,
      currValExpr,
      fieldExpr,
      expression,
      converter.isImmutable(input.value),
      converter.isNullable(input.value),
      statements,
      dynamicInputsMethod,
      constantInputsMethod,
      fieldType: inputType,
      isHostComponent: isHostComponent,
    );
  }
  if (constantInputsMethod.isNotEmpty) {
    detectChangesInInputsMethod.addStmtsIfFirstCheck(
      constantInputsMethod.finish(),
    );
  }
  if (dynamicInputsMethod.isNotEmpty) {
    detectChangesInInputsMethod.addStmts(dynamicInputsMethod.finish());
  }
  if (isOnPushComp) {
    detectChangesInInputsMethod.addStmt(o.IfStmt(DetectChangesVars.changed, [
      compileElement.componentView.callMethod('markAsCheckOnce', []).toStmt()
    ]));
  }
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
    case 'double':
    case 'String':
      return true;
  }
  return false;
}
