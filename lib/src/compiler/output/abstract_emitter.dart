import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart"
    show isPresent, isBlank, isString, StringWrapper;

import "output_ast.dart" as o;

var _SINGLE_QUOTE_ESCAPE_STRING_RE = new RegExp(r'' + "'" + r'|\\|\n|\r|\$');
var CATCH_ERROR_VAR = o.variable("error");
var CATCH_STACK_VAR = o.variable("stack");

abstract class OutputEmitter {
  String emitStatements(
      String moduleUrl, List<o.Statement> stmts, List<String> exportedVars);
}

class _EmittedLine {
  num indent;
  List<String> parts = [];
  _EmittedLine(this.indent) {}
}

class EmitterVisitorContext {
  List<String> _exportedVars;
  num _indent;
  static EmitterVisitorContext createRoot(List<String> exportedVars) {
    return new EmitterVisitorContext(exportedVars, 0);
  }

  List<_EmittedLine> _lines;
  List<o.ClassStmt> _classes = [];
  EmitterVisitorContext(this._exportedVars, this._indent) {
    this._lines = [new _EmittedLine(_indent)];
  }
  _EmittedLine get _currentLine {
    return this._lines[this._lines.length - 1];
  }

  bool isExportedVar(String varName) {
    return !identical(this._exportedVars.indexOf(varName), -1);
  }

  void println([String lastPart = ""]) {
    this.print(lastPart, true);
  }

  bool lineIsEmpty() {
    return identical(this._currentLine.parts.length, 0);
  }

  print(String part, [bool newLine = false]) {
    if (part.length > 0) {
      this._currentLine.parts.add(part);
    }
    if (newLine) {
      this._lines.add(new _EmittedLine(this._indent));
    }
  }

  removeEmptyLastLine() {
    if (this.lineIsEmpty()) {
      this._lines.removeLast();
    }
  }

  incIndent() {
    this._indent++;
    this._currentLine.indent = this._indent;
  }

  decIndent() {
    this._indent--;
    this._currentLine.indent = this._indent;
  }

  pushClass(o.ClassStmt clazz) {
    this._classes.add(clazz);
  }

  o.ClassStmt popClass() {
    return this._classes.removeLast();
  }

  o.ClassStmt get currentClass {
    return this._classes.length > 0
        ? this._classes[this._classes.length - 1]
        : null;
  }

  dynamic toSource() {
    var lines = this._lines;
    if (identical(lines[lines.length - 1].parts.length, 0)) {
      lines = ListWrapper.slice(lines, 0, lines.length - 1);
    }
    return lines
        .map((line) {
          if (line.parts.length > 0) {
            return _createIndent(line.indent) + line.parts.join("");
          } else {
            return "";
          }
        })
        .toList()
        .join("\n");
  }
}

