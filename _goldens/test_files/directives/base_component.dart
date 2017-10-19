import 'package:angular/angular.dart';

import 'components.dart';
import 'directives.dart' as directive;

@Component(
  selector: 'test-foo',
  template: '<div>Foo</div><test-bar></test-bar>',
  directives: const [directive.TestDirective, TestSubComponent],
)
class TestFooComponent {}
