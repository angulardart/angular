import 'dart:async';

import 'package:angular/angular.dart';
import 'package:meta/meta.dart';

import 'base_stabilizer.dart';

/// Observes [NgZone] and custom parent zone to stabilize.
///
/// * Any microtasks are automatically waited for stability in [update].
/// * Any timers are automatically waited for stability in [update].
///
/// This stabilizer is a good choice for most tests.
///
/// **NOTE**: _Periodic_ timers are not supported by this stabilizer.
class RealTimeNgZoneStabilizer extends BaseNgZoneStabilizer<_ObservedTimer> {
  /// Creates a new stabilizer which manages a custom zone around an [NgZone].
  ///
  /// Expects a provided [createNgZone] callback, which will ensure the zone
  /// is created _within_ the parent zone owned by [RealTimeNgZoneStabilizer],
  /// and waits an appropriate amount of real execution time for the test to
  /// stabilize.
  factory RealTimeNgZoneStabilizer(NgZone Function() createNgZone) {
    // All non-periodic timers that have been started, but not completed.
    final pendingTimers = Set<_ObservedTimer>.identity();
    final timerZone = Zone.current.fork(
      specification: ZoneSpecification(createTimer: (
        self,
        parent,
        zone,
        duration,
        callback,
      ) {
        _ObservedTimer instance;
        final wrappedCallback = () {
          try {
            callback();
          } finally {
            pendingTimers.remove(instance);
          }
        };
        final delegate = parent.createTimer(
          zone,
          duration,
          wrappedCallback,
        );
        instance = _ObservedTimer(delegate, duration);
        pendingTimers.add(instance);
        return instance;
      }),
    );
    return RealTimeNgZoneStabilizer._(
      timerZone.run(createNgZone),
      pendingTimers,
    );
  }

  RealTimeNgZoneStabilizer._(
    NgZone ngZone,
    Set<_ObservedTimer> pendingTimers,
  ) : super(ngZone, pendingTimers);

  @override
  bool get isStable => super.isStable && pendingTimers.isEmpty;

  @protected
  Future<void> waitForAsyncEvents() {
    if (pendingTimers.isEmpty) {
      return super.waitForAsyncEvents();
    }
    return Future.delayed(_minimumDurationForAllPendingTimers());
  }

  Duration _minimumDurationForAllPendingTimers() {
    var result = Duration.zero;
    for (final timer in pendingTimers) {
      if (timer._duration > result) {
        result = timer._duration;
      }
    }
    return result;
  }
}

/// A wrapper interface around a [Timer] that tracks how long it will take.
class _ObservedTimer implements Timer {
  /// Underlying (live) timer implementation.
  final Timer _delegate;

  /// Scheduled duration.
  final Duration _duration;

  const _ObservedTimer(this._delegate, this._duration);

  @override
  void cancel() => _delegate.cancel();

  @override
  int get tick => _delegate.tick;

  @override
  bool get isActive => _delegate.isActive;
}
