import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import '../analyzed_class.dart' as analyzer;
import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../output/output_ast.dart' as o;
import '../template_ast.dart';
import '../view_compiler/compile_view.dart';
import 'expression_converter.dart' show convertCdExpressionToIr, NameResolver;

@alwaysThrows
void _throwUnrecognized(BoundValue value) {
  throw StateError('Unrecognized bound value: $value');
}

/// An abstract utility for converting bound values to output expressions.
abstract class BoundValueConverter {
  final analyzer.AnalyzedClass _analyzedClass;

  BoundValueConverter(this._analyzedClass);

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
  ) =>
      _DirectiveBoundValueConverter(metadata, implicitReceiver, nameResolver);

  /// Creates a bound value converter for expressions in a [view].
  ///
  /// The [implicitReceiver] is the receiver on which bound expressions are
  /// implicitly invoked. For example, if [implicitReceiver] is the variable
  /// `ctx`, the expression `foo(bar)` is rewritten as `ctx.foo(ctx.bar)`.
  factory BoundValueConverter.forView(
    CompileView view,
    o.Expression implicitReceiver,
  ) =>
      _ViewBoundValueConverter(view, implicitReceiver);

  /// Converts a bound [value] to an expression.
  ///
  /// The [sourceSpan] of [value] is used for reporting errors that may occur
  /// during expression conversion.
  ///
  /// The [propertyType] is the type of the property to which [value] is bound.
  o.Expression convertToExpression(
    BoundValue value,
    SourceSpan sourceSpan,
    o.OutputType propertyType,
  );

  /// Returns whether [value] can change during its lifetime.
  bool isImmutable(BoundValue value) {
    if (value is BoundExpression) {
      return analyzer.isImmutable(value.expression, _analyzedClass);
    } else if (value is BoundI18nMessage) {
      return true;
    }
    _throwUnrecognized(value);
  }

  /// Returns whether [value] can be null during its lifetime.
  bool isNullable(BoundValue value) {
    if (value is BoundExpression) {
      return analyzer.canBeNull(value.expression);
    } else if (value is BoundI18nMessage) {
      return false;
    }
    _throwUnrecognized(value);
  }

  /// Returns whether [value] is a string.
  bool isString(BoundValue value) {
    if (value is BoundExpression) {
      return analyzer.isString(value.expression, _analyzedClass);
    } else if (value is BoundI18nMessage) {
      return true;
    }
    _throwUnrecognized(value);
  }
}

/// Converts values bound by a directive change detector.
class _DirectiveBoundValueConverter extends BoundValueConverter {
  final o.Expression _implicitReceiver;
  final CompileDirectiveMetadata _metadata;
  final NameResolver _nameResolver;

  _DirectiveBoundValueConverter(
    this._metadata,
    this._implicitReceiver,
    this._nameResolver,
  ) : super(_metadata.analyzedClass);

  @override
  o.Expression convertToExpression(
    BoundValue value,
    SourceSpan sourceSpan,
    o.OutputType type,
  ) {
    if (value is BoundExpression) {
      return convertCdExpressionToIr(
        _nameResolver,
        _implicitReceiver,
        value.expression,
        sourceSpan,
        _metadata,
        type,
      );
    } else if (value is BoundI18nMessage) {
      throw UnsupportedError(
          'Cannot create internationalized message expression without a view');
    }
    _throwUnrecognized(value);
  }
}

// Converts values bound in a view.
class _ViewBoundValueConverter extends BoundValueConverter {
  final o.Expression _implicitReceiver;
  final CompileView _view;

  _ViewBoundValueConverter(this._view, this._implicitReceiver)
      : super(_view.component.analyzedClass);

  @override
  o.Expression convertToExpression(
    BoundValue value,
    SourceSpan sourceSpan,
    o.OutputType type,
  ) {
    if (value is BoundExpression) {
      final expression =
          analyzer.rewriteInterpolate(value.expression, _analyzedClass);
      return convertCdExpressionToIr(
        _view.nameResolver,
        _implicitReceiver,
        expression,
        sourceSpan,
        _view.component,
        type,
      );
    } else if (value is BoundI18nMessage) {
      return _view.createI18nMessage(value.message);
    }
    _throwUnrecognized(value);
  }
}
