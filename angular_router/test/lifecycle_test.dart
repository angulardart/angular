@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_router/src/router/router_impl.dart';
import 'package:angular_test/angular_test.dart';

// ignore: uri_has_not_been_generated
import 'lifecycle_test.template.dart' as ng;

void main() {
  ng.initReflector();

  tearDown(disposeAnyRunningTest);

  // /first-child -> /second-child
  test('navigate to and from a sibling', () async {
    final fixture = await setup<TestNavigateToSibling>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstChildComponent.ngOnInit',
      '$FirstChildComponent.canActivate',
      '$FirstChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-child'), NavigationResult.SUCCESS);
    expect(log, [
      '$FirstChildComponent.canNavigate',
      '$SecondChildComponent.ngOnInit',
      '$FirstChildComponent.canDeactivate',
      '$SecondChildComponent.canActivate',
      '$FirstChildComponent.onDeactivate',
      '$FirstChildComponent.canReuse',
      '$FirstChildComponent.ngOnDestroy',
      '$SecondChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/first-child'), NavigationResult.SUCCESS);
    expect(log, [
      '$SecondChildComponent.canNavigate',
      '$FirstChildComponent.ngOnInit',
      '$SecondChildComponent.canDeactivate',
      '$FirstChildComponent.canActivate',
      '$SecondChildComponent.onDeactivate',
      '$SecondChildComponent.canReuse',
      '$SecondChildComponent.ngOnDestroy',
      '$FirstChildComponent.onActivate',
    ]);
  });

  // /first-reusable-child -> /second-child -> /first-reusable-child
  test('navigate from a reusable component to a sibling and back', () async {
    final fixture = await setup<TestNavigateToSiblingFromReusableChild>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstReusableChildComponent.ngOnInit',
      '$FirstReusableChildComponent.canActivate',
      '$FirstReusableChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-child'), NavigationResult.SUCCESS);
    expect(log, [
      '$FirstReusableChildComponent.canNavigate',
      '$SecondChildComponent.ngOnInit',
      '$FirstReusableChildComponent.canDeactivate',
      '$SecondChildComponent.canActivate',
      '$FirstReusableChildComponent.onDeactivate',
      '$FirstReusableChildComponent.canReuse',
      '$SecondChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/first-reusable-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$SecondChildComponent.canNavigate',
      '$SecondChildComponent.canDeactivate',
      '$FirstReusableChildComponent.canActivate',
      '$SecondChildComponent.onDeactivate',
      '$SecondChildComponent.canReuse',
      '$SecondChildComponent.ngOnDestroy',
      '$FirstReusableChildComponent.onActivate',
    ]);
  });

  // /parent/first-child -> /parent/second-child
  test('navigate to a nested sibling', () async {
    final fixture = await setup<TestNavigateToNestedSibling>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$ParentComponent.ngOnInit',
      '$FirstChildComponent.ngOnInit',
      '$ParentComponent.canActivate',
      '$FirstChildComponent.canActivate',
      '$ParentComponent.onActivate',
      '$FirstChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/parent/second-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$ParentComponent.canNavigate',
      '$FirstChildComponent.canNavigate',
      '$SecondChildComponent.ngOnInit',
      '$ParentComponent.canDeactivate',
      '$FirstChildComponent.canDeactivate',
      '$ParentComponent.canActivate',
      '$SecondChildComponent.canActivate',
      '$ParentComponent.onDeactivate',
      '$FirstChildComponent.onDeactivate',
      '$ParentComponent.canReuse',
      '$FirstChildComponent.ngOnDestroy',
      '$SecondChildComponent.ngOnDestroy',
      '$ParentComponent.ngOnDestroy',
      '$ParentComponent.ngOnInit',
      '$ParentComponent.onActivate',
      '$SecondChildComponent.ngOnInit',
      '$SecondChildComponent.onActivate',
    ]);
  });

  // /reusable-parent/first-child -> /reusable-parent/second-child
  test('navigate to a nested sibling with a reusable parent', () async {
    final fixture = await setup<TestNavigateToNestedSiblingWithSharedParent>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$ReusableParentComponent.ngOnInit',
      '$FirstChildComponent.ngOnInit',
      '$ReusableParentComponent.canActivate',
      '$FirstChildComponent.canActivate',
      '$ReusableParentComponent.onActivate',
      '$FirstChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/reusable-parent/second-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$ReusableParentComponent.canNavigate',
      '$FirstChildComponent.canNavigate',
      '$SecondChildComponent.ngOnInit',
      '$ReusableParentComponent.canDeactivate',
      '$FirstChildComponent.canDeactivate',
      '$ReusableParentComponent.canActivate',
      '$SecondChildComponent.canActivate',
      '$ReusableParentComponent.onDeactivate',
      '$FirstChildComponent.onDeactivate',
      '$ReusableParentComponent.canReuse',
      '$ReusableParentComponent.onActivate',
      '$FirstChildComponent.canReuse',
      '$FirstChildComponent.ngOnDestroy',
      '$SecondChildComponent.onActivate',
    ]);
  });

  // /first-parent/first-child -> /second-parent/second-child
  test('navigate between nested routes', () async {
    final fixture = await setup<TestNavigateBetweenNestedRoutes>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstParentComponent.ngOnInit',
      '$FirstChildComponent.ngOnInit',
      '$FirstParentComponent.canActivate',
      '$FirstChildComponent.canActivate',
      '$FirstParentComponent.onActivate',
      '$FirstChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-parent/second-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$FirstParentComponent.canNavigate',
      '$FirstChildComponent.canNavigate',
      '$SecondParentComponent.ngOnInit',
      '$SecondChildComponent.ngOnInit',
      '$FirstParentComponent.canDeactivate',
      '$FirstChildComponent.canDeactivate',
      '$SecondParentComponent.canActivate',
      '$SecondChildComponent.canActivate',
      '$FirstParentComponent.onDeactivate',
      '$FirstChildComponent.onDeactivate',
      '$FirstParentComponent.canReuse',
      '$FirstChildComponent.ngOnDestroy',
      '$FirstParentComponent.ngOnDestroy',
      '$SecondParentComponent.onActivate',
      '$SecondChildComponent.onActivate',
    ]);
  });

  // /first-reusable-parent/first-child -> /second-parent/second-child
  test('navigate between nested routes with a reusable parent', () async {
    final fixture =
        await setup<TestNavigateBetweenNestedRoutesWithReusableParent>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstReusableParentComponent.ngOnInit',
      '$FirstChildComponent.ngOnInit',
      '$FirstReusableParentComponent.canActivate',
      '$FirstChildComponent.canActivate',
      '$FirstReusableParentComponent.onActivate',
      '$FirstChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-parent/second-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$FirstReusableParentComponent.canNavigate',
      '$FirstChildComponent.canNavigate',
      '$SecondParentComponent.ngOnInit',
      '$SecondChildComponent.ngOnInit',
      '$FirstReusableParentComponent.canDeactivate',
      '$FirstChildComponent.canDeactivate',
      '$SecondParentComponent.canActivate',
      '$SecondChildComponent.canActivate',
      '$FirstReusableParentComponent.onDeactivate',
      '$FirstChildComponent.onDeactivate',
      '$FirstReusableParentComponent.canReuse',
      '$SecondParentComponent.onActivate',
      '$SecondChildComponent.onActivate',
    ]);
  });

  // /first-reusable-parent/first-child -> /second-reusable-parent/second-child
  //
  // The 'first-reusable-parent' and 'second-reusable-parent' routes actually
  // map to the same component factory, which should be reused.
  test('navigate between nested routes with the same reusable parent',
      () async {
    final fixture =
        await setup<TestNavigateBetweenNestedRoutesWithSameReusableParent>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$ReusableParentComponent.ngOnInit',
      '$FirstChildComponent.ngOnInit',
      '$ReusableParentComponent.canActivate',
      '$FirstChildComponent.canActivate',
      '$ReusableParentComponent.onActivate',
      '$FirstChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-reusable-parent/second-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$ReusableParentComponent.canNavigate',
      '$FirstChildComponent.canNavigate',
      '$SecondChildComponent.ngOnInit',
      '$ReusableParentComponent.canDeactivate',
      '$FirstChildComponent.canDeactivate',
      '$ReusableParentComponent.canActivate',
      '$SecondChildComponent.canActivate',
      '$ReusableParentComponent.onDeactivate',
      '$FirstChildComponent.onDeactivate',
      '$ReusableParentComponent.canReuse',
      '$ReusableParentComponent.onActivate',
      '$FirstChildComponent.canReuse',
      '$FirstChildComponent.ngOnDestroy',
      '$SecondChildComponent.onActivate',
    ]);
  });

  test('navigate to the same route should do nothing', () async {
    final fixture = await setup<TestNavigateToSibling>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstChildComponent.ngOnInit',
      '$FirstChildComponent.canActivate',
      '$FirstChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/'), NavigationResult.SUCCESS);
    expect(log, [
      '$FirstChildComponent.canNavigate',
    ]);
  });

  test('reload the same route', () async {
    final fixture = await setup<TestNavigateToSibling>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstChildComponent.ngOnInit',
      '$FirstChildComponent.canActivate',
      '$FirstChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/', new NavigationParams(reload: true)),
        NavigationResult.SUCCESS);
    expect(log, [
      '$FirstChildComponent.canNavigate',
      '$FirstChildComponent.canDeactivate',
      '$FirstChildComponent.canActivate',
      '$FirstChildComponent.onDeactivate',
      '$FirstChildComponent.canReuse',
      '$FirstChildComponent.ngOnDestroy',
      '$FirstChildComponent.ngOnInit',
      '$FirstChildComponent.onActivate'
    ]);
  });

  test('prevent navigation before other lifecycle callbacks', () async {
    final fixture = await setup<TestPreventNavigation>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$CantNavigateChildComponent.ngOnInit',
      '$CantNavigateChildComponent.canActivate',
      '$CantNavigateChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-child'),
        NavigationResult.BLOCKED_BY_GUARD);
    expect(log, [
      '$CantNavigateChildComponent.canNavigate',
    ]);
  });

  test('redirect to a sibling', () async {
    final fixture = await setup<TestRedirectToSibling>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstChildComponent.ngOnInit',
      '$FirstChildComponent.canActivate',
      '$FirstChildComponent.onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/foo'), NavigationResult.SUCCESS);
    expect(log, [
      '$FirstChildComponent.canNavigate',
      '$SecondChildComponent.ngOnInit',
      '$FirstChildComponent.canDeactivate',
      '$SecondChildComponent.canActivate',
      '$FirstChildComponent.onDeactivate',
      '$FirstChildComponent.canReuse',
      '$FirstChildComponent.ngOnDestroy',
      '$SecondChildComponent.onActivate',
    ]);
  });

  test('only match complete path segment', () async {
    final fixture = await setup<TestMatchCompletePathSegment>('/second-child');
    final log = fixture.assertOnlyInstance.lifecycleLog;
    // TODO(b/70224632): prevent initial `FirstChildComponent.ngOnInit`.
    expect(
        log,
        [
          '$SecondChildComponent.ngOnInit',
          '$SecondChildComponent.canActivate',
          '$SecondChildComponent.onActivate'
        ],
        skip: true);
  });
}

