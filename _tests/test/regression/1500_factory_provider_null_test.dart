@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

// See https://github.com/dart-lang/angular/issues/1500.
void main() {
  test('should disallow a value of "null" for FactoryProvider', () async {
    await compilesExpecting("""
      import '$ngImport';

      class Service {}

      @GenerateInjector([
        FactoryProvider(Service, null),
      ])
      final InjectorFactory injectorFactory = null; // OK for compiler tests.
    """, errors: [
      contains('an explicit value of `null` was passed in where a function is'),
    ]);
  });
}
