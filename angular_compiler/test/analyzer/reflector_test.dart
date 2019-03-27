import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/cli.dart';

import '../src/resolve.dart';

void main() {
  test('should record a no-op', () async {
    final testLib = await resolveLibrary('');
    final output = await ReflectableReader.noLinking().resolve(testLib);
    expect(
      output,
      ReflectableOutput(),
    );
  });

  test('should record a factory', () async {
    final testLib = await resolveLibrary(r'''
      @Injectable()
      Duration getDuration(DateTime date) => null;

      Duration notAnnotated() => null;
    ''');
    final output = await ReflectableReader.noLinking().resolve(testLib);
    expect(
      output,
      ReflectableOutput(
        registerFunctions: [
          DependencyInvocation(
            testLib.definingCompilationUnit.functions.firstWhere(
              (e) => e.name == 'getDuration',
            ),
            [
              DependencyElement(
                TypeTokenElement(
                  const TypeLink('DateTime', 'dart:core'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  });

  test('should record a class', () async {
    final testLib = await resolveLibrary(r'''
      @Injectable()
      class Example {
        Example(Duration duration);
      }
    ''');
    final output = await ReflectableReader.noLinking().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      ReflectableOutput(registerClasses: [
        ReflectableClass(
          element: clazz,
          name: 'Example',
          factory: DependencyInvocation(
            clazz.unnamedConstructor,
            [
              DependencyElement(
                TypeTokenElement(
                  const TypeLink('Duration', 'dart:core'),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  });

  test('should record a component with an @RouteConfig annotation', () async {
    final testLib = await resolveLibrary(r'''
      // Inlined a minimal version here to simplify the test setup.
      class RouteConfig {
        final List<Route> configs;
        const RouteConfig(this.configs);
      }
      class Route {
        final dynamic component;
        final String path;
        final String name;

        const Route({
          this.name,
          this path,
          this.component,
        });
      }

      @Component(selector: 'example')
      @RouteConfig(const [
        const Route(
          path: '/heroes',
          name: 'Heroes',
          component: Example,
        ),
      ])
      class Example {
        Example(Duration duration);
      }
    ''');
    final output = await ReflectableReader.noLinking().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      ReflectableOutput(registerClasses: [
        ReflectableClass(
          element: clazz,
          name: 'Example',
          factory: null,
          registerAnnotation: _StubRevivable(
            Uri.parse('asset:test_lib/lib/test_lib.dart#RouteConfig'),
          ),
          registerComponentFactory: true,
        ),
      ]),
    );
  });

  group('for linking', () {
    Set<String> _fakeInputs;
    Set<String> _fakeIsLibrary;
    ReflectableReader reader;

    setUp(() {
      _fakeInputs = <String>{};
      _fakeIsLibrary = <String>{};
      reader = ReflectableReader(
        hasInput: _fakeInputs.contains,
        isLibrary: (lib) async => _fakeIsLibrary.contains(lib),
      );
    });

    test('should always link to an imported .template.dart', () async {
      final testLib = await resolveLibrary(r'''
        import 'foo.template.dart';
        export 'bar.template.dart';
      ''');
      final output = await reader.resolve(testLib);
      expect(
        output.urlsNeedingInitReflector,
        unorderedEquals([
          'foo.template.dart',
          'bar.template.dart',
        ]),
      );
    });

    test('should link to a file that has a .template.dart on disk', () async {
      _fakeIsLibrary.add('foo.template.dart');
      final testLib = await resolveLibrary(r'''
        import 'foo.dart';
        import 'bar.dart';
      ''');
      final output = await reader.resolve(testLib);
      expect(
        output.urlsNeedingInitReflector,
        [
          'foo.template.dart',
        ],
      );
    });

    test('should link to a file that will have a .template.dart', () async {
      _fakeInputs.add('foo.dart');
      final testLib = await resolveLibrary(r'''
        import 'foo.dart';
        import 'bar.dart';
      ''');
      final output = await reader.resolve(testLib);
      expect(
        output.urlsNeedingInitReflector,
        [
          'foo.template.dart',
        ],
      );
    });
  });

  group('errors', () {
    ReflectableReader reader;

    String pleaseThrow = 'please.throw';
    setUp(() {
      reader = ReflectableReader(
        hasInput: (input) => input.contains(pleaseThrow)
            ? throw Exception("bad input $input")
            : false,
        isLibrary: (lib) async => lib.contains(pleaseThrow)
            ? throw Exception("bad library $lib")
            : false,
      );
    });

    test('should throw on invalid asset it', () async {
      final testLib = await resolveLibrary('''
        import 'package:$pleaseThrow/file.dart';
      ''');
      expect(
          reader.resolve(testLib),
          throwsA(allOf([
            predicate((e) => e is BuildError),
            predicate((e) =>
                e.message.contains("Could not parse URI") &&
                e.message.contains("line 4, column 9")),
          ])));
    });

    test('should throw on private injectable class', () async {
      final testLib = await resolveLibrary(r'''
      @Injectable()
      class _Example {
        Example(Duration duration);
      }
    ''');
      expect(
          reader.resolve(testLib),
          throwsA(allOf([
            predicate((e) => e is BuildError),
            predicate((e) =>
                e.message.contains("Private classes can not be @Injectable") &&
                e.message.contains("line 5, column 13")),
          ])));
    });
  });
}

// TODO(matanl): https://github.com/dart-lang/source_gen/issues/254.
class _StubRevivable implements Revivable {
  final Uri source;

  const _StubRevivable(this.source);

  @override
  noSuchMethod(i) => super.noSuchMethod(i);
}
