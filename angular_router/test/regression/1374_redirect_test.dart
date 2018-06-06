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
    expect(urlChanges.single, '/redirect-to');
  });

  test('redirect should replace state', () async {
    final params = new NavigationParams(replace: true);
    final urlChanges = await redirect(params);
    expect(urlChanges.single, 'replace: /redirect-to');
  });

  test("redirect shouldn't update URL", () async {
    final params = new NavigationParams(updateUrl: false);
    final urlChanges = await redirect(params);
    expect(urlChanges, isEmpty);
  });
}

/// Performs a navigation that should be redirected with [params].
///
/// Returns any URL changes that occurred due to navigation.
Future<List<String>> redirect([NavigationParams params]) async {
  final testBed = NgTestBed
      .forComponent<TestComponent>(ng.TestComponentNgFactory)
      .addInjector(injector);
  final testFixture = await testBed.create();
  final router = testFixture.assertOnlyInstance.router;
  final result = await router.navigate('/redirect-from', params);
  expect(result, NavigationResult.SUCCESS);
  return testFixture.assertOnlyInstance.locationStrategy.urlChanges;
}

@GenerateInjector(routerProvidersTest)
InjectorFactory injector = ng.injector$Injector;

@Component(
  selector: 'redirect-to',
  template: '',
)
class RedirectToComponent {}

@Component(
  selector: 'test',
  template: '<router-outlet [routes]="routes"></router-outlet>',
  directives: const [RouterOutlet],
)
class TestComponent {
  static final routes = [
    new RouteDefinition(
      path: '/redirect-to',
      component: ng.RedirectToComponentNgFactory,
    ),
    new RouteDefinition.redirect(
      path: '/redirect-from',
      redirectTo: '/redirect-to',
    ),
  ];

  final MockLocationStrategy locationStrategy;
  final Router router;

  TestComponent(@Inject(LocationStrategy) this.locationStrategy, this.router);
}
