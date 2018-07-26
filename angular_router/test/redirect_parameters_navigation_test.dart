@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';

import 'redirect_parameters_navigation_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('redirect should preserve parameters', () async {
    final urlChanges = await redirect('/from/1');
    expect(urlChanges, ['/to/1']);
  });

  test('redirect should discard extra parameters', () async {
    final urlChanges = await redirect('/from/1/2');
    expect(urlChanges, ['/to/1']);
  });
}

/// Performs a navigation that should be redirected.
/// Returns any URL changes that occurred due to navigation.
Future<List<String>> redirect(String from) async {
  final testBed = NgTestBed.forComponent(ng.TestRedirectComponentNgFactory)
      .addInjector(injector);
  final testFixture = await testBed.create();
  final urlChanges = testFixture.assertOnlyInstance.locationStrategy.urlChanges;
  final router = testFixture.assertOnlyInstance.router;
  final result = await router.navigate(from);
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
    RouteDefinition(path: '/to/:id', component: ng.ToComponentNgFactory),
    RouteDefinition.redirect(path: '/from/:id', redirectTo: '/to/:id'),
    RouteDefinition.redirect(path: '/from/:id/:id2', redirectTo: '/to/:id'),
  ];

  final MockLocationStrategy locationStrategy;
  final Router router;

  TestRedirectComponent(
    @Inject(LocationStrategy) this.locationStrategy,
    this.router,
  );
}
