import "package:angular2/src/core/reflection/reflection.dart" show reflector;
import "package:angular2/src/facade/async.dart" show ObservableWrapper;
import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart"
    show isPresent, IS_DART, FunctionWrapper;

import "dart_emitter.dart" show debugOutputAstAsDart;
import "output_ast.dart" as o;
import "ts_emitter.dart" show debugOutputAstAsTypeScript;

dynamic interpretStatements(List<o.Statement> statements, String resultVar,
    InstanceFactory instanceFactory) {
  List<o.Statement> stmtsWithReturn = (new List.from(statements)
    ..addAll([new o.ReturnStatement(o.variable(resultVar))]));
  var ctx = new _ExecutionContext(
      null,
      null,
      null,
      null,
      new Map<String, dynamic>(),
      new Map<String, dynamic>(),
      new Map<String, Function>(),
      new Map<String, Function>(),
      instanceFactory);
  var visitor = new StatementInterpreter();
  var result = visitor.visitAllStatements(stmtsWithReturn, ctx);
  return result?.value;
}

abstract class InstanceFactory {
  DynamicInstance createInstance(
      dynamic superClass,
      dynamic clazz,
      List<dynamic> constructorArgs,
      Map<String, dynamic> props,
      Map<String, Function> getters,
      Map<String, Function> methods);
}

abstract class DynamicInstance {
  Map<String, dynamic> get props;

  Map<String, Function> get getters;

  Map<String, dynamic> get methods;

  dynamic get clazz;
}

dynamic isDynamicInstance(dynamic instance) {
  if (IS_DART) {
    return instance is DynamicInstance;
  } else {
    return isPresent(instance) &&
        isPresent(instance.props) &&
        isPresent(instance.getters) &&
        isPresent(instance.methods);
  }
}

dynamic _executeFunctionStatements(
    List<String> varNames,
    List<dynamic> varValues,
    List<o.Statement> statements,
    _ExecutionContext ctx,
    StatementInterpreter visitor) {
  var childCtx = ctx.createChildWihtLocalVars();
  for (var i = 0; i < varNames.length; i++) {
    childCtx.vars[varNames[i]] = varValues[i];
  }
  var result = visitor.visitAllStatements(statements, childCtx);
  return isPresent(result) ? result.value : null;
}

class _ExecutionContext {
  _ExecutionContext parent;
  dynamic superClass;
  dynamic superInstance;
  String className;
  Map<String, dynamic> vars;
  Map<String, dynamic> props;
  Map<String, Function> getters;
  Map<String, Function> methods;
  InstanceFactory instanceFactory;
  _ExecutionContext(
      this.parent,
      this.superClass,
      this.superInstance,
      this.className,
      this.vars,
      this.props,
      this.getters,
      this.methods,
      this.instanceFactory) {}
  _ExecutionContext createChildWihtLocalVars() {
    return new _ExecutionContext(
        this,
        this.superClass,
        this.superInstance,
        this.className,
        new Map<String, dynamic>(),
        this.props,
        this.getters,
        this.methods,
        this.instanceFactory);
  }
}

class ReturnValue {
  final value;
  const ReturnValue(this.value);
}

class _DynamicClass {
  o.ClassStmt _classStmt;
  _ExecutionContext _ctx;
  StatementInterpreter _visitor;
  _DynamicClass(this._classStmt, this._ctx, this._visitor) {}
  DynamicInstance instantiate(List<dynamic> args) {
    var props = new Map<String, dynamic>();
    var getters = new Map<String, Function>();
    var methods = new Map<String, Function>();
    var superClass =
        this._classStmt.parent.visitExpression(this._visitor, this._ctx);
    var instanceCtx = new _ExecutionContext(
        this._ctx,
        superClass,
        null,
        this._classStmt.name,
        this._ctx.vars,
        props,
        getters,
        methods,
        this._ctx.instanceFactory);
    this._classStmt.fields.forEach((o.ClassField field) {
      props[field.name] = null;
    });
    this._classStmt.getters.forEach((o.ClassGetter getter) {
      getters[getter.name] = () => _executeFunctionStatements(
          [], [], getter.body, instanceCtx, this._visitor);
    });
    this._classStmt.methods.forEach((o.ClassMethod method) {
      var paramNames = method.params.map((param) => param.name).toList();
      methods[method.name] =
          _declareFn(paramNames, method.body, instanceCtx, this._visitor);
    });
    var ctorParamNames = this
        ._classStmt
        .constructorMethod
        .params
        .map((param) => param.name)
        .toList();
    _executeFunctionStatements(ctorParamNames, args,
        this._classStmt.constructorMethod.body, instanceCtx, this._visitor);
    return instanceCtx.superInstance;
  }

