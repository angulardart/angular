import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

import '../src/resolve.dart';

void main() {
  test('should record a no-op', () async {
    final testLib = await resolveLibrary('');
    final output = await new ReflectableReader.noLinking().resolve(testLib);
    expect(
      output,
      new ReflectableOutput(),
    );
  });

  test('should record a factory', () async {
    final testLib = await resolveLibrary(r'''
      @Injectable()
      Duration getDuration(DateTime date) => null;

      Duration notAnnotated() => null;
    ''');
    final output = await new ReflectableReader.noLinking().resolve(testLib);
    expect(
      output,
      new ReflectableOutput(
        registerFunctions: [
          new DependencyInvocation(
            testLib.definingCompilationUnit.functions.firstWhere(
              (e) => e.name == 'getDuration',
            ),
            [
              new DependencyElement(
                new TypeTokenElement(
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
    final output = await new ReflectableReader.noLinking().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      new ReflectableOutput(registerClasses: [
        new ReflectableClass(
          element: clazz,
          name: 'Example',
          factory: new DependencyInvocation(
            clazz.unnamedConstructor,
            [
              new DependencyElement(
                new TypeTokenElement(
                  const TypeLink('Duration', 'dart:core'),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  });

  test('should record a directive (treated as an @Injectable)', () async {
    final testLib = await resolveLibrary(r'''
      @Directive(selector: 'example')
      class Example {
        Example(Duration duration);
      }
    ''');
    final output = await new ReflectableReader.noLinking().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      new ReflectableOutput(registerClasses: [
        new ReflectableClass(
          element: clazz,
          name: 'Example',
          factory: new DependencyInvocation(
            clazz.unnamedConstructor,
            [
              new DependencyElement(
                new TypeTokenElement(
                  const TypeLink('Duration', 'dart:core'),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  });

  test('should record a pipe (treated as an @Injectable)', () async {
    final testLib = await resolveLibrary(r'''
      @Pipe('example')
      class Example {
        Example(Duration duration);
      }
    ''');
    final output = await new ReflectableReader.noLinking().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      new ReflectableOutput(registerClasses: [
        new ReflectableClass(
          element: clazz,
          name: 'Example',
          factory: new DependencyInvocation(
            clazz.unnamedConstructor,
            [
              new DependencyElement(
                new TypeTokenElement(
                  const TypeLink('Duration', 'dart:core'),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  });

  test('should record a component (treated as an @Injectable too)', () async {
    final testLib = await resolveLibrary(r'''
      @Component(selector: 'example')
      class Example {
        Example(Duration duration);
      }
    ''');
    final output = await new ReflectableReader.noLinking().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      new ReflectableOutput(registerClasses: [
        new ReflectableClass(
          element: clazz,
          name: 'Example',
          factory: new DependencyInvocation(
            clazz.unnamedConstructor,
            [
              new DependencyElement(
                new TypeTokenElement(
                  const TypeLink('Duration', 'dart:core'),
                ),
              ),
            ],
          ),
          registerComponentFactory: true,
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
    final output = await new ReflectableReader.noLinking().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      new ReflectableOutput(registerClasses: [
        new ReflectableClass(
          element: clazz,
          name: 'Example',
          factory: new DependencyInvocation(
            clazz.unnamedConstructor,
            [
              new DependencyElement(
                new TypeTokenElement(
                  const TypeLink('Duration', 'dart:core'),
                ),
              ),
            ],
          ),
          registerAnnotation: new _StubRevivable(
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
      _fakeInputs = new Set<String>();
      _fakeIsLibrary = new Set<String>();
      reader = new ReflectableReader(
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

    test('should allow using "generatorInputs" to bypass I/O checks', () async {
      // Purposefully do not add any inputs, to ensure they are not used.
      reader = new ReflectableReader.noLinking(
        generatorInputs: [
          new Glob('**.dart'),
        ],
      );
      final testLib = await resolveLibrary(r'''
        // Do not link.
        import 'package:quiver/core.dart';
        
        // Link expected.
        import 'foo.dart';
      ''');
      final output = await reader.resolve(testLib);
      expect(output.urlsNeedingInitReflector, [
        'foo.template.dart',
      ]);
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
