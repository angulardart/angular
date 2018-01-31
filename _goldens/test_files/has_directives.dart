import 'package:angular/angular.dart';

@Component(
  selector: 'test-foo',
  template: r'''
    <div>My own template</div>
    A directive: <directive></directive>
    A component: <test-bar></test-bar>
  ''',
  directives: const [TestDirective, TestSubComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestFooComponent {}

@Directive(
  selector: 'directive',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestDirective {}

@Component(
  selector: 'test-bar',
  template: '<div>Bar</div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestSubComponent {}
