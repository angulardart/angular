import "../compile_metadata.dart" show CompileIdentifierMetadata;

/// Supported modifiers for [OutputType].
enum TypeModifier { Const }

abstract class OutputType {
  final List<TypeModifier> modifiers;
  const OutputType([List<TypeModifier> modifiers])
      : this.modifiers = modifiers ?? const <TypeModifier>[];

  R visitType<R, C>(TypeVisitor<R, C> visitor, C context);
  bool hasModifier(TypeModifier modifier) {
    return !identical(this.modifiers.indexOf(modifier), -1);
  }
}

enum BuiltinTypeName {
  Dynamic,
  Bool,
  String,
  Int,
  Double,
  Number,
  Function,
  Void,
  Null,
}

class BuiltinType extends OutputType {
  final BuiltinTypeName name;

  const BuiltinType(this.name, [List<TypeModifier> modifiers])
      : super(modifiers);

  @override
  R visitType<R, C>(TypeVisitor<R, C> visitor, C context) =>
      visitor.visitBuiltinType(this, context);
}

class ExternalType extends OutputType {
  final CompileIdentifierMetadata value;
  final List<OutputType> typeParams;
  ExternalType(this.value, [this.typeParams, List<TypeModifier> modifiers])
      : super(modifiers);

  @override
  R visitType<R, C>(TypeVisitor<R, C> visitor, C context) =>
      visitor.visitExternalType(this, context);
}

class FunctionType extends OutputType {
  final OutputType returnType;
  final List<OutputType> paramTypes; // Required and named/positional optional.

  FunctionType(this.returnType, this.paramTypes, [List<TypeModifier> modifiers])
      : super(modifiers);

  @override
  R visitType<R, C>(TypeVisitor<R, C> visitor, C context) =>
      visitor.visitFunctionType(this, context);
}

class ArrayType extends OutputType {
  final OutputType of;
  ArrayType(this.of, [List<TypeModifier> modifiers]) : super(modifiers);

  @override
  R visitType<R, C>(TypeVisitor<R, C> visitor, C context) =>
      visitor.visitArrayType(this, context);
}

class MapType extends OutputType {
  final OutputType valueType;
  MapType(this.valueType, [List<TypeModifier> modifiers]) : super(modifiers);

  @override
  R visitType<R, C>(TypeVisitor<R, C> visitor, C context) =>
      visitor.visitMapType(this, context);
}

const DYNAMIC_TYPE = BuiltinType(BuiltinTypeName.Dynamic);
const VOID_TYPE = BuiltinType(BuiltinTypeName.Void);
const NULL_TYPE = BuiltinType(BuiltinTypeName.Null);
const BOOL_TYPE = BuiltinType(BuiltinTypeName.Bool);
const INT_TYPE = BuiltinType(BuiltinTypeName.Int);
const DOUBLE_TYPE = BuiltinType(BuiltinTypeName.Double);
const NUMBER_TYPE = BuiltinType(BuiltinTypeName.Number);
const STRING_TYPE = BuiltinType(BuiltinTypeName.String);
const FUNCTION_TYPE = BuiltinType(BuiltinTypeName.Function);

abstract class TypeVisitor<R, C> {
  R visitBuiltinType(BuiltinType type, C context);
  R visitExternalType(ExternalType type, C context);
  R visitFunctionType(FunctionType type, C context);
  R visitArrayType(ArrayType type, C context);
  R visitMapType(MapType type, C context);
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
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context);
  ReadPropExpr prop(String name) {
    return ReadPropExpr(this, name);
  }

  ReadKeyExpr key(Expression index, [OutputType type]) {
    return ReadKeyExpr(this, index, type);
  }

  /// Calls a method on an expression result.
  ///
  /// If [checked] is specified, the call will make a safe null check before
  /// calling using '?' operator.
  InvokeMethodExpr callMethod(
    dynamic /* String | BuiltinMethod */ name,
    List<Expression> params, {
    bool checked = false,
    List<NamedExpr> namedParams,
  }) {
    return InvokeMethodExpr(this, name, params,
        checked: checked, namedArgs: namedParams);
  }

  InvokeFunctionExpr callFn(
    List<Expression> params, {
    List<NamedExpr> namedParams,
    List<OutputType> typeArguments,
  }) {
    return InvokeFunctionExpr(
      this,
      params,
      typeArguments,
      namedArgs: namedParams,
    );
  }

  InstantiateExpr instantiate(
    List<Expression> params, {
    List<NamedExpr> namedParams,
    OutputType type,
    List<OutputType> genericTypes,
  }) {
    return InstantiateExpr(
      this,
      params,
      type: type,
      typeArguments: genericTypes,
      namedArgs: namedParams,
    );
  }

  ConditionalExpr conditional(Expression trueCase, [Expression falseCase]) {
    return ConditionalExpr(this, trueCase, falseCase);
  }

  IfNullExpr ifNull(Expression nullCase) {
    return IfNullExpr(this, nullCase);
  }

  BinaryOperatorExpr equals(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.Equals, this, rhs);
  }

  BinaryOperatorExpr notEquals(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.NotEquals, this, rhs);
  }

  BinaryOperatorExpr identical(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.Identical, this, rhs);
  }

  BinaryOperatorExpr notIdentical(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.NotIdentical, this, rhs);
  }

  BinaryOperatorExpr minus(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.Minus, this, rhs);
  }

  BinaryOperatorExpr plus(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.Plus, this, rhs);
  }

  BinaryOperatorExpr divide(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.Divide, this, rhs);
  }

  BinaryOperatorExpr multiply(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.Multiply, this, rhs);
  }

  BinaryOperatorExpr modulo(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.Modulo, this, rhs);
  }

  BinaryOperatorExpr and(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.And, this, rhs);
  }

  BinaryOperatorExpr or(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.Or, this, rhs);
  }

  BinaryOperatorExpr lower(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.Lower, this, rhs);
  }

  BinaryOperatorExpr lowerEquals(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.LowerEquals, this, rhs);
  }

  BinaryOperatorExpr bigger(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.Bigger, this, rhs);
  }

  BinaryOperatorExpr biggerEquals(Expression rhs) {
    return BinaryOperatorExpr(BinaryOperator.BiggerEquals, this, rhs);
  }

  Expression isBlank() {
    // Note: We use equals by purpose here to compare to null and undefined in JS.
    return this.equals(NULL_EXPR);
  }

  Expression cast(OutputType type) {
    return CastExpr(this, type);
  }

  Statement toStmt() {
    return ExpressionStatement(this);
  }
}

