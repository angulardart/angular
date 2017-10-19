import 'package:angular/angular.dart';

import 'deferred_component.dart';

@Component(
  selector: 'test-container',
  template: '<deferred-component @deferred>Foo</deferred-component>',
  directives: const [DeferredChildComponent],
)
class TestContainerComponent {}
