@TestOn('browser')
library angular2.test.core.linker.reflector_component_resolver_test;

import "package:angular2/core.dart" show provide;
import "package:angular2/src/core/linker/component_factory.dart"
    show ComponentFactory;
import "package:angular2/src/core/linker/component_resolver.dart"
    show ComponentResolver, ReflectorComponentResolver;
import "package:angular2/src/core/reflection/reflection.dart"
    show reflector, ReflectionInfo;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void main() {
  group("Compiler", () {
    var someCompFactory;
    beforeEachProviders(() =>
        [provide(ComponentResolver, useClass: ReflectorComponentResolver)]);
    setUp(() async {
      await inject([ComponentResolver], (_compiler) {
        someCompFactory = new ComponentFactory(null, null, null);
        reflector.registerType(
            SomeComponent, new ReflectionInfo([someCompFactory]));
      });
    });
    test("should read the template from an annotation", () async {
      return inject([AsyncTestCompleter, ComponentResolver],
          (AsyncTestCompleter completer, ComponentResolver compiler) {
        compiler
            .resolveComponent(SomeComponent)
            .then((ComponentFactory compFactory) {
          expect(compFactory, someCompFactory);
          completer.done();
          return null;
        });
      });
    });
  });
}

class SomeComponent {}
