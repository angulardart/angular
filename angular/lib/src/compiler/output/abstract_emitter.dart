import 'output_ast.dart' as o;

final _singleQuoteEscape = new RegExp(r'' + "'" + r'|\\|\n|\r|\$');
final catchErrorVar = o.variable('error');
final catchStackVar = o.variable('stack');

abstract class OutputEmitter {
  String emitStatements(String moduleUrl, List<o.Statement> stmts,
      List<String> exportedVars, Map<String, String> deferredModules);
}

class _EmittedLine {
  int indent;
  List<String> parts = [];
  _EmittedLine(this.indent);
}

class EmitterVisitorContext {
  final Map<String, String> deferredModules;
  final List<String> _exportedVars;
  int _indent;
  int _outputPos;
  // Current method being emitted. Allows expressions access to method
  // parameter names.
  o.ClassMethod _activeMethod;
  bool _inSuperCall;

  static EmitterVisitorContext createRoot(
      List<String> exportedVars, Map<String, String> deferredModules) {
    return new EmitterVisitorContext(exportedVars, 0, deferredModules);
  }

  List<_EmittedLine> _lines;
  final List<o.ClassStmt> _classes = [];
  EmitterVisitorContext(
      this._exportedVars, this._indent, this.deferredModules) {
    _outputPos = 0;
    this._lines = [new _EmittedLine(_indent)];
  }
  _EmittedLine get _currentLine {
    return this._lines[this._lines.length - 1];
  }

  int get currentLineLength => _currentLine.indent + _outputPos;

  bool isExportedVar(String varName) {
    return !identical(this._exportedVars.indexOf(varName), -1);
  }

  void println([String lastPart = '']) {
    this.print(lastPart, true);
    _outputPos += lastPart.length;
  }

  bool lineIsEmpty() {
    return identical(this._currentLine.parts.length, 0);
  }

  void print(String part, [bool newLine = false]) {
    if (part.length > 0) {
      this._currentLine.parts.add(part);
    }
    if (newLine) {
      this._lines.add(new _EmittedLine(this._indent));
      _outputPos = 0;
    } else {
      _outputPos += part.length;
    }
  }

  void removeEmptyLastLine() {
    if (this.lineIsEmpty()) {
      this._lines.removeLast();
    }
  }

  void incIndent() {
    this._indent++;
    this._currentLine.indent = this._indent;
  }

  void decIndent() {
    this._indent--;
    this._currentLine.indent = this._indent;
  }

