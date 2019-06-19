@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should fail on a non-".css" file extension', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Component(
        selector: 'example',
        template: '',
        styleUrls: [
          'example.scss',
        ],
      )
      class Example {}
    """, errors: [
      contains('Unsupported extension in styleUrls: "example.scss"'),
    ]);
  });

  test('should fail on an invalid URI', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Component(
        selector: 'example',
        template: '',
        styleUrls: [
           // Intentionally mis-spell package as packages.
          'packages:foo/foo.css',
        ],
      )
      class Example {}
    """, errors: [
      contains('Invalid Style URL: "packages:foo/foo.css"'),
    ]);
  });
}
