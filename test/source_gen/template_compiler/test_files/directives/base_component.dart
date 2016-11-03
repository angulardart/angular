import 'package:angular2/angular2.dart';

import 'directives.dart';

@Component(
    selector: 'test-foo',
    template: '<div>Foo</div>',
    directives: const [TestDirective, TestSubComponent])
class TestFooComponent {}
