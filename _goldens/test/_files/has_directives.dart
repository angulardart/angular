import 'package:angular/angular.dart';

@Component(
  selector: 'test-foo',
  template: r'''
    <div>My own template</div>
    A directive: <directive></directive>
    A component: <test-bar></test-bar>
  ''',
  directives: [TestDirective, TestSubComponent],
)
class TestFooComponent {}

@Directive(
  selector: 'directive',
)
class TestDirective {}

@Component(
  selector: 'test-bar',
  template: '<div>Bar</div>',
)
class TestSubComponent {}
