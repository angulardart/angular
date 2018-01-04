### New features

*   Added `replace` field to `NavigationParams` which can be used to replace the
    current history entry on navigation instead of creating a new one.

### Breaking changes

*   Removed `hashCode` and `operator ==` overrides from `RouteDefinition` and
    `RouterState`, as these can't be removed by tree-shaking.

## 2.0.0-alpha+2

- Fixed a bug where `RouterLinkDirective` was not keyboard accessible.

## 2.0.0-alpha+1

- Support for angular 5.0.0-alpha+1

## 2.0.0-alpha

- Major refactoring of the `angular_router` package. For a migration guide from
`angular_router` v1, see
https://github.com/dart-lang/angular/blob/master/angular_router/g3doc/migration_guide.md.

## 1.0.2

- Support for angular 4.0.0.

## 1.0.1

- Minor internal changes to support angular 4.0.0-beta

## 1.0.0

- Initial commit of `angular_router`. This is just a port of the router that was
  in the core angular package.
