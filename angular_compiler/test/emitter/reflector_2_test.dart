import 'package:angular_compiler/angular_compiler.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

import '../src/resolve.dart';

void main() {
  final _dartfmt = new DartFormatter().format;
  final angular = 'package:angular';
  final libReflection = '$angular/src/core/reflection/reflection.dart';

  test('should support a no-op', () {
    final output = new ReflectableOutput();
    final emitter = new ReflectableEmitter.useCodeBuilder(output);
    expect(emitter.emitImports(), isEmpty);
    expect(emitter.emitInitReflector(), isEmpty);
  });

  test('should emit no metadata for an empty injectable class', () async {
    final reflector = new ReflectableReader.noLinking(
      recordComponentsAsInjectables: false,
    );
    final output = await reflector.resolve(await resolveLibrary(r'''
      @Component(selector: 'example')
      class Example {}
    '''));
    final emitter = new ReflectableEmitter.useCodeBuilder(
      output,
      reflectorSource: libReflection,
    );
    expect(
      _dartfmt(emitter.emitInitReflector()),
      _dartfmt(r'''
        const _ExampleMetadata = const [];
      '''),
    );
  });

  test('should emit metadata for annotations named RouteConfig', () async {
    final reflector = new ReflectableReader.noLinking(
      recordComponentsAsInjectables: false,
    );
    final output = await reflector.resolve(await resolveLibrary(r'''
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
          path: '/dashboard',
          name: 'Dashboard',
          component: Example,
        ),
      ])
      class Example {}
    '''));
    final emitter = new ReflectableEmitter.useCodeBuilder(
      output,
      reflectorSource: libReflection,
    );
    expect(
      _dartfmt(emitter.emitInitReflector()),
      _dartfmt(r'''
        const _ExampleMetadata = const [
          const RouteConfig(const [
            const Route(
              path: '/dashboard',
              name: 'Dashboard',
              component: Example
            )
          ])
        ];
      '''),
    );
  });
}
