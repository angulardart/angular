@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:test/test.dart';

void main() {
  group('ReflectiveInjector.resolveStaticAndCreate', () {
    test('should allow ValueProvider', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate([
        ValueProvider(String, 'Hello World'),
      ]);
      expect(injector.get(String), 'Hello World');
    });

    test('should allow Provider(useValue: ...)', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate([
        Provider(String, useValue: 'Hello World'),
      ]);
      expect(injector.get(String), 'Hello World');
    });

    test('should allow FactoryProvider', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate([
        FactoryProvider(String, () => 'Hello World', deps: const []),
      ]);
      expect(injector.get(String), 'Hello World');
    });

    test('should allow FactoryProvider with non-empty deps', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate(
        [
          FactoryProvider(
            String,
            (Object o) => 'Hello $o',
            deps: const [Object],
          ),
        ],
        Injector.map(
          {
            Object: 'World',
          },
        ),
      );
      expect(injector.get(String), 'Hello World');
    });

    test('should allow Provider(useFactory: ...)', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate([
        Provider(String, useFactory: () => 'Hello World', deps: const []),
      ]);
      expect(injector.get(String), 'Hello World');
    });

    test('should allow ExistingProvider', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate(
        [
          ExistingProvider(Object, String),
        ],
        Injector.map(
          {
            String: 'Hello World',
          },
        ),
      );
      expect(injector.get(Object), 'Hello World');
    });

    test('should allow Provider(useExisting: ...)', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate(
        [
          Provider(
            Object,
            useExisting: String,
          ),
        ],
        Injector.map(
          {
            String: 'Hello World',
          },
        ),
      );
      expect(injector.get(String), 'Hello World');
    });

    test('should throw on FactoryProvider without deps', () {
      expect(
        () {
          ReflectiveInjector.resolveStaticAndCreate([
            FactoryProvider(String, (Duration d) => '$d'),
          ]);
        },
        throwsUnsupportedError,
      );
    });

    test('should throw on an explicit ClassProvider', () {
      expect(
        () {
          ReflectiveInjector.resolveStaticAndCreate([
            ClassProvider(InjectableService),
          ]);
        },
        throwsUnsupportedError,
      );
    });

    test('should throw on an implicit ClassProvider', () {
      expect(
        () {
          ReflectiveInjector.resolveStaticAndCreate([
            InjectableService,
          ]);
        },
        throwsUnsupportedError,
      );
    });

    test('resolveAndCreateChild should also check providers', () {
      final i = ReflectiveInjector.resolveStaticAndCreate([]);
      expect(
        () {
          i.resolveAndCreateChild([
            InjectableService,
          ]);
        },
        throwsUnsupportedError,
      );
    });

    test('resolveAndInstantiate should also check providers', () {
      final i = ReflectiveInjector.resolveStaticAndCreate([]);
      expect(
        // ignore: deprecated_member_use
        () => i.resolveAndInstantiate(InjectableService),
        throwsUnsupportedError,
      );
    });
  });
}

class InjectableService {}
