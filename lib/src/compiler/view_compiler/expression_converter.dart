import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show isBlank, isPresent, isArray;

import "../expression_parser/ast.dart" as cdAst;
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
  ExpressionWithWrappedValueInfo(this.expression, this.needsValueUnwrapper) {}
}

ExpressionWithWrappedValueInfo convertCdExpressionToIr(
    NameResolver nameResolver,
    o.Expression implicitReceiver,
    cdAst.AST expression,
    o.ReadVarExpr valueUnwrapper) {
  var visitor =
      new _AstToIrVisitor(nameResolver, implicitReceiver, valueUnwrapper);
  o.Expression irAst = expression.visit(visitor, _Mode.Expression);
  return new ExpressionWithWrappedValueInfo(irAst, visitor.needsValueUnwrapper);
}

List<o.Statement> convertCdStatementToIr(
    NameResolver nameResolver, o.Expression implicitReceiver, cdAst.AST stmt) {
  var visitor = new _AstToIrVisitor(nameResolver, implicitReceiver, null);
  var statements = <o.Statement>[];
  flattenStatements(stmt.visit(visitor, _Mode.Statement), statements);
  return statements;
}

enum _Mode { Statement, Expression }
ensureStatementMode(_Mode mode, cdAst.AST ast) {
  if (!identical(mode, _Mode.Statement)) {
    throw new BaseException('''Expected a statement, but saw ${ ast}''');
  }
}

