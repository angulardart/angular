@TestOn('browser')
library angular2.test.core.di.injector_test;

import "package:angular2/core.dart" show Injector, InjectorFactory;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void main() {
  group("Injector.NULL", () {
    test("should throw if no arg is given", () {
      expect(() => Injector.NULL.get("someToken"),
          throwsWith("No provider for someToken!"));
    });
    test("should throw if THROW_IF_NOT_FOUND is given", () {
      expect(() => Injector.NULL.get("someToken", Injector.THROW_IF_NOT_FOUND),
          throwsWith("No provider for someToken!"));
    });
    test("should return the default value", () {
      expect(Injector.NULL.get("someToken", "notFound"), "notFound");
    });
  });
  group("InjectorFactory.bind", () {
    test("should bind the context", () {
      var factory = new MockInjectorFactory();
      expect(
          InjectorFactory.bind(factory, "testContext").create(), Injector.NULL);
      expect(factory.context, "testContext");
    });
  });
  group("InjectorFactory.EMPTY", () {
    test("should return Injector.NULL if no parent is given", () {
      expect(InjectorFactory.EMPTY.create(), Injector.NULL);
    });
    test("should be const", () {
      expect(InjectorFactory.EMPTY, InjectorFactory.EMPTY);
    });
  });
}

class MockInjectorFactory implements InjectorFactory<dynamic> {
  dynamic context;
  Injector parent;
  Injector create([Injector parent = null, dynamic context = null]) {
    this.context = context;
    this.parent = parent;
    return Injector.NULL;
  }
}
