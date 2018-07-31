@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
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
      '$FirstChildComponent[0].ngOnInit',
      '$FirstChildComponent[0].canActivate',
      '$FirstChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-child'), NavigationResult.SUCCESS);
    expect(log, [
      '$FirstChildComponent[0].canNavigate',
      '$SecondChildComponent[0].ngOnInit',
      '$FirstChildComponent[0].canDeactivate',
      '$SecondChildComponent[0].canActivate',
      '$FirstChildComponent[0].onDeactivate',
      '$FirstChildComponent[0].canReuse',
      '$FirstChildComponent[0].ngOnDestroy',
      '$SecondChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/first-child'), NavigationResult.SUCCESS);
    expect(log, [
      '$SecondChildComponent[0].canNavigate',
      '$FirstChildComponent[1].ngOnInit',
      '$SecondChildComponent[0].canDeactivate',
      '$FirstChildComponent[1].canActivate',
      '$SecondChildComponent[0].onDeactivate',
      '$SecondChildComponent[0].canReuse',
      '$SecondChildComponent[0].ngOnDestroy',
      '$FirstChildComponent[1].onActivate',
    ]);
  });

  // /first-reusable-child -> /second-child -> /first-reusable-child
  test('navigate from a reusable component to a sibling and back', () async {
    final fixture = await setup<TestNavigateToSiblingFromReusableChild>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstReusableChildComponent[0].ngOnInit',
      '$FirstReusableChildComponent[0].canActivate',
      '$FirstReusableChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-child'), NavigationResult.SUCCESS);
    expect(log, [
      '$FirstReusableChildComponent[0].canNavigate',
      '$SecondChildComponent[0].ngOnInit',
      '$FirstReusableChildComponent[0].canDeactivate',
      '$SecondChildComponent[0].canActivate',
      '$FirstReusableChildComponent[0].onDeactivate',
      '$FirstReusableChildComponent[0].canReuse',
      '$SecondChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/first-reusable-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$SecondChildComponent[0].canNavigate',
      '$SecondChildComponent[0].canDeactivate',
      '$FirstReusableChildComponent[0].canActivate',
      '$SecondChildComponent[0].onDeactivate',
      '$SecondChildComponent[0].canReuse',
      '$SecondChildComponent[0].ngOnDestroy',
      '$FirstReusableChildComponent[0].onActivate',
    ]);
  });

  // /parent/first-child -> /parent/second-child -> /parent/first-child
  test('navigate to a nested sibling and back', () async {
    final fixture = await setup<TestNavigateToNestedSibling>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$ParentComponent[0].ngOnInit',
      '$FirstChildComponent[0].ngOnInit',
      '$ParentComponent[0].canActivate',
      '$FirstChildComponent[0].canActivate',
      '$ParentComponent[0].onActivate',
      '$FirstChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/parent/second-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$ParentComponent[0].canNavigate',
      '$FirstChildComponent[0].canNavigate',
      '$SecondChildComponent[0].ngOnInit',
      '$ParentComponent[0].canDeactivate',
      '$FirstChildComponent[0].canDeactivate',
      '$ParentComponent[0].canActivate',
      '$SecondChildComponent[0].canActivate',
      '$ParentComponent[0].onDeactivate',
      '$FirstChildComponent[0].onDeactivate',
      '$ParentComponent[0].canReuse',
      '$FirstChildComponent[0].ngOnDestroy',
      '$SecondChildComponent[0].ngOnDestroy',
      '$ParentComponent[0].ngOnDestroy',
      '$ParentComponent[1].ngOnInit',
      '$ParentComponent[1].onActivate',
      '$SecondChildComponent[1].ngOnInit',
      '$SecondChildComponent[1].onActivate',
    ]);
    log.clear();
    expect(
        await router.navigate('/parent/first-child'), NavigationResult.SUCCESS);
    expect(log, [
      '$ParentComponent[1].canNavigate',
      '$SecondChildComponent[1].canNavigate',
      '$FirstChildComponent[1].ngOnInit',
      '$ParentComponent[1].canDeactivate',
      '$SecondChildComponent[1].canDeactivate',
      '$ParentComponent[1].canActivate',
      '$FirstChildComponent[1].canActivate',
      '$ParentComponent[1].onDeactivate',
      '$SecondChildComponent[1].onDeactivate',
      '$ParentComponent[1].canReuse',
      '$SecondChildComponent[1].ngOnDestroy',
      '$FirstChildComponent[1].ngOnDestroy',
      '$ParentComponent[1].ngOnDestroy',
      '$ParentComponent[2].ngOnInit',
      '$ParentComponent[2].onActivate',
      '$FirstChildComponent[2].ngOnInit',
      '$FirstChildComponent[2].onActivate',
    ]);
  });

  // /reusable-parent/first-child -> /reusable-parent/second-child
  test('navigate to a nested sibling with a reusable parent', () async {
    final fixture = await setup<TestNavigateToNestedSiblingWithSharedParent>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$ReusableParentComponent[0].ngOnInit',
      '$FirstChildComponent[0].ngOnInit',
      '$ReusableParentComponent[0].canActivate',
      '$FirstChildComponent[0].canActivate',
      '$ReusableParentComponent[0].onActivate',
      '$FirstChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/reusable-parent/second-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$ReusableParentComponent[0].canNavigate',
      '$FirstChildComponent[0].canNavigate',
      '$SecondChildComponent[0].ngOnInit',
      '$ReusableParentComponent[0].canDeactivate',
      '$FirstChildComponent[0].canDeactivate',
      '$ReusableParentComponent[0].canActivate',
      '$SecondChildComponent[0].canActivate',
      '$ReusableParentComponent[0].onDeactivate',
      '$FirstChildComponent[0].onDeactivate',
      '$ReusableParentComponent[0].canReuse',
      '$ReusableParentComponent[0].onActivate',
      '$FirstChildComponent[0].canReuse',
      '$FirstChildComponent[0].ngOnDestroy',
      '$SecondChildComponent[0].onActivate',
    ]);
  });

  // /first-parent/first-child -> /second-parent/second-child
  test('navigate between nested routes', () async {
    final fixture = await setup<TestNavigateBetweenNestedRoutes>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstParentComponent[0].ngOnInit',
      '$FirstChildComponent[0].ngOnInit',
      '$FirstParentComponent[0].canActivate',
      '$FirstChildComponent[0].canActivate',
      '$FirstParentComponent[0].onActivate',
      '$FirstChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-parent/second-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$FirstParentComponent[0].canNavigate',
      '$FirstChildComponent[0].canNavigate',
      '$SecondParentComponent[0].ngOnInit',
      '$SecondChildComponent[0].ngOnInit',
      '$FirstParentComponent[0].canDeactivate',
      '$FirstChildComponent[0].canDeactivate',
      '$SecondParentComponent[0].canActivate',
      '$SecondChildComponent[0].canActivate',
      '$FirstParentComponent[0].onDeactivate',
      '$FirstChildComponent[0].onDeactivate',
      '$FirstParentComponent[0].canReuse',
      '$FirstChildComponent[0].ngOnDestroy',
      '$FirstParentComponent[0].ngOnDestroy',
      '$SecondParentComponent[0].onActivate',
      '$SecondChildComponent[0].onActivate',
    ]);
  });

  // /first-reusable-parent/first-child -> /second-parent/second-child
  test('navigate between nested routes with a reusable parent', () async {
    final fixture =
        await setup<TestNavigateBetweenNestedRoutesWithReusableParent>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstReusableParentComponent[0].ngOnInit',
      '$FirstChildComponent[0].ngOnInit',
      '$FirstReusableParentComponent[0].canActivate',
      '$FirstChildComponent[0].canActivate',
      '$FirstReusableParentComponent[0].onActivate',
      '$FirstChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-parent/second-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$FirstReusableParentComponent[0].canNavigate',
      '$FirstChildComponent[0].canNavigate',
      '$SecondParentComponent[0].ngOnInit',
      '$SecondChildComponent[0].ngOnInit',
      '$FirstReusableParentComponent[0].canDeactivate',
      '$FirstChildComponent[0].canDeactivate',
      '$SecondParentComponent[0].canActivate',
      '$SecondChildComponent[0].canActivate',
      '$FirstReusableParentComponent[0].onDeactivate',
      '$FirstChildComponent[0].onDeactivate',
      '$FirstReusableParentComponent[0].canReuse',
      '$SecondParentComponent[0].onActivate',
      '$SecondChildComponent[0].onActivate',
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
      '$ReusableParentComponent[0].ngOnInit',
      '$FirstChildComponent[0].ngOnInit',
      '$ReusableParentComponent[0].canActivate',
      '$FirstChildComponent[0].canActivate',
      '$ReusableParentComponent[0].onActivate',
      '$FirstChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-reusable-parent/second-child'),
        NavigationResult.SUCCESS);
    expect(log, [
      '$ReusableParentComponent[0].canNavigate',
      '$FirstChildComponent[0].canNavigate',
      '$SecondChildComponent[0].ngOnInit',
      '$ReusableParentComponent[0].canDeactivate',
      '$FirstChildComponent[0].canDeactivate',
      '$ReusableParentComponent[0].canActivate',
      '$SecondChildComponent[0].canActivate',
      '$ReusableParentComponent[0].onDeactivate',
      '$FirstChildComponent[0].onDeactivate',
      '$ReusableParentComponent[0].canReuse',
      '$ReusableParentComponent[0].onActivate',
      '$FirstChildComponent[0].canReuse',
      '$FirstChildComponent[0].ngOnDestroy',
      '$SecondChildComponent[0].onActivate',
    ]);
  });

  test('navigate to the same route should do nothing', () async {
    final fixture = await setup<TestNavigateToSibling>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstChildComponent[0].ngOnInit',
      '$FirstChildComponent[0].canActivate',
      '$FirstChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/'), NavigationResult.SUCCESS);
    expect(log, [
      '$FirstChildComponent[0].canNavigate',
    ]);
  });

  test('reload the same route', () async {
    final fixture = await setup<TestNavigateToSibling>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstChildComponent[0].ngOnInit',
      '$FirstChildComponent[0].canActivate',
      '$FirstChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/', NavigationParams(reload: true)),
        NavigationResult.SUCCESS);
    expect(log, [
      '$FirstChildComponent[0].canNavigate',
      '$FirstChildComponent[0].canDeactivate',
      '$FirstChildComponent[0].canActivate',
      '$FirstChildComponent[0].onDeactivate',
      '$FirstChildComponent[0].canReuse',
      '$FirstChildComponent[0].ngOnDestroy',
      '$FirstChildComponent[1].ngOnInit',
      '$FirstChildComponent[1].onActivate'
    ]);
  });

  test('prevent navigation before other lifecycle callbacks', () async {
    final fixture = await setup<TestPreventNavigation>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$CantNavigateChildComponent[0].ngOnInit',
      '$CantNavigateChildComponent[0].canActivate',
      '$CantNavigateChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/second-child'),
        NavigationResult.BLOCKED_BY_GUARD);
    expect(log, [
      '$CantNavigateChildComponent[0].canNavigate',
    ]);
  });

  test('redirect to a sibling', () async {
    final fixture = await setup<TestRedirectToSibling>();
    final log = fixture.assertOnlyInstance.lifecycleLog;
    final router = fixture.assertOnlyInstance.router;
    expect(log, [
      '$FirstChildComponent[0].ngOnInit',
      '$FirstChildComponent[0].canActivate',
      '$FirstChildComponent[0].onActivate',
    ]);
    log.clear();
    expect(await router.navigate('/foo'), NavigationResult.SUCCESS);
    expect(log, [
      '$FirstChildComponent[0].canNavigate',
      '$SecondChildComponent[0].ngOnInit',
      '$FirstChildComponent[0].canDeactivate',
      '$SecondChildComponent[0].canActivate',
      '$FirstChildComponent[0].onDeactivate',
      '$FirstChildComponent[0].canReuse',
      '$FirstChildComponent[0].ngOnDestroy',
      '$SecondChildComponent[0].onActivate',
    ]);
  });
}

