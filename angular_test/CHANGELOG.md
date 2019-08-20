### New Features

*   `NgTestFixture.dispose()` now resets and clears all component styles from
    the DOM when assertions are enabled.

## 2.4.0

### New Features

*   Added an optional named parameter, `maxIterations`, to
    `FakeTimeNgZoneStabilizer`'s constructor. If not specified 10 maximum loops
    are attempted to `elapse` pending timers. In advanced use cases, a test may
    configure a higher threshold:

    ```dart
    NgZoneStabilizer allow100InsteadOf10() {
      return FakeTimeNgZoneStabilizer(timerZone, ngZone, maxIterations: 100);
    }
    ```

### Bug Fixes

*   `NgTestFixture.update()` now delegates to `ComponentRef.update()`, which
    automatically calls `markForCheck()`. Previously, an `OnPush` component
    under test might not have been properly updated.

## 2.3.1

*   Maintenance release to support Angular 6.0-alpha.

## 2.3.0

### New Features

*   Added support for periodic timers in `FakeTimeNgZoneStabilizer`.

## 2.2.0

### Breaking Changes

*   Changed `NgTestStabilizer` initialization from originating from a
    `List<NgTestStabilizerFactory>` to a single `NgTestStabilizerFactory`. The
    new top-level function `composeStabilizers` may be used to create a
    composite factory from multiple factories:

    ```dart
    composeStabilizers([
      (_) => stabilizer1,
      (_) => stabilizer2,
    ])
    ```

    This helps disambiguate the order of stabilizers running, which in turn will
    allow additional new stabilizers and features to be added in a non-breaking
    fashion. This change does not impact users that were not augmenting or
    creating their own stabilizers (i.e. most users/most tests).

*   Removed `NgTestStabilizer.all`. See `composeStabilizers` instead.

*   Removed `NgZoneStabilizer`. The new class is `RealTimeNgZoneStabilizer`,
    though most users should not be impacted `NgTestBed` now uses the new
    stabilizer by default.

### New Features

*   Added a new `NgTestStabilizer.alwaysStable`, which does what it sounds like
    and always reports stability. This handles making composition easier as the
    root stabilizer can effectively be a no-op.

### Bug Fixes

*   When using `RealTimeNgZoneStabilizer`, do not try to stabilize timers that
    run outside of Angular zone.

## 2.1.0

### New Features

*   Supported `beforeComponentCreated(Injector)` when creating fixture to allow
    using `injector` to set up prerequisite data for testing from DI.

    This is useful when an object (that is already injected to the app) is
    difficult to create otherwise. For example:

    ```dart
    // ComplexDataLayer is difficult to instantiate in test, but it is needed
    // to set up some fake data before the component is loaded and used.
    final fixture = await testBed.create(
      beforeComponentCreated: (i) {
        var dataLayer = i.get(ComplexDataLayer) as ComplexDataLayer;
        dataLayer.setUpMockDataForTesting();
      },
    );
    ```

## 2.0.0

### New Features

*   Supported `FutureOr<void>` for `beforeChangeDetection`.

*   `NgZoneStabilizer` waits for the longest pending timer during `update()`.

*   Added `isStable` API to `NgTestStabilizer`.

*   Made `NgTestStabilizerFactory` public.

### Breaking Changes

*   Removed `throwsInAngular`. Use `throwsA`.

*   Removed `NgTestFixture#query/queryAll`, as debug-mode is being turned down.

*   Run `DelegatingNgTestStabilizer` stabilizers one by one instead of run all
    at once. `update()` for each stabilizers will be run at least once. After
    that, it will only be run if the current stabilizer is not stable.

*   `pub run angular_test` was entirely removed. Similar functionality is
    supported out of the box by `build_runner`:

```bash
$ pub run build_runner test
```

*   Removed built-in support for `package:pageloader`. The current version of
    `pageloader` relies on `dart:mirrors`, which is being removed from the web
    compilers (dart2js, dartdevc). There is a new version of `pageloader` in
    development that uses code generation. We'll consider re-adding support once
    available or through another package (i.e. `angular_pageloader` or similar).

*   Adding stabilizers to `NgTestBed` now takes a factory function of type
    `NgTestStabilizer Function(Injector)`, which is aliased as
    `NgTestStabilizerFactory`. This allows using `NgTestBed` without any dynamic
    reflective factories (i.e. `initReflector()`) and doesn't have impact to
    most users.

