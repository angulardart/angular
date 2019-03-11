@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should fail on a missing @ViewChild() query', () async {
    await compilesExpecting("""
      import 'dart:html';
      import '$ngImport';

      @Component(
        selector: 'hero',
        template: '<div></div>',
      )
      class HeroComponent {
        @ViewChild()
        Element div;
      }
    """, errors: [
      allOf([
        contains('Missing selector argument for "@ViewChild"'),
        containsSourceLocation(9, 9)
      ])
    ]);
  });
}
