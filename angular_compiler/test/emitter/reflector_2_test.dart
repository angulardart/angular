import 'package:angular_compiler/angular_compiler.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

import '../src/resolve.dart';

void main() {
  final dartfmt = new DartFormatter().format;
  final angular = 'package:angular';
  final libReflection = '$angular/src/core/reflection/reflection.dart';

  test('should support a no-op', () {
    final output = new ReflectableOutput();
    final emitter = new ReflectableEmitter.useCodeBuilder(output);
    expect(emitter.emitImports(), isEmpty);
    expect(
      emitter.emitInitReflector(),
      '// No initReflector() linking required.\nvoid initReflector(){}',
    );
  });

  test('should support linking', () {
    final output = new ReflectableOutput(
      urlsNeedingInitReflector: ['foo.template.dart'],
    );
    final emitter = new ReflectableEmitter.useCodeBuilder(output);
    expect(
      dartfmt(emitter.emitImports()),
      dartfmt(r'''
        import 'foo.template.dart' as _ref0;
      '''),
    );
    expect(
      dartfmt(emitter.emitInitReflector()),
      dartfmt(r'''
        var _visited = false;
        void initReflector() {
          if (_visited) {
            return;
          }
          _visited = true;

          _ref0.initReflector();
        }
      '''),
    );
  });

  test('should skip linking to deferred libraries', () {
    final output = new ReflectableOutput(
      urlsNeedingInitReflector: [
        // Relative file.
        'foo.template.dart',

        // Package file.
        'package:bar/bar.template.dart',
      ],
    );
    final emitter = new ReflectableEmitter.useCodeBuilder(
      output,
      deferredModules: [
        // Relative file.
        'asset:baz/lib/foo.template.dart',

        // Package file.
        'asset:bar/lib/bar.template.dart',
      ],
      deferredModuleSource: 'asset:baz/lib/baz.dart',
    );
    expect(emitter.emitImports(), isEmpty);
    expect(
      dartfmt(emitter.emitInitReflector()),
      dartfmt(r'''
        var _visited = false;
        void initReflector() {
          if (_visited) {
            return;
          }
          _visited = true;
        }
      '''),
    );
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
      dartfmt(emitter.emitInitReflector()),
      dartfmt(r'''
        const _ExampleMetadata = const [];
        var _visited = false;
        void initReflector() {
          if (_visited) {
            return;
          }
          _visited = true;
        }
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
      dartfmt(emitter.emitInitReflector()),
      dartfmt(r'''
        const _ExampleMetadata = const [
          const RouteConfig(const [
            const Route(
              path: '/dashboard',
              name: 'Dashboard',
              component: Example
            )
          ])
        ];
        var _visited = false;
        void initReflector() {
          if (_visited) {
            return;
          }
          _visited = true;
        }
      '''),
    );
  });
}
