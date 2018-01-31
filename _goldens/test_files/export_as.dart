import 'package:angular/angular.dart';

@Component(
  selector: 'test-foo',
  template: '<div>Foo</div>',
  exportAs: 'foo',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestFooComponent {}
