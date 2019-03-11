@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should support generic component with dynamic type argument', () {
    return compilesNormally('''
      import '$ngImport';

      @Component(
        selector: 'generic',
        template: '',
      )
      class GenericComponent<T> {}

      @Component(
        selector: 'test',
        template: '<generic></generic>',
        directives: [GenericComponent],
        directiveTypes: [Typed<GenericComponent<dynamic>>()],
      )
      class TestComponent {}
    ''');
  });
}
