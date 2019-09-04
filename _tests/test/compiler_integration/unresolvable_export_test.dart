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
        containsSourceLocation(8, 25)
      ]),
    ]);
  });

  test('should fail build for non identifier exports', () async {
    await compilesExpecting('''
      import '$ngImport';

      @Component(
        selector: 'bad',
        template: '',
        exports: const [1],
      )
      class BadComponent {}
    ''', errors: [
      allOf([
        contains('Item 1 in the "exports" field must be an identifier'),
        containsSourceLocation(3, 7)
      ]),
    ]);
  });

  test(
      'should fail build if exports field having a class prefix, it only allows'
      'library prefix instead', () async {
    await compilesExpecting('''
      import '$ngImport';

      class Foo {
        static String bar() => 'Error';
      }

      @Component(
        selector: 'bad',
        template: '',
        exports: const [Foo.bar],
      )
      class BadComponent {}
    ''', errors: [
      allOf([
        contains('must be either a simple identifier or an identifier with a '
            'library prefix'),
        contains('Foo.bar'),
        containsSourceLocation(7, 7)
      ])
    ]);
  });
}
