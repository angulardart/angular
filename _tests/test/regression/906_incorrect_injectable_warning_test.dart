@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should not warn about @Injectable for classes not injected', () async {
    // See https://github.com/dart-lang/angular/issues/906.
    await compilesNormally("""
      import '$ngImport';

      abstract class JustAnInterface {}

      const providesAnInterface = const ExistingProvider<JustAnInterface>(
        JustAnInterface,
        ConcreteClass,
      );

      @Component(
        selector: 'comp',
        providers: const [
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

  test('should still warn when useClass: is used with an interface', () async {
    await compilesExpecting("""
      import '$ngImport';

      abstract class JustAnInterface {}

      @Component(
        selector: 'comp',
        provides: const [
          const Provider(JustAnInterface, useClass: JustAnInterface),
        ],
        template: '',
      )
      class Comp {}
    """, warnings: [
      contains('Found a constructor for an abstract class JustAnInterface'),
    ]);
  }, skip: 'This fails both before AND after the fix for #906. Fixing after.');

  test('should still warn when using a type implicitly as useClass:', () async {
    await compilesExpecting("""
      import '$ngImport';

      abstract class JustAnInterface {}

      @Component(
        selector: 'comp',
        provides: const [
          JustAnInterface,
        ],
        template: '',
      )
      class Comp {}
    """, warnings: [
      contains('Found a constructor for an abstract class JustAnInterface'),
    ]);
  }, skip: 'This fails both before AND after the fix for #906. Fixing after.');
}