const instanceIdsToken = OpaqueToken<Map<String, int>>();
const lifecycleLogToken = OpaqueToken<List<String>>();

Future<NgTestFixture<T>> setup<T>() async {
  final testBed = NgTestBed<T>().addProviders([
    ValueProvider.forToken(lifecycleLogToken, <String>[]),
    ValueProvider.forToken(instanceIdsToken, <String, int>{}),
    routerProvidersTest,
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
  /// An identifier used to indicate which instance received a lifecycle call.
  final String _identifier;

  /// An ordered list in which lifecycle invocations are recorded.
  final List<String> lifecycleLog;

  RouterLifecycleLogger(
    String name,
    Map<String, int> instanceIds,
    this.lifecycleLog,
  ) : _identifier = instanceIds.containsKey(name)
            ? '$name[${++instanceIds[name]}]'
            : '$name[0]' {
    instanceIds.putIfAbsent(name, () => 0);
  }

  @override
  Future<bool> canActivate(_, __) async {
    lifecycleLog.add('$_identifier.canActivate');
    return true;
  }

  @override
  Future<bool> canDeactivate(_, __) async {
    lifecycleLog.add('$_identifier.canDeactivate');
    return true;
  }

  @override
  Future<bool> canNavigate() async {
    lifecycleLog.add('$_identifier.canNavigate');
    return true;
  }

  @override
  Future<bool> canReuse(_, __) async {
    lifecycleLog.add('$_identifier.canReuse');
    return false;
  }

  @override
  void onActivate(_, __) {
    lifecycleLog.add('$_identifier.onActivate');
  }

  @override
  void onDeactivate(_, __) {
    lifecycleLog.add('$_identifier.onDeactivate');
  }

  @override
  void ngOnDestroy() {
    lifecycleLog.add('$_identifier.ngOnDestroy');
  }

  @override
  void ngOnInit() {
    lifecycleLog.add('$_identifier.ngOnInit');
  }
}

@Component(
  selector: 'first-child',
  template: '',
)
class FirstChildComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = RouteDefinition(
    path: 'first-child',
    component: ng.FirstChildComponentNgFactory,
    useAsDefault: true,
  );

  FirstChildComponent(
    @instanceIdsToken Map<String, int> instanceIds,
    @lifecycleLogToken List<String> lifecycleLog,
  ) : super('$FirstChildComponent', instanceIds, lifecycleLog);
}

@Component(
  selector: 'second-child',
  template: '',
)
class SecondChildComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = RouteDefinition(
    path: 'second-child',
    component: ng.SecondChildComponentNgFactory,
  );

  SecondChildComponent(
    @instanceIdsToken Map<String, int> instanceIds,
    @lifecycleLogToken List<String> lifecycleLog,
  ) : super('$SecondChildComponent', instanceIds, lifecycleLog);
}

