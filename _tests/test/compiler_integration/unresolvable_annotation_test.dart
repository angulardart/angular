@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
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
      ),
    ]);
  });

  test('should fail with a readable error on a missing import', () async {
    await compilesExpecting("""
      // Intentionally missing import.

      @Injectable()
      class HeroService {}
    """, errors: [
      allOf(
        contains('Could not resolve "@Injectable()"'),
        contains('class HeroService'),
        contains('Try the following when diagnosing the problem:'),
      ),
    ]);
  });

  test('should not fail on an invalid but unrelated annotation', () async {
    await compilesNormally("""
      import '$ngImport';
      // Oops, we forgot to import 'package:meta/meta.dart'!

      class NotRelatedtoAngular {
        @protected
        void doAThing() {}
      }
    """);
  });
}
