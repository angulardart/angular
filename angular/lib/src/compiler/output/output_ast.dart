import "../compile_metadata.dart" show CompileIdentifierMetadata;

/// Supported modifiers for [OutputType].
enum TypeModifier { Const }

abstract class OutputType {
  final List<TypeModifier> modifiers;
  const OutputType([List<TypeModifier> modifiers])
      : this.modifiers = modifiers ?? const <TypeModifier>[];

  dynamic visitType(TypeVisitor visitor, dynamic context);
  bool hasModifier(TypeModifier modifier) {
    return !identical(this.modifiers.indexOf(modifier), -1);
  }
}

enum BuiltinTypeName { Dynamic, Bool, String, Int, Double, Number, Function }

class BuiltinType extends OutputType {
  final BuiltinTypeName name;

  const BuiltinType(this.name, [List<TypeModifier> modifiers])
      : super(modifiers);

  @override
  dynamic visitType(TypeVisitor visitor, dynamic context) =>
      visitor.visitBuiltinType(this, context);
}

class ExternalType extends OutputType {
  final CompileIdentifierMetadata value;
  final List<OutputType> typeParams;
  ExternalType(this.value, [this.typeParams, List<TypeModifier> modifiers])
      : super(modifiers);

  @override
  dynamic visitType(TypeVisitor visitor, dynamic context) =>
      visitor.visitExternalType(this, context);
}

class ArrayType extends OutputType {
  final OutputType of;
  ArrayType(this.of, [List<TypeModifier> modifiers]) : super(modifiers);

  @override
  dynamic visitType(TypeVisitor visitor, dynamic context) =>
      visitor.visitArrayType(this, context);
}

class MapType extends OutputType {
  final OutputType valueType;
  MapType(this.valueType, [List<TypeModifier> modifiers]) : super(modifiers);

  @override
  dynamic visitType(TypeVisitor visitor, dynamic context) =>
      visitor.visitMapType(this, context);
}

const DYNAMIC_TYPE = const BuiltinType(BuiltinTypeName.Dynamic);
const BOOL_TYPE = const BuiltinType(BuiltinTypeName.Bool);
const INT_TYPE = const BuiltinType(BuiltinTypeName.Int);
const DOUBLE_TYPE = const BuiltinType(BuiltinTypeName.Double);
const NUMBER_TYPE = const BuiltinType(BuiltinTypeName.Number);
const STRING_TYPE = const BuiltinType(BuiltinTypeName.String);
const FUNCTION_TYPE = const BuiltinType(BuiltinTypeName.Function);

abstract class TypeVisitor {
  dynamic visitBuiltinType(BuiltinType type, dynamic context);
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
  final OutputType type;
  Expression(this.type);
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context);
  ReadPropExpr prop(String name) {
    return new ReadPropExpr(this, name);
  }

  ReadKeyExpr key(Expression index, [OutputType type]) {
    return new ReadKeyExpr(this, index, type);
  }

  /// Calls a method on an expression result.
  ///
  /// If [checked] is specified, the call will make a safe null check before
  /// calling using '?' operator.
  InvokeMethodExpr callMethod(
      dynamic /* String | BuiltinMethod */ name, List<Expression> params,
      {bool checked: false}) {
    return new InvokeMethodExpr(this, name, params, checked: checked);
  }

  InvokeFunctionExpr callFn(List<Expression> params) {
    return new InvokeFunctionExpr(this, params);
  }

  InstantiateExpr instantiate(List<Expression> params, [OutputType type]) {
    return new InstantiateExpr(this, params, type);
  }

  ConditionalExpr conditional(Expression trueCase, [Expression falseCase]) {
    return new ConditionalExpr(this, trueCase, falseCase);
  }

  IfNullExpr ifNull(Expression nullCase) {
    return new IfNullExpr(this, nullCase);
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

  Expression cast(OutputType type) {
    return new CastExpr(this, type);
  }

  Statement toStmt() {
    return new ExpressionStatement(this);
  }
}

class NamedExpr extends Expression {
  String name;
  Expression expr;

  NamedExpr(this.name, this.expr) : super(expr.type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitNamedExpr(this, context);
  }
}

enum BuiltinVar { This, Super, CatchError, CatchStack, MetadataMap }

class ReadVarExpr extends Expression {
  String name;
  BuiltinVar builtin;
  ReadVarExpr(dynamic /* String | BuiltinVar */ name, [OutputType type])
      : super(type) {
    if (name is String) {
      this.name = name;
      this.builtin = null;
    } else {
      this.name = null;
      this.builtin = (name as BuiltinVar);
    }
  }
  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitReadVarExpr(this, context);
  }

  WriteVarExpr set(Expression value) {
    return new WriteVarExpr(this.name, value);
  }
}

