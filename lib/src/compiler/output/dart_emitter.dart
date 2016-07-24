import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show isPresent, isBlank, isArray;

import "../compile_metadata.dart" show CompileIdentifierMetadata;
import "abstract_emitter.dart"
    show
        OutputEmitter,
        EmitterVisitorContext,
        AbstractEmitterVisitor,
        CATCH_ERROR_VAR,
        CATCH_STACK_VAR;
import "output_ast.dart" as o;
import "path_util.dart" show getImportModulePath, ImportEnv;

var _debugModuleUrl = "asset://debug/lib";
var _METADATA_MAP_VAR = '''_METADATA''';
String debugOutputAstAsDart(
    dynamic /* o . Statement | o . Expression | o . Type | List < dynamic > */ ast) {
  var converter = new _DartEmitterVisitor(_debugModuleUrl);
  var ctx = EmitterVisitorContext.createRoot([]);
  List<dynamic> asts;
  if (isArray(ast)) {
    asts = (ast as List<dynamic>);
  } else {
    asts = [ast];
  }
  asts.forEach((ast) {
    if (ast is o.Statement) {
      ast.visitStatement(converter, ctx);
    } else if (ast is o.Expression) {
      ast.visitExpression(converter, ctx);
    } else if (ast is o.OutputType) {
      ast.visitType(converter, ctx);
    } else {
      throw new BaseException(
          '''Don\'t know how to print debug info for ${ ast}''');
    }
  });
  return ctx.toSource();
}

class DartEmitter implements OutputEmitter {
  DartEmitter() {}
  String emitStatements(
      String moduleUrl, List<o.Statement> stmts, List<String> exportedVars) {
    var srcParts = [];
    // Note: We are not creating a library here as Dart does not need it.

    // Dart analzyer might complain about it though.
    var converter = new _DartEmitterVisitor(moduleUrl);
    var ctx = EmitterVisitorContext.createRoot(exportedVars);
    converter.visitAllStatements(stmts, ctx);
    converter.importsWithPrefixes.forEach((importedModuleUrl, prefix) {
      srcParts.add(
          '''import \'${ getImportModulePath ( moduleUrl , importedModuleUrl , ImportEnv . Dart )}\' as ${ prefix};''');
    });
    srcParts.add(ctx.toSource());
    return srcParts.join("\n");
  }
}

