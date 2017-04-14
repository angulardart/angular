import 'package:angular2/angular2.dart';

import 'deferred_component.dart';

@Component(
    selector: 'test-container',
    template: '<deferred-component !deferred>Foo</deferred-component>',
    directives: const [DeferredChildComponent])
class TestContainerComponent {}
