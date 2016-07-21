import "package:angular2/src/facade/lang.dart" show isPresent, isBlank;

import "abstract_emitter.dart" show OutputEmitter, EmitterVisitorContext;
import "abstract_js_emitter.dart" show AbstractJsEmitterVisitor;
import "output_ast.dart" as o;
import "path_util.dart" show getImportModulePath, ImportEnv;

class JavaScriptEmitter implements OutputEmitter {
  JavaScriptEmitter() {}
  String emitStatements(
      String moduleUrl, List<o.Statement> stmts, List<String> exportedVars) {
    var converter = new JsEmitterVisitor(moduleUrl);
    var ctx = EmitterVisitorContext.createRoot(exportedVars);
    converter.visitAllStatements(stmts, ctx);
    var srcParts = [];
    converter.importsWithPrefixes.forEach((importedModuleUrl, prefix) {
      // Note: can't write the real word for import as it screws up system.js auto detection...
      srcParts.add('''var ${ prefix} = req''' +
          '''uire(\'${ getImportModulePath ( moduleUrl , importedModuleUrl , ImportEnv . JS )}\');''');
    });
    srcParts.add(ctx.toSource());
    return srcParts.join("\n");
  }
}

class JsEmitterVisitor extends AbstractJsEmitterVisitor {
  String _moduleUrl;
  var importsWithPrefixes = new Map<String, String>();
  JsEmitterVisitor(this._moduleUrl) : super() {
    /* super call moved to initializer */;
  }
  dynamic visitExternalExpr(o.ExternalExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (isPresent(ast.value.moduleUrl) &&
        ast.value.moduleUrl != this._moduleUrl) {
      var prefix = this.importsWithPrefixes[ast.value.moduleUrl];
      if (isBlank(prefix)) {
        prefix = '''import${ this . importsWithPrefixes . length}''';
        this.importsWithPrefixes[ast.value.moduleUrl] = prefix;
      }
      ctx.print('''${ prefix}.''');
    }
    ctx.print(ast.value.name);
    return null;
  }

  dynamic visitDeclareVarStmt(o.DeclareVarStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    super.visitDeclareVarStmt(stmt, ctx);
    if (ctx.isExportedVar(stmt.name)) {
      ctx.println(exportVar(stmt.name));
    }
    return null;
  }

  dynamic visitDeclareFunctionStmt(
      o.DeclareFunctionStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    super.visitDeclareFunctionStmt(stmt, ctx);
    if (ctx.isExportedVar(stmt.name)) {
      ctx.println(exportVar(stmt.name));
    }
    return null;
  }

  dynamic visitDeclareClassStmt(o.ClassStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    super.visitDeclareClassStmt(stmt, ctx);
    if (ctx.isExportedVar(stmt.name)) {
      ctx.println(exportVar(stmt.name));
    }
    return null;
  }
}

String exportVar(String varName) {
  return '''Object.defineProperty(exports, \'${ varName}\', { get: function() { return ${ varName}; }});''';
}