  String debugAst() {
    return this._visitor.debugAst(this._classStmt);
  }
}

class StatementInterpreter implements o.StatementVisitor, o.ExpressionVisitor {
  String debugAst(dynamic /* o . Expression | o . Statement | o . Type */ ast) {
    return IS_DART
        ? debugOutputAstAsDart(ast)
        : debugOutputAstAsTypeScript(ast);
  }

  dynamic visitDeclareVarStmt(o.DeclareVarStmt stmt, dynamic context) {
    _ExecutionContext ctx = context;
    ctx.vars[stmt.name] = stmt.value.visitExpression(this, ctx);
    return null;
  }

  dynamic visitWriteVarExpr(o.WriteVarExpr expr, dynamic context) {
    _ExecutionContext ctx = context;
    var value = expr.value.visitExpression(this, ctx);
    var currCtx = ctx;
    while (currCtx != null) {
      if (currCtx.vars.containsKey(expr.name)) {
        currCtx.vars[expr.name] = value;
        return value;
      }
      currCtx = currCtx.parent;
    }
    throw new BaseException('''Not declared variable ${ expr . name}''');
  }

  dynamic visitReadVarExpr(o.ReadVarExpr ast, dynamic context) {
    _ExecutionContext ctx = context;
    var varName = ast.name;
    if (isPresent(ast.builtin)) {
      switch (ast.builtin) {
        case o.BuiltinVar.Super:
        case o.BuiltinVar.This:
          return ctx.superInstance;
        case o.BuiltinVar.CatchError:
          varName = CATCH_ERROR_VAR;
          break;
        case o.BuiltinVar.CatchStack:
          varName = CATCH_STACK_VAR;
          break;
        case o.BuiltinVar.MetadataMap:
          return null;
        default:
          throw new BaseException(
              '''Unknown builtin variable ${ ast . builtin}''');
      }
    }
    var currCtx = ctx;
    while (currCtx != null) {
      if (currCtx.vars.containsKey(varName)) {
        return currCtx.vars[varName];
      }
      currCtx = currCtx.parent;
    }
    throw new BaseException('''Not declared variable ${ varName}''');
  }

  dynamic visitWriteKeyExpr(o.WriteKeyExpr expr, dynamic context) {
    _ExecutionContext ctx = context;
    var receiver = expr.receiver.visitExpression(this, ctx);
    var index = expr.index.visitExpression(this, ctx);
    var value = expr.value.visitExpression(this, ctx);
    receiver[index] = value;
    return value;
  }

  dynamic visitWritePropExpr(o.WritePropExpr expr, dynamic context) {
    _ExecutionContext ctx = context;
    var receiver = expr.receiver.visitExpression(this, ctx);
    var value = expr.value.visitExpression(this, ctx);
    if (isDynamicInstance(receiver)) {
      var di = (receiver as DynamicInstance);
      if (di.props.containsKey(expr.name)) {
        di.props[expr.name] = value;
      } else {
        reflector.setter(expr.name)(receiver, value);
      }
    } else {
      reflector.setter(expr.name)(receiver, value);
    }
    return value;
  }

