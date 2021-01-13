import 'package:async/async.dart' show StreamGroup;
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';

// ingore: uri_has_not_been_generated
import 'on_route_resolved_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('Router.onRouteResolved', () {
    test('fires on navigation', () async {
      final testBed = NgTestBed(
        ng.createTestComponentFactory(),
      );
      final testFixture = await testBed.create();
      final router = testFixture.assertOnlyInstance.router;
      await expectLater(
        navigate(router, '/destination'),
        emitsInOrder([
          '#RouterState {/destination} popstate:false',
          NavigationResult.SUCCESS,
        ]),
      );
    });

    test("doesn't fire when navigation is prohibited", () async {
      final testBed = NgTestBed(
        ng.createTestComponentFactory(),
      ).addInjector((i) => Injector.map({canNavigateToken: false}, i));
      final testFixture = await testBed.create();
      final router = testFixture.assertOnlyInstance.router;
      await expectLater(
        navigate(router, '/destination'),
        emits(NavigationResult.BLOCKED_BY_GUARD),
      );
    });

    test('fires when deactivation is prohibited', () async {
      final testBed = NgTestBed(
        ng.createTestComponentFactory(),
      ).addInjector((i) => Injector.map({canDeactivateToken: false}, i));
      final testFixture = await testBed.create();
      final router = testFixture.assertOnlyInstance.router;
      await expectLater(
        navigate(router, '/destination'),
        emitsInOrder([
          '#RouterState {/destination} popstate:false',
          NavigationResult.BLOCKED_BY_GUARD,
        ]),
      );
    });

    test('fires on popstate', () async {
      final testBed = NgTestBed(
        ng.createTestComponentFactory(),
      );
      final testFixture = await testBed.create();
      final router = testFixture.assertOnlyInstance.router;
      final locationStrategy = testFixture.assertOnlyInstance.locationStrategy;
      await expectLater(
        popState(router, locationStrategy, '/destination'),
        emits('#RouterState {/destination} popstate:true'),
      );
    });

    test('fires only once on redirect', () async {
      final testBed = NgTestBed(
        ng.createTestComponentFactory(),
      );
      final testFixture = await testBed.create();
      final router = testFixture.assertOnlyInstance.router;
      await expectLater(
        navigate(router, '/redirection'),
        emitsInOrder([
          '#RouterState {/destination} popstate:false',
          NavigationResult.SUCCESS,
        ]),
      );
    });
  });
}

Stream<String> onRouteResolved(Router router) => router.onRouteResolved
    .map((state) => '$state popstate:${state.fromPopState}');

Stream<dynamic> navigate(Router router, String path) => StreamGroup.merge([
      onRouteResolved(router),
      router.navigate(path).asStream(),
    ]);

Stream<String> popState(
    Router router, LocationStrategy locationStrategy, String url) {
  final stream = onRouteResolved(router);
  (locationStrategy as MockLocationStrategy).simulatePopState(url);
  return stream;
}

const canDeactivateToken = OpaqueToken<bool>('canDeactivateToken');
const canNavigateToken = OpaqueToken<bool>('canNavigateToken');

@Component(
  selector: 'home',
  template: '',
)
class HomeComponent implements CanDeactivate, CanNavigate {
  final bool _canDeactivate;
  final bool _canNavigate;

  HomeComponent(
    @Optional() @Inject(canDeactivateToken) bool? canDeactivate,
    @Optional() @Inject(canNavigateToken) bool? canNavigate,
  )   : _canDeactivate = canDeactivate ?? true,
        _canNavigate = canNavigate ?? true;

  @override
  Future<bool> canDeactivate(_, __) => Future.value(_canDeactivate);

  @override
  Future<bool> canNavigate() => Future.value(_canNavigate);
}

@Component(
  selector: 'destination',
  template: '',
)
class DestinationComponent {}

@Component(
  selector: 'test',
  template: '<router-outlet [routes]="routes"></router-outlet>',
  directives: [RouterOutlet],
  providers: [routerProvidersTest],
)
class TestComponent {
  final Router router;
  final LocationStrategy locationStrategy;
  final List<RouteDefinition> routes = [
    RouteDefinition(
      path: 'home',
      component: ng.createHomeComponentFactory(),
      useAsDefault: true,
    ),
    RouteDefinition(
      path: 'destination',
      component: ng.createDestinationComponentFactory(),
    ),
    RouteDefinition.redirect(
      path: 'redirection',
      redirectTo: 'destination',
    ),
  ];

  TestComponent(this.router, this.locationStrategy);
}
