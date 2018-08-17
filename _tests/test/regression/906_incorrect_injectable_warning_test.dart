@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

// See https://github.com/dart-lang/angular/issues/906.
void main() {
  test('should not warn about @Injectable for classes not injected', () async {
    await compilesNormally("""
      import '$ngImport';

      abstract class JustAnInterface {}

      const providesAnInterface = ExistingProvider<JustAnInterface>(
        JustAnInterface,
        ConcreteClass,
      );

      @Component(
        selector: 'comp',
        providers: [
          providesAnInterface,
        ],
        template: '',
      )
      class ConcreteClass implements JustAnInterface {}

      @Injectable()
      class InjectsAnInterface {
        InjectsAnInterface(JustAnInterface _);
      }
    """);
  });

  test('should still fail when useClass: is used with an interface', () async {
    await compilesExpecting("""
      import '$ngImport';

      abstract class JustAnInterface {}

      @Component(
        selector: 'comp',
        providers: [
          ClassProvider(JustAnInterface, JustAnInterface),
        ],
        template: '',
      )
      class Comp {}
    """, errors: [
      contains('Cannot create a new instance of an abstract class'),
    ]);
  });

  test('should still fail when using a type implicitly as useClass:', () async {
    await compilesExpecting("""
      import '$ngImport';

      abstract class JustAnInterface {}

      @Component(
        selector: 'comp',
        providers: [
          JustAnInterface,
        ],
        template: '',
      )
      class Comp {}
    """, errors: [
      contains('Cannot create a new instance of an abstract class'),
    ]);
  });
}
