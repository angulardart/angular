library angular2.src.compiler.view_compiler.expression_converter;

import "../expression_parser/ast.dart" as cdAst;
import "../output/output_ast.dart" as o;
import "../identifiers.dart" show Identifiers;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show isBlank, isPresent, isArray;

var IMPLICIT_RECEIVER = o.variable("#implicit");

abstract class NameResolver {
  o.Expression createPipe(String name);
  o.Expression getVariable(String name);
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
  var statements = [];
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
  dynamic visitBinary(cdAst.Binary ast, _Mode mode) {
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

  dynamic visitChain(cdAst.Chain ast, _Mode mode) {
    ensureStatementMode(mode, ast);
    return this.visitAll(ast.expressions, mode);
  }

  dynamic visitConditional(cdAst.Conditional ast, _Mode mode) {
    o.Expression value = ast.condition.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(
        mode,
        value.conditional(ast.trueExp.visit(this, _Mode.Expression),
            ast.falseExp.visit(this, _Mode.Expression)));
  }

  dynamic visitPipe(cdAst.BindingPipe ast, _Mode mode) {
    var pipeInstance = this._nameResolver.createPipe(ast.name);
    var input = ast.exp.visit(this, _Mode.Expression);
    var args = this.visitAll(ast.args, _Mode.Expression);
    this.needsValueUnwrapper = true;
    return convertToStatementIfNeeded(
        mode,
        this._valueUnwrapper.callMethod("unwrap", [
          pipeInstance.callMethod("transform", [input, o.literalArr(args)])
        ]));
  }

  dynamic visitFunctionCall(cdAst.FunctionCall ast, _Mode mode) {
    return convertToStatementIfNeeded(
        mode,
        ast.target
            .visit(this, _Mode.Expression)
            .callFn(this.visitAll(ast.args, _Mode.Expression)));
  }

  dynamic visitImplicitReceiver(cdAst.ImplicitReceiver ast, _Mode mode) {
    ensureExpressionMode(mode, ast);
    return IMPLICIT_RECEIVER;
  }

  dynamic visitInterpolation(cdAst.Interpolation ast, _Mode mode) {
    ensureExpressionMode(mode, ast);
    var args = [o.literal(ast.expressions.length)];
    for (var i = 0; i < ast.strings.length - 1; i++) {
      args.add(o.literal(ast.strings[i]));
      args.add(ast.expressions[i].visit(this, _Mode.Expression));
    }
    args.add(o.literal(ast.strings[ast.strings.length - 1]));
    return o.importExpr(Identifiers.interpolate).callFn(args);
  }

  dynamic visitKeyedRead(cdAst.KeyedRead ast, _Mode mode) {
    return convertToStatementIfNeeded(
        mode,
        ast.obj
            .visit(this, _Mode.Expression)
            .key(ast.key.visit(this, _Mode.Expression)));
  }

  dynamic visitKeyedWrite(cdAst.KeyedWrite ast, _Mode mode) {
    o.Expression obj = ast.obj.visit(this, _Mode.Expression);
    o.Expression key = ast.key.visit(this, _Mode.Expression);
    o.Expression value = ast.value.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(mode, obj.key(key).set(value));
  }

  dynamic visitLiteralArray(cdAst.LiteralArray ast, _Mode mode) {
    return convertToStatementIfNeeded(
        mode,
        this
            ._nameResolver
            .createLiteralArray(this.visitAll(ast.expressions, mode)));
  }

  dynamic visitLiteralMap(cdAst.LiteralMap ast, _Mode mode) {
    var parts = [];
    for (var i = 0; i < ast.keys.length; i++) {
      parts.add([ast.keys[i], ast.values[i].visit(this, _Mode.Expression)]);
    }
    return convertToStatementIfNeeded(
        mode, this._nameResolver.createLiteralMap(parts));
  }

  dynamic visitLiteralPrimitive(cdAst.LiteralPrimitive ast, _Mode mode) {
    return convertToStatementIfNeeded(mode, o.literal(ast.value));
  }

  dynamic visitMethodCall(cdAst.MethodCall ast, _Mode mode) {
    var args = this.visitAll(ast.args, _Mode.Expression);
    var result = null;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      var varExpr = this._nameResolver.getVariable(ast.name);
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

  dynamic visitPrefixNot(cdAst.PrefixNot ast, _Mode mode) {
    return convertToStatementIfNeeded(
        mode, o.not(ast.expression.visit(this, _Mode.Expression)));
  }

  dynamic visitPropertyRead(cdAst.PropertyRead ast, _Mode mode) {
    var result = null;
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      result = this._nameResolver.getVariable(ast.name);
      if (isBlank(result)) {
        receiver = this._implicitReceiver;
      }
    }
    if (isBlank(result)) {
      result = receiver.prop(ast.name);
    }
    return convertToStatementIfNeeded(mode, result);
  }

  dynamic visitPropertyWrite(cdAst.PropertyWrite ast, _Mode mode) {
    o.Expression receiver = ast.receiver.visit(this, _Mode.Expression);
    if (identical(receiver, IMPLICIT_RECEIVER)) {
      var varExpr = this._nameResolver.getVariable(ast.name);
      if (isPresent(varExpr)) {
        throw new BaseException("Cannot reassign a variable binding");
      }
      receiver = this._implicitReceiver;
    }
    return convertToStatementIfNeeded(mode,
        receiver.prop(ast.name).set(ast.value.visit(this, _Mode.Expression)));
  }

  dynamic visitSafePropertyRead(cdAst.SafePropertyRead ast, _Mode mode) {
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    return convertToStatementIfNeeded(mode,
        receiver.isBlank().conditional(o.NULL_EXPR, receiver.prop(ast.name)));
  }

  dynamic visitSafeMethodCall(cdAst.SafeMethodCall ast, _Mode mode) {
    var receiver = ast.receiver.visit(this, _Mode.Expression);
    var args = this.visitAll(ast.args, _Mode.Expression);
    return convertToStatementIfNeeded(
        mode,
        receiver
            .isBlank()
            .conditional(o.NULL_EXPR, receiver.callMethod(ast.name, args)));
  }

  dynamic visitAll(List<cdAst.AST> asts, _Mode mode) {
    return asts.map((ast) => ast.visit(this, mode)).toList();
  }

  dynamic visitQuote(cdAst.Quote ast, _Mode mode) {
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