class ReadStaticMemberExpr extends Expression {
  final String name;
  final OutputType sourceClass;
  ReadStaticMemberExpr(this.name, {OutputType type, this.sourceClass})
      : super(type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitReadStaticMemberExpr(this, context);
  }
}

class ReadClassMemberExpr extends Expression {
  final String name;
  ReadClassMemberExpr(this.name, [OutputType type]) : super(type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitReadClassMemberExpr(this, context);
  }

  WriteClassMemberExpr set(Expression value) {
    return new WriteClassMemberExpr(this.name, value);
  }
}

class WriteClassMemberExpr extends Expression {
  final String name;
  final Expression value;
  WriteClassMemberExpr(this.name, this.value, [OutputType type]) : super(type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitWriteClassMemberExpr(this, context);
  }
}

class WriteVarExpr extends Expression {
  final String name;
  final Expression value;
  WriteVarExpr(this.name, Expression value, [OutputType type])
      : this.value = value,
        super(type ?? value.type);
  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitWriteVarExpr(this, context);
  }

  DeclareVarStmt toDeclStmt([OutputType type, List<StmtModifier> modifiers]) {
    return new DeclareVarStmt(this.name, this.value, type, modifiers);
  }
}

class WriteIfNullExpr extends WriteVarExpr {
  WriteIfNullExpr(String name, Expression value, [OutputType type])
      : super(name, value, type ?? value.type);
  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitWriteVarExpr(this, context, checkForNull: true);
  }
}

class WriteStaticMemberExpr extends Expression {
  final String name;
  final Expression value;
  final bool checkIfNull;

  WriteStaticMemberExpr(this.name, Expression value,
      {OutputType type, this.checkIfNull: false})
      : this.value = value,
        super(type ?? value.type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitWriteStaticMemberExpr(this, context);
  }
}

class WriteKeyExpr extends Expression {
  final Expression receiver;
  final Expression index;
  final Expression value;
  WriteKeyExpr(this.receiver, this.index, Expression value, [OutputType type])
      : this.value = value,
        super(type ?? value.type);
  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitWriteKeyExpr(this, context);
  }
}

class WritePropExpr extends Expression {
  final Expression receiver;
  final String name;
  final Expression value;
  WritePropExpr(this.receiver, this.name, Expression value, [OutputType type])
      : this.value = value,
        super(type ?? value.type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitWritePropExpr(this, context);
  }
}

enum BuiltinMethod { ConcatArray, SubscribeObservable }

class InvokeMethodExpr extends Expression {
  final Expression receiver;
  final List<Expression> args;
  String name;
  BuiltinMethod builtin;
  final bool checked;

  InvokeMethodExpr(
      this.receiver, dynamic /* String | BuiltinMethod */ method, this.args,
      {OutputType outputType, this.checked})
      : super(outputType) {
    if (method is String) {
      this.name = method;
      this.builtin = null;
    } else {
      this.name = null;
      this.builtin = (method as BuiltinMethod);
    }
  }
  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitInvokeMethodExpr(this, context);
  }
}

class InvokeMemberMethodExpr extends Expression {
  final List<Expression> args;
  final String methodName;

  InvokeMemberMethodExpr(this.methodName, this.args, {OutputType outputType})
      : super(outputType);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitInvokeMemberMethodExpr(this, context);
  }
}

class InvokeFunctionExpr extends Expression {
  final Expression fn;
  final List<Expression> args;
  InvokeFunctionExpr(this.fn, this.args, [OutputType type]) : super(type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitInvokeFunctionExpr(this, context);
  }
}

class InstantiateExpr extends Expression {
  final Expression classExpr;
  final List<Expression> args;
  InstantiateExpr(this.classExpr, this.args, [OutputType type]) : super(type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitInstantiateExpr(this, context);
  }
}

class LiteralExpr extends Expression {
  final dynamic value;
  LiteralExpr(this.value, [OutputType type]) : super(type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitLiteralExpr(this, context);
  }
}

class ExternalExpr extends Expression {
  final CompileIdentifierMetadata value;
  final List<OutputType> typeParams;
  final bool deferred;

  ExternalExpr(this.value, {OutputType type, this.typeParams, this.deferred})
      : super(type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitExternalExpr(this, context);
  }
}

