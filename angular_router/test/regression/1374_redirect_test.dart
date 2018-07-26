@TestOn('browser')
import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import '1374_redirect_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('redirect should push new state', () async {
    final urlChanges = await redirect();
    expect(urlChanges, ['/to']);
  });

  test('redirect should replace state', () async {
    final params = NavigationParams(replace: true);
    final urlChanges = await redirect(params);
    expect(urlChanges, ['replace: /to']);
  });

  test("redirect shouldn't update URL", () async {
    final params = NavigationParams(updateUrl: false);
    final urlChanges = await redirect(params);
    expect(urlChanges, isEmpty);
  });

  test('redirect on outlet registration should replace URL', () async {
    final testBed =
        NgTestBed.forComponent(ng.TestInitialRedirectComponentNgFactory)
            .addInjector(injector);
    final testFixture = await testBed.create();
    final locationStrategy = testFixture.assertOnlyInstance.locationStrategy;
    expect(locationStrategy.urlChanges, ['replace: /to']);
  });
}

/// Performs a navigation that should be redirected with [params].
///
/// Returns any URL changes that occurred due to navigation.
Future<List<String>> redirect([NavigationParams params]) async {
  final testBed = NgTestBed.forComponent(ng.TestRedirectComponentNgFactory)
      .addInjector(injector);
  final testFixture = await testBed.create();
  final urlChanges = testFixture.assertOnlyInstance.locationStrategy.urlChanges;
  final router = testFixture.assertOnlyInstance.router;
  final result = await router.navigate('/from', params);
  expect(result, NavigationResult.SUCCESS);
  return urlChanges;
}

@GenerateInjector(routerProvidersTest)
InjectorFactory injector = ng.injector$Injector;

@Component(selector: 'to', template: '')
class ToComponent {}

@Component(
  selector: 'test',
  template: '<router-outlet [routes]="routes"></router-outlet>',
  directives: [RouterOutlet],
)
class TestRedirectComponent {
  static final routes = [
    RouteDefinition(path: '/to', component: ng.ToComponentNgFactory),
    RouteDefinition.redirect(path: '/from', redirectTo: '/to'),
  ];

  final MockLocationStrategy locationStrategy;
  final Router router;

  TestRedirectComponent(
    @Inject(LocationStrategy) this.locationStrategy,
    this.router,
  );
}

@Component(
  selector: 'test',
  template: '<router-outlet [routes]="routes"></router-outlet>',
  directives: [RouterOutlet],
)
class TestInitialRedirectComponent {
  static final routes = [
    RouteDefinition(path: '/to', component: ng.ToComponentNgFactory),
    RouteDefinition.redirect(path: '/.*', redirectTo: '/to'),
  ];

  final MockLocationStrategy locationStrategy;
  final Router router;

  TestInitialRedirectComponent(
    @Inject(LocationStrategy) this.locationStrategy,
    this.router,
  );
}