  dynamic visitInvokeMethodExpr(o.InvokeMethodExpr expr, dynamic context) {
    _ExecutionContext ctx = context;
    var receiver = expr.receiver.visitExpression(this, ctx);
    var args = this.visitAllExpressions(expr.args, ctx);
    var result;
    if (isPresent(expr.builtin)) {
      switch (expr.builtin) {
        case o.BuiltinMethod.ConcatArray:
          result = ListWrapper.concat(receiver, args[0]);
          break;
        case o.BuiltinMethod.SubscribeObservable:
          result = ObservableWrapper.subscribe(receiver, args[0]);
          break;
        case o.BuiltinMethod.bind:
          if (IS_DART) {
            result = receiver;
          } else {
            result = receiver.bind(args[0]);
          }
          break;
        default:
          throw new BaseException(
              '''Unknown builtin method ${ expr . builtin}''');
      }
    } else if (isDynamicInstance(receiver)) {
      var di = (receiver as DynamicInstance);
      if (di.methods.containsKey(expr.name)) {
        result = FunctionWrapper.apply(di.methods[expr.name], args);
      } else {
        result = reflector.method(expr.name)(receiver, args);
      }
    } else {
      result = reflector.method(expr.name)(receiver, args);
    }
    return result;
  }

  dynamic visitInvokeFunctionExpr(o.InvokeFunctionExpr stmt, dynamic context) {
    _ExecutionContext ctx = context;
    var args = this.visitAllExpressions(stmt.args, ctx);
    var fnExpr = stmt.fn;
    if (fnExpr is o.ReadVarExpr &&
        identical(fnExpr.builtin, o.BuiltinVar.Super)) {
      ctx.superInstance = ctx.instanceFactory.createInstance(ctx.superClass,
          ctx.className, args, ctx.props, ctx.getters, ctx.methods);
      ctx.parent.superInstance = ctx.superInstance;
      return null;
    } else {
      var fn = stmt.fn.visitExpression(this, ctx);
      return FunctionWrapper.apply(fn, args);
    }
  }

  dynamic visitReturnStmt(o.ReturnStatement stmt, dynamic context) {
    _ExecutionContext ctx = context;
    return new ReturnValue(stmt.value.visitExpression(this, ctx));
  }

  dynamic visitDeclareClassStmt(o.ClassStmt stmt, dynamic context) {
    _ExecutionContext ctx = context;
    var clazz = new _DynamicClass(stmt, ctx, this);
    ctx.vars[stmt.name] = clazz;
    return null;
  }

  dynamic visitExpressionStmt(o.ExpressionStatement stmt, dynamic context) {
    _ExecutionContext ctx = context;
    return stmt.expr.visitExpression(this, ctx);
  }

  dynamic visitIfStmt(o.IfStmt stmt, dynamic context) {
    _ExecutionContext ctx = context;
    var condition = stmt.condition.visitExpression(this, ctx);
    if (condition) {
      return this.visitAllStatements(stmt.trueCase, ctx);
    } else if (isPresent(stmt.falseCase)) {
      return this.visitAllStatements(stmt.falseCase, ctx);
    }
    return null;
  }

  dynamic visitTryCatchStmt(o.TryCatchStmt stmt, dynamic context) {
    _ExecutionContext ctx = context;
    try {
      return this.visitAllStatements(stmt.bodyStmts, ctx);
    } catch (e, e_stack) {
      var childCtx = ctx.createChildWihtLocalVars();
      childCtx.vars[CATCH_ERROR_VAR] = e;
      childCtx.vars[CATCH_STACK_VAR] = e_stack;
      return this.visitAllStatements(stmt.catchStmts, childCtx);
    }
  }

  dynamic visitThrowStmt(o.ThrowStmt stmt, dynamic context) {
    _ExecutionContext ctx = context;
    throw stmt.error.visitExpression(this, ctx);
  }

  dynamic visitCommentStmt(o.CommentStmt stmt, [dynamic context]) {
    return null;
  }

