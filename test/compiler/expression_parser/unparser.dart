library angular2.test.compiler.expression_parser.unparser;

import "package:angular2/src/compiler/expression_parser/ast.dart";
import "package:angular2/src/facade/lang.dart" show StringWrapper, isString;

class Unparser implements AstVisitor {
  static var _quoteRegExp = new RegExp(r'"');
  String _expression;
  unparse(AST ast) {
    this._expression = "";
    this._visit(ast);
    return this._expression;
  }

  visitPropertyRead(PropertyRead ast, dynamic context) {
    this._visit(ast.receiver);
    this._expression += ast.receiver is ImplicitReceiver
        ? '''${ ast . name}'''
        : '''.${ ast . name}''';
  }

  visitPropertyWrite(PropertyWrite ast, dynamic context) {
    this._visit(ast.receiver);
    this._expression += ast.receiver is ImplicitReceiver
        ? '''${ ast . name} = '''
        : '''.${ ast . name} = ''';
    this._visit(ast.value);
  }

  visitBinary(Binary ast, dynamic context) {
    this._visit(ast.left);
    this._expression += ''' ${ ast . operation} ''';
    this._visit(ast.right);
  }

  visitChain(Chain ast, dynamic context) {
    var len = ast.expressions.length;
    for (var i = 0; i < len; i++) {
      this._visit(ast.expressions[i]);
      this._expression += i == len - 1 ? ";" : "; ";
    }
  }

  visitConditional(Conditional ast, dynamic context) {
    this._visit(ast.condition);
    this._expression += " ? ";
    this._visit(ast.trueExp);
    this._expression += " : ";
    this._visit(ast.falseExp);
  }

  visitPipe(BindingPipe ast, dynamic context) {
    this._expression += "(";
    this._visit(ast.exp);
    this._expression += ''' | ${ ast . name}''';
    ast.args.forEach((arg) {
      this._expression += ":";
      this._visit(arg);
    });
    this._expression += ")";
  }

  visitFunctionCall(FunctionCall ast, dynamic context) {
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

  visitImplicitReceiver(ImplicitReceiver ast, dynamic context) {}
  visitInterpolation(Interpolation ast, dynamic context) {
    for (var i = 0; i < ast.strings.length; i++) {
      this._expression += ast.strings[i];
      if (i < ast.expressions.length) {
        this._expression += "{{ ";
        this._visit(ast.expressions[i]);
        this._expression += " }}";
      }
    }
  }

  visitKeyedRead(KeyedRead ast, dynamic context) {
    this._visit(ast.obj);
    this._expression += "[";
    this._visit(ast.key);
    this._expression += "]";
  }

  visitKeyedWrite(KeyedWrite ast, dynamic context) {
    this._visit(ast.obj);
    this._expression += "[";
    this._visit(ast.key);
    this._expression += "] = ";
    this._visit(ast.value);
  }

  visitLiteralArray(LiteralArray ast, dynamic context) {
    this._expression += "[";
    var isFirst = true;
    ast.expressions.forEach((expression) {
      if (!isFirst) this._expression += ", ";
      isFirst = false;
      this._visit(expression);
    });
    this._expression += "]";
  }

  visitLiteralMap(LiteralMap ast, dynamic context) {
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

  visitLiteralPrimitive(LiteralPrimitive ast, dynamic context) {
    if (isString(ast.value)) {
      this._expression +=
          '''"${ StringWrapper . replaceAll ( ast . value , Unparser . _quoteRegExp , "\"" )}"''';
    } else {
      this._expression += '''${ ast . value}''';
    }
  }

  visitMethodCall(MethodCall ast, dynamic context) {
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

  visitPrefixNot(PrefixNot ast, dynamic context) {
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
