import 'dart:async';

/// Creates a context for capturing timer instances.
class TimerHookZone {
  Zone _timerZone;

  TimerHookZone() {
    _timerZone = Zone.current.fork(
      specification: ZoneSpecification(createTimer: (
        self,
        parent,
        zone,
        duration,
        callback,
      ) {
        // Intentionally not bound directly to allow indirect/lazy assignment.
        return createTimer(self, parent, zone, duration, callback);
      }, createPeriodicTimer: (
        self,
        parent,
        zone,
        duration,
        callback,
      ) {
        // Intentionally not bound directly to allow indirect/lazy assignment.
        return createPeriodicTimer(self, parent, zone, duration, callback);
      }),
    );
  }

  /// Lazily set by stabilizers that need access to intercept timer creation.
  CreateTimerHandler createTimer = (
    self,
    parent,
    zone,
    duration,
    callback,
  ) {
    return parent.createTimer(zone, duration, callback);
  };

  /// Lazily set by stabilizers that need access to intercept timer creation.
  CreatePeriodicTimerHandler createPeriodicTimer = (
    self,
    parent,
    zone,
    duration,
    callback,
  ) {
    return parent.createPeriodicTimer(zone, duration, callback);
  };

  /// Runs and returns [context], capturing the timers.
  T run<T>(T Function() context) => _timerZone.run(context);
}
