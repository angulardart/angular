import 'package:angular/angular.dart';

@Component(
  selector: 'test-foo', template: '<div>Foo</div>', exportAs: 'foo',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class TestFooComponent {}