const lifecycleLogToken = const OpaqueToken('lifecycleLog');

Future<NgTestFixture<T>> setup<T>([String initialPath]) async {
  final location = new SpyLocation();
  if (initialPath != null) {
    location.setInitialPath(initialPath);
  }
  final testBed = new NgTestBed<T>().addProviders([
    new Provider(lifecycleLogToken, useValue: []),
    new Provider(Location, useValue: location),
    new Provider(Router, useClass: RouterImpl),
  ]);
  return testBed.create();
}

/// Records all lifecycle method invocations.
abstract class RouterLifecycleLogger
    implements
        CanActivate,
        CanDeactivate,
        CanNavigate,
        CanReuse,
        OnActivate,
        OnDeactivate,
        OnDestroy,
        OnInit {
  /// Unique name used to identify which component received a lifecycle call.
  String get componentName;

  /// An ordered list in which lifecycle invocations are recorded.
  List<String> get lifecycleLog;

  @override
  Future<bool> canActivate(_, __) async {
    lifecycleLog.add('$componentName.canActivate');
    return true;
  }

  @override
  Future<bool> canDeactivate(_, __) async {
    lifecycleLog.add('$componentName.canDeactivate');
    return true;
  }

  @override
  Future<bool> canNavigate() async {
    lifecycleLog.add('$componentName.canNavigate');
    return true;
  }

  @override
  Future<bool> canReuse(_, __) async {
    lifecycleLog.add('$componentName.canReuse');
    return false;
  }

  @override
  void onActivate(_, __) {
    lifecycleLog.add('$componentName.onActivate');
  }

  @override
  void onDeactivate(_, __) {
    lifecycleLog.add('$componentName.onDeactivate');
  }

  @override
  void ngOnDestroy() {
    lifecycleLog.add('$componentName.ngOnDestroy');
  }

  @override
  void ngOnInit() {
    lifecycleLog.add('$componentName.ngOnInit');
  }
}

