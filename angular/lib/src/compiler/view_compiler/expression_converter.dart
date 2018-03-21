import 'package:angular/src/facade/exceptions.dart' show BaseException;

import '../analyzed_class.dart';
import '../chars.dart';
import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../expression_parser/ast.dart' as compiler_ast;
import '../identifiers.dart' show Identifiers;
import '../output/output_ast.dart' as o;

// TODO: Remove the following lines (for --no-implicit-casts).
// ignore_for_file: argument_type_not_assignable
// ignore_for_file: invalid_assignment
// ignore_for_file: list_element_type_not_assignable
// ignore_for_file: non_bool_operand
// ignore_for_file: return_of_invalid_type

var IMPLICIT_RECEIVER = o.variable("#implicit");

abstract class NameResolver {
  o.Expression callPipe(
      String name, o.Expression input, List<o.Expression> args);

  /// Returns a variable that references the [name] local.
  o.Expression getLocal(String name);

  /// Returns variable declarations for all locals used in this scope.
  List<o.Statement> getLocalDeclarations();

  /// Creates a closure that returns a list of [type] when [values] change.
  o.Expression createLiteralList(
    List<o.Expression> values, {
    o.OutputType type,
  });

  /// Creates a closure that returns a map of [type] when [values] change.
  o.Expression createLiteralMap(
    List<List<dynamic /* String | o.Expression */ >> values, {
    o.OutputType type,
  });

  int createUniqueBindIndex();

  /// Creates a name resolver with shared state for use in a new method scope.
  NameResolver scope();
}

/// Converts a bound [AST] expression to an [Expression].
///
/// If non-null, [boundType] is the type of the input to which [expression] is
/// bound. This is used to support empty expressions for boolean inputs, and to
/// type annotate collection literal bindings.
o.Expression convertCdExpressionToIr(
  NameResolver nameResolver,
  o.Expression implicitReceiver,
  compiler_ast.AST expression,
  CompileDirectiveMetadata metadata,
  o.OutputType boundType,
) {
  assert(nameResolver != null);
  var visitor =
      new _AstToIrVisitor(nameResolver, implicitReceiver, metadata, boundType);
  return expression.visit(visitor, _Mode.Expression);
}

List<o.Statement> convertCdStatementToIr(
  NameResolver nameResolver,
  o.Expression implicitReceiver,
  compiler_ast.AST stmt,
  CompileDirectiveMetadata metadata,
) {
  assert(nameResolver != null);
  var visitor =
      new _AstToIrVisitor(nameResolver, implicitReceiver, metadata, null);
  var statements = <o.Statement>[];
  flattenStatements(stmt.visit(visitor, _Mode.Statement), statements);
  return statements;
}

enum _Mode { Statement, Expression }

void ensureStatementMode(_Mode mode, compiler_ast.AST ast) {
  if (!identical(mode, _Mode.Statement)) {
    throw new BaseException('Expected a statement, but saw $ast');
  }
}

void ensureExpressionMode(_Mode mode, compiler_ast.AST ast) {
  if (!identical(mode, _Mode.Expression)) {
    throw new BaseException('Expected an expression, but saw $ast');
  }
}

dynamic /* o.Expression | o.Statement */ convertToStatementIfNeeded(
    _Mode mode, o.Expression expr) {
  if (identical(mode, _Mode.Statement)) {
    return expr.toStmt();
  } else {
    return expr;
  }
}

class _AstToIrVisitor implements compiler_ast.AstVisitor<dynamic, _Mode> {
  final NameResolver _nameResolver;
  final o.Expression _implicitReceiver;
  final CompileDirectiveMetadata _metadata;

  /// The type to which this expression is bound.
  ///
  /// This is used to support empty expressions for booleans bindings, and type
  /// pure proxy fields for collection literals.
  final o.OutputType _boundType;

  /// Whether the current AST is the root of the expression.
  ///
  /// This is used to indicate whether [_boundType] can be used to type pure
  /// proxy fields for collection literals.
  bool _visitingRoot;

