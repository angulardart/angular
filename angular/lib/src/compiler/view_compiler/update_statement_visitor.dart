import 'package:angular/src/compiler/identifiers.dart'
    show DomHelpers, Identifiers;
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/security.dart';
import 'package:angular/src/compiler/view_compiler/compile_view.dart'
    show NodeReference, TextBindingNodeReference;

/// Converts [binding] to an update statement.
///
/// This is update statement is called when the [currValExpr] has changed.
o.Statement bindingToUpdateStatement(
    ir.Binding binding,
    o.Expression appViewInstance,
    NodeReference renderNode,
    bool isHtmlElement,
    o.Expression currValExpr) {
  // Wraps current value with sanitization call if necessary.
  o.Expression renderValue =
      _sanitizedValue(binding.target.securityContext, currValExpr);
  var visitor = _UpdateStatementsVisitor(
      appViewInstance, renderNode, binding.source, isHtmlElement, currValExpr);
  return binding.target.accept(visitor, renderValue);
}

class _UpdateStatementsVisitor
    implements ir.BindingTargetVisitor<o.Statement, o.Expression> {
  final o.Expression appViewInstance;
  final NodeReference renderNode;
  final ir.BindingSource bindingSource;
  final bool isHtmlElement;
  final o.Expression currValExpr;

  _UpdateStatementsVisitor(
    this.appViewInstance,
    this.renderNode,
    this.bindingSource,
    this.isHtmlElement,
    this.currValExpr,
  );

  @override
  o.Statement visitAttributeBinding(ir.AttributeBinding attributeBinding,
      [o.Expression renderValue]) {
    if (attributeBinding.isConditional) {
      // Conditional attribute (i.e. [attr.disabled.if]).
      //
      // For now we treat this as a pure transform to make the
      // implementation simpler (and consistent with how it worked before)
      // - it would be a non-breaking change to optimize further.
      renderValue = renderValue.conditional(o.literal(''), o.NULL_EXPR);
    } else {
      // Convert to string if necessary.
      // The sanitizer returns a string, so we only check if values that
      // don't require sanitization need to be converted to a string.
      if (attributeBinding.securityContext == TemplateSecurityContext.none &&
          !bindingSource.isString) {
        renderValue = renderValue.callMethod(
          'toString',
          const [],
          checked: bindingSource.isNullable,
        );
      }
    }
    if (attributeBinding.hasNamespace) {
      return o.importExpr(DomHelpers.updateAttributeNS).callFn([
        renderNode.toReadExpr(),
        o.literal(attributeBinding.namespace),
        o.literal(attributeBinding.name),
        renderValue,
      ]).toStmt();
    }

    return o
        .importExpr(bindingSource.isNullable
            ? DomHelpers.updateAttribute
            : DomHelpers.setAttribute)
        .callFn(
      [
        renderNode.toReadExpr(),
        o.literal(attributeBinding.name),
        renderValue,
      ],
    ).toStmt();
  }

  @override
  o.Statement visitClassBinding(ir.ClassBinding classBinding,
      [o.Expression renderValue]) {
    if (classBinding.name == null) {
      // TODO(b/126226538): Consider optimizing "static" classBindings in the
      // constructor to skip adding the shim classes.

      // Handle [attr.class]="expression" or [className]="expression".
      final renderMethod =
          isHtmlElement ? 'updateChildClass' : 'updateChildClassNonHtml';
      return appViewInstance.callMethod(
          renderMethod, [renderNode.toReadExpr(), renderValue]).toStmt();
    } else {
      final renderMethod = isHtmlElement
          ? DomHelpers.updateClassBinding
          : DomHelpers.updateClassBindingNonHtml;
      return o.importExpr(renderMethod).callFn([
        renderNode.toReadExpr(),
        o.literal(classBinding.name),
        renderValue,
      ]).toStmt();
    }
  }

  @override
  o.Statement visitPropertyBinding(ir.PropertyBinding propertyBinding,
      [o.Expression renderValue]) {
    return o.importExpr(DomHelpers.setProperty).callFn([
      renderNode.toReadExpr(),
      o.literal(propertyBinding.name),
      renderValue,
    ]).toStmt();
  }

  // TODO(b/110433960): Should probably use renderValue instead of currValExpr.
  @override
  o.Statement visitStyleBinding(ir.StyleBinding styleBinding, [_]) {
    o.Expression styleValueExpr;
    if (styleBinding.unit != null) {
      // Append the unit to the bound expression if not null. For example:
      //
      //    ctx.width == null ? null : ctx.width.toString() + 'px'
      //
      final styleString = bindingSource.isString
          ? currValExpr
          : currValExpr.callMethod('toString', []);
      final styleWithUnit = styleString.plus(o.literal(styleBinding.unit));
      styleValueExpr =
          currValExpr.isBlank().conditional(o.NULL_EXPR, styleWithUnit);
    } else {
      styleValueExpr = bindingSource.isString
          ? currValExpr
          : currValExpr.callMethod(
              'toString', [],
              // Use null check to bind null instead of string "null".
              checked: bindingSource.isNullable,
            );
    }
    // Call Element.style.setProperty(propName, value);
    o.Expression updateStyleExpr = renderNode
        .toReadExpr()
        .prop('style')
        .callMethod(
            'setProperty', [o.literal(styleBinding.name), styleValueExpr]);
    return updateStyleExpr.toStmt();
  }

  @override
  o.Statement visitTabIndexBinding(ir.TabIndexBinding tabIndexBinding,
      [o.Expression renderValue]) {
    if (renderValue is o.LiteralExpr) {
      final value = renderValue.value;
      try {
        final tabValue = int.parse(value as String);
        return renderNode
            .toReadExpr()
            .prop('tabIndex')
            .set(o.literal(tabValue))
            .toStmt();
      } catch (_) {
        // TODO(b/128689252): Better error handling.
        throw ArgumentError.value(renderValue.value, 'renderValue',
            'tabIndex only supports an int value.');
      }
    } else {
      // Assume it's an int field
      // TODO(b/128689252): Validate this during parse / convert to IR.
      return renderNode.toReadExpr().prop('tabIndex').set(renderValue).toStmt();
    }
  }

  @override
  o.Statement visitTextBinding(ir.TextBinding textBinding,
      [o.Expression renderValue]) {
    // TODO(alorenzen): Generalize updateExpr() to all NodeReferences.
    var node = renderNode as TextBindingNodeReference;
    return node.updateExpr(renderValue).toStmt();
  }

  @override
  o.Statement visitHtmlBinding(ir.HtmlBinding htmlBinding, [_]) {
    throw UnsupportedError(
        '${ir.HtmlBinding}s are not supported as bound properties.');
  }

  @override
  o.Statement visitInputBinding(ir.InputBinding inputBinding,
      [o.Expression renderValue]) {
    return appViewInstance.prop(inputBinding.name).set(renderValue).toStmt();
  }

  @override
  o.Statement visitCustomEvent(ir.CustomEvent customEvent,
      [o.Expression renderValue]) {
    final appViewUtilsExpr = o.importExpr(Identifiers.appViewUtils);
    final eventManagerExpr = appViewUtilsExpr.prop('eventManager');
    return eventManagerExpr.callMethod(
      'addEventListener',
      [
        renderNode?.toReadExpr() ?? appViewInstance,
        o.literal(customEvent.name),
        renderValue
      ],
    ).toStmt();
  }

  @override
  o.Statement visitDirectiveOutput(ir.DirectiveOutput directiveOutput,
          [o.Expression renderValue]) =>
      renderNode.toWriteStmt(appViewInstance
          .prop(directiveOutput.name)
          .callMethod(o.BuiltinMethod.SubscribeObservable, [renderValue],
              checked: directiveOutput.isMockLike));

  @override
  o.Statement visitNativeEvent(ir.NativeEvent nativeEvent,
          [o.Expression renderValue]) =>
      (renderNode?.toReadExpr() ?? appViewInstance).callMethod(
        'addEventListener',
        [o.literal(nativeEvent.name), renderValue],
      ).toStmt();
}

o.Expression _sanitizedValue(
    TemplateSecurityContext securityContext, o.Expression renderValue) {
  String methodName;
  switch (securityContext) {
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
          'TemplateSecurityContext $securityContext.');
  }
  var ctx = o.importExpr(Identifiers.appViewUtils).prop('sanitizer');
  return ctx.callMethod(methodName, [renderValue]);
}
