import 'package:angular/angular.dart';

import 'deferred_component.dart';

@Component(
  selector: 'test-container',
  template: '<deferred-component @deferred>Foo</deferred-component>',
  directives: const [DeferredChildComponent],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class TestContainerComponent {}
