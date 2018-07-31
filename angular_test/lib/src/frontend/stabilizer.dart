// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:angular/di.dart';
import 'package:angular/experimental.dart';

import '../errors.dart';

/// Creates a [NgTestStabilizer], optionally from an [Injector].
typedef NgTestStabilizerFactory = NgTestStabilizer Function(Injector);

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
  ) = DelegatingNgTestStabilizer;

  // Allow inheritance.
  const NgTestStabilizer();

  /// Whether this stabilizer is currently stable.
  bool get isStable => false;

  /// Returns a future that completes after processing DOM update events.
  ///
  /// If `true` is returned, calling [update] again may be required to get to
  /// a completely stable state. See [NgTestStabilizer.stabilize].
  ///
  /// [runAndTrackSideEffects] may optionally be specified:
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
  Future<bool> update([void Function() runAndTrackSideEffects]) {
    return Future<bool>.sync(() {
      if (runAndTrackSideEffects != null) {
        runAndTrackSideEffects();
      }
      return false;
    });
  }

  /// Runs [update] until it completes with `false`, reporting stabilized.
  ///
  /// If more then [threshold] attempts occur, throws [WillNeverStabilizeError].
  Future<void> stabilize({
    void Function() runAndTrackSideEffects,
    int threshold = 100,
  }) async {
    if (threshold == null) {
      throw ArgumentError.notNull('threshold');
    }
    if (runAndTrackSideEffects != null) {
      await update(runAndTrackSideEffects);
    }
    return stabilizeWithThreshold(threshold);
  }

  /// Run [update] until the stabilizer is stable or threshold exceeds.
  ///
  /// **NOTE:** `[update] is guaranteed to run at least once.
  @protected
  Future<void> stabilizeWithThreshold(int threshold) async {
    if (threshold < 1) {
      throw ArgumentError.value(threshold, 'threshold', 'Must be >= 1');
    }

    var count = 0;
    bool thresholdExceeded() => count++ > threshold;

    // ... and once update says there is no more work to do, we will bail out.
    while (!await update()) {
      if (thresholdExceeded()) {
        throw WillNeverStabilizeError(threshold);
      }
    }
  }
}

@visibleForTesting
class DelegatingNgTestStabilizer extends NgTestStabilizer {
  final List<NgTestStabilizer> _delegates;

  bool _updatedAtLeastOnce = false;

  DelegatingNgTestStabilizer(Iterable<NgTestStabilizer> stabilizers)
      : _delegates = stabilizers.toList(growable: false);

  @override
  bool get isStable => _delegates.every((delegate) => delegate.isStable);

  @override
  Future<bool> update([void Function() runAndTrackSideEffects]) async {
    if (_delegates.isEmpty) {
      return false;
    }

    if (runAndTrackSideEffects == null && _updatedAtLeastOnce) {
      // Only run the "update" function if the delegate is not stable.
      //
      // When a delegate is stable, call the "update" function may cause other
      // delegates to never stabilize. For example, calling "update" on the
      // NgZoneStabilizer will trigger an NgZone's "onEventDone" event. Another
      // service that listens on this event may trigger other events.
      await _updateAll(runAndTrackSideEffects, (d) => !d.isStable);
    } else {
      await _updateAll(runAndTrackSideEffects);
    }

    _updatedAtLeastOnce = true;
    return isStable;
  }

  /// Runs [update] where [test] is satisfied.
  Future<void> _updateAll(
    void Function() runAndTrackSideEffects, [
    bool Function(NgTestStabilizer) test,
  ]) async {
    for (final delegate in _delegates) {
      if (test == null || test(delegate)) {
        await delegate.update(runAndTrackSideEffects);
      }
    }
  }

  @override
  Future<void> stabilizeWithThreshold(int threshold) async {
    try {
      _updatedAtLeastOnce = false;
      return super.stabilizeWithThreshold(threshold);
    } finally {
      _updatedAtLeastOnce = false;
    }
  }
}

/// A wrapper API that reports stability based on the Angular [NgZone].
class NgZoneStabilizer extends NgTestStabilizer {
  final NgZone _ngZone;

  const NgZoneStabilizer(this._ngZone);

  /// Zone is considered stable when there are no more micro-tasks or timers.
  @override
  bool get isStable {
    return !(_ngZone.hasPendingMacrotasks || _ngZone.hasPendingMicrotasks);
  }

  @override
  Future<bool> update([void Function() fn]) {
    return Future.sync(() => _waitForZone(fn)).then((_) => isStable);
  }

  Future<void> _waitForZone([void fn()]) async {
    // If we haven't supplied anything, at least run a simple function w/ task.
    // This gives enough "work" to do where we can catch an error or stability.
    scheduleMicrotask(() {
      _ngZone.runGuarded(fn ?? () => scheduleMicrotask(() {}));
    });

    var ngZoneErrorFuture = _ngZone.onError.first;
    await _waitForFutureOrFailOnNgZoneError(
        _ngZone.onTurnDone.first, ngZoneErrorFuture);

    var longestPendingTimerDuration = longestPendingTimer(_ngZone);
    if (longestPendingTimerDuration != Duration.zero) {
      await _waitForFutureOrFailOnNgZoneError(
          Future.delayed(longestPendingTimerDuration), ngZoneErrorFuture);
    }
  }

  Future<void> _waitForFutureOrFailOnNgZoneError(
      Future future, Future<NgZoneError> ngZoneErrorFuture) async {
    // Stop executing as soon as either [future] or an error occurs.
    NgZoneError caughtError;
    var finishedWithoutError = false;
    await Future.any([
      future,
      ngZoneErrorFuture.then((e) {
        if (!finishedWithoutError) {
          caughtError = e;
        }
      })
    ]);

    // Give a bit of time to catch up, we could still have an occur in future.
    await Future(() {});

    // Fail if we caught an error.
    if (caughtError != null) {
      return Future.error(
        caughtError.error,
        StackTrace.fromString(caughtError.stackTrace.join('\n')),
      );
    }

    // Mark finish.
    finishedWithoutError = true;
  }

  @override
  String toString() => '$NgZoneStabilizer {isStable: $isStable}';
}
