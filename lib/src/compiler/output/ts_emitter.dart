import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show isPresent, isArray;

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
String debugOutputAstAsTypeScript(
    dynamic /* o . Statement | o . Expression | o . Type | List < dynamic > */ ast) {
  var converter = new _TsEmitterVisitor(_debugModuleUrl);
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

class TypeScriptEmitter implements OutputEmitter {
  TypeScriptEmitter() {}
  String emitStatements(
      String moduleUrl, List<o.Statement> stmts, List<String> exportedVars) {
    var converter = new _TsEmitterVisitor(moduleUrl);
    var ctx = EmitterVisitorContext.createRoot(exportedVars);
    converter.visitAllStatements(stmts, ctx);
    var srcParts = [];
    converter.importsWithPrefixes.forEach((importedModuleUrl, prefix) {
      // Note: can't write the real word for import as it screws up system.js auto detection...
      srcParts.add('''imp''' +
          '''ort * as ${ prefix} from \'${ getImportModulePath ( moduleUrl , importedModuleUrl , ImportEnv . JS )}\';''');
    });
    srcParts.add(ctx.toSource());
    return srcParts.join("\n");
  }
}

class _TsEmitterVisitor extends AbstractEmitterVisitor
    implements o.TypeVisitor {
  String _moduleUrl;
  _TsEmitterVisitor(this._moduleUrl) : super(false) {
    /* super call moved to initializer */;
  }
  var importsWithPrefixes = new Map<String, String>();
  dynamic visitExternalExpr(o.ExternalExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    this._visitIdentifier(ast.value, ast.typeParams, ctx);
    return null;
  }

  dynamic visitDeclareVarStmt(o.DeclareVarStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (ctx.isExportedVar(stmt.name)) {
      ctx.print('''export ''');
    }
    if (stmt.hasModifier(o.StmtModifier.Final)) {
      ctx.print('''const''');
    } else {
      ctx.print('''var''');
    }
    ctx.print(''' ${ stmt . name}''');
    if (isPresent(stmt.type)) {
      ctx.print(''':''');
      stmt.type.visitType(this, ctx);
    }
    ctx.print(''' = ''');
    stmt.value.visitExpression(this, ctx);
    ctx.println(''';''');
    return null;
  }

  dynamic visitCastExpr(o.CastExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''(<''');
    ast.type.visitType(this, ctx);
    ctx.print('''>''');
    ast.value.visitExpression(this, ctx);
    ctx.print(''')''');
    return null;
  }

  dynamic visitDeclareClassStmt(o.ClassStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.pushClass(stmt);
    if (ctx.isExportedVar(stmt.name)) {
      ctx.print('''export ''');
    }
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
    if (field.hasModifier(o.StmtModifier.Private)) {
      ctx.print('''private ''');
    }
    ctx.print(field.name);
    if (isPresent(field.type)) {
      ctx.print(''':''');
      field.type.visitType(this, ctx);
    }
    ctx.println(''';''');
  }

  _visitClassGetter(o.ClassGetter getter, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (getter.hasModifier(o.StmtModifier.Private)) {
      ctx.print('''private ''');
    }
    ctx.print('''get ${ getter . name}()''');
    if (isPresent(getter.type)) {
      ctx.print(''':''');
      getter.type.visitType(this, ctx);
    }
    ctx.println(''' {''');
    ctx.incIndent();
    this.visitAllStatements(getter.body, ctx);
    ctx.decIndent();
    ctx.println('''}''');
  }

  _visitClassConstructor(o.ClassStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''constructor(''');
    this._visitParams(stmt.constructorMethod.params, ctx);
    ctx.println(''') {''');
    ctx.incIndent();
    this.visitAllStatements(stmt.constructorMethod.body, ctx);
    ctx.decIndent();
    ctx.println('''}''');
  }

  _visitClassMethod(o.ClassMethod method, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (method.hasModifier(o.StmtModifier.Private)) {
      ctx.print('''private ''');
    }
    ctx.print('''${ method . name}(''');
    this._visitParams(method.params, ctx);
    ctx.print('''):''');
    if (isPresent(method.type)) {
      method.type.visitType(this, ctx);
    } else {
      ctx.print('''void''');
    }
    ctx.println(''' {''');
    ctx.incIndent();
    this.visitAllStatements(method.body, ctx);
    ctx.decIndent();
    ctx.println('''}''');
  }

  dynamic visitFunctionExpr(o.FunctionExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''(''');
    this._visitParams(ast.params, ctx);
    ctx.print('''):''');
    if (isPresent(ast.type)) {
      ast.type.visitType(this, ctx);
    } else {
      ctx.print('''void''');
    }
    ctx.println(''' => {''');
    ctx.incIndent();
    this.visitAllStatements(ast.statements, ctx);
    ctx.decIndent();
    ctx.print('''}''');
    return null;
  }

  dynamic visitDeclareFunctionStmt(
      o.DeclareFunctionStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (ctx.isExportedVar(stmt.name)) {
      ctx.print('''export ''');
    }
    ctx.print('''function ${ stmt . name}(''');
    this._visitParams(stmt.params, ctx);
    ctx.print('''):''');
    if (isPresent(stmt.type)) {
      stmt.type.visitType(this, ctx);
    } else {
      ctx.print('''void''');
    }
    ctx.println(''' {''');
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
    List<o.Statement> catchStmts = (new List<o.Statement>.from([
      (CATCH_STACK_VAR
          .set(CATCH_ERROR_VAR.prop("stack"))
          .toDeclStmt(null, [o.StmtModifier.Final]))
    ])..addAll(stmt.catchStmts));
    this.visitAllStatements(catchStmts, ctx);
    ctx.decIndent();
    ctx.println('''}''');
    return null;
  }

  dynamic visitBuiltintType(o.BuiltinType type, dynamic context) {
    EmitterVisitorContext ctx = context;
    var typeStr;
    switch (type.name) {
      case o.BuiltinTypeName.Bool:
        typeStr = "boolean";
        break;
      case o.BuiltinTypeName.Dynamic:
        typeStr = "any";
        break;
      case o.BuiltinTypeName.Function:
        typeStr = "Function";
        break;
      case o.BuiltinTypeName.Number:
        typeStr = "number";
        break;
      case o.BuiltinTypeName.Int:
        typeStr = "number";
        break;
      case o.BuiltinTypeName.String:
        typeStr = "string";
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
    if (isPresent(type.of)) {
      type.of.visitType(this, ctx);
    } else {
      ctx.print('''any''');
    }
    ctx.print('''[]''');
    return null;
  }

  dynamic visitMapType(o.MapType type, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('''{[key: string]:''');
    if (isPresent(type.valueType)) {
      type.valueType.visitType(this, ctx);
    } else {
      ctx.print('''any''');
    }
    ctx.print('''}''');
    return null;
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

  void _visitParams(List<o.FnParam> params, EmitterVisitorContext ctx) {
    this.visitAllObjects((param) {
      ctx.print(param.name);
      if (isPresent(param.type)) {
        ctx.print(''':''');
        param.type.visitType(this, ctx);
      }
    }, params, ctx, ",");
  }

  void _visitIdentifier(CompileIdentifierMetadata value,
      List<o.OutputType> typeParams, EmitterVisitorContext ctx) {
    if (isPresent(value.moduleUrl) && value.moduleUrl != this._moduleUrl) {
      var prefix = this.importsWithPrefixes[value.moduleUrl];
      if (prefix == null) {
        prefix = '''import${ this . importsWithPrefixes . length}''';
        importsWithPrefixes[value.moduleUrl] = prefix;
      }
      ctx.print('''${ prefix}.''');
    }
    ctx.print(value.name);
    if (isPresent(typeParams) && typeParams.length > 0) {
      ctx.print('''<''');
      visitAllObjects(
          (type) => type.visitType(this, ctx), typeParams, ctx, ",");
      ctx.print('''>''');
    }
  }
}
