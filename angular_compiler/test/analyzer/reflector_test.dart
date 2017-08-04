import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

import '../src/resolve.dart';

// TODO(matanl): Add a test that adds imports and checks .template.dart.
void main() {
  test('should record a no-op', () async {
    final testLib = await resolveLibrary('');
    final output = await new ReflectableReader().resolve(testLib);
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
    final output = await new ReflectableReader().resolve(testLib);
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
                  Uri.parse('dart:core#DateTime'),
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
    final output = await new ReflectableReader().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      new ReflectableOutput(registerClasses: [
        new ReflectableClass(
          name: 'Example',
          factory: new DependencyInvocation(
            clazz.unnamedConstructor,
            [
              new DependencyElement(
                new TypeTokenElement(
                  Uri.parse('dart:core#Duration'),
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
    final output = await new ReflectableReader().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      new ReflectableOutput(registerClasses: [
        new ReflectableClass(
          name: 'Example',
          factory: new DependencyInvocation(
            clazz.unnamedConstructor,
            [
              new DependencyElement(
                new TypeTokenElement(
                  Uri.parse('dart:core#Duration'),
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
    final output = await new ReflectableReader().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      new ReflectableOutput(registerClasses: [
        new ReflectableClass(
          name: 'Example',
          factory: new DependencyInvocation(
            clazz.unnamedConstructor,
            [
              new DependencyElement(
                new TypeTokenElement(
                  Uri.parse('dart:core#Duration'),
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
    final output = await new ReflectableReader().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      new ReflectableOutput(registerClasses: [
        new ReflectableClass(
          name: 'Example',
          factory: new DependencyInvocation(
            clazz.unnamedConstructor,
            [
              new DependencyElement(
                new TypeTokenElement(
                  Uri.parse('dart:core#Duration'),
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
    final output = await new ReflectableReader().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      new ReflectableOutput(registerClasses: [
        new ReflectableClass(
          name: 'Example',
          factory: new DependencyInvocation(
            clazz.unnamedConstructor,
            [
              new DependencyElement(
                new TypeTokenElement(
                  Uri.parse('dart:core#Duration'),
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
}

// TODO(matanl): https://github.com/dart-lang/source_gen/issues/254.
class _StubRevivable implements Revivable {
  final Uri source;

  const _StubRevivable(this.source);

  @override
  noSuchMethod(i) => super.noSuchMethod(i);
}
