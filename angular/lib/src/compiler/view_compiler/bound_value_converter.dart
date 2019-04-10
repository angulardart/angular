import 'package:angular/src/compiler/i18n/message.dart';
import 'package:angular/src/compiler/ir/model.dart' as ir;

import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../output/output_ast.dart' as o;
import '../view_compiler/compile_view.dart';
import 'expression_converter.dart' show convertCdExpressionToIr, NameResolver;

/// An abstract utility for converting bound values to output expressions.
abstract class BoundValueConverter
    implements ir.BindingSourceVisitor<o.Expression, o.OutputType> {
  final CompileDirectiveMetadata _metadata;
  final o.Expression _implicitReceiver;
  final NameResolver _nameResolver;

  BoundValueConverter(
    this._metadata,
    this._implicitReceiver,
    this._nameResolver,
  );

  /// Creates a bound value converter for a directive change detector.
  ///
  /// The [implicitReceiver] is the receiver on which bound expressions are
  /// implicitly invoked. For example, if [implicitReceiver] is the variable
  /// `ctx`, the expression `foo(bar)` is rewritten as `ctx.foo(ctx.bar)`.
  ///
  /// The [nameResolver] is used to uniquely name any variables created during
  /// the process of converting bound values to expressions.
  factory BoundValueConverter.forDirective(
    CompileDirectiveMetadata metadata,
    o.Expression implicitReceiver,
    NameResolver nameResolver,
  ) = _DirectiveBoundValueConverter;

  /// Creates a bound value converter for expressions in a [view].
  ///
  /// The [implicitReceiver] is the receiver on which bound expressions are
  /// implicitly invoked. For example, if [implicitReceiver] is the variable
  /// `ctx`, the expression `foo(bar)` is rewritten as `ctx.foo(ctx.bar)`.
  factory BoundValueConverter.forView(
    CompileView view,
    o.Expression implicitReceiver,
  ) = _ViewBoundValueConverter;

  o.Expression convertSourceToExpression(
          ir.BindingSource source, o.OutputType type) =>
      source.accept(this, type);

  o.Expression _createI18nMessage(I18nMessage message);

  @override
  o.Expression visitBoundExpression(ir.BoundExpression boundExpression,
          [o.OutputType type]) =>
      convertCdExpressionToIr(
        _nameResolver,
        _implicitReceiver,
        boundExpression.expression,
        boundExpression.sourceSpan,
        _metadata,
        type,
      );

  @override
  o.Expression visitBoundI18nMessage(ir.BoundI18nMessage boundI18nMessage,
          [_]) =>
      _createI18nMessage(boundI18nMessage.value);

  @override
  o.Expression visitStringLiteral(ir.StringLiteral stringLiteral, [_]) =>
      o.literal(stringLiteral.value);
}

/// Converts values bound by a directive change detector.
class _DirectiveBoundValueConverter extends BoundValueConverter {
  _DirectiveBoundValueConverter(
    CompileDirectiveMetadata metadata,
    o.Expression implicitReceiver,
    NameResolver nameResolver,
  ) : super(metadata, implicitReceiver, nameResolver);

  @override
  o.Expression _createI18nMessage(I18nMessage message) {
    throw UnsupportedError(
        'Cannot create internationalized message expression without a view');
  }
}

// Converts values bound in a view.
class _ViewBoundValueConverter extends BoundValueConverter {
  final CompileView _view;

  _ViewBoundValueConverter(this._view, o.Expression implicitReceiver)
      : super(_view.component, implicitReceiver, _view.nameResolver);

  @override
  o.Expression _createI18nMessage(I18nMessage message) =>
      _view.createI18nMessage(message);
}
