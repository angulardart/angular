import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/compile_metadata.dart';

abstract class AST {
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]);
}

class NamedExpr extends AST {
  final String name;
  final AST expression;

  NamedExpr(this.name, this.expression);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitNamedExpr(this, context);
}

class EmptyExpr extends AST {
  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitEmptyExpr(this, context);
}

class StaticRead extends AST {
  final CompileIdentifierMetadata id;

  /// The analyzed class being read, if this is a class reference.
  AnalyzedClass get analyzedClass => id.analyzedClass;

  StaticRead(this.id);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitStaticRead(this, context);
}

class ImplicitReceiver extends AST {
  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitImplicitReceiver(this, context);
}

class Conditional extends AST {
  AST condition;
  AST trueExp;
  AST falseExp;
  Conditional(this.condition, this.trueExp, this.falseExp);
  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
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
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitIfNull(this, context);
}

class PropertyRead extends AST {
  AST receiver;
  String name;
  PropertyRead(this.receiver, this.name);
  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitPropertyRead(this, context);
}

class PropertyWrite extends AST {
  AST receiver;
  String name;
  AST value;
  PropertyWrite(this.receiver, this.name, this.value);
  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) {
    return visitor.visitPropertyWrite(this, context);
  }
}

class SafePropertyRead extends AST {
  AST receiver;
  String name;
  SafePropertyRead(this.receiver, this.name);
  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitSafePropertyRead(this, context);
}

class KeyedRead extends AST {
  AST obj;
  AST key;
  KeyedRead(this.obj, this.key);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitKeyedRead(this, context);
}

class KeyedWrite extends AST {
  AST obj;
  AST key;
  AST value;
  KeyedWrite(this.obj, this.key, this.value);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitKeyedWrite(this, context);
}

class BindingPipe extends AST {
  AST exp;
  String name;
  List<AST> args;
  BindingPipe(this.exp, this.name, this.args);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitPipe(this, context);
}

class LiteralPrimitive extends AST {
  var value;
  LiteralPrimitive(this.value);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitLiteralPrimitive(this, context);
}

class LiteralArray extends AST {
  List<AST> expressions;
  LiteralArray(this.expressions);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitLiteralArray(this, context);
}

class Interpolation extends AST {
  List<String> strings;
  List<AST> expressions;
  Interpolation(this.strings, this.expressions);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) {
    return visitor.visitInterpolation(this, context);
  }
}

class Binary extends AST {
  String operation;
  AST left;
  AST right;
  Binary(this.operation, this.left, this.right);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitBinary(this, context);
}

class PrefixNot extends AST {
  AST expression;
  PrefixNot(this.expression);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitPrefixNot(this, context);
}

class MethodCall extends AST {
  AST receiver;
  String name;
  List<AST> args;
  List<NamedExpr> namedArgs;
  MethodCall(
    this.receiver,
    this.name,
    this.args, [
    this.namedArgs = const [],
  ]);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitMethodCall(this, context);
}

class SafeMethodCall extends AST {
  AST receiver;
  String name;
  List<AST> args;
  List<NamedExpr> namedArgs;
  SafeMethodCall(
    this.receiver,
    this.name,
    this.args, [
    this.namedArgs = const [],
  ]);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitSafeMethodCall(this, context);
}

class FunctionCall extends AST {
  AST target;
  List<AST> args;
  List<NamedExpr> namedArgs;
  FunctionCall(
    this.target,
    this.args, [
    this.namedArgs = const [],
  ]);

  @override
  R visit<R, C, CO extends C>(AstVisitor<R, C> visitor, [CO context]) =>
      visitor.visitFunctionCall(this, context);
}

class ASTWithSource {
  AST ast;
  String source;
  String location;
  ASTWithSource(this.ast, this.source, this.location);

  ASTWithSource.from(ASTWithSource original, AST transformed)
      : this(transformed, original.source, original.location);

  ASTWithSource.missingSource(AST ast) : this(ast, null, null);

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
  R visitConditional(Conditional ast, C context);
  R visitEmptyExpr(EmptyExpr ast, C context);
  R visitFunctionCall(FunctionCall ast, C context);
  R visitIfNull(IfNull ast, C context);
  R visitImplicitReceiver(ImplicitReceiver ast, C context);
  R visitInterpolation(Interpolation ast, C context);
  R visitKeyedRead(KeyedRead ast, C context);
  R visitKeyedWrite(KeyedWrite ast, C context);
  R visitLiteralArray(LiteralArray ast, C context);
  R visitLiteralPrimitive(LiteralPrimitive ast, C context);
  R visitMethodCall(MethodCall ast, C context);
  R visitNamedExpr(NamedExpr ast, C context);
  R visitPipe(BindingPipe ast, C context);
  R visitPrefixNot(PrefixNot ast, C context);
  R visitPropertyRead(PropertyRead ast, C context);
  R visitPropertyWrite(PropertyWrite ast, C context);
  R visitSafeMethodCall(SafeMethodCall ast, C context);
  R visitSafePropertyRead(SafePropertyRead ast, C context);
  R visitStaticRead(StaticRead ast, C context);
}

class RecursiveAstVisitor<C> implements AstVisitor<void, C> {
  @override
  void visitBinary(Binary ast, C context) {
    ast.left.visit(this, context);
    ast.right.visit(this, context);
  }

  @override
  void visitConditional(Conditional ast, C context) {
    ast.condition.visit(this, context);
    ast.trueExp.visit(this, context);
    ast.falseExp.visit(this, context);
  }

  @override
  void visitEmptyExpr(EmptyExpr ast, C context) {}

  @override
  void visitPipe(BindingPipe ast, C context) {
    ast.exp.visit(this, context);
    visitAll(ast.args, context);
  }

