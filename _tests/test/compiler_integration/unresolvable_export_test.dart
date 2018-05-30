@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should fail build for unresolved exports', () async {
    await compilesExpecting('''
      import '$ngImport';

      class GoodExport {}

      @Component(
        selector: 'bad',
        template: '',
        exports: const [BadExport, GoodExport],
      )
      class BadComponent {}
    ''', errors: [
      allOf([
        contains('Compiling @Component-annotated class "BadComponent" failed'),
        contains('BadExport'),
        isNot(contains('GoodExport')),
      ]),
    ]);
  });
}
