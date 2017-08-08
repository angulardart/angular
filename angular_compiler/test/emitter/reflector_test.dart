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

  test('should support registration', () async {
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
          '  // TODO: Register functions and classes.\n'
          '}\n',
    );
  });

  // TODO(matanl): Add remaining test cases (functions, components, etc).
}
