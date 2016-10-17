import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "../chars.dart";
import "../expression_parser/ast.dart" as compiler_ast;
import "../identifiers.dart" show Identifiers;
import "../output/output_ast.dart" as o;

var IMPLICIT_RECEIVER = o.variable("#implicit");

abstract class NameResolver {
  o.Expression callPipe(
      String name, o.Expression input, List<o.Expression> args);
  o.Expression getLocal(String name);
  o.Expression createLiteralArray(List<o.Expression> values);
  o.Expression createLiteralMap(
      List<List<dynamic /* String | o . Expression */ >> values);
}

class ExpressionWithWrappedValueInfo {
  o.Expression expression;
  bool needsValueUnwrapper;
  ExpressionWithWrappedValueInfo(this.expression, this.needsValueUnwrapper);
}

ExpressionWithWrappedValueInfo convertCdExpressionToIr(
    NameResolver nameResolver,
    o.Expression implicitReceiver,
    compiler_ast.AST expression,
    o.ReadVarExpr valueUnwrapper,
    bool preserveWhitespace) {
  var visitor = new _AstToIrVisitor(
      nameResolver, implicitReceiver, valueUnwrapper, preserveWhitespace);
  o.Expression irAst = expression.visit(visitor, _Mode.Expression);
  return new ExpressionWithWrappedValueInfo(irAst, visitor.needsValueUnwrapper);
}

List<o.Statement> convertCdStatementToIr(
    NameResolver nameResolver,
    o.Expression implicitReceiver,
    compiler_ast.AST stmt,
    bool preserveWhitespace) {
  var visitor = new _AstToIrVisitor(
      nameResolver, implicitReceiver, null, preserveWhitespace);
  var statements = <o.Statement>[];
  flattenStatements(stmt.visit(visitor, _Mode.Statement), statements);
  return statements;
}

enum _Mode { Statement, Expression }
void ensureStatementMode(_Mode mode, compiler_ast.AST ast) {
  if (!identical(mode, _Mode.Statement)) {
    throw new BaseException('''Expected a statement, but saw ${ ast}''');
  }
}

void ensureExpressionMode(_Mode mode, compiler_ast.AST ast) {
  if (!identical(mode, _Mode.Expression)) {
    throw new BaseException('''Expected an expression, but saw ${ ast}''');
  }
}

dynamic /* o . Expression | o . Statement */ convertToStatementIfNeeded(
    _Mode mode, o.Expression expr) {
  if (identical(mode, _Mode.Statement)) {
    return expr.toStmt();
  } else {
    return expr;
  }
}

