import 'dart:async';

/// Creates a context for capturing timer instances.
class TimerHookZone {
  late final Zone _timerZone = Zone.current.fork(
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

  /// Lazily set by stabilizers that need access to intercept timer creation.
  /// ignore: prefer_function_declarations_over_variables
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
  /// ignore: prefer_function_declarations_over_variables
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