class _DartEmitterVisitor extends AbstractEmitterVisitor
    implements o.TypeVisitor {
  String _moduleUrl;
  var importsWithPrefixes = new Map<String, String>();
  _DartEmitterVisitor(this._moduleUrl) : super(true) {
    /* super call moved to initializer */;
  }
  dynamic visitExternalExpr(o.ExternalExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    this._visitIdentifier(ast.value, ast.typeParams, ctx);
    return null;
  }

  dynamic visitDeclareVarStmt(o.DeclareVarStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (stmt.hasModifier(o.StmtModifier.Final)) {
      if (isConstType(stmt.type)) {
        ctx.print('''const ''');
      } else {
        ctx.print('''final ''');
      }
    } else if (isBlank(stmt.type)) {
      ctx.print('''var ''');
    }
    if (isPresent(stmt.type)) {
      stmt.type.visitType(this, ctx);
      ctx.print(''' ''');
    }
    ctx.print('''${ stmt . name} = ''');
    stmt.value.visitExpression(this, ctx);
    ctx.println(''';''');
    return null;
  }

  dynamic visitCastExpr(o.CastExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''(''');
    ast.value.visitExpression(this, ctx);
    ctx.print(''' as ''');
    ast.type.visitType(this, ctx);
    ctx.print(''')''');
    return null;
  }

  dynamic visitDeclareClassStmt(o.ClassStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.pushClass(stmt);
    ctx.print('''class ${ stmt . name}''');
    if (isPresent(stmt.parent)) {
      ctx.print(''' extends ''');
      stmt.parent.visitExpression(this, ctx);
    }
    ctx.println(''' {''');
    ctx.incIndent();
    stmt.fields.forEach((field) => this._visitClassField(field, ctx));
    if (isPresent(stmt.constructorMethod)) {
      this._visitClassConstructor(stmt, ctx);
    }
    stmt.getters.forEach((getter) => this._visitClassGetter(getter, ctx));
    stmt.methods.forEach((method) => this._visitClassMethod(method, ctx));
    ctx.decIndent();
    ctx.println('''}''');
    ctx.popClass();
    return null;
  }

  _visitClassField(o.ClassField field, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (field.hasModifier(o.StmtModifier.Final)) {
      ctx.print('''final ''');
    } else if (isBlank(field.type)) {
      ctx.print('''var ''');
    }
    if (isPresent(field.type)) {
      field.type.visitType(this, ctx);
      ctx.print(''' ''');
    }
    ctx.println('''${ field . name};''');
  }

  _visitClassGetter(o.ClassGetter getter, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (isPresent(getter.type)) {
      getter.type.visitType(this, ctx);
      ctx.print(''' ''');
    }
    ctx.println('''get ${ getter . name} {''');
    ctx.incIndent();
    this.visitAllStatements(getter.body, ctx);
    ctx.decIndent();
    ctx.println('''}''');
  }

  _visitClassConstructor(o.ClassStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''${ stmt . name}(''');
    this._visitParams(stmt.constructorMethod.params, ctx);
    ctx.print(''')''');
    var ctorStmts = stmt.constructorMethod.body;
    var superCtorExpr =
        ctorStmts.length > 0 ? getSuperConstructorCallExpr(ctorStmts[0]) : null;
    if (isPresent(superCtorExpr)) {
      ctx.print(''': ''');
      superCtorExpr.visitExpression(this, ctx);
      ctorStmts = ListWrapper.slice(ctorStmts, 1);
    }
    ctx.println(''' {''');
    ctx.incIndent();
    this.visitAllStatements(ctorStmts, ctx);
    ctx.decIndent();
    ctx.println('''}''');
  }

  _visitClassMethod(o.ClassMethod method, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (isPresent(method.type)) {
      method.type.visitType(this, ctx);
    } else {
      ctx.print('''void''');
    }
    ctx.print(''' ${ method . name}(''');
    this._visitParams(method.params, ctx);
    ctx.println(''') {''');
    ctx.incIndent();
    this.visitAllStatements(method.body, ctx);
    ctx.decIndent();
    ctx.println('''}''');
  }

  dynamic visitFunctionExpr(o.FunctionExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''(''');
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
    if (isPresent(stmt.type)) {
      stmt.type.visitType(this, ctx);
    } else {
      ctx.print('''void''');
    }
    ctx.print(''' ${ stmt . name}(''');
    this._visitParams(stmt.params, ctx);
    ctx.println(''') {''');
    ctx.incIndent();
    this.visitAllStatements(stmt.statements, ctx);
    ctx.decIndent();
    ctx.println('''}''');
    return null;
  }

  String getBuiltinMethodName(o.BuiltinMethod method) {
    var name;
    switch (method) {
      case o.BuiltinMethod.ConcatArray:
        name = ".addAll";
        break;
      case o.BuiltinMethod.SubscribeObservable:
        name = "listen";
        break;
      case o.BuiltinMethod.bind:
        name = null;
        break;
      default:
        throw new BaseException('''Unknown builtin method: ${ method}''');
    }
    return name;
  }

  dynamic visitReadVarExpr(o.ReadVarExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (identical(ast.builtin, o.BuiltinVar.MetadataMap)) {
      ctx.print(_METADATA_MAP_VAR);
    } else {
      super.visitReadVarExpr(ast, ctx);
    }
    return null;
  }

  dynamic visitTryCatchStmt(o.TryCatchStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.println('''try {''');
    ctx.incIndent();
    this.visitAllStatements(stmt.bodyStmts, ctx);
    ctx.decIndent();
    ctx.println(
        '''} catch (${ CATCH_ERROR_VAR . name}, ${ CATCH_STACK_VAR . name}) {''');
    ctx.incIndent();
    this.visitAllStatements(stmt.catchStmts, ctx);
    ctx.decIndent();
    ctx.println('''}''');
    return null;
  }

  dynamic visitBinaryOperatorExpr(o.BinaryOperatorExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    switch (ast.operator) {
      case o.BinaryOperator.Identical:
        ctx.print('''identical(''');
        ast.lhs.visitExpression(this, ctx);
        ctx.print(''', ''');
        ast.rhs.visitExpression(this, ctx);
        ctx.print(''')''');
        break;
      case o.BinaryOperator.NotIdentical:
        ctx.print('''!identical(''');
        ast.lhs.visitExpression(this, ctx);
        ctx.print(''', ''');
        ast.rhs.visitExpression(this, ctx);
        ctx.print(''')''');
        break;
      default:
        super.visitBinaryOperatorExpr(ast, ctx);
    }
    return null;
  }

  dynamic visitLiteralArrayExpr(o.LiteralArrayExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (isConstType(ast.type)) {
      ctx.print('''const ''');
    }
    return super.visitLiteralArrayExpr(ast, ctx);
  }

  dynamic visitLiteralMapExpr(o.LiteralMapExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (isConstType(ast.type)) {
      ctx.print('''const ''');
    }
    if (isPresent(ast.valueType)) {
      ctx.print('''<String, ''');
      ast.valueType.visitType(this, ctx);
      ctx.print('''>''');
    }
    return super.visitLiteralMapExpr(ast, ctx);
  }

  dynamic visitInstantiateExpr(o.InstantiateExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print(isConstType(ast.type) ? '''const''' : '''new''');
    ctx.print(" ");
    ast.classExpr.visitExpression(this, ctx);
    ctx.print('''(''');
    this.visitAllExpressions(ast.args, ctx, ''',''');
    ctx.print(''')''');
    return null;
  }

  dynamic visitBuiltintType(o.BuiltinType type, dynamic context) {
    EmitterVisitorContext ctx = context;
    var typeStr;
    switch (type.name) {
      case o.BuiltinTypeName.Bool:
        typeStr = "bool";
        break;
      case o.BuiltinTypeName.Dynamic:
        typeStr = "dynamic";
        break;
      case o.BuiltinTypeName.Function:
        typeStr = "Function";
        break;
      case o.BuiltinTypeName.Number:
        typeStr = "num";
        break;
      case o.BuiltinTypeName.Int:
        typeStr = "int";
        break;
      case o.BuiltinTypeName.String:
        typeStr = "String";
        break;
      default:
        throw new BaseException('''Unsupported builtin type ${ type . name}''');
    }
    ctx.print(typeStr);
    return null;
  }

  dynamic visitExternalType(o.ExternalType ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    this._visitIdentifier(ast.value, ast.typeParams, ctx);
    return null;
  }

  dynamic visitArrayType(o.ArrayType type, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''List<''');
    if (isPresent(type.of)) {
      type.of.visitType(this, ctx);
    } else {
      ctx.print('''dynamic''');
    }
    ctx.print('''>''');
    return null;
  }

  dynamic visitMapType(o.MapType type, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''Map<String, ''');
    if (isPresent(type.valueType)) {
      type.valueType.visitType(this, ctx);
    } else {
      ctx.print('''dynamic''');
    }
    ctx.print('''>''');
    return null;
  }

  void _visitParams(List<o.FnParam> params, dynamic context) {
    EmitterVisitorContext ctx = context;
    this.visitAllObjects((param) {
      if (isPresent(param.type)) {
        param.type.visitType(this, ctx);
        ctx.print(" ");
      }
      ctx.print(param.name);
    }, params, ctx, ",");
  }

  void _visitIdentifier(CompileIdentifierMetadata value,
      List<o.OutputType> typeParams, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (isPresent(value.moduleUrl) && value.moduleUrl != this._moduleUrl) {
      var prefix = this.importsWithPrefixes[value.moduleUrl];
      if (isBlank(prefix)) {
        prefix = '''import${ this . importsWithPrefixes . length}''';
        this.importsWithPrefixes[value.moduleUrl] = prefix;
      }
      ctx.print('''${ prefix}.''');
    }
    ctx.print(value.name);
    if (isPresent(typeParams) && typeParams.length > 0) {
      ctx.print('''<''');
      this.visitAllObjects(
          (type) => type.visitType(this, ctx), typeParams, ctx, ",");
      ctx.print('''>''');
    }
  }
}

o.Expression getSuperConstructorCallExpr(o.Statement stmt) {
  if (stmt is o.ExpressionStatement) {
    var expr = stmt.expr;
    if (expr is o.InvokeFunctionExpr) {
      var fn = expr.fn;
      if (fn is o.ReadVarExpr) {
        if (identical(fn.builtin, o.BuiltinVar.Super)) {
          return expr;
        }
      }
    }
  }
  return null;
}

bool isConstType(o.OutputType type) {
  return isPresent(type) && type.hasModifier(o.TypeModifier.Const);
}
