// @dart=2.9

import 'package:test/test.dart';
import 'package:_tests/compiler.dart';
import 'package:angular_compiler/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  test('should fail with a readable error on a mispelled annotation', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Injectionable()
      class HeroService {}
    """, errors: [
      allOf(
        contains('Could not resolve "@Injectionable()"'),
        contains('class HeroService'),
        contains('Try the following when diagnosing the problem:'),
        containsSourceLocation(4, 13),
      ),
    ]);
  });

  test('should fail with an error on mispelled parameter annotation', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Component(
        selector: 'with-bad-annotation',
        template: '<b>Boo</b>')
      class HeroComponent {
        HeroComponent(@badAnnotation someService);
      }
    """, errors: [
      allOf(
        contains('Error evaluating annotation'),
        contains('@badAnnotation'),
        containsSourceLocation(7, 23),
      ),
    ]);
  });

  test('should fail with an error in an @Inject parameter', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Injectable()
      class HeroComponent {
        HeroComponent(@Inject(badValue) someService);
      }
    """, errors: [
      allOf(
        contains('Annotation on element has errors and was unresolvable.'),
        contains('badValue'),
        containsSourceLocation(5, 41),
      ),
    ]);
  });

  test('should fail with a readable error on a missing import', () async {
    await compilesExpecting('''
      // Intentionally missing import.

      @Injectable()
      class HeroService {}
    ''', errors: [
      allOf(
        contains('Could not resolve "@Injectable()"'),
        contains('class HeroService'),
        contains('Try the following when diagnosing the problem:'),
        containsSourceLocation(4, 13),
      ),
    ]);
  });

  test('should warn on a bad enum annotation', () async {
    await compilesExpecting('''
      @undefinedAnnotation
      enum SomeEnum {
        cool,
      }
    ''', errors: [], warnings: [
      allOf(
        contains('@undefinedAnnotation'),
        containsSourceLocation(1, 7),
      )
    ]);
  });
}
