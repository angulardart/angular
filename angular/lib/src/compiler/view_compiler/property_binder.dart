import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/core/app_view_consts.dart' show namespaceUris;
import 'package:angular/src/core/change_detection/constants.dart'
    show isDefaultChangeDetectionStrategy, ChangeDetectionStrategy;
import 'package:angular/src/core/linker/view_type.dart' show ViewType;
import 'package:angular/src/core/metadata/lifecycle_hooks.dart'
    show LifecycleHooks;
import 'package:angular/src/core/security.dart';
import 'package:angular/src/source_gen/common/names.dart'
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
import 'expression_converter.dart' show convertCdExpressionToIr;
import 'ir/view_storage.dart';
import 'view_builder.dart' show buildUpdaterFunctionName;
import 'view_compiler_utils.dart'
    show
        createFlatArray,
        createSetAttributeParams,
        outlinerDeprecated,
        unwrapDirective,
        unwrapDirectiveInstance;
import 'view_name_resolver.dart';

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
    CompileDirectiveMetadata viewDirective,
    ViewNameResolver nameResolver,
    ViewStorage storage,
    o.ReadVarExpr currValExpr,
    o.ReadClassMemberExpr fieldExpr,
    ast.AST parsedExpression,
    o.Expression context,
    List<o.Statement> actions,
    CompileMethod method,
    CompileMethod literalMethod,
    bool genDebugInfo,
    {o.OutputType fieldType,
    bool isHostComponent: false,
    o.Expression fieldExprInitializer}) {
  parsedExpression =
      rewriteInterpolate(parsedExpression, viewDirective.analyzedClass);
  var checkExpression = convertCdExpressionToIr(
    nameResolver,
    context,
    parsedExpression,
    viewDirective.template.preserveWhitespace,
    fieldType,
  );
  if (isImmutable(parsedExpression, viewDirective.analyzedClass)) {
    // If the expression is a literal, it will never change, so we can run it
    // once on the first change detection.
    if (!isHostComponent) {
      _bindLiteral(checkExpression, actions, currValExpr.name, fieldExpr.name,
          literalMethod, canBeNull(parsedExpression));
    }
    return;
  }
  if (checkExpression == null) {
    // e.g. an empty expression was given
    return;
  }
  bool isPrimitive = isPrimitiveFieldType(fieldType);
  ViewStorageItem previousValueField = storage.allocate(fieldExpr.name,
      modifiers: const [o.StmtModifier.Private],
      initializer: fieldExprInitializer,
      outputType: isPrimitive ? fieldType : null);
  method.addStmt(currValExpr
      .set(checkExpression)
      .toDeclStmt(null, [o.StmtModifier.Final]));
  o.Expression condition;
  if (genDebugInfo) {
    condition =
        o.importExpr(Identifiers.checkBinding).callFn([fieldExpr, currValExpr]);
  } else {
    condition = new o.NotExpr(
        o.importExpr(Identifiers.identical).callFn([fieldExpr, currValExpr]));
  }
  method.addStmt(new o.IfStmt(
      condition,
      new List.from(actions)
        ..addAll([
          storage.buildWriteExpr(previousValueField, currValExpr).toStmt()
        ])));
}

