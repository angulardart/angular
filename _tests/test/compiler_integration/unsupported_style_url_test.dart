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
}
