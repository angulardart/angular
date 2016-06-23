library angular2.src.compiler.expression_parser.ast;

import "package:angular2/src/facade/collection.dart" show ListWrapper;

class AST {
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return null;
  }

  String toString() {
    return "AST";
  }
}

/**
 * Represents a quoted expression of the form:
 *
 * quote = prefix `:` uninterpretedExpression
 * prefix = identifier
 * uninterpretedExpression = arbitrary string
 *
 * A quoted expression is meant to be pre-processed by an AST transformer that
 * converts it into another AST that no longer contains quoted expressions.
 * It is meant to allow third-party developers to extend Angular template
 * expression language. The `uninterpretedExpression` part of the quote is
 * therefore not interpreted by the Angular's own expression parser.
 */
class Quote extends AST {
  String prefix;
  String uninterpretedExpression;
  dynamic location;
  Quote(this.prefix, this.uninterpretedExpression, this.location) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitQuote(this, context);
  }

  String toString() {
    return "Quote";
  }
}

class EmptyExpr extends AST {
  visit(AstVisitor visitor, [dynamic context = null]) {}
}

class ImplicitReceiver extends AST {
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitImplicitReceiver(this, context);
  }
}

/**
 * Multiple expressions separated by a semicolon.
 */
class Chain extends AST {
  List<dynamic> expressions;
  Chain(this.expressions) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitChain(this, context);
  }
}

class Conditional extends AST {
  AST condition;
  AST trueExp;
  AST falseExp;
  Conditional(this.condition, this.trueExp, this.falseExp) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitConditional(this, context);
  }
}

class PropertyRead extends AST {
  AST receiver;
  String name;
  PropertyRead(this.receiver, this.name) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitPropertyRead(this, context);
  }
}

class PropertyWrite extends AST {
  AST receiver;
  String name;
  AST value;
  PropertyWrite(this.receiver, this.name, this.value) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitPropertyWrite(this, context);
  }
}

class SafePropertyRead extends AST {
  AST receiver;
  String name;
  SafePropertyRead(this.receiver, this.name) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitSafePropertyRead(this, context);
  }
}

class KeyedRead extends AST {
  AST obj;
  AST key;
  KeyedRead(this.obj, this.key) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitKeyedRead(this, context);
  }
}

class KeyedWrite extends AST {
  AST obj;
  AST key;
  AST value;
  KeyedWrite(this.obj, this.key, this.value) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitKeyedWrite(this, context);
  }
}

class BindingPipe extends AST {
  AST exp;
  String name;
  List<dynamic> args;
  BindingPipe(this.exp, this.name, this.args) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitPipe(this, context);
  }
}

class LiteralPrimitive extends AST {
  var value;
  LiteralPrimitive(this.value) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitLiteralPrimitive(this, context);
  }
}

class LiteralArray extends AST {
  List<dynamic> expressions;
  LiteralArray(this.expressions) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitLiteralArray(this, context);
  }
}

class LiteralMap extends AST {
  List<dynamic> keys;
  List<dynamic> values;
  LiteralMap(this.keys, this.values) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitLiteralMap(this, context);
  }
}

class Interpolation extends AST {
  List<dynamic> strings;
  List<dynamic> expressions;
  Interpolation(this.strings, this.expressions) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitInterpolation(this, context);
  }
}

class Binary extends AST {
  String operation;
  AST left;
  AST right;
  Binary(this.operation, this.left, this.right) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitBinary(this, context);
  }
}

class PrefixNot extends AST {
  AST expression;
  PrefixNot(this.expression) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitPrefixNot(this, context);
  }
}

class MethodCall extends AST {
  AST receiver;
  String name;
  List<dynamic> args;
  MethodCall(this.receiver, this.name, this.args) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitMethodCall(this, context);
  }
}

class SafeMethodCall extends AST {
  AST receiver;
  String name;
  List<dynamic> args;
  SafeMethodCall(this.receiver, this.name, this.args) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitSafeMethodCall(this, context);
  }
}

class FunctionCall extends AST {
  AST target;
  List<dynamic> args;
  FunctionCall(this.target, this.args) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return visitor.visitFunctionCall(this, context);
  }
}