class ConditionalExpr extends Expression {
  final Expression condition;
  final Expression falseCase;
  final Expression trueCase;
  ConditionalExpr(this.condition, Expression trueCase,
      [this.falseCase, OutputType type])
      : this.trueCase = trueCase,
        super(type ?? trueCase.type);
  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitConditionalExpr(this, context);
  }
}

/// Represents the ?? expression in Dart
class IfNullExpr extends Expression {
  /// Condition for the null check and result if it is not null.
  final Expression condition;

  /// Result if the `condition` operand is null.
  final Expression nullCase;

  IfNullExpr(this.condition, Expression nullCase, [OutputType type])
      : nullCase = nullCase,
        super(type ?? nullCase.type);
  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitIfNullExpr(this, context);
  }
}

class NotExpr extends Expression {
  final Expression condition;
  NotExpr(this.condition) : super(BOOL_TYPE);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitNotExpr(this, context);
  }
}

class CastExpr extends Expression {
  final Expression value;
  CastExpr(this.value, OutputType type) : super(type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitCastExpr(this, context);
  }
}

class FnParam {
  final String name;
  final OutputType type;
  FnParam(this.name, [this.type]);
}

class FunctionExpr extends Expression {
  final List<FnParam> params;
  final List<Statement> statements;

  FunctionExpr(this.params, this.statements, [OutputType type]) : super(type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitFunctionExpr(this, context);
  }

  DeclareFunctionStmt toDeclStmt(String name, [List<StmtModifier> modifiers]) {
    return new DeclareFunctionStmt(
        name, this.params, this.statements, this.type, modifiers);
  }
}

class BinaryOperatorExpr extends Expression {
  final BinaryOperator operator;
  final Expression rhs;
  final Expression lhs;
  BinaryOperatorExpr(this.operator, Expression lhs, this.rhs, [OutputType type])
      : this.lhs = lhs,
        super(type ?? lhs.type);
  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitBinaryOperatorExpr(this, context);
  }
}

class ReadPropExpr extends Expression {
  final Expression receiver;
  final String name;

  ReadPropExpr(this.receiver, this.name, {OutputType outputType})
      : super(outputType);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitReadPropExpr(this, context);
  }

  WritePropExpr set(Expression value) {
    return new WritePropExpr(this.receiver, this.name, value);
  }
}

class ReadKeyExpr extends Expression {
  final Expression receiver;
  final Expression index;

  ReadKeyExpr(this.receiver, this.index, [OutputType type]) : super(type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitReadKeyExpr(this, context);
  }

  WriteKeyExpr set(Expression value) {
    return new WriteKeyExpr(this.receiver, this.index, value);
  }
}

class LiteralArrayExpr extends Expression {
  final List<Expression> entries;

  LiteralArrayExpr(this.entries, [OutputType type]) : super(type);

  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitLiteralArrayExpr(this, context);
  }
}

class LiteralMapExpr extends Expression {
  final List<List<dynamic /* String | Expression */ >> entries;
  OutputType valueType;
  LiteralMapExpr(this.entries, [MapType type]) : super(type) {
    if (type != null) {
      this.valueType = type.valueType;
    }
  }
  @override
  dynamic visitExpression(ExpressionVisitor visitor, dynamic context) {
    return visitor.visitLiteralMapExpr(this, context);
  }
}

abstract class ExpressionVisitor {
  dynamic visitReadVarExpr(ReadVarExpr ast, dynamic context);
  dynamic visitReadClassMemberExpr(ReadClassMemberExpr ast, dynamic context);
  dynamic visitWriteClassMemberExpr(WriteClassMemberExpr ast, dynamic context);
  dynamic visitWriteVarExpr(WriteVarExpr expr, dynamic context,
      {bool checkForNull: false});
  dynamic visitReadStaticMemberExpr(ReadStaticMemberExpr ast, dynamic context);
  dynamic visitWriteStaticMemberExpr(
      WriteStaticMemberExpr expr, dynamic context);
  dynamic visitWriteKeyExpr(WriteKeyExpr expr, dynamic context);
  dynamic visitWritePropExpr(WritePropExpr expr, dynamic context);
  dynamic visitInvokeMethodExpr(InvokeMethodExpr ast, dynamic context);
  dynamic visitInvokeMemberMethodExpr(
      InvokeMemberMethodExpr ast, dynamic context);
  dynamic visitInvokeFunctionExpr(InvokeFunctionExpr ast, dynamic context);
  dynamic visitInstantiateExpr(InstantiateExpr ast, dynamic context);
  dynamic visitLiteralExpr(LiteralExpr ast, dynamic context);
  dynamic visitExternalExpr(ExternalExpr ast, dynamic context);
  dynamic visitConditionalExpr(ConditionalExpr ast, dynamic context);
  dynamic visitIfNullExpr(IfNullExpr ast, dynamic context);
  dynamic visitNotExpr(NotExpr ast, dynamic context);
  dynamic visitCastExpr(CastExpr ast, dynamic context);
  dynamic visitFunctionExpr(FunctionExpr ast, dynamic context);
  dynamic visitBinaryOperatorExpr(BinaryOperatorExpr ast, dynamic context);
  dynamic visitReadPropExpr(ReadPropExpr ast, dynamic context);
  dynamic visitReadKeyExpr(ReadKeyExpr ast, dynamic context);
  dynamic visitLiteralArrayExpr(LiteralArrayExpr ast, dynamic context);
  dynamic visitLiteralMapExpr(LiteralMapExpr ast, dynamic context);
  dynamic visitNamedExpr(NamedExpr ast, dynamic context);
}

