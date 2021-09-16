// @dart=2.9

import 'package:_tests/compiler.dart';
import 'package:angular_compiler/v2/context.dart';
import 'package:test/test.dart';

void main() {
  CompileContext.overrideForTesting();

  test('should fail on an @Injectable private class', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Injectable()
      class _HeroService {}
    """, errors: [
      allOf([
        contains('Private classes can not be @Injectable'),
        contains('_HeroService'),
        containsSourceLocation(4, 13)
      ]),
    ]);
  });

  test('should succeed on an @Injectable() public class', () async {
    await compilesNormally("""
      import '$ngImport';

      @Injectable()
      class HeroService {}
    """);
  });

  test('should not warn about @Injectable for classes not injected', () async {
    // See https://github.com/angulardart/angular/issues/906.
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
}
