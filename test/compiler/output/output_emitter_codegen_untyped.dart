// ATTENTION: This file will be overwritten with generated code by main()
library angular2.test.compiler.output.output_emitter_codegen_untyped;

import "package:angular2/src/compiler/output/js_emitter.dart"
    show JavaScriptEmitter;
import "package:angular2/src/facade/lang.dart" show print;

import "output_emitter_util.dart" show codegenExportsVars, codegenStmts;

dynamic getExpressions() {
  throw new UnimplementedError();
}

// Generator
main(List<String> args) {
  var emitter = new JavaScriptEmitter();
  var emittedCode = emitter.emitStatements(
      "asset:angular2/test/compiler/output/output_emitter_codegen_untyped",
      codegenStmts,
      codegenExportsVars);
  // debug: console.error(emittedCode);
  print(emittedCode);
}