abstract class AbstractEmitterVisitor
    implements o.StatementVisitor, o.ExpressionVisitor {
  bool _escapeDollarInStrings;
  AbstractEmitterVisitor(this._escapeDollarInStrings) {}
  dynamic visitExpressionStmt(o.ExpressionStatement stmt, context) {
    EmitterVisitorContext ctx = context;
    stmt.expr.visitExpression(this, ctx);
    ctx.println(";");
    return null;
  }

  dynamic visitReturnStmt(o.ReturnStatement stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''return ''');
    stmt.value.visitExpression(this, ctx);
    ctx.println(";");
    return null;
  }

  dynamic visitCastExpr(o.CastExpr ast, dynamic context);
  dynamic visitDeclareClassStmt(o.ClassStmt stmt, dynamic context);
  dynamic visitIfStmt(o.IfStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''if (''');
    stmt.condition.visitExpression(this, ctx);
    ctx.print(''') {''');
    var hasElseCase = isPresent(stmt.falseCase) && stmt.falseCase.length > 0;
    if (stmt.trueCase.length <= 1 && !hasElseCase) {
      ctx.print(''' ''');
      this.visitAllStatements(stmt.trueCase, ctx);
      ctx.removeEmptyLastLine();
      ctx.print(''' ''');
    } else {
      ctx.println();
      ctx.incIndent();
      this.visitAllStatements(stmt.trueCase, ctx);
      ctx.decIndent();
      if (hasElseCase) {
        ctx.println('''} else {''');
        ctx.incIndent();
        this.visitAllStatements(stmt.falseCase, ctx);
        ctx.decIndent();
      }
    }
    ctx.println('''}''');
    return null;
  }

  dynamic visitTryCatchStmt(o.TryCatchStmt stmt, dynamic context);
  dynamic visitThrowStmt(o.ThrowStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''throw ''');
    stmt.error.visitExpression(this, ctx);
    ctx.println(''';''');
    return null;
  }

  dynamic visitCommentStmt(o.CommentStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    var lines = stmt.comment.split("\n");
    lines.forEach((line) {
      ctx.println('''// ${ line}''');
    });
    return null;
  }

  dynamic visitDeclareVarStmt(o.DeclareVarStmt stmt, dynamic context);
  dynamic visitWriteVarExpr(o.WriteVarExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    var lineWasEmpty = ctx.lineIsEmpty();
    if (!lineWasEmpty) {
      ctx.print("(");
    }
    ctx.print('''${ expr . name} = ''');
    expr.value.visitExpression(this, ctx);
    if (!lineWasEmpty) {
      ctx.print(")");
    }
    return null;
  }

  dynamic visitWriteKeyExpr(o.WriteKeyExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    var lineWasEmpty = ctx.lineIsEmpty();
    if (!lineWasEmpty) {
      ctx.print("(");
    }
    expr.receiver.visitExpression(this, ctx);
    ctx.print('''[''');
    expr.index.visitExpression(this, ctx);
    ctx.print('''] = ''');
    expr.value.visitExpression(this, ctx);
    if (!lineWasEmpty) {
      ctx.print(")");
    }
    return null;
  }

  dynamic visitWritePropExpr(o.WritePropExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    var lineWasEmpty = ctx.lineIsEmpty();
    if (!lineWasEmpty) {
      ctx.print("(");
    }
    expr.receiver.visitExpression(this, ctx);
    ctx.print('''.${ expr . name} = ''');
    expr.value.visitExpression(this, ctx);
    if (!lineWasEmpty) {
      ctx.print(")");
    }
    return null;
  }

  dynamic visitInvokeMethodExpr(o.InvokeMethodExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    expr.receiver.visitExpression(this, ctx);
    var name = expr.name;
    if (isPresent(expr.builtin)) {
      name = this.getBuiltinMethodName(expr.builtin);
      if (isBlank(name)) {
        // some builtins just mean to skip the call.

        // e.g. `bind` in Dart.
        return null;
      }
    }
    ctx.print('''.${ name}(''');
    this.visitAllExpressions(expr.args, ctx, ''',''');
    ctx.print(''')''');
    return null;
  }

  String getBuiltinMethodName(o.BuiltinMethod method);
  dynamic visitInvokeFunctionExpr(o.InvokeFunctionExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    expr.fn.visitExpression(this, ctx);
    ctx.print('''(''');
    this.visitAllExpressions(expr.args, ctx, ",");
    ctx.print(''')''');
    return null;
  }

  dynamic visitReadVarExpr(o.ReadVarExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var varName = ast.name;
    if (isPresent(ast.builtin)) {
      switch (ast.builtin) {
        case o.BuiltinVar.Super:
          varName = "super";
          break;
        case o.BuiltinVar.This:
          varName = "this";
          break;
        case o.BuiltinVar.CatchError:
          varName = CATCH_ERROR_VAR.name;
          break;
        case o.BuiltinVar.CatchStack:
          varName = CATCH_STACK_VAR.name;
          break;
        case o.BuiltinVar.MetadataMap:
          varName = "null";
          break;
        default:
          throw new BaseException(
              '''Unknown builtin variable ${ ast . builtin}''');
      }
    }
    ctx.print(varName);
    return null;
  }

  dynamic visitInstantiateExpr(o.InstantiateExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''new ''');
    ast.classExpr.visitExpression(this, ctx);
    ctx.print('''(''');
    this.visitAllExpressions(ast.args, ctx, ",");
    ctx.print(''')''');
    return null;
  }

  dynamic visitLiteralExpr(o.LiteralExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var value = ast.value;
    if (isString(value)) {
      ctx.print(escapeSingleQuoteString(value, this._escapeDollarInStrings));
    } else if (isBlank(value)) {
      ctx.print("null");
    } else {
      ctx.print('''${ value}''');
    }
    return null;
  }

  dynamic visitExternalExpr(o.ExternalExpr ast, dynamic context);
  dynamic visitConditionalExpr(o.ConditionalExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''(''');
    ast.condition.visitExpression(this, ctx);
    ctx.print("? ");
    ast.trueCase.visitExpression(this, ctx);
    ctx.print(": ");
    ast.falseCase.visitExpression(this, ctx);
    ctx.print(''')''');
    return null;
  }

  dynamic visitNotExpr(o.NotExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print("!");
    ast.condition.visitExpression(this, ctx);
    return null;
  }

  dynamic visitFunctionExpr(o.FunctionExpr ast, dynamic context);
  dynamic visitDeclareFunctionStmt(o.DeclareFunctionStmt stmt, dynamic context);
  dynamic visitBinaryOperatorExpr(o.BinaryOperatorExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var opStr;
    switch (ast.operator) {
      case o.BinaryOperator.Equals:
        opStr = "==";
        break;
      case o.BinaryOperator.Identical:
        opStr = "===";
        break;
      case o.BinaryOperator.NotEquals:
        opStr = "!=";
        break;
      case o.BinaryOperator.NotIdentical:
        opStr = "!==";
        break;
      case o.BinaryOperator.And:
        opStr = "&&";
        break;
      case o.BinaryOperator.Or:
        opStr = "||";
        break;
      case o.BinaryOperator.Plus:
        opStr = "+";
        break;
      case o.BinaryOperator.Minus:
        opStr = "-";
        break;
      case o.BinaryOperator.Divide:
        opStr = "/";
        break;
      case o.BinaryOperator.Multiply:
        opStr = "*";
        break;
      case o.BinaryOperator.Modulo:
        opStr = "%";
        break;
      case o.BinaryOperator.Lower:
        opStr = "<";
        break;
      case o.BinaryOperator.LowerEquals:
        opStr = "<=";
        break;
      case o.BinaryOperator.Bigger:
        opStr = ">";
        break;
      case o.BinaryOperator.BiggerEquals:
        opStr = ">=";
        break;
      default:
        throw new BaseException('''Unknown operator ${ ast . operator}''');
    }
    ctx.print('''(''');
    ast.lhs.visitExpression(this, ctx);
    ctx.print(''' ${ opStr} ''');
    ast.rhs.visitExpression(this, ctx);
    ctx.print(''')''');
    return null;
  }

  dynamic visitReadPropExpr(o.ReadPropExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ast.receiver.visitExpression(this, ctx);
    ctx.print('''.''');
    ctx.print(ast.name);
    return null;
  }

  dynamic visitReadKeyExpr(o.ReadKeyExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ast.receiver.visitExpression(this, ctx);
    ctx.print('''[''');
    ast.index.visitExpression(this, ctx);
    ctx.print(''']''');
    return null;
  }

  dynamic visitLiteralArrayExpr(o.LiteralArrayExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var useNewLine = ast.entries.length > 1;
    ctx.print('''[''', useNewLine);
    ctx.incIndent();
    this.visitAllExpressions(ast.entries, ctx, ",", useNewLine);
    ctx.decIndent();
    ctx.print(''']''', useNewLine);
    return null;
  }

  dynamic visitLiteralMapExpr(o.LiteralMapExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var useNewLine = ast.entries.length > 1;
    ctx.print('''{''', useNewLine);
    ctx.incIndent();
    this.visitAllObjects((entry) {
      ctx.print(
          '''${ escapeSingleQuoteString ( entry [ 0 ] , this . _escapeDollarInStrings )}: ''');
      entry[1].visitExpression(this, ctx);
    }, ast.entries, ctx, ",", useNewLine);
    ctx.decIndent();
    ctx.print('''}''', useNewLine);
    return null;
  }

  void visitAllExpressions(List<o.Expression> expressions,
      EmitterVisitorContext ctx, String separator,
      [bool newLine = false]) {
    this.visitAllObjects((expr) => expr.visitExpression(this, ctx), expressions,
        ctx, separator, newLine);
  }

  void visitAllObjects(Function handler, dynamic expressions,
      EmitterVisitorContext ctx, String separator,
      [bool newLine = false]) {
    for (var i = 0; i < expressions.length; i++) {
      if (i > 0) {
        ctx.print(separator, newLine);
      }
      handler(expressions[i]);
    }
    if (newLine) {
      ctx.println();
    }
  }

  void visitAllStatements(
      List<o.Statement> statements, EmitterVisitorContext ctx) {
    statements.forEach((stmt) {
      return stmt.visitStatement(this, ctx);
    });
  }
}

dynamic escapeSingleQuoteString(String input, bool escapeDollar) {
  if (isBlank(input)) {
    return null;
  }
  var body = StringWrapper
      .replaceAllMapped(input, _SINGLE_QUOTE_ESCAPE_STRING_RE, (match) {
    if (match[0] == "\$") {
      return escapeDollar ? "\\\$" : "\$";
    } else if (match[0] == "\n") {
      return "\\n";
    } else if (match[0] == "\r") {
      return "\\r";
    } else {
      return '''\\${ match [ 0 ]}''';
    }
  });
  return '''\'${ body}\'''';
}

String _createIndent(num count) {
  var res = "";
  for (var i = 0; i < count; i++) {
    res += "  ";
  }
  return res;
}
