library angular2.src.compiler.output.output_ast;

import "package:angular2/src/facade/lang.dart"
    show isString, isPresent, isBlank;
import "../compile_metadata.dart" show CompileIdentifierMetadata;

//// Types
enum TypeModifier { Const }

abstract class Type {
  List<TypeModifier> modifiers;
  Type([this.modifiers = null]) {
    if (isBlank(modifiers)) {
      this.modifiers = [];
    }
  }
  dynamic visitType(TypeVisitor visitor, dynamic context);
  bool hasModifier(TypeModifier modifier) {
    return !identical(this.modifiers.indexOf(modifier), -1);
  }
}

enum BuiltinTypeName { Dynamic, Bool, String, Int, Number, Function }

class BuiltinType extends Type {
  BuiltinTypeName name;
  BuiltinType(this.name, [List<TypeModifier> modifiers = null])
      : super(modifiers) {
    /* super call moved to initializer */;
  }
  dynamic visitType(TypeVisitor visitor, dynamic context) {
    return visitor.visitBuiltintType(this, context);
  }
}

class ExternalType extends Type {
  CompileIdentifierMetadata value;
  List<Type> typeParams;
  ExternalType(this.value,
      [this.typeParams = null, List<TypeModifier> modifiers = null])
      : super(modifiers) {
    /* super call moved to initializer */;
  }
  dynamic visitType(TypeVisitor visitor, dynamic context) {
    return visitor.visitExternalType(this, context);
  }
}

class ArrayType extends Type {
  Type of;
  ArrayType(this.of, [List<TypeModifier> modifiers = null]) : super(modifiers) {
    /* super call moved to initializer */;
  }
  dynamic visitType(TypeVisitor visitor, dynamic context) {
    return visitor.visitArrayType(this, context);
  }
}

class MapType extends Type {
  Type valueType;
  MapType(this.valueType, [List<TypeModifier> modifiers = null])
      : super(modifiers) {
    /* super call moved to initializer */;
  }
  dynamic visitType(TypeVisitor visitor, dynamic context) {
    return visitor.visitMapType(this, context);
  }
}

var DYNAMIC_TYPE = new BuiltinType(BuiltinTypeName.Dynamic);
var BOOL_TYPE = new BuiltinType(BuiltinTypeName.Bool);
var INT_TYPE = new BuiltinType(BuiltinTypeName.Int);
var NUMBER_TYPE = new BuiltinType(BuiltinTypeName.Number);
var STRING_TYPE = new BuiltinType(BuiltinTypeName.String);
var FUNCTION_TYPE = new BuiltinType(BuiltinTypeName.Function);

abstract class TypeVisitor {
  dynamic visitBuiltintType(BuiltinType type, dynamic context);
  dynamic visitExternalType(ExternalType type, dynamic context);
  dynamic visitArrayType(ArrayType type, dynamic context);
  dynamic visitMapType(MapType type, dynamic context);
}

///// Expressions
enum BinaryOperator {
  Equals,
  NotEquals,
  Identical,
  NotIdentical,
  Minus,
  Plus,
  Divide,
  Multiply,
  Modulo,
  And,
  Or,
  Lower,
  LowerEquals,
  Bigger,
  BiggerEquals
}

