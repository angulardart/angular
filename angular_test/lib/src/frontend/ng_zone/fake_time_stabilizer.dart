import 'dart:async';

import 'package:angular/angular.dart';

import 'base_stabilizer.dart';
import 'timer_hook_zone.dart';

/// Observes [NgZone], a custom parent zone, and custom hooks to stabilize.
///
/// * Any microtasks are automatically waited for stability in [update].
/// * Any timers need to be manually elapsed using the [elapse] hook.
///
/// This stabilizer is a good choice for tests that need to assert transitional
/// state (i.e. "idle", "loading", "loaded"), custom animations that use [Timer]
/// or [Future.delayed]. The vast majority of tests are better off using the
/// default ([RealTimeNgZoneStabilizer]) stabilizer.
///
/// **NOTE**: _Periodic_ timers are not supported by this stabilizer.
class FakeTimeNgZoneStabilizer extends BaseNgZoneStabilizer<_FakeTimer> {
  /// Creates a new stabilizer which uses a combination of zones.
  factory FakeTimeNgZoneStabilizer(TimerHookZone timerZone, NgZone ngZone) {
    // All non-periodic timers that have been started, but not completed.
    final pendingTimers = Set<_FakeTimer>.identity();
    // The parent zone that adds hooks around every non-periodic timer.
    FakeTimeNgZoneStabilizer stabilizer;
    timerZone.createTimer = (self, parent, zone, duration, callback) {
      _FakeTimer instance;
      void removeTimer() {
        pendingTimers.remove(instance);
      }

      final wrappedCallback = () {
        try {
          callback();
        } finally {
          removeTimer();
        }
      };
      instance = _FakeTimer(zone.bindCallback(wrappedCallback), removeTimer,
          stabilizer._lastElapse + duration);
      pendingTimers.add(instance);
    };
    return stabilizer = FakeTimeNgZoneStabilizer._(
      ngZone,
      pendingTimers,
    );
  }

  FakeTimeNgZoneStabilizer._(
    NgZone ngZone,
    Set<_FakeTimer> pendingTimers,
  ) : super(ngZone, pendingTimers);

  /// The amount of time since construction that [elapse] has executed on.
  var _lastElapse = Duration.zero;

  /// Forces elapsing all timers that are less than or equal to duration [time].
  ///
  /// After each timers is elapsed, this implicitly calls [update], awaiting any
  /// pending microtasks, and returns a future that completes when both all
  /// timers and microtasks are completed.
  Future<void> elapse(Duration time) async {
    final waitUntil = _lastElapse + time;
    await _completeTimers((t) => t._completeAfter <= waitUntil);
    _lastElapse = waitUntil;
  }

  Future<void> _completeTimers(bool Function(_FakeTimer) shouldComplete) async {
    var toComplete = pendingTimers.where(shouldComplete).toList();
    do {
      for (final pendingTimer in toComplete) {
        await update(pendingTimer.complete);
      }
      toComplete = pendingTimers.where(shouldComplete).toList();
    } while (toComplete.isNotEmpty);
  }
}

/// A simplified fake timer that does not wrap an actual timer.
class _FakeTimer implements Timer {
  final void Function() _complete;
  final void Function() _clearPendingStatus;
  final Duration _completeAfter;

  _FakeTimer(this._complete, this._clearPendingStatus, this._completeAfter);

  @override
  var isActive = true;

  @override
  int get tick => 0;

  @override
  void cancel() {
    if (isActive) {
      _clearPendingStatus();
      isActive = false;
    }
  }

  void complete() {
    if (isActive) {
      _complete();
      cancel();
    }
  }
}
