import 'package:analyzer/dart/element/element.dart';

import 'package:source_gen/src/type_checker.dart';
import 'expression_parser/ast.dart' as ast;

final stringTypeChecker = new TypeChecker.fromRuntime(String);

/// A wrapper around [ClassElement] which exposes the functionality
/// needed for the view compiler to find types for expressions.
class AnalyzedClass {
  final ClassElement _classElement;

  /// Whether this class has mock-like behavior.
  ///
  /// The heuristic used to determine mock-like behavior is if the analyzed
  /// class or one of its ancestors, other than [Object], implements
  /// [noSuchMethod].
  final bool isMockLike;

  AnalyzedClass(
    this._classElement, {
    this.isMockLike: false,
  });
}

// TODO(het): Make this work with chained expressions.
/// Returns [true] if [expression] is immutable.
bool isImmutable(ast.AST expression, AnalyzedClass analyzedClass) {
  if (expression is ast.ASTWithSource) {
    expression = (expression as ast.ASTWithSource).ast;
  }
  if (expression is ast.LiteralPrimitive ||
      expression is ast.StaticRead ||
      expression is ast.EmptyExpr) {
    return true;
  }
  if (expression is ast.IfNull) {
    return isImmutable(expression.condition, analyzedClass) &&
        isImmutable(expression.nullExp, analyzedClass);
  }
  if (expression is ast.Interpolation) {
    return expression.expressions.every((e) => isImmutable(e, analyzedClass));
  }
  if (expression is ast.PropertyRead) {
    if (analyzedClass == null) return false;
    if (expression.receiver is ast.ImplicitReceiver) {
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

// TODO(het): preserve any source info in the new expression
/// If this interpolation can be optimized, returns the optimized expression.
/// Otherwise, returns the original expression.
///
/// An example of an interpolation that can be optimized is `{{foo}}` where
/// `foo` is a getter on the class that is known to return a [String]. This can
/// be rewritten as just `foo`.
ast.AST rewriteInterpolate(ast.AST original, AnalyzedClass analyzedClass) {
  ast.AST unwrappedExpression = original;
  if (original is ast.ASTWithSource) {
    unwrappedExpression = original.ast;
  }
  if (unwrappedExpression is! ast.Interpolation) return original;
  ast.Interpolation interpolation = unwrappedExpression;
  if (interpolation.expressions.length == 1 &&
      interpolation.strings[0].isEmpty &&
      interpolation.strings[1].isEmpty) {
    ast.AST expression = interpolation.expressions.single;
    if (expression is ast.LiteralPrimitive) {
      return new ast.LiteralPrimitive(
          expression.value == null ? '' : '${expression.value}');
    }
    if (expression is ast.PropertyRead) {
      if (analyzedClass == null) return original;
      if (expression.receiver is ast.ImplicitReceiver) {
        var field = analyzedClass._classElement.getField(expression.name);
        if (field != null) {
          if (stringTypeChecker.isExactlyType(field.type)) {
            return new ast.IfNull(expression, new ast.LiteralPrimitive(''));
          }
        }
      }
    }
  }
  return original;
}

/// Returns [true] if [expression] could be [null].
bool canBeNull(ast.AST expression) {
  if (expression is ast.ASTWithSource) {
    expression = (expression as ast.ASTWithSource).ast;
  }
  if (expression is ast.LiteralPrimitive ||
      expression is ast.EmptyExpr ||
      expression is ast.Interpolation) {
    return false;
  }
  if (expression is ast.IfNull) {
    if (!canBeNull(expression.condition)) return false;
    return canBeNull(expression.nullExp);
  }
  return true;
}
