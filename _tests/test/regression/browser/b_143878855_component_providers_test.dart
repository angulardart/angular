@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'b_143878855_component_providers_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should only inject providers from a matched component', () {
    final testBed = NgTestBed.forComponent(ng.createTestFactory());
    return testBed.create();
  });
}

abstract class Foo {}

@Component(
  selector: 'foo',
  template: '',
  providers: [
    ExistingProvider(Foo, Foo1),
  ],
)
class Foo1 implements Foo {}

@Component(
  selector: 'foo',
  template: '',
  providers: [
    ExistingProvider(Foo, Foo2),
  ],
)
class Foo2 implements Foo {}

@Directive(selector: '[bar]')
class Bar {
  Bar(Foo foo) {
    expect(foo, TypeMatcher<Foo1>());
  }
}

@Component(
  selector: 'test',
  template: '''
    <foo bar></foo>
  ''',
  // Both Foo1 and Foo2 match <foo>, but Foo1 is instantiated because it's first
  // in the list of directives. Bar injects Foo, which is provided by both Foo1
  // and Foo2. Normally the *last* matching provider is injected, but since Foo2
  // isn't instantiated, its providers shouldn't be available for injection,
  // thus Foo1's provider should be injected.
  directives: [
    Foo1,
    Foo2,
    Bar,
  ],
)
class Test {}
