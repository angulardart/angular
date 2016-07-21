import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show isPresent;

import "abstract_emitter.dart"
    show
        EmitterVisitorContext,
        AbstractEmitterVisitor,
        CATCH_ERROR_VAR,
        CATCH_STACK_VAR;
import "output_ast.dart" as o;

abstract class AbstractJsEmitterVisitor extends AbstractEmitterVisitor {
  AbstractJsEmitterVisitor() : super(false) {
    /* super call moved to initializer */;
  }
  dynamic visitDeclareClassStmt(o.ClassStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.pushClass(stmt);
    this._visitClassConstructor(stmt, ctx);
    if (isPresent(stmt.parent)) {
      ctx.print('''${ stmt . name}.prototype = Object.create(''');
      stmt.parent.visitExpression(this, ctx);
      ctx.println('''.prototype);''');
    }
    stmt.getters.forEach((getter) => this._visitClassGetter(stmt, getter, ctx));
    stmt.methods.forEach((method) => this._visitClassMethod(stmt, method, ctx));
    ctx.popClass();
    return null;
  }

  _visitClassConstructor(o.ClassStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''function ${ stmt . name}(''');
    if (isPresent(stmt.constructorMethod)) {
      this._visitParams(stmt.constructorMethod.params, ctx);
    }
    ctx.println(''') {''');
    ctx.incIndent();
    if (isPresent(stmt.constructorMethod)) {
      if (stmt.constructorMethod.body.length > 0) {
        ctx.println('''var self = this;''');
        this.visitAllStatements(stmt.constructorMethod.body, ctx);
      }
    }
    ctx.decIndent();
    ctx.println('''}''');
  }

  _visitClassGetter(o.ClassStmt stmt, o.ClassGetter getter, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.println(
        '''Object.defineProperty(${ stmt . name}.prototype, \'${ getter . name}\', { get: function() {''');
    ctx.incIndent();
    if (getter.body.length > 0) {
      ctx.println('''var self = this;''');
      this.visitAllStatements(getter.body, ctx);
    }
    ctx.decIndent();
    ctx.println('''}});''');
  }

  _visitClassMethod(o.ClassStmt stmt, o.ClassMethod method, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''${ stmt . name}.prototype.${ method . name} = function(''');
    this._visitParams(method.params, ctx);
    ctx.println(''') {''');
    ctx.incIndent();
    if (method.body.length > 0) {
      ctx.println('''var self = this;''');
      this.visitAllStatements(method.body, ctx);
    }
    ctx.decIndent();
    ctx.println('''};''');
  }

  String visitReadVarExpr(o.ReadVarExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (identical(ast.builtin, o.BuiltinVar.This)) {
      ctx.print("self");
    } else if (identical(ast.builtin, o.BuiltinVar.Super)) {
      throw new BaseException(
          '''\'super\' needs to be handled at a parent ast node, not at the variable level!''');
    } else {
      super.visitReadVarExpr(ast, ctx);
    }
    return null;
  }

  dynamic visitDeclareVarStmt(o.DeclareVarStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''var ${ stmt . name} = ''');
    stmt.value.visitExpression(this, ctx);
    ctx.println(''';''');
    return null;
  }

  dynamic visitCastExpr(o.CastExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ast.value.visitExpression(this, ctx);
    return null;
  }

  String visitInvokeFunctionExpr(o.InvokeFunctionExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    var fnExpr = expr.fn;
    if (fnExpr is o.ReadVarExpr &&
        identical(fnExpr.builtin, o.BuiltinVar.Super)) {
      ctx.currentClass.parent.visitExpression(this, ctx);
      ctx.print('''.call(this''');
      if (expr.args.length > 0) {
        ctx.print(''', ''');
        this.visitAllExpressions(expr.args, ctx, ",");
      }
      ctx.print(''')''');
    } else {
      super.visitInvokeFunctionExpr(expr, ctx);
    }
    return null;
  }

  dynamic visitFunctionExpr(o.FunctionExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''function(''');
    this._visitParams(ast.params, ctx);
    ctx.println(''') {''');
    ctx.incIndent();
    this.visitAllStatements(ast.statements, ctx);
    ctx.decIndent();
    ctx.print('''}''');
    return null;
  }

  dynamic visitDeclareFunctionStmt(
      o.DeclareFunctionStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''function ${ stmt . name}(''');
    this._visitParams(stmt.params, ctx);
    ctx.println(''') {''');
    ctx.incIndent();
    this.visitAllStatements(stmt.statements, ctx);
    ctx.decIndent();
    ctx.println('''}''');
    return null;
  }

  dynamic visitTryCatchStmt(o.TryCatchStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.println('''try {''');
    ctx.incIndent();
    this.visitAllStatements(stmt.bodyStmts, ctx);
    ctx.decIndent();
    ctx.println('''} catch (${ CATCH_ERROR_VAR . name}) {''');
    ctx.incIndent();
    List<o.Statement> catchStmts = (new List.from([
      (CATCH_STACK_VAR
          .set(CATCH_ERROR_VAR.prop("stack"))
          .toDeclStmt(null, [o.StmtModifier.Final]))
    ])..addAll(stmt.catchStmts));
    this.visitAllStatements(catchStmts, ctx);
    ctx.decIndent();
    ctx.println('''}''');
    return null;
  }

  void _visitParams(List<o.FnParam> params, dynamic context) {
    EmitterVisitorContext ctx = context;
    this.visitAllObjects((param) => ctx.print(param.name), params, ctx, ",");
  }

  String getBuiltinMethodName(o.BuiltinMethod method) {
    var name;
    switch (method) {
      case o.BuiltinMethod.ConcatArray:
        name = "concat";
        break;
      case o.BuiltinMethod.SubscribeObservable:
        name = "subscribe";
        break;
      case o.BuiltinMethod.bind:
        name = "bind";
        break;
      default:
        throw new BaseException('''Unknown builtin method: ${ method}''');
    }
    return name;
  }
}
