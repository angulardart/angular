# AngularDart's generated code


This is a document focused on the _internals_ of the generated
(`.template.dart`) files aimed primarily at _developers_ of AngularDart (versus
consumers).

## Overview

Each `.template.dart` has a few functional pieces (some public, some private).

### `@Component`

Each `@Component` generates the following code at compile-time:

#### Host View

`class _View{Type}Host0 extends HostView<{Type}> { ... }`

This is a class generated for a `CompileView` with `ViewType.host`.

One is generated for each component, and is used to back the implementation of
`ComponentFactory`, which in turn is used to imperatively create the component.

It is considered _private_ API.

#### Component View

`class View{Type}0 extends ComponentView<{Type}> { ... }`

This is a class generated for a `CompileView` with `ViewType.component`.

One is generated for each `@Component`-annotated class, and is used to create
and change detect the static portion of the component's template. It may also
instantiate _embedded_ views for any `<template>` elements well as _component_
views or _directive_ change detectors for anything in `directives: [ ... ]`.

It is considered _public_ but _internal only_ API (i.e. internal to Angular).

#### Embedded Views

`class _View{Type}{n > 0} extends EmbeddedView<{Type}> { ... }`

This is a class generated for a `CompileView` with `ViewType.embedded`.

One is generated for each `<template>` element in a component's template, and
represents a dynamic portion of the overall view. Otherwise it shares the same
responsibility as a _component_ view in regards to creating and change detecting
the content within the `<template>`.

Each embedded view is used to back a `TemplateRef`, and once instantiated, may
be managed via an `EmbeddedViewRef`.

It is considered _private_ API.

#### Component Factory

`const ComponentFactory {Type}NgFactory = ...`

This is a statically defined helper for creating an instance of a component
imperatively. Internally it uses a "view factory" (below) to instantiate the
`_View{Type}Host` class.

It is considered _public_ API.

#### View Factory

`AppView<{Type}> viewFactory_{Type}Host0`

A top-level function that instantiates `_View{Type}Host` and is used to back the
implementation of a `ComponentFactory`.

It is considered _private_ API, even though the method is public.

### `@Directive`

Each `@Directive` generates `{Type}NgCd` _iff_ it has at least one bound host
property (`@HostBinding`). The purpose of this class is to centralize change
detection of host properties.

## `initReflector`

A closed-world graph of all imported files (that are not `deferred`) that have
generated code (`.template.dart`). This is used to prime a behind-the-scenes
mapping of `Type` -> _metadata_, which in turn is used for some legacy APIs in
AngularDart (`ReflectiveInjector`, `DynamicComponentLoader`).

It is considered _public_ API.
