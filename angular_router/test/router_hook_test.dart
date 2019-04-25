@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';

import 'router_hook_test.template.dart' as ng;

void main() {
  group('RouterHook', () {
    Router router;

    setUp(() async {
      final testBed = NgTestBed.forComponent(ng.TestAppComponentNgFactory)
          .addInjector(createInjector);
      final testFixture = await testBed.create();
      router = testFixture.assertOnlyInstance.router;
    });

    tearDown(() {
      disposeAnyRunningTest();
      testRouterHook.reset();
    });

    test('canActivate should block navigation', () async {
      testRouterHook.canActivateFn = (_, __, newState) async {
        // Block navigation to '/foo' route.
        return newState.path != TestAppComponent.fooPath;
      };
      final navigationResult = await router.navigate(TestAppComponent.fooPath);
      expect(navigationResult, NavigationResult.BLOCKED_BY_GUARD);
    });

    test('canDeactivate should block navigation', () async {
      testRouterHook.canDeactivateFn = (_, oldState, __) async {
        // Block navigation away from index route.
        return oldState.path != TestAppComponent.indexPath;
      };
      final navigationResult = await router.navigate(TestAppComponent.fooPath);
      expect(navigationResult, NavigationResult.BLOCKED_BY_GUARD);
    });

    test('canNavigate should block navigation', () async {
      testRouterHook.canNavigateFn = () async {
        // Block navigation.
        return false;
      };
      final navigationResult = await router.navigate(TestAppComponent.fooPath);
      expect(navigationResult, NavigationResult.BLOCKED_BY_GUARD);
    });

    test('canReuse should allow reuse', () async {
      testRouterHook.canReuseFn = (_, oldState, ___) async {
        // Reuse component instance of index route.
        return oldState.path == TestAppComponent.indexPath;
      };
      final navigationResult = await router.navigate(TestAppComponent.fooPath);
      expect(navigationResult, NavigationResult.SUCCESS);
      // The index route instance should have been cached for reuse, rather than
      // destroyed.
      expect(IndexComponent.instanceCount, 1);
    });
  });

  test('can support cyclic dependency with lazy injection', () async {
    final testBed = NgTestBed.forComponent(ng.TestAppComponentNgFactory)
        .addInjector(accumulateQueryHookInjector);
    final testFixture = await testBed.create();
    final router = testFixture.assertOnlyInstance.router;
    expect(router.current.queryParameters, isEmpty);
    var navigationResult = await router.navigate(
        '/foo', NavigationParams(queryParameters: {'a': 'b'}));
    expect(navigationResult, NavigationResult.SUCCESS);
    expect(router.current.queryParameters, {'a': 'b'});
    // Router hook should combine new query parameters with existing ones.
    navigationResult = await router.navigate(
        '/foo', NavigationParams(queryParameters: {'x': 'y'}));
    expect(navigationResult, NavigationResult.SUCCESS);
    expect(router.current.queryParameters, {'a': 'b', 'x': 'y'});
  });
}

@GenerateInjector([
  routerProvidersTest,
  FactoryProvider(RouterHook, routerHookFactory),
])
final createInjector = ng.createInjector$Injector;
final testRouterHook = TestRouterHook();

RouterHook routerHookFactory() => testRouterHook;

@Component(
  selector: 'test-app',
  template: '<router-outlet [routes]="routes"></router-outlet>',
  directives: [RouterOutlet],
)
class TestAppComponent {
  static final fooPath = '/foo';
  static final indexPath = '';
  static final routes = [
    RouteDefinition(path: fooPath, component: ng.FooComponentNgFactory),
    RouteDefinition(path: indexPath, component: ng.IndexComponentNgFactory),
  ];
  final Router router;

  TestAppComponent(this.router);
}

@Component(selector: 'foo', template: '')
class FooComponent {}

@Component(selector: 'index', template: '')
class IndexComponent implements OnInit, OnDestroy {
  /// Tracks the number of active or cached instances of this component.
  static var instanceCount = 0;

  @override
  void ngOnInit() {
    ++instanceCount;
  }

  @override
  void ngOnDestroy() {
    --instanceCount;
  }
}

typedef NavigationGuard = Future<bool> Function(
  Object,
  RouterState,
  RouterState,
);

class TestRouterHook extends RouterHook {
  NavigationGuard canActivateFn;
  NavigationGuard canDeactivateFn;
  Future<bool> Function() canNavigateFn;
  NavigationGuard canReuseFn;

  @override
  Future<bool> canActivate(
    Object componentInstance,
    RouterState oldState,
    RouterState newState,
  ) {
    return canActivateFn != null
        ? canActivateFn(componentInstance, oldState, newState)
        : super.canActivate(componentInstance, oldState, newState);
  }

  @override
  Future<bool> canDeactivate(
    Object componentInstance,
    RouterState oldState,
    RouterState newState,
  ) {
    return canDeactivateFn != null
        ? canDeactivateFn(componentInstance, oldState, newState)
        : super.canDeactivate(componentInstance, oldState, newState);
  }

  @override
  Future<bool> canNavigate() {
    return canNavigateFn != null ? canNavigateFn() : super.canNavigate();
  }

  @override
  Future<bool> canReuse(
    Object componentInstance,
    RouterState oldState,
    RouterState newState,
  ) {
    return canReuseFn != null
        ? canReuseFn(componentInstance, oldState, newState)
        : super.canReuse(componentInstance, oldState, newState);
  }

  void reset() {
    canActivateFn = null;
    canDeactivateFn = null;
    canNavigateFn = null;
    canReuseFn = null;
  }
}

@GenerateInjector([
  ClassProvider(RouterHook, useClass: AccumulateQueryHook),
  routerProvidersTest,
])
final accumulateQueryHookInjector = ng.accumulateQueryHookInjector$Injector;

class AccumulateQueryHook extends RouterHook {
  AccumulateQueryHook(this._injector);

  final Injector _injector;

  // Lazily inject `Router` to avoid cyclic dependency.
  Router _router;
  Router get router => _router ??= _injector.provideType(Router);

  @override
  Future<NavigationParams> navigationParams(String _, NavigationParams params) {
    return Future.value(NavigationParams(
      queryParameters: {
        ...?router.current?.queryParameters,
        ...params.queryParameters,
      },
    ));
  }
}
