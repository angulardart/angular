import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/core/change_detection/constants.dart'
    show isDefaultChangeDetectionStrategy, ChangeDetectionStrategy;
import 'package:angular/src/core/linker/view_type.dart';
import 'package:angular/src/core/metadata/lifecycle_hooks.dart'
    show LifecycleHooks;
import 'package:angular/src/core/security.dart';
import 'package:angular_compiler/cli.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import '../compile_metadata.dart';
import '../expression_parser/ast.dart' as ast;
import '../identifiers.dart' show Identifiers;
import '../output/output_ast.dart' as o;
import '../template_ast.dart'
    show
        BoundDirectivePropertyAst,
        BoundElementPropertyAst,
        BoundExpression,
        BoundTextAst,
        DirectiveAst,
        PropertyBindingType;
import 'bound_value_converter.dart';
import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_method.dart' show CompileMethod;
import 'compile_view.dart' show CompileView;
import 'constants.dart' show DetectChangesVars;
import 'expression_converter.dart' show convertCdExpressionToIr;
import 'ir/view_storage.dart';
import 'view_compiler_utils.dart'
    show
        createFlatArray,
        createSetAttributeParams,
        namespaceUris,
        unwrapDirective,
        unwrapDirectiveInstance;
import 'view_name_resolver.dart';

o.ReadClassMemberExpr _createBindFieldExpr(num exprIndex) =>
    o.ReadClassMemberExpr('_expr_$exprIndex');

o.ReadVarExpr _createCurrValueExpr(num exprIndex) =>
    o.variable('currVal_$exprIndex');

