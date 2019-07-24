## 2.0.0-alpha+24

*   Maintenance release to support Angular 6.0-alpha+1.

## 2.0.0-alpha+23

### Bug fixes

*   Navigation requests triggered by `popstate` events that redirect back to the
    active route will now correctly update the browser location to match the
    active route. Prior to this fix, the browser location would be left in the
    state changed by the `popstate` event.

*   The history stack prior to the current entry is now preserved when
    preventing a navigation triggered by the back button. Previously, preventing
    such a navigation would erase the previous history entry, causing subsequent
    history manipulations to have unexpected results.

## 2.0.0-alpha+22

### New features

*   `RouteDefinition.defer` now supports an optional `prefetcher` parameter
    which can be defined to prefetch additional resources that are dependent on
    the matched `RouterState`.

*   The `RouteDefinition` subclasses `DeferredRouteDefinition`,
    `RedirectRouteDefinition`, and `ComponentRouteDefinition` are now exported
    from `package:angular_router/testing.dart`.

### Bug fixes

*   Deferred route loaders and prefetchers are no longer called a second time
    when matched during route resolution.

*   Navigation requests triggered by `popstate` events will now update the
    browser location if the resulting navigation matches a redirecting route or
    is transformed by a `RouterHook` implementation.

## 2.0.0-alpha+21

*   Maintenance release to support Angular 5.2.

## 2.0.0-alpha+20

### Bug fixes

*   Fixed a discrepancy between the href rendered by `RouterLinkDirective`, and
    the browser location to which it would navigate upon being clicked when
    using `routerProvidersHash`.

## 2.0.0-alpha+19

*   Maintenance release to support Angular 5.0.

## 2.0.0-alpha+18

### Bug fixes

*   `HashLocationStrategy` no longer drops query parameters (before the #) when
    pushing or replacing an empty URL.

## 2.0.0-alpha+17

### New features

*   `RouteDefinition.redirect` now supports forwarding route parameters.

## 2.0.0-alpha+16

*   Maintenance release; declare official support for the Dart2 SDK.

## 2.0.0-alpha+15

### Breaking changes

*   Removed component instance parameter from `RouterHook.canNavigate()`.

## 2.0.0-alpha+14

### Bug fixes

*   Preserves `NavigationParams` on redirection.

*   Added `canNavigate` to `RouterHook`.

*   Navigation will no longer succeed for an empty path if it doesn't match a
    route.

## 2.0.0-alpha+13

### New features

*   Moved `normalizePath()` from an internal type to `Location` to give
    fine-grained control over path normalization.

### Bug fixes

*   Fixed a regression where the `RouterLinkActive` directive would not activate
    for empty paths (including `'/'`).

*   Fixed a bug where if a component threw an exception during routing the
    router would get in a perpetual bad state where it was impossible to route
    away or otherwise use the application.

## 2.0.0-alpha+12

### Breaking changes

*   Renamed the `platformStrategy` field of `Location` to `locationStrategy`,
    since it's of type `LocationStrategy`.

## 2.0.0-alpha+11

### New features

*   Added the method `navigateByUrl` to `Router`.

## 2.0.0-alpha+10

### Breaking changes

*   The minimum SDK version is now `sdk: ">=2.0.0-dev.46.0 <2.0.0"`.

### Bug fixes

*   Router navigation requests are now queued to ensure they'll run sequentially
    in the order they were requested. Previously no attempt was made to
    synchronise navigation requests, and if multiple were made simultaneously
    they could run concurrently, interfere with each other, and potentially
    complete out of order.

## 2.0.0-alpha+9

### Breaking changes

*   `APP_BASE_HREF` was removed in favor of `appBaseHref`.

*   When navigating to and from the same implementation of `CanReuse`, if it
    returns true, the implementation will remain attached to the DOM.
    Previously, components were unconditionally detached from the DOM on
    navigation, and reusable components would simply be reattached.

    This *may* be a change to the scroll behavior of your components, as
    temporarily removing reused components from the DOM could reset the scroll
    position if no other content was present.

### Bug fixes

*   `CanNavigate`, `CanDeactivate`, and `OnDeactivate` should now always be
    invoked on the active instance of a component rather than the instance
    created during route resolution. This previously could occur when navigating
    away and back to a nested route whose parent was not reusable.

## 2.0.0-alpha+8

### Breaking changes

*   `APP_BASE_HREF` is being renamed `appBaseHref`.

## 2.0.0-alpha+7

### Breaking changes

*   `RouterOutlet` is no longer injectable.

*   Renamed `Router.stream` to `Router.onRouteActivated`. `Router.stream` is now
    deprecated and will be removed after next release.

### Bug fixes

*   `RouterPath.toUrl()` no longer generates an incorrect URL with an extra '/'
    when a parent route has an empty path.

## 2.0.0-alpha+6

### New features

*   `Router.onNavigationStart` now emits the requested navigation path.

## 2.0.0-alpha+5

### New features

*   Added `Router.onNavigationStart` to notify subscribers when a navigation
    request starts.

*   Added the `routerProvidersTest` module for testing route configurations or
    components with router dependencies.

### Breaking changes

*   Removed fuzzy arrow from `MockLocationStrategy`. It relied on Dart 1's
    treatment of dynamic as bottom to mock handling of `popstate` events without
    actually relying on `dart:html`. Since Angular must be tested in the browser
    anyways, there's no incentive to avoid this dependency. As a consequence,
    the signature of `MockLocationStrategy.onPopState` is now unchanged from
    `LocationStrategy.onPopState`.

## 2.0.0-alpha+4

### Breaking changes

*   Removed `SpyLocation`. `MockLocationStrategy` should be used instead.

### Bug fixes

*   Prevented `canDeactivate()` from being invoked twice during redirection. It
    will now only be invoked with the redirected next router state, without also
    being invoked with the intermediate next router state.

*   Prevented `canNavigate()` from being invoked twice during redirection.

## 2.0.0-alpha+3

### New features

*   Added the `CanNavigate` lifecycle interface. This is similar to
    `CanDeactivate`, and preferred when the next `RouterState` isn't necessary
    to determine whether the router may navigate.

*   Added `reload` field to `NavigationParams` which can be used to force
    navigation, even if the path and other navigation parameters are unchanged.

*   Added `replace` field to `NavigationParams` which can be used to replace the
    current history entry on navigation instead of creating a new one.

### Breaking changes

*   Removed `hashCode` and `operator ==` overrides from `RouteDefinition` and
    `RouterState`, as these can't be removed by tree-shaking.

### Bug fixes

*   Upon destruction, `RouterOutlet` will now properly destroy all of its cached
    components, instead of only destroying the active one.

## 2.0.0-alpha+2

*   Fixed a bug where `RouterLinkDirective` was not keyboard accessible.

## 2.0.0-alpha+1

*   Support for angular 5.0.0-alpha+1

## 2.0.0-alpha

*   Major refactoring of the `angular_router` package. For a migration guide
    from `angular_router` v1, see
    https://github.com/dart-lang/angular/blob/master/doc/router/migration.md.

## 1.0.2

*   Support for angular 4.0.0.

## 1.0.1

*   Minor internal changes to support angular 4.0.0-beta

## 1.0.0

*   Initial commit of `angular_router`. This is just a port of the router that
    was in the core angular package.
