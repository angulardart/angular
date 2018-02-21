### New features

*   The compiler now reports an actionable error when an annotation is used on a
    private class member.

*   Added `InjectionError` and `NoProviderError`, which _may_ be thrown during
    dependency injection when `InjectionError.enableBetterErrors` is set to
    `true`. This is an experiment, and we may not complete this feature (and it
    could be rolled back entirely).

*   Added `@GenerateInjector`, a way to generate a factory for an `Injector`
    completely at compile-time, similar to `@Component` or `@Directive`. This
    replaces the experimental feature `@Injector.generate`, and can be used in
    conjunction with the `InjectorFactory` function type:

```dart
import 'my_file.template.dart' as ng;

@GenerateInjector(const [
  const Provider(A, useClass: APrime),
])
// The generated factory is your method's name, suffixed with `$Injector`.
final InjectorFactory example = example$Injector;
```

* You are now able to use an `OpaqueToken` or `MultiToken` as an annotation
  directly instead of wrapping it in `@Inject`. For example, the following
  classes are identically understood by AngularDart:

```dart
const baseUrl = const OpaqueToken<String>('baseUrl');

class Comp1 {
  Comp1(@Inject(baseUrl) String url);
}

class Comp2 {
  Comp2(@baseUrl String url);
}
```

### Breaking changes

*   Restricted the default visibility of all components and directives to
    `Visibility.local`. This means components and directives will no longer be
    available for injection by their descendants, unless their visibility is
    explicitly set to `Visibility.all`. This feature had a cost in code size but
    was rarely used, so it's now opt-in, rather than the default behavior.

*   We now use a different code-path for the majority of content and view
    queries, with the exception of places statically typed `QueryList`. While
    this is not intended to be a breaking change it could have timing
    implications.

*   Both `COMMON_DIRECTIVES` and `CORE_DIRECTIVES` are now deprecated, and
    should be replaced by `coreDirectives`. This is a no-op change (alias).

*   Removed the deprecated `EventEmitter` class from the public entrypoints.

### Bug fixes

*   An invalid event binding (`<comp (event-with-no-expression)>`) no longer
    crashes the parser during compilation and instead reports that such a
    binding is not allowed.

*   Corrects the behavior of `Visibility.local` to match documentation.

    Previously, a directive with `Visibility.local` was only injectable via an
    alias within its defining view. This meant the following was possible

    ```dart
    abstract class Dependency {}

    @Component(
      selector: 'dependency',
      template: '<ng-content></ng-content>',
      providers: const [
        const Provider(Dependency, useExisting: DependencyImpl),
      ],
      visibility: Visibility.local,
    )
    class DependencyImpl implements Dependency {}

    @Component(
      selector: 'dependent',
      ...
    )
    class Dependent {
      Dependent(Dependency _); // Injection succeeds.
    }

    @Component(
      selector: 'app',
      template: '''
        <dependency>
          <dependent></dependent>
        </dependency>
      ''',
      directives: const [Dependency, Dependent],
    )
    class AppComponent {}
    ```

    because both `DependencyImpl` and `Dependent` are constructed in the same
    method, thus the instance of `DependencyImpl` could be passed directly to
    `Dependent` without an injector lookup. However, the following failed

    ```dart
    @Component(
      selector: 'dependency',
      // `Dependent` will fail to inject `Dependency`.
      template: '<dependent></dependent>',
      directives: const [Dependent],
      providers: const [
        const Provider(Dependency, useExisting: DependencyImpl),
      ],
      visibility: Visibility.local,
    )
    class DependencyImpl implements Dependency {}
    ```

    because no code was generated for children to inject `Dependency`. This was
    at odds with the documentation, and optimized for a very specific use case.

    This has been fixed and it's now possible for all children of
    `DependencyImpl` to inject `Dependency`, not just those constructed in the
    same view.

*   Services that were _not_ marked `@Injectable()` are _no longer skipped_ when
    provided in `providers: const [ ... ]` for a `@Directive` or `@Component`.
    This choice made sense when `@Injectable()` was required, but this is no
    longer the case. Additionally, the warning that was printed to console has
    been removed.

*   It is no longer a build warning to have an injectable service with multiple
    constructors. This was originally meant to keep injection from being too
    ambiguous, but there are understood patterns now (first constructor), and
    there is no alternative present yet. We may re-add this as a warning if
    there ends up being a mechanism to pick a constructor in the future.

*   It is no longer a build warning to have injectable services or components
    with named constructor parameters. While they are still not supported for
    injected, they were always successfully ignored in the past, and showing a
    warning to the user on every build served no purpose.

