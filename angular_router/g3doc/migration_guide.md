# Router Migration Guide

## Major changes

*   Routes are not defined in annotations. They are defined as a router-outlet Input().
*   The router navigates only with paths, not instructions or named routes.
    *   Instructions no longer exist.
    *   Routes no longer have names.
*   A navigation results in a RouterState, which contains the page's URL parameters, query parameters, and fragment.
    *   No more nested routers.
    *   No injected RouteParams. Query parameters are extracted from the RouterState (router.current).


## Migration steps

1.  Change the RouteConfig to a routes Input() on the router-outlet.

    1.  Create a
        [RoutePath](https://github.com/dart-lang/angular/blob/master/angular_router/lib/src/route_path.dart).
        This will contain all information about component routes, minus the
        component itself.
    1.  Create a list of
        [RouteDefinition](https://github.com/dart-lang/angular/blob/master/angular_router/lib/src/route_definition.dart)
        objects.
    1.  Add the `[routes]` to `<router-outlet>`. Example: `<router-outlet
        [routes]="routes">`

    **Old code:** \
    **root/lib/root.dart**

    ```
    @Component(
        selector: 'my-app',
        directives: const [routerDirectives],
        template: '''
          <router-outlet></router-outlet>
        ''')
    @RouteConfig(const [
      const Route(
          name: 'Overview',
          path: 'overview',
          component: OverviewComponent,
          useAsDefault: true),
      const Route(
          name: 'Planning',
          path: 'planning/:planType',
          component: PlanningComponent),
      const AsyncRoute(name: 'Clients', path: 'clients', loader: loadClients),
      const Redirect(path: '/**', redirectTo: const ['Overview'])
    ])
    class RootComponent {}
    ```

    **New code:** \
    **routes/lib/root_routes.dart**

    ```
    static const planTypeParameter = 'planType';

    static final overviewRoute = new RoutePath(
      path: "overview",
      useAsDefault: true,
    );
    static final planningRoute = new RoutePath(
      path: "planning/:$planTypeParameter",
    );
    static final clientRoute = new RoutePath(
      path: "client",
    );
    ```

    **root/lib/root.dart**

    ```
    import 'root_routes.dart' as root_routes;
    import 'overview_component.template.dart' as overview_component;
    import 'planning_component.template.dart' as planning_component;
    @Component(
        selector: 'my-app',
        directives: const [routerDirectives],
        template: '''
          <router-outlet [routes]="routes"></router-outlet>
        ''')
    class RootComponent {
      final List<RouteDefinition> routes = [
        new RouteDefinition(
          routePath: root_routes.overviewRoute,
          component: overview_component.OverviewComponentNgFactory,
        ),
        new RouteDefinition(
          routePath: root_routes.planningRoute,
          component: planning_component.PlanningComponentNgFactory,
        ),
        new RouteDefinition.defer(
          routePath: root_routes.clientRoute,
          loader: loadClients
        ),
        new RouteDefinition.redirect(
          path: '.*', // Regex
          redirectTo: root_routes.overviewRoute.toUrl(),
        ),
      ];
    }
    ```

1.  For nested routes, define and use parent route paths. The following example
    builds on the earlier one, assuming PlanningComponent also has a
    router-outlet.

    **New code:** \
    **routes/lib/planning_routes.dart**

    ```
    import 'root_routes.dart' as root_routes;

    static final homeRoute = new RoutePath(
      path: "home",
      useAsDefault: true,
      parent: root_routes.planningRoute
    );
    static final detailRoute = new RoutePath(
      path: "details",
      parent: root_routes.planningRoute
    );
    ```

    **planning/lib/planning.dart**

    ```
    import 'planning_routes.dart' as planning_routes;
    import 'home_component.template.dart' as home_component;
    import 'details_component.template.dart' as details_component;
    @Component(
        selector: 'my-app',
        directives: const [routerDirectives],
        template: '''
          <router-outlet [routes]="routes"></router-outlet>
        ''')
    class PlanningComponent {
      final List<RouteDefinition> routes = [
        new RouteDefinition(
          routePath: planning_routes.homeRoute,
          component: home_component.PlanningHomeComponentNgFactory,
        ),
        new RouteDefinition(
          routePath: planning_routes.detailRoute,
          component: details_component.PlanningDetailsComponentNgFactory,
        ),
      ]
    }
    ```

1.  Use RouterState to retrieve parameters.

    **Old code:**

    ```
    class PlanningHomeComponent {
      final RouteParams params;
      PlanningHomeComponent(this.params);
      void handleClick() {
        print(params.get('planType'));
      }
    }
    ```

    **New code:**

    ```
    import 'root_routes.dart' as root_routes;
    class PlanningHomeComponent {
      final Router router;
      PlanningHomeComponent(this.router);
      void handleClick() {
        print(router.current.parameters[root_routes.planTypeParameter]);
      }
    }
    ```

1.  Use OnActivate instead of OnInit.

    **Old code:**

    ```
    class PlanningHomeComponent implements OnInit {
      @override
      Future ngOnInit() async {
        doSomething();
      }
    }
    ```

    **New code:**

    ```
    class PlanningHomeComponent implements OnActivate {
      @override
      Future onActivate(_, __) async {
        doSomething();
      }
    }
    ```

1.  Create
    [Lifecycle](https://github.com/dart-lang/angular/blob/master/angular_router/lib/src/lifecycle.dart)
    hooks.

    Supported hooks: CanActivate, CanDeactivate, CanReuse, OnActivate,
    OnDeactivate

    **Example:**

    ```
    class MyComponent implements CanReuse {
      @override
      Future<bool> canReuse(RouterState current, RouterState next) async {
        // Always re-use this instance.
        return true;
      }
    }
    ```

## Resources

*   [Source code](https://github.com/dart-lang/angular/tree/master/angular_router/lib)
*   [Basic example](https://github.com/dart-lang/angular/tree/master/angular_router/example)

## FAQ

### Why RoutePath in another file?

This deals with circular dependencies. Other files can use these RoutePath
objects to know the URL of certain paths. This allows any component to access
navigate to any URL.

For example: `overviewRoute.toUrl() == '/overview'`. We can do things like:

*  `router.navigate(overviewRoute.toUrl());`
*  `planningRoute.toUrl( parameters: { 'planType': 'emergency' } )`


### Why OnActivate instead of OnInit?

Since the routes exist as an Input(), the router-outlet must be init in order for the route tree to be defined. Thus, the router will initialize components when trying to find the match the route to navigate. Therefore, a component may be initialized but not actually rendered.

OnActivate will have the same guarantees as OnInit, but be safe with the router.
