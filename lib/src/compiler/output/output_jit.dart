import "package:angular2/src/facade/lang.dart" show isPresent, evalExpression;

import "../util.dart" show sanitizeIdentifier;
import "abstract_emitter.dart" show EmitterVisitorContext;
import "abstract_js_emitter.dart" show AbstractJsEmitterVisitor;
import "output_ast.dart" as o;

List<String> jitStatements(
    String sourceUrl, List<o.Statement> statements, String resultVar) {
  var converter = new JitEmitterVisitor();
  var ctx = EmitterVisitorContext.createRoot([resultVar]);
  converter.visitAllStatements(statements, ctx);
  return evalExpression(sourceUrl, resultVar, ctx.toSource(),
      converter.getArgs() as Map<String, String>);
}

class JitEmitterVisitor extends AbstractJsEmitterVisitor {
  List<String> _evalArgNames = [];
  List<dynamic> _evalArgValues = [];
  Map<String, dynamic> getArgs() {
    var result = <String, String>{};
    for (var i = 0; i < this._evalArgNames.length; i++) {
      result[this._evalArgNames[i]] = this._evalArgValues[i];
    }
    return result;
  }

  dynamic visitExternalExpr(o.ExternalExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    var value = ast.value.runtime;
    var id = this._evalArgValues.indexOf(value);
    if (identical(id, -1)) {
      id = this._evalArgValues.length;
      this._evalArgValues.add(value);
      var name = isPresent(ast.value.name)
          ? sanitizeIdentifier(ast.value.name)
          : "val";
      this._evalArgNames.add(sanitizeIdentifier('''jit_${ name}${ id}'''));
    }
    ctx.print(this._evalArgNames[id]);
    return null;
  }
}