var THIS_EXPR = new ReadVarExpr(BuiltinVar.This);
var SUPER_EXPR = new ReadVarExpr(BuiltinVar.Super);
var CATCH_ERROR_VAR = new ReadVarExpr(BuiltinVar.CatchError);
var CATCH_STACK_VAR = new ReadVarExpr(BuiltinVar.CatchStack);
var NULL_EXPR = new LiteralExpr(null, null);
//// Statements
enum StmtModifier { Const, Final, Private, Static }

abstract class Statement {
  List<StmtModifier> modifiers;
  Statement([this.modifiers]) {
    this.modifiers ??= [];
  }
  dynamic visitStatement(StatementVisitor visitor, dynamic context);
  bool hasModifier(StmtModifier modifier) {
    return !identical(this.modifiers.indexOf(modifier), -1);
  }
}

class DeclareVarStmt extends Statement {
  final String name;
  final Expression value;
  final OutputType type;
  DeclareVarStmt(this.name, Expression value,
      [OutputType type, List<StmtModifier> modifiers])
      : this.type = type ?? value.type,
        this.value = value,
        super(modifiers);
  @override
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitDeclareVarStmt(this, context);
  }
}

class DeclareFunctionStmt extends Statement {
  final String name;
  final List<FnParam> params;
  final List<Statement> statements;
  final OutputType type;
  DeclareFunctionStmt(this.name, this.params, this.statements,
      [this.type, List<StmtModifier> modifiers])
      : super(modifiers);

  @override
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitDeclareFunctionStmt(this, context);
  }
}

class ExpressionStatement extends Statement {
  final Expression expr;
  ExpressionStatement(this.expr);

  @override
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitExpressionStmt(this, context);
  }
}

class ReturnStatement extends Statement {
  final Expression value;
  final String inlineComment;
  ReturnStatement(this.value, {this.inlineComment: ''});

  @override
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitReturnStmt(this, context);
  }
}

class AbstractClassPart {
  OutputType type;
  List<StmtModifier> modifiers;

  // TODO(srawlins): Make an Annotation class when we need to annotate with
  // something other than a constant, like `@overrides`.
  List<String> annotations;
  AbstractClassPart([this.type, this.modifiers, this.annotations]) {
    modifiers ??= [];
    annotations ??= [];
  }
  bool hasModifier(StmtModifier modifier) {
    return !identical(this.modifiers.indexOf(modifier), -1);
  }
}

class ClassField extends AbstractClassPart {
  String name;
  Expression initializer;
  ClassField(this.name,
      {OutputType outputType,
      List<StmtModifier> modifiers,
      List<String> annotations,
      this.initializer})
      : super(outputType, modifiers, annotations);
}

class ClassMethod extends AbstractClassPart {
  String name;
  List<FnParam> params;
  // Set for fast lookup of parameter names to see if we need 'this.' prefix.
  Set<String> paramNames;
  List<Statement> body;
  ClassMethod(this.name, this.params, this.body,
      [OutputType type, List<StmtModifier> modifiers, List<String> annotations])
      : super(type, modifiers, annotations) {
    if (params != null) {
      paramNames = new Set<String>();
      for (FnParam param in params) {
        paramNames.add(param.name);
      }
    }
  }

  /// Whether [name] is a parameter name.
  bool containsParameterName(String name) {
    if (paramNames == null) return false;
    return paramNames.contains(name);
  }
}

class ClassGetter extends AbstractClassPart {
  String name;
  List<Statement> body;
  ClassGetter(this.name, this.body,
      [OutputType type, List<StmtModifier> modifiers])
      : super(type, modifiers);
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
      [List<StmtModifier> modifiers])
      : super(modifiers);
  @override
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitDeclareClassStmt(this, context);
  }
}

