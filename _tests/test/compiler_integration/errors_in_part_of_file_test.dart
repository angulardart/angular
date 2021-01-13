// @dart=2.9

import 'package:test/test.dart';
import 'package:_tests/compiler.dart';
import 'package:angular_compiler/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  test('should throw meaningful error message if it is in part of dart file',
      () async {
    await compilesExpecting(
      """
      import '$ngImport';

      part 'rest.dart';

      @Component(
        selector: 'major',
        template: '',
      )
      class MajorComp {}
    """,
      include: {
        'pkg|lib/rest.dart': """
        part of 'input.dart';

        @Component(
          selector: 'rest',
          template: '',
          styleUrls: ['rest.scss'],
        )
        class RestComp {}
        """,
      },
      errors: [
        allOf(
          contains('Unsupported extension in styleUrls:'),
          contains('Only ".css" is supported'),
        )
      ],
    );
  });
}