abstract class Expression {
  Type type;
  Expression(this.type) {}
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context);
  ReadPropExpr prop(String name) {
    return new ReadPropExpr(this, name);
  }

  ReadKeyExpr key(Expression index, [Type type = null]) {
    return new ReadKeyExpr(this, index, type);
  }

  InvokeMethodExpr callMethod(
      dynamic /* String | BuiltinMethod */ name, List<Expression> params) {
    return new InvokeMethodExpr(this, name, params);
  }

  InvokeFunctionExpr callFn(List<Expression> params) {
    return new InvokeFunctionExpr(this, params);
  }

  InstantiateExpr instantiate(List<Expression> params, [Type type = null]) {
    return new InstantiateExpr(this, params, type);
  }

  ConditionalExpr conditional(Expression trueCase,
      [Expression falseCase = null]) {
    return new ConditionalExpr(this, trueCase, falseCase);
  }

  BinaryOperatorExpr equals(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.Equals, this, rhs);
  }

  BinaryOperatorExpr notEquals(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.NotEquals, this, rhs);
  }

  BinaryOperatorExpr identical(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.Identical, this, rhs);
  }

  BinaryOperatorExpr notIdentical(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.NotIdentical, this, rhs);
  }

  BinaryOperatorExpr minus(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.Minus, this, rhs);
  }

  BinaryOperatorExpr plus(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.Plus, this, rhs);
  }

  BinaryOperatorExpr divide(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.Divide, this, rhs);
  }

  BinaryOperatorExpr multiply(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.Multiply, this, rhs);
  }

  BinaryOperatorExpr modulo(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.Modulo, this, rhs);
  }

  BinaryOperatorExpr and(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.And, this, rhs);
  }

  BinaryOperatorExpr or(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.Or, this, rhs);
  }

  BinaryOperatorExpr lower(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.Lower, this, rhs);
  }

  BinaryOperatorExpr lowerEquals(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.LowerEquals, this, rhs);
  }

  BinaryOperatorExpr bigger(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.Bigger, this, rhs);
  }

  BinaryOperatorExpr biggerEquals(Expression rhs) {
    return new BinaryOperatorExpr(BinaryOperator.BiggerEquals, this, rhs);
  }

  Expression isBlank() {
    // Note: We use equals by purpose here to compare to null and undefined in JS.
    return this.equals(NULL_EXPR);
  }

  Expression cast(Type type) {
    return new CastExpr(this, type);
  }

  Statement toStmt() {
    return new ExpressionStatement(this);
  }
}

enum BuiltinVar { This, Super, CatchError, CatchStack }

class ReadVarExpr extends Expression {
  var name;
  BuiltinVar builtin;
  ReadVarExpr(dynamic /* String | BuiltinVar */ name, [Type type = null])
      : super(type) {
    /* super call moved to initializer */;
    if (isString(name)) {
      this.name = (name as String);
      this.builtin = null;
    } else {
      this.name = null;
      this.builtin = (name as BuiltinVar);
    }
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitReadVarExpr(this, context);
  }

  WriteVarExpr set(Expression value) {
    return new WriteVarExpr(this.name, value);
  }
}

class WriteVarExpr extends Expression {
  String name;
  Expression value;
  WriteVarExpr(this.name, Expression value, [Type type = null])
      : super(isPresent(type) ? type : value.type) {
    /* super call moved to initializer */;
    this.value = value;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitWriteVarExpr(this, context);
  }

  DeclareVarStmt toDeclStmt(
      [Type type = null, List<StmtModifier> modifiers = null]) {
    return new DeclareVarStmt(this.name, this.value, type, modifiers);
  }
}

class WriteKeyExpr extends Expression {
  Expression receiver;
  Expression index;
  Expression value;
  WriteKeyExpr(this.receiver, this.index, Expression value, [Type type = null])
      : super(isPresent(type) ? type : value.type) {
    /* super call moved to initializer */;
    this.value = value;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitWriteKeyExpr(this, context);
  }
}

class WritePropExpr extends Expression {
  Expression receiver;
  String name;
  Expression value;
  WritePropExpr(this.receiver, this.name, Expression value, [Type type = null])
      : super(isPresent(type) ? type : value.type) {
    /* super call moved to initializer */;
    this.value = value;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitWritePropExpr(this, context);
  }
}

enum BuiltinMethod { ConcatArray, SubscribeObservable }

class InvokeMethodExpr extends Expression {
  Expression receiver;
  List<Expression> args;
  String name;
  BuiltinMethod builtin;
  InvokeMethodExpr(
      this.receiver, dynamic /* String | BuiltinMethod */ method, this.args,
      [Type type = null])
      : super(type) {
    /* super call moved to initializer */;
    if (isString(method)) {
      this.name = (method as String);
      this.builtin = null;
    } else {
      this.name = null;
      this.builtin = (method as BuiltinMethod);
    }
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitInvokeMethodExpr(this, context);
  }
}