class _AstToIrVisitor implements compiler_ast.AstVisitor {
  final NameResolver _nameResolver;
  final o.Expression _implicitReceiver;
  final bool preserveWhitespace;
  o.ReadVarExpr _valueUnwrapper;
  bool needsValueUnwrapper = false;
  _AstToIrVisitor(this._nameResolver, this._implicitReceiver,
      this._valueUnwrapper, this.preserveWhitespace);
  dynamic visitBinary(compiler_ast.Binary ast, dynamic context) {
    _Mode mode = context;
    var op;
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
        throw new BaseException(
            '''Unsupported operation ${ ast . operation}''');
    }
    return convertToStatementIfNeeded(
        mode,
        new o.BinaryOperatorExpr(op, ast.left.visit(this, _Mode.Expression),
            ast.right.visit(this, _Mode.Expression)));
  }

  dynamic visitChain(compiler_ast.Chain ast, dynamic context) {
    _Mode mode = context;
    ensureStatementMode(mode, ast);
    return this.visitAll(ast.expressions as List<compiler_ast.AST>, mode);
  }

  dynamic visitConditional(compiler_ast.Conditional ast, dynamic context) {
    _Mode mode = context;
    o.Expression value = ast.condition.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(
        mode,
        value.conditional(ast.trueExp.visit(this, _Mode.Expression),
            ast.falseExp.visit(this, _Mode.Expression)));
  }

  dynamic visitPipe(compiler_ast.BindingPipe ast, dynamic context) {
    _Mode mode = context;
    var input = ast.exp.visit(this, _Mode.Expression);
    var args =
        this.visitAll(ast.args as List<compiler_ast.AST>, _Mode.Expression)
        as List<o.Expression>;
    var value = this._nameResolver.callPipe(ast.name, input, args);
    this.needsValueUnwrapper = true;
    return convertToStatementIfNeeded(
        mode, this._valueUnwrapper.callMethod("unwrap", [value]));
  }

  dynamic visitFunctionCall(compiler_ast.FunctionCall ast, dynamic context) {
    _Mode mode = context;
    return convertToStatementIfNeeded(
        mode,
        ast.target.visit(this, _Mode.Expression).callFn(this
            .visitAll(ast.args as List<compiler_ast.AST>, _Mode.Expression)));
  }

  dynamic visitIfNull(compiler_ast.IfNull ast, dynamic context) {
    _Mode mode = context;
    o.Expression value = ast.condition.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(
        mode, value.ifNull(ast.nullExp.visit(this, _Mode.Expression)));
  }

  dynamic visitImplicitReceiver(
      compiler_ast.ImplicitReceiver ast, dynamic context) {
    _Mode mode = context;
    ensureExpressionMode(mode, ast);
    return IMPLICIT_RECEIVER;
  }

  /// Trim text in preserve whitespace mode if it contains \n preceding or
  /// following an interpolation.
  String compressWhitespace(String value) {
    if (preserveWhitespace ||
        value.contains('\u00A0') ||
        value.contains(ngSpace) ||
        !value.contains('\n')) return replaceNgSpace(value);
    return replaceNgSpace(value.replaceAll('\n', '').trim());
  }

  dynamic visitInterpolation(compiler_ast.Interpolation ast, dynamic context) {
    _Mode mode = context;
    ensureExpressionMode(mode, ast);

    /// Handle most common case where prefix and postfix are empty.
    if (ast.expressions.length == 1 &&
        ast.strings[0].isEmpty &&
        ast.strings[1].isEmpty) {
      var args = <o.Expression>[
        ast.expressions[0].visit(this, _Mode.Expression)
      ];
      return o.importExpr(Identifiers.interpolate0).callFn(args);
    } else if (ast.expressions.length <= 2) {
      var args = <o.Expression>[];
      for (var i = 0, len = ast.strings.length - 1; i < len; i++) {
        String literalStr = compressWhitespace(replaceNgSpace(ast.strings[i]));
        args.add(o.literal(literalStr));
        args.add(ast.expressions[i].visit(this, _Mode.Expression));
      }
      args.add(
          o.literal(compressWhitespace(ast.strings[ast.strings.length - 1])));
      if (ast.expressions.length == 1)
        return o.importExpr(Identifiers.interpolate1).callFn(args);
      else
        return o.importExpr(Identifiers.interpolate2).callFn(args);
    } else {
      var args = [o.literal(ast.expressions.length)];
      for (var i = 0; i < ast.strings.length - 1; i++) {
        String literalStr = i == 0
            ? compressWhitespace(ast.strings[i])
            : replaceNgSpace(ast.strings[i]);
        args.add(o.literal(literalStr));
        args.add(ast.expressions[i].visit(this, _Mode.Expression));
      }
      args.add(
          o.literal(compressWhitespace(ast.strings[ast.strings.length - 1])));
      return o.importExpr(Identifiers.interpolate).callFn(args);
    }
  }

  dynamic visitKeyedRead(compiler_ast.KeyedRead ast, dynamic context) {
    _Mode mode = context;
    return convertToStatementIfNeeded(
        mode,
        ast.obj
            .visit(this, _Mode.Expression)
            .key(ast.key.visit(this, _Mode.Expression)));
  }

  dynamic visitKeyedWrite(compiler_ast.KeyedWrite ast, dynamic context) {
    _Mode mode = context;
    o.Expression obj = ast.obj.visit(this, _Mode.Expression);
    o.Expression key = ast.key.visit(this, _Mode.Expression);
    o.Expression value = ast.value.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(mode, obj.key(key).set(value));
  }

  dynamic visitLiteralArray(compiler_ast.LiteralArray ast, dynamic context) {
    _Mode mode = context;
    return convertToStatementIfNeeded(
        mode,
        _nameResolver.createLiteralArray(
            this.visitAll(ast.expressions as List<compiler_ast.AST>, mode)
            as List<o.Expression>));
  }

  dynamic visitLiteralMap(compiler_ast.LiteralMap ast, dynamic context) {
    _Mode mode = context;
    var parts = <List>[];
    for (var i = 0; i < ast.keys.length; i++) {
      parts.add([ast.keys[i], ast.values[i].visit(this, _Mode.Expression)]);
    }
    return convertToStatementIfNeeded(
        mode, this._nameResolver.createLiteralMap(parts));
  }

  dynamic visitLiteralPrimitive(
      compiler_ast.LiteralPrimitive ast, dynamic context) {
    _Mode mode = context;
    return convertToStatementIfNeeded(mode, o.literal(ast.value));
  }

  dynamic visitMethodCall(compiler_ast.MethodCall ast, dynamic context) {
    _Mode mode = context;
    var args =
        this.visitAll(ast.args as List<compiler_ast.AST>, _Mode.Expression)
        as List<o.Expression>;
    var result;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      var varExpr = this._nameResolver.getLocal(ast.name);
      if (varExpr != null) {
        result = varExpr.callFn(args);
      } else {
        receiver = this._implicitReceiver;
      }
    }
    if (result == null) {
      result = receiver.callMethod(ast.name, args);
    }
    return convertToStatementIfNeeded(mode, result);
  }

  dynamic visitPrefixNot(compiler_ast.PrefixNot ast, dynamic context) {
    _Mode mode = context;
    return convertToStatementIfNeeded(
        mode, o.not(ast.expression.visit(this, _Mode.Expression)));
  }

  dynamic visitPropertyRead(compiler_ast.PropertyRead ast, dynamic context) {
    _Mode mode = context;
    var result;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      result = this._nameResolver.getLocal(ast.name);
      if (result == null) {
        receiver = this._implicitReceiver;
      }
    }
    if (result == null) {
      result = receiver.prop(ast.name);
    }
    return convertToStatementIfNeeded(mode, result);
  }

  dynamic visitPropertyWrite(compiler_ast.PropertyWrite ast, dynamic context) {
    _Mode mode = context;
    o.Expression receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      var varExpr = this._nameResolver.getLocal(ast.name);
      if (varExpr != null) {
        throw new BaseException("Cannot assign to a reference or variable!");
      }
      receiver = this._implicitReceiver;
    }
    return convertToStatementIfNeeded(mode,
        receiver.prop(ast.name).set(ast.value.visit(this, _Mode.Expression)));
  }

  dynamic visitSafePropertyRead(
      compiler_ast.SafePropertyRead ast, dynamic context) {
    _Mode mode = context;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(mode,
        receiver.isBlank().conditional(o.NULL_EXPR, receiver.prop(ast.name)));
  }

  dynamic visitSafeMethodCall(
      compiler_ast.SafeMethodCall ast, dynamic context) {
    _Mode mode = context;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    var args =
        this.visitAll(ast.args as List<compiler_ast.AST>, _Mode.Expression);
    return convertToStatementIfNeeded(
        mode,
        receiver
            .isBlank()
            .conditional(o.NULL_EXPR, receiver.callMethod(ast.name, args)));
  }

  dynamic visitAll(List<compiler_ast.AST> asts, dynamic context) {
    _Mode mode = context;
    return asts.map((ast) => ast.visit(this, mode)).toList();
  }

  dynamic visitQuote(compiler_ast.Quote ast, dynamic context) {
    throw new BaseException("Quotes are not supported for evaluation!");
  }
}

void flattenStatements(dynamic arg, List<o.Statement> output) {
  if (arg is List) {
    arg.forEach((entry) => flattenStatements(entry, output));
  } else {
    output.add(arg);
  }
}
