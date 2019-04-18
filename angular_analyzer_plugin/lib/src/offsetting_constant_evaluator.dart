import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart' as ast_utils;

/// An AST-based constant evaluator that inserts whitespace to preserve offsets.
///
/// Evaluates an AST via dart constant semantics, inserting whitespace so that
/// the result can be analyzed and offsets in that result match the offsets of
/// the code.
///
/// Example:
///   input:  'adjacent' 'strings' + 'with' + 'addition'
///   output: 'adjacent   strings     with     addition'
///
/// Now we can highlight any arbitrary source range in the output as erroneous,
/// and it will match the offset of what the user wrote.
///
/// Note that AST-evaluation is incomplete. Users may reference variables from
/// the file or even other files. True constant evaluation therefore requires
/// a resolved AST.
///
/// Example:
///   const before = 'foo';
///   ...
///   ... template: after + 'and $before' * 3;
///   ...
///   const after = 'bar';
///
/// In this case we report [offsetsAreValid] is false at the end of evaluation.
/// When false, it means we could not cleanly map the constant value to a string
/// for error reporting. (in the case above, it is impossible, as the beginning
/// of the string would have to come at the end and vice versa).
///
/// In theory we could produce a mapping that handles these harder cases,
/// however, it is enough to report to users that they will not get IDE support
/// for their design.
class OffsettingConstantEvaluator extends ast_utils.ConstantEvaluator {
  bool offsetsAreValid = true;
  Object value;
  ast.AstNode lastUnoffsettableNode;

  @override
  Object visitAdjacentStrings(ast.AdjacentStrings node) {
    final buffer = StringBuffer();
    int lastEndingOffset;
    for (final string in node.strings) {
      final value = string.accept(this);
      if (identical(value, ast_utils.ConstantEvaluator.NOT_A_CONSTANT)) {
        return value;
      }
      // preserve offsets across the split by padding
      if (lastEndingOffset != null) {
        buffer.write(' ' * (string.offset - lastEndingOffset));
      }
      lastEndingOffset = string.offset + string.length;
      buffer.write(value);
    }
    return buffer.toString();
  }

  @override
  Object visitBinaryExpression(ast.BinaryExpression node) {
    if (node.operator.type == TokenType.PLUS) {
      // ignore: omit_local_variable_types
      final Object leftOperand = node.leftOperand.accept(this);
      if (identical(leftOperand, ast_utils.ConstantEvaluator.NOT_A_CONSTANT)) {
        return leftOperand;
      }
      // ignore: omit_local_variable_types
      final Object rightOperand = node.rightOperand.accept(this);
      if (identical(rightOperand, ast_utils.ConstantEvaluator.NOT_A_CONSTANT)) {
        return rightOperand;
      }
      // numeric or {@code null}
      if (leftOperand is String && rightOperand is String) {
        final gap = node.rightOperand.offset -
            node.leftOperand.offset -
            node.leftOperand.length;
        // ignore: prefer_interpolation_to_compose_strings
        return leftOperand + (' ' * gap) + rightOperand;
      }
    }

    return super.visitBinaryExpression(node);
  }

  @override
  Object visitMethodInvocation(ast.MethodInvocation node) {
    offsetsAreValid = false;
    lastUnoffsettableNode = node;
    return super.visitMethodInvocation(node);
  }

  @override
  Object visitParenthesizedExpression(ast.ParenthesizedExpression node) {
    offsetsAreValid = false;
    lastUnoffsettableNode = node;
    final preGap = node.expression.offset - node.offset;
    final postGap = node.offset +
        node.length -
        node.expression.offset -
        node.expression.length;
    // ignore: omit_local_variable_types
    final Object value = super.visitParenthesizedExpression(node);
    if (value is String) {
      // ignore: prefer_interpolation_to_compose_strings
      return ' ' * preGap + value + ' ' * postGap;
    }

    return value;
  }

  @override
  Object visitPrefixedIdentifier(ast.PrefixedIdentifier node) {
    offsetsAreValid = false;
    lastUnoffsettableNode = node;
    return super.visitPrefixedIdentifier(node);
  }

  @override
  Object visitPropertyAccess(ast.PropertyAccess node) {
    offsetsAreValid = false;
    lastUnoffsettableNode = node;
    return super.visitPropertyAccess(node);
  }

  @override
  Object visitSimpleIdentifier(ast.SimpleIdentifier node) {
    offsetsAreValid = false;
    lastUnoffsettableNode = node;
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitSimpleStringLiteral(ast.SimpleStringLiteral node) {
    final gap = node.contentsOffset - node.offset;
    lastUnoffsettableNode = node;
    // ignore: prefer_interpolation_to_compose_strings
    return ' ' * gap + node.value + ' ';
  }

  @override
  Object visitStringInterpolation(ast.StringInterpolation node) {
    offsetsAreValid = false;
    lastUnoffsettableNode = node;
    return super.visitStringInterpolation(node);
  }
}
