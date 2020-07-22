### New features

*   Added `debugClearComponentStyles()`. This top-level function resets all
    static state used for component styles, and removes all component `<style>`
    tags from the DOM. This can be called to prevent styles leaking between DDC
    hot restarts or hermetic test cases. It can only be called in development
    mode.

*   Added `@i18n.locale`. This annotation overrides the locale of the message to
    use, even if a translation is available for the current locale.

    ```html
    <!-- Use "en_US" even if translation for current locale exists. -->
    <div @i18n="..." @i18n.locale="en_US">...</div>
    ```

*   Added `debugCheckBindings()`. This top-level function opts in to stricter
    checking for template bindings and interpolation, and will often have some
    contextual information (expression source and source location) for the
    underlying failure. See `/docs/advanced/debugging.md` for details.

*   Added `ChangeDetectorRef.markChildForCheck()`. This method can be used to
    mark a child query for change detection when the underlying result is a
    component that uses the OnPush change detection strategy.

    ```
    @Component(
      selector: 'example',
      template: '<ng-content></ng-content>',
      changeDetection: ChangeDetectionStrategy.OnPush,
    )
    class ExampleComponent {
      ExampleComponent(this._changeDetectorRef);

      final ChangeDetectorRef _changeDetectorRef;

      @ContentChildren(Child),
      List<Child> children;

      void updateChildren(Model model) {
        for (final child in children) {
          // If child is implemented by an onPush component, imperatively
          // mutating a property like this won't be observed without marking the
          // child to be checked.
          child.model = model;
          _changeDetectorRef.markChildForCheck(child);
        }
      }
    }
    ```

    Prefer propagating updates to children through the template over this method
    when possible. This method is intended to faciliate migrating existing
    components to use OnPush change detection.

    See `ChangeDetectorRef.markChildForCheck()` documentation for more details.

*   The compiler now issues a warning when a component that doesn't use
    "ChangeDetectionStrategy.OnPush" is used by a component that does. This is
    unsupported and likely to cause bugs, as the component's change detection
    contract can't be upheld.

### Breaking changes

*   Warn for all unknown properties in a template.

    Previously, we would skip the warning for tags that contained `-`, as a
    compatibility layer for custom web elements. Now that most of our users have
    migrated away from custom elements, such as from Polymer, we are going to
    strictly enforce unknown properties with a warning.

*   Event bindings no longer support multiple statements.

    Supported:

    ```html
    <!-- Bind method named "handleClick" (both equivalent) -->
    <button (click)="handleClick"></button>
    <button (click)="handleClick($event)"></button>

    <!-- Execute a single statement -->
    <button (click)="isPopupVisible = true"></button>
    ```

    Not supported:

    ```html
    <!-- Execute multiple statements -->
    <button (click)="isPopupVisible = true; $event.stopPropagation()"></button>
    ```

    To execute multiple statements, define and bind a method.

*   `TemplateSecurityContext` is no longer exported by
    `package:angular/security.dart`. This enum is only used during compilation
    and has no purpose in client code.

## 6.0.0-alpha+1

### New features

*   Added `ComponentRef.update()`. This method should be used to apply changes
    to a component and then trigger change detection. Before this, change
    detection and lifecycles would not always follow Angular's specifications
    when imperatively loading a component, especialy for those using the OnPush
    change detection strategy.

    ```dart
    final componentRef = componentFactory();
    componentRef.update((component) {
      component.input = newValue;
    });
    ```

*   Added `@changeDetectionLink` to `package:angular/experimental.dart`.

    This annotation allows a component that imperatively loads another component
    from a user-provided factory to adopt the OnPush change detection strategy,
    without dictacting the change detection strategy of the component created
    from the factory. This allows such a component to be used in both Default
    and OnPush apps.

    An annotated component will serve as a link between an ancestor and an
    imperatively loaded descendant that both use the Default change detection
    strategy. This link is used to change detect the descendant anytime the
    ancestor is change detected, thus honoring its Default change detection
    contract. Without this annotation, the descendant would be skipped anytime
    the annotated OnPush component had not been marked to be checked.

    For more details, see this annotation's documentation.

## 6.0.0-alpha

### New features

*   An eager error is emitted when a non-`.css` file extension is used within a
    `@Component(styleUrls: [ ... ])`. This used to fail later in the compile
    process with a confusing error (cannot find asset).

### Breaking changes

*   The `OnChanges` lifecycle has been completely removed. Use `AfterChanges`
    instead.

*   `ExceptionHandler` is no longer exported via `angular/di.dart`. Import this
    symbol via `angular/angular.dart` instead.

*   Directives no longer support extending, implementing, or mixing in
    `ComponentState`.

*   The `/deep/` and `>>>` combinators are no longer supported in style sheets
    of components with style encapsulation enabled. The special `::ng-deep`
    pseudo-element should be used in their stead to pierce style encapsulation
    when necessary.

*   `ChangeDetectorRef.checkNoChanges()` has been removed from the public API.

*   Removed `ExpressionChangedAfterItHasBeenCheckedException`. It is supported
    for end-users to interact with this object (it is now private to the
    framework).

*   Map literals (i.e. `{foo: bar}`) are no longer supported within the template
    and throw a compile-time error. Move code that constructs or maintains Map
    instances inside of your `@Component`-annotated Dart class, or prefer syntax
    such as `[class.active]="isActive"` over `[ngClass]="{'active': isActive}"`.

*   Asynchronous (i.e. "long") stack traces are now disabled by default, even in
    debug mode. To enable them for your app or tests, add the following line to
    your `main()` function before starting an app:

    ```dart
    import 'package:angular/angular.dart';

    void main() {
      ExceptionHandler.debugAsyncStackTraces();
      // Now run your app/tests.
    }
    ```

    We would like feedback if this feature is required for your team, otherwise
    we are considering removing it all together in a future release of
    AngularDart.

*   `ChangeDetectionStrategy.Stateful` was removed. It always served as an alias
    for extending or mixing-in `ComponentState`, and was found to be confusing.

### Deprecations

*   Deprecated `ChangeDetectorRef.detach()` and `ChangeDetectorRef.reattach()`.
    Components that rely on these methods should use `changeDetection:
    ChangeDetectionStrategy.OnPush` instead.

*   Deprecated `ComponentState`. Under the hood, it now delegates and uses the
    same mechanisms as `ChangeDetectionStrategy.OnPush`, and it is now
    recommended to use `ChangeDetectionStrategy.OnPush` over extending or
    mixing-in the `ComponentState` class.

### Bug fixes