class IfStmt extends Statement {
  Expression condition;
  List<Statement> trueCase;
  List<Statement> falseCase;
  IfStmt(this.condition, this.trueCase, [this.falseCase = const []]);

  @override
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitIfStmt(this, context);
  }
}

class CommentStmt extends Statement {
  String comment;
  CommentStmt(this.comment);

  @override
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitCommentStmt(this, context);
  }
}

class TryCatchStmt extends Statement {
  List<Statement> bodyStmts;
  List<Statement> catchStmts;
  TryCatchStmt(this.bodyStmts, this.catchStmts);

  @override
  dynamic visitStatement(StatementVisitor visitor, dynamic context) {
    return visitor.visitTryCatchStmt(this, context);
  }
}

class ThrowStmt extends Statement {
  Expression error;
  ThrowStmt(this.error);

  @override
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
  @override
  dynamic visitNamedExpr(NamedExpr ast, dynamic context) {
    return new NamedExpr(ast.name, ast.expr.visitExpression(this, context));
  }

  @override
  dynamic visitReadVarExpr(ReadVarExpr ast, dynamic context) {
    return ast;
  }

  @override
  dynamic visitReadClassMemberExpr(ReadClassMemberExpr ast, dynamic context) {
    return ast;
  }

  @override
  dynamic visitWriteVarExpr(WriteVarExpr expr, dynamic context,
      {bool checkForNull: false}) {
    if (checkForNull) {
      return new WriteIfNullExpr(
          expr.name, expr.value.visitExpression(this, context));
    }
    return new WriteVarExpr(
        expr.name, expr.value.visitExpression(this, context));
  }

  @override
  dynamic visitWriteStaticMemberExpr(
      WriteStaticMemberExpr expr, dynamic context) {
    return new WriteStaticMemberExpr(
        expr.name, expr.value.visitExpression(this, context),
        type: expr.type, checkIfNull: expr.checkIfNull);
  }

  @override
  dynamic visitReadStaticMemberExpr(ReadStaticMemberExpr ast, dynamic context) {
    return ast;
  }

  @override
  dynamic visitWriteKeyExpr(WriteKeyExpr expr, dynamic context) {
    return new WriteKeyExpr(
        expr.receiver.visitExpression(this, context),
        expr.index.visitExpression(this, context),
        expr.value.visitExpression(this, context));
  }

  @override
  dynamic visitWritePropExpr(WritePropExpr expr, dynamic context) {
    return new WritePropExpr(expr.receiver.visitExpression(this, context),
        expr.name, expr.value.visitExpression(this, context));
  }

  @override
  dynamic visitWriteClassMemberExpr(
      WriteClassMemberExpr expr, dynamic context) {
    return new WriteClassMemberExpr(
        expr.name, expr.value.visitExpression(this, context));
  }

  @override
  dynamic visitInvokeMethodExpr(InvokeMethodExpr ast, dynamic context) {
    var method = ast.builtin ?? ast.name;
    return new InvokeMethodExpr(ast.receiver.visitExpression(this, context),
        method, this.visitAllExpressions(ast.args, context),
        outputType: ast.type, checked: ast.checked);
  }

  @override
  dynamic visitInvokeMemberMethodExpr(
      InvokeMemberMethodExpr ast, dynamic context) {
    return new InvokeMemberMethodExpr(
        ast.methodName, this.visitAllExpressions(ast.args, context),
        outputType: ast.type);
  }

  @override
  dynamic visitInvokeFunctionExpr(InvokeFunctionExpr ast, dynamic context) {
    return new InvokeFunctionExpr(ast.fn.visitExpression(this, context),
        this.visitAllExpressions(ast.args, context), ast.type);
  }

  @override
  dynamic visitInstantiateExpr(InstantiateExpr ast, dynamic context) {
    return new InstantiateExpr(ast.classExpr.visitExpression(this, context),
        this.visitAllExpressions(ast.args, context), ast.type);
  }

  @override
  dynamic visitLiteralExpr(LiteralExpr ast, dynamic context) {
    return ast;
  }

  @override
  dynamic visitExternalExpr(ExternalExpr ast, dynamic context) {
    return ast;
  }

  @override
  dynamic visitConditionalExpr(ConditionalExpr ast, dynamic context) {
    return new ConditionalExpr(
        ast.condition.visitExpression(this, context),
        ast.trueCase.visitExpression(this, context),
        ast.falseCase.visitExpression(this, context));
  }

