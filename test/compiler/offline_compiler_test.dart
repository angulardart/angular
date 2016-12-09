@TestOn('browser')
library angular2.test.compiler.offline_compiler_test;

import "package:angular2/core.dart" show Injector;
import "package:angular2/src/core/linker/component_factory.dart"
    show ComponentFactory;
import "package:angular2/src/core/render/api.dart" show sharedStylesHost;
import "package:angular2/src/debug/debug_node.dart"
    show DebugElement, getDebugNode;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

import "offline_compiler_codegen_typed.dart" as typed;
import "offline_compiler_util.dart" show CompA;

void main() {
  var outputDefs = [];
  var typedComponentFactory = typed.CompANgFactory;
  // Our generator only works on node.js and Dart...
  outputDefs.add(
      {"compAHostComponentFactory": typedComponentFactory, "name": "typed"});
  group("OfflineCompiler", () {
    Injector injector;
    setUp(() async {
      await inject([Injector], (_injector) {
        injector = _injector;
      });
    });
    DebugElement createHostComp(ComponentFactory cf) {
      var compRef = cf.create(injector);
      return (getDebugNode(compRef.location.nativeElement) as DebugElement);
    }

    outputDefs.forEach((outputDef) {
      group('''${ outputDef [ "name" ]}''', () {
        test("should compile components", () {
          var hostEl = createHostComp(outputDef["compAHostComponentFactory"]);
          expect(hostEl.componentInstance, new isInstanceOf<CompA>());
          var styles = sharedStylesHost.getAllStyles();
          expect(styles[0], contains(".redStyle[_ngcontent"));
          expect(styles[1], contains(".greenStyle[_ngcontent"));
        });
      });
    });
  });
}
