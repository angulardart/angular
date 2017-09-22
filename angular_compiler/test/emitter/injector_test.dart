import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

import '../src/resolve.dart';

void main() {
  const angular = 'package:angular';
  const libInjector = '$angular/src/di/injector.dart';

  test('should support a no-op', () {
    final emitter = new InjectorEmitter({});
    expect(emitter.emitImports(), isEmpty);
    expect(emitter.emitInjector(), isEmpty);
  });

  test('should support a simple injector', () async {
    final library = await resolveLibrary(r'''
      @providers
      class Example {}
      class ExamplePrime {}

      const providers = const [
        const Provider(Example, useClass: ExamplePrime),  
      ];
    ''');
    final module = const ModuleReader().parseModule(
      library.getType('Example').metadata.first.computeConstantValue(),
    );
    final providers = module.flatten();
    final injector = new InjectorEmitter({
      'ExampleInjector': providers,
    });
    expect(
      injector.emitImports(),
      "import '$libInjector' as _injector;",
    );
    expect(
        injector.emitInjector(),
        ''
        'class ExampleInjector\$Generated extends _injector.GeneratedInjector {\n'
        '  ExampleInjector\$Generated([_injector.Injector parent]) : super(parent);\n'
        '  @override\n'
        '  T injectFromSelf<T>(\n'
        '    Object token, {\n'
        '    _injector.OrElseInject<T> orElse: _injector.throwsNotFound,\n'
        '  }) {\n'
        '    switch (token) {\n'
        '      case Example:\n'
        '        return _provide0();\n'
        '      default:\n'
        '        return orElse(this, token);\n'
        '    }\n'
        '  }\n'
        '  Example _field0;\n'
        '  Example _provide0() {\n'
        '    return _field0 ??= new ExamplePrime();\n'
        '  }\n'
        '\n'
        '}\n');
  });
}
