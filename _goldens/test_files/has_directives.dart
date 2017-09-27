import 'package:angular/angular.dart';

@Component(
  selector: 'test-foo',
  template: r'''
    <div>My own template</div>
    A directive: <directive></directive>
    A component: <test-bar></test-bar>
  ''',
  directives: const [TestDirective, TestSubComponent],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class TestFooComponent {}

@Directive(selector: 'directive')
class TestDirective {}

@Component(
  selector: 'test-bar', template: '<div>Bar</div>',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class TestSubComponent {}