class InvokeFunctionExpr extends Expression {
  Expression fn;
  List<Expression> args;
  InvokeFunctionExpr(this.fn, this.args, [Type type = null]) : super(type) {
    /* super call moved to initializer */;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitInvokeFunctionExpr(this, context);
  }
}

class InstantiateExpr extends Expression {
  Expression classExpr;
  List<Expression> args;
  InstantiateExpr(this.classExpr, this.args, [Type type]) : super(type) {
    /* super call moved to initializer */;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitInstantiateExpr(this, context);
  }
}

class LiteralExpr extends Expression {
  dynamic value;
  LiteralExpr(this.value, [Type type = null]) : super(type) {
    /* super call moved to initializer */;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitLiteralExpr(this, context);
  }
}

class ExternalExpr extends Expression {
  CompileIdentifierMetadata value;
  List<Type> typeParams;
  ExternalExpr(this.value, [Type type = null, this.typeParams = null])
      : super(type) {
    /* super call moved to initializer */;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitExternalExpr(this, context);
  }
}

class ConditionalExpr extends Expression {
  Expression condition;
  Expression falseCase;
  Expression trueCase;
  ConditionalExpr(this.condition, Expression trueCase,
      [this.falseCase = null, Type type = null])
      : super(isPresent(type) ? type : trueCase.type) {
    /* super call moved to initializer */;
    this.trueCase = trueCase;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitConditionalExpr(this, context);
  }
}

class NotExpr extends Expression {
  Expression condition;
  NotExpr(this.condition) : super(BOOL_TYPE) {
    /* super call moved to initializer */;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitNotExpr(this, context);
  }
}

class CastExpr extends Expression {
  Expression value;
  CastExpr(this.value, Type type) : super(type) {
    /* super call moved to initializer */;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitCastExpr(this, context);
  }
}

class FnParam {
  String name;
  Type type;
  FnParam(this.name, [this.type = null]) {}
}

class FunctionExpr extends Expression {
  List<FnParam> params;
  List<Statement> statements;
  FunctionExpr(this.params, this.statements, [Type type = null]) : super(type) {
    /* super call moved to initializer */;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitFunctionExpr(this, context);
  }

  DeclareFunctionStmt toDeclStmt(String name,
      [List<StmtModifier> modifiers = null]) {
    return new DeclareFunctionStmt(
        name, this.params, this.statements, this.type, modifiers);
  }
}

class BinaryOperatorExpr extends Expression {
  BinaryOperator operator;
  Expression rhs;
  Expression lhs;
  BinaryOperatorExpr(this.operator, Expression lhs, this.rhs,
      [Type type = null])
      : super(isPresent(type) ? type : lhs.type) {
    /* super call moved to initializer */;
    this.lhs = lhs;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitBinaryOperatorExpr(this, context);
  }
}

class ReadPropExpr extends Expression {
  Expression receiver;
  String name;
  ReadPropExpr(this.receiver, this.name, [Type type = null]) : super(type) {
    /* super call moved to initializer */;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitReadPropExpr(this, context);
  }

  WritePropExpr set(Expression value) {
    return new WritePropExpr(this.receiver, this.name, value);
  }
}

class ReadKeyExpr extends Expression {
  Expression receiver;
  Expression index;
  ReadKeyExpr(this.receiver, this.index, [Type type = null]) : super(type) {
    /* super call moved to initializer */;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitReadKeyExpr(this, context);
  }

  WriteKeyExpr set(Expression value) {
    return new WriteKeyExpr(this.receiver, this.index, value);
  }
}

class LiteralArrayExpr extends Expression {
  List<Expression> entries;
  LiteralArrayExpr(List<Expression> entries, [Type type = null]) : super(type) {
    /* super call moved to initializer */;
    this.entries = entries;
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitLiteralArrayExpr(this, context);
  }
}

class LiteralMapExpr extends Expression {
  List<List<dynamic /* String | Expression */ >> entries;
  Type valueType = null;
  LiteralMapExpr(this.entries, [MapType type = null]) : super(type) {
    /* super call moved to initializer */;
    if (isPresent(type)) {
      this.valueType = type.valueType;
    }
  }
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitLiteralMapExpr(this, context);
  }
}

