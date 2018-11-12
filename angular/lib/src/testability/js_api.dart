@JS()
library angular.src.testability.js_api;

import 'dart:html';

import 'package:js/js.dart';
import 'package:meta/meta.dart';

/// A function that returns a testability API for a provided DOM element.
typedef JsGetAngularTestability = JsTestability Function(Element);

/// A function that returns all testability APIs currently available.
typedef JsGetAllAngularTestabilities = List<JsTestability> Function();

/// Globally scoped [JsTestabilityRegistry] accessors.
@JS('self')
external JsTestabilityRegistry get jsTestabilityGlobals;

/// An array of stability functions shared across major frameworks.
///
/// Other non-AngularDart stabilizers may also be registered here!
@JS('frameworkStabilizers')
external List<void Function(bool didAsyncWork)> get frameworkStabilizers;

@JS('frameworkStabilizers')
external set frameworkStabilizers(List<void Function(bool)> list);

/// A JavaScript interface for interacting with AngularDart's `Testability` API.
///
/// This interfaces with a running AngularDart application.
@JS()
@anonymous
abstract class JsTestability {
  external factory JsTestability({
    @required bool Function() isStable,
    @required void Function(void Function(bool didAsyncWork)) whenStable,
  });

  /// Returns whether the application is considered stable.
  ///
  /// Stability is determined when the DOM is unlikely to change due to the
  /// framework. By default, this is determined by no known asynchronous tasks
  /// (microtasks, or timers) being present but not yet executed within the
  /// framework context.
  ///
  /// Applications can also customize stability by manually adding/decrementing
  /// other pending asynchronous tasks, such as pending RPCs, reading from
  /// IndexedDB, etc.
  bool isStable();

  /// Invokes the provided [callback] when the application [isStable].
  ///
  /// If the application was already stable at the time of this function being
  /// invoked, [callback] is invoked with a value of `false` for `didWork`,
  /// indicating that no asynchronous work was awaited before execution.
  /// Otherwise a value of `true` is passed.
  void whenStable(void Function(bool) callback);
}

@JS()
@anonymous
abstract class JsTestabilityRegistry {
  external factory JsTestabilityRegistry({
    @required JsGetAngularTestability getAngularTestability,
    @required JsGetAllAngularTestabilities getAllAngularTestabilities,
  });

  /// Given a DOM [rootElement], returns the [JsTestability] interface for it.
  ///
  /// It may throw a runtime error if the element provided does not have a
  /// testability interface (for example, it may not represent the root element
  /// of an AngularDart app, or e2e testing was not enabled for that app).
  external JsGetAngularTestability get getAngularTestability;
  external set getAngularTestability(JsGetAngularTestability fn);

  /// Returns an array of _all_ [JsTestability] interfaces in the browser.
  external JsGetAllAngularTestabilities get getAllAngularTestabilities;
  external set getAllAngularTestabilities(JsGetAllAngularTestabilities fn);
}