ensureExpressionMode(_Mode mode, cdAst.AST ast) {
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

class _AstToIrVisitor implements cdAst.AstVisitor {
  NameResolver _nameResolver;
  o.Expression _implicitReceiver;
  o.ReadVarExpr _valueUnwrapper;
  bool needsValueUnwrapper = false;
  _AstToIrVisitor(
      this._nameResolver, this._implicitReceiver, this._valueUnwrapper) {}
  dynamic visitBinary(cdAst.Binary ast, dynamic context) {
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

  dynamic visitChain(cdAst.Chain ast, dynamic context) {
    _Mode mode = context;
    ensureStatementMode(mode, ast);
    return this.visitAll(ast.expressions as List<cdAst.AST>, mode);
  }

  dynamic visitConditional(cdAst.Conditional ast, dynamic context) {
    _Mode mode = context;
    o.Expression value = ast.condition.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(
        mode,
        value.conditional(ast.trueExp.visit(this, _Mode.Expression),
            ast.falseExp.visit(this, _Mode.Expression)));
  }

  dynamic visitPipe(cdAst.BindingPipe ast, dynamic context) {
    _Mode mode = context;
    var input = ast.exp.visit(this, _Mode.Expression);
    var args = this.visitAll(ast.args as List<cdAst.AST>, _Mode.Expression)
        as List<o.Expression>;
    var value = this._nameResolver.callPipe(ast.name, input, args);
    this.needsValueUnwrapper = true;
    return convertToStatementIfNeeded(
        mode, this._valueUnwrapper.callMethod("unwrap", [value]));
  }

  dynamic visitFunctionCall(cdAst.FunctionCall ast, dynamic context) {
    _Mode mode = context;
    return convertToStatementIfNeeded(
        mode,
        ast.target.visit(this, _Mode.Expression).callFn(
            this.visitAll(ast.args as List<cdAst.AST>, _Mode.Expression)));
  }

  dynamic visitImplicitReceiver(cdAst.ImplicitReceiver ast, dynamic context) {
    _Mode mode = context;
    ensureExpressionMode(mode, ast);
    return IMPLICIT_RECEIVER;
  }

  dynamic visitInterpolation(cdAst.Interpolation ast, dynamic context) {
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
    } else {
      var args = [o.literal(ast.expressions.length)];
      for (var i = 0; i < ast.strings.length - 1; i++) {
        args.add(o.literal(ast.strings[i]));
        args.add(ast.expressions[i].visit(this, _Mode.Expression));
      }
      args.add(o.literal(ast.strings[ast.strings.length - 1]));
      return o.importExpr(Identifiers.interpolate).callFn(args);
    }
  }

  dynamic visitKeyedRead(cdAst.KeyedRead ast, dynamic context) {
    _Mode mode = context;
    return convertToStatementIfNeeded(
        mode,
        ast.obj
            .visit(this, _Mode.Expression)
            .key(ast.key.visit(this, _Mode.Expression)));
  }

  dynamic visitKeyedWrite(cdAst.KeyedWrite ast, dynamic context) {
    _Mode mode = context;
    o.Expression obj = ast.obj.visit(this, _Mode.Expression);
    o.Expression key = ast.key.visit(this, _Mode.Expression);
    o.Expression value = ast.value.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(mode, obj.key(key).set(value));
  }

  dynamic visitLiteralArray(cdAst.LiteralArray ast, dynamic context) {
    _Mode mode = context;
    return convertToStatementIfNeeded(
        mode,
        _nameResolver.createLiteralArray(
            this.visitAll(ast.expressions as List<cdAst.AST>, mode)
            as List<o.Expression>));
  }

  dynamic visitLiteralMap(cdAst.LiteralMap ast, dynamic context) {
    _Mode mode = context;
    var parts = <List>[];
    for (var i = 0; i < ast.keys.length; i++) {
      parts.add([ast.keys[i], ast.values[i].visit(this, _Mode.Expression)]);
    }
    return convertToStatementIfNeeded(
        mode, this._nameResolver.createLiteralMap(parts));
  }

  dynamic visitLiteralPrimitive(cdAst.LiteralPrimitive ast, dynamic context) {
    _Mode mode = context;
    return convertToStatementIfNeeded(mode, o.literal(ast.value));
  }

  dynamic visitMethodCall(cdAst.MethodCall ast, dynamic context) {
    _Mode mode = context;
    var args = this.visitAll(ast.args as List<cdAst.AST>, _Mode.Expression)
        as List<o.Expression>;
    var result = null;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      var varExpr = this._nameResolver.getLocal(ast.name);
      if (isPresent(varExpr)) {
        result = varExpr.callFn(args);
      } else {
        receiver = this._implicitReceiver;
      }
    }
    if (isBlank(result)) {
      result = receiver.callMethod(ast.name, args);
    }
    return convertToStatementIfNeeded(mode, result);
  }

  dynamic visitPrefixNot(cdAst.PrefixNot ast, dynamic context) {
    _Mode mode = context;
    return convertToStatementIfNeeded(
        mode, o.not(ast.expression.visit(this, _Mode.Expression)));
  }

  dynamic visitPropertyRead(cdAst.PropertyRead ast, dynamic context) {
    _Mode mode = context;
    var result = null;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      result = this._nameResolver.getLocal(ast.name);
      if (isBlank(result)) {
        receiver = this._implicitReceiver;
      }
    }
    if (isBlank(result)) {
      result = receiver.prop(ast.name);
    }
    return convertToStatementIfNeeded(mode, result);
  }

  dynamic visitPropertyWrite(cdAst.PropertyWrite ast, dynamic context) {
    _Mode mode = context;
    o.Expression receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      var varExpr = this._nameResolver.getLocal(ast.name);
      if (isPresent(varExpr)) {
        throw new BaseException("Cannot assign to a reference or variable!");
      }
      receiver = this._implicitReceiver;
    }
    return convertToStatementIfNeeded(mode,
        receiver.prop(ast.name).set(ast.value.visit(this, _Mode.Expression)));
  }

  dynamic visitSafePropertyRead(cdAst.SafePropertyRead ast, dynamic context) {
    _Mode mode = context;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(mode,
        receiver.isBlank().conditional(o.NULL_EXPR, receiver.prop(ast.name)));
  }

  dynamic visitSafeMethodCall(cdAst.SafeMethodCall ast, dynamic context) {
    _Mode mode = context;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    var args = this.visitAll(ast.args as List<cdAst.AST>, _Mode.Expression);
    return convertToStatementIfNeeded(
        mode,
        receiver
            .isBlank()
            .conditional(o.NULL_EXPR, receiver.callMethod(ast.name, args)));
  }

  dynamic visitAll(List<cdAst.AST> asts, dynamic context) {
    _Mode mode = context;
    return asts.map((ast) => ast.visit(this, mode)).toList();
  }

  dynamic visitQuote(cdAst.Quote ast, dynamic context) {
    throw new BaseException("Quotes are not supported for evaluation!");
  }
}

flattenStatements(dynamic arg, List<o.Statement> output) {
  if (isArray(arg)) {
    ((arg as List<dynamic>))
        .forEach((entry) => flattenStatements(entry, output));
  } else {
    output.add(arg);
  }
}
