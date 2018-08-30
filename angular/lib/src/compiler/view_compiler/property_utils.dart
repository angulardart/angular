import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import '../analyzed_class.dart' as analyzer;
import '../output/output_ast.dart' as o;
import '../template_ast.dart';
import 'compile_view.dart';
import 'constants.dart';
import 'expression_converter.dart';

/// Returns the expression of [type] that binds [value] in [view].
o.Expression expressionForValue(
  BoundValue value,
  SourceSpan sourceSpan,
  CompileView view,
  o.OutputType type,
) {
  if (value is BoundExpression) {
    final rewrittenAst = analyzer.rewriteInterpolate(
        value.expression, view.component.analyzedClass);
    return convertCdExpressionToIr(
      view.nameResolver,
      DetectChangesVars.cachedCtx,
      rewrittenAst,
      sourceSpan,
      view.component,
      type,
    );
  } else if (value is BoundI18nMessage) {
    throw UnimplementedError();
  }
  _throwUnrecognized(value);
}

/// Returns whether [value] bound in [view] can change during its lifetime.
bool isImmutable(BoundValue value, CompileView view) {
  if (value is BoundExpression) {
    return analyzer.isImmutable(value.expression, view.component.analyzedClass);
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
