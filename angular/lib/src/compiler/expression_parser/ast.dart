import 'package:angular/src/compiler/compile_metadata.dart';

// TODO: Remove the following lines (for --no-implicit-casts).
// ignore_for_file: argument_type_not_assignable
// ignore_for_file: invalid_assignment
// ignore_for_file: list_element_type_not_assignable
// ignore_for_file: non_bool_operand
// ignore_for_file: return_of_invalid_type

class AST {
  dynamic visit(AstVisitor visitor, [dynamic context]) {
    return null;
  }

  @override
  String toString() => 'AST';
}

class EmptyExpr extends AST {
  @override
  void visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitEmptyExpr(this, context);
}

class StaticRead extends AST {
  CompileIdentifierMetadata id;
  StaticRead(this.id);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitStaticRead(this, context);
}

class ImplicitReceiver extends AST {
  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitImplicitReceiver(this, context);
}

/// Multiple expressions separated by a semicolon.
class Chain extends AST {
  List<dynamic> expressions;
  Chain(this.expressions);
  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitChain(this, context);
}

class Conditional extends AST {
  AST condition;
  AST trueExp;
  AST falseExp;
  Conditional(this.condition, this.trueExp, this.falseExp);
  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
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
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitIfNull(this, context);
}

class PropertyRead extends AST {
  AST receiver;
  String name;
  PropertyRead(this.receiver, this.name);
  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitPropertyRead(this, context);
}

class PropertyWrite extends AST {
  AST receiver;
  String name;
  AST value;
  PropertyWrite(this.receiver, this.name, this.value);
  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) {
    return visitor.visitPropertyWrite(this, context);
  }
}

class SafePropertyRead extends AST {
  AST receiver;
  String name;
  SafePropertyRead(this.receiver, this.name);
  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitSafePropertyRead(this, context);
}

class KeyedRead extends AST {
  AST obj;
  AST key;
  KeyedRead(this.obj, this.key);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitKeyedRead(this, context);
}

class KeyedWrite extends AST {
  AST obj;
  AST key;
  AST value;
  KeyedWrite(this.obj, this.key, this.value);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitKeyedWrite(this, context);
}

class BindingPipe extends AST {
  AST exp;
  String name;
  List<dynamic> args;
  BindingPipe(this.exp, this.name, this.args);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitPipe(this, context);
}

class LiteralPrimitive extends AST {
  var value;
  LiteralPrimitive(this.value);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitLiteralPrimitive(this, context);
}

class LiteralArray extends AST {
  List<dynamic> expressions;
  LiteralArray(this.expressions);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitLiteralArray(this, context);
}

class LiteralMap extends AST {
  List<dynamic> keys;
  List<dynamic> values;
  LiteralMap(this.keys, this.values);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) {
    return visitor.visitLiteralMap(this, context);
  }
}

class Interpolation extends AST {
  List<dynamic> strings;
  List<dynamic> expressions;
  Interpolation(this.strings, this.expressions);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) {
    return visitor.visitInterpolation(this, context);
  }
}

class Binary extends AST {
  String operation;
  AST left;
  AST right;
  Binary(this.operation, this.left, this.right);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitBinary(this, context);
}

class PrefixNot extends AST {
  AST expression;
  PrefixNot(this.expression);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitPrefixNot(this, context);
}

class MethodCall extends AST {
  AST receiver;
  String name;
  List<dynamic> args;
  MethodCall(this.receiver, this.name, this.args);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitMethodCall(this, context);
}

class SafeMethodCall extends AST {
  AST receiver;
  String name;
  List<dynamic> args;
  SafeMethodCall(this.receiver, this.name, this.args);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitSafeMethodCall(this, context);
}

class FunctionCall extends AST {
  AST target;
  List<dynamic> args;
  FunctionCall(this.target, this.args);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) =>
      visitor.visitFunctionCall(this, context);
}

class ASTWithSource extends AST {
  AST ast;
  String source;
  String location;
  ASTWithSource(this.ast, this.source, this.location);