  _AstToIrVisitor(
    this._nameResolver,
    this._implicitReceiver,
    this._metadata,
    this._boundType,
  ) : _visitingRoot = true {
    assert(_nameResolver != null);
  }

  dynamic visitBinary(compiler_ast.Binary ast, _Mode mode) {
    _visitingRoot = false;
    o.BinaryOperator op;
    switch (ast.operation) {
      case "+":
        op = o.BinaryOperator.Plus;
        break;
      case "-":
        op = o.BinaryOperator.Minus;
        break;
      case "*":
        op = o.BinaryOperator.Multiply;
        break;
      case "/":
        op = o.BinaryOperator.Divide;
        break;
      case "%":
        op = o.BinaryOperator.Modulo;
        break;
      case "&&":
        op = o.BinaryOperator.And;
        break;
      case "||":
        op = o.BinaryOperator.Or;
        break;
      case "==":
        op = o.BinaryOperator.Equals;
        break;
      case "!=":
        op = o.BinaryOperator.NotEquals;
        break;
      case "===":
        op = o.BinaryOperator.Identical;
        break;
      case "!==":
        op = o.BinaryOperator.NotIdentical;
        break;
      case "<":
        op = o.BinaryOperator.Lower;
        break;
      case ">":
        op = o.BinaryOperator.Bigger;
        break;
      case "<=":
        op = o.BinaryOperator.LowerEquals;
        break;
      case ">=":
        op = o.BinaryOperator.BiggerEquals;
        break;
      default:
        throw new BaseException('Unsupported operation ${ast.operation}');
    }
    return convertToStatementIfNeeded(
        mode,
        new o.BinaryOperatorExpr(op, ast.left.visit(this, _Mode.Expression),
            ast.right.visit(this, _Mode.Expression)));
  }

  dynamic visitChain(compiler_ast.Chain ast, _Mode mode) {
    _visitingRoot = false;
    ensureStatementMode(mode, ast);
    return visitAll(ast.expressions, mode);
  }

  dynamic visitConditional(compiler_ast.Conditional ast, _Mode mode) {
    _visitingRoot = false;
    o.Expression value = ast.condition.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(
        mode,
        value.conditional(ast.trueExp.visit(this, _Mode.Expression),
            ast.falseExp.visit(this, _Mode.Expression)));
  }

  dynamic visitEmptyExpr(compiler_ast.EmptyExpr ast, _Mode mode) {
    final value = _isBoolType(_boundType)
        ? new o.LiteralExpr(true, o.BOOL_TYPE)
        : new o.LiteralExpr('', o.STRING_TYPE);
    return convertToStatementIfNeeded(mode, value);
  }

  dynamic visitPipe(compiler_ast.BindingPipe ast, _Mode mode) {
    _visitingRoot = false;
    var input = ast.exp.visit(this, _Mode.Expression);
    var args = visitAll(ast.args, _Mode.Expression) as List<o.Expression>;
    var value = _nameResolver.callPipe(ast.name, input, args);
    return convertToStatementIfNeeded(mode, value);
  }

  dynamic visitFunctionCall(compiler_ast.FunctionCall ast, _Mode mode) {
    _visitingRoot = false;
    return convertToStatementIfNeeded(
        mode,
        ast.target
            .visit(this, _Mode.Expression)
            .callFn(visitAll(ast.args, _Mode.Expression)));
  }

  dynamic visitIfNull(compiler_ast.IfNull ast, _Mode mode) {
    _visitingRoot = false;
    o.Expression value = ast.condition.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(
        mode, value.ifNull(ast.nullExp.visit(this, _Mode.Expression)));
  }

  dynamic visitImplicitReceiver(compiler_ast.ImplicitReceiver ast, _Mode mode) {
    _visitingRoot = false;
    ensureExpressionMode(mode, ast);
    return IMPLICIT_RECEIVER;
  }

