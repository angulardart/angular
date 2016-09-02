import 'package:angular2/di.dart';
import 'package:angular2/src/testing/test_bed/flatten_providers.dart';
import 'package:test/test.dart';

void main() {
  group('flattenProviders', () {
    test('should emit a detailed error message', () {
      try {
        flattenProviders([Foo, null, Bar]);
        fail('Should have thrown $InvalidProviderTypeException');
      } on InvalidProviderTypeException catch (e) {
        expect(
            e.toString(),
            'Invalid provider: [\n'
            '  "#0: Type {Foo}",\n'
            '  "vvvvvvvv",\n'
            '  "#1: null",\n'
            '  "^^^^^^^^",\n'
            '  "#2: Type {Bar}"\n'
            ']');
      }
    });

    test('should throw if `null` is provided', () {
      expect(() => flattenProviders([Foo, null, Bar]),
          throwsA(const isInstanceOf<InvalidProviderTypeException>()));
    });

    test('should throw if something strange is provided', () {
      expect(() => flattenProviders([Foo, 'notAProvider', Bar]),
          throwsA(const isInstanceOf<InvalidProviderTypeException>()));
    });

    test('should not throw when only valid types are used', () {
      expect(
          () => flattenProviders([
                Foo,
                const Provider(Bar),
                [Bar]
              ]),
          isNot(throws));
    });
  });
}

class Foo {}

class Bar {}
