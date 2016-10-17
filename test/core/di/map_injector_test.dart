@TestOn('browser')
library angular2.test.core.di.map_injector_test;

import "package:angular2/core.dart" show Injector, MapInjectorFactory;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void main() {
  group("MapInjector", () {
    test("should throw if not found", () {
      expect(() => new MapInjectorFactory().create().get("someToken"),
          throwsWith("No provider for someToken!"));
    });
    test("should return the default value", () {
      expect(new MapInjectorFactory().create().get("someToken", "notFound"),
          "notFound");
    });
    test("should return the injector", () {
      var injector = new MapInjectorFactory().create();
      expect(injector.get(Injector), injector);
    });
    test("should delegate to the parent", () {
      var parent = new MapInjectorFactory({"someToken": "someValue"}).create();
      expect(new MapInjectorFactory().create(parent).get("someToken"),
          "someValue");
    });
  });
}
