@TestOn('browser')
import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';

// ignore: uri_has_not_been_generated
import 'navigation_queue_test.template.dart' as ng;

const firstToken = OpaqueToken<Future<Null>>('first');
const secondToken = OpaqueToken<Future<Null>>('second');
const thirdToken = OpaqueToken<Future<Null>>('third');

void main() {
  ng.initReflector();

  tearDown(disposeAnyRunningTest);

  test('navigation should complete in requested order', () async {
    // These are used to delay route activation guards.
    final firstCompleter = Completer<Null>();
    final secondCompleter = Completer<Null>();
    final thirdCompleter = Completer<Null>();

    final testBed = NgTestBed<TestComponent>().addProviders([
      routerProvidersTest,
      ValueProvider.forToken(firstToken, firstCompleter.future),
      ValueProvider.forToken(secondToken, secondCompleter.future),
      ValueProvider.forToken(thirdToken, thirdCompleter.future),
    ]);

    final testFixture = await testBed.create();
    final router = testFixture.assertOnlyInstance.router;
    final requests = router.onRouteActivated.map((state) => state.path);

    unawaited(router.navigate('/first'));
    unawaited(router.navigate('/second'));
    unawaited(router.navigate('/third'));

    // Expect navigation to complete in order requested.
    expect(requests, emitsInOrder(['/first', '/second', '/third']));

    // Allow activation in reverse order. It's necessary to complete these
    // activations in multiple events loops, to ensure the activation guards
    // are checked incrementally as each activation is allowed. If all
    // activations are permitted in the same event loop, the pending awaited
    // activation guards will execute in the original order.
    thirdCompleter.complete();
    unawaited(Future(secondCompleter.complete));
    unawaited(Future(firstCompleter.complete));
  });
}

@Component(
  selector: 'test',
  template: '<router-outlet [routes]="routes"></router-outlet>',
  directives: [RouterOutlet],
)
class TestComponent {
  final Router router;
  final List<RouteDefinition> routes = [
    RouteDefinition(
      path: '/first',
      component: ng.FirstComponentNgFactory,
    ),
    RouteDefinition(
      path: '/second',
      component: ng.SecondComponentNgFactory,
    ),
    RouteDefinition(
      path: '/third',
      component: ng.ThirdComponentNgFactory,
    ),
    RouteDefinition(
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
