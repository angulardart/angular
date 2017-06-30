## 1.0.0-beta+4

**Now supports `package:angular` instead of `package:angular2`.**

## 1.0.0-beta+3

### Breaking Changes & Deprecations

- Throws in bootstrapping if the root component does not use default change
  detection. AngularDart does not support `OnPush` or other change detection
  strategies on the root component.

- Pub serve now defaults to a random unused port (instead of `8080`) and
  `--port` is deprecated. Going forward the supported way to supply this
  argument is via `--serve-arg`:

```bash
$ pub run angular_test --serve-arg=port=1234
```

- Option `--run-test-flag` (`-t`) is now **deprecated**, and no longer has a
  default value of `aot`. Tags are still highly encouraged in order to have
  faster compilation times! Use `--test-arg` instead:

```bash
$ pub run angular_test --test-arg=--tags=aot
```

- Option `--platform` (`-p`) is now **Deprecated**, and no longer has a default
  value of `content-shell`, which was not always installed on host machines.
  Instead use `--test-arg`:

```bash
$ pub run angular_test --test-arg=--platform=content-shell
```

- Option `--name` (`-n`) and `--simple-name` (`-N`) are also deprecated. Use
  `--test-arg=--name=` and `--test-arg=--simple-name=` instead.

### Features

- Added `--serve-arg` and `--test-arg`, which both support multiple arguments
  in order to have better long-term support for proxying to both `pub serve`
  and `pub run test` without frequent changes to this package. For example to
  use the [DartDevCompiler (dartdevc)]:


```bash
$ pub run angular_test --serve-arg=web-compiler=dartdevc
```

### Fixes

- Fixes a bug where the root was not removed from the DOM after disposed.

- Added a missing dependency on `package:func`.

## 1.0.0-beta+2

- Add support for setting a custom `PageLoader` factory:

```dart
testBed = testBed.setPageLoader(
  (element) => new CustomPageLoader(...),
);
```

- Add support for `query` and `queryAll` to `NgTestFixture`. This works similar
  to the `update` command, but is called back with either a single or multiple
  _child_ component instances to interact with or run expectations against:

```dart
// Assert we have 3 instances of <child>.
await fixture.queryAll(
  (el) => el.componentInstance is ChildComponent,
  (children) {
    expect(children, hasLength(3));
  },
);
```

## 1.0.0-beta+1

- Properly fix support for windows by using `pub.bat`.

## 1.0.0-beta

- Prepare to support `angular2: 3.0.0-beta`.
- Replace all uses of generic comment with proper syntax.
- Fixed a bug where `activeTest` was never set (and therefore disposed).
- Fixed a bug where `pub`, not `pub.bat`, is run in windows.

## 1.0.0-alpha+6

- Address breaking changes in `angular2`: `3.0.0-alpha+1`.

## 1.0.0-alpha+5

- Update `pubspec.yaml` to tighten the constraint on AngularDart

## 1.0.0-alpha+4

- Update `pubspec.yaml` so it properly lists AngularDart `3.0.0-alpha`

## 1.0.0-alpha+3

- Fix the executable so `pub run angular_test` can be used

## 1.0.0-alpha+2

- Add built-in support for `package:pageloader`:

```dart
final fixture = await new NgTestBed<TestComponent>().create();
final pageObject = await fixture.getPageObject/*<ClickCounterPO>*/(
  ClickCounterPO,
);
expect(await pageObject.button.visibleText, 'Click count: 0');
await pageObject.button.click();
expect(await pageObject.button.visibleText, 'Click count: 1');
```

- Fix a serious generic type error when `NgTestBed` is forked

- Fix a generic type error
- Added `compatibility.dart`, a temporary API to some users migrate

Changes to `compatibility.dart` might not be considered in future semver
updates, and it **highly suggested** you don't use these APIs for any new code.

## 1.0.0-alpha+1

- Change `NgTestFixture.update` to have a single optional parameter

## 1.0.0-alpha

- Initial commit with compatibility for AngularDart `2.2.0`
