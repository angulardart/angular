import 'package:angular/src/compiler/identifiers.dart'
    show DomHelpers, Identifiers;
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/core/security.dart';

import 'view_compiler_utils.dart' show createSetAttributeParams, namespaceUris;

/// Converts [binding] to an update statement.
///
/// This is update statement is called when the [currValExpr] has changed.
o.Statement bindingToUpdateStatement(
    ir.Binding binding,
    o.Expression appViewInstance,
    o.Expression renderNode,
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
  final o.Expression renderNode;
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
    var params = createSetAttributeParams(
      renderNode,
      namespaceUris[attributeBinding.namespace],
      attributeBinding.name,
      renderValue,
    );

    final updateAttribute = o.importExpr(attributeBinding.hasNamespace
        ? DomHelpers.updateAttributeNS
        : (bindingSource.isNullable
            ? DomHelpers.updateAttribute
            : DomHelpers.setAttribute));

    return updateAttribute.callFn(params).toStmt();
  }

  @override
  o.Statement visitClassBinding(ir.ClassBinding classBinding,
      [o.Expression renderValue]) {
    if (classBinding.name == null) {
      // Handle [attr.class]="expression" or [className]="expression".
      final renderMethod =
          isHtmlElement ? 'updateChildClass' : 'updateChildClassNonHtml';
      return appViewInstance
          .callMethod(renderMethod, [renderNode, renderValue]).toStmt();
    } else {
      final renderMethod = isHtmlElement
          ? DomHelpers.updateClassBinding
          : DomHelpers.updateClassBindingNonHtml;
      return o.importExpr(renderMethod).callFn([
        renderNode,
        o.literal(classBinding.name),
        renderValue,
      ]).toStmt();
    }
  }

  @override
  o.Statement visitPropertyBinding(ir.PropertyBinding propertyBinding,
      [o.Expression renderValue]) {
    return o.importExpr(DomHelpers.setProperty).callFn([
      renderNode,
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
    o.Expression updateStyleExpr = renderNode.prop('style').callMethod(
        'setProperty', [o.literal(styleBinding.name), styleValueExpr]);
    return updateStyleExpr.toStmt();
  }

  @override
  o.Statement visitTextBinding(ir.TextBinding textBinding, [_]) {
    throw UnsupportedError(
        '${ir.TextBinding}s are not supported as bound properties.');
  }

  @override
  o.Statement visitHtmlBinding(ir.HtmlBinding htmlBinding, [_]) {
    throw UnsupportedError(
        '${ir.HtmlBinding}s are not supported as bound properties.');
  }
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
