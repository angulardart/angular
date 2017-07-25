# AngularDart's generated code

This is a document focused on the _internals_ of the generated
(`.template.dart`) files aimed primarily at _developers_ of AngularDart (versus
consumers).

## Overview

Each `.template.dart` has a few functional pieces (some public, some private).

### `@Component`

Each `@Component` generates the following code at compile-time:

#### Host View

`class View{Type}Host extends AppView<dynamic> { ... }`

This is a class generated that matches `ViewType.HOST`, and is used to back the
implementation of `ComponentFactory`, which in turn is used for imperative
component creation.

It is considered _private_ API.

#### Component View

`class View{Type}0 extends AppView<{Type}> { ... }`

This is a class generated that matches `ViewType.COMPONENT`, and is the view for
the `@Component`-annotated `class`. It will create n-number of _embedded_ views
for parts of the template, and also create n-number of _component_ and
_directive_ views and change detectors for anything in `directives: [ ... ]`.

It is considered _public_ but _internal only_ API (i.e. internal to Angular).

#### Embedded Views

`class View{Type}{n > 0} extends AppView<dynamic> { ... }`

This is any number of classes, generated, that back the implementation of the
`template|templateUrl` of an `@Component`. As the template changes these will
change (and more may be added, for example). These match `ViewType.EMBEDDED`.

It is considered _private_ API.

#### Component Factory

`const ComponentFactory {Type}NgFactory = ...`

This is a statically defined helper for creating an instance of a component
imperatively. Internally it uses the `View{Type}Host` class as the backing
implementation, as well as a "view factory" (below).

#### View Factory

`AppView viewFactory_{Type}Host0`

A top-level function that helps back the implementation of `ComponentFactory`.

### `@Directive`

Each `@Directive` generates `{Type}NgCd` _iff_:

*   It is not called `NgIf` (special cased)
*   At least one `@Input` _or_ bound host property (`@Host...` or `host:`)

## `initReflector`

A closed-world graph all imported files (that are not `deferred`) that have
generated code (`.template.dart`). This is used to prime a behind-the-scenes
mapping of `Type` -> _metadata_, which in turn is used for some legacy APIs in
AngularDart (`ReflectiveInjector`, `DynamicComponentLoader`).

It is considered _public_ API.
