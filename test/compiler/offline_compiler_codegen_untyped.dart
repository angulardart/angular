// ATTENTION: This file will be overwritten with generated code by main()
library angular2.test.compiler.offline_compiler_codegen_untyped;

import "package:angular2/src/compiler/output/js_emitter.dart"
    show JavaScriptEmitter;
import "package:angular2/src/core/linker/component_factory.dart"
    show ComponentFactory;
import "package:angular2/src/facade/lang.dart" show print;

import "offline_compiler_util.dart" show compileComp, compAMetadata;

final ComponentFactory CompANgFactory = null;
// Generator
main(List<String> args) {
  var emitter = new JavaScriptEmitter();
  compileComp(emitter, compAMetadata).then((source) {
    // debug: console.error(source);
    print(source);
  });
}