class NamedExpr extends Expression {
  String name;
  Expression expr;

  NamedExpr(this.name, this.expr) : super(expr.type);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
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
      this.builtin = name as BuiltinVar;
    }
  }
  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitReadVarExpr(this, context);
  }

  WriteVarExpr set(Expression value) {
    return WriteVarExpr(this.name, value);
  }
}

class ReadStaticMemberExpr extends Expression {
  final String name;
  final OutputType sourceClass;
  ReadStaticMemberExpr(this.name, {OutputType type, this.sourceClass})
      : super(type);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitReadStaticMemberExpr(this, context);
  }
}

class ReadClassMemberExpr extends Expression {
  final String name;
  ReadClassMemberExpr(this.name, [OutputType type]) : super(type);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitReadClassMemberExpr(this, context);
  }

  WriteClassMemberExpr set(Expression value) {
    return WriteClassMemberExpr(this.name, value);
  }

  @override
  String toString() => 'ReadClassMember {$name, $type}';
}

class WriteClassMemberExpr extends Expression {
  final String name;
  final Expression value;
  WriteClassMemberExpr(this.name, this.value, [OutputType type]) : super(type);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitWriteClassMemberExpr(this, context);
  }
}

class WriteVarExpr extends Expression {
  final String name;
  final Expression value;
  WriteVarExpr(this.name, this.value, [OutputType type])
      : super(type ?? value.type);
  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitWriteVarExpr(this, context);
  }

  DeclareVarStmt toDeclStmt([OutputType type, List<StmtModifier> modifiers]) {
    return DeclareVarStmt(this.name, this.value, type, modifiers);
  }
}

class WriteIfNullExpr extends WriteVarExpr {
  WriteIfNullExpr(String name, Expression value, [OutputType type])
      : super(name, value, type ?? value.type);
  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitWriteVarExpr(this, context, checkForNull: true);
  }
}

class WriteStaticMemberExpr extends Expression {
  final String name;
  final Expression value;
  final bool checkIfNull;

  WriteStaticMemberExpr(this.name, this.value,
      {OutputType type, this.checkIfNull = false})
      : super(type ?? value.type);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitWriteStaticMemberExpr(this, context);
  }
}

class WriteKeyExpr extends Expression {
  final Expression receiver;
  final Expression index;
  final Expression value;
  WriteKeyExpr(this.receiver, this.index, this.value, [OutputType type])
      : super(type ?? value.type);
  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitWriteKeyExpr(this, context);
  }
}

class WritePropExpr extends Expression {
  final Expression receiver;
  final String name;
  final Expression value;
  WritePropExpr(this.receiver, this.name, this.value, [OutputType type])
      : super(type ?? value.type);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitWritePropExpr(this, context);
  }
}

enum BuiltinMethod { ConcatArray, SubscribeObservable }

class InvokeMethodExpr extends Expression {
  final Expression receiver;
  final List<Expression> args;
  final List<NamedExpr> namedArgs;

  String name;
  BuiltinMethod builtin;
  final bool checked;

  InvokeMethodExpr(
    this.receiver,
    dynamic /* String | BuiltinMethod */ method,
    this.args, {
    OutputType outputType,
    this.checked,
    this.namedArgs = const [],
  }) : super(outputType) {
    assert(() {
      for (var arg in args) {
        if (arg == null) {
          throw ArgumentError.notNull();
        }
      }
      return true;
    }());
    if (method is String) {
      this.name = method;
      this.builtin = null;
    } else {
      this.name = null;
      this.builtin = method as BuiltinMethod;
    }
  }
  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitInvokeMethodExpr(this, context);
  }
}

class InvokeMemberMethodExpr extends Expression {
  final List<Expression> args;
  final String methodName;
  final List<NamedExpr> namedArgs;