abstract class ExpressionVisitor {
  dynamic visitReadVarExpr(ReadVarExpr ast, dynamic context);
  dynamic visitWriteVarExpr(WriteVarExpr expr, dynamic context);
  dynamic visitWriteKeyExpr(WriteKeyExpr expr, dynamic context);
  dynamic visitWritePropExpr(WritePropExpr expr, dynamic context);
  dynamic visitInvokeMethodExpr(InvokeMethodExpr ast, dynamic context);
  dynamic visitInvokeFunctionExpr(InvokeFunctionExpr ast, dynamic context);
  dynamic visitInstantiateExpr(InstantiateExpr ast, dynamic context);
  dynamic visitLiteralExpr(LiteralExpr ast, dynamic context);
  dynamic visitExternalExpr(ExternalExpr ast, dynamic context);
  dynamic visitConditionalExpr(ConditionalExpr ast, dynamic context);
  dynamic visitNotExpr(NotExpr ast, dynamic context);
  dynamic visitCastExpr(CastExpr ast, dynamic context);
  dynamic visitFunctionExpr(FunctionExpr ast, dynamic context);
  dynamic visitBinaryOperatorExpr(BinaryOperatorExpr ast, dynamic context);
  dynamic visitReadPropExpr(ReadPropExpr ast, dynamic context);
  dynamic visitReadKeyExpr(ReadKeyExpr ast, dynamic context);
  dynamic visitLiteralArrayExpr(LiteralArrayExpr ast, dynamic context);
  dynamic visitLiteralMapExpr(LiteralMapExpr ast, dynamic context);
}

var THIS_EXPR = new ReadVarExpr(BuiltinVar.This);
var SUPER_EXPR = new ReadVarExpr(BuiltinVar.Super);
var CATCH_ERROR_VAR = new ReadVarExpr(BuiltinVar.CatchError);
var CATCH_STACK_VAR = new ReadVarExpr(BuiltinVar.CatchStack);
var NULL_EXPR = new LiteralExpr(null, null);
//// Statements
enum StmtModifier { Final, Private }

abstract class Statement {
  List<StmtModifier> modifiers;
  Statement([this.modifiers = null]) {
    if (isBlank(modifiers)) {
      this.modifiers = [];
    }
  }
  dynamic visitStatement(StatementVisitor visitor, dynamic context);
  bool hasModifier(StmtModifier modifier) {
    return !identical(this.modifiers.indexOf(modifier), -1);
  }
}

class DeclareVarStmt extends Statement {
  String name;
  Expression value;
  Type type;
  DeclareVarStmt(this.name, this.value,
      [Type type = null, List<StmtModifier> modifiers = null])
      : super(modifiers) {
    /* super call moved to initializer */;
    this.type = isPresent(type) ? type : value.type;
  }
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitDeclareVarStmt(this, context);
  }
}

class DeclareFunctionStmt extends Statement {
  String name;
  List<FnParam> params;
  List<Statement> statements;
  Type type;
  DeclareFunctionStmt(this.name, this.params, this.statements,
      [this.type = null, List<StmtModifier> modifiers = null])
      : super(modifiers) {
    /* super call moved to initializer */;
  }
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitDeclareFunctionStmt(this, context);
  }
}

class ExpressionStatement extends Statement {
  Expression expr;
  ExpressionStatement(this.expr) : super() {
    /* super call moved to initializer */;
  }
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitExpressionStmt(this, context);
  }
}

class ReturnStatement extends Statement {
  Expression value;
  ReturnStatement(this.value) : super() {
    /* super call moved to initializer */;
  }
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitReturnStmt(this, context);
  }
}

class AbstractClassPart {
  Type type;
  List<StmtModifier> modifiers;
  AbstractClassPart([this.type = null, this.modifiers]) {
    if (isBlank(modifiers)) {
      this.modifiers = [];
    }
  }
  bool hasModifier(StmtModifier modifier) {
    return !identical(this.modifiers.indexOf(modifier), -1);
  }
}

