import 'output_ast.dart' as o;

final _singleQuoteEscape = RegExp(r'' + "'" + r'|\\|\n|\r|\$');
final catchErrorVar = o.variable('error');
final catchStackVar = o.variable('stack');

abstract class OutputEmitter {
  String emitStatements(String moduleUrl, List<o.Statement> stmts,
      Map<String, String> deferredModules);
}

class _EmittedLine {
  int indent;
  List<String> parts = [];
  _EmittedLine(this.indent);
}

class EmitterVisitorContext {
  final Map<String, String> deferredModules;
  int _indent;
  int _outputPos = 0;

  final List<_EmittedLine> _lines;
  final List<o.ClassStmt> _classes = [];

  static EmitterVisitorContext createRoot(Map<String, String> deferredModules) {
    return EmitterVisitorContext(0, deferredModules);
  }

  EmitterVisitorContext(this._indent, this.deferredModules)
      : this._lines = [_EmittedLine(_indent)];

  _EmittedLine get _currentLine {
    return _lines[_lines.length - 1];
  }

  int get currentLineLength => _currentLine.indent + _outputPos;

  void println([String lastPart = '']) {
    print(lastPart, true);
    _outputPos += lastPart.length;
  }

  bool lineIsEmpty() {
    return identical(_currentLine.parts.length, 0);
  }

  void print(String part, [bool newLine = false]) {
    if (part.isNotEmpty) {
      _currentLine.parts.add(part);
    }
    if (newLine) {
      _lines.add(_EmittedLine(_indent));
      _outputPos = 0;
    } else {
      _outputPos += part.length;
    }
  }

  void removeEmptyLastLine() {
    if (lineIsEmpty()) {
      _lines.removeLast();
    }
  }

  void incIndent() {
    _indent++;
    _currentLine.indent = _indent;
  }

  void decIndent() {
    _indent--;
    _currentLine.indent = _indent;
  }

  void pushClass(o.ClassStmt clazz) {
    _classes.add(clazz);
  }

  o.ClassStmt popClass() {
    return _classes.removeLast();
  }

  o.ClassStmt get currentClass {
    return _classes.isNotEmpty ? _classes[_classes.length - 1] : null;
  }

  String toSource() {
    var lines = _lines;
    if (identical(lines[lines.length - 1].parts.length, 0)) {
      lines = lines.sublist(0, lines.length - 1);
    }
    return lines
        .map((line) {
          if (line.parts.isNotEmpty) {
            return _createIndent(line.indent) + line.parts.join('');
          } else {
            return '';
          }
        })
        .toList()
        .join('\n');
  }
}