@Component(
  selector: 'first-child',
  template: '',
)
class FirstChildComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = new RouteDefinition(
    path: 'first-child',
    component: ng.FirstChildComponentNgFactory,
    useAsDefault: true,
  );

  final String componentName = '$FirstChildComponent';
  final List<String> lifecycleLog;

  FirstChildComponent(@Inject(lifecycleLogToken) this.lifecycleLog);
}

@Component(
  selector: 'second-child',
  template: '',
)
class SecondChildComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = new RouteDefinition(
    path: 'second-child',
    component: ng.SecondChildComponentNgFactory,
  );

  final String componentName = '$SecondChildComponent';
  final List<String> lifecycleLog;

  SecondChildComponent(@Inject(lifecycleLogToken) this.lifecycleLog);
}

@Component(
  selector: 'first-child',
  template: '',
)
class FirstReusableChildComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = new RouteDefinition(
    path: 'first-reusable-child',
    component: ng.FirstReusableChildComponentNgFactory,
    useAsDefault: true,
  );

  final String componentName = '$FirstReusableChildComponent';
  final List<String> lifecycleLog;

  FirstReusableChildComponent(@Inject(lifecycleLogToken) this.lifecycleLog);

  @override
  Future<bool> canReuse(_, __) async {
    await super.canReuse(_, __);
    return true;
  }
}