  @override
  void visitFunctionCall(FunctionCall ast, C context) {
    ast.target.visit(this, context);
    visitAll(ast.args, context);
    visitAll(ast.namedArgs, context);
  }

  @override
  void visitNamedExpr(NamedExpr ast, C context) {
    ast.expression.visit(this, context);
  }

  @override
  void visitIfNull(IfNull ast, C context) {
    ast.condition.visit(this, context);
    ast.nullExp.visit(this, context);
  }

  @override
  void visitImplicitReceiver(ImplicitReceiver ast, C context) {}

  @override
  void visitInterpolation(Interpolation ast, C context) {
    visitAll(ast.expressions, context);
  }

  @override
  void visitKeyedRead(KeyedRead ast, C context) {
    ast.obj.visit(this, context);
    ast.key.visit(this, context);
  }

  @override
  void visitKeyedWrite(KeyedWrite ast, C context) {
    ast.obj.visit(this, context);
    ast.key.visit(this, context);
    ast.value.visit(this, context);
  }

  @override
  void visitLiteralArray(LiteralArray ast, C context) {
    visitAll(ast.expressions, context);
  }

  @override
  void visitLiteralPrimitive(LiteralPrimitive ast, C context) {}

  @override
  void visitMethodCall(MethodCall ast, C context) {
    ast.receiver.visit(this, context);
    visitAll(ast.args, context);
    visitAll(ast.namedArgs, context);
  }

  @override
  void visitPrefixNot(PrefixNot ast, C context) {
    ast.expression.visit(this, context);
  }

  @override
  void visitPropertyRead(PropertyRead ast, C context) {
    ast.receiver.visit(this, context);
  }

  @override
  void visitPropertyWrite(PropertyWrite ast, C context) {
    ast.receiver.visit(this, context);
    ast.value.visit(this, context);
  }

  @override
  void visitSafePropertyRead(SafePropertyRead ast, C context) {
    ast.receiver.visit(this, context);
  }

  @override
  void visitSafeMethodCall(SafeMethodCall ast, C context) {
    ast.receiver.visit(this, context);
    visitAll(ast.args, context);
    visitAll(ast.namedArgs, context);
  }

  @override
  void visitStaticRead(StaticRead ast, C context) {}

  void visitAll(List<AST> asts, C context) {
    for (var ast in asts) {
      ast.visit(this, context);
    }
  }
}

class AstTransformer implements AstVisitor<AST, Null> {
  @override
  AST visitImplicitReceiver(ImplicitReceiver ast, _) => ast;

  @override
  AST visitStaticRead(StaticRead ast, _) => ast;

  @override
  AST visitInterpolation(Interpolation ast, _) =>
      Interpolation(ast.strings, this._visitAll(ast.expressions));

  @override
  AST visitLiteralPrimitive(LiteralPrimitive ast, _) =>
      LiteralPrimitive(ast.value);

  @override
  AST visitPropertyRead(PropertyRead ast, _) =>
      PropertyRead(ast.receiver.visit(this), ast.name);

  @override
  AST visitPropertyWrite(PropertyWrite ast, _) =>
      PropertyWrite(ast.receiver.visit(this), ast.name, ast.value);

  @override
  AST visitSafePropertyRead(SafePropertyRead ast, _) =>
      SafePropertyRead(ast.receiver.visit(this), ast.name);

  @override
  AST visitMethodCall(MethodCall ast, _) => MethodCall(ast.receiver.visit(this),
      ast.name, _visitAll(ast.args), _visitAll(ast.namedArgs));

  @override
  AST visitSafeMethodCall(SafeMethodCall ast, _) => SafeMethodCall(
      ast.receiver.visit(this),
      ast.name,
      _visitAll(ast.args),
      _visitAll(ast.namedArgs));

  @override
  AST visitFunctionCall(FunctionCall ast, _) => FunctionCall(
      ast.target.visit(this), _visitAll(ast.args), _visitAll(ast.namedArgs));

  @override
  AST visitNamedExpr(NamedExpr ast, _) => ast;

  @override
  AST visitLiteralArray(LiteralArray ast, _) =>
      LiteralArray(this._visitAll(ast.expressions));

  @override
  AST visitBinary(Binary ast, _) =>
      Binary(ast.operation, ast.left.visit(this), ast.right.visit(this));

  @override
  AST visitPrefixNot(PrefixNot ast, _) => PrefixNot(ast.expression.visit(this));

  @override
  AST visitConditional(Conditional ast, _) => Conditional(
      ast.condition.visit(this),
      ast.trueExp.visit(this),
      ast.falseExp.visit(this));

  @override
  AST visitIfNull(IfNull ast, _) =>
      IfNull(ast.condition.visit(this), ast.nullExp.visit(this));

  @override
  AST visitPipe(BindingPipe ast, _) =>
      BindingPipe(ast.exp.visit(this), ast.name, this._visitAll(ast.args));

  @override
  AST visitKeyedRead(KeyedRead ast, _) =>
      KeyedRead(ast.obj.visit(this), ast.key.visit(this));

  @override
  AST visitKeyedWrite(KeyedWrite ast, _) => KeyedWrite(
      ast.obj.visit(this), ast.key.visit(this), ast.value.visit(this));

  @override
  AST visitEmptyExpr(EmptyExpr ast, _) => EmptyExpr();

  List<R> _visitAll<R extends AST>(List<AST> asts) {
    var res = List<R>(asts.length);
    for (var i = 0; i < asts.length; ++i) {
      final ast = asts[i];
      final result = ast.visit(this);
      res[i] = result as R;
    }
    return res;
  }
}
