import 'package:angular/src/compiler/expression_parser/ast.dart';

class Unparser implements AstVisitor {
  static final _quoteRegExp = RegExp(r'"');
  StringBuffer sb;

  String unparse(ASTWithSource ast) {
    sb = StringBuffer();
    _visit(ast.ast);
    return sb.toString();
  }

  @override
  void visitPropertyRead(PropertyRead ast, dynamic context) {
    this._visit(ast.receiver);
    sb.write(ast.receiver is ImplicitReceiver ? '${ast.name}' : '.${ast.name}');
  }

  @override
  void visitPropertyWrite(PropertyWrite ast, dynamic context) {
    _visit(ast.receiver);
    sb.write(ast.receiver is ImplicitReceiver
        ? '${ast.name} = '
        : '.${ast.name} = ');
    _visit(ast.value);
  }

  @override
  void visitBinary(Binary ast, dynamic context) {
    _visit(ast.left);
    sb.write(' ${ast.operation} ');
    _visit(ast.right);
  }

  @override
  void visitConditional(Conditional ast, dynamic context) {
    _visit(ast.condition);
    sb.write(" ? ");
    _visit(ast.trueExp);
    sb.write(" : ");
    _visit(ast.falseExp);
  }

  @override
  void visitIfNull(IfNull ast, dynamic context) {
    this._visit(ast.condition);
    sb.write(" ?? ");
    _visit(ast.nullExp);
  }

  @override
  void visitPipe(BindingPipe ast, dynamic context) {
    sb.write("(");
    _visit(ast.exp);
    sb.write(' | ${ast.name}');
    for (var arg in ast.args) {
      sb.write(":");
      _visit(arg);
    }
    sb.write(")");
  }

  @override
  void visitFunctionCall(FunctionCall ast, dynamic context) {
    _visit(ast.target);
    sb.write("(");
    var isFirst = true;
    for (var arg in ast.args) {
      if (!isFirst) sb.write(", ");
      isFirst = false;
      _visit(arg);
    }
    for (var namedArg in ast.namedArgs) {
      if (!isFirst) sb.write(", ");
      isFirst = false;
      namedArg.visit(this);
    }
    sb.write(")");
  }

  @override
  void visitNamedExpr(NamedExpr ast, _) {
    sb.write("${ast.name}: ");
    ast.expression.visit(this);
  }

  @override
  void visitImplicitReceiver(ImplicitReceiver ast, dynamic context) {}

  @override
  void visitInterpolation(Interpolation ast, dynamic context) {
    for (var i = 0; i < ast.strings.length; i++) {
      sb.write(ast.strings[i]);
      if (i < ast.expressions.length) {
        sb.write("{{ ");
        _visit(ast.expressions[i]);
        sb.write(" }}");
      }
    }
  }

  @override
  void visitKeyedRead(KeyedRead ast, dynamic context) {
    _visit(ast.obj);
    sb.write("[");
    _visit(ast.key);
    sb.write("]");
  }

  @override
  void visitKeyedWrite(KeyedWrite ast, dynamic context) {
    _visit(ast.obj);
    sb.write("[");
    _visit(ast.key);
    sb.write("] = ");
    _visit(ast.value);
  }

  @override
  void visitLiteralArray(LiteralArray ast, dynamic context) {
    sb.write("[");
    var isFirst = true;
    for (var expression in ast.expressions) {
      if (!isFirst) sb.write(", ");
      isFirst = false;
      _visit(expression);
    }
    sb.write("]");
  }

  @override
  void visitLiteralPrimitive(LiteralPrimitive ast, dynamic context) {
    if (ast.value is String) {
      sb.write('"${ast.value.replaceAll(Unparser._quoteRegExp, '"')}"');
    } else {
      sb.write('${ast.value}');
    }
  }

  @override
  void visitMethodCall(MethodCall ast, dynamic context) {
    _visit(ast.receiver);
    sb.write(
        ast.receiver is ImplicitReceiver ? '${ast.name}(' : '.${ast.name}(');
    var isFirst = true;
    for (var arg in ast.args) {
      if (!isFirst) sb.write(", ");
      isFirst = false;
      _visit(arg);
    }
    for (var namedArg in ast.namedArgs) {
      if (!isFirst) sb.write(", ");
      isFirst = false;
      namedArg.visit(this);
    }
    sb.write(")");
  }

  @override
  void visitPrefixNot(PrefixNot ast, dynamic context) {
    sb.write("!");
    _visit(ast.expression);
  }

  @override
  void visitSafePropertyRead(SafePropertyRead ast, dynamic context) {
    _visit(ast.receiver);
    sb.write('?.${ast.name}');
  }

  @override
  void visitSafeMethodCall(SafeMethodCall ast, dynamic context) {
    _visit(ast.receiver);
    sb.write('?.${ast.name}(');
    var isFirst = true;
    for (var arg in ast.args) {
      if (!isFirst) sb.write(", ");
      isFirst = false;
      _visit(arg);
    }
    for (var namedArg in ast.namedArgs) {
      if (!isFirst) sb.write(", ");
      isFirst = false;
      namedArg.visit(this);
    }
    sb.write(")");
  }

  @override
  void visitStaticRead(StaticRead ast, dynamic context) {
    sb.write(ast.id.name);
  }

  @override
  void visitEmptyExpr(EmptyExpr ast, dynamic context) {}

  void _visit(AST ast) {
    ast.visit(this);
  }
}
