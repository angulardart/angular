@JS()
library angular.src.testability.js_api;

import 'package:js/js.dart';
import 'package:meta/meta.dart';

/// A JavaScript interface for interacting with AngularDart's `Testability` API.
///
/// This interfaces with a running AngularDart application.
@JS()
@anonymous
abstract class JsTestability {
  external factory JsTestability({
    @required bool Function() isStable,
    @required void Function(void Function(bool)) whenStable,
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
  void whenStable(void Function(bool didWork) callback);
}
