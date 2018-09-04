import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import '../analyzed_class.dart' as analyzer;
import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../output/output_ast.dart' as o;
import '../template_ast.dart';
import 'constants.dart';
import 'expression_converter.dart' show convertCdExpressionToIr, NameResolver;

/// Returns an expression that binds a [value] of [type].
///
/// The [sourceSpan] of [value] is used for reporting any errors that may occur
/// during expression conversion.
///
/// The directive [metadata] provides compile-time information about the context
/// in which [value] is evaluated at run-time.
///
/// The [nameResolver] is used to resolve any references in the resulting
/// expression.
///
/// The [implicitReceiver], which is the receiver on which bound expressions are
/// evaluated at run-time, defaults to the host component instance, but can be
/// overridden if necessary.
o.Expression expressionForValue(
  BoundValue value,
  SourceSpan sourceSpan,
  CompileDirectiveMetadata metadata,
  NameResolver nameResolver,
  o.OutputType type, {
  o.Expression implicitReceiver,
}) {
  if (value is BoundExpression) {
    final rewrittenAst =
        analyzer.rewriteInterpolate(value.expression, metadata.analyzedClass);
    return convertCdExpressionToIr(
      nameResolver,
      implicitReceiver ?? DetectChangesVars.cachedCtx,
      rewrittenAst,
      sourceSpan,
      metadata,
      type,
    );
  } else if (value is BoundI18nMessage) {
    throw UnimplementedError();
  }
  _throwUnrecognized(value);
}

/// Returns whether [value] can change during its lifetime.
///
/// The directive [metadata] provides compile-time information about the context
/// in which [value] is evaluated at run-time.
bool isImmutable(BoundValue value, CompileDirectiveMetadata metadata) {
  if (value is BoundExpression) {
    return analyzer.isImmutable(value.expression, metadata.analyzedClass);
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

@alwaysThrows
void _throwUnrecognized(BoundValue value) {
  throw StateError('Unrecognized bound value: $value');
}