class ClassField extends AbstractClassPart {
  String name;
  ClassField(this.name, [Type type = null, List<StmtModifier> modifiers = null])
      : super(type, modifiers) {
    /* super call moved to initializer */;
  }
}

class ClassMethod extends AbstractClassPart {
  String name;
  List<FnParam> params;
  List<Statement> body;
  ClassMethod(this.name, this.params, this.body,
      [Type type = null, List<StmtModifier> modifiers = null])
      : super(type, modifiers) {
    /* super call moved to initializer */;
  }
}

class ClassGetter extends AbstractClassPart {
  String name;
  List<Statement> body;
  ClassGetter(this.name, this.body,
      [Type type = null, List<StmtModifier> modifiers = null])
      : super(type, modifiers) {
    /* super call moved to initializer */;
  }
}

class ClassStmt extends Statement {
  String name;
  Expression parent;
  List<ClassField> fields;
  List<ClassGetter> getters;
  ClassMethod constructorMethod;
  List<ClassMethod> methods;
  ClassStmt(this.name, this.parent, this.fields, this.getters,
      this.constructorMethod, this.methods,
      [List<StmtModifier> modifiers = null])
      : super(modifiers) {
    /* super call moved to initializer */;
  }
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitDeclareClassStmt(this, context);
  }
}

class IfStmt extends Statement {
  Expression condition;
  List<Statement> trueCase;
  List<Statement> falseCase;
  IfStmt(this.condition, this.trueCase, [this.falseCase = const []]) : super() {
    /* super call moved to initializer */;
  }
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitIfStmt(this, context);
  }
}

class CommentStmt extends Statement {
  String comment;
  CommentStmt(this.comment) : super() {
    /* super call moved to initializer */;
  }
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitCommentStmt(this, context);
  }
}

class TryCatchStmt extends Statement {
  List<Statement> bodyStmts;
  List<Statement> catchStmts;
  TryCatchStmt(this.bodyStmts, this.catchStmts) : super() {
    /* super call moved to initializer */;
  }
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitTryCatchStmt(this, context);
  }
}

class ThrowStmt extends Statement {
  Expression error;
  ThrowStmt(this.error) : super() {
    /* super call moved to initializer */;
  }
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitThrowStmt(this, context);
  }
}

abstract class StatementVisitor {
  dynamic visitDeclareVarStmt(DeclareVarStmt stmt, dynamic context);
  dynamic visitDeclareFunctionStmt(DeclareFunctionStmt stmt, dynamic context);
  dynamic visitExpressionStmt(ExpressionStatement stmt, dynamic context);
  dynamic visitReturnStmt(ReturnStatement stmt, dynamic context);
  dynamic visitDeclareClassStmt(ClassStmt stmt, dynamic context);
  dynamic visitIfStmt(IfStmt stmt, dynamic context);
  dynamic visitTryCatchStmt(TryCatchStmt stmt, dynamic context);
  dynamic visitThrowStmt(ThrowStmt stmt, dynamic context);
  dynamic visitCommentStmt(CommentStmt stmt, dynamic context);
}

class ExpressionTransformer implements StatementVisitor, ExpressionVisitor {
  dynamic visitReadVarExpr(ReadVarExpr ast, dynamic context) {
    return ast;
  }

  dynamic visitWriteVarExpr(WriteVarExpr expr, dynamic context) {
    return new WriteVarExpr(
        expr.name, expr.value.visitExpression(this, context));
  }

  dynamic visitWriteKeyExpr(WriteKeyExpr expr, dynamic context) {
    return new WriteKeyExpr(
        expr.receiver.visitExpression(this, context),
        expr.index.visitExpression(this, context),
        expr.value.visitExpression(this, context));
  }

  dynamic visitWritePropExpr(WritePropExpr expr, dynamic context) {
    return new WritePropExpr(expr.receiver.visitExpression(this, context),
        expr.name, expr.value.visitExpression(this, context));
  }