  @override
  dynamic visit(AstVisitor visitor, [dynamic context]) {
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

abstract class AstVisitor {
  dynamic visitBinary(Binary ast, dynamic context);
  dynamic visitChain(Chain ast, dynamic context);
  dynamic visitConditional(Conditional ast, dynamic context);
  dynamic visitEmptyExpr(EmptyExpr ast, dynamic context);
  dynamic visitFunctionCall(FunctionCall ast, dynamic context);
  dynamic visitIfNull(IfNull ast, dynamic context);
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
  dynamic visitSafeMethodCall(SafeMethodCall ast, dynamic context);
  dynamic visitSafePropertyRead(SafePropertyRead ast, dynamic context);
  dynamic visitStaticRead(StaticRead ast, dynamic context);
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
    return this.visitAll(ast.expressions as List<AST>, context);
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
    this.visitAll(ast.args as List<AST>, context);
    return null;
  }

  @override
  dynamic visitFunctionCall(FunctionCall ast, dynamic context) {
    ast.target.visit(this);
    this.visitAll(ast.args as List<AST>, context);
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
    return this.visitAll(ast.expressions as List<AST>, context);
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
    return this.visitAll(ast.expressions as List<AST>, context);
  }

  @override
  dynamic visitLiteralMap(LiteralMap ast, dynamic context) {
    return this.visitAll(ast.values as List<AST>, context);
  }

  @override
  dynamic visitLiteralPrimitive(LiteralPrimitive ast, dynamic context) {
    return null;
  }

  @override
  dynamic visitMethodCall(MethodCall ast, dynamic context) {
    ast.receiver.visit(this);
    return this.visitAll(ast.args as List<AST>, context);
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
    return this.visitAll(ast.args as List<AST>, context);
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

class AstTransformer implements AstVisitor {
  @override
  AST visitImplicitReceiver(ImplicitReceiver ast, dynamic context) => ast;

  @override
  AST visitStaticRead(StaticRead ast, dynamic context) => ast;

  @override
  AST visitInterpolation(Interpolation ast, dynamic context) =>
      new Interpolation(ast.strings, this._visitAll(ast.expressions));

  @override
  AST visitLiteralPrimitive(LiteralPrimitive ast, dynamic context) =>
      new LiteralPrimitive(ast.value);

  @override
  AST visitPropertyRead(PropertyRead ast, dynamic context) =>
      new PropertyRead(ast.receiver.visit(this), ast.name);

  @override
  AST visitPropertyWrite(PropertyWrite ast, dynamic context) =>
      new PropertyWrite(ast.receiver.visit(this), ast.name, ast.value);

  @override
  AST visitSafePropertyRead(SafePropertyRead ast, dynamic context) =>
      new SafePropertyRead(ast.receiver.visit(this), ast.name);

  @override
  AST visitMethodCall(MethodCall ast, dynamic context) => new MethodCall(
      ast.receiver.visit(this), ast.name, this._visitAll(ast.args));

  @override
  AST visitSafeMethodCall(SafeMethodCall ast, dynamic context) =>
      new SafeMethodCall(
          ast.receiver.visit(this), ast.name, this._visitAll(ast.args));

  @override
  AST visitFunctionCall(FunctionCall ast, dynamic context) =>
      new FunctionCall(ast.target.visit(this), this._visitAll(ast.args));

  @override
  AST visitLiteralArray(LiteralArray ast, dynamic context) =>
      new LiteralArray(this._visitAll(ast.expressions));

  @override
  AST visitLiteralMap(LiteralMap ast, dynamic context) =>
      new LiteralMap(ast.keys, this._visitAll(ast.values));

  @override
  AST visitBinary(Binary ast, dynamic context) =>
      new Binary(ast.operation, ast.left.visit(this), ast.right.visit(this));

  @override
  AST visitPrefixNot(PrefixNot ast, dynamic context) =>
      new PrefixNot(ast.expression.visit(this));

  @override
  AST visitConditional(Conditional ast, dynamic context) => new Conditional(
      ast.condition.visit(this),
      ast.trueExp.visit(this),
      ast.falseExp.visit(this));

  @override
  AST visitIfNull(IfNull ast, dynamic context) =>
      new IfNull(ast.condition.visit(this), ast.nullExp.visit(this));

  @override
  AST visitPipe(BindingPipe ast, dynamic context) =>
      new BindingPipe(ast.exp.visit(this), ast.name, this._visitAll(ast.args));

  @override
  AST visitKeyedRead(KeyedRead ast, dynamic context) =>
      new KeyedRead(ast.obj.visit(this), ast.key.visit(this));

  @override
  AST visitKeyedWrite(KeyedWrite ast, dynamic context) => new KeyedWrite(
      ast.obj.visit(this), ast.key.visit(this), ast.value.visit(this));

  @override
  AST visitChain(Chain ast, dynamic context) =>
      new Chain(this._visitAll(ast.expressions));

  @override
  AST visitEmptyExpr(EmptyExpr ast, dynamic context) => new EmptyExpr();

  List<dynamic> _visitAll(List<dynamic> asts) {
    var res = new List(asts.length);
    for (var i = 0; i < asts.length; ++i) {
      res[i] = asts[i].visit(this);
    }
    return res;
  }
}