*   If a `templateUrl` is mispelled, a more readable exception is thrown (closes
    https://github.com/dart-lang/angular/issues/389):

    ```shell
    [SEVERE]: Unable to read file:
      "package:.../not_a_template.html"
      Ensure the file exists on disk and is available to the compiler.
    ```

*   If both `template` AND `templateUrl` are supplied, it is now a cleaner build
    error (closes https://github.com/dart-lang/angular/issues/451):

    ```shell
    [SEVERE]: Component "CompWithBothProperties" in
      asset:experimental.users.matanl.examples.angular.template_url_crash/lib/template_url_crash.dart:
      Cannot supply both "template" and "templateUrl"
    ```

*   If _neither_ is supplied, it is also a cleaner build error:

    ```shell
    [SEVERE]: Component "CompWithNoTemplate" in
      asset:experimental.users.matanl.examples.angular.template_url_crash/lib/template_url_crash.dart:
      Requires either a "template" or "templateUrl"; had neither.
    ```

*   If a `template` is a string that points to a file on disk, we now warn:

    ```shell
    [WARNING]: Component "CompMeantTemplateUrl" in
      asset:experimental.users.matanl.examples.angular.template_url_crash/lib/template_url_crash.dart:
      Has a "template" property set to a string that is a file.
      This is a common mistake, did you mean "templateUrl" instead?
    ```

*  If a private class is annotated with `@Injectable()` the compiler fails. In
   practice this caused a compilation error later in DDC/Dart2JS, but now the
   AngularDart compiler will not emit invalid code.

## 5.0.0-alpha+5

### New features

*   Enables the new template parser by default. This parser is much stricter
    than the old one, as it will detect things like missing closing tags or
    quotation marks.

    If you need to turn it off temporarily, you need to set the following flag
    in your `build.yaml`:

    ```yaml
    targets:
      $default:
        builders:
          angular:
            options:
              use_new_template_parser: false
    ```

*   Requires `source_gen ^0.7.4+2` (was previously `^0.7.0`).

*   The compiler behind `initReflector()` has changed implementations and now
    uses fully-scoped import statements instead of trying to figure out the
    original scope (including import prefixes) of your source code. This is not
    intended to be a breaking change.

### Breaking changes

*   **We have removed the transformer completely from `angular`.** It is now a
    requirement that you use `build_runner` to build `angular`. For more
    details, see [Building Angular][building_angular].

*   `QueryList` is now formally *deprecated*. See
    `doc/deprecated_query_list.md`. This feature is not compatible with future
    restrictions of Dart 2, because `QueryList` was always created as a
    `QueryList<dynamic>`, even though users expected it to be a `QueryList<T>`.
    The new API is fully compatible.

*   `SlowComponentLoader` is now formally *deprecated*. See
    `doc/component_loading.md`. This feature is not compatible with future
    restrictions of AngularDart, because it requires collecting metadata and
    disabling tree-shaking of classes annotated with `@Component`. The newer API
    is nearly fully compatible, is faster, and will be supported long-term.

*   Explicitly remove support for `ngNonBindable` in the new template parser.

*   Both `@Component.host` and `@Directive.host` were deprecated several
    versions back, but not properly, so warnings never appeared in IDEs. They
    are now properly deprecated: `'Use @HostBinding() on a getter or
    @HostListener on a method'`.

*   `ElementRef` is now deprecated. Inject `Element` or `HtmlElement` instead.
    This has unnecessary overhead on-top of the native DOM bindings without any
    benefit.

[building_angular]: https://github.com/dart-lang/angular/blob/master/doc/building_angular.md

### Bug fixes

*   The experimental feature `@Injector.generate` now supports some `const`
    expressions in a Provider's `useValue: ...`. There are remaining known
    issues with this implementation, and `useFactory` should be used instead if
    you encounter issues.

*   Fixed a bug where a `Injector.get` call where `Injector` is a
    `ReflectiveInjector` (which is also the injector most commonly used for both
    the entrypoint and virtually every test) would throw `No provider found for
    X`, where `X` was a class or factory that _was_ found but one or more of
    `X`'s dependencies were not found. We now correctly throw `No provider found
    for Y` (where `Y` was that actual missing dependency).

*   `OpaqueToken<T>` was emitted as `OpaqueToken<dynamic>` when you used nested
    views (`<div *ngIf="..."><comp></comp></div>`), and `<comp>` was a component
    or directive that `@Inject`-ed a typed token (like `OpaqueToken<String>`);
    this is now fixed.

*   Trying to use `@{Content|View}Child{ren}` with `Element` or `HtmlElement`
    (from `dart:html`) caused a runtime exception, as `ElementRef` was passed
    instead. The following now works:

```dart
@Component(
  selector: 'uses-element',
  template: '<div #div>1</div>'
)
class UsesElement {
  @ViewChild('div')
  // Could also be HtmlElement.
  Element div;
}
```

## 5.0.0-alpha+4

*   We have a new template parser. This parser is much stricter than the old
    one, as it will detect things like missing closing tags or quotation marks.
    Enabling it will be a major breaking change, so we encourage you to try it
    out in this alpha release before we enable it by default in the next one.

    In order to use it, you need to set the following flag in your `build.yaml`:

    ```yaml
    targets:
      $default:
        builders:
          angular:
            options:
              use_new_template_parser: true
    ```

*   We now require `code_builder ^3.0.0`.

### New features

*   Using `OpaqueToken<T>` and `MutliToken<T>` where `T` is not `dynamic` is now
    properly supported in all the different implementations of Injector. As a
    consequence relying on the following is now a breaking change:

    ```dart
    // These used to be considered the same in some DI implementations.
    const tokenA = const OpaqueToken<String>('a');
    const tokenB = const OpaqueToken<dynamic>('b');
    ```

*   Added a lifecycle event `AfterChanges`, which is similar to `OnChanges`, but
    with a much lower performance cost - it does not take any parameters and is
    suitable when you have multiple fields and you want to be notified when any
    of them change:

    ```dart
    class Comp implements AfterChanges {
      @Input()
      String field1;

      @Input()
      String field2;

      @override
      void ngAfterChanges() {
        print('Field1: $field1, Field2: $field2');
      }
    }
    ```

### Breaking changes

*   `ComponentRef.componentType` throws an `UnsupportedError`, pending removal.
    This removes our last invocation of `.runtimeType`, which has potentially
    severe code-size implications for some apps.
*   The type of `EmbeddedViewRef.rootNodes` and `ViewRefImpl.rootNodes` has
    changed from `List<dynamic>` to `List<Node>`.

### Bug fixes

*   Fixed a bug where `Provider(T)` was not correctly parsed as an implicit use
    of `Provider(T, useClass: T)`.

## 5.0.0-alpha+3

### New features

*   `Provider` is now soft-deprecated (not preferred), and new more-typed
    classes exist: `ClassProvider`, `ExistingProvider`, `FactoryProvider`, and
    `ValueProvider`. Each also has a `.forToken` named constructor that infers
    the `Provider<T>`'s `T` value from the provided `OpaqueToken<T>`'s `T`. This
    is meant to help with the move to strong mode and DDC, and is now the
    preferred way to configure dependency injection.

*   Any variation of `multi: true` when configuring dependency injection is now
    soft-deprecated (not preferred), and the `MultiToken` class has been added.
    A `MultiToken<T>` now represents an `OpaqueToken<T>` where `multi: true` is
    implicitly always `true`:

    ```dart
    const usPresidents = const MultiToken<String>('usPresidents');

    @Component(
      selector: 'presidents-list',
      providers: const [
        const ValueProvider.forToken(usPresidents, 'George Washington'),
        const ValueProvider.forToken(usPresidents, 'Abraham Lincoln'),
      ],
    )
    class PresidentsListComponent {
      // Will be ['George Washington', 'Abraham Lincoln'].
      final List<String> items;

      PresidentsListComponent(@Inject(usPresidents) this.items);
    }
    ```

*   We are starting to support the new build system at `dart-lang/build`. More
    information and documentation will be included in a future release, but we
    expect to drop support for `pub serve/build` by 5.0.0 final.

### Breaking changes

*   Dartium is no longer supported. Use [dartdevc][ddc] and Chrome instead when
    developing your AngularDart apps. With incoming language and library
    changes, using dartdevc would have been required regardless, but we expect
    to have faster build tools available (instead of `pub serve`) soon.

[ddc]: https://webdev.dartlang.org/tools/dartdevc

### Bug fixes

*   Fixed a bug where `ReflectiveInjector` would return an `Object` instead of
    throwing `ArgumentError` when resolving an `@Injectable()` service that
    injected a dependency with one or more annotations (i.e. `@Inject(...)`).

*   Fixed a bug where `DatePipe` didn't format`millisecondsSinceEpoch` in the
    local time zone (consistent with how it formats `DateTime`).

## 5.0.0-alpha+2

### Breaking changes

*   Replaced `Visibility.none` with `Visibility.local`. The former name is
    misleading, as a directive is always capable of providing itself locally for
    injection via another token.

*   `RenderComponentType` is no longer part of the public API.

*   Dropped support for `@AngularEntrypoint` and rewriting entrypoints to
    automatically use `initReflector()` and `bootstrapStatic`. This will no
    longer be supported in the new build system so we're encouraging that manual
    changes are made as of this release:

    ```dart
    // test/a_test.dart

    import 'a_test.template.dart' as ng;

    void main() {
      ng.initReflector();
    }
    ```

    ```dart
    // web/a_app.dart

    import 'package:angular/angular.dart';
    import 'a_app.template.dart' as ng;

    @Component(selector: 'app', template: '')
    class AppComponent {}

    void main() {
      bootstrapStatic(AppComponent, [/*providers*/], ng.initReflector);
    }
    ```

*   Use of the template annotation `@deferred` does not work out of the box with
    the standard bootstrap process (`bootstrap/bootstrapStatic`), only the
    experimental `bootstrapFactory`. We've added a backwards compatible compiler
    flag, `fast_boot`, that may be changed to `false`. We don't expect this to
    impact most users.

    ```yaml
    transformers:
      angular:
        fast_boot: false
    ```

### Bug fixes

*   Fixed a bug where errors thrown in event listeners were sometimes uncaught
    by the framework and never forwarded to the `ExceptionHandler`. Closes
    https://github.com/dart-lang/angular/issues/721.

*   The `$implicit` (iterable) value in `*ngFor` is now properly typed whenever
    possible. It was previously always typed as `dynamic`, which caused dynamic
    lookups/calls at runtime, and hid compilation errors.

*   Fixed a bug where an `@deferred` components were still being linked to in
    `initReflector()`.

### Refactors

*   Added `Visibility.all` as the default visibility of all directives. This has
    no user-facing implications yet, but will allow migrating the default from
    `Visibility.all` to `Visibility.local`.

## 5.0.0-alpha+1

**NOTE**: As of `angular 5.0.0-alpha+1` [`dependency_overrides`][dep_overrides]
are **required**:

```yaml
dependency_overrides:
  analyzer: ^0.31.0-alpha.1
```

This is because we are starting to use and support the Dart 2.0.0 SDK, which is
evolving. We expect to no longer require overrides once we are at a beta
release, but this is unlikely until sometime in early 2018.

[dep_overrides]: https://www.dartlang.org/tools/pub/dependencies#dependency-overrides

### New features

*   Added an optional input to `NgTemplateOutlet` named
    `ngTemplateOutletContext` for setting local variables in the embedded view.
    These variables are assignable to template input variables declared using
    `let`, which can be bound within the template. See the `NgTemplateOutlet`
    documentation for examples.

### Breaking changes

*   Removed `WrappedValue`. `AsyncPipe.transform` will no longer return a
    `WrappedValue` when the transformed result changes, and instead will rely on
    regular change detection.

*   Pipes no longer support private types in their `transform` method signature.
    This method's type is now used to generate a type annotation in the
    generated code, which can't import private types from another library.

*   Removed the following from the public API:

    *   `APPLICATION_COMMON_PROVIDERS`
    *   `BROWSER_APP_COMMON_PROVIDERS`
    *   `BROWSER_APP_PROVIDERS`
    *   `PACKAGE_ROOT_URL`
    *   `ErrorHandlingFn`
    *   `UrlResolver`
    *   `WrappedTimer`
    *   `ZeroArgFunction`
    *   `appIdRandomProviderFactory`
    *   `coreBootstrap`
    *   `coreLoadAndBootstrap`
    *   `createNgZone`
    *   `createPlatform`
    *   `disposePlatform`
    *   `getPlatform`

In practice, most of these APIs were never intended to be public and never had a
documentation or support, and primarily existed for framework-internal
consumption. Others have been made obsolete by new language features in Dart.

In particular, the `UrlResolver` class was no longer needed by the framework
itself, and there is a cost to supplying APIs that we don't use. Clients that
need this code (_deprecated as of 4.x_) can copy it safely into their own
projects.

*   Removed unused `context` parameter from `TemplateRef.createEmbeddedView`.

*   Removed deprecated getters `onStable`|`onUnstable` from `NgZone`. They have
    been reachable as `onTurnDone`|`onTurnStart` for a few releases.

### Bug fixes

*   Correctly depend on `analyzer: ^0.31.0-alpha.1`.

### Refactors

*   Use the new generic function syntax, stop using `package:func`.
*   Now using `code_builder: '>=2.0.0-beta <3.0.0'`.

## 5.0.0-alpha

**We are now tracking the Dart 2.0 SDK**. It is _not_ recommended to use the
_5.0.0-alpha_ series of releases unless you are using a recent dev release of
the Dart SDK. We plan to exit an alpha state once Dart 2.0 is released.

If you are individually depending on `angular_compiler`, we require:

```yaml
dependencies:
  angular_compiler: '^0.4.0-alpha`
```

### New features

*   Both `ComponentFactory` and `ComponentRef` are now properly typed `<T>`
    where `T` is the type of the `@Component`-annotated class. Prior to this
    release, `ComponentFactory` did not have a type, and `ComponentRef<T>` was
    always `ComponentRef<dynamic>`.

### Breaking changes

*   `preserveWhitespace` is now `false` by default in `@Component`. The old
    default behavior can be achieved by setting `preserveWhitespace` to `true`.

*   Classes annotated `@Component` can no longer be treated like services that
    were annotated with `@Injectable()`, and now fail when they are used within
    a `ReflectiveInjector`. Similar changes are planned for `@Directive`.

*   Removed `inputs` field from `Directive`. Inputs now must be declared using
    inline `@Input` annotations.

### Bug fixes

*   Fixed a bug where injecting the `Injector` in a component/directive and
    passing a second argument (as a default value) always returned `null`. It
    now correctly returns the second argument (closes
    [#626](https://github.com/dart-lang/angular/issues/612)).

*   No longer invoke `ExceptionHandler#call` with a `null` exception.

*   Using `Visibility.none` no longer applies to providers directly on the
    `@Component` or `@Directive`; in practice this makes `none` closer to the
    `local` visibility in AngularDart v1, or `self` elsewhere in AngularDart; we
    might consider a rename in the future.

*   Fixed a bug where the hashcode of an item passed via `ngFor` changing would
    cause a strange runtime exception; while it is considered unsupported for a
    mutable object to have an overridden `hashCode`, we wanted the exception to
    be much better.

### Refactors

*   The `StylesheetCompiler` is now a `Builder`, and is being integrated as part
    of the template code genreator instead of a separate build action. This will
    let us further optimize the generated code.

### Performance

*   Types bound from generics are now properly resolved in a component when
    inheriting from a class with a generic type. For example, the following used
    to be untyped:

    ```dart
    class Container<T> {
      @Input()
      T value;
    }

    class StringContainerComponent implements Container<String> {}
    ```

## 4.0.0

**We are now named `package:angular` instead of `package:angular2`**. As such
you cannot `pub upgrade` from `angular2 3.x` -> `angular2 4.x`, and you need to
manually update your dependencies instead:

```yaml
dependencies:
  angular: ^4.0.0
```

AngularDart will start tracking the upcoming Dart 2.0 alpha SDK, and as such,
4.0.0 will be the _last_ stable release that fully supports Dart 1.24.0. We may
release small patches if needed, but otherwise the plan is to release 4.0.0 and
then immediately start working on `5.0.0-alpha`, which uses the new Dart SDK.

### Breaking changes

*   `@Pipe`-annotated classes are no longer considered `@Injectable`, in that
    they aren't usable within a `ReflectiveInjector`. You can get this behavior
    back by adding the `@Injectable()` annotation to the `@Pipe`-annotated
    class. Similar changes are in progress for `@Component` and `@Directive`.

*   `PLATFORM_{PIPES|DIRECTIVES|PROVIDERS}`, which was only supported in an
    older version of the compiler, was removed. All of these must be manually
    included in lists in an `@Directive` or `@Component` annotation.

*   Removed `formDirectives` from `COMMON_DIRECTIVES` list; replace
    `COMMON_DIRECTIVES` with `[CORE_DIRECTIVES, formDirectives]` for components
    that use forms directives.

*   Forms API has been moved to a new package, `angular_forms`, which is going
    to be versioned and maintained alongside the core framework. This should
    allow better segmentation of code and easier contributions.

*   The router package is now being published separate as
    `package:angular_router` (not through `package:angular/router.dart`). In the
    near future it will be updated to a more Dart idiomatic "2.0" router, but
    for now it is an exact replica of the previous router.

*   Removed `@{Component|Directive}#queries`. This is replable using the same
    member-level annotation (i.e. `@{Content|View}Child{ren}`).

*   `DynamicComponentLoader` was renamed `SlowComponentLoader` to encourage
    users to prefer `ComponentLoader`. Additionally, arguments
    `projectableNodes:` and `onDestroy:` callbacks were removed - they were
    mostly unused, and confusing since they were undocumented.

*   Removed `angular/platform/browser_static.dart`; replace imports with
    `angular/angular.dart`.

*   Removed `angular/platform/common_dom.dart`; replace imports with
    `angular/angular.dart`.

*   Removed `angular/testing.dart`; Use `angular_test` package instead.

*   Removed `angular/platform/testing.dart`.

*   Removed `platform/testing/browser_static.dart`.

*   Removed `MockNgZone`.

*   Removed `ViewEncapsulation.native`, which is no longer supported.

*   Renamed `FORM_DIRECTIVES` to `formDirectives`.

*   Removed `angular/common.dart`; replace imports with `angular/angular.dart`.

*   Removed `angular/compiler.dart`; compiler should only be invoked via the
    transformers or via `pkg:build` directly using `angular/source_gen.dart`.

*   Deprecated `@View()` annotation was completely removed.

*   Deprecated second parameter to `ExceptionHandler` was completely removed.

*   Removed the runtime (`dart:mirrors`-based) interpreter. It is now required
    to always use the AngularDart transformer to pre-compile the code, even
    during development time in Dartium. `package:angular2/reflection.dart` was
    also removed.

*   The `bootstrap` function now always throws a runtime exception, and both it
    and `bootstrapStatic` are accessible via `angular.dart` instead of
    `platform/browser.dart` and `platform/browser_static.dart`
    [#357](https://github.com/dart-lang/angular/issues/357).

*   Returning `false` from an event handler will no longer cancel the event. See
    [#387](https://github.com/dart-lang/angular2/issues/387) for details.

*   Removed `Query` and `ViewQuery`. Please use `ContentChild`/`ContentChildren`
    and `ViewChild`/`ViewChildren` in their place instead.

*   Removed the `use_analyzer` flag for the transformer. This is always `true`.
    [#404](https://github.com/dart-lang/angular/issues/404).

*   Removed all other unused or unsupported flags from the transformer. There is
    now a single `CompilerFlags` class that is universally supported for all
    build systems.

*   Removed a number of classes that were never intended to be public.

*   Removed the second parameter to `ExceptionHandler`, which was a no-op
    anyway.

*   Removed `outputs` field from `Directive`. Outputs now must be declared using
    inline `Output` annotations.

### New features

*   Added support for functional directives: lightweight, stateless directives
    that apply a one-time transformation.

    *   One is defined by annotating a public, top-level function with
        `@Directive()`.

    *   The function parameters specify its dependencies, similar to the
        constructor of a regular directive.

    *   Only the `selector` and `providers` parameters of the `@Directive()`
        annotation are permitted, because the other parameters are stateful.

    *   The function return type must be `void`.

```dart
@Directive(selector: '[autoId]')
void autoIdDirective(Element element, IdGenerator generator) {
  element.id = generator.next();
}
```

*   Added `visibility` property to `Directive`. Directives and components that
    don't need to be injected can set `visibility: Visibility.none` in their
    annotation. This prevents the compiler from generating code necessary to
    support injection, making the directive or component non-injectable and
    reducing the size of your application.

```dart
// This component can't be injected by other directives or components.
@Component(selector: 'my-component', visibility: Visibility.none)
class MyComponent { ... }
```

*   Added `ComponentLoader`, a high-level imperative API for creating components
    at runtime. It uses internal code-paths that already existed, and is much
    more future proof. `ComponentLoader` is usable within a `@Directive()`, an
    `@Component()`, and injectable services.

```dart
// An `ExampleComponent`s generated code, including a `ComponentFactory`.
import 'example.template.dart' as ng;

class AdBannerComponent implements AfterViewInit {
  final ComponentLoader _loader;

  AdBannerComponent(this._loader);

  @override
  ngAfterViewInit() {
    final component = _loader.loadDetached(ng.ExampleComponentNgFactory);
    // Do something with this reference.
  }
}
```

*   You can now directly inject `dart:html`'s `Element` or `HtmlElement` instead
    of `ElementRef`, which is "soft deprecated" (will be deprecated and removed
    in a future release).

*   `findContainer` has now been exposed from NgForm allowing easier creation of
    custom form implementations.

*   `setUpControl` has been exposed from the forms API to allow forms to setup
    their controls easier.

*   Inheritance for both component and directive metadata is now complete! Any
    field or method-level annotations (`@Input`, `@Output`,
    `@ViewChild|Children`, `@ContentChild|Children`) are now inherited through
    super types (`extends`, `implements`, `with`)
    [#231](https://github.com/dart-lang/angular/issues/231):

```dart
class BaseComponent {
  @Input()
  String name;
}

// Also has an input called "name" now!
@Component(selector: 'comp')
class ConcreteComponent extends BaseComponent {}
```

*   Inputs that are of type `bool` now receive a default value of `true` instead
    of a value of `null` or an empty string. This allows a much more
    HTML-friendly syntax for your components:

```html
<!-- All of these set a value of disabled=true -->
<fancy-button disabled></fancy-button>
<fancy-button [disabled]></fancy-button>
<fancy-button [disabled]="true"></fancy-button>

<!-- Value of disabled=false -->
<fancy-button [disabled]="false"></fancy-button>
```

```dart
@Component()
class FancyButton {
  @Input()
  bool disabled = false;
}
```

*   Added `exports: [ ... ]` to `@Component`, which allows the limited use of
    top-level fields and static methods/fields in a template without making an
    alias getter in your class. Implements
    [#374](https://github.com/dart-lang/angular/issues/374).

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

*   _Limitations_:

    *   Only top-level fields that are `const` (not `final`) can be exported.

*   Added `@deferred` as the first "compile-time" directive (it has no specific
    runtime code nor is it listed in a `directives: [ ... ]` list. Implements
    [#406](https://github.com/dart-lang/angular/issues/406).

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

*   Added preliminary support for component inheritance. Components now inherit
    inputs, outputs, host bindings, host listeners, queries, and view queries
    from all supertypes.

*   We use a new open sourcing tool called "[CopyBara][]" that greatly
    simplifies both releasing and taking open source contributions. We are able
    to release to github more often, and accept PRs much more easily. You can
    view our bleeding [`github-sync`][github-sync] branch for what has yet to be
    merged into `master`.

*   We no longer emit `ng_*.json` files as part of the compile process
    [#276](https://github.com/dart-lang/angular/issues/276).

*   Attribute selectors (`<ng-content select="custom-action[group='1']">`) is
    now supported [#237](https://github.com/dart-lang/angular/issues/237).

*   Lifecycle interfaces no longer need to be "re-implemented" on classes in
    order for the compiler to pick them up - we now respect the dependency chain
    [#19](https://github.com/dart-lang/angular/issues/19).

*   `Provider(useValue: ...)` now accepts "complex const data structures", with
    the caveat that your data structure must not be invoking a private
    constructor [#10](https://github.com/dart-lang/angular/issues/10).

[CopyBara]: https://github.com/google/copybara
[github-sync]: https://github.com/dart-lang/angular/tree/github-sync

### Deprecations

*   Support for shadow piercing combinators `/deep/` and `>>>` to prevent style
    encapsulation is now deprecated. `/deep/` is already deprecated and will be
    [removed in Chrome 60][deep-removal]. Its alias `>>>` is limited to the
    [static profile of selectors][static-profile], meaning it's not supported in
    style sheets. Continued use of these combinators puts Angular at risk of
    incompatibility with common CSS tooling. `::ng-deep` is a drop-in
    replacement, intended to provide the same functionality as `/deep/` and
    `>>>`, without the need to use deprecated or unsupported CSS syntax
    [#454](https://github.com/dart-lang/angular/issues/454).

[deep-removal]: https://www.chromestatus.com/features/4964279606312960
[static-profile]: https://drafts.csswg.org/css-scoping/#deep-combinator

### Bug fixes

*   Compiler now warns when annotations are added to private classes or
    functions.

*   Compiler now warns when injecting into a field that is non-existent.

*   Fixed a long-standing bug on `ngSwitch` behavior in Dartium.

*   Fixed a bug in `@deferred` when nested views has DI bindings. Fixes
    [#578](https://github.com/dart-lang/angular/issues/578).

*   The transformer now fails if any unsupported arguments are passed in.

*   Fixed a bug where `@deferred` did not work nested inside of `<template>`:

```html
<template [ngIf]="someCondition">
  <expensive-comp @deferred></expensive-comp>
</template>
```

*   `ngForm` now allows `onSubmit` to be called with a `null` value.

*   Using `inputs|outputs` in the `@Component` annotation to rename an existing
    `@Input()` or `@Output()` now logs and fails the build during compilation.

*   Symbol collisions with `dart:html` no longer cause a runtime exception, all
    framework use of `dart:html` is now scoped behind a prefixed import.

*   Properly annotate methods in generated `.template.dart` code with
    `@override`.

*   Updated the documentation for `OnInit` and `OnDestroy` to mention more
    specifics about the contract and document "crash detection" cases where they
    may be called more than once.

*   `*ngIf` now properly checks that inputs do not change during change
    detection [#453](https://github.com/dart-lang/angular/issues/453).

*   Properly typed `TrackByFn` as an `int` not a `num`
    [#431](https://github.com/dart-lang/angular/issues/431).

*   Import aliases are supported by the compiler
    [#245](https://github.com/dart-lang/angular/issues/245).

### Performance

*   Various small reductions to the size of generated code and the runtime.

*   Directives now generate their own change detector class (behind the scenes)
    instead of the code being re-created into every component that uses a
    directive.

*   Remove redundant calls to `dbg(...)` in dev-mode. This reduces the amount of
    work done and speeds up developer runtimes, such as those using the
    [DartDevCompiler
    (DDC)](https://github.com/dart-lang/sdk/tree/master/pkg/dev_compiler).

*   Some change detection code that was duplicated across all generated
    templates were moved internally to a new `AppView#detectHostChanges` method.

*   Introduced a new `AppViewData` structure in the generated code that
    decreases code size ~2% or more in some applications due to better code
    re-use and emit in dart2js.

*   We no longer change detect literals and simple `final` property reads.

*   Some of the enums used to manage change detection state have been simplified
    to `int` in order to reduce the cost in the generated code.

## 3.1.0

### New features

*   Exposed `TouchFunction` and `ChangeFunction` typedefs to make the transition
    to strong-mode easier for teams relying on these function definitions. We
    might remove them in a future release when they are no longer needed.

*   Added a flag to use an experimental new compiler that uses the Dart analyzer
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

*   Using `dart:mirrors` (i.e. running AngularDart without code generation) is
    now formally deprecated. In `4.0+` code generation will be the only way to
    run an AngularDart application, even in development mode. Please ensure you
    are using our transformer: https://goo.gl/rRHqO7.

### Bug fixes

*   CSS errors are now just warnings, and can be ignored. This is due to using a
    CSS parser for encapsulation - and the AngularDart transformer aggressively
    runs on all CSS files in a given package. We hope to make this smoother in a
    future release.

*   Do not generate `throwOnChanges` checks outside of dev-mode.

### Performance

*   Bypasses the deprecated event plugin system for all native DOM events.
*   At runtime `interpolate` is now represented by multiple functions (faster).
*   `KeyValueDiffer` (`NgClass`, `NgStyle`) optimized for initial add/removals.
*   No longer generates event handler registrations for directive outputs.

## 3.0.0

### New features

*   `composeValidators` and `composeAsyncValidators` now part of the public API.
*   `angular2/testing.dart` includes a test-only `isDebugMode` function.
*   (Forms) `AbstractControl.markAsDirty` now emits a status change event.

### Breaking changes

*   Requires at least Dart SDK `1.23.0`.

*   Injecting `null` is no longer supported.

*   Remove unused `useProperty` argument in DI `Provider` api.

*   `ReflectionCapabilities.isReflectionEnabled` renamed to `reflectionEnabled`.

*   Malformed CSS warnings are errors now.

*   Removed forms async validators. Alternative:

    ```dart
    control.valueChange((value) {
      rpc.validate(change).then((errors) {
        if (errors != null) control.setErrors(errors);
      });
    });
    ```

*   Removed `TitleService`. To update the title, use `dart:html`:

    ```dart
    document.title = 'My title';
    ```

*   `DynamicComponentLoader` now has a simplified API:

    `loadAsRoot`, `loadAsRootIntoNode` replaced by a single `load` method that
    always creates the component root node instead of hoisting into an existing
    node.

*   Removed `viewBindings` from `Component`. This has been interchangeable with
    `viewProviders` for a while now.

    **BEFORE:** `dart @Component(viewBindings: const [])`

    **AFTER:** `dart @Component(viewProviders: const [])`

*   Removed `EventManager` from the public API. Code generation is now closer to
    `document.addEventListener` and having this interception layer would not
    allow further optimizations.

*   Removed `IterableDifferFactory` and `KeyValueDifferFactory` from the public
    API. We have planned compiler optimizations that will no longer allow
    overriding our diffing implementations. Looking into alternatives before a
    final `3.0.0` release that are lower cost.

*   `ASYNC_VALIDATORS` can no longer return a `Stream` instance, only `Future`.

*   The experimental `NgTestBed` was removed. Use `package:angular_test` now.

*   By default, the `ExceptionHandler` is a `BrowserExceptionHandler`, which
    prints exceptions to the console. If you don't want this behavior (i.e.
    releasing to production), make sure to override it.

*   `ElementRef.nativeElement` is now `final` (no setter).

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

*   Removed the `isFirstChange()` method of `SimpleChange`. Instead, check
    whether `previousValue` is `null`.

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

*   `@View` will be removed in `4.0`, only use `@Component` instead.
*   `EventEmitter` is now `@Deprecated`: Use `Stream` and `StreamController`.
*   `ngSwitchCase` replaces `ngSwitchWhen` (soft deprecation).
*   `XHR` is deprecated, along with the runtime/reflective compiler.
*   `IterableDiffers` and `KeyValueDiffers` are deprecated. The cost of looking
    up to see if a custom differ is available is too high for almost no use.
    Before they're removed, we'll have other customization options.

### Bug fixes

*   Updated various documentation to make cleaner and use Dart, not TS, samples.
*   Perf: Added performance improvements around generated code and type
    inference.
*   Fix: Key-value differ now detects removals when first key moves.
*   Fix: `<ng-content select="...">` does not emit incorrect code (regression).
*   Perf: Optimized how reflective providers are resolved on application
    startup.
*   `ngSwitchWhen` now properly compares identity in Dartium.
*   `Component/Directive#selector` is now a `@required` property.
*   Angular warns in the console if using Dartium without _checked_ mode.
*   Various performance improvements for both code size and runtime.
*   Various Dart idiomatic/style guide updates to the codebase.
*   `ngIf` now throws again if the bound value changes during change detection.
*   Fixed a bug where the router didn't work on a root path in IE11.
*   Fixed generated code that caused a strong-mode warning on `AppView<...>`.
*   Fixed a bug where DDC didn't work properly with "pure" `Pipe`s.
*   Some simple types are now propagated to the generated `.template.dart` file.
*   When setting up a new `NgControl`, `valueAccessor` no longer can throw an
    NPE
*   Re-enabled `strong-mode` analysis within the project, and fixed some errors.

### Refactoring

*   We now use the formal `<T>` generic type syntax for methods, not `/*<T>*/`.
*   Removed `NgZoneImpl`, all the code exists in `NgZone` now.
*   We now generate specific code for view and content children (faster).
*   Projectable nodes now use the visitor pattern in `AppView`.
*   In generated `.template.dart` change detected primitives are typed.
*   Moved `renderType` as a static class member in generated code.

## 2.2.0

### API changes

*   Breaking changes
    *   Using `@ViewQuery|Children|Content|` in a constructor is no longer
        valid. This caused significant extra code to need to be generated for a
        case that is relatively rare. Code can safely be moved into a setter in
        most cases.

**BEFORE** ```dart class MyComponent { QueryList<ChildComponent>
_childComponents;

MyComponent(@ContentChildren(ChildComponent) this._childComponents); } ```

**AFTER** ```dart class MyComponent { QueryList<ChildComponent>
_childComponents;

@ContentChildren(ChildComponent) set childComponents(QueryList<ChildComponent>
childComponents) { _childComponents = childComponents; } } ```

### Bug fixes

*   Importing `angular2/reflection.dart` now works properly.

## 2.1.1

### API changes

*   Introduced `angular2/reflection.dart` as canonical way to opt-in to mirrors.
    In 2.2.0 it will be considered deprecated to enable runtime reflection by
    any other means.

## 2.1.0

### API changes

*   Breaking changes
    *   `NgControlStatus` no longer included in `COMMON_DIRECTIVES` and in
        `FORM_DIRECTIVES`. Needs to be manually included in your bootstrap or
        migrated off of
*   Deprecations
    *   Using `@Query` in a component constructor; move to field-level
    *   `Renderer`: Use `dart:html` directly
    *   `NgControlStatus`: A form control should set class they are interested
        in
    *   `NgPlural`: Was never formally supported in Angular Dart. Recommend
        using `package:intl` with getters on your `@Component` pointing to an
        `Intl.message` call until we have formal template support (planned)
    *   `ObservableListDiff`: Not properly implemented, will re-introduce later
*   Removed support for `InjectorModule` - was never formally supported

### Bug fixes and other changes

*   Documentation fixes and cleanups across the codebase
*   Code size and runtime performance improvements across the codebase
*   More reduction of STRONG_MODE exceptions in the compiler
*   Removed `InjectorModule` code (from TS-transpiler era)
*   Fixed a bug with `ExceptionHandler` not being called during change detection
*   Fixed a bug where controls were not marked dirty when an error was set

## 2.0.0 Release

### API changes

*   Implemented NgTestBed to improve test infrastructure goo.gl/NAXXlN.
*   Removed Metadata classes used for angular annotations.
*   Added ComponentState to provide push change detection with better ergonomics
    and code generation.
*   ViewContainerRef.createEmbeddedView index parameter removed instead
    introduced insertEmbeddedView.
*   Added support for minimal code generation when user explicitly marks
    component with preserveWhitespace:false.

### Bug fixes and other changes

*   Improved ngFor performance.
*   Improved shared style host performance.
*   Improved @ViewChild/@ViewChildren performance.
*   Code and documentation cleanups.
*   Strong mode fixes.

## 2.0.0-beta.22

### API changes

*   **POTENTIALLY BREAKING** Observable features new use the new `observable`
    package, instead of `observe`.
*   Removed `Renderer.createViewRoot`.

### Bug fixes and other changes

*   Improved compiler errors.
*   Fixes to reduce code size.
*   Support the latest `pkg/build`.
*   Now require Dart SDK 1.19 at a minimum.
*   Added `.analysis_options` to enforce a number of style rules.

## 2.0.0-beta.21

Our push towards better performance has started showing results in this release.
This update provides 5-10% speedup in components. >20% reduction in Dart code
size emitted from compiler.

### API changes

*   Added support for '??' operator in template compiler.
*   Removed unused animation directives to create more Darty/compile time
    version.
*   Removed unused i18n pipes to prepare for dart:intl based solution.
*   Language facades removed (isPresent, isBlank, getMapKey, normalizeBool,
    DateWrapper, RegExpWrapper, StringWrapper, NumberWrapper, Math facades,
    SetWrapper, ListWrapper, MapWrapper, StringMapWrapper, ObservableWrapper,
    TimerWrapper).
*   Deprecated unused ROUTER_LINK_DSL_TRANSFORM.
*   Refactor(element.dart) is now app_element.dart.
*   AppView moved to app_view. DebugAppView moved to debug/debug_app_view.dart.
*   The deprecated injection Binding and bind have been removed.
*   Remove global events and disposables (instead of :window type targets, use
    dart APIs).

### Bug fixes and other changes

*   Improved change detection performance.
*   Improved error messages reported by template compiler.
*   Optimized [class.x]="y" type bindings.
*   Switched to js_util for browser_adapter to make angular CSP compliant.
*   Started strongly typing element members in compiled template code.
*   Cheatsheet and code docs updated.
*   Router fixes

## 2.0.0-beta.20

### API changes

*   Added ngBeforeSubmit event to ngForm API to allow better validation.
*   Global events removed from event binding syntax (dart:html APIs provide
    better alternative).

### Bug fixes and other changes

*   Reduced template code size.
*   Cleanup of facades.
*   Class Documentation updates.
*   ngForm submit changed to sync.
*   Removed disposables in generated template code.

## 2.0.0-beta.19

### API changes

*   Remove existing implementation of web workers, to be replaced in the future
    with Dart import override for dart:html.

### Bug fixes and other changes

*   Remove throwOnChanges parameter from all change detection calls in generated
    template.dart.
*   Unused and empty assertArrayOfStrings API removed.
*   Update BrowserDomAdapter from dart:js to package:js.
*   Reset change detection to guard against template exception.
*   Delete unused files.
*   Clean up the NgIf directive and remove facades.
*   Enabled Travis-CI.
*   Update tests that should only run in the browser.
*   Add angular transformer which deletes any pre-existing generated files from
    Bazel.
*   Add DI library entrypoint to support VM tests.
*   Fix the Math facade (improper annotation): @Deprecated(description).
*   Clean up animation classes.
*   Remove library name declarations.
*   Run dart formatter on all code.
*   Remove unused testing/lang_utils.dart.

## 2.0.0-beta.18

This is the first release of Angular 2 for Dart that is written directly in
Dart, instead of generated from TypeScript.

### API changes

The `Provider` constructor and `provide()` function are now more intuitive when
they have a single argument.

Before, `const Provider(Foo)` or `provide(Foo)` would provide a `null` object.
To provide a `Foo` object, you had to use `const Provider(Foo, useClass:Foo)` or
`provide(Foo, useClass:Foo)`. Now you can omit the `useClass:Foo`. Either of the
following provides a `Foo` instance:

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

*   Some types of **dependency injection** don't work.
    (https://github.com/dart-lang/angular2/issues/10)

### Bug fixes and other changes

*   Fix lower bound of pkg/build dependency.
*   Fixes for dependency upper bounds: build and protobuf.
*   Bumping min version of pkg/intl and pkg version.
*   Remove redundant declaration of `el`.
*   Security Update. Secure Contextual Escaping Implementation.
*   Fix Intl number formatting.
*   Enforce strong mode for angular2.dart.
*   Updating README and CONTRIBUTING.md for first release.
*   Enforce dartfmt for dart/angular2.
*   Add //dart/angular2/build_defs with default resolved_identifiers.
*   Import cleanup.
*   Annotate browser-only tests.
*   Include .gitignore in files sent to GitHub.
*   Fix a strong mode error in angular2 (strong mode type inference miss).
*   Add compiler tests.
*   Delete unused libraries in lib/src.
*   Updated pubspec: authors, description, homepage.
*   Angular strong mode fixes for DDC support.
*   Add _LoggerConsole implementation of Console for the TemplateCompiler.
*   Mark Binding and bind() as deprecated. Replaced by Provider and provide().
