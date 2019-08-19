# Debugging


WARNING: This page is a WIP, and not yet exhaustive nor authorative.

## `debugCheckBindings`

Currently AngularDart makes an effort to throw, in development mode, a runtime
error when evaluating a template binding or interpolation results in a different
value when invoked a second time in the same change detection pass (e.g.
synchronously). For example:

```html
Hello, {{i}}
```

```dart
class C {
  var _i = 0;
  get i => _i++;
}
```

Despite the above being valid Dart, `i` will return a different value everytime
it is called, which means that Angular will not be able to "stabilize" on a
value and propogate it. An `UnstableExpressionError` will be thrown.

Unfortunately, this protection is only granted to bindings of a primitive value
(such as `Null`, `int`, `String`, `bool`). We are introducing a new opt-in flag
in order to get full protection. As a bonus, we are also including context
information (expression evaluated and source location) when the opt-in is used.

### Opt-In

At the top of your test case, import and invoke `debugCheckBindings()`:

```dart
// example_test.dart

import 'package:angular/angular.dart';

void main() {
  // All test cases going forward opt-in to the new protection & better errors.
  debugCheckBindings();
}
```

In more advanced use-cases, you may opt-in/out by passing a boolean parameter:

```dart
// example_test.dart

import 'package:angular/angular.dart';

void main() {
  group('Tests that do not fail with debugCheckBindings', () {
    setUp(() {
      debugCheckBindings(true);
    });

    tearDown(() {
      debugCheckBindings(false);
    });

    // ...
  });

  group('Tests that do not support debugCheckBindings yet', () {
    // ...
  });
}
```

### Caveats

Source and expression information is currently a **WIP**, and you will likely
find many expressions that have them omitted. We will update the flag and this
documentation as we increase confidence in the source information.
