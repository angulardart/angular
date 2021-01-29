// @dart=2.9

import 'package:angular_compiler/v1/src/compiler/expression_parser/ast.dart';

class Unparser implements AstVisitor<void, String> {
  static final _quoteRegExp = RegExp(r'"');

  StringBuffer sb;

  String unparse(ASTWithSource ast) {
    sb = StringBuffer();
    _visit(ast.ast);
    return sb.toString();
  }

  @override
  void visitPropertyRead(
    PropertyRead ast,
    void _,
  ) {
    _visit(ast.receiver);
    sb.write(ast.receiver is ImplicitReceiver ? '${ast.name}' : '.${ast.name}');
  }

  @override
  void visitPropertyWrite(
    PropertyWrite ast,
    void _,
  ) {
    _visit(ast.receiver);
    sb.write(ast.receiver is ImplicitReceiver
        ? '${ast.name} = '
        : '.${ast.name} = ');
    _visit(ast.value);
  }

  @override
  void visitBinary(
    Binary ast,
    void _,
  ) {
    _visit(ast.left);
    sb.write(' ${ast.operator} ');
    _visit(ast.right);
  }

  @override
  void visitConditional(
    Conditional ast,
    void _,
  ) {
    _visit(ast.condition);
    sb.write(' ? ');
    _visit(ast.trueExp);
    sb.write(' : ');
    _visit(ast.falseExp);
  }

  @override
  void visitIfNull(
    IfNull ast,
    void _,
  ) {
    _visit(ast.condition);
    sb.write(' ?? ');
    _visit(ast.nullExp);
  }

  @override
  void visitPipe(
    BindingPipe ast,
    void _,
  ) {
    sb.write('\$pipe.${ast.name}(');
    _visit(ast.exp);
    for (var arg in ast.args) {
      sb.write(', ');
      _visit(arg);
    }
    sb.write(')');
  }

  @override
  void visitFunctionCall(
    FunctionCall ast,
    void _,
  ) {
    _visit(ast.target);
    sb.write('(');
    var isFirst = true;
    for (var arg in ast.args) {
      if (!isFirst) sb.write(', ');
      isFirst = false;
      _visit(arg);
    }
    for (var namedArg in ast.namedArgs) {
      if (!isFirst) sb.write(', ');
      isFirst = false;
      namedArg.visit(this);
    }
    sb.write(')');
  }

  @override
  void visitNamedExpr(NamedExpr ast, _) {
    sb.write('${ast.name}: ');
    ast.expression.visit(this);
  }

  @override
  void visitImplicitReceiver(
    ImplicitReceiver ast,
    void _,
  ) {}

  @override
  void visitInterpolation(
    Interpolation ast,
    void _,
  ) {
    for (var i = 0; i < ast.strings.length; i++) {
      sb.write(ast.strings[i]);
      if (i < ast.expressions.length) {
        sb.write('{{ ');
        _visit(ast.expressions[i]);
        sb.write(' }}');
      }
    }
  }

  @override
  void visitKeyedRead(
    KeyedRead ast,
    void _,
  ) {
    _visit(ast.receiver);
    sb.write('[');
    _visit(ast.key);
    sb.write(']');
  }

  @override
  void visitKeyedWrite(
    KeyedWrite ast,
    void _,
  ) {
    _visit(ast.receiver);
    sb.write('[');
    _visit(ast.key);
    sb.write('] = ');
    _visit(ast.value);
  }

  @override
  void visitLiteralPrimitive(
    LiteralPrimitive ast,
    void _,
  ) {
    final value = ast.value;
    if (value is String) {
      sb.write('"${value.replaceAll(Unparser._quoteRegExp, '"')}"');
    } else {
      sb.write('$value');
    }
  }

  @override
  void visitMethodCall(
    MethodCall ast,
    void _,
  ) {
    _visit(ast.receiver);
    sb.write(
        ast.receiver is ImplicitReceiver ? '${ast.name}(' : '.${ast.name}(');
    var isFirst = true;
    for (var arg in ast.args) {
      if (!isFirst) sb.write(', ');
      isFirst = false;
      _visit(arg);
    }
    for (var namedArg in ast.namedArgs) {
      if (!isFirst) sb.write(', ');
      isFirst = false;
      namedArg.visit(this);
    }
    sb.write(')');
  }

  @override
  void visitPostfixNotNull(
    PostfixNotNull ast,
    void _,
  ) {
    _visit(ast.expression);
    sb.write('!');
  }

  @override
  void visitPrefixNot(
    PrefixNot ast,
    void _,
  ) {
    sb.write('!');
    _visit(ast.expression);
  }

  @override
  void visitSafePropertyRead(
    SafePropertyRead ast,
    void _,
  ) {
    _visit(ast.receiver);
    sb.write('?.${ast.name}');
  }

  @override
  void visitSafeMethodCall(
    SafeMethodCall ast,
    void _,
  ) {
    _visit(ast.receiver);
    sb.write('?.${ast.name}(');
    var isFirst = true;
    for (var arg in ast.args) {
      if (!isFirst) sb.write(', ');
      isFirst = false;
      _visit(arg);
    }
    for (var namedArg in ast.namedArgs) {
      if (!isFirst) sb.write(', ');
      isFirst = false;
      namedArg.visit(this);
    }
    sb.write(')');
  }

  @override
  void visitStaticRead(
    StaticRead ast,
    void _,
  ) {
    sb.write(ast.id.name);
  }

  @override
  void visitEmptyExpr(
    EmptyExpr ast,
    void _,
  ) {}

  @override
  void visitVariableRead(
    VariableRead ast,
    void _,
  ) {}

  void _visit(AST ast) {
    ast.visit(this);
  }
}
