@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should warn on a bad enum annotation', () async {
    await compilesExpecting("""
      @undefinedAnnotation
      enum SomeEnum {}
    """, errors: [], warnings: [
      allOf(contains('@undefinedAnnotation'), containsSourceLocation(1, 7))
    ]);
  });
}