  dynamic visitInstantiateExpr(o.InstantiateExpr ast, dynamic context) {
    _ExecutionContext ctx = context;
    var args = this.visitAllExpressions(ast.args, ctx);
    var clazz = ast.classExpr.visitExpression(this, ctx);
    if (clazz is _DynamicClass) {
      return clazz.instantiate(args);
    } else {
      return FunctionWrapper.apply(reflector.factory(clazz), args);
    }
  }

  dynamic visitLiteralExpr(o.LiteralExpr ast, dynamic context) {
    return ast.value;
  }

  dynamic visitExternalExpr(o.ExternalExpr ast, dynamic context) {
    return ast.value.runtimeCallback != null
        ? ast.value.runtimeCallback()
        : ast.value.runtime;
  }

  dynamic visitConditionalExpr(o.ConditionalExpr ast, dynamic context) {
    _ExecutionContext ctx = context;
    if (ast.condition.visitExpression(this, ctx)) {
      return ast.trueCase.visitExpression(this, ctx);
    } else if (isPresent(ast.falseCase)) {
      return ast.falseCase.visitExpression(this, ctx);
    }
    return null;
  }

  dynamic visitNotExpr(o.NotExpr ast, dynamic context) {
    _ExecutionContext ctx = context;
    return !ast.condition.visitExpression(this, ctx);
  }

  dynamic visitCastExpr(o.CastExpr ast, dynamic context) {
    _ExecutionContext ctx = context;
    return ast.value.visitExpression(this, ctx);
  }

  dynamic visitFunctionExpr(o.FunctionExpr ast, dynamic context) {
    _ExecutionContext ctx = context;
    var paramNames = ast.params.map((param) => param.name).toList();
    return _declareFn(paramNames, ast.statements, ctx, this);
  }

  dynamic visitDeclareFunctionStmt(
      o.DeclareFunctionStmt stmt, dynamic context) {
    _ExecutionContext ctx = context;
    var paramNames = stmt.params.map((param) => param.name).toList();
    ctx.vars[stmt.name] = _declareFn(paramNames, stmt.statements, ctx, this);
    return null;
  }

  dynamic visitBinaryOperatorExpr(o.BinaryOperatorExpr ast, dynamic context) {
    _ExecutionContext ctx = context;
    var lhs = () => ast.lhs.visitExpression(this, ctx);
    var rhs = () => ast.rhs.visitExpression(this, ctx);
    switch (ast.operator) {
      case o.BinaryOperator.Equals:
        return lhs() == rhs();
      case o.BinaryOperator.Identical:
        return identical(lhs(), rhs());
      case o.BinaryOperator.NotEquals:
        return lhs() != rhs();
      case o.BinaryOperator.NotIdentical:
        return !identical(lhs(), rhs());
      case o.BinaryOperator.And:
        return lhs() && rhs();
      case o.BinaryOperator.Or:
        return lhs() || rhs();
      case o.BinaryOperator.Plus:
        return lhs() + rhs();
      case o.BinaryOperator.Minus:
        return lhs() - rhs();
      case o.BinaryOperator.Divide:
        return lhs() / rhs();
      case o.BinaryOperator.Multiply:
        return lhs() * rhs();
      case o.BinaryOperator.Modulo:
        return lhs() % rhs();
      case o.BinaryOperator.Lower:
        return lhs() < rhs();
      case o.BinaryOperator.LowerEquals:
        return lhs() <= rhs();
      case o.BinaryOperator.Bigger:
        return lhs() > rhs();
      case o.BinaryOperator.BiggerEquals:
        return lhs() >= rhs();
      default:
        throw new BaseException('''Unknown operator ${ ast . operator}''');
    }
  }

  dynamic visitReadPropExpr(o.ReadPropExpr ast, dynamic context) {
    _ExecutionContext ctx = context;
    var result;
    var receiver = ast.receiver.visitExpression(this, ctx);
    if (isDynamicInstance(receiver)) {
      var di = (receiver as DynamicInstance);
      if (di.props.containsKey(ast.name)) {
        result = di.props[ast.name];
      } else if (di.getters.containsKey(ast.name)) {
        result = di.getters[ast.name]();
      } else if (di.methods.containsKey(ast.name)) {
        result = di.methods[ast.name];
      } else {
        result = reflector.getter(ast.name)(receiver);
      }
    } else {
      result = reflector.getter(ast.name)(receiver);
    }
    return result;
  }

