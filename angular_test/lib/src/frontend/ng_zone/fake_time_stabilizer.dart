import 'dart:async';

import 'package:angular/angular.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

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
  static const defaultMaxIterations = 10;

  /// Creates a new stabilizer which uses a combination of zones.
  ///
  /// Optionally, specify the [maxIterations] that will be attempted to elapse
  /// all pending timers before giving up and throwing "will never complete". In
  /// most cases, the default value [defaultMaxIterations] is appropriate but it
  /// may be increased in code that has heavy usage of repetitive timers.
  factory FakeTimeNgZoneStabilizer(
    TimerHookZone timerZone,
    NgZone ngZone, {
    int maxIterations,
  }) {
    // All non-periodic timers that have been started, but not completed.
    final pendingTimers = PriorityQueue<_FakeTimer>();

    // The parent zone that adds hooks around every non-periodic timer.
    FakeTimeNgZoneStabilizer stabilizer;

    timerZone.createTimer = (self, parent, zone, duration, callback) {
      _FakeTimer instance;
      instance = _FakeTimer(
        (_) => zone.run(callback),
        pendingTimers.remove,
        duration,
        stabilizer._lastElapse + duration,
        isPeriodic: false,
      );
      pendingTimers.add(instance);
      return instance;
    };

    timerZone.createPeriodicTimer = (self, parent, zone, duration, callback) {
      _FakeTimer instance;
      instance = _FakeTimer(
        (timer) => zone.run(() => callback(timer)),
        pendingTimers.remove,
        duration,
        stabilizer._lastElapse + duration,
        isPeriodic: true,
      );
      pendingTimers.add(instance);
      return instance;
    };

    return stabilizer = FakeTimeNgZoneStabilizer._(
      ngZone,
      pendingTimers,
      maxIterations: maxIterations,
    );
  }

  /// Maximum stabilization attempts before throwing "will never complete".
  final int _maxIterations;

  FakeTimeNgZoneStabilizer._(
    NgZone ngZone,
    PriorityQueue<_FakeTimer> pendingTimers, {
    int maxIterations,
  })  : _maxIterations = maxIterations ?? defaultMaxIterations,
        super(ngZone, pendingTimers);

  /// The amount of time since construction that [elapse] has executed on.
  var _lastElapse = Duration.zero;

  /// Forces elapsing all timers that are less than or equal to duration [time].
  ///
  /// After each timers is elapsed, this implicitly calls [update], awaiting any
  /// pending microtasks, and returns a future that completes when both all
  /// timers and microtasks are completed.
  ///
  /// May throw [TimersWillNotCompleteError].
  Future<void> elapse(Duration time) async {
    final waitUntil = _lastElapse + time;
    await _completeTimers((t) => t._completeAfter <= waitUntil);
    _lastElapse = waitUntil;
  }

  /// Completes all the times that [shouldComplete] in time order and update
  /// [_lastElapse] with each timer completes.
  Future<void> _completeTimers(bool Function(_FakeTimer) shouldComplete) async {
    // We need to execute seemingly indefinitely until enough time is elapsed.
    var totalIterations = 0;
    while (pendingTimers.isNotEmpty) {
      // We want to find the shortest duration timer.
      final run = pendingTimers.first;
      if (!shouldComplete(run)) {
        break;
      }

      if (++totalIterations > _maxIterations) {
        final willNeverComplete = pendingTimers.toList().where(shouldComplete);
        throw TimersWillNotCompleteError._(
          _maxIterations,
          willNeverComplete.toList(),
        );
      }

      _lastElapse = run._completeAfter;
      await update(() => run.complete(pendingTimers.add));
    }
  }
}

class TimersWillNotCompleteError extends Error {
  final int _maxIterations;
  final List<_FakeTimer> _timers;

  TimersWillNotCompleteError._(this._maxIterations, this._timers);

  @override
  String toString() => (StringBuffer('Could not complete timers!')
        ..write('Tried $_maxIterations times to elapse timers')
        ..writeln(', but everytime more were scheduled.')
        ..writeln('The following timers are pending:')
        ..writeAll(_timers, '\n')
        ..write('Check your code carefully and/or increase maxIterations only ')
        ..writeln('when timers are being continously scheduled by design.'))
      .toString();
}

/// A simplified fake timer that does not wrap an actual timer.
class _FakeTimer implements Timer, Comparable<_FakeTimer> {
  final void Function(_FakeTimer) _complete;
  final void Function(_FakeTimer) _clearPendingStatus;
  final bool isPeriodic;
  final Duration _scheduledDuration;

  // Mutable for periodic timers.
  Duration _completeAfter;

  _FakeTimer(
    this._complete,
    this._clearPendingStatus,
    this._scheduledDuration,
    this._completeAfter, {
    @required this.isPeriodic,
  });

  bool _isActive = true;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => 0;

  @override
  void cancel() {
    if (_isActive) {
      _clearPendingStatus(this);
      _isActive = false;
    }
  }

  void complete(void Function(_FakeTimer) onPeriodic) {
    assert(_isActive, 'An inactive timer should not be accessible to complete');

    // In case the complete crashes, we still want to clear the state.
    _clearPendingStatus(this);

    // Now complete.
    _complete(this);

    if (isPeriodic) {
      // For periodic timers, we've cancelled this one and schedule a new one.
      _completeAfter = _completeAfter + _scheduledDuration;

      // Trigger this timer being removed and added to the pendingTimers queue.
      _clearPendingStatus(this);
      onPeriodic(this);
    } else {
      _isActive = false;
    }
  }

  @override
  int compareTo(_FakeTimer b) => _completeAfter.compareTo(b._completeAfter);

  @override
  String toString() {
    if (isPeriodic) {
      return '$hashCode: Periodic: $_scheduledDuration -> $_completeAfter';
    } else {
      return '$hashCode: One-Off: $_scheduledDuration -> $_completeAfter';
    }
  }
}