  @override
  dynamic visitIfNullExpr(IfNullExpr ast, dynamic context) {
    return new IfNullExpr(ast.condition.visitExpression(this, context),
        ast.nullCase.visitExpression(this, context));
  }

  @override
  dynamic visitNotExpr(NotExpr ast, dynamic context) {
    return new NotExpr(ast.condition.visitExpression(this, context));
  }

  @override
  dynamic visitCastExpr(CastExpr ast, dynamic context) {
    return new CastExpr(ast.value.visitExpression(this, context), context);
  }

  @override
  dynamic visitFunctionExpr(FunctionExpr ast, dynamic context) {
    // Don't descend into nested functions
    return ast;
  }

  @override
  dynamic visitBinaryOperatorExpr(BinaryOperatorExpr ast, dynamic context) {
    return new BinaryOperatorExpr(
        ast.operator,
        ast.lhs.visitExpression(this, context),
        ast.rhs.visitExpression(this, context),
        ast.type);
  }

  @override
  dynamic visitReadPropExpr(ReadPropExpr ast, dynamic context) {
    return new ReadPropExpr(
        ast.receiver.visitExpression(this, context), ast.name,
        outputType: ast.type);
  }

  @override
  dynamic visitReadKeyExpr(ReadKeyExpr ast, dynamic context) {
    return new ReadKeyExpr(ast.receiver.visitExpression(this, context),
        ast.index.visitExpression(this, context), ast.type);
  }

  @override
  dynamic visitLiteralArrayExpr(LiteralArrayExpr ast, dynamic context) {
    return new LiteralArrayExpr(this.visitAllExpressions(ast.entries, context));
  }

  @override
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
    return exprs
        .map((expr) => expr.visitExpression(this, context) as Expression)
        .toList();
  }

  @override
  dynamic visitDeclareVarStmt(DeclareVarStmt stmt, dynamic context) {
    return new DeclareVarStmt(stmt.name,
        stmt.value?.visitExpression(this, context), stmt.type, stmt.modifiers);
  }

  @override
  dynamic visitDeclareFunctionStmt(DeclareFunctionStmt stmt, dynamic context) {
    // Don't descend into nested functions
    return stmt;
  }

  @override
  dynamic visitExpressionStmt(ExpressionStatement stmt, dynamic context) {
    return new ExpressionStatement(stmt.expr.visitExpression(this, context));
  }

  @override
  dynamic visitReturnStmt(ReturnStatement stmt, dynamic context) {
    return new ReturnStatement(stmt.value?.visitExpression(this, context));
  }

  @override
  dynamic visitDeclareClassStmt(ClassStmt stmt, dynamic context) {
    // Don't descend into nested functions
    return stmt;
  }

  @override
  dynamic visitIfStmt(IfStmt stmt, dynamic context) {
    return new IfStmt(
        stmt.condition.visitExpression(this, context),
        this.visitAllStatements(stmt.trueCase, context),
        this.visitAllStatements(stmt.falseCase, context));
  }

  @override
  dynamic visitTryCatchStmt(TryCatchStmt stmt, dynamic context) {
    return new TryCatchStmt(this.visitAllStatements(stmt.bodyStmts, context),
        this.visitAllStatements(stmt.catchStmts, context));
  }

  @override
  dynamic visitThrowStmt(ThrowStmt stmt, dynamic context) {
    return new ThrowStmt(stmt.error.visitExpression(this, context));
  }

  @override
  dynamic visitCommentStmt(CommentStmt stmt, dynamic context) {
    return stmt;
  }

  List<Statement> visitAllStatements(List<Statement> stmts, dynamic context) {
    return stmts
        .map((stmt) => stmt.visitStatement(this, context) as Statement)
        .toList();
  }
}