  InvokeMemberMethodExpr(
    this.methodName,
    this.args, {
    OutputType outputType,
    this.namedArgs,
  }) : super(outputType) {
    assert(() {
      for (var arg in args) {
        if (arg == null) {
          throw ArgumentError.notNull();
        }
      }
      return true;
    }());
  }

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitInvokeMemberMethodExpr(this, context);
  }
}

class InvokeFunctionExpr extends Expression {
  final Expression fn;
  final List<Expression> args;
  final List<OutputType> typeArgs;
  final List<NamedExpr> namedArgs;

  InvokeFunctionExpr(
    this.fn,
    this.args,
    this.typeArgs, {
    OutputType type,
    this.namedArgs = const [],
  }) : super(type) {
    assert(() {
      for (var arg in args) {
        if (arg == null) {
          throw ArgumentError.notNull();
        }
      }
      return true;
    }());
  }

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitInvokeFunctionExpr(this, context);
  }
}

class InstantiateExpr extends Expression {
  final Expression classExpr;
  final List<Expression> args;
  final List<OutputType> typeArguments;
  final List<NamedExpr> namedArgs;

  InstantiateExpr(
    this.classExpr,
    this.args, {
    OutputType type,
    this.typeArguments,
    this.namedArgs = const [],
  }) : super(type) {
    assert(() {
      for (int len = args.length, i = 0; i < len; i++) {
        if (args[i] == null) {
          throw ArgumentError('Expecting non-null arguments');
        }
      }
      return true;
    }());
  }

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitInstantiateExpr(this, context);
  }
}

class LiteralExpr extends Expression {
  final dynamic value;
  LiteralExpr(this.value, [OutputType type]) : super(type);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
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
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitExternalExpr(this, context);
  }
}

class ConditionalExpr extends Expression {
  final Expression condition;
  final Expression falseCase;
  final Expression trueCase;
  ConditionalExpr(this.condition, this.trueCase,
      [this.falseCase, OutputType type])
      : super(type ?? trueCase.type);
  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitConditionalExpr(this, context);
  }
}

/// Represents the ?? expression in Dart
class IfNullExpr extends Expression {
  /// Condition for the null check and result if it is not null.
  final Expression condition;

  /// Result if the `condition` operand is null.
  final Expression nullCase;

  IfNullExpr(this.condition, this.nullCase, [OutputType type])
      : super(type ?? nullCase.type);
  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitIfNullExpr(this, context);
  }
}

class NotExpr extends Expression {
  final Expression condition;
  NotExpr(this.condition) : super(BOOL_TYPE);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitNotExpr(this, context);
  }
}

class CastExpr extends Expression {
  final Expression value;
  CastExpr(this.value, OutputType type) : super(type);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
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
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitFunctionExpr(this, context);
  }

  DeclareFunctionStmt toDeclStmt(
    String name, {
    List<TypeParameter> typeParameters = const [],
  }) {
    return DeclareFunctionStmt(
      name,
      this.params,
      this.statements,
      type: this.type,
      typeParameters: typeParameters,
    );
  }

  DeclareFunctionStmt toGetter(String name) {
    return DeclareFunctionStmt(
      name,
      [],
      this.statements,
      type: this.type,
      isGetter: true,
    );
  }
}

class BinaryOperatorExpr extends Expression {
  final BinaryOperator operator;
  final Expression rhs;
  final Expression lhs;
  BinaryOperatorExpr(this.operator, this.lhs, this.rhs, [OutputType type])
      : super(type ?? lhs.type);
  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitBinaryOperatorExpr(this, context);
  }
}

class ReadPropExpr extends Expression {
  final Expression receiver;
  final String name;

  ReadPropExpr(this.receiver, this.name, {OutputType outputType})
      : super(outputType) {
    assert(name != null, 'Expecting name in ReadPropExpr');
  }

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitReadPropExpr(this, context);
  }

  WritePropExpr set(Expression value) {
    return WritePropExpr(this.receiver, this.name, value);
  }
}

class ReadKeyExpr extends Expression {
  final Expression receiver;
  final Expression index;

  ReadKeyExpr(this.receiver, this.index, [OutputType type]) : super(type);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitReadKeyExpr(this, context);
  }

  WriteKeyExpr set(Expression value) {
    return WriteKeyExpr(this.receiver, this.index, value);
  }
}

/// Similar to [LiteralArrayExpr], but without wrapping in brackets.
class LiteralVargsExpr extends Expression {
  final List<Expression> entries;

  LiteralVargsExpr(this.entries) : super(null);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitLiteralVargsExpr(this, context);
  }
}

class LiteralArrayExpr extends Expression {
  final List<Expression> entries;

  LiteralArrayExpr(this.entries, [OutputType type]) : super(type);

  @override
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
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
  R visitExpression<R, C>(ExpressionVisitor<R, C> visitor, C context) {
    return visitor.visitLiteralMapExpr(this, context);
  }
}