@Component(
  selector: 'first-child',
  template: '',
)
class FirstReusableChildComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = RouteDefinition(
    path: 'first-reusable-child',
    component: ng.FirstReusableChildComponentNgFactory,
    useAsDefault: true,
  );

  FirstReusableChildComponent(
    @instanceIdsToken Map<String, int> instanceIds,
    @lifecycleLogToken List<String> lifecycleLog,
  ) : super('$FirstReusableChildComponent', instanceIds, lifecycleLog);

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
  static final RouteDefinition routeDefinition = RouteDefinition(
    path: 'cant-navigate-child',
    component: ng.CantNavigateChildComponentNgFactory,
    useAsDefault: true,
  );

  CantNavigateChildComponent(
    @instanceIdsToken Map<String, int> instanceIds,
    @lifecycleLogToken List<String> lifecycleLog,
  ) : super('$CantNavigateChildComponent', instanceIds, lifecycleLog);

  @override
  Future<bool> canNavigate() async {
    await super.canNavigate();
    return false;
  }
}

const testDirectives = [RouterOutlet];
const testTemplate = '<router-outlet [routes]="routes"></router-outlet>';

@Component(
  selector: 'parent',
  template: testTemplate,
  directives: testDirectives,
)
class ParentComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = RouteDefinition(
    path: 'parent',
    component: ng.ParentComponentNgFactory,
    useAsDefault: true,
  );

  final List<RouteDefinition> routes = [
    FirstChildComponent.routeDefinition,
    SecondChildComponent.routeDefinition,
  ];

  ParentComponent(
    @instanceIdsToken Map<String, int> instanceIds,
    @lifecycleLogToken List<String> lifecycleLog,
  ) : super('$ParentComponent', instanceIds, lifecycleLog);
}