*   Issue a compile-time error on an invalid `styleUrl`. Previously some URLs
    that were invalid (i.e. an unsupported schema) were skipped, leading to
    confusing behavior for users.

## 5.3.0

### New features

*   The template compiler issues a warning if a component that does not project
    content has children. Previously, these nodes were created and never
    attached. Now the nodes are not created at all.

*   Specialized interpolation functions for Strings.

*   Optimization: Removes toString() calls of interpolated strings bound to
    properties.

*   The compiler now uses superclass information to determine immutability.

*   Added `Injector.provideTypeOptional` and `Injector.provideTokenOptional`.

*   The compiler now optimizes string bindings inside `NgFor` loops.

*   The compiler now adds type information to local variables in nested `NgFor`
    loops.

*   The compiler now includes source locations to errors in annotations on class
    members.

*   The compiler now optimizes change detection for HTML Text nodes.

*   Disabled an optimization around pure-HTML DOM nodes wrapped in a `*ngIf`. In
    practice this optimization only kicked in for a few views per application
    and had a high runtime cost as well as a high overhead for the framework
    team. We have added and expect to add additional optimizations around the
    size of generated views.

### Bug fixes

*   The template compiler now outputs the full path to a template file when it
    reports an error.

*   [#1694][]: Composite `keyup` and `keydown` event bindings now ignore
    synthetic events (e.g. those triggered by a mouse click) instead of throwing
    a `TypeError`.

*   [#1669][]: Fixed a regression which prevented a pipe invoked with more than
    two arguments from being passed as an argument to a function.

*   The compiler emits source locations for errors in Dart files when using an
    `AnalysisDriver`.

*   Internationalized attribute, property, and input bindings will now properly
    escape characters in the message that would invalidate the generated string
    (such as `\n`, `$`, and `'`). This behavior is now consistent with
    internationalized text and HTML.

*   The template compiler no longer crashes on HTML attributes ending in ":"

*   When querying for a directive present in multiple embedded views (portions
    of the template controlled by a structural directive such as `*ngIf`) with
    `@ViewChildren()`, the directives in the resulting list are now in the same
    order as they appear in the template. Prior to this fix, directives in
    nested embedded views would occur *before* those in their parent view.

*   The template compiler now properly updates class statements for "literal
    attributes". Previously, we did not shim these classes correctly. This
    includes both raw attributes (e.g. `class="foo"`) and host bindings (e.g.
    `@HostBinding('class')`).

*   The presence of a query (e.g. `@ContentChild(TemplateRef)`) no longer causes
    any matching `<template>` references to become available for dynamic
    injection (i.e. `injector.provideType(TemplateRef)`).

*   The template compiler now properly updates class bindings on SVG elements.
    Previously, we did not shim these classes correctly.

*   When using `runAppAsync`, `beforeComponentCreated` now runs within `NgZone`
    which previously surfaced bugs when services created and initialized in this
    callback did not trigger change detection.

*   The style sheet compiler will no longer emit invalid Dart code when a style
    sheet is placed within a directory whose name is not a valid Dart
    identifier.

*   The template compiler will now report a helpful error message when an
    `@i18n.skip` annotation has no corresponding `@i18n` description, instead of
    throwing an unhandled error.

### Breaking changes

*   Removed `castCallback2ForDirective` from `meta.dart`. In practice this was
    not used. We also deprecated `castCallback1ForDirective` now that the
    `directiveTypes: [ ... ]` feature is live.

*   Removed deprecated `AppViewUtils.resetChangeDetection()`. This method was
    never intended to be used in the public API, and is no longer used by our
    own infra.

*   Using anything but `ChangeDetectionStrategy.{Default|OnPush}` is considered
    deprecated, as they were not intended to be publicly accessible states. See
    the deprecation messages for details.

*   `ViewContainerRef.get()` now returns a `ViewRef` instead of an
    `EmbeddedViewRef`.

    For context, `ViewContainerRef` supports inserting both host views (created
    via `ComponentFactory`) and embedded views (created via `TemplateRef`).
    Today, `EmbeddedViewRef` can reference either kind of view, but in the
    future it will only reference the latter, for which its methods are actually
    relevant (for example setting locals has no purpose on host views). This
    change is in preperation for when a host view reference may not implement
    `EmbeddedViewRef`.

[#1694]: https://github.com/dart-lang/angular/issues/1694
[#1669]: https://github.com/dart-lang/angular/issues/1669

### Deprecations

*   `OnChanges` is now officially deprecated. Please use `AfterChanges` instead.

    *   If you don't use the `changes` map at all, just remove the parameter and
        you're good to go.
    *   If you are only tracking the change of one or two fields, consider using
        a boolean, i.e. `valueChanged`, which can be set in the `value` setter
        and then checked in `ngAfterChanges`.
    *   If you are making extensive use of the `changes` map, then consider
        recreating the map manually.

## 5.2.0

### Breaking changes

*   The template parser no longer supports styles defined inside the template
    itself.

    Previously, the following two snippets would have been parsed and shimmed in
    the same way.

    ```html
    <style> .my-class {padding: 10px;} </style>
    ```

    ```dart
    @Component(
      styles: ['.other-class {padding: 10px;}'],
    )
    class ExampleComponent{}
    ```

    Now, only the latter will be parsed and shimmed. The former will be ignored.

*   The template parser no longer supports loading stylesheets defined in an
    `<link>` tag in the template itself.

    Previously, the following two snippets would have loaded the exact same
    stylesheet.

    ```html
    <link href="my-styles.css" rel="stylesheet" />
    ```

    ```dart
    @Component(
      styleUrls: ['my-styles.css'],
    )
    class ExampleComponent {}
    ```

    Now, only the latter will actually be loaded. The former will be ignored.

*   The deprecated field, `ComponentRef.componentType`, which always threw, has
    now been completely removed. This was a legacy field for older clients of
    AngularDart.

### New features

*   Better error messages in the compiler by failing fast on all analyzer errors
    in element annotations (@Component, etc) and passing the analyzer error
    messages to the user.

*   Added `runAfterChangesObserved` to `NgZone`. This API is intended to be a
    more precise way to execute code _after_ AngularDart would have run change
    detection (instead of relying on `scheduleMicrotask` or `Timer.run`).

*   Added new type-safe ways to use the `Injector` API without dynamic calls:

    ```dart
    void example(Injector injector) {
      // Injecting "SomeType".
      // Before:
      var someType1 = injector.get(SomeType) as SomeType;

      // After:
      var someType2 = injector.provide<SomeType>();

      // Injecting "OpaqueToken<SomeType>(...)".
      // Before:
      var someToken1 = injector.get(someToken) as SomeType;

      // After:
      var someToken2 = injector.provideToken(someToken);
    }
    ```

*   The code in generated `AppView` no longer performs null safety `?.` checks
    when calling child views `.destroy()` or `.destroyNestedViews()`. This means
    that misbehaving code could have slightly more confusing stack traces (new
    null errors), at the benefit of reduced code-size across the board.

*   It's now a build error for `@Component()` to include an entry in
    `directiveTypes` that types a directive not present in `directives`.

### Bug fixes

*   [#1653][]: `AppView.lastRootNode` now correctly returns the last root node
    when multiple `ViewContainer`s are directly nested.

*   When using the `@deferred` annotation in a template file, ensure that the
    constructed component class uses the _deferred_ import. For example, we now
    emit `deflib1.ComponentName(...)` instead of `lib1.ComponentName(...)`. This
    should ensure Dart2JS properly defer loads the entire component.

*   Typing a generic directive with a private type argument is now a build
    error. Directive type arguments must be public so that they can be
    referenced by the generated library that instantiates the directive.
    Previously, this would build successfully but emit code that instantiated
    the directive with `dynamic` in place of the private type.

*   [#1665][]: `@Optional()` dependencies of pipes are now correctly treated as
    optional. Previously the annotation was ignored, and attempting to
    instantiate the pipe with a missing optional dependency would throw an error
    for the missing dependency.

*   [#1666][]: Properly emit calls from event bindings in templates where the
    tear-off function has one or more named arguments. Previously we would
    consider named arguments in the same vane as positional, and it would
    generate invalid code causing Dart2JS or DDC to fail compilation.

*   The `@deferred` annotation now also defers the annotated component's
    defining library, rather than just its generated template's library.

[#1653]: https://github.com/dart-lang/angular/issues/1653
[#1665]: https://github.com/dart-lang/angular/issues/1665
[#1666]: https://github.com/dart-lang/angular/issues/1666

## 5.1.0

### New features

*   Added support for generic components and directives.

    Type arguments can now be specified for any generic components and
    directives via `Typed` instances passed to the `Component` annotation's
    `directiveTypes` parameter.

    ```dart
    @Component(
      selector: 'generic',
      template: '{{value}}',
    )
    class GenericComponent<T> {
      @Input()
      T value;
    }

    @Component(
      selector: 'example',
      template: '''
        <generic [value]="value"></generic>
      ''',
      directives: [
        GenericComponent,
      ],
      directiveTypes: [
        Typed<GenericComponent<String>>(),
      ],
    )
    class ExampleComponent {
      var value = 'Hello generics!';
    }
    ```

    The `Typed` class also has support for typing specific component and
    directive instances by `#`-reference, and flowing generic type parameters
    from the annotated component as type arguments to its children. See its
    documentation for details.

*   [#930][]: Added `@visibleForTemplate` to `package:angular/meta.dart`. This
    is an _optional_ annotation that may be used to annotate elements that
    should _only_ be used from within generated code (i.e. a `.template.dart`).
    It is a compile-time _hint_, which may be treated as a failing build, to use
    annotated elements outside of the component or template.

    This annotation is intended to give component authors more control in
    specifying the public API of their component(s), especially coupled with the
    fact that AngularDart requires all members to be public to be reachable from
    generated code. For example, `c` and `ngAfterChanges` are only accessible
    from `CalculatorComponent` (or its template) in the following:

    ```dart
    import 'package:angular/angular.dart';
    import 'package:angular/meta.dart';

    @Component(
      selector: 'calculator-comp',
      template: '{{a}} + {{b}} = {{c}}',
    )
    class CalculatorComponent implements AfterChanges {
      @Input()
      num a = 0;

      @Input()
      num b = 0;

      @visibleForTemplate
      num c = 0;

      @override
      @visibleForTemplate
      void ngAfterChanges() {
        c = a + b;
      }
    }
    ```

    **NOTE**: This feature is only _enforced_ in SDK: `>=2.1.0-dev.3.1`.

*   Added support for internationalization in templates.

    The `@i18n` annotation marks content in document fragments or attributes for
    internationalization via integration with [`package:intl`][intl].

    A document fragment can be internationalized by applying the `@i18n`
    annotation to its parent element:

    ```html
    <div @i18n="A description of the message.">
      A message to be <i>translated</i>!
    </div>
    ```

    An attribute, property, or input `<name>` can be internationalized by
    applying the `@i18n:<name>` annotation to its host element:

    ```html
    <input
        placeholder="A message to be translated"
        @i18n:placeholder="A description of the message.">
    ```

    Note that internationalization in templates currently only supports messages
    with static text and HTML. See the [example][i18n_example] for more details.

[intl]: https://pub.dev/packages/intl
[i18n_example]: https://github.com/dart-lang/angular/blob/master/examples/i18n

### Bug fixes

*   [#1538][]: A compile-time error is reported if the `@deferred` template
    annotation is present on a `<template>` element or is a sibling to a
    structural directive (such as `*ngIf`). Before we would silently drop/ignore
    the annotation, so this might be considered a breaking change of an
    incorrect program. The fix is just to move the annotation, such as:

    ```html
    <!-- Before (Both are identical) -->
    <template @deferred [ngIf]="showArea">
      <expensive-comp></expensive-comp>
    </template>

    <expensive-comp *ngIf="showArea" @deferred></expensive-comp>

    <!-- After (Both are identical) -->
    <template [ngIf]="showArea">
      <expensive-comp @deferred></expensive-comp>
    </template>

    <ng-container *ngIf="showArea">
      <expensive-comp @deferred></expensive-comp>
    </ng-container>
    ```

*   [#1558][]: When importing a `library.dart` that has two or more components
    (i.e. `Comp1` and `Comp2`), and at least one component is used `@deferred`
    and at least one component is used _without_ `@deferred`, the compiler would
    generate invalid Dart code that would fail analysis/compilation to JS.
    Correct code is now emitted, allowing the described scenario to work.

*   [#1539][]: Fixed a bug where components that were `@deferred` as the direct
    child of another `<template>` tag had phantom DOM left behind even after the
    parent template was destroyed. For example:

    ```html
    <template [ngIf]="showComponent">
      <expensive-comp @deferred></expensive-comp>
    </template>
    ```

    ... additionally, a check for a race condition of the deferred component
    being loaded _after_ the parent view was already destroyed was added. As a
    result, [#1540][] has also been fixed (view and content queries were not
    getting reset as the `@deferred` node was destroyed).

*   [#880][]: Fixed a bug where an extraneous space in `*ngFor` micro expression
    caused the directive to no longer be functional (`*ngFor="let x; let i =
    $index "`, for example).

*   [#1570][]: When a provider's `token` for `@GeneratedInjector(...)` is read
    as `null` (either intentionally, or due to analysis errors/imports missing)
    a better error message is now thrown with the context of the error.

*   [#434][]: In development mode, creating a component or service `C` that
    attempts to inject a missing dynamic dependency `D` will now throw an error
    message containing `Could not find provider for D: C -> D`. Previously the
    message was only `Could not find provider for D` in these cases, which was
    often not enough information to debug easily.

*   [#1502][]: When parsing an invalid template micro expression (i.e.
    `*ngFor="let item of items;"` - note the trailing `;`), throws a proper
    unexpected token error instead of a confusing type error during recovery.

*   [#1500][]: Configuring a provider with `FactoryProvider(Foo, null)` is now a
    compile-time error, instead of a misleading runtime error.

*   [#1591][]: Using `@GenerateInjector` with a `ValueProvider` bound to a
    `String` instance that expects a _raw_ string (i.e `r'$5.00'`) no longer
    generates invalid code. Now _all_ strings are emitted as _raw_.

*   [#1598][]: Using `@GenerateInjector` with a `ValueProvider` whose value is
    created as a `const` object with _named_ arguments is now created correctly.
    Before, all named arguments were skipped (left to default values, which was
    often `null`).

*   `@GenerateInjector(...)` now correctly solves duplicate tokens by having the
    _last_, not _first_, provider win. This aligns the semantics with how the
    other injector implementations work. For `MultiToken`, the order stays the
    same.

*   Clarified that `Injector.map({...})` doesn't support `null` as values.

*   Named arguments are now supported for function calls in templates where the
    function is an exported symbol (`Component(exports: [someFunction])`).

*   [#1625][]: Named arguments in function calls in templates that collide with
    an exported symbol (`Component(exports: [someExport])`) no longer cause a
    parsing error.

*   Whitespace in internationalized message descriptions and meanings is now
    normalized so they're no longer affected by formatting changes. Identical
    messages with meanings that are formatted differently will now properly be
    treated as the same message.

*   [#1633][]: Using a function type or any non-class `Type` inside of the
    `@GenerateInjector([...])` annotation would cause a non-ideal error to be
    produced. It now includes more information where available.

*   Error ranges for invalid code sometimes listed the error offset as if it
    were a column on line 1. Now shows correct line and column number.

[#434]: https://github.com/dart-lang/angular/issues/434
[#880]: https://github.com/dart-lang/angular/issues/880
[#930]: https://github.com/dart-lang/angular/issues/930
[#1500]: https://github.com/dart-lang/angular/issues/1500
[#1502]: https://github.com/dart-lang/angular/issues/1502
[#1538]: https://github.com/dart-lang/angular/issues/1538
[#1539]: https://github.com/dart-lang/angular/issues/1539
[#1540]: https://github.com/dart-lang/angular/issues/1540
[#1558]: https://github.com/dart-lang/angular/issues/1558
[#1570]: https://github.com/dart-lang/angular/issues/1570
[#1591]: https://github.com/dart-lang/angular/issues/1591
[#1598]: https://github.com/dart-lang/angular/issues/1598
[#1625]: https://github.com/dart-lang/angular/issues/1625
[#1633]: https://github.com/dart-lang/angular/issues/1633

### Other improvements

*   Error messages for misconfigured pipes now display their source location.

*   Assertion added for ensuring different SanitizationServices aren't used when
    calling runApp multiple times. SanitizationService is a static resource so
    different instances would not work as expected.

*   `AppViewUtils.resetChangeDetection()` is now deprecated and will be removed
    in the next major release.

## 5.0.0

Welcome to AngularDart v5.0.0, with full support for Dart 2. Please note that
this release is not compatible with older versions of Dart 1.XX. Additionally:

*   _Dartium_ is no longer supported. Instead, use the new
    [DartDevCompiler](https://webdev.dartlang.org/tools/dartdevc)
*   Pub _transformers_ are no longer used. Instead, use the new
    [webdev](https://pub.dev/packages/webdev) CLI, or, for advanced users, the
    [build_runner](https://pub.dev/packages/build_runner) CLI.

More details of
[changes to Dart 2 for web users](https://webdev.dartlang.org/dart-2) are
available on our website.

**Thanks**, and enjoy AngularDart!

### Dependency Injection

Dependency injection was enhanced greatly for 5.0.0, primarily around using
proper types (for Dart 2), and paths to enable much smaller code size (for
everyone).

#### New features

*   `Provider` (and `provide`) are _soft_ deprecated, and in their place are
    four new classes with more precise type signatures. Additionally, `Provider`
    now supports an optional type argument `<T>`, making it `Provider<T>`.

    *   `ValueProvider(Type, T)` and `ValueProvider.forToken(OpaqueToken<T>, T)`
        _instead_ of `Provider(typeOrToken, useValue: ...)`.

    *   `FactoryProvider(Type, T)` and `FactoryProvider.forToken(OpaqueToken<T>,
        T)` _instead_ of `Provider(typeOrToken, useFactory: ...)`.

    *   `ClassProvider(Type, useClass: T)` and
        `ClassProvider.forToken(OpaqueToken<T>, useClass: T)` _instead_ of
        `Provider(typeOrToken, useClass: ...)` or an implicit `Type`.

    *   `ExistingProvider(Type, T)` and
        `ExistingProvider.forToken(OpaqueToken<T>, T)` _instead_ of
        `Provider(typeOrToken, useExisting: ...)`.

*   `OpaqueToken` is now much more useful. Previously, it could be used to
    define a custom, non-`Type` to refer to something to be injected; commonly
    instead of types like `String`. For example, you might use an `OpaqueToken`
    to refer to the a URL to download a file from:

    ```dart
    const downloadUrl = OpaqueToken('downloadUrl');

    @Component(
      providers: [
        Provider(downloadUrl, useValue: 'https://a-site.com/file.zip'),
      ],
    )
    class Example {
      Example(@Inject(downloadUrl) String url) {
        // url == 'https://a-site.com/file.zip'
      }
    }
    ```

    First, `OpaqueToken` adds an optional type argument, making
    `OpaqueToken<T>`. The type argument, `T`, should be used to refer to the
    `Type` of the object this token should be bound to:

    ```dart
    const downloadUrl = OpaqueToken<String>('downloadUrl');
    ```

    Coupled with the new named `Provider` classes and their `.forToken` named
    constructor (see below), you now also have a way to specify the type of
    providers using type inference:

    ```dart
    @Component(
      providers: [
        // This is now a Provider<String>.
        ValueProvider.forToken(downloadUrl, 'https://a-site.com/file.zip'),
      ],
    )
    ```

    Second, `MultiToken<T>` has been added, and it extends
    `OpaqueToken<List<T>>`. This is an idiomatic replacement for the now
    _deprecated_ `multi: true` argument to the `Provider` constructor:

    ```dart
    const usPresidents = MultiToken<String>('usPresidents');

    @Component(
      providers: [
        ValueProvider.forToken(usPresidents, 'George'),
        ValueProvider.forToken(usPresidents, 'Abe'),
      ],
    )
    class Example {
      Example(@Inject(usPresidents) List<String> names) {
        // names == ['George', 'Abe']
      }
    }
    ```

    Third, we heard feedback that the `String`-based name of tokens was
    insufficient for larger teams because the names could collide. Imagine 2
    different tokens being registered with a name of `'importantThing'`! It is
    now possible (but optional) to `extend` either `OpaqueToken` or `MultiToken`
    to create scoped custom token names:

    ```dart
    class DownloadUrl extends OpaqueToken<String> {
      const DownloadUrl();
    }

    class UsPresidents extends MultiToken<String> {
      const UsPresidents();
    }

    class Example {
      providers: const [
        ValueProvider.forToken(DownloadUrl(), 'https://a-site.com/file.zip'),
        ValueProvider.forToken(UsPresidents(), 'George'),
        ValueProvider.forToken(UsPresidents(), 'Abe'),
      ],
    }
    ```

    Fourth, and finally, we'd like to repurpose `@Inject` in the future, and let
    you write _less_ to inject tokens. So, `OpaqueToken` and `MultiToken`
    instances may now be used _directly_ as annotations:

    ```dart
    class Example {
      Example(@DownloadUrl() String url, @UsPresidents() List<String> names) {
        // url == 'https://a-site.com/file.zip'
        // names == ['George', 'Abe']
      }
    }
    ```

*   `InjectorFactory`, a function type definition of `Injector
    Function([Injector parent])`, was added and started to be used across the
    framework. It normally indicates the ability to create a _new_ `Injector`
    instance with an optional _parent_.

*   A new annotation, `@GenerateInjector`, was added. It is now posibble to
    generate, at compile-time, a standalone `InjectorFactory` method for
    providers, without explicitly wrapping in an `@Component`:

    ```dart
    // example.dart

    import 'example.template.dart' as ng;

    @GenerateInjector([
      ClassProvider(HelloService),
    ])
    final InjectorFactory rootInjector = ng.rootInjector$Injector;
    ```

*   `Module` has been added as a new, more-typed way to encapsulate a collection
    of `Provider` instances. This is an _optional_ feature to use instead of
    nested `const` lists to represent shared providers. For example:

    ```dart
    const httpModule = [ /* Other providers and/or modules. */ ];

    const commonModule = [
      httpModule,
      ClassProvider(AuthService, useClass: OAuthService),
      FactoryProvider.forToken(xsrfToken, useFactory: readXsrfToken),
    ];
    ```

    ... you can represent this with the new typed `Module` syntax:

    ```dart
    const httpModule = Module( /* ... Configuration ... */);

    const commonModule = Module(
      include: [httpModule],
      provide: [
        ClassProvider(AuthService, useClass: OAuthService),
        FactoryProvider.forToken(xsrfToken, useFactory: readXsrfToken),
      ],
    );
    ```

    The advantages here are numerous:

    *   Less ambiguity around ordering of providers. Engineers would tend to try
        and sort providers alphabetically, would of course, would lead to
        problems. `Module` specifically outlines that _order_ is significant,
        and that `include` is processed _before_ `provide`.

    *   `Module` rejects using a `Type` implicitly as a `ClassProvider`. This
        removes additional ambiguity around supporting `List<dynamic>`, and
        while more verbose, should lead to more correct use.

    *   `Module` tends to be more understandable by users of other dependency
        injection systems such as Guice or Dagger, and reads better than a
        `const` `List` (which is a very Dart-only idiom).

    **NOTE**: It is also possible to use `Module` in `@GenerateInjector`:

    ```dart
    @GenerateInjector.fromModules([
      commonModule,
    ])
    final InjectorFactory exampleFromModule = ng.exampleFromModule$Injector;
    ```

    **NOTE**: It is also possible to use `Module` in `ReflectiveInjector`:

    ```dart
    // Using ReflectiveInjector is strongly not recommended for new code
    // due to adverse effects on code-size and runtime performance.
    final injector = ReflectiveInjector.resolveAndCreate([
      commonModule,
    ]);
    ```

#### Breaking changes

*   `OpaqueToken` no longer overrides `operator==` or `hashCode`. In practice
    this should have no effect for most programs, but it does mean that
    effectively that only `const` instances of `OpaqueToken` (or `MultiToken`)
    are valid.

*   It is no longer valid to provide a token type of anything other than `Type`
    or an `OpaqueToken` (or `MultiToken`). In the past anything from aribtrary
    literals (such as a string - `'iAmAToken'`) or a custom `const` instance of
    a class were supported.

*   For defining whether a component or directive should provide itself for
    injection, `Visibility.none` has been renamed `Visibility.local` to make it
    more clear that it _is_ accessable locally (within `providers` for example).

*   Classes annotated with `@Component` or `@Directive` are no longer treated
    like services annotated with `@Injectable`, and not accessible (by default)
    to `ReflectiveInjector`. `@Injectable` can always be added to these classes
    in order to return to the old behavior.

#### Bug fixes

*   Fixed a bug where calling `get` on an `Injector` injected in the context of
    an `@Component` or `@Directive`-annotated class and passing a second
    argument always returned `null` (instead of that second argument) if the
    token was not found.

*   Setting `@Component(visibility: Visibility.none`) no longer applies to
    `providers`, if any. Note that `Visibility.none` was always renamed
    `Visibility.local` in _breaking changes_ above.

*   Fixed a bug where `Provider(SomeType)` was not parsed correctly as an
    implicit use of `Provider(SomeType, useClass: SomeType`).

*   Fixed a bug where `<ReflectiveInjector>.get(X)` would throw with a message
    of _no provider found for X_, even when the acutal cause was a missing
    downstream dependency `Y`. We now emit the correct message.

#### Other improvements

*   Some injection failures will display the chain of dependencies that were
    attempted before a token was not found (`'X -> Y -> Z'`) in development
    mode. We are working on making sure this better error message shows up
    _always_ but it is likely to slip until after the v5 release.

*   It is no longer a build warning to have an `@Injectable`-annotated service
    with more than one constructor. This was originally meant to keep injection
    from being too ambiguous, but there are understood patterns now (first
    constructor), and there is no alternative present yet. We may re-add this as
    a warning if there ends up being a mechanism to pick a constructor in the
    future.

*   It is no longer a build warning to have `@Injectable`-annotated services
    with named constructor parameters. While they are still not supported for
    injected, they were always successfully ignored in the past, and showing a
    warning to the user on every build served no purpose.

*   If a private class is annotated with `@Injectable()` the compiler fails. In
    practice this caused a compilation error later in DDC/Dart2JS, but now the
    AngularDart compiler will not emit invalid code.

*   Removed spurious/incorrect warnings about classes that are used as
    interfaces needing `@Injectable` (or needing to be non-abstract), which are
    wrong and confusing.

*   The compiler behind `initReflector()` has changed implementations and now
    uses fully-scoped import statements instead of trying to figure out the
    original scope (including import prefixes) of your source code. This was not
    intended to be a breaking change.

### Components and Templates

#### New features

*   `NgTemplateOutlet` added `ngTemplateOutletContext` for setting local
    variables in an embedded view. These variables are assignable to template
    input variables declared using `let`, which can be bound within the
    template. See the `NgTemplateOutlet` documentation for examples.

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

*   It is possible to directly request `Element` or `HtmlElement` types from
    content or view children instead of `ElementRef` (which is deprecated). For
    example:

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

*   Additionally, `List<Element>` and `List<HtmlElement>` for `@ViewChildren`
    and `@ContentChildren` no longer require `read: Element`, and the type is
    correctly inferred the same as a single child is.

*   Static properties and methods of a component may now be referenced without a
    receiver in the component's own template. For example:

    **Before:** `ExampleComponent` as receiver is necessary.

    ```dart
    @Component(
      selector: 'example',
      template: '<h1>{{ExampleComponent.title}}</h1>',
    )
    class ExampleComponent {
      static String title;
    }
    ```

    **After**: No receiver is necessary.

    ```dart
    @Component(
      selector: 'example',
      template: '<h1>{{title}}</h1>',
    )
    class ExampleComponent {
      static String title;
    }
    ```

*   `@HostListener()` can now automatically infer the `const ['$event']`
    parameter when it is omitted but the bound method has a single argument:

    ```dart
    class Comp {
      @HostListener('click')
      void onClick(MouseEvent e) {}
    }
    ```

*   Added `<ng-container>`, an element for logical grouping that has no effect
    on layout. This enables use of the *-syntax for structural directives,
    without requiring the cost an HTML element.

    **Before**

    ```html
    <ul>
      <template ngFor let-user [ngForOf]="users">
        <li *ngIf="user.visible">{{user.name}}</li>
      </template>
    </ul>
    ```

    **After**

    ```html
    <ul>
      <ng-container *ngFor="let user of users">
        <li *ngIf="user.visible">{{user.name}}</li>
      </ng-container>
    </ul>
    ```

*   In dev mode only, an attribute named `from` is now added to each `<style>`
    tag whose value identifies the source file URL and name of the component
    from which the styles originate.

*   Support for the suffix `.if` for attribute bindings, both in a template and
    in a `@HostBinding()`. Accepts an expression of type `bool`, and adds an
    attribute if `true`, and removes it if `false` and closes
    https://github.com/dart-lang/angular/issues/1058:

    ```html
    <!-- These are identical -->
    <button [attr.disabled]="isDisabled ? '' : null"></button>
    <button [attr.disabled.if]="isDisabled"></button>
    ```

*   Add support for tear-offs in event handlers in the templates.

    **BEFORE**: `<button (onClick)="clickHandler($event)">`

    **AFTER**: `<button (onClick)="clickHandler">`

*   It is now possible to annotate parts of a template with
    `@preserveWhitespace` _instead_ of opting into preserving whitespace for the
    entire template. [Closes #1295][#1295]:

    ```html
    <div>
      <div class="whitespace-sensitive" @preserveWhitespace>
        Hello
        World!
      </div>
    </div>
    ```

*   A warning is produced if the compiler removes any elements (such as
    `<script>`) from your template. This may become an error in future versions
    of AngularDart.

*   A warning is produced if the selector provided to a query (such as
    `@ViewChildren(...)`) is invalid and will not produce any elements at
    runtime. **NOTE**: any unknown type is just ignored (it may still be
    invalid), and any invalid _value_ throws a build error. For example:

    ```dart
    class A {
      // Might not be valid, but no warning.
      @ViewChildren(SomeArbitraryType)
      List<SomeArbitraryType> someTypes;

      // We throw a build error.
      @ViewChildren(1234)
      List thisDoesNotWork;
    }
    ```

*   Added support for named arguments in function calls in templates:

    ```html
    <span>Hello {{getName(includeExclamationPoint: true)}}</span>
    ```

    **NOTE**: Because of the collision of syntax for both named arguments and
    pipes, any pipes used as the _value_ of a named argument need to be wrapped
    in parentheses: `func(namedArg: (pipeName | pipeVar:pipeVarValue))`.

#### Breaking changes

*   We now have a new, more stricter template parser, which strictly requires
    double quotes (`"..."`) versus single quotes, and in general enforces a
    stricter HTML-like syntax. It does produce better error messages than
    before.

*   We removed support for `ngNonBindable` in the new template syntax.

*   The fields `inputs:`, `outputs:`, and `host:` have been removed from
    `@Directive(...)` and `@Component(...`). It is expected to use the member
    annotations (`@Input()`, `@Output()`, `@HostBinding()`, `@HostListener()`)
    instead.

*   The default for `@Component(preserveWhitespace: ...)` is now `false`. Many
    improvements were put into the whitespace optimziation in order to make the
    results easier to understand and work around.

*   `<AsyncPipe>.transform` no longer returns the (now removed) `WrappedValue`
    when a transformed result changes, and relies on regular change detection.

*   Pipes no longer support private types in their `transform` method signature.
    This method's type is now used to generate a type annotation in the
    generated code, which can't import private types from another library.

*   Using `@deferred` no longer supports the legacy bootstrap processes. You
    must use `runApp` (or `runAppAsync`) to bootstrap the application without
    relying on `initReflector()`.

*   `<ComponentRef>.componentType` always throws `UnsupportedError`, and will be
    removed in a later minor release. This removes our last invocation of
    `.runtimeType`, which has potentially severe code-size implications for some
    apps.

*   `QueryList` for `@ViewChildren` and `@ContentChildren` has been removed, in
    favor of just a plain `List` that is replaced with a new instance when the
    children change (instead of requiring a custom collection and listener):

    ```dart
    class Comp {
      @ViewChildren(ChildComponent)
      set viewChildren(List<ChildComponent> viewChildren) {
        // ...
      }

      // Can also be a simple field.
      @ContentChildren(ChildComponent)
      List<ChildComponent> contentChildren;
    }
    ```

*   `EventEmitter` was removed in favor using `Stream` and `StreamController`.

*   `COMMON_DIRECTIVES` was renamed `commonDirectives`.

*   `CORE_DIRECTIVES` was renamed `coreDirectives`.

*   `COMMON_PIPES` was renamed `commonPipes`.

*   Private types can't be used in template collection literals bound to an
    input. This is a consequence of fixing a cast warning that is soon to be an
    error caused by the code generated for change detecting collection literals
    in templates. See https://github.com/dart-lang/angular/issues/844 for more
    information.

*   `SafeInnerHtmlDirective` is no longer injectable.

*   The following types were never intended for external use and are no longer
    exported by `package:angular/security.dart`:

    *   `SafeHtmlImpl`
    *   `SafeScriptImpl`
    *   `SafeStyleImpl`
    *   `SafeResourceUrlImpl`
    *   `SafeUrlImpl`
    *   `SafeValueImpl`

    To mark a value as safe, users should inject `DomSanitizationService` and
    invoke the corresponding `bypassSecurityTrust*()` method, instead of
    constructing these types directly.

*   `ComponentResolver` was removed, and `SlowComponentLoader` was deprecated.

*   Methods in lifecycle hooks have `void` return type. This is breaking change
    if the override doesn't specify return type and uses `return` without any
    value. To fix add a `void` or `Future<void>` return type to the override:

    ```dart
    class MyComp implements OnInit {
      @override
      void ngOnInit() {
        // ...
      }
    }
    ```

*   Removed the rarely used `template` attribute syntax. Uses can be replaced
    with either the `*` micro-syntax, or a `<template>` element.

    **Before**

    ```html
      <div template="ngFor let item of items; trackBy: trackById; let i=index">
        {{i}}: {{item}}
      </div>
    ```

    **After**

    ```html
    <!-- * micro-syntax -->
    <div *ngFor="let item of items; trackBy: trackById; let i=index">
      {{i}}: {{item}}
    </div>

    <!-- <template> element -->
    <template
        ngFor
        let-item
        [ngForOf]="items"
        [ngForTrackBy]="trackById"
        let-i="index">
      <div>
        {{i}}: {{item}}
      </div>
    </template>
    ```

*   It is now a compile error to implement both the `DoCheck` and `OnChanges`
    lifecycle interfaces. `DoCheck` will never fill in values for the `Map` in
    `OnChanges`, so this compile-error helps avoid bugs and directs the user to
    use `DoCheck` and `AfterChanges` _instead_.

*   Using a suffix/unit for the `[attr.name.*]` syntax other than the newly
    introduced `[attr.name.if]` is now a compile-error. These binding suffixes
    were silently ignored (users were likely confused with `[style.name.px]`,
    which is supported).

#### Bug fixes

*   Fixed a bug where an `@deferred` components were still being linked to in
    `initReflector()`.

*   Fixed a bug where errors thrown in event listeners were sometimes uncaught
    by the framework and never forwarded to the `ExceptionHandler`.

*   Fixed a bug where `DatePipe` didn't format `millisecondsSinceEpoch` in the
    local time zone (consistent with how it formats `DateTime`).

*   Testability now includes `ComponentState` updates. Due to prior use of
    `animationFrame` callback, `NgTestBed` was not able to detect a stable
    state.

*   String literals bound in templates now support Unicode escapes of the form
    `\u{?-??????}`. This enables support for Unicode supplementary planes, which
    includes emojis!

*   Inheriting from a class that defines a `@HostBinding()` on a static member
    no longer causes the web compiler (Dartdevc or Dart2JS) to fail. We
    previously inherited these bindings and generated invalid Dart code. Given
    that static members are not inherited in the Dart language, it made sense to
    give a similar treatment to these annotations. Instance-level members are
    still inherited:

    ```dart
    class Base {
      @HostBinding('title')
      static const hostTitle = 'Hello';

      @HostBinding('class')
      final hostClass = 'fancy';
    }

    // Will have DOM of <fancy-button class="fancy"> but *not* title="Hello".
    @Component(
      selector: 'fancy-button',
      template: '...',
    )
    class FancyButton extends Base {}
    ```

*   Fixed a bug where a recursive type signature on a component or directive
    would cause a stack overflow. We don't support generic type arguments yet
    (the reified type is always `dynamic`), but the compiler no longer crashes.

*   Fails the build immediately if an element in a component's `pipes` list is
    unresolved.

*   Fixed a bug where `[attr.name.if]` did not work on a static `@HostBinding`.

*   Implicit static tear-offs and field invocations are now supported:

    ```dart
    @Component(
      selector: 'example',
      template: '''
        <!-- Invoking an implicit static field. -->
        <div>{{field()}}</div>

        <!-- Binding an implicit static tear-off. -->
        <div [invoke]="tearOff"></div>
      ''',
    )
    class ExampleComponent {
      static String Function() field = () => 'Hello world';
      static String tearOff() => 'Hello world';
    }
    ```

#### Other improvements

*   Types bound from generics are now properly resolved in a component when
    inheriting from a class with a generic type. For example, the following used
    to be untyped in the generated code:

    ```dart
    class Container<T> {
      @Input()
      T value;
    }

    class StringContainerComponent implements Container<String> {}
    ```

*   Both `ComponentFactory` and `ComponentRef` now have a generic type parameter
    `<T>`, which is properly reified where `T` is the type of the component
    class.

*   The `$implicit` (iterable) value in `*ngFor` is now properly typed whenever
    possible. It was previously always typed as `dynamic`, which caused dynamic
    lookups/calls at runtime, and hid compilation errors.

*   The type of `<EmbeddedViewRef>.rootNodes` and `<ViewRefImpl>.rootNodes` has
    been tightened from `List<dynamic>` to `List<Node>` (where `Node` is from
    `dart:html`).

*   A combination of compile errors and warnings are produced when it seem that
    `template`, `templateUrl`, `style`, or `styleUrls` are either incorrect or
    missing when required.

*   The compiler now reports an actionable error when an annotation is used on a
    private class member. We also report errors when various annotations are
    used improperly (but not in all cases yet).

*   The compiler optimizes `*ngIf` usages where the content is pure HTML.

*   The view compiler is able to tell when `exports: [ ... ]` in an `@Component`
    are static reads and are immutable (such as `String`). This allows us to
    optimize the generated code.

*   Some changes to how template files import 'dart:core' to accommodate
    analyzer changes that make 'dynamic' a member of 'dart:core'. These should
    not have user-visible effects.

*   Fixed a bug where many queries (`@ViewChildren()` and the like) generated
    additional runtime casts in production mode. Now in Dart2JS with
    `--omit-implicit-checks` the casts are removed.

*   Emits more optimized code when there are multiple data bindings in a row
    that are checked only once (such as `final` strings). Previously we
    generated redundant code.

*   Fixed an optimization issue when `@ViewChild()` or `@ContentChild()` was
    used on a nested element (i.e. inside a `<template>`). The code that was
    produced accidentally created two queries instead of one.

*   Improved error message for binding incorrectly typed event handlers. This
    moves the check from event dispatch time, to event subscription time,
    meaning it *may* be a breaking change if you had an incorrectly typed event
    handler bound to a output that never fired.

### Application Bootstrap

#### New features

*   The process for starting your AngularDart application changed significantly:

    *   For most applications, we now strongly recommend using the new `runApp`
        function. Instead of starting your application by passing the `Type` of
        an `@Component`-annotated `class`, you now pass a `ComponentFactory`,
        the generated code for a component:

    ```dart
    import 'package:angular/angular.dart';

    import 'main.template.dart' as ng;

    void main() {
        runApp(ng.RootComponentNgFactory);
    }

    @Component(
        selector: 'root',
        template: 'Hello World',
    )
    class RootComponent {}
    ```

    To provide top-level services, use the `createInjector` parameter, and pass
    a generated `InjectorFactory` for a top-level annotated with
    `@GenerateInjector`:

    ```dart
    import 'package:angular/angular.dart';

    import 'main.template.dart' as ng;

    void main() {
      runApp(ng.RootComponentNgFactory, createInjector: rootInjector);
    }

    class HelloService {
      void sayHello() => print('Hello!');
    }

    @GenerateInjector([
       ClassProvider(HelloService),
    ])
    final InjectorFactory rootInjector = ng.rootInjector$Injector;
    ```

    A major difference between `runApp` and previous bootstrapping code is the
    lack of the `initReflector()` method or call, which is no longer needed.
    That means using `runApp` disables the use of `SlowComponentLoader` and
    `ReflectiveInjector`, two APIs that require this extra runtime metadata.

    To enable use of these classes for migration purposes, use `runAppLegacy`:

    ```dart
    import 'package:angular/angular.dart';

    // ignore: uri_has_not_been_generated
    import 'main.template.dart' as ng;

    void main() {
      runAppLegacy(
        RootComponent,
        createInjectorFromProviders: [
          ClassProvider(HelloService),
        ],
        initReflector: ng.initReflector,
      );
    }
    ```

    **NOTE**: `initReflector` and `runAppLegacy` disables tree-shaking on any
    class annotated with `@Component` or `@Injectable`. We strongly recommend
    migrating to the `runApp` pattern.

#### Breaking changes

*   The top-level function `bootstrap` was deleted. This function always threw a
    runtime exception since `5.0.0-alpha+5`, and was a relic of when a code
    transformer rewrote it automatically as `bootstrapStatic`.

*   Dropped support for `@AngularEntrypoint` and rewriting entrypoints to
    automatically use `initReflector()` and `bootstrapStatic`. This is no longer
    supported in the new build system.

*   `RenderComponentType` is no longer part of the public API.

*   `<ApplicationRef>` `.componentFactories`, `.componentTypes`, `.zone`, and
    `.registerBootstrapListener` were removed; these were used internally by the
    legacy router and not intended to be part of the public API.

*   `PLATFORM_INITIALIZERS` was removed.

*   `APP_INITIALIZER` was removed. A similar functionality can be accomplished
    using the `runAppAsync` or `runAppLegacyAsync` functions with the
    `beforeComponentCreated` callback.

*   `PlatformRef` and `PlatformRefImpl` were removed.

### Misc

#### New features

*   Added `package:angular/meta.dart`, a series of utilities for additional
    static analysis checks and/or functions to retain semantics for migration
    purposes, starting with `castCallback1ForDirective` and
    `castCallback2ForDirective`. These methods are _only_ intended to be used as
    stop-gaps for the lack of generic support in AngularDart directives and
    components.

#### Breaking changes

*   `<NgZone>.onStable` has been renamed to `onTurnDone`.

*   `<NgZone>.onUnstable` has been renamed to `onTurnStart`.

*   The `context` parameter was removed from `<TemplateRef>.createEmbeddedView`.

*   The following relatively unused fields and functions were removed:

    *   `APPLICATION_COMMON_PROVIDERS`
    *   `BROWSER_APP_COMMON_PROVIDERS`
    *   `BROWSER_APP_PROVIDERS`
    *   `PACKAGE_ROOT_URL`
    *   `ErrorHandlingFn`
    *   `UrlResolver`
    *   `WrappedTimer`
    *   `WrappedValue`
    *   `ZeroArgFunction`
    *   `appIdRandomProviderFactory`
    *   `coreBootstrap`
    *   `coreLoadAndBootstrap`
    *   `createNgZone`
    *   `createPlatform`
    *   `disposePlatform`
    *   `getPlatform`

*   Running within the `NgZone` will no longer cause addtional turns to occur
    within it's parent's zone. `<NgZone>.run()` will now run inside the parent
    zone's `run()` function as opposed to the other way around.

*   The compilation mode `--debug` (sparingly used externally) is now no longer
    supported. Some flags and code paths in the compiler still check/support it
    but it will be removed entirely by the final release and should no longer be
    used. We will rely on assertion-based tree-shaking (from `Dart2JS`) going
    forward to emit debug-only conditional code.

#### Bug fixes

*   We longer invoke `<ExceptionHandler>.call` with a `null` exception.

#### Other improvements

*   Misspelled or otherwise erroneous annotations on classes now produce a more
    understandable error message, including the element that was annotated and
    the annotation that was not resolved.

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
    [DartDevCompiler (DDC)](https://github.com/dart-lang/sdk/tree/master/pkg/dev_compiler).

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