@Component(
  selector: 'cant-navigate-child',
  template: '',
)
class CantNavigateChildComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = new RouteDefinition(
    path: 'cant-navigate-child',
    component: ng.CantNavigateChildComponentNgFactory,
    useAsDefault: true,
  );

  final String componentName = '$CantNavigateChildComponent';
  final List<String> lifecycleLog;

  CantNavigateChildComponent(@Inject(lifecycleLogToken) this.lifecycleLog);

  @override
  Future<bool> canNavigate() async {
    await super.canNavigate();
    return false;
  }
}

const testDirectives = const [RouterOutlet];
const testTemplate = '<router-outlet [routes]="routes"></router-outlet>';

@Component(
  selector: 'parent',
  template: testTemplate,
  directives: testDirectives,
)
class ParentComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = new RouteDefinition(
    path: 'parent',
    component: ng.ParentComponentNgFactory,
    useAsDefault: true,
  );

  final String componentName = '$ParentComponent';
  final List<String> lifecycleLog;
  final List<RouteDefinition> routes = [
    FirstChildComponent.routeDefinition,
    SecondChildComponent.routeDefinition,
  ];

  ParentComponent(@Inject(lifecycleLogToken) this.lifecycleLog);
}

@Component(
  selector: 'reusable-parent',
  template: testTemplate,
  directives: testDirectives,
)
class ReusableParentComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = new RouteDefinition(
    path: 'reusable-parent',
    component: ng.ReusableParentComponentNgFactory,
    useAsDefault: true,
  );

  final String componentName = '$ReusableParentComponent';
  final List<String> lifecycleLog;
  final List<RouteDefinition> routes = [
    FirstChildComponent.routeDefinition,
    SecondChildComponent.routeDefinition,
  ];

  ReusableParentComponent(@Inject(lifecycleLogToken) this.lifecycleLog);

  @override
  Future<bool> canReuse(_, __) async {
    await super.canReuse(_, __);
    return true;
  }
}