  dynamic visitInvokeMethodExpr(InvokeMethodExpr ast, dynamic context) {
    var method = isPresent(ast.builtin) ? ast.builtin : ast.name;
    return new InvokeMethodExpr(ast.receiver.visitExpression(this, context),
        method, this.visitAllExpressions(ast.args, context), ast.type);
  }

  dynamic visitInvokeFunctionExpr(InvokeFunctionExpr ast, dynamic context) {
    return new InvokeFunctionExpr(ast.fn.visitExpression(this, context),
        this.visitAllExpressions(ast.args, context), ast.type);
  }

  dynamic visitInstantiateExpr(InstantiateExpr ast, dynamic context) {
    return new InstantiateExpr(ast.classExpr.visitExpression(this, context),
        this.visitAllExpressions(ast.args, context), ast.type);
  }

  dynamic visitLiteralExpr(LiteralExpr ast, dynamic context) {
    return ast;
  }

  dynamic visitExternalExpr(ExternalExpr ast, dynamic context) {
    return ast;
  }

  dynamic visitConditionalExpr(ConditionalExpr ast, dynamic context) {
    return new ConditionalExpr(
        ast.condition.visitExpression(this, context),
        ast.trueCase.visitExpression(this, context),
        ast.falseCase.visitExpression(this, context));
  }

  dynamic visitNotExpr(NotExpr ast, dynamic context) {
    return new NotExpr(ast.condition.visitExpression(this, context));
  }

  dynamic visitCastExpr(CastExpr ast, dynamic context) {
    return new CastExpr(ast.value.visitExpression(this, context), context);
  }

  dynamic visitFunctionExpr(FunctionExpr ast, dynamic context) {
    // Don't descend into nested functions
    return ast;
  }

  dynamic visitBinaryOperatorExpr(BinaryOperatorExpr ast, dynamic context) {
    return new BinaryOperatorExpr(
        ast.operator,
        ast.lhs.visitExpression(this, context),
        ast.rhs.visitExpression(this, context),
        ast.type);
  }

  dynamic visitReadPropExpr(ReadPropExpr ast, dynamic context) {
    return new ReadPropExpr(
        ast.receiver.visitExpression(this, context), ast.name, ast.type);
  }

  dynamic visitReadKeyExpr(ReadKeyExpr ast, dynamic context) {
    return new ReadKeyExpr(ast.receiver.visitExpression(this, context),
        ast.index.visitExpression(this, context), ast.type);
  }

  dynamic visitLiteralArrayExpr(LiteralArrayExpr ast, dynamic context) {
    return new LiteralArrayExpr(this.visitAllExpressions(ast.entries, context));
  }

  dynamic visitLiteralMapExpr(LiteralMapExpr ast, dynamic context) {
    return new LiteralMapExpr(ast.entries
        .map((entry) => [
              entry[0],
              ((entry[1] as Expression)).visitExpression(this, context)
            ])
        .toList());
  }

  List<Expression> visitAllExpressions(
      List<Expression> exprs, dynamic context) {
    return exprs.map((expr) => expr.visitExpression(this, context)).toList();
  }

  dynamic visitDeclareVarStmt(DeclareVarStmt stmt, dynamic context) {
    return new DeclareVarStmt(stmt.name,
        stmt.value.visitExpression(this, context), stmt.type, stmt.modifiers);
  }

  dynamic visitDeclareFunctionStmt(DeclareFunctionStmt stmt, dynamic context) {
    // Don't descend into nested functions
    return stmt;
  }

  dynamic visitExpressionStmt(ExpressionStatement stmt, dynamic context) {
    return new ExpressionStatement(stmt.expr.visitExpression(this, context));
  }

  dynamic visitReturnStmt(ReturnStatement stmt, dynamic context) {
    return new ReturnStatement(stmt.value.visitExpression(this, context));
  }

  dynamic visitDeclareClassStmt(ClassStmt stmt, dynamic context) {
    // Don't descend into nested functions
    return stmt;
  }

  dynamic visitIfStmt(IfStmt stmt, dynamic context) {
    return new IfStmt(
        stmt.condition.visitExpression(this, context),
        this.visitAllStatements(stmt.trueCase, context),
        this.visitAllStatements(stmt.falseCase, context));
  }

