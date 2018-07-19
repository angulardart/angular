# End to End Testing


AngularDart does not currently have _direct_ support for integration/end-to-end
testing, but instead has some Dart and JavaScript code for communicating with
running AngularDart applications. This can be used by third-party tools like
Dart's `web_driver` or JS's `protractor` - or you can roll your own tool.

**WARNING**: This API is not considered stable, and may change in the future.
             As of the current release, testability is _always_ enabled, even
             if your application does not use it, which has negative effects on
             code-size and initial startup. We may change this at a future point
             of time.

## Dart Interface

AngularDart supports a _Dart_ interface, `Testability`, which can be injected:

```dart
abstract class Testability {
  /// Returns whether the application is currently stable.
  bool isStable();

  /// Invokes [callback] when the application is stable.
  ///
  /// The argument, `didAsyncWork`, will be `true` if asynchronous work was
  /// awaited _before_ invoking the callback, or `false` if the framework was
  /// _already_ stable.
  void whenStable(void Function(bool didAsyncWork) callback);
}
```

It is semantically equivalent to the API described in _getAngularTestability_.

## JS Interface

AngularDart inserts the following properties in the JS context (`window`),
which in turn can be used by tools to communicate with AngularDart

### API

The following are methods attached to `window`:

#### `getAngularTestability(element)`

Given a DOM element that is the _root_ component (i.e. the one created by
`runApp` or `bootstrapStatic`), returns the `Testability` interface for the
app. Throws an error if component provided does not have a testability
interface (it might not represent an AngularDart app, or e2e testing was not
enabled for that app).

Here's an example:

```js
var ngAppRoot = document.querySelector('ng-app');
var testability = getAngularTestability(ngAppRoot);
```

The JS interface of `Testability` is as follows:

* `isStable()`: Returns whether the application is currently stable.
* `whenStable(callback)`: Invokes `callback` when the application is stable.
  * `callback` may provide a single argument, `didAsyncWork`, which represents
    whether the `whenStable` call had to wait for asynchronous work.
  * It will be invoked with `false` when the application was already stable.

#### `getAllAngularTestabilities()`

Returns an array of _all_ `Testability` interfaces in the browser.

#### `ngTestabilityRegistries`

An array of all `TestabilityRegistry` interfaces in the browser.

**NOTE**: Currently this does not seem to be used today, and may be removed.

#### `frameworkStabilizers`

An array of functions with a definition similar to `Testability.whenStable`:

```js
var stabilizers = frameworkStabilizers;
for (var i = 0; i < stabilizers.length; i++) {
  var fn = stabilizers[i];
  fn(function(didAsyncWork) {
     // Invoked when reported stable.
  });
}
```

Unlike the other methods, this is considered a mutable array that other
frameworks or services could add their own stability methods to, and is not
necessarily specific to AngularDart.

AngularDart will add a method for each `Testability` interface added.