@Component(
  selector: 'first-parent',
  template: testTemplate,
  directives: testDirectives,
)
class FirstParentComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = new RouteDefinition(
    path: 'first-parent',
    component: ng.FirstParentComponentNgFactory,
    useAsDefault: true,
  );

  final String componentName = '$FirstParentComponent';
  final List<String> lifecycleLog;
  final List<RouteDefinition> routes = [
    FirstChildComponent.routeDefinition,
  ];

  FirstParentComponent(@Inject(lifecycleLogToken) this.lifecycleLog);
}

@Component(
  selector: 'second-parent',
  template: testTemplate,
  directives: testDirectives,
)
class SecondParentComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = new RouteDefinition(
    path: 'second-parent',
    component: ng.SecondParentComponentNgFactory,
  );

  final String componentName = '$SecondParentComponent';
  final List<String> lifecycleLog;
  final List<RouteDefinition> routes = [
    SecondChildComponent.routeDefinition,
  ];

  SecondParentComponent(@Inject(lifecycleLogToken) this.lifecycleLog);
}

@Component(
  selector: 'first-reusable-parent',
  template: testTemplate,
  directives: testDirectives,
)
class FirstReusableParentComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = new RouteDefinition(
    path: 'first-reusable-parent',
    component: ng.FirstReusableParentComponentNgFactory,
    useAsDefault: true,
  );

  final String componentName = '$FirstReusableParentComponent';
  final List<String> lifecycleLog;
  final List<RouteDefinition> routes = [
    FirstChildComponent.routeDefinition,
  ];

  FirstReusableParentComponent(@Inject(lifecycleLogToken) this.lifecycleLog);

  @override
  Future<bool> canReuse(_, __) async {
    await super.canReuse(_, __);
    return true;
  }
}

@Component(
  selector: 'test-navigate-to-sibling',
  template: testTemplate,
  directives: testDirectives,
)
class TestNavigateToSibling {
  final List<String> lifecycleLog;
  final Router router;
  final List<RouteDefinition> routes = [
    FirstChildComponent.routeDefinition,
    SecondChildComponent.routeDefinition,
  ];

  TestNavigateToSibling(
      @Inject(lifecycleLogToken) this.lifecycleLog, this.router);
}

@Component(
  selector: 'test-navigate-to-sibling-from-reusable-child',
  template: testTemplate,
  directives: testDirectives,
)
class TestNavigateToSiblingFromReusableChild {
  final List<String> lifecycleLog;
  final Router router;
  final List<RouteDefinition> routes = [
    FirstReusableChildComponent.routeDefinition,
    SecondChildComponent.routeDefinition,
  ];

  TestNavigateToSiblingFromReusableChild(
      @Inject(lifecycleLogToken) this.lifecycleLog, this.router);
}

@Component(
  selector: 'test-navigate-to-nested-sibling',
  template: testTemplate,
  directives: testDirectives,
)
class TestNavigateToNestedSibling {
  final List<String> lifecycleLog;
  final Router router;
  final List<RouteDefinition> routes = [
    ParentComponent.routeDefinition,
  ];

  TestNavigateToNestedSibling(
      @Inject(lifecycleLogToken) this.lifecycleLog, this.router);
}

