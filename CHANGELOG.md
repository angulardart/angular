## 2.0.0 Release

### API changes
 * Implemented NgTestBed to improve test infrastructure goo.gl/NAXXlN.
 * Removed Metadata classes used for angular annotations.
 * Added ComponentState to provide push change detection with better
   ergonomics and code generation.
 * ViewContainerRef.createEmbeddedView index parameter removed instead
   introduced insertEmbeddedView.
 * Added support for minimal code generation when user explicitly marks
   component with preserveWhitespace:false.

### Bug fixes and other changes
 * Improved ngFor performance.
 * Improved shared style host performance.
 * Improved @ViewChild/@ViewChildren performance.
 * Code and documentation cleanups.
 * Strong mode fixes.

## 2.0.0-beta.22

### API changes

 * **POTENTIALLY BREAKING** Observable features new use the new `observable`
 package, instead of `observe`.
 * Removed `Renderer.createViewRoot`.

### Bug fixes and other changes

 * Improved compiler errors.
 * Fixes to reduce code size.
 * Support the latest `pkg/build`.
 * Now require Dart SDK 1.19 at a minimum.
 * Added `.analysis_options` to enforce a number of style rules.

## 2.0.0-beta.21

Our push towards better performance has started showing results in
this release. This update provides 5-10% speedup in components. >20% reduction
in Dart code size emitted from compiler.

### API changes

* Added support for '??' operator in template compiler.
* Removed unused animation directives to create more Darty/compile time version.
* Removed unused i18n pipes to prepare for dart:intl based solution.
* Language facades removed (isPresent, isBlank, getMapKey, normalizeBool,
  DateWrapper, RegExpWrapper, StringWrapper, NumberWrapper, Math facades,
  SetWrapper, ListWrapper, MapWrapper, StringMapWrapper, ObservableWrapper,
  TimerWrapper).
* Deprecated unused ROUTER_LINK_DSL_TRANSFORM.
* Refactor(element.dart) is now app_element.dart.
* AppView moved to app_view. DebugAppView moved to debug/debug_app_view.dart.
* The deprecated injection Binding and bind have been removed.
* Remove global events and disposables (instead of :window type targets,
  use dart APIs).

### Bug fixes and other changes
* Improved change detection performance.
* Improved error messages reported by template compiler.
* Optimized [class.x]="y" type bindings.
* Switched to js_util for browser_adapter to make angular CSP compliant.
* Started strongly typing element members in compiled template code.
* Cheatsheet and code docs updated.
* Router fixes

## 2.0.0-beta.20

### API changes

* Added ngBeforeSubmit event to ngForm API to allow better validation.
* Global events removed from event binding syntax (dart:html APIs provide
  better alternative).

### Bug fixes and other changes
* Reduced template code size.
* Cleanup of facades.
* Class Documentation updates.
* ngForm submit changed to sync.
* Removed disposables in generated template code.

## 2.0.0-beta.19

### API changes

* Remove existing implementation of web workers, to be replaced in the
  future with Dart import override for dart:html.

### Bug fixes and other changes
* Remove throwOnChanges parameter from all change detection calls in
  generated template.dart.
* Unused and empty assertArrayOfStrings API removed.
* Update BrowserDomAdapter from dart:js to package:js.
* Reset change detection to guard against template exception.
* Delete unused files.
* Clean up the NgIf directive and remove facades.
* Enabled Travis-CI.
* Update tests that should only run in the browser.
* Add angular transformer which deletes any pre-existing generated files
  from Bazel.
* Add DI library entrypoint to support VM tests.
* Fix the Math facade (improper annotation): @Deprecated(description).
* Clean up animation classes.
* Remove library name declarations.
* Run dart formatter on all code.
* Remove unused testing/lang_utils.dart.


## 2.0.0-beta.18

This is the first release of Angular 2 for Dart that is written directly in
Dart, instead of generated from TypeScript.


### API changes

The `Provider` constructor and `provide()` function are now more intuitive
when they have a single argument.

Before, `const Provider(Foo)` or `provide(Foo)`
would provide a `null` object.
To provide a `Foo` object, you had to use `const Provider(Foo, useClass:Foo)`
or `provide(Foo, useClass:Foo)`.
Now you can omit the `useClass:Foo`.
Either of the following provides a `Foo` instance:

```dart
const Provider(Foo)
// or
provide(Foo)
```

If you want the old behavior, change your code to specify `useValue`:

```dart
const Provider(Foo, useValue: null)
// or
provide(Foo, useValue: null)
```

### Known issues

* Some types of **dependency injection** don't work.
  (https://github.com/dart-lang/angular2/issues/10)

### Bug fixes and other changes

* Fix lower bound of pkg/build dependency.
* Fixes for dependency upper bounds: build and protobuf.
* Bumping min version of pkg/intl and pkg version.
* Remove redundant declaration of `el`.
* Security Update. Secure Contextual Escaping Implementation.
* Fix Intl number formatting.
* Enforce strong mode for angular2.dart.
* Updating README and CONTRIBUTING.md for first release.
* Enforce dartfmt for dart/angular2.
* Add //dart/angular2/build_defs with default resolved_identifiers.
* Import cleanup.
* Annotate browser-only tests.
* Include .gitignore in files sent to GitHub.
* Fix a strong mode error in angular2 (strong mode type inference miss).
* Add compiler tests.
* Delete unused libraries in lib/src.
* Updated pubspec: authors, description, homepage.
* Angular strong mode fixes for DDC support.
* Add _LoggerConsole implementation of Console for the TemplateCompiler.
* Mark Binding and bind() as deprecated. Replaced by Provider and provide().
