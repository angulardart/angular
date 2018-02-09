import 'package:angular/angular.dart';

import 'components.dart';
import 'directives.dart' as directive;

@Component(
  selector: 'test-foo',
  template: '<div>Foo</div><test-bar></test-bar>',
  directives: const [directive.TestDirective, TestSubComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestFooComponent {}
