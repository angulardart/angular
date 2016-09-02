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


@cheatsheetItem
syntax:
`<router-outlet></router-outlet>`|`router-outlet`
description:
Marks the location to load the component of the active route.


@cheatsheetItem
syntax:
`<a [routerLink]="[ '/MyCmp', {myParam: 'value' } ]">`|`[routerLink]`
description:
Creates a link to a different view based on a route instruction consisting of a route name and optional parameters. To navigate to a root route, use the `/` prefix; for a child route, use the `./`prefix.

@cheatsheetItem
syntax:
`@CanActivate(() => ...)class MyComponent() {}`|`@CanActivate`
description:
A component decorator defining a function that the router should call first to determine if it should activate this component. Should return a boolean or a future.


@cheatsheetItem
syntax:
`routerOnActivate(nextInstruction,
    prevInstruction) { ... }`|`routerOnActivate`
description:
After navigating to a component, the router calls the component's `routerOnActivate` method (if defined).


@cheatsheetItem
syntax:
`routerCanReuse(nextInstruction,
    prevInstruction) { ... }`|`routerCanReuse`
description:
The router calls a component's `routerCanReuse` method (if defined) to determine whether to reuse the instance or destroy it and create a new instance. Should return a boolean or a future.


@cheatsheetItem
syntax:
`routerOnReuse(nextInstruction,
    prevInstruction) { ... }`|`routerOnReuse`
description:
The router calls the component's `routerOnReuse` method (if defined) when it reuses a component instance.


@cheatsheetItem
syntax:
`routerCanDeactivate(nextInstruction,
    prevInstruction) { ... }`|`routerCanDeactivate`
description:
The router calls the `routerCanDeactivate` methods (if defined) of every component that would be removed after a navigation. The navigation proceeds if and only if all such methods return true or a future that completes successfully.


@cheatsheetItem
syntax:
`routerOnDeactivate(nextInstruction,
    prevInstruction) { ... }`|`routerOnDeactivate`
description:
Called before the directive is removed as the result of a route change. May return a future that pauses removing the directive until the future completes.
