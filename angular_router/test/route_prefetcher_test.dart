@TestOn('browser')
import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'route_prefetcher_test.template.dart' as ng;

void main() {
  NgTestBed<AppComponent> testBed;

  setUp(() {
    testBed = NgTestBed.forComponent(ng.AppComponentNgFactory)
        .addInjector(appInjector);
  });

  tearDown(disposeAnyRunningTest);

  test('should call prefetcher before route is initialized', () {
    AppComponent.routes = [
      RouteDefinition.defer(
        path: '/',
        loader: () async => ng.EmptyComponentNgFactory,
        prefetcher: expectAsync1((_) {}),
      ),
    ];
    return testBed.create();
  });

  test('should await prefetcher before route is initialized', () async {
    var prefetcherCompleter = Completer<void>();
    var prefetcherWasCalled = false;
    AppComponent.routes = [
      RouteDefinition.defer(
        path: '/',
        loader: () async => ng.EmptyComponentNgFactory,
        prefetcher: (_) {
          prefetcherWasCalled = true;
          return prefetcherCompleter.future;
        },
      ),
    ];
    var testFixture = await testBed.create();
    var router = testFixture.assertOnlyInstance.router;
    // Assert that initial navigation is awaiting prefetcher's result.
    expect(prefetcherWasCalled, true);
    expect(router.current, null);
    await testFixture.update(prefetcherCompleter.complete);
    // Assert that initial navigation is now complete.
    expect(
      router.current,
      TypeMatcher<RouterState>().having((s) => s.path, 'path', ''),
    );
  });

  test('should pass partial RouterState to prefetcher', () {
    AppComponent.routes = [
      RouteDefinition(
        path: '/foo/:fooId',
        component: ng.FooComponentNgFactory,
      ),
    ];
    FooComponent.routes = [
      RouteDefinition.defer(
        path: '/bar/:barId',
        loader: () async => ng.BarComponentNgFactory,
        prefetcher: expectAsync1((state) {
          // The prefetcher is called while matching this route, so we only know
          // what routes have matched so far (from the root matching route to
          // this one). So despite the fact that the navigation to
          // '/foo/bar/baz' will succeed in this case, at the time this is
          // invoked, we don't know about the matching nested route for '/baz'.
          expect(state.routes, [
            AppComponent.routes.first,
            FooComponent.routes.first,
          ]);
          expect(state.parameters, {'fooId': '1', 'barId': '2'});
          expect(state.fragment, 'qux',
              skip: 'Not correctly set by MockLocationStrategy (b/122484064)');
          expect(state.queryParameters, {'x': '12'});
        }),
      ),
    ];
    BarComponent.routes = [
      RouteDefinition(path: '/baz', component: ng.EmptyComponentNgFactory),
    ];
    return testBed.create(beforeComponentCreated: (injector) {
      injector.provideType<Location>(Location).go('/foo/1/bar/2/baz?x=12#qux');
    });
  });
}

@GenerateInjector(routerProvidersTest)
final appInjector = ng.appInjector$Injector;

@Component(
  selector: 'app',
  template: '<router-outlet [routes]="routes"></router-outlet>',
  directives: [RouterOutlet],
)
class AppComponent {
  static List<RouteDefinition> routes;

  final Router router;

  AppComponent(this.router);
}

@Component(
  selector: 'empty',
  template: '',
)
class EmptyComponent {}

@Component(
  selector: 'bar',
  template: '<router-outlet [routes]="routes"></router-outlet>',
  directives: [RouterOutlet],
)
class BarComponent {
  static List<RouteDefinition> routes;
}

@Component(
  selector: 'foo',
  template: '<router-outlet [routes]="routes"></router-outlet>',
  directives: [RouterOutlet],
)
class FooComponent {
  static List<RouteDefinition> routes;
}
