@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should identify a possibly unresolvable directive', () async {
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

  test('should identify a possibly unresolvable pipe', () async {
    await compilesExpecting('''
      import '$ngImport';

      @Component(
        selector: 'bad-comp',
        template: '',
        pipes: [MissingPipe],
      )
      class BadComp {}
    ''', errors: [
      allOf([
        contains('Compiling @Component-annotated class "BadComp" failed'),
      ]),
    ]);
  });

  test('should identify an unresolved provider', () async {
    await compilesExpecting('''
    import '$ngImport';

      @Component(
        selector: 'bad-provider',
        directives: const [
          ClassProvider(Nope),
        ],
        template: '',
      )
      class BadProvider {}

    ''', errors: [
      allOf([
        contains('Compiling @Component-annotated class "BadProvider" failed'),
      ])
    ]);
  });

  test('should warn on dead code', () async {
    await compilesExpecting('''
    import '$ngImport';

    @Component(
      selector: 'opaque',
      template: 'I am a rock'
    )
    class OpaqueComponent {}

    @Component(
      selector: 'hidden-gold',
      template: '<opaque>Dropped</opaque>',
      directives: [OpaqueComponent]
    )
    class HiddenGoldComponenet {}
    ''', warnings: [
      allOf([
        'line 1, column 9 of asset:pkg/lib/input.dart: Dead code in template: '
            'Non-empty text node (Dropped) is a child of a non-projecting '
            'component (opaque) and will not be added to the DOM.\n'
            '<opaque>Dropped</opaque>\n'
            '        ^^^^^^^'
      ])
    ]);
  });
}