abstract class AbstractEmitterVisitor
    implements
        o.StatementVisitor<void, EmitterVisitorContext>,
        o.ExpressionVisitor<void, EmitterVisitorContext> {
  final bool _escapeDollarInStrings;

  AbstractEmitterVisitor(this._escapeDollarInStrings);

  @override
  void visitExpressionStmt(
      o.ExpressionStatement stmt, EmitterVisitorContext context) {
    stmt.expr.visitExpression(this, context);
    context.println(';');
  }

  @override
  void visitReturnStmt(o.ReturnStatement stmt, EmitterVisitorContext context) {
    if (stmt.value == null) {
      context.println('return;${stmt.inlineComment}');
    } else {
      context.print('return ');
      stmt.value.visitExpression(this, context);
      context.println(';${stmt.inlineComment}');
    }
  }

  @override
  void visitCastExpr(o.CastExpr ast, EmitterVisitorContext context);

  @override
  void visitDeclareClassStmt(o.ClassStmt stmt, EmitterVisitorContext context);

  @override
  void visitIfStmt(o.IfStmt stmt, EmitterVisitorContext context) {
    context.print('if (');
    stmt.condition.visitExpression(this, context);
    context.print(') {');
    var hasElseCase = stmt.falseCase != null && stmt.falseCase.isNotEmpty;
    if (stmt.trueCase.length <= 1 && !hasElseCase) {
      context.print(' ');
      visitAllStatements(stmt.trueCase, context);
      context.removeEmptyLastLine();
      context.print(' ');
    } else {
      context.println();
      context.incIndent();
      visitAllStatements(stmt.trueCase, context);
      context.decIndent();
      if (hasElseCase) {
        context.println('} else {');
        context.incIndent();
        visitAllStatements(stmt.falseCase, context);
        context.decIndent();
      }
    }
    context.println('}');
  }

  @override
  void visitTryCatchStmt(o.TryCatchStmt stmt, EmitterVisitorContext context);

  @override
  void visitThrowStmt(o.ThrowStmt stmt, EmitterVisitorContext context) {
    context.print('throw ');
    stmt.error.visitExpression(this, context);
    context.println(';');
  }

  @override
  void visitCommentStmt(o.CommentStmt stmt, EmitterVisitorContext context) {
    var lines = stmt.comment.split('\n');
    for (var line in lines) {
      context.print('// ');
      context.println(line);
    }
  }

  @override
  void visitDeclareVarStmt(
      o.DeclareVarStmt stmt, EmitterVisitorContext context);

  @override
  void visitWriteVarExpr(o.WriteVarExpr expr, EmitterVisitorContext context,
      {bool checkForNull = false}) {
    var lineWasEmpty = context.lineIsEmpty();
    if (!lineWasEmpty) {
      context.print('(');
    }
    if (checkForNull) {
      context.print('${expr.name} ??= ');
    } else {
      context.print('${expr.name} = ');
    }
    expr.value.visitExpression(this, context);
    if (!lineWasEmpty) {
      context.print(')');
    }
  }

  @override
  void visitWriteStaticMemberExpr(
      o.WriteStaticMemberExpr expr, EmitterVisitorContext context) {
    var lineWasEmpty = context.lineIsEmpty();
    if (!lineWasEmpty) {
      context.print('(');
    }
    if (expr.checkIfNull) {
      context.print('${expr.name} ??= ');
    } else {
      context.print('${expr.name} = ');
    }
    expr.value.visitExpression(this, context);
    if (!lineWasEmpty) {
      context.print(')');
    }
  }

  @override
  void visitWriteKeyExpr(o.WriteKeyExpr expr, EmitterVisitorContext context) {
    var lineWasEmpty = context.lineIsEmpty();
    if (!lineWasEmpty) {
      context.print('(');
    }
    expr.receiver.visitExpression(this, context);
    context.print('[');
    expr.index.visitExpression(this, context);
    context.print('] = ');
    expr.value.visitExpression(this, context);
    if (!lineWasEmpty) {
      context.print(')');
    }
  }

  @override
  void visitWritePropExpr(o.WritePropExpr expr, EmitterVisitorContext context) {
    var lineWasEmpty = context.lineIsEmpty();
    if (!lineWasEmpty) {
      context.print('(');
    }
    expr.receiver.visitExpression(this, context);
    context.print('.${expr.name} = ');
    expr.value.visitExpression(this, context);
    if (!lineWasEmpty) {
      context.print(')');
    }
  }

  @override
  void visitWriteClassMemberExpr(
      o.WriteClassMemberExpr expr, EmitterVisitorContext context) {
    var lineWasEmpty = context.lineIsEmpty();
    if (!lineWasEmpty) {
      context.print('(');
    }
    o.THIS_EXPR.visitExpression(this, context);
    context.print('.${expr.name} = ');
    expr.value.visitExpression(this, context);
    if (!lineWasEmpty) {
      context.print(')');
    }
  }

  @override
  void visitInvokeMethodExpr(
      o.InvokeMethodExpr expr, EmitterVisitorContext context) {
    expr.receiver.visitExpression(this, context);
    var name = expr.name;
    if (expr.builtin != null) {
      name = getBuiltinMethodName(expr.builtin);
      if (name == null) {
        // some builtins just mean to skip the call.

        // e.g. `bind` in Dart.
        return;
      }
    }
    if (expr.checked) {
      context.print('?');
    }
    context.print('.$name(');
    visitAllExpressions(expr.args, context, ',');
    visitAllNamedExpressions(
      expr.namedArgs,
      context,
      ',',
      alwaysAddSeperator: expr.args.isNotEmpty,
    );
    context.print(')');
  }

  @override
  void visitInvokeMemberMethodExpr(
      o.InvokeMemberMethodExpr expr, EmitterVisitorContext context) {
    context.print('this.${expr.methodName}(');
    visitAllExpressions(expr.args, context, ',');
    visitAllNamedExpressions(
      expr.namedArgs,
      context,
      ',',
      alwaysAddSeperator: expr.args.isNotEmpty,
    );
    context.print(')');
  }

  String getBuiltinMethodName(o.BuiltinMethod method);

  @override
  void visitReadVarExpr(o.ReadVarExpr ast, EmitterVisitorContext context) {
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
          throw StateError('Unknown builtin variable ${ast.builtin}');
      }
    }
    context.print(varName);
  }

  @override
  void visitReadStaticMemberExpr(
      o.ReadStaticMemberExpr ast, EmitterVisitorContext context) {
    var varName = ast.name;
    var t = ast.sourceClass as o.ExternalType;
    if (t != null) {
      context.print('${t.value.name}.');
    }
    context.print(varName);
  }

  @override
  void visitReadClassMemberExpr(
      o.ReadClassMemberExpr ast, EmitterVisitorContext context) {
    context.print('this.${ast.name}');
  }

  @override
  void visitInstantiateExpr(
      o.InstantiateExpr ast, EmitterVisitorContext context) {
    context.print('new ');
    ast.classExpr.visitExpression(this, context);
    context.print('(');
    visitAllExpressions(ast.args, context, ',');
    visitAllNamedExpressions(
      ast.namedArgs,
      context,
      ',',
      alwaysAddSeperator: ast.args.isNotEmpty,
    );
    context.print(')');
  }

  @override
  void visitLiteralExpr(o.LiteralExpr ast, EmitterVisitorContext context) {
    var value = ast.value;
    if (value is String) {
      context.print(escapeSingleQuoteString(value, _escapeDollarInStrings));
    } else if (value is o.EscapedString) {
      context.print("'${value.value}'");
    } else if (value == null) {
      context.print('null');
    } else {
      context.print('$value');
    }
  }

  @override
  void visitExternalExpr(o.ExternalExpr ast, EmitterVisitorContext context);

  @override
  void visitConditionalExpr(
      o.ConditionalExpr ast, EmitterVisitorContext context) {
    context.print('(');
    ast.condition.visitExpression(this, context);
    context.print('? ');
    ast.trueCase.visitExpression(this, context);
    context.print(': ');
    ast.falseCase.visitExpression(this, context);
    context.print(')');
  }

  @override
  void visitIfNullExpr(o.IfNullExpr ast, EmitterVisitorContext context) {
    context.print('(');
    ast.condition.visitExpression(this, context);
    context.print('?? ');
    ast.nullCase.visitExpression(this, context);
    context.print(')');
  }

  @override
  void visitNotExpr(o.NotExpr ast, EmitterVisitorContext context) {
    context.print('(!');
    ast.condition.visitExpression(this, context);
    context.print(')');
  }

  @override
  void visitFunctionExpr(o.FunctionExpr ast, EmitterVisitorContext context);

  @override
  void visitDeclareFunctionStmt(
      o.DeclareFunctionStmt stmt, EmitterVisitorContext context);

  @override
  void visitBinaryOperatorExpr(
      o.BinaryOperatorExpr ast, EmitterVisitorContext context) {
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
        throw StateError('Unknown operator ${ast.operator}');
    }
    context.print('(');
    ast.lhs.visitExpression(this, context);
    context.print(' $opStr ');
    ast.rhs.visitExpression(this, context);
    context.print(')');
  }

  @override
  void visitReadPropExpr(o.ReadPropExpr ast, EmitterVisitorContext context) {
    ast.receiver.visitExpression(this, context);
    context.print('.');
    context.print(ast.name);
  }

  @override
  void visitReadKeyExpr(o.ReadKeyExpr ast, EmitterVisitorContext context) {
    ast.receiver.visitExpression(this, context);
    context.print('[');
    ast.index.visitExpression(this, context);
    context.print(']');
  }

  @override
  void visitLiteralArrayExpr(
      o.LiteralArrayExpr ast, EmitterVisitorContext context) {
    var useNewLine = ast.entries.length > 1;
    context.print('[', useNewLine);
    context.incIndent();
    visitAllExpressions(ast.entries, context, ',',
        newLine: useNewLine, keepOnSameLine: true);
    context.decIndent();
    context.print(']', useNewLine);
  }

  @override
  void visitLiteralMapExpr(
      o.LiteralMapExpr ast, EmitterVisitorContext context) {
    var useNewLine = ast.entries.length > 1;
    context.print('{', useNewLine);
    context.incIndent();
    visitAllObjects((entry) {
      final firstEntry = entry[0];
      if (firstEntry is o.Expression) {
        firstEntry.visitExpression(this, context);
      } else {
        final firstEntryCasted = firstEntry as String;
        context.print(
            escapeSingleQuoteString(firstEntryCasted, _escapeDollarInStrings));
      }
      context.print(': ');
      entry[1].visitExpression(this, context);
    }, ast.entries, context, ',', newLine: useNewLine, keepOnSameLine: false);
    context.decIndent();
    context.print('}', useNewLine);
  }

  void visitAllExpressions(List<o.Expression> expressions,
      EmitterVisitorContext ctx, String separator,
      {bool newLine = false, bool keepOnSameLine = false}) {
    visitAllObjects<o.Expression>(
        (expr) => expr.visitExpression(this, ctx), expressions, ctx, separator,
        newLine: newLine, keepOnSameLine: keepOnSameLine);
  }

  void visitAllNamedExpressions(
    List<o.NamedExpr> expressions,
    EmitterVisitorContext ctx,
    String seperator, {
    bool alwaysAddSeperator = false,
  }) {
    if (expressions == null || expressions.isEmpty) {
      return;
    }
    if (alwaysAddSeperator) {
      ctx.print(seperator);
    }
    for (var ast in expressions) {
      ctx.print('${ast.name}: ');
      ast.expr.visitExpression(this, ctx);
      ctx.print(seperator);
    }
  }

  void visitAllObjects<T>(void Function(T) handler, List<T> expressions,
      EmitterVisitorContext ctx, String separator,
      {bool newLine = false, bool keepOnSameLine = false}) {
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