class RecursiveExpressionVisitor
    implements StatementVisitor, ExpressionVisitor {
  @override
  dynamic visitNamedExpr(NamedExpr ast, dynamic context) {
    ast.expr.visitExpression(this, context);
    return ast;
  }

  @override
  dynamic visitReadVarExpr(ReadVarExpr ast, dynamic context) {
    return ast;
  }

  @override
  dynamic visitReadClassMemberExpr(ReadClassMemberExpr ast, dynamic context) {
    return ast;
  }

  @override
  dynamic visitWriteVarExpr(WriteVarExpr expr, dynamic context,
      {bool checkForNull: false}) {
    expr.value.visitExpression(this, context);
    return expr;
  }

  @override
  dynamic visitReadStaticMemberExpr(ReadStaticMemberExpr ast, dynamic context) {
    return ast;
  }

  @override
  dynamic visitWriteStaticMemberExpr(
      WriteStaticMemberExpr expr, dynamic context) {
    expr.value.visitExpression(this, context);
    return expr;
  }

  @override
  dynamic visitWriteKeyExpr(WriteKeyExpr expr, dynamic context) {
    expr.receiver.visitExpression(this, context);
    expr.index.visitExpression(this, context);
    expr.value.visitExpression(this, context);
    return expr;
  }

  @override
  dynamic visitWritePropExpr(WritePropExpr expr, dynamic context) {
    expr.receiver.visitExpression(this, context);
    expr.value.visitExpression(this, context);
    return expr;
  }

  @override
  dynamic visitWriteClassMemberExpr(
      WriteClassMemberExpr expr, dynamic context) {
    THIS_EXPR.visitExpression(this, context);
    expr.value.visitExpression(this, context);
    return expr;
  }

  @override
  dynamic visitInvokeMethodExpr(InvokeMethodExpr ast, dynamic context) {
    ast.receiver.visitExpression(this, context);
    this.visitAllExpressions(ast.args, context);
    return ast;
  }

  @override
  dynamic visitInvokeMemberMethodExpr(
      InvokeMemberMethodExpr ast, dynamic context) {
    this.visitAllExpressions(ast.args, context);
    return ast;
  }

  @override
  dynamic visitInvokeFunctionExpr(InvokeFunctionExpr ast, dynamic context) {
    ast.fn.visitExpression(this, context);
    this.visitAllExpressions(ast.args, context);
    return ast;
  }

  @override
  dynamic visitInstantiateExpr(InstantiateExpr ast, dynamic context) {
    ast.classExpr.visitExpression(this, context);
    this.visitAllExpressions(ast.args, context);
    return ast;
  }

  @override
  dynamic visitLiteralExpr(LiteralExpr ast, dynamic context) {
    return ast;
  }

  @override
  dynamic visitExternalExpr(ExternalExpr ast, dynamic context) {
    return ast;
  }

  @override
  dynamic visitConditionalExpr(ConditionalExpr ast, dynamic context) {
    ast.condition.visitExpression(this, context);
    ast.trueCase.visitExpression(this, context);
    ast.falseCase.visitExpression(this, context);
    return ast;
  }

  @override
  dynamic visitIfNullExpr(IfNullExpr ast, dynamic context) {
    ast.condition.visitExpression(this, context);
    ast.nullCase.visitExpression(this, context);
    return ast;
  }

  @override
  dynamic visitNotExpr(NotExpr ast, dynamic context) {
    ast.condition.visitExpression(this, context);
    return ast;
  }

  @override
  dynamic visitCastExpr(CastExpr ast, dynamic context) {
    ast.value.visitExpression(this, context);
    return ast;
  }

  @override
  dynamic visitFunctionExpr(FunctionExpr ast, dynamic context) {
    return ast;
  }

  @override
  dynamic visitBinaryOperatorExpr(BinaryOperatorExpr ast, dynamic context) {
    ast.lhs.visitExpression(this, context);
    ast.rhs.visitExpression(this, context);
    return ast;
  }

  @override
  dynamic visitReadPropExpr(ReadPropExpr ast, dynamic context) {
    ast.receiver.visitExpression(this, context);
    return ast;
  }

  @override
  dynamic visitReadKeyExpr(ReadKeyExpr ast, dynamic context) {
    ast.receiver.visitExpression(this, context);
    ast.index.visitExpression(this, context);
    return ast;
  }

  @override
  dynamic visitLiteralArrayExpr(LiteralArrayExpr ast, dynamic context) {
    this.visitAllExpressions(ast.entries, context);
    return ast;
  }

  @override
  dynamic visitLiteralMapExpr(LiteralMapExpr ast, dynamic context) {
    for (var entry in ast.entries) {
      ((entry[1] as Expression)).visitExpression(this, context);
    }
    return ast;
  }

  void visitAllExpressions(List<Expression> exprs, dynamic context) {
    for (var expr in exprs) {
      expr.visitExpression(this, context);
    }
  }

  @override
  dynamic visitDeclareVarStmt(DeclareVarStmt stmt, dynamic context) {
    stmt.value?.visitExpression(this, context);
    return stmt;
  }

  @override
  dynamic visitDeclareFunctionStmt(DeclareFunctionStmt stmt, dynamic context) {
    // Don't descend into nested functions
    return stmt;
  }

  @override
  dynamic visitExpressionStmt(ExpressionStatement stmt, dynamic context) {
    stmt.expr.visitExpression(this, context);
    return stmt;
  }

  @override
  dynamic visitReturnStmt(ReturnStatement stmt, dynamic context) {
    stmt.value?.visitExpression(this, context);
    return stmt;
  }

  @override
  dynamic visitDeclareClassStmt(ClassStmt stmt, dynamic context) {
    // Don't descend into nested functions
    return stmt;
  }

  @override
  dynamic visitIfStmt(IfStmt stmt, dynamic context) {
    stmt.condition.visitExpression(this, context);
    this.visitAllStatements(stmt.trueCase, context);
    this.visitAllStatements(stmt.falseCase, context);
    return stmt;
  }

  @override
  dynamic visitTryCatchStmt(TryCatchStmt stmt, dynamic context) {
    this.visitAllStatements(stmt.bodyStmts, context);
    this.visitAllStatements(stmt.catchStmts, context);
    return stmt;
  }

  @override
  dynamic visitThrowStmt(ThrowStmt stmt, dynamic context) {
    stmt.error.visitExpression(this, context);
    return stmt;
  }

  @override
  dynamic visitCommentStmt(CommentStmt stmt, dynamic context) {
    return stmt;
  }

  void visitAllStatements(List<Statement> stmts, dynamic context) {
    for (var stmt in stmts) {
      stmt.visitStatement(this, context);
    }
  }
}

