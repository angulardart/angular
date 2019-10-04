import 'package:source_span/source_span.dart';

import '../expression_parser/ast.dart';
import '../template_parser.dart';
import 'message.dart';
import 'metadata.dart';

/// Creates an internationalized message from a bound [value] with [metadata].
I18nMessage i18nMessageFromPropertyBinding(
  ASTWithSource value,
  I18nMetadata metadata,
  SourceSpan sourceSpan,
  TemplateContext templateContext,
) {
  final visitor = _I18nPropertyVisitor();
  final context = _I18nPropertyContext();
  try {
    value.ast.visit(visitor, context);
    return context.build(metadata);
  } on _I18nPropertyException catch (e) {
    templateContext.reportError(e.message, sourceSpan);
    return null;
  }
}

/// Context for visiting an internationalized property binding.
class _I18nPropertyContext {
  final _messageBuffer = StringBuffer();

  /// Adds [text] to the bound internationalized message.
  void addText(String text) {
    _messageBuffer.write(text);
  }

  /// Builds an internationalized message from a visited property.
  I18nMessage build(I18nMetadata metadata) {
    final text = _messageBuffer.toString();
    if (text.trim().isEmpty) {
      throw _I18nPropertyException(
          'Internationalized messages must contain text');
    }
    return I18nMessage(text, metadata);
  }
}

class _I18nPropertyException implements Exception {
  final String message;

  _I18nPropertyException(this.message);
}

/// Visits an internationalized property binding.
class _I18nPropertyVisitor extends AstVisitor<void, _I18nPropertyContext> {
  @override
  void visitBinary(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitConditional(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitEmptyExpr(_, _I18nPropertyContext context) {
    // This state is reached if a property binding has no value:
    //
    //  <example [input] @i18n:input="A description."></example>
    //
    // We don't report this as an invalid expression so that the subsequent
    // check for empty messages can instead report that messages require text.
  }

  @override
  void visitFunctionCall(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitIfNull(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitImplicitReceiver(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitInterpolation(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitKeyedRead(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitKeyedWrite(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitLiteralArray(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitLiteralPrimitive(
    LiteralPrimitive ast,
    _I18nPropertyContext context,
  ) {
    final value = ast.value;
    if (value is String) {
      context.addText(value);
    } else {
      _reportInvalidBinding(context);
    }
  }

  @override
  void visitMethodCall(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitNamedExpr(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitPipe(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitPrefixNot(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitPropertyRead(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitPropertyWrite(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitSafeMethodCall(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitSafePropertyRead(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  @override
  void visitStaticRead(_, _I18nPropertyContext context) {
    _reportInvalidBinding(context);
  }

  void _reportInvalidBinding(_I18nPropertyContext context) {
    throw _I18nPropertyException(
        'Internationalized property bindings only support string literals');
  }
}