@Component(
  selector: 'reusable-parent',
  template: testTemplate,
  directives: testDirectives,
)
class ReusableParentComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = RouteDefinition(
    path: 'reusable-parent',
    component: ng.ReusableParentComponentNgFactory,
    useAsDefault: true,
  );

  final List<RouteDefinition> routes = [
    FirstChildComponent.routeDefinition,
    SecondChildComponent.routeDefinition,
  ];

  ReusableParentComponent(
    @instanceIdsToken Map<String, int> instanceIds,
    @lifecycleLogToken List<String> lifecycleLog,
  ) : super('$ReusableParentComponent', instanceIds, lifecycleLog);

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
  static final RouteDefinition routeDefinition = RouteDefinition(
    path: 'first-parent',
    component: ng.FirstParentComponentNgFactory,
    useAsDefault: true,
  );

  final List<RouteDefinition> routes = [
    FirstChildComponent.routeDefinition,
  ];

  FirstParentComponent(
    @instanceIdsToken Map<String, int> instanceIds,
    @lifecycleLogToken List<String> lifecycleLog,
  ) : super('$FirstParentComponent', instanceIds, lifecycleLog);
}

@Component(
  selector: 'second-parent',
  template: testTemplate,
  directives: testDirectives,
)
class SecondParentComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = RouteDefinition(
    path: 'second-parent',
    component: ng.SecondParentComponentNgFactory,
  );

  final List<RouteDefinition> routes = [
    SecondChildComponent.routeDefinition,
  ];

  SecondParentComponent(
    @instanceIdsToken Map<String, int> instanceIds,
    @lifecycleLogToken List<String> lifecycleLog,
  ) : super('$SecondParentComponent', instanceIds, lifecycleLog);
}

