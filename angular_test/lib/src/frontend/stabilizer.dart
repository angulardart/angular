// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:angular/di.dart';

import '../errors.dart';

/// Abstraction around services that change the state of the DOM asynchronously.
///
/// One strategy of testing Angular components is to interact with their emitted
/// DOM as-if you were a user with a browser, and assert the state of the DOM
/// instead of the state of the component. For example, a toggle button that
/// switches between 'Yes' and 'No' when clicked:
/// ```dart
/// testToggleButton(ButtonElement button) {
///   expect(button.text, 'Yes');
///   button.click();
///   expect(button.text, 'No');
/// }
/// ```dart
///
/// In the case of Angular, and of other DOM-related libraries, however, the
/// changes are not always applied immediately (synchronously). Instead, we need
/// a contract that lets us `await` any possible changes, and then assert state:
/// ```dart
/// testToggleButton(ButtonElement button, NgTestStabilizer dom) async {
///   expect(button.text, 'Yes');
///   await dom.update(() => button.click());
///   expect(button.text, 'No');
/// }
/// ```
///
/// Either `extend` or `implement` [NgTestStabilizer].
abstract class NgTestStabilizer {
  /// Create a new [NgTestStabilizer] that delegates to all [stabilizers].
  ///
  /// The [NgTestStabilizer.update] completes when _every_ stabilizer completes.
  factory NgTestStabilizer.all(
    Iterable<NgTestStabilizer> stabilizers,
  ) = _DelegatingNgTestStabilizer;

  // Allow inheritance.
  const NgTestStabilizer();

  /// Returns a future that completes after processing DOM update events.
  ///
  /// If `true` is returned, calling [update] again may be required to get to
  /// a completely stable state. See [NgTestStabilizer.stabilize].
  ///
  /// [fn] may be supported to be aware of any side-effects, for example:
  /// ```
  /// @override
  /// Future<bool> update([void fn()]) async {
  ///   // Track the results of running fn, which may spawn async events.
  ///   _zone.run(fn);
  ///
  ///   // Now wait until we know those events are done.
  ///   await _waitUntilZoneStable();
  ///   return true;
  /// }
  /// ```
  Future<bool> update([void fn()]) {
    return new Future<bool>.sync(() {
      if (fn != null) {
        fn();
      }
      return false;
    });
  }

  /// Runs [update] until it completes with `false`, reporting stabilized.
  ///
  /// If more then [threshold] attempts occur, throws [WillNeverStabilizeError].
  Future<Null> stabilize({void run(), int threshold: 100}) async {
    if (threshold == null) {
      throw new ArgumentError.notNull('threshold');
    }
    var count = 0;
    bool thresholdExceeded() => count++ > threshold;
    while (!await update(run)) {
      if (thresholdExceeded()) {
        throw new WillNeverStabilizeError(threshold);
      }
    }
  }
}

class _DelegatingNgTestStabilizer extends NgTestStabilizer {
  final List<NgTestStabilizer> _delegates;

  _DelegatingNgTestStabilizer(Iterable<NgTestStabilizer> stabilizers)
      : _delegates = stabilizers.toList(growable: false);

  @override
  Future<bool> update([void fn()]) async {
    if (_delegates.isEmpty) {
      return false;
    }
    final results = await Future.wait(_delegates.map((s) => s.update(fn)));
    return results.any((r) => r);
  }
}

/// A wrapper API that reports stability based on the Angular [NgZone].
class NgZoneStabilizer extends NgTestStabilizer {
  final NgZone _ngZone;

  const NgZoneStabilizer(this._ngZone);

  /// Zone is considered stable when there are no more micro-tasks or timers.
  bool get isStable {
    return !(_ngZone.hasPendingMacrotasks || _ngZone.hasPendingMicrotasks);
  }

  @override
  Future<bool> update([void fn()]) {
    return new Future<Null>.sync(() => _waitForZone(fn)).then((_) => isStable);
  }

  Future<Null> _waitForZone([void fn()]) async {
    // If we haven't supplied anything, at least run a simple function w/ task.
    // This gives enough "work" to do where we can catch an error or stability.
    scheduleMicrotask(() {
      _ngZone.runGuarded(fn ?? () => scheduleMicrotask(() {}));
    });

    // Stop executing as soon as either stability or an error occurs.
    NgZoneError caughtError;
    var finishedWithoutError = false;
    await Future.any([
      _ngZone.onTurnDone.first,
      _ngZone.onError.first.then((e) {
        if (!finishedWithoutError) {
          caughtError = e;
        }
      })
    ]);

    // Give a bit of time to catch up, we could still have an occur in future.
    await new Future(() {});

    // Fail if we caught an error.
    if (caughtError != null) {
      return new Future.error(
        caughtError.error,
        new StackTrace.fromString(caughtError.stackTrace.join('\n')),
      );
    }

    // Mark finish.
    finishedWithoutError = true;
  }

  @override
  String toString() => '$NgZoneStabilizer {isStable: $isStable}';
}