/// A wrapper that converts [parsedExpression] and forwards to [_bind].
///
/// Historically [_bind] accepted a parsed AST; however, this detail was
/// abstracted away so that [_bind] could be invoked on synthesized expressions
/// with no parsed AST. This method acts an adapter between the old interface
/// and the new.
void _bindAst(
  CompileDirectiveMetadata viewDirective,
  ViewNameResolver nameResolver,
  ViewStorage storage,
  o.ReadVarExpr currValExpr,
  o.ReadClassMemberExpr fieldExpr,
  ast.AST parsedExpression,
  SourceSpan parsedExpressionSourceSpan,
  List<o.Statement> actions,
  CompileMethod method,
  CompileMethod literalMethod, {
  o.OutputType fieldType,
  o.Expression fieldExprInitializer,
}) {
  parsedExpression =
      rewriteInterpolate(parsedExpression, viewDirective.analyzedClass);
  var checkExpression = convertCdExpressionToIr(
      nameResolver,
      DetectChangesVars.cachedCtx,
      parsedExpression,
      parsedExpressionSourceSpan,
      viewDirective,
      fieldType);
  _bind(
    storage,
    currValExpr,
    fieldExpr,
    checkExpression,
    isImmutable(parsedExpression, viewDirective.analyzedClass),
    canBeNull(parsedExpression),
    actions,
    method,
    literalMethod,
    fieldType: fieldType,
    isHostComponent: false,
    fieldExprInitializer: fieldExprInitializer,
  );
}

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
    BoundTextAst boundText, CompileNode compileNode, CompileView view) {
  if (isImmutable(boundText.value, view.component.analyzedClass)) {
    // We already set the value to the text node at creation
    return;
  }
  int bindingIndex = view.nameResolver.createUniqueBindIndex();
  // Expression for current value of expression when value is re-read.
  var currValExpr = _createCurrValueExpr(bindingIndex);
  // Expression that points to _expr_## stored value.
  var valueField = _createBindFieldExpr(bindingIndex);
  var dynamicRenderMethod = CompileMethod();
  var constantRenderMethod = CompileMethod();
  _bindAst(
    view.component,
    view.nameResolver,
    view.storage,
    currValExpr,
    valueField,
    boundText.value,
    boundText.sourceSpan,
    [
      compileNode.renderNode.toReadExpr().prop('text').set(currValExpr).toStmt()
    ],
    dynamicRenderMethod,
    constantRenderMethod,
  );
  if (constantRenderMethod.isNotEmpty) {
    view.detectChangesRenderPropertiesMethod.addStmtsIfFirstCheck(
      constantRenderMethod.finish(),
    );
  }
  if (dynamicRenderMethod.isNotEmpty) {
    view.detectChangesRenderPropertiesMethod
        .addStmts(dynamicRenderMethod.finish());
  }
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
  o.Expression renderNode,
  bool isHtmlElement,
  ViewNameResolver nameResolver,
  ViewStorage storage,
  CompileMethod targetMethod, {
  bool isHostComponent = false,
}) {
  final dynamicPropertiesMethod = CompileMethod();
  final constantPropertiesMethod = CompileMethod();
  for (var boundProp in boundProps) {
    // Add to view bindings collection.
    int bindingIndex = nameResolver.createUniqueBindIndex();

    // Expression that points to _expr_## stored value.
    var fieldExpr = _createBindFieldExpr(bindingIndex);

    // Expression for current value of expression when value is re-read.
    var currValExpr = _createCurrValueExpr(bindingIndex);

    String renderMethod;
    o.OutputType fieldType;
    // Wraps current value with sanitization call if necessary.
    o.Expression renderValue = _sanitizedValue(boundProp, currValExpr);

    var updateStmts = <o.Statement>[];
    switch (boundProp.type) {
      case PropertyBindingType.property:
        renderMethod = 'setElementProperty';
        // If user asked for logging bindings, generate code to log them.
        if (boundProp.name == 'className') {
          // Handle className special case for class="binding".
          var updateClassExpr = appViewInstance
              .callMethod('updateChildClass', [renderNode, renderValue]);
          updateStmts.add(updateClassExpr.toStmt());
          fieldType = o.STRING_TYPE;
        } else {
          updateStmts.add(o.InvokeMemberMethodExpr('setProp',
              [renderNode, o.literal(boundProp.name), renderValue]).toStmt());
        }
        break;
      case PropertyBindingType.attribute:
        String attrNs;
        String attrName = boundProp.name;
        if (attrName.startsWith('@') && attrName.contains(':')) {
          var nameParts = attrName.substring(1).split(':');
          attrNs = namespaceUris[nameParts[0]];
          attrName = nameParts[1];
        }

        if (attrName == 'class') {
          // Handle [attr.class].
          var updateClassExpr = appViewInstance
              .callMethod('updateChildClass', [renderNode, renderValue]);
          updateStmts.add(updateClassExpr.toStmt());
        } else {
          if (boundProp.unit == 'if') {
            // Conditional attribute (i.e. [attr.disabled.if]).
            //
            // For now we treat this as a pure transform to make the
            // implementation simpler (and consistent with how it worked before)
            // - it would be a non-breaking change to optimize further.
            renderValue = renderValue.conditional(o.literal(''), o.NULL_EXPR);
          } else {
            // For attributes other than class convert to string if necessary.
            // The sanitizer returns a string, so we only check if values that
            // don't require sanitization need to be converted to a string.
            if (boundProp.securityContext == TemplateSecurityContext.none &&
                !converter.isString(boundProp.value)) {
              renderValue = renderValue.callMethod(
                'toString',
                const [],
                checked: converter.isNullable(boundProp.value),
              );
            }
          }
          var params = createSetAttributeParams(
            renderNode,
            attrNs,
            attrName,
            renderValue,
          );
          updateStmts.add(o.InvokeMemberMethodExpr(
            attrNs == null ? 'setAttr' : 'setAttrNS',
            params,
          ).toStmt());
        }
        break;
      case PropertyBindingType.cssClass:
        fieldType = o.BOOL_TYPE;
        renderMethod = isHtmlElement ? 'updateClass' : 'updateElemClass';
        updateStmts.add(o.InvokeMemberMethodExpr(renderMethod,
            [renderNode, o.literal(boundProp.name), renderValue]).toStmt());
        break;
      case PropertyBindingType.style:
        // Convert to string if necessary.
        o.Expression styleValueExpr = converter.isString(boundProp.value)
            ? currValExpr
            : currValExpr.callMethod('toString', [],
                checked: converter.isNullable(boundProp.value));
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
    final checkExpression = converter.convertToExpression(
        boundProp.value, boundProp.sourceSpan, fieldType);
    _bind(
      storage,
      currValExpr,
      fieldExpr,
      checkExpression,
      converter.isImmutable(boundProp.value),
      converter.isNullable(boundProp.value),
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

o.Expression _sanitizedValue(
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
    case TemplateSecurityContext.url:
      methodName = 'sanitizeUrl';
      break;
    case TemplateSecurityContext.resourceUrl:
      methodName = 'sanitizeResourceUrl';
      break;
    default:
      throw ArgumentError('internal error, unexpected '
          'TemplateSecurityContext ${boundProp.securityContext}.');
  }
  var ctx = o.importExpr(Identifiers.appViewUtils).prop('sanitizer');
  return ctx.callMethod(methodName, [renderValue]);
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
    renderNode.toReadExpr(),
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
  var implicitReceiver = DetectChangesVars.cachedCtx;
  var converter = BoundValueConverter.forView(view, implicitReceiver);
  var detectChangesInInputsMethod = view.detectChangesInInputsMethod;
  var dynamicInputsMethod = CompileMethod();
  var constantInputsMethod = CompileMethod();
  var lifecycleHooks = directive.lifecycleHooks;
  bool calcChangesMap = lifecycleHooks.contains(LifecycleHooks.onChanges);
  bool calcChangedState = lifecycleHooks.contains(LifecycleHooks.afterChanges);
  var isOnPushComp = directive.isComponent &&
      !isDefaultChangeDetectionStrategy(directive.changeDetection);
  var isStatefulComp = directive.isComponent &&
      directive.changeDetection == ChangeDetectionStrategy.Stateful;
  var isStatefulDirective = !directive.isComponent &&
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
  if (((!isStatefulComp && isOnPushComp) || calcChangedState) &&
      view.viewType != ViewType.host) {
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
    if (isStatefulDirective) {
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
    if ((!isStatefulComp && isOnPushComp) || calcChangedState) {
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
    if (isStatefulComp) {
      _bindToUpdateMethod(
        view,
        currValExpr,
        fieldExpr,
        expression,
        statements,
        dynamicInputsMethod,
        fieldType: inputType,
      );
    } else {
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
  }
  if (constantInputsMethod.isNotEmpty) {
    detectChangesInInputsMethod.addStmtsIfFirstCheck(
      constantInputsMethod.finish(),
    );
  }
  if (dynamicInputsMethod.isNotEmpty) {
    detectChangesInInputsMethod.addStmts(dynamicInputsMethod.finish());
  }
  if (!isStatefulComp && isOnPushComp) {
    detectChangesInInputsMethod.addStmt(o.IfStmt(DetectChangesVars.changed, [
      compileElement.componentView.callMethod('markAsCheckOnce', []).toStmt()
    ]));
  }
}

void _bindToUpdateMethod(
  CompileView view,
  o.ReadVarExpr currValExpr,
  o.ReadClassMemberExpr fieldExpr,
  o.Expression checkExpression,
  List<o.Statement> actions,
  CompileMethod method, {
  o.OutputType fieldType,
}) {
  if (checkExpression == null) {
    // e.g. an empty expression was given
    return;
  }
  // Add class field to store previous value.
  bool isPrimitive = _isPrimitiveFieldType(fieldType);
  ViewStorageItem previousValueField = view.storage.allocate(fieldExpr.name,
      outputType: isPrimitive ? fieldType : null,
      modifiers: const [o.StmtModifier.Private]);
  // Generate: final currVal_0 = ctx.expression.
  method.addStmt(currValExpr
      .set(checkExpression)
      .toDeclStmt(null, [o.StmtModifier.Final]));

  // If we have only setter action, we can simply call updater and assign
  // newValue to previous value.
  if (actions.length == 1) {
    method.addStmt(actions.first);
    method.addStmt(
        view.storage.buildWriteExpr(previousValueField, currValExpr).toStmt());
  } else {
    method.addStmt(o.IfStmt(
        o.importExpr(Identifiers.checkBinding).callFn([fieldExpr, currValExpr]),
        List.from(actions)
          ..addAll(
              [o.WriteClassMemberExpr(fieldExpr.name, currValExpr).toStmt()])));
  }
}

void bindInlinedNgIf(DirectiveAst directiveAst, CompileElement compileElement) {
  assert(directiveAst.directive.identifier.name == 'NgIf',
      'Inlining a template that is not an NgIf');
  var view = compileElement.view;

  var input = directiveAst.inputs.single;
  var bindingIndex = view.nameResolver.createUniqueBindIndex();
  var fieldExpr = _createBindFieldExpr(bindingIndex);
  var currValExpr = _createCurrValueExpr(bindingIndex);

  var embeddedView = compileElement.embeddedView;

  var buildStmts = <o.Statement>[];
  embeddedView.writeBuildStatements(buildStmts);
  var rootNodes = createFlatArray(embeddedView.rootNodesOrViewContainers);
  var anchor = compileElement.renderNode.toReadExpr();
  var buildArgs = [anchor, rootNodes];
  var destroyArgs = [rootNodes];
  if (compileElement.isRootElement) {
    buildArgs.add(o.literal(true));
    destroyArgs.add(o.literal(true));
  }
  buildStmts
      .add(o.InvokeMemberMethodExpr('addInlinedNodes', buildArgs).toStmt());

  var inputAst = _inputAst(input);

  final converter =
      BoundValueConverter.forView(view, DetectChangesVars.cachedCtx);

  var isImmutable = converter.isImmutable(input.value);
  ast.AST condition = isImmutable
      ? inputAst
      // This hack is to allow legacy NgIf behavior on null inputs
      : ast.Binary('==', inputAst, ast.LiteralPrimitive(true));
  List<o.Statement> statements = _statements(
      currValExpr, buildStmts, destroyArgs,
      isImmutable: isImmutable);

  var dynamicInputsMethod = CompileMethod();
  var constantInputsMethod = CompileMethod();
  _bindAst(
      view.component,
      view.nameResolver,
      view.storage,
      currValExpr,
      fieldExpr,
      condition,
      input.sourceSpan,
      statements,
      dynamicInputsMethod,
      constantInputsMethod,
      fieldType: o.BOOL_TYPE,
      fieldExprInitializer: o.literal(false));

  if (constantInputsMethod.isNotEmpty) {
    view.detectChangesInInputsMethod.addStmtsIfFirstCheck(
      constantInputsMethod.finish(),
    );
  }
  if (dynamicInputsMethod.isNotEmpty) {
    view.detectChangesInInputsMethod.addStmts(dynamicInputsMethod.finish());
  }
}

List<o.Statement> _statements(
  o.ReadVarExpr currValExpr,
  List<o.Statement> buildStmts,
  List<o.Expression> destroyArgs, {
  @required bool isImmutable,
}) {
  if (isImmutable) {
    // If the input is immutable, we don't need to handle the case where the
    // condition is false since in that case we simply do nothing.
    return <o.Statement>[o.IfStmt(currValExpr, buildStmts)];
  } else {
    var destroyStmts = <o.Statement>[
      o.InvokeMemberMethodExpr('removeInlinedNodes', destroyArgs).toStmt(),
    ];
    return <o.Statement>[o.IfStmt(currValExpr, buildStmts, destroyStmts)];
  }
}

ast.AST _inputAst(BoundDirectivePropertyAst input) {
  var inputValue = input.value;
  if (inputValue is BoundExpression) {
    // This promotion is require to support the legacy hack in the following if.
    return inputValue.expression;
  } else {
    // This state is reached if an @i18n message is bound to an *ngIf, which we
    // know isn't a boolean expression.
    throwFailure(input.sourceSpan.message('Expected a boolean expression'));
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
