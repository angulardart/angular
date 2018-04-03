@TestOn('browser')
import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

// ignore: uri_has_not_been_generated
import 'navigation_queue_test.template.dart' as ng;

const firstToken = const OpaqueToken<Future<Null>>('first');
const secondToken = const OpaqueToken<Future<Null>>('second');
const thirdToken = const OpaqueToken<Future<Null>>('third');

void main() {
  tearDown(disposeAnyRunningTest);

  test('navigation should complete in requested order', () async {
    // These are used to delay route activation guards.
    final firstCompleter = new Completer<Null>();
    final secondCompleter = new Completer<Null>();
    final thirdCompleter = new Completer<Null>();

    final testBed = new NgTestBed<TestComponent>().addProviders([
      routerProvidersTest,
      new ValueProvider.forToken(firstToken, firstCompleter.future),
      new ValueProvider.forToken(secondToken, secondCompleter.future),
      new ValueProvider.forToken(thirdToken, thirdCompleter.future),
    ]);

    final testFixture = await testBed.create();
    final router = testFixture.assertOnlyInstance.router;
    final requests = router.onRouteActivated.map((state) => state.path);

    router.navigate('/first');
    router.navigate('/second');
    router.navigate('/third');

    // Expect navigation to complete in order requested.
    expect(requests, emitsInOrder(['/first', '/second', '/third']));

    // Allow activation in reverse order. It's necessary to complete these
    // activations in multiple events loops, to ensure the activation guards
    // are checked incrementally as each activation is allowed. If all
    // activations are permitted in the same event loop, the pending awaited
    // activation guards will execute in the original order.
    thirdCompleter.complete();
    new Future(secondCompleter.complete);
    new Future(firstCompleter.complete);
  });
}

@Component(
  selector: 'test',
  template: '<router-outlet [routes]="routes"></router-outlet>',
  directives: const [RouterOutlet],
)
class TestComponent {
  final Router router;
  final List<RouteDefinition> routes = [
    new RouteDefinition(
      path: '/first',
      component: ng.FirstComponentNgFactory,
    ),
    new RouteDefinition(
      path: '/second',
      component: ng.SecondComponentNgFactory,
    ),
    new RouteDefinition(
      path: '/third',
      component: ng.ThirdComponentNgFactory,
    ),
    new RouteDefinition(
      path: '/',
      component: ng.DefaultComponentNgFactory,
      useAsDefault: true,
    ),
  ];

  TestComponent(this.router);
}

@Component(selector: 'default', template: 'Default')
class DefaultComponent {}

abstract class DelayedActivation implements CanActivate {
  final Future<Null> _future;

  DelayedActivation(this._future);

  @override
  Future<bool> canActivate(_, __) => _future.then((_) => true);
}

@Component(selector: 'first', template: 'First')
class FirstComponent extends DelayedActivation {
  FirstComponent(@firstToken Future<Null> future) : super(future);
}

@Component(selector: 'second', template: 'Second')
class SecondComponent extends DelayedActivation {
  SecondComponent(@secondToken Future<Null> future) : super(future);
}

@Component(selector: 'third', template: 'Third')
class ThirdComponent extends DelayedActivation {
  ThirdComponent(@thirdToken Future<Null> future) : super(future);
}
