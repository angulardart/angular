@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should error gracefully on unresolved FactoryProvider', () async {
    await compilesExpecting("""
      import '$ngImport';

      String notConstFunction() => 'hello';
      const token = OpaqueToken<String>('my.token');

      @GenerateInjector(const [
        FactoryProvider.forToken(token, notConstFunction())
      ])
      final InjectorFactory injectorFactory = null; // OK for compiler tests.
    """, errors: [
      // NOTE: This error is associated with "injectorFactory". It should be
      // associated with "FactoryProvider.forToken instead.
      allOf(contains('Unable to parse @GenerateInjector'),
          containsSourceLocation(9, 29))
    ]);
  });
}