  /// Trim text in preserve whitespace mode if it contains \n preceding
  /// interpolation.
  String compressWhitespacePreceding(String value) {
    if (_metadata.template.preserveWhitespace ||
        value.contains('\u00A0') ||
        value.contains(ngSpace) ||
        !value.contains('\n')) return replaceNgSpace(value);
    return replaceNgSpace(value.replaceAll('\n', '').trimLeft());
  }

  /// Trim text in preserve whitespace mode if it contains \n following
  /// interpolation.
  String compressWhitespaceFollowing(String value) {
    if (_metadata.template.preserveWhitespace ||
        value.contains('\u00A0') ||
        value.contains(ngSpace) ||
        !value.contains('\n')) return replaceNgSpace(value);
    return replaceNgSpace(value.replaceAll('\n', '').trimRight());
  }

  dynamic visitInterpolation(compiler_ast.Interpolation ast, _Mode mode) {
    _visitingRoot = false;
    ensureExpressionMode(mode, ast);

    /// Handle most common case where prefix and postfix are empty.
    if (ast.expressions.length == 1) {
      String firstArg = compressWhitespacePreceding(ast.strings[0]);
      String secondArg = compressWhitespaceFollowing(ast.strings[1]);
      if (firstArg.isEmpty && secondArg.isEmpty) {
        var args = <o.Expression>[
          ast.expressions[0].visit(this, _Mode.Expression)
        ];
        return o.importExpr(Identifiers.interpolate[0]).callFn(args);
      } else {
        var args = <o.Expression>[
          o.literal(firstArg),
          ast.expressions[0].visit(this, _Mode.Expression),
          o.literal(secondArg),
        ];
        return o.importExpr(Identifiers.interpolate[1]).callFn(args);
      }
    } else {
      var args = <o.Expression>[];
      for (var i = 0; i < ast.strings.length - 1; i++) {
        String literalText = i == 0
            ? compressWhitespacePreceding(ast.strings[i])
            : replaceNgSpace(ast.strings[i]);
        args.add(o.literal(literalText));
        args.add(ast.expressions[i].visit(this, _Mode.Expression));
      }
      args.add(o.literal(
          compressWhitespaceFollowing(ast.strings[ast.strings.length - 1])));
      return o
          .importExpr(Identifiers.interpolate[ast.expressions.length])
          .callFn(args);
    }
  }

  dynamic visitKeyedRead(compiler_ast.KeyedRead ast, _Mode mode) {
    _visitingRoot = false;
    return convertToStatementIfNeeded(
        mode,
        ast.obj
            .visit(this, _Mode.Expression)
            .key(ast.key.visit(this, _Mode.Expression)));
  }

  dynamic visitKeyedWrite(compiler_ast.KeyedWrite ast, _Mode mode) {
    _visitingRoot = false;
    o.Expression obj = ast.obj.visit(this, _Mode.Expression);
    o.Expression key = ast.key.visit(this, _Mode.Expression);
    o.Expression value = ast.value.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(mode, obj.key(key).set(value));
  }

  dynamic visitLiteralArray(compiler_ast.LiteralArray ast, _Mode mode) {
    final isRootExpression = _visitingRoot;
    _visitingRoot = false;
    return convertToStatementIfNeeded(
      mode,
      _nameResolver.createLiteralList(
          visitAll(ast.expressions, mode) as List<o.Expression>,
          type: isRootExpression ? _boundType : null),
    );
  }

  dynamic visitLiteralMap(compiler_ast.LiteralMap ast, _Mode mode) {
    final isRootExpression = _visitingRoot;
    _visitingRoot = false;
    var parts = <List>[];
    for (var i = 0; i < ast.keys.length; i++) {
      parts.add([ast.keys[i], ast.values[i].visit(this, _Mode.Expression)]);
    }
    return convertToStatementIfNeeded(
        mode,
        _nameResolver.createLiteralMap(parts,
            type: isRootExpression ? _boundType : null));
  }

  dynamic visitLiteralPrimitive(compiler_ast.LiteralPrimitive ast, _Mode mode) {
    _visitingRoot = false;
    return convertToStatementIfNeeded(mode, o.literal(ast.value));
  }