Expression replaceReadClassMemberInExpression(
    Expression newValue, Expression expression) {
  var transformer = new _ReplaceReadClassMemberTransformer(newValue);
  return expression.visitExpression(transformer, null);
}

class _ReplaceReadClassMemberTransformer extends ExpressionTransformer {
  final Expression _newValue;
  _ReplaceReadClassMemberTransformer(this._newValue);

  @override
  dynamic visitReadClassMemberExpr(ReadClassMemberExpr ast, dynamic context) =>
      new ReadPropExpr(_newValue, ast.name);
}

Expression replaceVarInExpression(
    String varName, Expression newValue, Expression expression) {
  var transformer = new _ReplaceVariableTransformer(varName, newValue);
  return expression.visitExpression(transformer, null);
}

Statement replaceVarInStatement(
    String varName, Expression newValue, Statement statement) {
  var transformer = new _ReplaceVariableTransformer(varName, newValue);
  return statement.visitStatement(transformer, null);
}

class _ReplaceVariableTransformer extends ExpressionTransformer {
  final String _varName;
  final Expression _newValue;
  _ReplaceVariableTransformer(this._varName, this._newValue);

  @override
  dynamic visitReadVarExpr(ReadVarExpr ast, dynamic context) =>
      ast.name == this._varName ? this._newValue : ast;

  @override
  dynamic visitReadClassMemberExpr(ReadClassMemberExpr ast, dynamic context) =>
      ast.name == this._varName ? this._newValue : ast;
}

Set<String> findReadVarNames(List<Statement> stmts) {
  var finder = new _VariableFinder();
  finder.visitAllStatements(stmts, null);
  return finder.varNames;
}

class _VariableFinder extends RecursiveExpressionVisitor {
  final varNames = new Set<String>();

  @override
  dynamic visitReadVarExpr(ReadVarExpr ast, dynamic context) {
    this.varNames.add(ast.name);
    return null;
  }
}

ReadVarExpr variable(String name, [OutputType type]) {
  return new ReadVarExpr(name, type);
}

ExternalExpr importExpr(CompileIdentifierMetadata id,
    {List<OutputType> typeParams, bool isConst: false}) {
  return new ExternalExpr(id, typeParams: typeParams);
}

ExternalExpr importDeferred(CompileIdentifierMetadata id,
    [List<OutputType> typeParams]) {
  return new ExternalExpr(id, typeParams: typeParams, deferred: true);
}

ExternalType importType(CompileIdentifierMetadata id,
    [List<OutputType> typeParams, List<TypeModifier> typeModifiers]) {
  return id != null ? new ExternalType(id, typeParams, typeModifiers) : null;
}

LiteralExpr literal(dynamic value, [OutputType type]) {
  return new LiteralExpr(value, type);
}

LiteralArrayExpr literalArr(List<Expression> values, [OutputType type]) {
  return new LiteralArrayExpr(values, type);
}

LiteralMapExpr literalMap(List<List<dynamic /* String | Expression */ >> values,
    [MapType type]) {
  return new LiteralMapExpr(values, type);
}

NotExpr not(Expression expr) {
  return new NotExpr(expr);
}

FunctionExpr fn(List<FnParam> params, List<Statement> body, [OutputType type]) {
  return new FunctionExpr(params, body, type);
}
