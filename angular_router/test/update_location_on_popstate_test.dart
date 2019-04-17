@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';

import 'update_location_on_popstate_test.template.dart' as ng;

void main() {
  Location location;
  MockLocationStrategy locationStrategy;
  NgTestFixture<AppComponent> testFixture;

  setUp(() async {
    final testBed = NgTestBed.forComponent(
      ng.AppComponentNgFactory,
      rootInjector: createInjector,
    );
    testFixture = await testBed.create(beforeComponentCreated: (injector) {
      location = injector.provideType(Location);
      locationStrategy =
          injector.provideType(LocationStrategy) as MockLocationStrategy;
    });
  });

  tearDown(disposeAnyRunningTest);

  test('redirect triggered by "popstate" should update location', () async {
    await testFixture.update((_) {
      locationStrategy.simulatePopState('/redirect-from');
    });

    expect(location.path(), '/redirect-to');
  });

  test(
      'redirect to current location triggered by "popstate" should update '
      'location', () async {
    await testFixture.update((_) {
      locationStrategy.simulatePopState('/redirect-to');
    });

    expect(location.path(), '/redirect-to');

    await testFixture.update((_) {
      locationStrategy.simulatePopState('/redirect-from');
    });

    expect(location.path(), '/redirect-to');
  });

  test('router hook triggered by "popstate" should update location', () async {
    await testFixture.update((_) {
      locationStrategy.simulatePopState('/rewrite-from');
    });

    expect(location.path(), '/rewrite-to');
  });
}

const testModule = Module(
  include: [routerTestModule],
  provide: [ClassProvider(RouterHook, useClass: TestRouterHook)],
);

@GenerateInjector.fromModules([testModule])
final createInjector = ng.createInjector$Injector;

@Component(
  selector: 'app',
  directives: [RouterOutlet],
  template: '''
    <router-outlet [routes]="routes"></router-outlet>
  ''',
)
class AppComponent {
  final routes = [
    RouteDefinition(
      path: '',
      component: ng.RouteComponentNgFactory,
    ),
    RouteDefinition.redirect(
      path: '/redirect-from',
      redirectTo: '/redirect-to',
    ),
    RouteDefinition(
      path: '/redirect-to',
      component: ng.RouteComponentNgFactory,
    ),
    RouteDefinition(
      path: '/rewrite-to',
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
  Future<String> navigationPath(String path, NavigationParams params) =>
      Future.value(path == '/rewrite-from' ? 'rewrite-to' : path);
}
