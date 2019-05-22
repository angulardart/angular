/// This regression test demonstrates why `View.injectorGet()` must null-check
/// the `nodeIndex` argument, a rare and complex case that requires a number of
/// conditions to be met.
///
///   (1) Create a component whose template contains a top-level view container;
///   this ensures the view container has a null parent index.
///
///   (2) Add directive(s) with multiple providers to any node in the
///   component's template with at least one child node; this ensures that a
///   range check on `nodeIndex` is generated in `injectorGetInternal` and not
///   skipped due to short-circuit evaluation when a node only has one provider
///   and the token doesn't match. This range check is what will throw if
///   `nodeIndex` is null.
///
///   (3) Inject a dependency via the top-level view container's
///   `parentInjector`. This causes the null parent index to pass from
///   `ElementInjector.provideUntyped()` to `View.injectorGet()`.
@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'b_133253211_null_node_index_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('View.injectorGet() should handle a null nodeIndex argument', () async {
    final testValue = 'Hello world!';
    final testBed = NgTestBed.forComponent(
      ng.TestComponentNgFactory,
      rootInjector: ([parent]) => Injector.map({testToken: testValue}, parent),
    );
    final testFixture = await testBed.create();
    final testComponent = testFixture.assertOnlyInstance;
    expect(
      // This parent injector, an `ElementInjector`, passes a null nodeIndex
      // parameter to `View.injectorGet()`. Note that while this looks like a
      // bizarre use case that might not seem worth supporting, this is the
      // simplest reproduction of this pattern that can be achieved far more
      // indirectly via declarative means. Clients do depend on this behavior.
      testComponent.viewContainerRef.parentInjector.provideToken(testToken),
      testValue,
    );
  });
}

@Component(
  selector: 'test',
  directives: [ProvidersDirective],
  template: '''
    <div providers>
      <span>Some content to create a range check on nodeIndex</span>
    </div>
    <div #container></div>
  ''',
)
class TestComponent {
  @ViewChild('container', read: ViewContainerRef)
  ViewContainerRef viewContainerRef;
}

const testToken = OpaqueToken<String>('test');
const tokenA = OpaqueToken<String>('a');
const tokenB = OpaqueToken<String>('b');

@Directive(
  selector: '[providers]',
  // Multiple providers to ensure the range check isn't skipped due to short
  // circuit evaluation of mismatched token query.
  providers: [
    ValueProvider.forToken(tokenA, 'a'),
    ValueProvider.forToken(tokenB, 'b'),
  ],
)
class ProvidersDirective {}
