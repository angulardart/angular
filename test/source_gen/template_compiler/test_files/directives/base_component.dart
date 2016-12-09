import 'package:angular2/angular2.dart';

import 'components.dart';
import 'directives.dart' as directive;

@Component(
    selector: 'test-foo',
    template: '<div>Foo</div>',
    directives: const [directive.TestDirective, TestSubComponent])
class TestFooComponent {}
