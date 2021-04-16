// @dart=2.9

import 'package:build/build.dart';
import 'package:test/test.dart';
import 'package:_tests/compiler.dart';
import 'package:angular_compiler/v2/context.dart';

void main() {
  setUp(CompileContext.overrideForTesting);

  test('should fail on an injector with a nullable non-optional', () async {
    await compilesExpecting("""
      import '$ngImport';

      class Engine {
        Engine(String? engineName);
      }

      @GenerateInjector([
        ClassProvider(Engine),
      ])
      final injectorFactory = null; // OK for compiler tests.
    """, errors: [
      allOf(
        contains('must be annotated @Optional()'),
      )
    ]);
  });

  test('should fail on an injector with a nullable FutureOr', () async {
    await compilesExpecting("""
      import 'dart:async';
      import '$ngImport';

      class Engine {
        Engine(FutureOr<String?> engineName);
      }

      @GenerateInjector([
        ClassProvider(Engine),
      ])
      final injectorFactory = null; // OK for compiler tests.
    """, errors: [
      allOf(
        contains('must be annotated @Optional()'),
      )
    ]);
  });

  test('should fail on an injector with a non-nullable optional', () async {
    await compilesExpecting("""
      import '$ngImport';

      class Engine {
        Engine(@Optional() String engineName);
      }

      @GenerateInjector([
        ClassProvider(Engine),
      ])
      final injectorFactory = null; // OK for compiler tests.
    """, errors: [
      allOf(
        contains('must be annotated @Optional()'),
      )
    ]);
  });

  test('should allow optional FactoryProvider deps in injector', () async {
    await compilesNormally('''
      import '$ngImport';

      class Engine {
        Engine(@Optional() String name);
      }

      Engine createEngine(@Optional() String? name) => Engine(name);

      @GenerateInjector([
        FactoryProvider(
          Engine,
          createEngine,
          deps: [
            [String, Optional()],
          ],
        ),
      ])
      final injectorFactory = null;
    ''');
  });

  test('should allow optional FactoryProvider deps in component', () async {
    await compilesNormally('''
      import '$ngImport';

      class Engine {
        Engine(@Optional() String name);
      }

      Engine createEngine(@Optional() String? name) => Engine(name);

      @Component(
        selector: 'car',
        template: '',
        providers: [
          FactoryProvider(
            Engine,
            createEngine,
            deps: [
              [String, Optional()],
            ],
          ),
        ],
      )
      class CarComponent {}
    ''');
  });

  test('should fail on a component with a non-nullable optional', () async {
    await compilesExpecting("""
      import '$ngImport';

      class Engine {}

      @Component(
        selector: 'car-comp',
        template: '',
      )
      class CarComponent {
        CarComponent(@Optional() Engine engine);
      }
    """, errors: [
      allOf(
        contains('must be annotated @Optional()'),
      )
    ]);
  });

  test('should fail on a component with a nullable non-optional', () async {
    await compilesExpecting("""
      import '$ngImport';

      class Engine {}

      @Component(
        selector: 'car-comp',
        template: '',
      )
      class CarComponent {
        CarComponent(Engine? engine);
      }
    """, errors: [
      allOf(
        contains('must be annotated @Optional()'),
      )
    ]);
  });

  test('should fail on an component with a nullable FutureOr', () async {
    await compilesExpecting("""
      import 'dart:async';
      import '$ngImport';

      class Engine {}

      @Component(
        selector: 'car-comp',
        template: '',
      )
      class CarComponent {
        CarComponent(FutureOr<Engine?> engine);
      }
    """, errors: [
      allOf(
        contains('must be annotated @Optional()'),
      )
    ]);
  });

  test('should allow a nullable attribute that is not optional', () async {
    await compilesNormally("""
      import '$ngImport';

      class Engine {}

      @Component(
        selector: 'car-comp',
        template: '',
      )
      class CarComponent {
        CarComponent(@Attribute('title') String? title);
      }
    """);
  });

  group('should allow opted-out to use opted-in import w/o error', () {
    final clientLibSource = """
      // @dart=2.9
      import '$ngImport';
      import 'opted_in_library.dart';

      @Component(
        selector: 'example-comp',
        template: '',
        providers: [
          ClassProvider(Clock),
        ],
      )
      class ExampleComp {
        ExampleComp(Clock clock);
      }
    """;

    setUp(() {
      CompileContext.overrideForTesting(
        CompileContext.forTesting(emitNullSafeCode: false),
      );
    });

    test('[expected nullable]', () async {
      final importLibSource = '''
        typedef DateTimeGetter = DateTime Function();
        class Clock {
          static DateTime _defaultGetTime() => DateTime.now();
          Clock([DateTimeGetter getTime = _defaultGetTime]);
        }
      ''';
      await compilesNormally(
        clientLibSource,
        include: {
          'pkg|lib/opted_in_library.dart': importLibSource,
        },
        inputSource: 'pkg|lib/opted_out_client.dart',
        runBuilderOn: {AssetId('pkg', 'lib/opted_out_client.dart')},
      );
    });

    test('[expected @Optional]', () async {
      final importLibSource = '''
        class Clock {
          Clock(DateTime? expectedToBeOptional);
        }
      ''';
      await compilesNormally(
        clientLibSource,
        include: {
          'pkg|lib/opted_in_library.dart': importLibSource,
        },
        inputSource: 'pkg|lib/opted_out_client.dart',
        runBuilderOn: {AssetId('pkg', 'lib/opted_out_client.dart')},
      );
    });
  });
}
