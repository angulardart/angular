import 'package:angular2/angular2.dart';

@Component(
    selector: 'test-foo',
    template: '<div>Foo</div>',
    directives: const [TestDirective, TestSubComponent])
class TestFooComponent {}

@Directive(selector: 'directive')
class TestDirective {}

@Component(selector: 'test-bar', template: '<div>Bar</div>')
class TestSubComponent {}