abstract class ExpressionVisitor<R, C> {
  R visitReadVarExpr(ReadVarExpr ast, C context);
  R visitReadClassMemberExpr(ReadClassMemberExpr ast, C context);
  R visitWriteClassMemberExpr(WriteClassMemberExpr ast, C context);
  R visitWriteVarExpr(WriteVarExpr expr, C context,
      {bool checkForNull = false});
  R visitReadStaticMemberExpr(ReadStaticMemberExpr ast, C context);
  R visitWriteStaticMemberExpr(WriteStaticMemberExpr expr, C context);
  R visitWriteKeyExpr(WriteKeyExpr expr, C context);
  R visitWritePropExpr(WritePropExpr expr, C context);
  R visitInvokeMethodExpr(InvokeMethodExpr ast, C context);
  R visitInvokeMemberMethodExpr(InvokeMemberMethodExpr ast, C context);
  R visitInvokeFunctionExpr(InvokeFunctionExpr ast, C context);
  R visitInstantiateExpr(InstantiateExpr ast, C context);
  R visitLiteralExpr(LiteralExpr ast, C context);
  R visitExternalExpr(ExternalExpr ast, C context);
  R visitConditionalExpr(ConditionalExpr ast, C context);
  R visitIfNullExpr(IfNullExpr ast, C context);
  R visitNotExpr(NotExpr ast, C context);
  R visitCastExpr(CastExpr ast, C context);
  R visitFunctionExpr(FunctionExpr ast, C context);
  R visitBinaryOperatorExpr(BinaryOperatorExpr ast, C context);
  R visitReadPropExpr(ReadPropExpr ast, C context);
  R visitReadKeyExpr(ReadKeyExpr ast, C context);
  R visitLiteralVargsExpr(LiteralVargsExpr ast, C context);
  R visitLiteralArrayExpr(LiteralArrayExpr ast, C context);
  R visitLiteralMapExpr(LiteralMapExpr ast, C context);
  R visitNamedExpr(NamedExpr ast, C context);
}

var THIS_EXPR = ReadVarExpr(BuiltinVar.This);
var SUPER_EXPR = ReadVarExpr(BuiltinVar.Super);
var CATCH_ERROR_VAR = ReadVarExpr(BuiltinVar.CatchError);
var CATCH_STACK_VAR = ReadVarExpr(BuiltinVar.CatchStack);
var NULL_EXPR = LiteralExpr(null, null);
//// Statements
enum StmtModifier { Const, Final, Private, Static }

abstract class Statement {
  List<StmtModifier> modifiers;
  Statement([this.modifiers]) {
    this.modifiers ??= [];
  }
  R visitStatement<R, C>(StatementVisitor<R, C> visitor, C context);
  bool hasModifier(StmtModifier modifier) {
    return !identical(this.modifiers.indexOf(modifier), -1);
  }
}

class DeclareVarStmt extends Statement {
  final String name;
  final Expression value;
  final OutputType type;
  DeclareVarStmt(this.name, this.value,
      [OutputType type, List<StmtModifier> modifiers])
      : this.type = type ?? value.type,
        super(modifiers);
  @override
  R visitStatement<R, C>(StatementVisitor<R, C> visitor, C context) {
    return visitor.visitDeclareVarStmt(this, context);
  }

  DeclareVarStmt withValue(Expression replacement) {
    return DeclareVarStmt(name, replacement, type, modifiers);
  }
}

class DeclareFunctionStmt extends Statement {
  final String name;
  final List<TypeParameter> typeParameters;
  final List<FnParam> params;
  final List<Statement> statements;
  final OutputType type;
  final bool isGetter;

  DeclareFunctionStmt(
    this.name,
    this.params,
    this.statements, {
    this.type,
    this.typeParameters = const [],
    this.isGetter = false,
  });

  @override
  R visitStatement<R, C>(StatementVisitor<R, C> visitor, C context) {
    return visitor.visitDeclareFunctionStmt(this, context);
  }
}

class ExpressionStatement extends Statement {
  final Expression expr;
  ExpressionStatement(this.expr);

  @override
  R visitStatement<R, C>(StatementVisitor<R, C> visitor, C context) {
    return visitor.visitExpressionStmt(this, context);
  }
}

class ReturnStatement extends Statement {
  final Expression value;
  final String inlineComment;
  ReturnStatement(this.value, {this.inlineComment = ''});

  @override
  R visitStatement<R, C>(StatementVisitor<R, C> visitor, C context) {
    return visitor.visitReturnStmt(this, context);
  }
}

class AbstractClassPart {
  OutputType type;
  List<StmtModifier> modifiers;
  List<Expression> annotations;

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
      List<Expression> annotations,
      this.initializer})
      : super(outputType, modifiers, annotations);
}

class Constructor extends ClassMethod {
  List<Statement> initializers;

  Constructor({
    List<FnParam> params,
    List<Statement> body,
    List<Statement> initializers,
  })  : this.initializers = initializers ?? [],
        super(null, params ?? [], body ?? []);
}

class ClassMethod extends AbstractClassPart {
  String name;
  List<FnParam> params;
  List<Statement> body;
  ClassMethod(
    this.name,
    this.params,
    this.body, [
    OutputType type,
    List<StmtModifier> modifiers,
    List<Expression> annotations,
  ]) : super(type, modifiers, annotations);
}

class ClassGetter extends AbstractClassPart {
  String name;
  List<Statement> body;
  ClassGetter(
    this.name,
    this.body, [
    OutputType type,
    List<StmtModifier> modifiers,
    List<Expression> annotations,
  ]) : super(type, modifiers, annotations);
}

