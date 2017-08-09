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
          'void initReflector() {\n'
          '  _ref0.initReflector();\n'
          '}\n',
    );
  });

  test('should support reflector linking', () async {
    final reflector = new ReflectableReader(
      // We have no inputs to this "build".
      hasInput: (_) => false,

      // Assume that the only import, "angular.dart", has generated code.
      isLibrary: (_) => true,
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
          'void initReflector() {\n'
          '  _ref0.initReflector();\n'
          '  _ngRef.registerFactory(\n'
          '    Example,\n'
          '    () => new Example(),\n'
          '  );\n'
          '  _ngRef.registerDependencies(\n'
          '    Example,\n'
          '    const [],\n'
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
          'void initReflector() {\n'
          '  _ngRef.registerFactory(\n'
          '    createExample,\n'
          '    (String p0) => createExample(p0),\n'
          '  );\n'
          '  _ngRef.registerDependencies(\n'
          '    createExample,\n'
          '    const [const [String,],],\n'
          '  );\n'
          '\n'
          '  _ngRef.registerFactory(\n'
          '    Example,\n'
          '    () => new Example(),\n'
          '  );\n'
          '  _ngRef.registerDependencies(\n'
          '    Example,\n'
          '    const [],\n'
          '  );\n'
          '\n'
          '}\n',
    );
  });

  test('should support component registration', () async {
    final reflector = new ReflectableReader.noLinking();
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
          'void initReflector() {\n'
          '  _ngRef.registerComponent(\n'
          '    Example,\n'
          '    ExampleNgFactory,\n'
          '  );\n'
          '  _ngRef.registerFactory(\n'
          '    Example,\n'
          '    () => new Example(),\n'
          '  );\n'
          '  _ngRef.registerDependencies(\n'
          '    Example,\n'
          '    const [],\n'
          '  );\n'
          '\n'
          '}\n',
    );
  });

  // TODO(matanl): Add remaining test cases:
  // 1. @RouteConfig.
  // 2. @Directive.
  // 3. @Pipe.
}
