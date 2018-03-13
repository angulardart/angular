import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/compile_metadata.dart';

class AST {
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) {
    return null;
  }

  @override
  String toString() => 'AST';
}

class EmptyExpr extends AST {
  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitEmptyExpr(this, context);
}

class StaticRead extends AST {
  final CompileIdentifierMetadata id;

  /// The analyzed class being read, if this is a class reference.
  AnalyzedClass get analyzedClass => id.analyzedClass;

  StaticRead(this.id);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitStaticRead(this, context);
}

class ImplicitReceiver extends AST {
  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitImplicitReceiver(this, context);
}

/// Multiple expressions separated by a semicolon.
class Chain extends AST {
  List<AST> expressions;
  Chain(this.expressions);
  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitChain(this, context);
}

class Conditional extends AST {
  AST condition;
  AST trueExp;
  AST falseExp;
  Conditional(this.condition, this.trueExp, this.falseExp);
  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitConditional(this, context);
}

/// Represents the ?? expression in Dart
class IfNull extends AST {
  /// Condition for the null check and result if it is not null.
  final AST condition;

  /// Result if the `condition` operand is null.
  final AST nullExp;

  IfNull(this.condition, this.nullExp);
  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitIfNull(this, context);
}

class PropertyRead extends AST {
  AST receiver;
  String name;
  PropertyRead(this.receiver, this.name);
  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitPropertyRead(this, context);
}

class PropertyWrite extends AST {
  AST receiver;
  String name;
  AST value;
  PropertyWrite(this.receiver, this.name, this.value);
  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) {
    return visitor.visitPropertyWrite(this, context);
  }
}

class SafePropertyRead extends AST {
  AST receiver;
  String name;
  SafePropertyRead(this.receiver, this.name);
  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitSafePropertyRead(this, context);
}

class KeyedRead extends AST {
  AST obj;
  AST key;
  KeyedRead(this.obj, this.key);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitKeyedRead(this, context);
}

class KeyedWrite extends AST {
  AST obj;
  AST key;
  AST value;
  KeyedWrite(this.obj, this.key, this.value);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitKeyedWrite(this, context);
}

class BindingPipe extends AST {
  AST exp;
  String name;
  List<AST> args;
  BindingPipe(this.exp, this.name, this.args);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitPipe(this, context);
}

class LiteralPrimitive extends AST {
  var value;
  LiteralPrimitive(this.value);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitLiteralPrimitive(this, context);
}

class LiteralArray extends AST {
  List<AST> expressions;
  LiteralArray(this.expressions);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitLiteralArray(this, context);
}

class LiteralMap extends AST {
  List<String> keys;
  List<AST> values;
  LiteralMap(this.keys, this.values);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) {
    return visitor.visitLiteralMap(this, context);
  }
}

class Interpolation extends AST {
  List<String> strings;
  List<AST> expressions;
  Interpolation(this.strings, this.expressions);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) {
    return visitor.visitInterpolation(this, context);
  }
}

class Binary extends AST {
  String operation;
  AST left;
  AST right;
  Binary(this.operation, this.left, this.right);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitBinary(this, context);
}

class PrefixNot extends AST {
  AST expression;
  PrefixNot(this.expression);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitPrefixNot(this, context);
}

class MethodCall extends AST {
  AST receiver;
  String name;
  List<AST> args;
  MethodCall(this.receiver, this.name, this.args);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitMethodCall(this, context);
}

class SafeMethodCall extends AST {
  AST receiver;
  String name;
  List<AST> args;
  SafeMethodCall(this.receiver, this.name, this.args);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitSafeMethodCall(this, context);
}

class FunctionCall extends AST {
  AST target;
  List<AST> args;
  FunctionCall(this.target, this.args);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) =>
      visitor.visitFunctionCall(this, context);
}

class ASTWithSource extends AST {
  AST ast;
  String source;
  String location;
  ASTWithSource(this.ast, this.source, this.location);

  @override
  R visit<R, C>(AstVisitor<R, C> visitor, [C context]) {
    return this.ast.visit(visitor, context);
  }

  @override
  String toString() => '$source in $location';
}

