@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:test/test.dart';

void main() {
  group('ReflectiveInjector.resolveStaticAndCreate', () {
    test('should allow ValueProvider', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate([
        new ValueProvider(String, 'Hello World'),
      ]);
      expect(injector.get(String), 'Hello World');
    });

    test('should allow Provider(useValue: ...)', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate([
        new Provider(String, useValue: 'Hello World'),
      ]);
      expect(injector.get(String), 'Hello World');
    });

    test('should allow FactoryProvider', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate([
        new FactoryProvider(String, () => 'Hello World', deps: const []),
      ]);
      expect(injector.get(String), 'Hello World');
    });

    test('should allow FactoryProvider with non-empty deps', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate(
        [
          new FactoryProvider(
            String,
            (Object o) => 'Hello $o',
            deps: const [Object],
          ),
        ],
        new Injector.map(
          {
            Object: 'World',
          },
        ),
      );
      expect(injector.get(String), 'Hello World');
    });

    test('should allow Provider(useFactory: ...)', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate([
        new Provider(String, useFactory: () => 'Hello World', deps: const []),
      ]);
      expect(injector.get(String), 'Hello World');
    });

    test('should allow ExistingProvider', () {
      final injector = ReflectiveInjector.resolveStaticAndCreate(
        [
          new ExistingProvider(Object, String),
        ],
        new Injector.map(
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
          new Provider(
            Object,
            useExisting: String,
          ),
        ],
        new Injector.map(
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
            new FactoryProvider(String, (Duration d) => '$d'),
          ]);
        },
        throwsUnsupportedError,
      );
    });

    test('should throw on an explicit ClassProvider', () {
      expect(
        () {
          ReflectiveInjector.resolveStaticAndCreate([
            new ClassProvider(InjectableService),
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
        () => i.resolveAndInstantiate(InjectableService),
        throwsUnsupportedError,
      );
    });
  });
}

class InjectableService {}
