@TestOn("!js")
library angular2.test.di.provider_test;

import 'dart:mirrors';

import 'package:test/test.dart';
import 'package:angular/di.dart';

void main() {
  group('Binding', () {
    test('can create constant from token', () {
      expect(const Provider(Foo).token, Foo);
    });

    test('can create constant from class', () {
      expect(const Provider(Foo, useClass: Bar).useClass, Bar);
    });

    test('can create constant from value', () {
      expect(const Provider(Foo, useValue: 5).useValue, 5);
    });

    test('can create constant from alias', () {
      expect(const Provider(Foo, useExisting: Bar).useExisting, Bar);
    });

    test('can create constant from factory', () {
      expect(const Provider(Foo, useFactory: fn).useFactory, fn);
    });

    test('can be used in annotation', () {
      ClassMirror mirror = reflectType(Annotated);
      var bindings = mirror.metadata[0].reflectee.bindings;
      expect(bindings, hasLength(5));
      bindings.forEach((b) {
        expect(b is Provider, true);
      });
    });
  });
}

class Foo {}

class Bar extends Foo {}

fn() => null;

class Annotation {
  final List bindings;
  const Annotation(this.bindings);
}

@Annotation([
  Provider(Foo),
  Provider(Foo, useClass: Bar),
  Provider(Foo, useValue: 5),
  Provider(Foo, useExisting: Bar),
  Provider(Foo, useFactory: fn)
])
class Annotated {}
