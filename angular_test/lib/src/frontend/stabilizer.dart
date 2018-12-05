// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:angular/di.dart';

import '../errors.dart';
import 'ng_zone/timer_hook_zone.dart';

/// Creates a [NgTestStabilizer], optionally from an [Injector].
typedef NgTestStabilizerFactory = NgTestStabilizer Function(Injector);

/// A variant of an [NgTestStabilizerFactory] with access to [TimerHookZone].
///
/// In the future we can consider opening up visibility, but for now we should
/// ensure that only our own stabilizers have access to this specific zone hook.
typedef AllowTimerHookZoneAccess = NgTestStabilizer Function(
  Injector, [
  TimerHookZone,
]);

/// Returns a composed sequence of [factories] as a single stabilizer.
NgTestStabilizerFactory composeStabilizers(
  Iterable<NgTestStabilizerFactory> factories,
) {
  return (Injector injector, [TimerHookZone zone]) {
    return _DelegatingNgTestStabilizer(factories.map((f) {
      // Most (i.e. all user-land) stabilizers do not have access to the
      // "secret" TimerHookZone. Only functions that are defined within this
      // package may have them, so we pass the zone to those functions only.
      if (f is AllowTimerHookZoneAccess) {
        return f(injector, zone);
      }
      // All other factories just are given an injector.
      if (f is NgTestStabilizerFactory) {
        return f(injector);
      }
      // Base case.
      throw ArgumentError('Invalid stabilizer factory: $f');
    }));
  };
}

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
  static const NgTestStabilizer alwaysStable = _AlwaysStableNgTestStabilizer();

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

class _AlwaysStableNgTestStabilizer extends NgTestStabilizer {
  const _AlwaysStableNgTestStabilizer();

  @override
  bool get isStable => true;
}

class _DelegatingNgTestStabilizer extends NgTestStabilizer {
  final List<NgTestStabilizer> _delegates;

  bool _updatedAtLeastOnce = false;

  _DelegatingNgTestStabilizer(Iterable<NgTestStabilizer> stabilizers)
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