class ASTWithSource extends AST {
  AST ast;
  String source;
  String location;
  ASTWithSource(this.ast, this.source, this.location) : super() {
    /* super call moved to initializer */;
  }
  dynamic visit(AstVisitor visitor, [dynamic context = null]) {
    return this.ast.visit(visitor, context);
  }

  String toString() {
    return '''${ this . source} in ${ this . location}''';
  }
}

class TemplateBinding {
  String key;
  bool keyIsVar;
  String name;
  ASTWithSource expression;
  TemplateBinding(this.key, this.keyIsVar, this.name, this.expression) {}
}

abstract class AstVisitor {
  dynamic visitBinary(Binary ast, dynamic context);
  dynamic visitChain(Chain ast, dynamic context);
  dynamic visitConditional(Conditional ast, dynamic context);
  dynamic visitFunctionCall(FunctionCall ast, dynamic context);
  dynamic visitImplicitReceiver(ImplicitReceiver ast, dynamic context);
  dynamic visitInterpolation(Interpolation ast, dynamic context);
  dynamic visitKeyedRead(KeyedRead ast, dynamic context);
  dynamic visitKeyedWrite(KeyedWrite ast, dynamic context);
  dynamic visitLiteralArray(LiteralArray ast, dynamic context);
  dynamic visitLiteralMap(LiteralMap ast, dynamic context);
  dynamic visitLiteralPrimitive(LiteralPrimitive ast, dynamic context);
  dynamic visitMethodCall(MethodCall ast, dynamic context);
  dynamic visitPipe(BindingPipe ast, dynamic context);
  dynamic visitPrefixNot(PrefixNot ast, dynamic context);
  dynamic visitPropertyRead(PropertyRead ast, dynamic context);
  dynamic visitPropertyWrite(PropertyWrite ast, dynamic context);
  dynamic visitQuote(Quote ast, dynamic context);
  dynamic visitSafeMethodCall(SafeMethodCall ast, dynamic context);
  dynamic visitSafePropertyRead(SafePropertyRead ast, dynamic context);
}

class RecursiveAstVisitor implements AstVisitor {
  dynamic visitBinary(Binary ast, dynamic context) {
    ast.left.visit(this);
    ast.right.visit(this);
    return null;
  }

  dynamic visitChain(Chain ast, dynamic context) {
    return this.visitAll(ast.expressions, context);
  }

  dynamic visitConditional(Conditional ast, dynamic context) {
    ast.condition.visit(this);
    ast.trueExp.visit(this);
    ast.falseExp.visit(this);
    return null;
  }

  dynamic visitPipe(BindingPipe ast, dynamic context) {
    ast.exp.visit(this);
    this.visitAll(ast.args, context);
    return null;
  }

  dynamic visitFunctionCall(FunctionCall ast, dynamic context) {
    ast.target.visit(this);
    this.visitAll(ast.args, context);
    return null;
  }

  dynamic visitImplicitReceiver(ImplicitReceiver ast, dynamic context) {
    return null;
  }

  dynamic visitInterpolation(Interpolation ast, dynamic context) {
    return this.visitAll(ast.expressions, context);
  }

  dynamic visitKeyedRead(KeyedRead ast, dynamic context) {
    ast.obj.visit(this);
    ast.key.visit(this);
    return null;
  }

  dynamic visitKeyedWrite(KeyedWrite ast, dynamic context) {
    ast.obj.visit(this);
    ast.key.visit(this);
    ast.value.visit(this);
    return null;
  }

  dynamic visitLiteralArray(LiteralArray ast, dynamic context) {
    return this.visitAll(ast.expressions, context);
  }

  dynamic visitLiteralMap(LiteralMap ast, dynamic context) {
    return this.visitAll(ast.values, context);
  }

  dynamic visitLiteralPrimitive(LiteralPrimitive ast, dynamic context) {
    return null;
  }

  dynamic visitMethodCall(MethodCall ast, dynamic context) {
    ast.receiver.visit(this);
    return this.visitAll(ast.args, context);
  }

  dynamic visitPrefixNot(PrefixNot ast, dynamic context) {
    ast.expression.visit(this);
    return null;
  }

