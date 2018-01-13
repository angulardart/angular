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
    https://github.com/dart-lang/angular/blob/master/angular_router/g3doc/migration_guide.md.

## 1.0.2

*   Support for angular 4.0.0.

## 1.0.1

*   Minor internal changes to support angular 4.0.0-beta

## 1.0.0

*   Initial commit of `angular_router`. This is just a port of the router that
    was in the core angular package.