class TemplateBinding {
  String key;
  bool keyIsVar;
  String name;
  ASTWithSource expression;
  TemplateBinding(this.key, this.keyIsVar, this.name, this.expression);
}

abstract class AstVisitor<R, C> {
  R visitBinary(Binary ast, C context);
  R visitChain(Chain ast, C context);
  R visitConditional(Conditional ast, C context);
  R visitEmptyExpr(EmptyExpr ast, C context);
  R visitFunctionCall(FunctionCall ast, C context);
  R visitIfNull(IfNull ast, C context);
  R visitImplicitReceiver(ImplicitReceiver ast, C context);
  R visitInterpolation(Interpolation ast, C context);
  R visitKeyedRead(KeyedRead ast, C context);
  R visitKeyedWrite(KeyedWrite ast, C context);
  R visitLiteralArray(LiteralArray ast, C context);
  R visitLiteralMap(LiteralMap ast, C context);
  R visitLiteralPrimitive(LiteralPrimitive ast, C context);
  R visitMethodCall(MethodCall ast, C context);
  R visitPipe(BindingPipe ast, C context);
  R visitPrefixNot(PrefixNot ast, C context);
  R visitPropertyRead(PropertyRead ast, C context);
  R visitPropertyWrite(PropertyWrite ast, C context);
  R visitSafeMethodCall(SafeMethodCall ast, C context);
  R visitSafePropertyRead(SafePropertyRead ast, C context);
  R visitStaticRead(StaticRead ast, C context);
}

class RecursiveAstVisitor implements AstVisitor {
  @override
  dynamic visitBinary(Binary ast, dynamic context) {
    ast.left.visit(this);
    ast.right.visit(this);
    return null;
  }

  @override
  dynamic visitChain(Chain ast, dynamic context) {
    return this.visitAll(ast.expressions, context);
  }

  @override
  dynamic visitConditional(Conditional ast, dynamic context) {
    ast.condition.visit(this);
    ast.trueExp.visit(this);
    ast.falseExp.visit(this);
    return null;
  }

  @override
  dynamic visitEmptyExpr(EmptyExpr ast, dynamic context) {
    return null;
  }

  @override
  dynamic visitPipe(BindingPipe ast, dynamic context) {
    ast.exp.visit(this);
    this.visitAll(ast.args, context);
    return null;
  }

  @override
  dynamic visitFunctionCall(FunctionCall ast, dynamic context) {
    ast.target.visit(this);
    this.visitAll(ast.args, context);
    return null;
  }

  @override
  dynamic visitIfNull(IfNull ast, dynamic context) {
    ast.condition.visit(this);
    ast.nullExp.visit(this);
    return null;
  }

  @override
  dynamic visitImplicitReceiver(ImplicitReceiver ast, dynamic context) {
    return null;
  }

  @override
  dynamic visitInterpolation(Interpolation ast, dynamic context) {
    return this.visitAll(ast.expressions, context);
  }

  @override
  dynamic visitKeyedRead(KeyedRead ast, dynamic context) {
    ast.obj.visit(this);
    ast.key.visit(this);
    return null;
  }

  @override
  dynamic visitKeyedWrite(KeyedWrite ast, dynamic context) {
    ast.obj.visit(this);
    ast.key.visit(this);
    ast.value.visit(this);
    return null;
  }

  @override
  dynamic visitLiteralArray(LiteralArray ast, dynamic context) {
    return this.visitAll(ast.expressions, context);
  }

  @override
  dynamic visitLiteralMap(LiteralMap ast, dynamic context) {
    return this.visitAll(ast.values, context);
  }

  @override
  dynamic visitLiteralPrimitive(LiteralPrimitive ast, dynamic context) {
    return null;
  }

  @override
  dynamic visitMethodCall(MethodCall ast, dynamic context) {
    ast.receiver.visit(this);
    return this.visitAll(ast.args, context);
  }

  @override
  dynamic visitPrefixNot(PrefixNot ast, dynamic context) {
    ast.expression.visit(this);
    return null;
  }

  @override
  dynamic visitPropertyRead(PropertyRead ast, dynamic context) {
    ast.receiver.visit(this);
    return null;
  }