  dynamic visitMethodCall(compiler_ast.MethodCall ast, _Mode mode) {
    _visitingRoot = false;
    var args = visitAll(ast.args, _Mode.Expression) as List<o.Expression>;
    o.Expression result;
    o.Expression receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      var varExpr = _nameResolver.getLocal(ast.name);
      if (varExpr != null) {
        result = varExpr.callFn(args);
      } else {
        receiver = _getImplicitOrStaticReceiver(ast.name, isStaticMethod);
      }
    }
    result ??= receiver.callMethod(ast.name, args);
    return convertToStatementIfNeeded(mode, result);
  }

  dynamic visitPrefixNot(compiler_ast.PrefixNot ast, _Mode mode) {
    _visitingRoot = false;
    return convertToStatementIfNeeded(
        mode, o.not(ast.expression.visit(this, _Mode.Expression)));
  }

  dynamic visitPropertyRead(compiler_ast.PropertyRead ast, _Mode mode) {
    _visitingRoot = false;
    o.Expression result;
    o.Expression receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      result = _nameResolver.getLocal(ast.name);
      if (result == null) {
        receiver = _getImplicitOrStaticReceiver(ast.name, isStaticGetter);
      }
    }
    result ??= receiver.prop(ast.name);
    return convertToStatementIfNeeded(mode, result);
  }

  dynamic visitPropertyWrite(compiler_ast.PropertyWrite ast, _Mode mode) {
    _visitingRoot = false;
    o.Expression receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      var varExpr = _nameResolver.getLocal(ast.name);
      if (varExpr != null) {
        throw new BaseException("Cannot assign to a reference or variable!");
      }
      receiver = _getImplicitOrStaticReceiver(ast.name, isStaticSetter);
    }
    return convertToStatementIfNeeded(mode,
        receiver.prop(ast.name).set(ast.value.visit(this, _Mode.Expression)));
  }

  dynamic visitSafePropertyRead(compiler_ast.SafePropertyRead ast, _Mode mode) {
    _visitingRoot = false;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(mode,
        receiver.isBlank().conditional(o.NULL_EXPR, receiver.prop(ast.name)));
  }

  dynamic visitSafeMethodCall(compiler_ast.SafeMethodCall ast, _Mode mode) {
    _visitingRoot = false;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    var args = visitAll(ast.args, _Mode.Expression);
    return convertToStatementIfNeeded(
        mode,
        receiver
            .isBlank()
            .conditional(o.NULL_EXPR, receiver.callMethod(ast.name, args)));
  }

  dynamic visitStaticRead(compiler_ast.StaticRead ast, _Mode mode) {
    _visitingRoot = false;
    return convertToStatementIfNeeded(
        mode, o.importExpr(ast.id.identifier, isConst: true));
  }

  dynamic visitAll(List<compiler_ast.AST> asts, _Mode mode) {
    return asts.map((ast) => ast.visit(this, mode)).toList();
  }

  /// Returns the receiver necessary to access [memberName].
  ///
  /// If [memberName] is a static member of the current view's component,
  /// determined by the predicate [isStaticMember], the static receiver is
  /// returned. Otherwise the implicit receiver is returned.
  o.Expression _getImplicitOrStaticReceiver(
    String memberName,
    bool Function(String, AnalyzedClass) isStaticMember,
  ) {
    return isStaticMember(memberName, _metadata.analyzedClass)
        ? o.importExpr(_metadata.identifier)
        : _implicitReceiver;
  }
}

void flattenStatements(dynamic arg, List<o.Statement> output) {
  if (arg is List) {
    for (var entry in arg) {
      flattenStatements(entry, output);
    }
  } else {
    output.add(arg);
  }
}

bool _isBoolType(o.OutputType type) {
  if (type == o.BOOL_TYPE) return true;
  if (type is o.ExternalType) {
    String name = type.value.name;
    return 'bool' == name.trim();
  }
  return false;
}
