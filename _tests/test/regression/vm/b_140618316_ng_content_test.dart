@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should compile as expected', () async {
    await compilesNormally("""
      import '$ngImport';

      @Component(
        selector: 'foo',
        template: '<ng-content select="[highlight]"></ng-content>',
      )
      class FooAComponent {}

      @Component(
        selector: 'foo[box]',
        providers: [ExistingProvider(FooAComponent, FooBComponent)],
        template: '',
      )
      class FooBComponent {}

      @Component(
        selector: 'test',
        template: '<foo box><p highlight>bar</p></foo>',
        directives: [FooAComponent, FooBComponent],
      )
      class TestComponent {}
    """);
  });
}
