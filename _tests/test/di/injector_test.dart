import 'package:angular/src/di/injector.dart';
import 'package:test/test.dart';

void main() {
  group('Injector.empty', () {
    test('should throw by default', () {
      const injector = const Injector.empty();
      expect(() => injector.get(Example), throwsArgumentError);
      expect(() => injector.inject(Example), throwsArgumentError);
      expect(() => injector.injectFromAncestry(Example), throwsArgumentError);
      expect(() => injector.injectFromParent(Example), throwsArgumentError);
      expect(() => injector.injectFromSelf(Example), throwsArgumentError);
    });

    test('should invoke orElse by default', () {
      const injector = const Injector.empty();
      final example = new Example();
      expect(
        injector.get(Example, example),
        example,
      );
      expect(
        injector.inject(Example, orElse: (_, __) => example),
        example,
      );
      expect(
        injector.injectFromAncestry(Example, orElse: (_, __) => example),
        example,
      );
      expect(
        injector.injectFromParent(Example, orElse: (_, __) => example),
        example,
      );
      expect(
        injector.injectFromSelf(Example, orElse: (_, __) => example),
        example,
      );
    });

    test('should provide self when injecting "Injector"', () {
      const injector = const Injector.empty();
      expect(injector.get(Injector), injector);
    });

    test('should delegate to the parent if provided', () {
      const parent = const Injector.map(const {
        Example: 5,
      });
      const injector = const Injector.empty(parent);
      expect(() => injector.injectFromSelf(Example), throwsArgumentError);
      expect(injector.get(Example), 5);
      expect(injector.inject(Example), 5);
      expect(injector.injectFromParent(Example), 5);
      expect(injector.injectFromAncestry(Example), 5);
    });
  });

  group('Injector.map', () {
    test('should throw if a key is missing', () {
      const injector = const Injector.map(const {});
      expect(() => injector.get(Example), throwsArgumentError);
      expect(() => injector.inject(Example), throwsArgumentError);
      expect(() => injector.injectFromAncestry(Example), throwsArgumentError);
      expect(() => injector.injectFromParent(Example), throwsArgumentError);
      expect(() => injector.injectFromSelf(Example), throwsArgumentError);
    });

    test('should invoke orElse by default', () {
      const injector = const Injector.map(const {});
      final example = new Example();
      expect(
        injector.get(Example, example),
        example,
      );
      expect(
        injector.inject(Example, orElse: (_, __) => example),
        example,
      );
      expect(
        injector.injectFromAncestry(Example, orElse: (_, __) => example),
        example,
      );
      expect(
        injector.injectFromParent(Example, orElse: (_, __) => example),
        example,
      );
      expect(
        injector.injectFromSelf(Example, orElse: (_, __) => example),
        example,
      );
    });

    test('should delegate to the parent if provided', () {
      const parent = const Injector.map(const {
        Example: 5,
      });
      const injector = const Injector.map(const {}, parent);
      expect(() => injector.injectFromSelf(Example), throwsArgumentError);
      expect(injector.get(Example), 5);
      expect(injector.inject(Example), 5);
      expect(injector.injectFromParent(Example), 5);
      expect(injector.injectFromAncestry(Example), 5);
    });

    test('should use the provided map for local lookups', () {
      const injector = const Injector.map(const {
        Example: 5,
      });
      expect(injector.get(Example), 5);
      expect(injector.inject(Example), 5);
      expect(injector.injectFromSelf(Example), 5);
    });
  });
}

class Example {}