/// The same as [bind], but we know that [checkExpression] is a literal.
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
    method.addStmt(new o.IfStmt(
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
  var currValExpr = createCurrValueExpr(bindingIndex);
  // Expression that points to _expr_## stored value.
  var valueField = createBindFieldExpr(bindingIndex);
  var dynamicRenderMethod = new CompileMethod(view.genDebugInfo);
  dynamicRenderMethod.resetDebugInfo(compileNode.nodeIndex, boundText);
  var constantRenderMethod = new CompileMethod(view.genDebugInfo);
  bind(
      view.component,
      view.nameResolver,
      view.storage,
      currValExpr,
      valueField,
      boundText.value,
      DetectChangesVars.cachedCtx,
      [
        compileNode.renderNode
            .toReadExpr()
            .prop('text')
            .set(currValExpr)
            .toStmt()
      ],
      dynamicRenderMethod,
      constantRenderMethod,
      view.genDebugInfo);
  if (constantRenderMethod.isNotEmpty) {
    view.detectChangesRenderPropertiesMethod.addStmt(new o.IfStmt(
        DetectChangesVars.firstCheck, constantRenderMethod.finish()));
  }
  if (dynamicRenderMethod.isNotEmpty) {
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
    o.Expression appViewInstance,
    o.Expression context,
    CompileDirectiveMetadata directiveMeta,
    o.Expression renderNode,
    bool isHtmlElement,
    ViewNameResolver nameResolver,
    ViewStorage storage,
    CompileMethod targetMethod,
    bool genDebugInfo,
    {bool updatingHostAttribute: false,
    bool isHostComponent: false}) {
  final dynamicPropertiesMethod = new CompileMethod(genDebugInfo);
  final constantPropertiesMethod = new CompileMethod(genDebugInfo);
  for (var boundProp in boundProps) {
    // Add to view bindings collection.
    int bindingIndex = nameResolver.createUniqueBindIndex();

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
          var updateClassExpr = appViewInstance
              .callMethod('updateChildClass', [renderNode, renderValue]);
          updateStmts.add(updateClassExpr.toStmt());
          fieldType = o.STRING_TYPE;
        } else {
          updateStmts.add(new o.InvokeMemberMethodExpr('setProp',
              [renderNode, o.literal(boundProp.name), renderValue]).toStmt());
        }
        break;
      case PropertyBindingType.Attribute:
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
          // For attributes other than class convert value to a string.
          // TODO: Once we have analyzer summaries and know the type is already
          // String short-circuit.
          renderValue =
              renderValue.callMethod('toString', const [], checked: true);

          var params = createSetAttributeParams(
              renderNode, attrNs, attrName, renderValue);

          updateStmts.add(new o.InvokeMemberMethodExpr(
                  attrNs == null ? 'setAttr' : 'setAttrNS', params)
              .toStmt());
        }
        break;
      case PropertyBindingType.Class:
        fieldType = o.BOOL_TYPE;
        renderMethod = isHtmlElement ? 'updateClass' : 'updateElemClass';
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

    bind(
        directiveMeta,
        nameResolver,
        storage,
        currValExpr,
        fieldExpr,
        boundProp.value,
        context,
        updateStmts,
        dynamicPropertiesMethod,
        constantPropertiesMethod,
        genDebugInfo,
        fieldType: fieldType,
        isHostComponent: isHostComponent);
  }
  if (constantPropertiesMethod.isNotEmpty) {
    targetMethod.addStmt(new o.IfStmt(
        DetectChangesVars.firstCheck, constantPropertiesMethod.finish()));
  }
  if (dynamicPropertiesMethod.isNotEmpty) {
    targetMethod.addStmts(dynamicPropertiesMethod.finish());
  }
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
  var appViewInstance = compileElement.component == null
      ? o.THIS_EXPR
      : compileElement.componentView;
  var renderNode = compileElement.renderNode;
  var view = compileElement.view;
  bindAndWriteToRenderer(
      boundProps,
      appViewInstance,
      DetectChangesVars.cachedCtx,
      view.component,
      renderNode.toReadExpr(),
      compileElement.isHtmlElement,
      view.nameResolver,
      view.storage,
      view.detectChangesRenderPropertiesMethod,
      view.genDebugInfo);
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
    {bool isHostComponent: false}) {
  var directive = directiveAst.directive;
  if (directive.inputs.isEmpty) {
    return;
  }

  var view = compileElement.view;
  var detectChangesInInputsMethod = view.detectChangesInInputsMethod;
  var dynamicInputsMethod = new CompileMethod(view.genDebugInfo);
  var constantInputsMethod = new CompileMethod(view.genDebugInfo);
  dynamicInputsMethod.resetDebugInfo(
      compileElement.nodeIndex, compileElement.sourceAst);
  var lifecycleHooks = directive.lifecycleHooks;
  bool calcChangesMap = lifecycleHooks.contains(LifecycleHooks.OnChanges);
  bool calcChangedState = lifecycleHooks.contains(LifecycleHooks.AfterChanges);
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
      view.viewType != ViewType.HOST) {
    detectChangesInInputsMethod
        .addStmt(DetectChangesVars.changed.set(o.literal(false)).toStmt());
  }
  // directiveAst contains the target directive we are updating.
  // input is a BoundPropertyAst that contains binding metadata.
  for (var input in directiveAst.inputs) {
    var bindingIndex = view.nameResolver.createUniqueBindIndex();
    dynamicInputsMethod.resetDebugInfo(compileElement.nodeIndex, input);
    var fieldExpr = createBindFieldExpr(bindingIndex);
    var currValExpr = createCurrValueExpr(bindingIndex);
    var statements = <o.Statement>[];

    // Optimization specifically for NgIf. Since the directive already performs
    // change detection we can directly update it's input.
    // TODO: generalize to SingleInputDirective mixin.
    if (directive.identifier.name == 'NgIf' && input.directiveName == 'ngIf') {
      var checkExpression = convertCdExpressionToIr(
          view.nameResolver,
          DetectChangesVars.cachedCtx,
          input.value,
          view.component.template.preserveWhitespace,
          o.BOOL_TYPE);
      dynamicInputsMethod.addStmt(directiveInstance
          .prop(input.directiveName)
          .set(checkExpression)
          .toStmt());
      continue;
    }
    if (isStatefulDirective) {
      var fieldType = o.importType(directiveAst.directive.inputTypes[input]);
      var checkExpression = convertCdExpressionToIr(
          view.nameResolver,
          DetectChangesVars.cachedCtx,
          input.value,
          view.component.template.preserveWhitespace,
          fieldType);
      if (isImmutable(input.value, view.component.analyzedClass)) {
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
    } else if (isStatefulComp && outlinerDeprecated) {
      // Write code for components that extend ComponentState:
      // Since we are not going to call markAsCheckOnce anymore we need to
      // generate a call to property updater that will invoke setState() on the
      // component if value has changed.
      String updaterFunctionName = buildUpdaterFunctionName(
          directiveAst.directive.type.name, input.directiveName);
      var updateFuncExpr = o.importExpr(new CompileIdentifierMetadata(
          name: updaterFunctionName,
          moduleUrl: toTemplateExtension(directive.identifier.moduleUrl),
          prefix: directive.identifier.prefix));
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
      statements.add(new o.WriteIfNullExpr(
              DetectChangesVars.changes.name,
              o.literalMap(
                  [], new o.MapType(o.importType(Identifiers.SimpleChange))))
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
        ? o.importType(inputTypeMeta, inputTypeMeta.genericTypes)
        : null;
    if (isStatefulComp) {
      bindToUpdateMethod(view, currValExpr, fieldExpr, input.value,
          DetectChangesVars.cachedCtx, statements, dynamicInputsMethod,
          fieldType: inputType);
    } else {
      bind(
          view.component,
          view.nameResolver,
          view.storage,
          currValExpr,
          fieldExpr,
          input.value,
          DetectChangesVars.cachedCtx,
          statements,
          dynamicInputsMethod,
          constantInputsMethod,
          view.genDebugInfo,
          fieldType: inputType,
          isHostComponent: isHostComponent);
    }
  }
  if (constantInputsMethod.isNotEmpty) {
    detectChangesInInputsMethod.addStmt(new o.IfStmt(
        DetectChangesVars.firstCheck, constantInputsMethod.finish()));
  }
  if (dynamicInputsMethod.isNotEmpty) {
    detectChangesInInputsMethod.addStmts(dynamicInputsMethod.finish());
  }
  if (!isStatefulComp && isOnPushComp) {
    detectChangesInInputsMethod.addStmt(new o.IfStmt(
        DetectChangesVars.changed, [
      compileElement.componentView.callMethod('markAsCheckOnce', []).toStmt()
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
  var checkExpression = convertCdExpressionToIr(view.nameResolver, context,
      parsedExpression, view.component.template.preserveWhitespace, fieldType);
  if (checkExpression == null) {
    // e.g. an empty expression was given
    return;
  }
  // Add class field to store previous value.
  bool isPrimitive = isPrimitiveFieldType(fieldType);
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
    // Otherwise use traditional checkBinding call.
    o.Expression condition;
    if (view.genConfig.genDebugInfo) {
      condition = o
          .importExpr(Identifiers.checkBinding)
          .callFn([fieldExpr, currValExpr]);
    } else {
      condition = new o.NotExpr(
          o.importExpr(Identifiers.identical).callFn([fieldExpr, currValExpr]));
    }
    method.addStmt(new o.IfStmt(
        condition,
        new List.from(actions)
          ..addAll([
            new o.WriteClassMemberExpr(fieldExpr.name, currValExpr).toStmt()
          ])));
  }
}

void bindInlinedNgIf(DirectiveAst directiveAst, CompileElement compileElement) {
  assert(directiveAst.directive.identifier.name == 'NgIf',
      'Inlining a template that is not an NgIf');
  var view = compileElement.view;
  var detectChangesInInputsMethod = view.detectChangesInInputsMethod;
  var dynamicInputsMethod = new CompileMethod(view.genDebugInfo);
  var constantInputsMethod = new CompileMethod(view.genDebugInfo);
  dynamicInputsMethod.resetDebugInfo(
      compileElement.nodeIndex, compileElement.sourceAst);

  var input = directiveAst.inputs.single;
  var bindingIndex = view.nameResolver.createUniqueBindIndex();
  dynamicInputsMethod.resetDebugInfo(compileElement.nodeIndex, input);
  var fieldExpr = createBindFieldExpr(bindingIndex);
  var currValExpr = createCurrValueExpr(bindingIndex);

  var embeddedView = compileElement.embeddedView;

  var buildStmts = <o.Statement>[];
  embeddedView.writeBuildStatements(buildStmts);
  var rootNodes = createFlatArray(embeddedView.rootNodesOrViewContainers);
  var anchor = compileElement.renderNode.toReadExpr();
  var isRoot = compileElement.view != compileElement.parent.view;
  var buildArgs = [anchor, rootNodes];
  var destroyArgs = [rootNodes];
  if (isRoot) {
    buildArgs.add(o.literal(true));
    destroyArgs.add(o.literal(true));
  }
  buildStmts
      .add(new o.InvokeMemberMethodExpr('addInlinedNodes', buildArgs).toStmt());

  var destroyStmts = <o.Statement>[
    new o.InvokeMemberMethodExpr('removeInlinedNodes', destroyArgs).toStmt(),
  ];

  List<o.Statement> statements;
  ast.AST condition;

  if (isImmutable(input.value, view.component.analyzedClass)) {
    // If the input is immutable, we don't need to handle the case where the
    // condition is false since in that case we simply do nothing.
    statements = <o.Statement>[
      new o.IfStmt(currValExpr, buildStmts),
    ];
    condition = input.value;
  } else {
    statements = <o.Statement>[
      new o.IfStmt(currValExpr, buildStmts, destroyStmts)
    ];
    // This hack is to allow legacy NgIf behavior on null inputs
    condition =
        new ast.Binary('==', input.value, new ast.LiteralPrimitive(true));
  }

  bind(
      view.component,
      view.nameResolver,
      view.storage,
      currValExpr,
      fieldExpr,
      condition,
      DetectChangesVars.cachedCtx,
      statements,
      dynamicInputsMethod,
      constantInputsMethod,
      view.genDebugInfo,
      fieldType: o.BOOL_TYPE,
      isHostComponent: false,
      fieldExprInitializer: o.literal(false));

  if (constantInputsMethod.isNotEmpty) {
    detectChangesInInputsMethod.addStmt(new o.IfStmt(
        DetectChangesVars.firstCheck, constantInputsMethod.finish()));
  }
  if (dynamicInputsMethod.isNotEmpty) {
    detectChangesInInputsMethod.addStmts(dynamicInputsMethod.finish());
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

bool isPrimitiveFieldType(o.OutputType type) {
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