/// A generic type parameter.
class TypeParameter {
  /// This type parameters name.
  ///
  /// For example, this would be `T` in `class Foo<T> {}`.
  final String name;

  /// The type parameter's bound.
  ///
  /// For example, this would be `Bar` in `class Foo<T extends Bar> {}`. Note
  /// that the bound itself may have generic type arguments.
  ///
  /// Null if this has no bound. Note that this is functionally equivalent to a
  /// bound of dynamic.
  final OutputType bound;

  TypeParameter(this.name, {this.bound});

  /// Converts this type parameter to a type.
  OutputType toType() => importType(CompileIdentifierMetadata(name: name));
}

class ClassStmt extends Statement {
  final List<TypeParameter> typeParameters;

  String name;
  Expression parent;
  List<ClassField> fields;
  List<ClassGetter> getters;
  Constructor constructorMethod;
  List<ClassMethod> methods;

  ClassStmt(
    this.name,
    this.parent,
    this.fields,
    this.getters,
    this.constructorMethod,
    this.methods, {
    this.typeParameters = const [],
  });

  @override
  R visitStatement<R, C>(StatementVisitor<R, C> visitor, C context) {
    return visitor.visitDeclareClassStmt(this, context);
  }
}

class IfStmt extends Statement {
  Expression condition;
  List<Statement> trueCase;
  List<Statement> falseCase;
  IfStmt(this.condition, this.trueCase, [this.falseCase = const []]);

  @override
  R visitStatement<R, C>(StatementVisitor<R, C> visitor, C context) {
    return visitor.visitIfStmt(this, context);
  }
}

class CommentStmt extends Statement {
  String comment;
  CommentStmt(this.comment);

  @override
  R visitStatement<R, C>(StatementVisitor<R, C> visitor, C context) {
    return visitor.visitCommentStmt(this, context);
  }
}

class TryCatchStmt extends Statement {
  List<Statement> bodyStmts;
  List<Statement> catchStmts;
  TryCatchStmt(this.bodyStmts, this.catchStmts);

  @override
  R visitStatement<R, C>(StatementVisitor<R, C> visitor, C context) {
    return visitor.visitTryCatchStmt(this, context);
  }
}

class ThrowStmt extends Statement {
  Expression error;
  ThrowStmt(this.error);

  @override
  R visitStatement<R, C>(StatementVisitor<R, C> visitor, C context) {
    return visitor.visitThrowStmt(this, context);
  }
}

abstract class StatementVisitor<R, C> {
  R visitDeclareVarStmt(DeclareVarStmt stmt, C context);
  R visitDeclareFunctionStmt(DeclareFunctionStmt stmt, C context);
  R visitExpressionStmt(ExpressionStatement stmt, C context);
  R visitReturnStmt(ReturnStatement stmt, C context);
  R visitDeclareClassStmt(ClassStmt stmt, C context);
  R visitIfStmt(IfStmt stmt, C context);
  R visitTryCatchStmt(TryCatchStmt stmt, C context);
  R visitThrowStmt(ThrowStmt stmt, C context);
  R visitCommentStmt(CommentStmt stmt, C context);
}

