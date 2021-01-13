// @dart=2.9

import 'package:test/test.dart';
import 'package:_tests/compiler.dart';
import 'package:angular_compiler/v2/context.dart';

void main() {
  test('should fail on files opted-in to null safety w/o allow-list', () async {
    CompileContext.overrideForTesting(
      CompileContext.forTesting(emitNullSafeCode: false),
    );

    await compilesExpecting(
      """
      // Intentionally omits "@dart=2.9".
      import '$ngImport';

      @Component(
        selector: 'example-class',
        template: '',
      )
      class ExampleComp {
        String? nullableString;
      }
      """,
      errors: [
        contains('Null-safety is not supported for AngularDart.'),
      ],
    );
  }, tags: 'fails-on-travis');

  test('should pass on files opted-in to null safety w/ allow-list', () async {
    CompileContext.overrideForTesting(
      CompileContext.forTesting(emitNullSafeCode: true),
    );

    await compilesNormally(
      """
      // Intentionally omits "@dart=2.9".
      import '$ngImport';

      @Component(
        selector: 'example-class',
        template: '',
      )
      class ExampleComp {
        String? nullableString;
      }
      """,
      inputSource: 'pkg|lib/allowed.dart',
    );
  });
}
