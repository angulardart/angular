import 'dart:async';

import 'package:angular2/di.dart';
import 'package:angular2/src/core/zone.dart';

/// Abstraction around services that change the state of the DOM asynchronously.
///
/// One strategy of testing Angular components is to interact with their emitted
/// DOM as-if you were a user with a browser, and assert the state of the DOM
/// instead of the state of the component. For example, a toggle button that
/// switches between 'Yes' and 'No' when clicked:
///     testToggleButton(ButtonElement button) {
///       expect(button.text, 'Yes');
///       button.click();
///       expect(button.text, 'No');
///     }
///
/// In the case of Angular, and of other DOM-related libraries, however, the
/// changes are not always applied immediately (synchronously). Instead, we need
/// a contract that lets us `await` any possible changes, and then assert state:
///     testToggleButton(ButtonElement button, NgTestStabilizer dom) async {
///       expect(button.text, 'Yes');
///       await dom.update(() => button.click());
///       expect(button.text, 'No');
///     }
///
/// Either `extend` or `implement` [NgTestStabilizer].
abstract class NgTestStabilizer {
  /// Runs [stabilizer.update] until it completes with `false`.
  ///
  /// If more than [threshold] occurrences, throws [WillNeverStabilizeError].
  static Future<Null> stabilize(
    NgTestStabilizer stabilizer, {
    int threshold: 100,
  }) async {
    if (threshold == null) {
      throw new ArgumentError.notNull('threshold');
    }
    var count = 0;
    bool thresholdExceeded() => count++ > threshold;
    while (await stabilizer.update()) {
      if (thresholdExceeded()) {
        throw new WillNeverStabilizeError._(threshold);
      }
    }
  }

  /// Create a new [NgTestStabilizer] that delegates to all [stabilizers].
  ///
  /// The [NgTestStabilizer.update] completes when _every_ stabilizer completes.
  factory NgTestStabilizer.all(Iterable<NgTestStabilizer> stabilizers) =
      _DelegatingNgTestStabilizer;

  /// Returns a [Future] that completes after processing DOM update events.
  ///
  /// If `true` is returned, calling [update] again may be required to get to
  /// a completely stable state. See [NgTestStabilizer.stabilize].
  ///
  /// [fn] may be supported to be aware of any side-effects, for example:
  ///     @override
  ///     Future<bool> update([void fn()]) async {
  ///       // Track the results of running fn, which may spawn async events.
  ///       _zone.run(fn);
  ///
  ///       // Now wait until we know those events are done.
  ///       await _waitUntilZoneStable();
  ///       return true;
  ///     }
  Future<bool> update([void fn()]) => new Future<bool>.value(true);
}

/// Thrown by [NgTestStabilizer.updateUntilStable].
class WillNeverStabilizeError extends Error {
  final int _threshold;

  WillNeverStabilizeError._(this._threshold);

  @override
  String toString() => 'May never stabilize: Attempted $_threshold times.';
}

class _DelegatingNgTestStabilizer implements NgTestStabilizer {
  final List<NgTestStabilizer> _delegates;

  _DelegatingNgTestStabilizer(Iterable<NgTestStabilizer> delegates)
      : _delegates = delegates.toList(growable: false);

  @override
  Future<bool> update([void fn()]) => Future
      .wait(_delegates.map((d) => d.update(fn)))
      .then((results) => results.any((r) => r));
}

/// A wrapper api that reports stability based on [NgZone].
@Injectable()
class NgZoneStabilizer implements NgTestStabilizer {
  final NgZone _ngZone;

  NgZoneStabilizer(this._ngZone);

  bool get _isStable =>
      !_ngZone.hasPendingMacrotasks && !_ngZone.hasPendingMicrotasks;

  @override
  Future<bool> update([void fn()]) {
    final completer = new Completer<bool>();
    final onErrorSub = _ngZone.onError.listen((NgZoneError ngZoneError) {
      if (!completer.isCompleted) {
        var s = new StackTrace.fromString(ngZoneError.stackTrace.join('\n'));
        completer.completeError(ngZoneError.error, s);
      }
    });
    final onStableSub = _ngZone.onStable.listen((_) {
      if (!completer.isCompleted) {
        completer.complete(_isStable);
      }
    });
    completer.future.whenComplete(() {
      onErrorSub.cancel();
      onStableSub.cancel();
    });
    _ngZone.run(fn);
    return completer.future;
  }
}

/// A type container class that asserts [T] is of [NgTestStabilizer].
///
/// __Example use__:
///     new RegisterStabilizer<MyCustomStabilizer>();
class RegisterStabilizer<T extends NgTestStabilizer> {
  RegisterStabilizer() {
    _assertIsNotDynamic();
  }

  /// Runs an assertion that the type is of NgTestStabilizer.
  void _assertIsNotDynamic() {
    if (T == dynamic) {
      throw new UnsupportedError('Explicit stabilizer type T required.');
    }
  }

  /// Registered generic type that is guaranteed to be a [NgTestStabilizer].
  Type get type => T;
}