### Bug Fixes

*   Deleted an unnecessary `hostElement.append(componentRef.location)`.

*   Fixed a bug where a `WillNeverStabilizeError` was thrown whenever there was
    a non-zero length `Timer` being executed. This was due to a bug in how the
    `NgStabilizer` was executing - constantly calling the `update` function
    instead of calling it _once_ and waiting for stabilization.

*   Fixed a bug where stabilizers are considered stable even when some of them
    are not.

*   Fixed a bug where `_createDynamic` does not preserve `rootInjector`.

*   Added `NgTestBed.forComponent`, which takes a `ComponentFactory<T>`, and
    optionally an `InjectorFactory`. This allows writing tests entirely free of
    any invocations of `initReflector()`.

## 1.0.1

### Cleanup

*   Remove dependency on `angular_router`.

## 1.0.0

### Breaking Changes & Deprecations

*   Throws in bootstrapping if the root component does not use default change
    detection. AngularDart does not support `OnPush` or other change detection
    strategies on the root component.

*   Pub serve now defaults to a random unused port (instead of `8080`) and
    `--port` is deprecated. Going forward the supported way to supply this
    argument is via `--serve-arg`:

```bash
$ pub run angular_test --serve-arg=port=1234
```

*   Option `--run-test-flag` (`-t`) is now **deprecated**, and no longer has a
    default value of `aot`. Tags are still highly encouraged in order to have
    faster compilation times! Use `--test-arg` instead:

```bash
$ pub run angular_test --test-arg=--tags=aot
```

*   Option `--platform` (`-p`) is now **Deprecated**, and no longer has a
    default value of `content-shell`, which was not always installed on host
    machines. Instead use `--test-arg`:

```bash
$ pub run angular_test --test-arg=--platform=content-shell
```

*   Option `--name` (`-n`) and `--simple-name` (`-N`) are also deprecated. Use
    `--test-arg=--name=` and `--test-arg=--simple-name=` instead.

*   Changes to `compatibility.dart` might not be considered in future semver
    updates, and it **highly suggested** you don't use these APIs for any new
    code.

*   Change `NgTestFixture.update` to have a single optional parameter

### Features

*   Add assertOnlyInstance to fixture to remove some boilerplate around testing
    the state of a instance. Only use to test state, not to update it.

*   Added `--serve-arg` and `--test-arg`, which both support multiple arguments
    in order to have better long-term support for proxying to both `pub serve`
    and `pub run test` without frequent changes to this package. For example to
    use the [DartDevCompiler (dartdevc)]:

```bash
$ pub run angular_test --serve-arg=web-compiler=dartdevc
```

*   Add support for setting a custom `PageLoader` factory:

```dart
testBed = testBed.setPageLoader(
  (element) => new CustomPageLoader(...),
);
```

*   Add support for `query` and `queryAll` to `NgTestFixture`. This works
    similar to the `update` command, but is called back with either a single or
    multiple _child_ component instances to interact with or run expectations
    against:

```dart
// Assert we have 3 instances of <child>.
await fixture.queryAll(
  (el) => el.componentInstance is ChildComponent,
  (children) {
    expect(children, hasLength(3));
  },
);
```

*   Add built-in support for `package:pageloader`:

```dart
final fixture = await new NgTestBed<TestComponent>().create();
final pageObject = await fixture.getPageObject/*<ClickCounterPO>*/(
  ClickCounterPO,
);
expect(await pageObject.button.visibleText, 'Click count: 0');
await pageObject.button.click();
expect(await pageObject.button.visibleText, 'Click count: 1');
```

### Fixes

*   Workaround for `pub {serve|build}` hanging on `angular_test` as a
    dependency.

*   Fixes a bug where the root was not removed from the DOM after disposed.

*   Added a missing dependency on `package:func`.

*   Properly fix support for windows by using `pub.bat`.

*   Replace all uses of generic comment with proper syntax.

*   Fixed a bug where `activeTest` was never set (and therefore disposed).

*   Fixed a bug where `pub`, not `pub.bat`, is run in windows.

*   Update `pubspec.yaml` so it properly lists AngularDart `3.0.0-alpha`

*   Fix the executable so `pub run angular_test` can be used

*   Fix a serious generic type error when `NgTestBed` is forked

*   Fix a generic type error

*   Added `compatibility.dart`, a temporary API to some users migrate