@Component(
  selector: 'test-navigate-to-nested-sibling-with-shared-parent',
  template: testTemplate,
  directives: testDirectives,
)
class TestNavigateToNestedSiblingWithSharedParent {
  final List<String> lifecycleLog;
  final Router router;
  final List<RouteDefinition> routes = [
    ReusableParentComponent.routeDefinition,
  ];

  TestNavigateToNestedSiblingWithSharedParent(
      @Inject(lifecycleLogToken) this.lifecycleLog, this.router);
}

@Component(
  selector: 'test-navigate-between-nested-routes',
  template: testTemplate,
  directives: testDirectives,
)
class TestNavigateBetweenNestedRoutes {
  final List<String> lifecycleLog;
  final Router router;
  final List<RouteDefinition> routes = [
    FirstParentComponent.routeDefinition,
    SecondParentComponent.routeDefinition,
  ];

  TestNavigateBetweenNestedRoutes(
      @Inject(lifecycleLogToken) this.lifecycleLog, this.router);
}

@Component(
  selector: 'test-navigate-between-nested-routes-with-reusable-parent',
  template: testTemplate,
  directives: testDirectives,
)
class TestNavigateBetweenNestedRoutesWithReusableParent {
  final List<String> lifecycleLog;
  final Router router;
  final List<RouteDefinition> routes = [
    FirstReusableParentComponent.routeDefinition,
    SecondParentComponent.routeDefinition,
  ];

  TestNavigateBetweenNestedRoutesWithReusableParent(
      @Inject(lifecycleLogToken) this.lifecycleLog, this.router);
}

@Component(
  selector: 'test-navigate-between-nested-routes-with-same-reusable-parent',
  template: testTemplate,
  directives: testDirectives,
)
class TestNavigateBetweenNestedRoutesWithSameReusableParent {
  final List<String> lifecycleLog;
  final Router router;
  final List<RouteDefinition> routes = [
    new RouteDefinition(
      path: 'first-reusable-parent',
      component: ng.ReusableParentComponentNgFactory,
      useAsDefault: true,
    ),
    new RouteDefinition(
      path: 'second-reusable-parent',
      component: ng.ReusableParentComponentNgFactory,
    ),
  ];

  TestNavigateBetweenNestedRoutesWithSameReusableParent(
      @Inject(lifecycleLogToken) this.lifecycleLog, this.router);
}

@Component(
  selector: 'test-prevent-navigation',
  template: testTemplate,
  directives: testDirectives,
)
class TestPreventNavigation {
  final List<String> lifecycleLog;
  final Router router;
  final List<RouteDefinition> routes = [
    CantNavigateChildComponent.routeDefinition,
    SecondChildComponent.routeDefinition,
  ];

  TestPreventNavigation(
      @Inject(lifecycleLogToken) this.lifecycleLog, this.router);
}

@Component(
  selector: 'test-redirect-to-sibiling',
  template: testTemplate,
  directives: testDirectives,
)
class TestRedirectToSibling {
  final List<String> lifecycleLog;
  final Router router;
  final List<RouteDefinition> routes = [
    FirstChildComponent.routeDefinition,
    SecondChildComponent.routeDefinition,
    new RouteDefinition.redirect(
      path: '.+',
      redirectTo: SecondChildComponent.routeDefinition.path,
    ),
  ];

  TestRedirectToSibling(
      @Inject(lifecycleLogToken) this.lifecycleLog, this.router);
}

@Component(
  selector: 'test-match-complete-path-segment',
  template: testTemplate,
  directives: testDirectives,
)
class TestMatchCompletePathSegment {
  final List<String> lifecycleLog;
  final Router router;
  final List<RouteDefinition> routes = [
    new RouteDefinition(path: '', component: ng.FirstChildComponentNgFactory),
    SecondChildComponent.routeDefinition,
  ];

  TestMatchCompletePathSegment(
      @Inject(lifecycleLogToken) this.lifecycleLog, this.router);
}
