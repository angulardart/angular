import 'package:angular/angular.dart';
import 'package:_goldens/component.dart';

import 'deferred_component.dart';

@Component(
  selector: 'test-container',
  template: r''''
      <deferred-component @deferred>Foo</deferred-component>
      <sample-component @deferred></sample-component>
  ''',
  directives: const [DeferredChildComponent, SampleComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestContainerComponent {}