class ExpressionTransformer<C>
    implements
        StatementVisitor<Statement, C>,
        ExpressionVisitor<Expression, C> {
  @override
  Expression visitNamedExpr(NamedExpr ast, C context) {
    return NamedExpr(ast.name, ast.expr.visitExpression(this, context));
  }

  @override
  Expression visitReadVarExpr(ReadVarExpr ast, C context) {
    return ast;
  }

  @override
  Expression visitReadClassMemberExpr(ReadClassMemberExpr ast, C context) {
    return ast;
  }

  @override
  Expression visitWriteVarExpr(WriteVarExpr expr, C context,
      {bool checkForNull = false}) {
    if (checkForNull) {
      return WriteIfNullExpr(
          expr.name, expr.value.visitExpression(this, context));
    }
    return WriteVarExpr(expr.name, expr.value.visitExpression(this, context));
  }

  @override
  Expression visitWriteStaticMemberExpr(WriteStaticMemberExpr expr, C context) {
    return WriteStaticMemberExpr(
        expr.name, expr.value.visitExpression(this, context),
        type: expr.type, checkIfNull: expr.checkIfNull);
  }

  @override
  Expression visitReadStaticMemberExpr(ReadStaticMemberExpr ast, C context) {
    return ast;
  }

  @override
  Expression visitWriteKeyExpr(WriteKeyExpr expr, C context) {
    return WriteKeyExpr(
        expr.receiver.visitExpression(this, context),
        expr.index.visitExpression(this, context),
        expr.value.visitExpression(this, context));
  }

  @override
  Expression visitWritePropExpr(WritePropExpr expr, C context) {
    return WritePropExpr(expr.receiver.visitExpression(this, context),
        expr.name, expr.value.visitExpression(this, context));
  }

  @override
  Expression visitWriteClassMemberExpr(WriteClassMemberExpr expr, C context) {
    return WriteClassMemberExpr(
        expr.name, expr.value.visitExpression(this, context));
  }

  @override
  Expression visitInvokeMethodExpr(InvokeMethodExpr ast, C context) {
    var method = ast.builtin ?? ast.name;
    return InvokeMethodExpr(
      ast.receiver.visitExpression(this, context),
      method,
      this.visitAllExpressions(ast.args, context),
      outputType: ast.type,
      checked: ast.checked,
    );
  }

  @override
  Expression visitInvokeMemberMethodExpr(
      InvokeMemberMethodExpr ast, C context) {
    return InvokeMemberMethodExpr(
      ast.methodName,
      this.visitAllExpressions(ast.args, context),
      outputType: ast.type,
    );
  }

  @override
  Expression visitInvokeFunctionExpr(InvokeFunctionExpr ast, C context) {
    return InvokeFunctionExpr(
      ast.fn.visitExpression(this, context),
      this.visitAllExpressions(ast.args, context),
      [],
      type: ast.type,
    );
  }

  @override
  Expression visitInstantiateExpr(InstantiateExpr ast, C context) {
    return InstantiateExpr(
      ast.classExpr.visitExpression(this, context),
      this.visitAllExpressions(ast.args, context),
      type: ast.type,
      typeArguments: ast.typeArguments,
    );
  }

  @override
  Expression visitLiteralExpr(LiteralExpr ast, C context) {
    return ast;
  }

  @override
  Expression visitExternalExpr(ExternalExpr ast, C context) {
    return ast;
  }

  @override
  Expression visitConditionalExpr(ConditionalExpr ast, C context) {
    return ConditionalExpr(
        ast.condition.visitExpression(this, context),
        ast.trueCase.visitExpression(this, context),
        ast.falseCase.visitExpression(this, context));
  }

  @override
  Expression visitIfNullExpr(IfNullExpr ast, C context) {
    return IfNullExpr(ast.condition.visitExpression(this, context),
        ast.nullCase.visitExpression(this, context));
  }

  @override
  Expression visitNotExpr(NotExpr ast, C context) {
    return NotExpr(ast.condition.visitExpression(this, context));
  }

  @override
  Expression visitCastExpr(CastExpr ast, C context) {
    return CastExpr(ast.value.visitExpression(this, context), null);
  }

  @override
  Expression visitFunctionExpr(FunctionExpr ast, C context) {
    // Don't descend into nested functions
    return ast;
  }

  @override
  Expression visitBinaryOperatorExpr(BinaryOperatorExpr ast, C context) {
    return BinaryOperatorExpr(
        ast.operator,
        ast.lhs.visitExpression(this, context),
        ast.rhs.visitExpression(this, context),
        ast.type);
  }

  @override
  Expression visitReadPropExpr(ReadPropExpr ast, C context) {
    return ReadPropExpr(ast.receiver.visitExpression(this, context), ast.name,
        outputType: ast.type);
  }

  @override
  Expression visitReadKeyExpr(ReadKeyExpr ast, C context) {
    return ReadKeyExpr(ast.receiver.visitExpression(this, context),
        ast.index.visitExpression(this, context), ast.type);
  }

  @override
  Expression visitLiteralVargsExpr(LiteralVargsExpr ast, C context) {
    return LiteralVargsExpr(this.visitAllExpressions(ast.entries, context));
  }

  @override
  Expression visitLiteralArrayExpr(LiteralArrayExpr ast, C context) {
    return LiteralArrayExpr(this.visitAllExpressions(ast.entries, context));
  }

  @override
  Expression visitLiteralMapExpr(LiteralMapExpr ast, C context) {
    return LiteralMapExpr(ast.entries
        .map((entry) => <Object>[
              entry[0],
              (entry[1] as Expression).visitExpression(this, context)
            ])
        .toList());
  }

  List<Expression> visitAllExpressions(List<Expression> exprs, C context) {
    return exprs.map((expr) => expr.visitExpression(this, context)).toList();
  }

  @override
  Statement visitDeclareVarStmt(DeclareVarStmt stmt, C context) {
    return stmt.withValue(stmt.value?.visitExpression(this, context));
  }

  @override
  Statement visitDeclareFunctionStmt(DeclareFunctionStmt stmt, C context) {
    // Don't descend into nested functions
    return stmt;
  }

  @override
  Statement visitExpressionStmt(ExpressionStatement stmt, C context) {
    return ExpressionStatement(stmt.expr.visitExpression(this, context));
  }

  @override
  Statement visitReturnStmt(ReturnStatement stmt, C context) {
    return ReturnStatement(stmt.value?.visitExpression(this, context));
  }

  @override
  Statement visitDeclareClassStmt(ClassStmt stmt, C context) {
    // Don't descend into nested functions
    return stmt;
  }

  @override
  Statement visitIfStmt(IfStmt stmt, C context) {
    return IfStmt(
        stmt.condition.visitExpression(this, context),
        this.visitAllStatements(stmt.trueCase, context),
        this.visitAllStatements(stmt.falseCase, context));
  }

  @override
  Statement visitTryCatchStmt(TryCatchStmt stmt, C context) {
    return TryCatchStmt(this.visitAllStatements(stmt.bodyStmts, context),
        this.visitAllStatements(stmt.catchStmts, context));
  }

  @override
  Statement visitThrowStmt(ThrowStmt stmt, C context) {
    return ThrowStmt(stmt.error.visitExpression(this, context));
  }

  @override
  Statement visitCommentStmt(CommentStmt stmt, C context) {
    return stmt;
  }

  List<Statement> visitAllStatements(List<Statement> stmts, C context) {
    return stmts.map((stmt) => stmt.visitStatement(this, context)).toList();
  }
}