  void pushClass(o.ClassStmt clazz) {
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

  String toSource() {
    var lines = this._lines;
    if (identical(lines[lines.length - 1].parts.length, 0)) {
      lines = lines.sublist(0, lines.length - 1);
    }
    return lines
        .map((line) {
          if (line.parts.length > 0) {
            return _createIndent(line.indent) + line.parts.join('');
          } else {
            return '';
          }
        })
        .toList()
        .join('\n');
  }

  /// Creates method context for expressions.
  void enterMethod(o.ClassMethod method) {
    _activeMethod = method;
  }

  /// Removes method context for expressions.
  void exitMethod() {
    _activeMethod = null;
  }

  /// Creates super call context for expressions.
  void enterSuperCall() {
    _inSuperCall = true;
  }

  /// Removes super call context for expressions.
  void exitSuperCall() {
    _inSuperCall = false;
  }

  bool get inSuperCall => _inSuperCall;
  o.ClassMethod get activeMethod => _activeMethod;
}

abstract class AbstractEmitterVisitor
    implements o.StatementVisitor, o.ExpressionVisitor {
  final bool _escapeDollarInStrings;
  AbstractEmitterVisitor(this._escapeDollarInStrings);
  @override
  dynamic visitExpressionStmt(o.ExpressionStatement stmt, context) {
    EmitterVisitorContext ctx = context;
    stmt.expr.visitExpression(this, ctx);
    ctx.println(';');
    return null;
  }

  @override
  dynamic visitReturnStmt(o.ReturnStatement stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (stmt.value == null) {
      ctx.println('return;${stmt.inlineComment}');
    } else {
      ctx.print('return ');
      stmt.value.visitExpression(this, ctx);
      ctx.println(';${stmt.inlineComment}');
    }
    return null;
  }

  @override
  dynamic visitCastExpr(o.CastExpr ast, dynamic context);
  @override
  dynamic visitDeclareClassStmt(o.ClassStmt stmt, dynamic context);
  @override
  dynamic visitIfStmt(o.IfStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('if (');
    stmt.condition.visitExpression(this, ctx);
    ctx.print(') {');
    var hasElseCase = stmt.falseCase != null && stmt.falseCase.length > 0;
    if (stmt.trueCase.length <= 1 && !hasElseCase) {
      ctx.print(' ');
      this.visitAllStatements(stmt.trueCase, ctx);
      ctx.removeEmptyLastLine();
      ctx.print(' ');
    } else {
      ctx.println();
      ctx.incIndent();
      this.visitAllStatements(stmt.trueCase, ctx);
      ctx.decIndent();
      if (hasElseCase) {
        ctx.println('} else {');
        ctx.incIndent();
        this.visitAllStatements(stmt.falseCase, ctx);
        ctx.decIndent();
      }
    }
    ctx.println('}');
    return null;
  }

  @override
  dynamic visitTryCatchStmt(o.TryCatchStmt stmt, dynamic context);
  @override
  dynamic visitThrowStmt(o.ThrowStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('throw ');
    stmt.error.visitExpression(this, ctx);
    ctx.println(';');
    return null;
  }

  @override
  dynamic visitCommentStmt(o.CommentStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    var lines = stmt.comment.split('\n');
    for (var line in lines) {
      ctx.print('// ');
      ctx.println(line);
    }
    return null;
  }

  @override
  dynamic visitDeclareVarStmt(o.DeclareVarStmt stmt, dynamic context);

  @override
  dynamic visitWriteVarExpr(o.WriteVarExpr expr, dynamic context,
      {bool checkForNull: false}) {
    EmitterVisitorContext ctx = context;
    var lineWasEmpty = ctx.lineIsEmpty();
    if (!lineWasEmpty) {
      ctx.print('(');
    }
    if (checkForNull) {
      ctx.print('${expr.name} ??= ');
    } else {
      ctx.print('${expr.name} = ');
    }
    expr.value.visitExpression(this, ctx);
    if (!lineWasEmpty) {
      ctx.print(')');
    }
    return null;
  }

  @override
  dynamic visitWriteStaticMemberExpr(
      o.WriteStaticMemberExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    var lineWasEmpty = ctx.lineIsEmpty();
    if (!lineWasEmpty) {
      ctx.print('(');
    }
    if (expr.checkIfNull) {
      ctx.print('${expr.name} ??= ');
    } else {
      ctx.print('${expr.name} = ');
    }
    expr.value.visitExpression(this, ctx);
    if (!lineWasEmpty) {
      ctx.print(')');
    }
    return null;
  }

  @override
  dynamic visitWriteKeyExpr(o.WriteKeyExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    var lineWasEmpty = ctx.lineIsEmpty();
    if (!lineWasEmpty) {
      ctx.print('(');
    }
    expr.receiver.visitExpression(this, ctx);
    ctx.print('[');
    expr.index.visitExpression(this, ctx);
    ctx.print('] = ');
    expr.value.visitExpression(this, ctx);
    if (!lineWasEmpty) {
      ctx.print(')');
    }
    return null;
  }

  @override
  dynamic visitWritePropExpr(o.WritePropExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    var lineWasEmpty = ctx.lineIsEmpty();
    if (!lineWasEmpty) {
      ctx.print('(');
    }
    expr.receiver.visitExpression(this, ctx);
    ctx.print('.${expr.name} = ');
    expr.value.visitExpression(this, ctx);
    if (!lineWasEmpty) {
      ctx.print(')');
    }
    return null;
  }

  @override
  dynamic visitWriteClassMemberExpr(
      o.WriteClassMemberExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    var lineWasEmpty = ctx.lineIsEmpty();
    if (!lineWasEmpty) {
      ctx.print('(');
    }
    o.THIS_EXPR.visitExpression(this, ctx);
    ctx.print('.${expr.name} = ');
    expr.value.visitExpression(this, ctx);
    if (!lineWasEmpty) {
      ctx.print(')');
    }
    return null;
  }

  @override
  dynamic visitInvokeMethodExpr(o.InvokeMethodExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    expr.receiver.visitExpression(this, ctx);
    var name = expr.name;
    if (expr.builtin != null) {
      name = this.getBuiltinMethodName(expr.builtin);
      if (name == null) {
        // some builtins just mean to skip the call.

        // e.g. `bind` in Dart.
        return null;
      }
    }
    if (expr.checked) {
      ctx.print('?');
    }
    ctx.print('.$name(');
    this.visitAllExpressions(expr.args, ctx, ',');
    ctx.print(')');
    return null;
  }

  @override
  dynamic visitInvokeMemberMethodExpr(
      o.InvokeMemberMethodExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('${expr.methodName}(');
    this.visitAllExpressions(expr.args, ctx, ',');
    ctx.print(')');
    return null;
  }

  String getBuiltinMethodName(o.BuiltinMethod method);

  @override
  dynamic visitInvokeFunctionExpr(o.InvokeFunctionExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    expr.fn.visitExpression(this, ctx);
    ctx.print('(');
    this.visitAllExpressions(expr.args, ctx, ',');
    ctx.print(')');
    return null;
  }

  @override
  dynamic visitReadVarExpr(o.ReadVarExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var varName = ast.name;
    if (ast.builtin != null) {
      switch (ast.builtin) {
        case o.BuiltinVar.Super:
          varName = 'super';
          break;
        case o.BuiltinVar.This:
          varName = 'this';
          break;
        case o.BuiltinVar.CatchError:
          varName = catchErrorVar.name;
          break;
        case o.BuiltinVar.CatchStack:
          varName = catchStackVar.name;
          break;
        case o.BuiltinVar.MetadataMap:
          varName = 'null';
          break;
        default:
          throw new StateError('Unknown builtin variable ${ast.builtin}');
      }
    }
    ctx.print(varName);
    return null;
  }

  @override
  dynamic visitReadStaticMemberExpr(
      o.ReadStaticMemberExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var varName = ast.name;
    o.ExternalType t = ast.sourceClass;
    if (t != null) {
      ctx.print('${t.value.name}.');
    }
    ctx.print(varName);
    return null;
  }

  @override
  dynamic visitReadClassMemberExpr(o.ReadClassMemberExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('this.${ast.name}');
    return null;
  }

  @override
  dynamic visitInstantiateExpr(o.InstantiateExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('new ');
    ast.classExpr.visitExpression(this, ctx);
    ctx.print('(');
    this.visitAllExpressions(ast.args, ctx, ',');
    ctx.print(')');
    return null;
  }

  @override
  dynamic visitLiteralExpr(o.LiteralExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var value = ast.value;
    if (value is String) {
      ctx.print(escapeSingleQuoteString(value, this._escapeDollarInStrings));
    } else if (value == null) {
      ctx.print('null');
    } else {
      ctx.print('$value');
    }
    return null;
  }

  @override
  dynamic visitExternalExpr(o.ExternalExpr ast, dynamic context);

  @override
  dynamic visitConditionalExpr(o.ConditionalExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('(');
    ast.condition.visitExpression(this, ctx);
    ctx.print('? ');
    ast.trueCase.visitExpression(this, ctx);
    ctx.print(': ');
    ast.falseCase.visitExpression(this, ctx);
    ctx.print(')');
    return null;
  }

  @override
  dynamic visitIfNullExpr(o.IfNullExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('(');
    ast.condition.visitExpression(this, ctx);
    ctx.print('?? ');
    ast.nullCase.visitExpression(this, ctx);
    ctx.print(')');
    return null;
  }

  @override
  dynamic visitNotExpr(o.NotExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('!');
    ast.condition.visitExpression(this, ctx);
    return null;
  }

  @override
  dynamic visitFunctionExpr(o.FunctionExpr ast, dynamic context);

  @override
  dynamic visitDeclareFunctionStmt(o.DeclareFunctionStmt stmt, dynamic context);

  @override
  dynamic visitBinaryOperatorExpr(o.BinaryOperatorExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var opStr;
    switch (ast.operator) {
      case o.BinaryOperator.Equals:
        opStr = '==';
        break;
      case o.BinaryOperator.Identical:
        opStr = '===';
        break;
      case o.BinaryOperator.NotEquals:
        opStr = '!=';
        break;
      case o.BinaryOperator.NotIdentical:
        opStr = '!==';
        break;
      case o.BinaryOperator.And:
        opStr = '&&';
        break;
      case o.BinaryOperator.Or:
        opStr = '||';
        break;
      case o.BinaryOperator.Plus:
        opStr = '+';
        break;
      case o.BinaryOperator.Minus:
        opStr = '-';
        break;
      case o.BinaryOperator.Divide:
        opStr = '/';
        break;
      case o.BinaryOperator.Multiply:
        opStr = '*';
        break;
      case o.BinaryOperator.Modulo:
        opStr = '%';
        break;
      case o.BinaryOperator.Lower:
        opStr = '<';
        break;
      case o.BinaryOperator.LowerEquals:
        opStr = '<=';
        break;
      case o.BinaryOperator.Bigger:
        opStr = '>';
        break;
      case o.BinaryOperator.BiggerEquals:
        opStr = '>=';
        break;
      default:
        throw new StateError('Unknown operator ${ast.operator}');
    }
    ctx.print('(');
    ast.lhs.visitExpression(this, ctx);
    ctx.print(' $opStr ');
    ast.rhs.visitExpression(this, ctx);
    ctx.print(')');
    return null;
  }

  @override
  dynamic visitReadPropExpr(o.ReadPropExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ast.receiver.visitExpression(this, ctx);
    ctx.print('.');
    ctx.print(ast.name);
    return null;
  }

  @override
  dynamic visitReadKeyExpr(o.ReadKeyExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ast.receiver.visitExpression(this, ctx);
    ctx.print('[');
    ast.index.visitExpression(this, ctx);
    ctx.print(']');
    return null;
  }

  @override
  dynamic visitLiteralArrayExpr(o.LiteralArrayExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var useNewLine = ast.entries.length > 1;
    ctx.print('[', useNewLine);
    ctx.incIndent();
    this.visitAllExpressions(ast.entries, ctx, ',',
        newLine: useNewLine, keepOnSameLine: true);
    ctx.decIndent();
    ctx.print(']', useNewLine);
    return null;
  }

  @override
  dynamic visitLiteralMapExpr(o.LiteralMapExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var useNewLine = ast.entries.length > 1;
    ctx.print('{', useNewLine);
    ctx.incIndent();
    this.visitAllObjects((entry) {
      final firstEntry = entry[0];
      if (firstEntry is o.Expression) {
        firstEntry.visitExpression(this, ctx);
      } else {
        final firstEntryCasted = firstEntry as String;
        ctx.print(
            escapeSingleQuoteString(firstEntryCasted, _escapeDollarInStrings));
      }
      ctx.print(': ');
      entry[1].visitExpression(this, ctx);
    }, ast.entries, ctx, ',', newLine: useNewLine, keepOnSameLine: false);
    ctx.decIndent();
    ctx.print('}', useNewLine);
    return null;
  }

  void visitAllExpressions(List<o.Expression> expressions,
      EmitterVisitorContext ctx, String separator,
      {bool newLine: false, bool keepOnSameLine: false}) {
    visitAllObjects(
        (expr) => expr.visitExpression(this, ctx), expressions, ctx, separator,
        newLine: newLine, keepOnSameLine: keepOnSameLine);
  }

  void visitAllObjects(Function handler, dynamic expressions,
      EmitterVisitorContext ctx, String separator,
      {bool newLine: false, bool keepOnSameLine: false}) {
    const int _MAX_OUTPUT_LENGTH = 80;
    int length = expressions.length;
    for (var i = 0; i < length; i++) {
      handler(expressions[i]);
      if (i != (length - 1)) {
        // Place separator.
        ctx.print(
            separator,
            keepOnSameLine
                ? ctx.currentLineLength > _MAX_OUTPUT_LENGTH
                : newLine);
      }
    }
    if (newLine) {
      ctx.println();
    }
  }

  void visitAllStatements(
      List<o.Statement> statements, EmitterVisitorContext ctx) {
    for (var stmt in statements) {
      stmt.visitStatement(this, ctx);
    }
  }
}

String escapeSingleQuoteString(String input, bool escapeDollar) {
  if (input == null) {
    return null;
  }
  var body = input.replaceAllMapped(_singleQuoteEscape, (match) {
    if (match[0] == '\$') {
      return escapeDollar ? '\\\$' : '\$';
    } else if (match[0] == '\n') {
      return '\\n';
    } else if (match[0] == '\r') {
      return '\\r';
    } else {
      return '\\${match[0]}';
    }
  });
  return "'$body'";
}

String _createIndent(int count) => '  ' * count;