  dynamic visitReadKeyExpr(o.ReadKeyExpr ast, dynamic context) {
    _ExecutionContext ctx = context;
    var receiver = ast.receiver.visitExpression(this, ctx);
    var prop = ast.index.visitExpression(this, ctx);
    return receiver[prop];
  }

  dynamic visitLiteralArrayExpr(o.LiteralArrayExpr ast, dynamic context) {
    _ExecutionContext ctx = context;
    return this.visitAllExpressions(ast.entries, ctx);
  }

  dynamic visitLiteralMapExpr(o.LiteralMapExpr ast, dynamic context) {
    _ExecutionContext ctx = context;
    var result = {};
    ast.entries.forEach((entry) => result[(entry[0] as String)] =
        ((entry[1] as o.Expression)).visitExpression(this, ctx));
    return result;
  }

  dynamic visitAllExpressions(List<o.Expression> expressions, dynamic context) {
    _ExecutionContext ctx = context;
    return expressions.map((expr) => expr.visitExpression(this, ctx)).toList();
  }

  ReturnValue visitAllStatements(
      List<o.Statement> statements, dynamic context) {
    _ExecutionContext ctx = context;
    for (var i = 0; i < statements.length; i++) {
      var stmt = statements[i];
      var val = stmt.visitStatement(this, ctx);
      if (val is ReturnValue) {
        return val;
      }
    }
    return null;
  }
}

Function _declareFn(List<String> varNames, List<o.Statement> statements,
    _ExecutionContext ctx, StatementInterpreter visitor) {
  switch (varNames.length) {
    case 0:
      return () =>
          _executeFunctionStatements(varNames, [], statements, ctx, visitor);
    case 1:
      return (d0) =>
          _executeFunctionStatements(varNames, [d0], statements, ctx, visitor);
    case 2:
      return (d0, d1) => _executeFunctionStatements(
          varNames, [d0, d1], statements, ctx, visitor);
    case 3:
      return (d0, d1, d2) => _executeFunctionStatements(
          varNames, [d0, d1, d2], statements, ctx, visitor);
    case 4:
      return (d0, d1, d2, d3) => _executeFunctionStatements(
          varNames, [d0, d1, d2, d3], statements, ctx, visitor);
    case 5:
      return (d0, d1, d2, d3, d4) => _executeFunctionStatements(
          varNames, [d0, d1, d2, d3, d4], statements, ctx, visitor);
    case 6:
      return (d0, d1, d2, d3, d4, d5) => _executeFunctionStatements(
          varNames, [d0, d1, d2, d3, d4, d5], statements, ctx, visitor);
    case 7:
      return (d0, d1, d2, d3, d4, d5, d6) => _executeFunctionStatements(
          varNames, [d0, d1, d2, d3, d4, d5, d6], statements, ctx, visitor);
    case 8:
      return (d0, d1, d2, d3, d4, d5, d6, d7) => _executeFunctionStatements(
          varNames, [d0, d1, d2, d3, d4, d5, d6, d7], statements, ctx, visitor);
    case 9:
      return (d0, d1, d2, d3, d4, d5, d6, d7, d8) => _executeFunctionStatements(
          varNames,
          [d0, d1, d2, d3, d4, d5, d6, d7, d8],
          statements,
          ctx,
          visitor);
    case 10:
      return (d0, d1, d2, d3, d4, d5, d6, d7, d8, d9) =>
          _executeFunctionStatements(
              varNames,
              [d0, d1, d2, d3, d4, d5, d6, d7, d8, d9],
              statements,
              ctx,
              visitor);
    default:
      throw new BaseException(
          "Declaring functions with more than 10 arguments is not supported right now");
  }
}

var CATCH_ERROR_VAR = "error";
var CATCH_STACK_VAR = "stack";
