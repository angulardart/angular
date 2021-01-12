// @dart=2.9

import 'package:test/test.dart';
import 'package:_tests/compiler.dart';
import 'package:angular_compiler/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  test('should not crash on null class names', () async {
    await compilesNormally("""
      import '$ngImport';

      @Component(
        selector: 'null-class',
        template: '<div class></div>',
      )
      class NullClassComponent {}
    """);
  });
}
