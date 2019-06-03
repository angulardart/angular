@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';
import 'package:term_glyph/term_glyph.dart' as term_glyph;

void main() {
  setUpAll(() {
    term_glyph.ascii = true;
  });

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

  test('should error on invalid use of const', () async {
    await compilesExpecting('''
      import '$ngImport';

      @Component(
        selector: 'bad-comp',
        directives:  [
          const UndeclaredIdentifier,
        ],
        template: '',
      )
      class BadComp {}
    ''', errors: [
      allOf([
        // This is an UnresolvedExpressionException, but it should
        // be an AnalysisError, reading "@Component-annotated" instead.
        contains('Compiling @Component annotated class "BadComp" failed'),
        // Once b/134096969 is fixed, these expectations should be true:
        // contains('Compiling @Component-annotated class "BadComp" failed'),
        // containsSourceLocation(6, 11), // points to 'const Undeclared..'
      ]),
    ]);
  });

  test('should error on an incorrect member annotation', () async {
    // NOTE: @Input on BadComp.inValue is invalid.
    await compilesExpecting('''
      import '$ngImport';

      @Directive(
        selector: 'valid',
      )
      class ValidDirective {}

      @Component(
        selector: 'bad-comp',
        directives: const [
        ],
        template: '',
      )
      class BadComp {
        @Input
        String inValue;
      }
    ''', warnings: [
      allOf(contains('Annotation creation must have arguments'),
          contains('Input'), containsSourceLocation(15, 9)),
    ]);
  });

  test('should error gracefully on a bad setter', () async {
    await compilesExpecting('''
      import '$ngImport';

      @Component(
        selector: 'bad-input',
        template: '',
      )
      class BadInputSetter {
        @Input()
        set noMethodBody;
      }
    ''', errors: [
      allOf([
        contains('@Input setter has no parameters'),
        contains('noMethodBody'),
        containsSourceLocation(9, 13)
      ])
    ]);
  });

  test('should error on incorrect function annotations', () async {
    await compilesExpecting('''
      import '$ngImport';

      @Directive(
        selector: 'badProvider',
        providers: [OopsProvider]
      )
      bool functionDirective() {};


    ''', errors: [
      allOf(
          contains('Compiling annotation @Directive'),
          contains('Undefined name \'OopsProvider\''),
          containsSourceLocation(5, 21)), // pointing at OopsProvider
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

  test('should error gracefully on bad constructor parameters', () async {
    await compilesExpecting('''
      import '$ngImport';

      @Component(
        selector: 'bad-constructor',
        template: '',
      )
      class BadConstructor {
        BadConstructor(@HuhWhatIsThis);
      }
    ''', errors: [
      // TODO(b/124524346): Only print one error.
      allOf([
        contains('Error evaluating annotation'),
        containsSourceLocation(8, 24)
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
            '  ,\n'
            '1 | <opaque>Dropped</opaque>\n'
            '  |         ^^^^^^^\n'
            "  '"
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

  test('should throw if both "template" and "templateUrl" are present',
      () async {
    await compilesExpecting('''
    import '$ngImport';

    @Component(
      selector: 'double-up',
      template: 'boo',
      templateUrl: 'boo.html'
    )
    class DoubleUp {}
    ''', errors: [
      allOf([
        contains(
            'Cannot supply both "template" and "templateUrl" for an @Component'),
        containsSourceLocation(3, 5)
      ])
    ]);
  });

  test('should throw if "templateUrl" fails to parse', () async {
    await compilesExpecting('''
    import '$ngImport';

    @Component(
      selector: 'bad-url',
      templateUrl: '<scheme:urlWithBadScheme'
    )
    class BadUrl {}
    ''', errors: [
      allOf([
        contains('@Component.templateUrl is not a valid URI'),
        containsSourceLocation(3, 5)
      ])
    ]);
  });

  group('providers', () {
    test('should error on invalid token', () async {
      await compilesExpecting('''
      import '$ngImport';

      const tokenRef = BadToken;

      @Component(
        selector: 'badToken',
        template: '',
        providers: [ClassProvider(tokenRef)]
      )
      class BadComponent {};
    ''', errors: [
        allOf(contains('A provider\'s token field failed to compile'),
            containsSourceLocation(5, 7)), // pointing at @Component
      ]);
    });

    test('should warn on when provider is not a class', () async {
      await compilesExpecting('''
      import '$ngImport';

      typedef Compare = int Function(Object a, Object b);
      @Component(
        selector: 'stringProvider',
        template: '',
        providers: [Compare]
      )
      class BadComponent {};
    ''', errors: [], warnings: [
        allOf(contains('Expected to find class in provider list'),
            containsSourceLocation(4, 7)), // pointing at @Component
      ]);
    });

    test('should error on when useClass is not a class', () async {
      await compilesExpecting('''
      import '$ngImport';

      class ToProvide {}
      typedef Compare = int Function(Object a, Object b);

      @Component(
        selector: 'useClass',
        template: '',
        providers: [ClassProvider(ToProvide, useClass: Compare)]
      )
      class BadComponent {};
    ''', errors: [
        allOf(contains('Provider.useClass can only be used with a class'),
            containsSourceLocation(6, 7)) // pointing at @Component
      ]);
    });

    test('should error on when useFactory is not a function', () async {
      await compilesExpecting('''
      import '$ngImport';

      class ToProvide {}

      @Component(
        selector: 'useFactory',
        template: '',
        providers: [FactoryProvider(ToProvide, ToProvide)]
      )
      class BadComponent {};
    ''', errors: [allOf(contains('ToProvide'), containsSourceLocation(8, 48))]);
    });
  });
}
