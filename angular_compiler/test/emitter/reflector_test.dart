import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

import '../src/resolve.dart';

void main() {
  const angular = 'package:angular';
  const libReflection = '$angular/src/core/reflection/reflection.dart';

  test('should support a no-op', () {
    final output = new ReflectableOutput();
    final emitter = new ReflectableEmitter(output);
    expect(
      emitter.emitImports(),
      ''
          '// No initReflector() linking required.\n',
    );
    expect(
      emitter.emitInitReflector(),
      ''
          '// No initReflector() needed.\n'
          'void initReflector() {}\n',
    );
  });

  test('should support linking', () {
    final output = new ReflectableOutput(
      urlsNeedingInitReflector: ['foo.template.dart'],
    );
    final emitter = new ReflectableEmitter(output);
    expect(
      emitter.emitImports(),
      ''
          '// Required for initReflector().\n'
          'import \'foo.template.dart\' as _ref0;\n'
          '\n',
    );
    expect(
      emitter.emitInitReflector(),
      ''
          'var _visited = false;\n'
          'void initReflector() {\n'
          '  if (_visited) {\n'
          '    return;\n'
          '  }\n'
          '  _visited = true;\n'
          '  _ref0.initReflector();\n'
          '}\n',
    );
  });

  test('should support reflector linking', () async {
    final reflector = new ReflectableReader(
      // We have no inputs to this "build".
      hasInput: (_) => false,

      // Assume that the only import, "angular.dart", has generated code.
      isLibrary: (_) async => true,
    );
    final output = await reflector.resolve(await resolveLibrary(r'''
      @Injectable()
      class Example {}
    '''));
    final emitter = new ReflectableEmitter(
      output,
      reflectorSource: libReflection,
    );
    expect(
        emitter.emitImports(),
        ''
        '// Required for initReflector().\n'
        'import \'$libReflection\' as _ngRef;\n'
        'import \'$angular/angular.template.dart\' as _ref0;\n'
        '\n');
    expect(
      emitter.emitInitReflector(),
      ''
          'var _visited = false;\n'
          'void initReflector() {\n'
          '  if (_visited) {\n'
          '    return;\n'
          '  }\n'
          '  _visited = true;\n'
          '  _ref0.initReflector();\n'
          '  _ngRef.registerFactory(\n'
          '    Example,\n'
          '    () => new Example(),\n'
          '  );\n'
          '\n'
          '}\n',
    );
  });

  test('should support named constructors', () async {
    final reflector = new ReflectableReader.noLinking();
    final output = await reflector.resolve(await resolveLibrary(r'''
      @Injectable()
      class Example {
        Example.namedConstructor();
      }
    '''));
    final emitter = new ReflectableEmitter(
      output,
      reflectorSource: libReflection,
    );
    expect(
      emitter.emitInitReflector(),
      ''
          'var _visited = false;\n'
          'void initReflector() {\n'
          '  if (_visited) {\n'
          '    return;\n'
          '  }\n'
          '  _visited = true;\n'
          '  _ngRef.registerFactory(\n'
          '    Example,\n'
          '    () => new Example.namedConstructor(),\n'
          '  );\n'
          '\n'
          '}\n',
    );
  });

  test('should support factory registration', () async {
    final reflector = new ReflectableReader.noLinking();
    final output = await reflector.resolve(await resolveLibrary(r'''
      @Injectable()
      class Example {}

      @Injectable()
      Example createExample(String parameter) => new Example();
    '''));
    final emitter = new ReflectableEmitter(
      output,
      reflectorSource: libReflection,
    );
    expect(
      emitter.emitInitReflector(),
      ''
          'var _visited = false;\n'
          'void initReflector() {\n'
          '  if (_visited) {\n'
          '    return;\n'
          '  }\n'
          '  _visited = true;\n'
          '  _ngRef.registerDependencies(\n'
          '    createExample,\n'
          '    const [const [String,],],\n'
          '  );\n'
          '\n'
          '  _ngRef.registerFactory(\n'
          '    Example,\n'
          '    () => new Example(),\n'
          '  );\n'
          '\n'
          '}\n',
    );
  });

  test('should support prefixed identifiers', () async {
    final reflector = new ReflectableReader.noLinking();
    final output = await reflector.resolve(await resolveLibrary(r'''
      import 'package:angular/angular.dart' as ng_prefixed;

      @Injectable()
      class Example {
        final ng_prefixed.ComponentLoader b;
        Example(ng_prefixed.ComponentLoader a1, this.b);
      }

      @Injectable()
      ng_prefixed.ComponentLoader getComponentLoader([
        @Optional()
        @SkipSelf()
        ng_prefixed.ComponentLoader existingComponentLoader,
      ]) => null;
    '''));
    final emitter = new ReflectableEmitter(
      output,
      reflectorSource: libReflection,
    );
    expect(
      emitter.emitInitReflector(),
      ''
          'var _visited = false;\n'
          'void initReflector() {\n'
          '  if (_visited) {\n'
          '    return;\n'
          '  }\n'
          '  _visited = true;\n'
          '  _ngRef.registerDependencies(\n'
          '    getComponentLoader,\n'
          '    const [const [ng_prefixed.ComponentLoader,const _ngRef.SkipSelf(),const _ngRef.Optional(),],],\n'
          '  );\n'
          '\n'
          '  _ngRef.registerFactory(\n'
          '    Example,\n'
          '    (ng_prefixed.ComponentLoader p0, ng_prefixed.ComponentLoader p1) => new Example(p0, p1),\n'
          '  );\n'
          '  _ngRef.registerDependencies(\n'
          '    Example,\n'
          '    const [const [ng_prefixed.ComponentLoader,],const [ng_prefixed.ComponentLoader,],],\n'
          '  );\n'
          '\n'
          '}\n',
    );
  });

  test('should support generic types', () async {
    final reflector = new ReflectableReader.noLinking();
    final output = await reflector.resolve(await resolveLibrary(r'''
      const someToken = const OpaqueToken('someToken');
      @Injectable()
      class Example {
        final Map<String, Map<int, String>> example;
        Example(@Inject(someToken) this.example);
      }
    '''));
    final emitter = new ReflectableEmitter(
      output,
      reflectorSource: libReflection,
    );
    expect(
      emitter.emitInitReflector(),
      ''
          'var _visited = false;\n'
          'void initReflector() {\n'
          '  if (_visited) {\n'
          '    return;\n'
          '  }\n'
          '  _visited = true;\n'
          '  _ngRef.registerFactory(\n'
          '    Example,\n'
          '    (Map p0) => new Example(p0),\n'
          '  );\n'
          '  _ngRef.registerDependencies(\n'
          '    Example,\n'
          '    const [const [const _ngRef.Inject(const _ngRef.OpaqueToken(r\'someToken\')),],],\n'
          '  );\n'
          '\n'
          '}\n',
    );
  });

  test('should support prefixed top-level fields', () async {
    final reflector = new ReflectableReader.noLinking();
    final output = await reflector.resolve(await resolveLibrary(r'''
      import 'package:meta/meta.dart' as meta_lib;

      @Injectable()
      class Example {
        final String example;
        Example(@Inject(meta_lib.visibleForTesting) this.example);
      }
    '''));
    final emitter = new ReflectableEmitter(
      output,
      reflectorSource: libReflection,
    );
    expect(
      emitter.emitInitReflector(),
      ''
          'var _visited = false;\n'
          'void initReflector() {\n'
          '  if (_visited) {\n'
          '    return;\n'
          '  }\n'
          '  _visited = true;\n'
          '  _ngRef.registerFactory(\n'
          '    Example,\n'
          '    (String p0) => new Example(p0),\n'
          '  );\n'
          '  _ngRef.registerDependencies(\n'
          '    Example,\n'
          '    const [const [const _ngRef.Inject(meta_lib.visibleForTesting),],],\n'
          '  );\n'
          '\n'
          '}\n',
    );
  });

  test('should support component registration', () async {
    final reflector = new ReflectableReader.noLinking(
      recordComponentsAsInjectables: false,
    );
    final output = await reflector.resolve(await resolveLibrary(r'''
      @Component(selector: 'example')
      class Example {}
    '''));
    final emitter = new ReflectableEmitter(
      output,
      reflectorSource: libReflection,
    );
    expect(
      emitter.emitInitReflector(),
      ''
          'const _ExampleMetadata = const [];\n'
          'var _visited = false;\n'
          'void initReflector() {\n'
          '  if (_visited) {\n'
          '    return;\n'
          '  }\n'
          '  _visited = true;\n'
          '  _ngRef.registerComponent(\n'
          '    Example,\n'
          '    ExampleNgFactory,\n'
          '  );\n'
          '}\n',
    );
  });

  test('should support directives and pipe factories', () async {
    final reflector = new ReflectableReader.noLinking();
    final output = await reflector.resolve(await resolveLibrary(r'''
      @Directive(selector: 'example')
      class ExampleDirective {}

      @Pipe('example')
      class ExamplePipe {}
    '''));
    final emitter = new ReflectableEmitter(
      output,
      reflectorSource: libReflection,
    );
    expect(
      emitter.emitInitReflector(),
      ''
          'var _visited = false;\n'
          'void initReflector() {\n'
          '  if (_visited) {\n'
          '    return;\n'
          '  }\n'
          '  _visited = true;\n'
          '  _ngRef.registerFactory(\n'
          '    ExampleDirective,\n'
          '    () => new ExampleDirective(),\n'
          '  );\n\n'
          '  _ngRef.registerFactory(\n'
          '    ExamplePipe,\n'
          '    () => new ExamplePipe(),\n'
          '  );\n'
          '\n'
          '}\n',
    );
  });

  test('should emit @RouteConfig annotations', () async {
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
    final emitter = new ReflectableEmitter(
      output,
      reflectorSource: libReflection,
    );
    expect(
      emitter.emitInitReflector(),
      ''
          'const _ExampleMetadata = const [\n'
          "  const RouteConfig(const [const Route(path: '/dashboard', name: 'Dashboard', component: Example)]),\n"
          '];\n'
          'var _visited = false;\n'
          'void initReflector() {\n'
          '  if (_visited) {\n'
          '    return;\n'
          '  }\n'
          '  _visited = true;\n'
          '  _ngRef.registerComponent(\n'
          '    Example,\n'
          '    ExampleNgFactory,\n'
          '  );\n'
          '}\n',
    );
  });
}