@Component(
  selector: 'first-reusable-parent',
  template: testTemplate,
  directives: testDirectives,
)
class FirstReusableParentComponent extends RouterLifecycleLogger {
  static final RouteDefinition routeDefinition = RouteDefinition(
    path: 'first-reusable-parent',
    component: ng.FirstReusableParentComponentNgFactory,
    useAsDefault: true,
  );

  final List<RouteDefinition> routes = [
    FirstChildComponent.routeDefinition,
  ];

  FirstReusableParentComponent(
    @instanceIdsToken Map<String, int> instanceIds,
    @lifecycleLogToken List<String> lifecycleLog,
  ) : super('$FirstReusableParentComponent', instanceIds, lifecycleLog);

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

  TestNavigateToSibling(@lifecycleLogToken this.lifecycleLog, this.router);
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
      @lifecycleLogToken this.lifecycleLog, this.router);
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
      @lifecycleLogToken this.lifecycleLog, this.router);
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
      @lifecycleLogToken this.lifecycleLog, this.router);
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
      @lifecycleLogToken this.lifecycleLog, this.router);
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
      @lifecycleLogToken this.lifecycleLog, this.router);
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
    RouteDefinition(
      path: 'first-reusable-parent',
      component: ng.ReusableParentComponentNgFactory,
      useAsDefault: true,
    ),
    RouteDefinition(
      path: 'second-reusable-parent',
      component: ng.ReusableParentComponentNgFactory,
    ),
  ];

  TestNavigateBetweenNestedRoutesWithSameReusableParent(
      @lifecycleLogToken this.lifecycleLog, this.router);
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

  TestPreventNavigation(@lifecycleLogToken this.lifecycleLog, this.router);
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
    RouteDefinition.redirect(
      path: '.+',
      redirectTo: SecondChildComponent.routeDefinition.path,
    ),
  ];

  TestRedirectToSibling(@lifecycleLogToken this.lifecycleLog, this.router);
}
