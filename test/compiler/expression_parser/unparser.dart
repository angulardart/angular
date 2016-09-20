library angular2.test.compiler.expression_parser.unparser;

import "package:angular2/src/compiler/expression_parser/ast.dart";

class Unparser implements AstVisitor {
  static var _quoteRegExp = new RegExp(r'"');
  String _expression;
  unparse(AST ast) {
    this._expression = "";
    this._visit(ast);
    return this._expression;
  }

  void visitPropertyRead(PropertyRead ast, dynamic context) {
    this._visit(ast.receiver);
    this._expression += ast.receiver is ImplicitReceiver
        ? '''${ ast . name}'''
        : '''.${ ast . name}''';
  }

  void visitPropertyWrite(PropertyWrite ast, dynamic context) {
    this._visit(ast.receiver);
    this._expression += ast.receiver is ImplicitReceiver
        ? '''${ ast . name} = '''
        : '''.${ ast . name} = ''';
    this._visit(ast.value);
  }

  void visitBinary(Binary ast, dynamic context) {
    this._visit(ast.left);
    this._expression += ''' ${ ast . operation} ''';
    this._visit(ast.right);
  }

  void visitChain(Chain ast, dynamic context) {
    var len = ast.expressions.length;
    for (var i = 0; i < len; i++) {
      this._visit(ast.expressions[i]);
      this._expression += i == len - 1 ? ";" : "; ";
    }
  }

  void visitConditional(Conditional ast, dynamic context) {
    this._visit(ast.condition);
    this._expression += " ? ";
    this._visit(ast.trueExp);
    this._expression += " : ";
    this._visit(ast.falseExp);
  }

  void visitIfNull(IfNull ast, dynamic context) {
    this._visit(ast.condition);
    this._expression += " ?? ";
    this._visit(ast.nullExp);
  }

  void visitPipe(BindingPipe ast, dynamic context) {
    this._expression += "(";
    this._visit(ast.exp);
    this._expression += ''' | ${ ast . name}''';
    ast.args.forEach((arg) {
      this._expression += ":";
      this._visit(arg);
    });
    this._expression += ")";
  }

  void visitFunctionCall(FunctionCall ast, dynamic context) {
    this._visit(ast.target);
    this._expression += "(";
    var isFirst = true;
    ast.args.forEach((arg) {
      if (!isFirst) this._expression += ", ";
      isFirst = false;
      this._visit(arg);
    });
    this._expression += ")";
  }

  void visitImplicitReceiver(ImplicitReceiver ast, dynamic context) {}
  void visitInterpolation(Interpolation ast, dynamic context) {
    for (var i = 0; i < ast.strings.length; i++) {
      this._expression += ast.strings[i];
      if (i < ast.expressions.length) {
        this._expression += "{{ ";
        this._visit(ast.expressions[i]);
        this._expression += " }}";
      }
    }
  }

  void visitKeyedRead(KeyedRead ast, dynamic context) {
    this._visit(ast.obj);
    this._expression += "[";
    this._visit(ast.key);
    this._expression += "]";
  }

  void visitKeyedWrite(KeyedWrite ast, dynamic context) {
    this._visit(ast.obj);
    this._expression += "[";
    this._visit(ast.key);
    this._expression += "] = ";
    this._visit(ast.value);
  }

  void visitLiteralArray(LiteralArray ast, dynamic context) {
    this._expression += "[";
    var isFirst = true;
    ast.expressions.forEach((expression) {
      if (!isFirst) this._expression += ", ";
      isFirst = false;
      this._visit(expression);
    });
    this._expression += "]";
  }

  void visitLiteralMap(LiteralMap ast, dynamic context) {
    this._expression += "{";
    var isFirst = true;
    for (var i = 0; i < ast.keys.length; i++) {
      if (!isFirst) this._expression += ", ";
      isFirst = false;
      this._expression += '''${ ast . keys [ i ]}: ''';
      this._visit(ast.values[i]);
    }
    this._expression += "}";
  }

  void visitLiteralPrimitive(LiteralPrimitive ast, dynamic context) {
    if (ast.value is String) {
      this._expression +=
          '''"${ ast.value.replaceAll ( Unparser . _quoteRegExp , "\"" )}"''';
    } else {
      this._expression += '''${ ast . value}''';
    }
  }

  void visitMethodCall(MethodCall ast, dynamic context) {
    this._visit(ast.receiver);
    this._expression += ast.receiver is ImplicitReceiver
        ? '''${ ast . name}('''
        : '''.${ ast . name}(''';
    var isFirst = true;
    ast.args.forEach((arg) {
      if (!isFirst) this._expression += ", ";
      isFirst = false;
      this._visit(arg);
    });
    this._expression += ")";
  }

  void visitPrefixNot(PrefixNot ast, dynamic context) {
    this._expression += "!";
    this._visit(ast.expression);
  }

  visitSafePropertyRead(SafePropertyRead ast, dynamic context) {
    this._visit(ast.receiver);
    this._expression += '''?.${ ast . name}''';
  }

  visitSafeMethodCall(SafeMethodCall ast, dynamic context) {
    this._visit(ast.receiver);
    this._expression += '''?.${ ast . name}(''';
    var isFirst = true;
    ast.args.forEach((arg) {
      if (!isFirst) this._expression += ", ";
      isFirst = false;
      this._visit(arg);
    });
    this._expression += ")";
  }

  visitQuote(Quote ast, dynamic context) {
    this._expression +=
        '''${ ast . prefix}:${ ast . uninterpretedExpression}''';
  }

  _visit(AST ast) {
    ast.visit(this);
  }
}