class RecursiveExpressionVisitor<C>
    implements
        StatementVisitor<Statement, C>,
        ExpressionVisitor<Expression, C> {
  @override
  Expression visitNamedExpr(NamedExpr ast, C context) {
    ast.expr.visitExpression(this, context);
    return ast;
  }

  @override
  Expression visitReadVarExpr(ReadVarExpr ast, C context) {
    return ast;
  }

  @override
  Expression visitReadClassMemberExpr(ReadClassMemberExpr ast, C context) {
    return ast;
  }

  @override
  Expression visitWriteVarExpr(WriteVarExpr expr, C context,
      {bool checkForNull = false}) {
    expr.value.visitExpression(this, context);
    return expr;
  }

  @override
  Expression visitReadStaticMemberExpr(ReadStaticMemberExpr ast, C context) {
    return ast;
  }

  @override
  Expression visitWriteStaticMemberExpr(WriteStaticMemberExpr expr, C context) {
    expr.value.visitExpression(this, context);
    return expr;
  }

  @override
  Expression visitWriteKeyExpr(WriteKeyExpr expr, C context) {
    expr.receiver.visitExpression(this, context);
    expr.index.visitExpression(this, context);
    expr.value.visitExpression(this, context);
    return expr;
  }

  @override
  Expression visitWritePropExpr(WritePropExpr expr, C context) {
    expr.receiver.visitExpression(this, context);
    expr.value.visitExpression(this, context);
    return expr;
  }

  @override
  Expression visitWriteClassMemberExpr(WriteClassMemberExpr expr, C context) {
    THIS_EXPR.visitExpression(this, context);
    expr.value.visitExpression(this, context);
    return expr;
  }

  @override
  Expression visitInvokeMethodExpr(InvokeMethodExpr ast, C context) {
    ast.receiver.visitExpression(this, context);
    this.visitAllExpressions(ast.args, context);
    return ast;
  }

  @override
  Expression visitInvokeMemberMethodExpr(
      InvokeMemberMethodExpr ast, C context) {
    this.visitAllExpressions(ast.args, context);
    return ast;
  }

  @override
  Expression visitInvokeFunctionExpr(InvokeFunctionExpr ast, C context) {
    ast.fn.visitExpression(this, context);
    this.visitAllExpressions(ast.args, context);
    return ast;
  }

  @override
  Expression visitInstantiateExpr(InstantiateExpr ast, C context) {
    ast.classExpr.visitExpression(this, context);
    this.visitAllExpressions(ast.args, context);
    return ast;
  }

  @override
  Expression visitLiteralExpr(LiteralExpr ast, C context) {
    return ast;
  }

  @override
  Expression visitExternalExpr(ExternalExpr ast, C context) {
    return ast;
  }

  @override
  Expression visitConditionalExpr(ConditionalExpr ast, C context) {
    ast.condition.visitExpression(this, context);
    ast.trueCase.visitExpression(this, context);
    ast.falseCase.visitExpression(this, context);
    return ast;
  }

  @override
  Expression visitIfNullExpr(IfNullExpr ast, C context) {
    ast.condition.visitExpression(this, context);
    ast.nullCase.visitExpression(this, context);
    return ast;
  }

  @override
  Expression visitNotExpr(NotExpr ast, C context) {
    ast.condition.visitExpression(this, context);
    return ast;
  }

  @override
  Expression visitCastExpr(CastExpr ast, C context) {
    ast.value.visitExpression(this, context);
    return ast;
  }

  @override
  Expression visitFunctionExpr(FunctionExpr ast, C context) {
    return ast;
  }

  @override
  Expression visitBinaryOperatorExpr(BinaryOperatorExpr ast, C context) {
    ast.lhs.visitExpression(this, context);
    ast.rhs.visitExpression(this, context);
    return ast;
  }

  @override
  Expression visitReadPropExpr(ReadPropExpr ast, C context) {
    ast.receiver.visitExpression(this, context);
    return ast;
  }

  @override
  Expression visitReadKeyExpr(ReadKeyExpr ast, C context) {
    ast.receiver.visitExpression(this, context);
    ast.index.visitExpression(this, context);
    return ast;
  }

  @override
  Expression visitLiteralVargsExpr(LiteralVargsExpr ast, C context) {
    this.visitAllExpressions(ast.entries, context);
    return ast;
  }

  @override
  Expression visitLiteralArrayExpr(LiteralArrayExpr ast, C context) {
    this.visitAllExpressions(ast.entries, context);
    return ast;
  }

  @override
  Expression visitLiteralMapExpr(LiteralMapExpr ast, C context) {
    for (var entry in ast.entries) {
      (entry[1] as Expression).visitExpression(this, context);
    }
    return ast;
  }

  void visitAllExpressions(List<Expression> exprs, C context) {
    for (var expr in exprs) {
      expr.visitExpression(this, context);
    }
  }

  @override
  Statement visitDeclareVarStmt(DeclareVarStmt stmt, C context) {
    stmt.value?.visitExpression(this, context);
    return stmt;
  }

  @override
  Statement visitDeclareFunctionStmt(DeclareFunctionStmt stmt, C context) {
    // Don't descend into nested functions
    return stmt;
  }

  @override
  Statement visitExpressionStmt(ExpressionStatement stmt, C context) {
    stmt.expr.visitExpression(this, context);
    return stmt;
  }

  @override
  Statement visitReturnStmt(ReturnStatement stmt, C context) {
    stmt.value?.visitExpression(this, context);
    return stmt;
  }

  @override
  Statement visitDeclareClassStmt(ClassStmt stmt, C context) {
    // Don't descend into nested functions
    return stmt;
  }

  @override
  Statement visitIfStmt(IfStmt stmt, C context) {
    stmt.condition.visitExpression(this, context);
    this.visitAllStatements(stmt.trueCase, context);
    this.visitAllStatements(stmt.falseCase, context);
    return stmt;
  }

  @override
  Statement visitTryCatchStmt(TryCatchStmt stmt, C context) {
    this.visitAllStatements(stmt.bodyStmts, context);
    this.visitAllStatements(stmt.catchStmts, context);
    return stmt;
  }

  @override
  Statement visitThrowStmt(ThrowStmt stmt, C context) {
    stmt.error.visitExpression(this, context);
    return stmt;
  }

  @override
  Statement visitCommentStmt(CommentStmt stmt, C context) {
    return stmt;
  }

  void visitAllStatements(List<Statement> stmts, C context) {
    for (var stmt in stmts) {
      stmt.visitStatement(this, context);
    }
  }
}