  dynamic visitTryCatchStmt(TryCatchStmt stmt, dynamic context) {
    return new TryCatchStmt(this.visitAllStatements(stmt.bodyStmts, context),
        this.visitAllStatements(stmt.catchStmts, context));
  }

  dynamic visitThrowStmt(ThrowStmt stmt, dynamic context) {
    return new ThrowStmt(stmt.error.visitExpression(this, context));
  }

  dynamic visitCommentStmt(CommentStmt stmt, dynamic context) {
    return stmt;
  }

  List<Statement> visitAllStatements(List<Statement> stmts, dynamic context) {
    return stmts.map((stmt) => stmt.visitStatement(this, context)).toList();
  }
}

class RecursiveExpressionVisitor
    implements StatementVisitor, ExpressionVisitor {
  dynamic visitReadVarExpr(ReadVarExpr ast, dynamic context) {
    return ast;
  }

  dynamic visitWriteVarExpr(WriteVarExpr expr, dynamic context) {
    expr.value.visitExpression(this, context);
    return expr;
  }

  dynamic visitWriteKeyExpr(WriteKeyExpr expr, dynamic context) {
    expr.receiver.visitExpression(this, context);
    expr.index.visitExpression(this, context);
    expr.value.visitExpression(this, context);
    return expr;
  }

  dynamic visitWritePropExpr(WritePropExpr expr, dynamic context) {
    expr.receiver.visitExpression(this, context);
    expr.value.visitExpression(this, context);
    return expr;
  }

  dynamic visitInvokeMethodExpr(InvokeMethodExpr ast, dynamic context) {
    ast.receiver.visitExpression(this, context);
    this.visitAllExpressions(ast.args, context);
    return ast;
  }

  dynamic visitInvokeFunctionExpr(InvokeFunctionExpr ast, dynamic context) {
    ast.fn.visitExpression(this, context);
    this.visitAllExpressions(ast.args, context);
    return ast;
  }

  dynamic visitInstantiateExpr(InstantiateExpr ast, dynamic context) {
    ast.classExpr.visitExpression(this, context);
    this.visitAllExpressions(ast.args, context);
    return ast;
  }

  dynamic visitLiteralExpr(LiteralExpr ast, dynamic context) {
    return ast;
  }

  dynamic visitExternalExpr(ExternalExpr ast, dynamic context) {
    return ast;
  }

  dynamic visitConditionalExpr(ConditionalExpr ast, dynamic context) {
    ast.condition.visitExpression(this, context);
    ast.trueCase.visitExpression(this, context);
    ast.falseCase.visitExpression(this, context);
    return ast;
  }

  dynamic visitNotExpr(NotExpr ast, dynamic context) {
    ast.condition.visitExpression(this, context);
    return ast;
  }

  dynamic visitCastExpr(CastExpr ast, dynamic context) {
    ast.value.visitExpression(this, context);
    return ast;
  }

  dynamic visitFunctionExpr(FunctionExpr ast, dynamic context) {
    return ast;
  }

  dynamic visitBinaryOperatorExpr(BinaryOperatorExpr ast, dynamic context) {
    ast.lhs.visitExpression(this, context);
    ast.rhs.visitExpression(this, context);
    return ast;
  }

  dynamic visitReadPropExpr(ReadPropExpr ast, dynamic context) {
    ast.receiver.visitExpression(this, context);
    return ast;
  }

  dynamic visitReadKeyExpr(ReadKeyExpr ast, dynamic context) {
    ast.receiver.visitExpression(this, context);
    ast.index.visitExpression(this, context);
    return ast;
  }

  dynamic visitLiteralArrayExpr(LiteralArrayExpr ast, dynamic context) {
    this.visitAllExpressions(ast.entries, context);
    return ast;
  }

  dynamic visitLiteralMapExpr(LiteralMapExpr ast, dynamic context) {
    ast.entries.forEach(
        (entry) => ((entry[1] as Expression)).visitExpression(this, context));
    return ast;
  }

  void visitAllExpressions(List<Expression> exprs, dynamic context) {
    exprs.forEach((expr) => expr.visitExpression(this, context));
  }

  dynamic visitDeclareVarStmt(DeclareVarStmt stmt, dynamic context) {
    stmt.value.visitExpression(this, context);
    return stmt;
  }

  dynamic visitDeclareFunctionStmt(DeclareFunctionStmt stmt, dynamic context) {
    // Don't descend into nested functions
    return stmt;
  }

  dynamic visitExpressionStmt(ExpressionStatement stmt, dynamic context) {
    stmt.expr.visitExpression(this, context);
    return stmt;
  }

  dynamic visitReturnStmt(ReturnStatement stmt, dynamic context) {
    stmt.value.visitExpression(this, context);
    return stmt;
  }

  dynamic visitDeclareClassStmt(ClassStmt stmt, dynamic context) {
    // Don't descend into nested functions
    return stmt;
  }

  dynamic visitIfStmt(IfStmt stmt, dynamic context) {
    stmt.condition.visitExpression(this, context);
    this.visitAllStatements(stmt.trueCase, context);
    this.visitAllStatements(stmt.falseCase, context);
    return stmt;
  }

  dynamic visitTryCatchStmt(TryCatchStmt stmt, dynamic context) {
    this.visitAllStatements(stmt.bodyStmts, context);
    this.visitAllStatements(stmt.catchStmts, context);
    return stmt;
  }

  dynamic visitThrowStmt(ThrowStmt stmt, dynamic context) {
    stmt.error.visitExpression(this, context);
    return stmt;
  }

  dynamic visitCommentStmt(CommentStmt stmt, dynamic context) {
    return stmt;
  }

  void visitAllStatements(List<Statement> stmts, dynamic context) {
    stmts.forEach((stmt) => stmt.visitStatement(this, context));
  }
}

