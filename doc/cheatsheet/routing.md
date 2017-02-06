@cheatsheetSection
Routing and navigation
@cheatsheetIndex 10
@description
`import 'package:angular2/router.dart';`


@cheatsheetItem
syntax:
`@RouteConfig(const [
  const Route(
      path: '/:myParam',
      component: MyComponent,
      name: 'MyCmp' ),
])`|`@RouteConfig`
description:
Configures routes for the decorated component. Supports static, parameterized, and wildcard routes.

See:
[Tutorial: Routing](/angular/tutorial/toh-pt5),
[RouteConfig class](/angular/api/angular2.router/RouteConfig-class),
[Route class](/angular/api/angular2.router/Route-class)


@cheatsheetItem
syntax:
`<router-outlet></router-outlet>`|`router-outlet`
description:
Marks the location to load the component of the active route.

See:
[Tutorial: Routing](/angular/tutorial/toh-pt5),
[RouterOutlet class](/angular/api/angular2.router/RouterOutlet-class)


@cheatsheetItem
syntax:
`<a [routerLink]="[ '/MyCmp', {myParam: 'value' } ]">`|`[routerLink]`
description:
Creates a link to a different view based on a route instruction consisting of a route name and optional parameters. To navigate to a root route, use the `/` prefix; for a child route, use the `./`prefix.

See:
[Tutorial: Routing](/angular/tutorial/toh-pt5),
[RouterLink class](/angular/api/angular2.router/RouterLink-class)


@cheatsheetItem
syntax:
`@CanActivate(() => ...)class MyComponent() {}`|`@CanActivate`
description:
A component decorator defining a function that the router should call first to determine if it should activate this component. Should return a boolean or a future.
<!-- TODO: link to good resource. -->


@cheatsheetItem
syntax:
`routerOnActivate(nextInstruction,
    prevInstruction) { ... }`|`routerOnActivate`
description:
After navigating to a component, the router calls the component's `routerOnActivate` method (if defined).

See: [OnActivate class](/angular/api/angular2.router/OnActivate-class)


@cheatsheetItem
syntax:
`routerCanReuse(nextInstruction,
    prevInstruction) { ... }`|`routerCanReuse`
description:
The router calls a component's `routerCanReuse` method (if defined) to determine whether to reuse the instance or destroy it and create a new instance. Should return a boolean or a future.

See: [CanReuse class](/angular/api/angular2.router/CanReuse-class)


@cheatsheetItem
syntax:
`routerOnReuse(nextInstruction,
    prevInstruction) { ... }`|`routerOnReuse`
description:
The router calls the component's `routerOnReuse` method (if defined) when it reuses a component instance.

See: [OnReuse class](/angular/api/angular2.router/OnReuse-class)


@cheatsheetItem
syntax:
`routerCanDeactivate(nextInstruction,
    prevInstruction) { ... }`|`routerCanDeactivate`
description:
The router calls the `routerCanDeactivate` methods (if defined) of every component that would be removed after a navigation. The navigation proceeds if and only if all such methods return true or a future that completes successfully.

See: [CanDeactivate class](/angular/api/angular2.router/CanDeactivate-class)


@cheatsheetItem
syntax:
`routerOnDeactivate(nextInstruction,
    prevInstruction) { ... }`|`routerOnDeactivate`
description:
Called before the directive is removed as the result of a route change. May return a future that pauses removing the directive until the future completes.

See: [OnDeactivate class](/angular/api/angular2.router/OnDeactivate-class)
