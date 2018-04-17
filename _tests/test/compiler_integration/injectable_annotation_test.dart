@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should fail on an @Injectable private class', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Injectable()
      class _HeroService {}
    """, errors: [
      contains('Cannot access private class _HeroService'),
    ]);
  });

  test('should succeed on an @Injectable() public class', () async {
    await compilesNormally("""
      import '$ngImport';

      @Injectable()
      class HeroService {}
    """);
  });
}