Expression replaceVarInExpression(
    String varName, Expression newValue, Expression expression) {
  var transformer = new _ReplaceVariableTransformer(varName, newValue);
  return expression.visitExpression(transformer, null);
}

class _ReplaceVariableTransformer extends ExpressionTransformer {
  String _varName;
  Expression _newValue;
  _ReplaceVariableTransformer(this._varName, this._newValue) : super() {
    /* super call moved to initializer */;
  }
  dynamic visitReadVarExpr(ReadVarExpr ast, dynamic context) {
    return ast.name == this._varName ? this._newValue : ast;
  }
}

Set<String> findReadVarNames(List<Statement> stmts) {
  var finder = new _VariableFinder();
  finder.visitAllStatements(stmts, null);
  return finder.varNames;
}

class _VariableFinder extends RecursiveExpressionVisitor {
  var varNames = new Set<String>();
  dynamic visitReadVarExpr(ReadVarExpr ast, dynamic context) {
    this.varNames.add(ast.name);
    return null;
  }
}

ReadVarExpr variable(String name, [Type type = null]) {
  return new ReadVarExpr(name, type);
}

ExternalExpr importExpr(CompileIdentifierMetadata id,
    [List<Type> typeParams = null]) {
  return new ExternalExpr(id, null, typeParams);
}

ExternalType importType(CompileIdentifierMetadata id,
    [List<Type> typeParams = null, List<TypeModifier> typeModifiers = null]) {
  return isPresent(id) ? new ExternalType(id, typeParams, typeModifiers) : null;
}

LiteralExpr literal(dynamic value, [Type type = null]) {
  return new LiteralExpr(value, type);
}

LiteralArrayExpr literalArr(List<Expression> values, [Type type = null]) {
  return new LiteralArrayExpr(values, type);
}

LiteralMapExpr literalMap(List<List<dynamic /* String | Expression */ >> values,
    [MapType type = null]) {
  return new LiteralMapExpr(values, type);
}

NotExpr not(Expression expr) {
  return new NotExpr(expr);
}

FunctionExpr fn(List<FnParam> params, List<Statement> body,
    [Type type = null]) {
  return new FunctionExpr(params, body, type);
}
