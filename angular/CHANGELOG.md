## 4.0.0-alpha

**NOTE**: Some of the features are not yet usable @ HEAD, as they require use of
the new AngularDart compiler, which is not yet enabled by default, and work is
ongoing. You can [track our progress](https://goo.gl/tFYsO3).

### New features

* Added `exports: [ ... ]` to `@Component`, which allows the limited use of
  top-level fields and static methods/fields in a template without making an
  alias getter in your class. Partially implements https://goo.gl/8mTMUH.

```dart
import 'dart:math' show max;

@Component(
  selector: 'comp',
  exports: const [
    max,
  ],
  // Should write '20'
  template: '{{max(20, 10)}}',
)
class Comp {}
```

* _Limitations_:
  * Only top-level fields that are `const` (not `final`) can be exported.

* Added `@deferred` as the first "compile-time" directive (it has no specific
  runtime code nor is it listed in a `directives: [ ... ]` list. Implements
  https://goo.gl/Cq3Uy1.

```dart
import 'package:angular2/angular2.dart';
import 'expensive_comp.dart' show ExpensiveComp;

@Component(
  selector: 'my-comp',
  directives: const [ExpensiveComp],
  template: r'''
    <expensive-comp @deferred></expensive-comp>
  ''',
)
class MyComp {}
```

* Added preliminary support for component inheritance. Components now inherit
  inputs, outputs, host bindings, host listeners, queries, and view queries
  transitively from their immediate supertype if it's a component or directive.

### Breaking changes

* Removed the runtime (`dart:mirrors`-based) interpreter. It is now required to
  always use the AngularDart transformer to pre-compile the code, even during
  development time in Dartium. `package:angular2/reflection.dart` was also
  removed.

* Returning `false` from an event handler will no longer cancel the event. See
  [#387](https://github.com/dart-lang/angular2/issues/387) for details.

* Removed `Query` and `ViewQuery`. Please use `ContentChild`/`ContentChildren`
  and `ViewChild`/`ViewChildren` in their place instead.

### Bug fixes

* Properly annotate methods in generated `.template.dart` code with `@override`.

### Performance

* Remove redundant calls to `dbg(...)` in dev-mode. This reduces the amount of
  work done and speeds up developer runtimes, such as those using the
  [DartDevCompiler (DDC)](https://github.com/dart-lang/sdk/tree/master/pkg/dev_compiler).

## 3.2.0

### Deprecations

* Support for shadow piercing combinators `/deep/` and `>>>` to prevent style
  encapsulation is now deprecated. `/deep/` is already deprecated and will be
  [removed in Chrome 60][deep-removal]. Its alias `>>>` is limited to the
  [static profile of selectors][static-profile], meaning it's not supported
  in style sheets. Continued use of these combinators puts Angular at risk of
  incompatibility with common CSS tooling. `::ng-deep` is a drop-in replacement,
  intended to provide the same functionality as `/deep/` and `>>>`, without the
  need to use deprecated or unsupported CSS syntax.

[deep-removal]: https://www.chromestatus.com/features/4964279606312960
[static-profile]: https://drafts.csswg.org/css-scoping/#deep-combinator

## 3.1.0

### New features

* Exposed `TouchFunction` and `ChangeFunction` typedefs to make the transition
  to strong-mode easier for teams relying on these function definitions. We
  might remove them in a future release when they are no longer needed.

* Added a flag to use an experimental new compiler that uses the Dart analyzer
  to gather metadata information. This flag will be turned on by default in
  `4.0`:

```yaml
transformers:
    angular2/transform/codegen:
        use_analyzer: true
```

**WARNING**: Using `use_analyzer: true` requires discontinuing use of the
`platform_*` options, and fails-fast if both flags are used. See
https://goo.gl/68VhMa for details.

**WARNING**: Using `use_analyser: true` doesn't yet work with most third-party
packages [due to a bug](https://github.com/dart-lang/angular2/issues/390).

### Deprecations

* Using `dart:mirrors` (i.e. running AngularDart without code generation) is
  now formally deprecated. In `4.0+` code generation will be the only way to
  run an AngularDart application, even in development mode. Please ensure you
  are using our transformer: https://goo.gl/rRHqO7.

### Bug fixes

* CSS errors are now just warnings, and can be ignored. This is due to using
  a CSS parser for encapsulation - and the AngularDart transformer aggressively
  runs on all CSS files in a given package. We hope to make this smoother in a
  future release.

* Do not generate `throwOnChanges` checks outside of dev-mode.

### Performance

* Bypasses the deprecated event plugin system for all native DOM events.
* At runtime `interpolate` is now represented by multiple functions (faster).
* `KeyValueDiffer` (`NgClass`, `NgStyle`) optimized for initial add/removals.
* No longer generates event handler registrations for directive outputs.

## 3.0.0

### New features

* `composeValidators` and `composeAsyncValidators` now part of the public API.
* `angular2/testing.dart` includes a test-only `isDebugMode` function.
*  (Forms) `AbstractControl.markAsDirty` now emits a status change event.

### Breaking changes

* Requires at least Dart SDK `1.23.0`.

* Injecting `null` is no longer supported.

* Remove unused `useProperty` argument in DI `Provider` api.

* `ReflectionCapabilities.isReflectionEnabled` renamed to `reflectionEnabled`.

* Malformed CSS warnings are errors now.

* Removed forms async validators. Alternative:

  ```dart
  control.valueChange((value) {
    rpc.validate(change).then((errors) {
      if (errors != null) control.setErrors(errors);
    });
  });
  ```

* Removed `TitleService`. To update the title, use `dart:html`:

  ```dart
  document.title = 'My title';
  ```

* `DynamicComponentLoader` now has a simplified API:

  `loadAsRoot`, `loadAsRootIntoNode` replaced by a single `load` method that
  always creates the component root node instead of hoisting into an existing
  node.

*  Removed `viewBindings` from `Component`. This has been interchangeable with
   `viewProviders` for a while now.

   **BEFORE:** `dart @Component(viewBindings: const [])`

   **AFTER:** `dart @Component(viewProviders: const [])`

*  Removed `EventManager` from the public API. Code generation is now closer to
   `document.addEventListener` and having this interception layer would not
   allow further optimizations.

*  Removed `IterableDifferFactory` and `KeyValueDifferFactory` from the public
   API. We have planned compiler optimizations that will no longer allow
   overriding our diffing implementations. Looking into alternatives before a
   final `3.0.0` release that are lower cost.

*  `ASYNC_VALIDATORS` can no longer return a `Stream` instance, only `Future`.

*  The experimental `NgTestBed` was removed. Use `package:angular_test` now.

*  By default, the `ExceptionHandler` is a `BrowserExceptionHandler`, which
   prints exceptions to the console. If you don't want this behavior (i.e.
   releasing to production), make sure to override it.

* `ElementRef.nativeElement` is now `final` (no setter).

*   DOM adapter is now completely removed from the API and generated code

*   A `name` parameter is now _required_ for all `@Pipe(...)` definitions:

    **BEFORE:** `dart @Pipe(name: 'uppercase')`

    **AFTER:** `dart @Pipe('uppercase')`

*   `DomEventsPlugin` now requires a strongly typed interface to `dart:html`.

*   `Null` is no longer propagated as an initial change value. Code should be
    updated to either deliver a different initial value or components with an
    `@Input()` should have an appropriate default value.

    **BEFORE**

    ```dart
    <my-component [value]="null"></my-component>
    ...
    String _value;

    set value(String value) {
      _value = value ?? 'Default name';
    }
    ```

    **AFTER**

    ```dart
    String _value = 'Default name';

    set value(String value) { _value = value; }
    ```

*   Removed the `isFirstChange()` method of `SimpleChange`.
    Instead, check whether `previousValue` is `null`.

*   Removed `NgPlural`, deprecated as of 2.1.0.

*   Removed `ObservableListDiffFactory`, deprecated as of 2.1.0.

*   Event handlers are bound at initialization time. Therefore, the following
    will no longer work, because `clickHandler` is `null` during initialization.

    ```dart
    @Component(
        selector: 'my-component',
        template: '<div (click)="clickHandler($event)"></div>')
    class MyComponent {
      Function clickHandler;
    }
    ```

*   Removed `Component.moduleId`, which was unused.

### Deprecations

* `@View` will be removed in `4.0`, only use `@Component` instead.
* `EventEmitter` is now `@Deprecated`: Use `Stream` and `StreamController`.
* `ngSwitchCase` replaces `ngSwitchWhen` (soft deprecation).
* `XHR` is deprecated, along with the runtime/reflective compiler.
*  `IterableDiffers` and `KeyValueDiffers` are deprecated. The cost of looking
   up to see if a custom differ is available is too high for almost no use.
   Before they're removed, we'll have other customization options.

### Bug fixes

* Updated various documentation to make cleaner and use Dart, not TS, samples.
* Perf: Added performance improvements around generated code and type inference.
* Fix: Key-value differ now detects removals when first key moves.
* Fix: `<ng-content select="...">` does not emit incorrect code (regression).
* Perf: Optimized how reflective providers are resolved on application startup.
* `ngSwitchWhen` now properly compares identity in Dartium.
* `Component/Directive#selector` is now a `@required` property.
* Angular warns in the console if using Dartium without _checked_ mode.
* Various performance improvements for both code size and runtime.
* Various Dart idiomatic/style guide updates to the codebase.
* `ngIf` now throws again if the bound value changes during change detection.
* Fixed a bug where the router didn't work on a root path in IE11.
* Fixed generated code that caused a strong-mode warning on `AppView<...>`.
* Fixed a bug where DDC didn't work properly with "pure" `Pipe`s.
* Some simple types are now propagated to the generated `.template.dart` file.
* When setting up a new `NgControl`, `valueAccessor` no longer can throw an NPE
*  Re-enabled `strong-mode` analysis within the project, and fixed some errors.

### Refactoring

* We now use the formal `<T>` generic type syntax for methods, not `/*<T>*/`.
* Removed `NgZoneImpl`, all the code exists in `NgZone` now.
* We now generate specific code for view and content children (faster).
* Projectable nodes now use the visitor pattern in `AppView`.
* In generated `.template.dart` change detected primitives are typed.
* Moved `renderType` as a static class member in generated code.

## 2.2.0

### API changes
  * Breaking changes
    * Using `@ViewQuery|Children|Content|` in a constructor is no longer valid.
      This caused significant extra code to need to be generated for a case that
      is relatively rare. Code can safely be moved into a setter in most cases.

**BEFORE**
```dart
class MyComponent {
  QueryList<ChildComponent> _childComponents;

  MyComponent(@ContentChildren(ChildComponent) this._childComponents);
}
```

**AFTER**
```dart
class MyComponent {
  QueryList<ChildComponent> _childComponents;

  @ContentChildren(ChildComponent)
  set childComponents(QueryList<ChildComponent> childComponents) {
    _childComponents = childComponents;
  }
}
```

### Bug fixes
  * Importing `angular2/reflection.dart` now works properly.

## 2.1.1

### API changes
  * Introduced `angular2/reflection.dart` as canonical way to opt-in to mirrors.
    In 2.2.0 it will be considered deprecated to enable runtime reflection by
    any other means.

## 2.1.0

### API changes
 * Breaking changes
   * `NgControlStatus` no longer included in `COMMON_DIRECTIVES` and in
     `FORM_DIRECTIVES`. Needs to be manually included in your bootstrap or
     migrated off of
 * Deprecations
   * Using `@Query` in a component constructor; move to field-level
   * `Renderer`: Use `dart:html` directly
   * `NgControlStatus`: A form control should set class they are interested in
   * `NgPlural`: Was never formally supported in Angular Dart. Recommend using
     `package:intl` with getters on your `@Component` pointing to an
     `Intl.message` call until we have formal template support (planned)
   * `ObservableListDiff`: Not properly implemented, will re-introduce later
 * Removed support for `InjectorModule` - was never formally supported

### Bug fixes and other changes
 * Documentation fixes and cleanups across the codebase
 * Code size and runtime performance improvements across the codebase
 * More reduction of STRONG_MODE exceptions in the compiler
 * Removed `InjectorModule` code (from TS-transpiler era)
 * Fixed a bug with `ExceptionHandler` not being called during change detection
 * Fixed a bug where controls were not marked dirty when an error was set

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