Statement replaceVarInStatement(
    String varName, Expression newValue, Statement statement) {
  var transformer = _ReplaceVariableTransformer(varName, newValue);
  return statement.visitStatement(transformer, null);
}

class _ReplaceVariableTransformer extends ExpressionTransformer<Null> {
  final String _varName;
  final Expression _newValue;
  _ReplaceVariableTransformer(this._varName, this._newValue);

  @override
  Expression visitReadVarExpr(ReadVarExpr ast, _) =>
      ast.name == this._varName ? this._newValue : ast;

  @override
  Expression visitReadClassMemberExpr(ReadClassMemberExpr ast, _) =>
      ast.name == this._varName ? this._newValue : ast;
}

Set<String> findReadVarNames(List<Statement> stmts) {
  var finder = _VariableReadFinder();
  finder.visitAllStatements(stmts, null);
  return finder.varNames;
}

Set<String> findWriteVarNames(List<Statement> stmts) {
  var finder = _VariableWriteFinder();
  finder.visitAllStatements(stmts, null);
  return finder.varNames;
}

class _VariableReadFinder extends RecursiveExpressionVisitor<Null> {
  final varNames = Set<String>();

  @override
  Expression visitReadVarExpr(ReadVarExpr ast, _) {
    this.varNames.add(ast.name);
    return null;
  }
}

class _VariableWriteFinder extends RecursiveExpressionVisitor<Null> {
  final varNames = Set<String>();

  @override
  Expression visitWriteVarExpr(WriteVarExpr ast, _,
      {bool checkForNull = false}) {
    varNames.add(ast.name);
    return null;
  }
}

ReadVarExpr variable(String name, [OutputType type]) {
  return ReadVarExpr(name, type);
}

ExternalExpr importExpr(CompileIdentifierMetadata id,
    {List<OutputType> typeParams, bool isConst = false}) {
  return ExternalExpr(id, typeParams: typeParams);
}

ExternalExpr importDeferred(CompileIdentifierMetadata id,
    [List<OutputType> typeParams]) {
  return ExternalExpr(id, typeParams: typeParams, deferred: true);
}

ExternalType importType(CompileIdentifierMetadata id,
    [List<OutputType> typeParams, List<TypeModifier> typeModifiers]) {
  return id != null ? ExternalType(id, typeParams, typeModifiers) : null;
}

/// A literal string whose [value] has been manually escaped.
///
/// Use this when intentionally emitting special characters that would
/// normally be escaped
class EscapedString {
  final String value;

  EscapedString(this.value);
}

LiteralExpr escapedString(String value) {
  return literal(EscapedString(value), STRING_TYPE);
}

LiteralExpr literal(dynamic value, [OutputType type]) {
  return LiteralExpr(value, type);
}

LiteralArrayExpr literalArr(List<Expression> values, [OutputType type]) {
  return LiteralArrayExpr(values, type);
}

LiteralVargsExpr literalVargs(List<Expression> values) {
  return LiteralVargsExpr(values);
}

LiteralMapExpr literalMap(List<List<dynamic /* String | Expression */ >> values,
    [MapType type]) {
  return LiteralMapExpr(values, type);
}

NotExpr not(Expression expr) {
  return NotExpr(expr);
}

FunctionExpr fn(List<FnParam> params, List<Statement> body, [OutputType type]) {
  return FunctionExpr(params, body, type);
}
