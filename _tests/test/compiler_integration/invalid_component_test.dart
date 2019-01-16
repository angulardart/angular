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
        containsSourceLocation(11, 11),
        contains('OopsDirective')
      ]),
    ]);
  });

  test('should not report unrelated errors', () async {
    await compilesExpecting('''
      import '$ngImport';

      const int neverMentionFour = "four";

      @Component(
        selector: 'bad-comp',
        directives: const [
          OopsDirective,
        ],
        template: '',
      )
      class BadComp {}
    ''', errors: [
      allOf([
        isNot(contains(
            "The argument type 'int' can't be assigned to the parameter type 'String'")),
        isNot(contains("neverMentionFour"))
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
        containsSourceLocation(6, 17),
        contains('MissingPipe')
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
        containsSourceLocation(6, 25),
        contains('Nope')
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

  test('should throw on unused directive types', () async {
    await compilesExpecting('''
    import '$ngImport';
    
    @Component(
      selector: 'generic',
      template: 'Bye',
    )
    class GenericComponent<T> {
      GenericComponent() {}
    }
    
    @Component(
      selector: 'mis-match',
      template: 'Aye',
      directves: [],
      directiveTypes: [Typed<GenericComponent<String>>()])
      
      class ExampleComponent {}
 
    ''', errors: [
      allOf([
        contains('Entry in "directiveTypes" missing corresponding entry in'
            ' "directives" for "GenericComponent".'),
        containsSourceLocation(11, 5)
      ])
    ]);
  });

  test('should throw on missing selector', () async {
    await compilesExpecting('''
    import '$ngImport';

    @Component(
      template: 'boo'
    )
    class NoSelector {}
    ''', errors: [
      allOf([
        contains('Selector is required, got "null"'),
        containsSourceLocation(3, 5)
      ])
    ]);
  });

  test('should throw on empty selector', () async {
    await compilesExpecting('''
    import '$ngImport';

    @Component(
      selector: '',
      template: 'boo'
    )
    class EmptySelector {}
    ''', errors: [
      allOf([
        contains('Selector is required, got ""'),
        containsSourceLocation(3, 5)
      ])
    ]);
  });

  test('should throw on async ngDoCheck', () async {
    await compilesExpecting('''
    import '$ngImport';

    @Component(
      selector: 'async-docheck',
      template: 'boo'
    )
    class AsyncDoCheck implements DoCheck {
      void ngDoCheck() async {}
    }
    ''', errors: [
      allOf([
        contains('ngDoCheck should not be "async"'),
        containsSourceLocation(8, 12)
      ])
    ]);
  });

  test('should throw on DoCheck and OnChanges', () async {
    await compilesExpecting('''
    import '$ngImport';

    @Component(
      selector: 'do-check-and-on-changes',
      template: 'boo'
    )
    class DoCheckAndOnChanges implements DoCheck, OnChanges {}
    ''', errors: [
      allOf([
        contains(
            'Cannot implement both the DoCheck and OnChanges lifecycle events'),
        containsSourceLocation(7, 11)
      ])
    ]);
  });
}
