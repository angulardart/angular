import 'package:analyzer/dart/element/element.dart';

import 'output/output_ast.dart';

/// A wrapper around [ClassElement] which exposes the functionality
/// needed for the view compiler to find types for expressions.
class AnalyzedClass {
  final ClassElement _classElement;

  AnalyzedClass(this._classElement);
}

// TODO(het): This only works for literals and simple property reads. Make this
// more robust. This should also support:
//   - static expressions (ExternalExpr)
//   - chained property read (eg a.b.c)
/// Returns [true] if [expression] is immutable.
bool isImmutable(
    Expression expression, Expression context, AnalyzedClass analyzedClass) {
  if (expression is LiteralExpr) return true;
  if (expression is ReadPropExpr) {
    if (analyzedClass == null) return false;
    if (expression.receiver == context &&
        // make sure the context is the Component
        context is ReadVarExpr &&
        context.name == '_ctx') {
      var field = analyzedClass._classElement.getField(expression.name);
      if (field != null) {
        return !field.isSynthetic && (field.isFinal || field.isConst);
      }
      var method = analyzedClass._classElement.getMethod(expression.name);
      if (method != null) {
        // methods are immutable
        return true;
      }
    }
    return false;
  }
  return false;
}
