*   `pub run angular_test` was entirely removed. This hasn't worked since
    `2.0.0-alpha+3`, but instead threw an error message reminding users it was
    no longer supported.

## 2.0.0-alpha+8

*   The minimum SDK version is now `sdk: ">=2.0.0-dev.46.0 <2.0.0"`.

*   **DEPRECATED**: `throwsInAngular` is now a no-op, and can be removed.

## 2.0.0-alpha+7

*   Maintenance release, supporting newer package versions.

## 2.0.0-alpha+6

*   Maintenance release, supporting newer package versions.

## 2.0.0-alpha+5

*   Maintenance release, supporting newer package versions.

## 2.0.0-alpha+4

*   Removed built-in support for `package:pageloader`. The current version of
    `pageloader` relies on `dart:mirrors`, which is being removed from the web
    compilers (dart2js, dartdevc). There is a new (internal-only, right now)
    version of `pageloader` in development that uses code generation, but it is
    not available externally yet. We'll consider re-adding support once
    available or through another package (i.e. `angular_pageloader` or similar).

*   Added `NgTestBed.forComponent`, which takes a `ComponentFactory<T>`, and
    optionally an `InjectorFactory`. This allows writing tests entirely free of
    any invocations of `initReflector()`.

*   **BREAKING CHANGE**: Adding stabilizers to `NgTestBed` now takes a factory
    function of type `NgTestStabilizer Function(Injector)`, which is aliased as
    `NgTestStabilizerFactory`. This allows using `NgTestBed` without any dynamic
    reflective factories (i.e. `initReflector()`) and doesn't have impact to
    most users.

## 2.0.0-alpha+3

*   Removed support for `pub run angular_test`. This is no longer strictly
    needed, as it was just a convenience for running both the build system and
    test runner. Similar functionality is supported out of the box by
    `build_runner`:

```bash
$ pub run build_runner test
```

## 2.0.0-alpha+2

_Maintenance release, to support the latest package:angular alpha._

## 2.0.0-alpha+1

*   Added support for `build.yaml`.

## 2.0.0-alpha

> **NOTE**: This was previously `1.0.2-alpha+1`, but since this has major
> breaking changes that make it incompatible with the `1.x.x` releases in order
> to support `angular 5.x.x`, this will now be the `2.0.0` alpha release.

*   Add support for the use of an externally launched `pub serve` by using
    "none" as the value of `--experimental-serve-script`.

## 1.0.2-alpha+1

*   Use the new generic function syntax, stop using `package:func`.
*   Support breaking changes and deprecations in angular 5.0.0-alpha+1.

## 1.0.2-alpha

*   Support breaking changes in angular 5.0.0-alpha

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
