@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should identify a possible unresolvable directive', () async {
    await compilesExpecting('''
      import '$ngImport';

      @Directive(
        selector: 'valid',
      )
      class ValidDirective {}

      @Component(
        selector: 'bad-comp',
        directives: const [
          OopsDirective,
          ValidDirective,
        ],
        template: '',
      )
      class BadComp {}
    ''', errors: [
      allOf([
        contains('Compiling @Component-annotated class "BadComp" failed'),
      ]),
    ]);
  });
}