  dynamic visitPropertyRead(PropertyRead ast, dynamic context) {
    ast.receiver.visit(this);
    return null;
  }

  dynamic visitPropertyWrite(PropertyWrite ast, dynamic context) {
    ast.receiver.visit(this);
    ast.value.visit(this);
    return null;
  }

  dynamic visitSafePropertyRead(SafePropertyRead ast, dynamic context) {
    ast.receiver.visit(this);
    return null;
  }

  dynamic visitSafeMethodCall(SafeMethodCall ast, dynamic context) {
    ast.receiver.visit(this);
    return this.visitAll(ast.args, context);
  }

  dynamic visitAll(List<AST> asts, dynamic context) {
    asts.forEach((ast) => ast.visit(this, context));
    return null;
  }

  dynamic visitQuote(Quote ast, dynamic context) {
    return null;
  }
}

class AstTransformer implements AstVisitor {
  AST visitImplicitReceiver(ImplicitReceiver ast, dynamic context) {
    return ast;
  }

  AST visitInterpolation(Interpolation ast, dynamic context) {
    return new Interpolation(ast.strings, this.visitAll(ast.expressions));
  }

  AST visitLiteralPrimitive(LiteralPrimitive ast, dynamic context) {
    return new LiteralPrimitive(ast.value);
  }

  AST visitPropertyRead(PropertyRead ast, dynamic context) {
    return new PropertyRead(ast.receiver.visit(this), ast.name);
  }

  AST visitPropertyWrite(PropertyWrite ast, dynamic context) {
    return new PropertyWrite(ast.receiver.visit(this), ast.name, ast.value);
  }

  AST visitSafePropertyRead(SafePropertyRead ast, dynamic context) {
    return new SafePropertyRead(ast.receiver.visit(this), ast.name);
  }

  AST visitMethodCall(MethodCall ast, dynamic context) {
    return new MethodCall(
        ast.receiver.visit(this), ast.name, this.visitAll(ast.args));
  }

  AST visitSafeMethodCall(SafeMethodCall ast, dynamic context) {
    return new SafeMethodCall(
        ast.receiver.visit(this), ast.name, this.visitAll(ast.args));
  }

  AST visitFunctionCall(FunctionCall ast, dynamic context) {
    return new FunctionCall(ast.target.visit(this), this.visitAll(ast.args));
  }

  AST visitLiteralArray(LiteralArray ast, dynamic context) {
    return new LiteralArray(this.visitAll(ast.expressions));
  }

  AST visitLiteralMap(LiteralMap ast, dynamic context) {
    return new LiteralMap(ast.keys, this.visitAll(ast.values));
  }

  AST visitBinary(Binary ast, dynamic context) {
    return new Binary(
        ast.operation, ast.left.visit(this), ast.right.visit(this));
  }

  AST visitPrefixNot(PrefixNot ast, dynamic context) {
    return new PrefixNot(ast.expression.visit(this));
  }

  AST visitConditional(Conditional ast, dynamic context) {
    return new Conditional(ast.condition.visit(this), ast.trueExp.visit(this),
        ast.falseExp.visit(this));
  }

  AST visitPipe(BindingPipe ast, dynamic context) {
    return new BindingPipe(
        ast.exp.visit(this), ast.name, this.visitAll(ast.args));
  }

  AST visitKeyedRead(KeyedRead ast, dynamic context) {
    return new KeyedRead(ast.obj.visit(this), ast.key.visit(this));
  }

  AST visitKeyedWrite(KeyedWrite ast, dynamic context) {
    return new KeyedWrite(
        ast.obj.visit(this), ast.key.visit(this), ast.value.visit(this));
  }

  List<dynamic> visitAll(List<dynamic> asts) {
    var res = ListWrapper.createFixedSize(asts.length);
    for (var i = 0; i < asts.length; ++i) {
      res[i] = asts[i].visit(this);
    }
    return res;
  }

  AST visitChain(Chain ast, dynamic context) {
    return new Chain(this.visitAll(ast.expressions));
  }

  AST visitQuote(Quote ast, dynamic context) {
    return new Quote(ast.prefix, ast.uninterpretedExpression, ast.location);
  }
}
