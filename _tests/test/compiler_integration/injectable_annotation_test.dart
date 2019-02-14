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
}
