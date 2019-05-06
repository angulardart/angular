@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_test/angular_test.dart';

import 'revert_popstate_test.template.dart' as ng;

void main() {
  Location location;
  NgTestFixture<TestComponent> testFixture;
  Router router;
  TestRouterHook routerHook;

  setUp(() async {
    routerHook = TestRouterHook();
    final testBed = NgTestBed.forComponent(
      ng.TestComponentNgFactory,
      rootInjector: ([parent]) {
        return createInjector(Injector.map({RouterHook: routerHook}, parent));
      },
    );
    testFixture = await testBed.create(beforeComponentCreated: (injector) {
      location = injector.provideType(Location)..replaceState('/a');
      router = injector.provideType(Router);
    });
  });

  tearDown(disposeAnyRunningTest);

  // When a navigation triggered by a popstate event is prevented, updating the
  // browser location to match the active route should preserve the previous
  // browser history (rather than overwriting it).
  test('preventing back should preserve previous history', () async {
    // Navigate from /a -> /b.
    var result = await router.navigate('/b');
    expect(result, NavigationResult.SUCCESS);

    // Navigate from /b -> /c.
    result = await router.navigate('/c');
    expect(result, NavigationResult.SUCCESS);

    // Prevent navigation on back button.
    await testFixture.update((_) {
      routerHook.canLeave = false;
      location.back();
    });
    // Location should not have changed.
    expect(location.path(), '/c');

    // Allow navigation on back button.
    await testFixture.update((_) {
      routerHook.canLeave = true;
      location.back();
    });
    // Location should now be the correct previous history location.
    expect(location.path(), '/b');
  });
}

const testModule = Module(
  include: [routerModule],
  provide: [ValueProvider.forToken(appBaseHref, '/')],
);

@GenerateInjector.fromModules([testModule])
final createInjector = ng.createInjector$Injector;

@Component(
  selector: 'test',
  directives: [RouterOutlet],
  template: '''
    <router-outlet [routes]="routes"></router-outlet>
  ''',
)
class TestComponent {
  final routes = [
    RouteDefinition(
      path: '/a',
      component: ng.RouteComponentNgFactory,
    ),
    RouteDefinition(
      path: '/b',
      component: ng.RouteComponentNgFactory,
    ),
    RouteDefinition(
      path: '/c',
      component: ng.RouteComponentNgFactory,
    ),
  ];
}

@Component(
  selector: 'route',
  template: '',
)
class RouteComponent {}

class TestRouterHook extends RouterHook {
  var canLeave = true;

  @override
  Future<bool> canDeactivate(_, __, ___) => Future.value(canLeave);
}