  @override
  dynamic visitPropertyWrite(PropertyWrite ast, dynamic context) {
    ast.receiver.visit(this);
    ast.value.visit(this);
    return null;
  }

  @override
  dynamic visitSafePropertyRead(SafePropertyRead ast, dynamic context) {
    ast.receiver.visit(this);
    return null;
  }

  @override
  dynamic visitSafeMethodCall(SafeMethodCall ast, dynamic context) {
    ast.receiver.visit(this);
    return this.visitAll(ast.args, context);
  }

  @override
  dynamic visitStaticRead(StaticRead ast, dynamic context) {
    return null;
  }

  dynamic visitAll(List<AST> asts, dynamic context) {
    for (var ast in asts) {
      ast.visit(this, context);
    }
    return null;
  }
}

class AstTransformer implements AstVisitor<AST, Null> {
  @override
  AST visitImplicitReceiver(ImplicitReceiver ast, _) => ast;

  @override
  AST visitStaticRead(StaticRead ast, _) => ast;

  @override
  AST visitInterpolation(Interpolation ast, _) =>
      new Interpolation(ast.strings, this._visitAll(ast.expressions));

  @override
  AST visitLiteralPrimitive(LiteralPrimitive ast, _) =>
      new LiteralPrimitive(ast.value);

  @override
  AST visitPropertyRead(PropertyRead ast, _) =>
      new PropertyRead(ast.receiver.visit(this), ast.name);

  @override
  AST visitPropertyWrite(PropertyWrite ast, _) =>
      new PropertyWrite(ast.receiver.visit(this), ast.name, ast.value);

  @override
  AST visitSafePropertyRead(SafePropertyRead ast, _) =>
      new SafePropertyRead(ast.receiver.visit(this), ast.name);

  @override
  AST visitMethodCall(MethodCall ast, _) => new MethodCall(
      ast.receiver.visit(this), ast.name, this._visitAll(ast.args));

  @override
  AST visitSafeMethodCall(SafeMethodCall ast, _) => new SafeMethodCall(
      ast.receiver.visit(this), ast.name, this._visitAll(ast.args));

  @override
  AST visitFunctionCall(FunctionCall ast, _) =>
      new FunctionCall(ast.target.visit(this), this._visitAll(ast.args));

  @override
  AST visitLiteralArray(LiteralArray ast, _) =>
      new LiteralArray(this._visitAll(ast.expressions));

  @override
  AST visitLiteralMap(LiteralMap ast, _) =>
      new LiteralMap(ast.keys, this._visitAll(ast.values));

  @override
  AST visitBinary(Binary ast, _) =>
      new Binary(ast.operation, ast.left.visit(this), ast.right.visit(this));

  @override
  AST visitPrefixNot(PrefixNot ast, _) =>
      new PrefixNot(ast.expression.visit(this));

  @override
  AST visitConditional(Conditional ast, _) => new Conditional(
      ast.condition.visit(this),
      ast.trueExp.visit(this),
      ast.falseExp.visit(this));

  @override
  AST visitIfNull(IfNull ast, _) =>
      new IfNull(ast.condition.visit(this), ast.nullExp.visit(this));

  @override
  AST visitPipe(BindingPipe ast, _) =>
      new BindingPipe(ast.exp.visit(this), ast.name, this._visitAll(ast.args));

  @override
  AST visitKeyedRead(KeyedRead ast, _) =>
      new KeyedRead(ast.obj.visit(this), ast.key.visit(this));

  @override
  AST visitKeyedWrite(KeyedWrite ast, _) => new KeyedWrite(
      ast.obj.visit(this), ast.key.visit(this), ast.value.visit(this));

  @override
  AST visitChain(Chain ast, _) => new Chain(this._visitAll(ast.expressions));

  @override
  AST visitEmptyExpr(EmptyExpr ast, _) => new EmptyExpr();

  List<AST> _visitAll(List<AST> asts) {
    var res = new List<AST>(asts.length);
    for (var i = 0; i < asts.length; ++i) {
      res[i] = asts[i].visit(this);
    }
    return res;
  }
}
