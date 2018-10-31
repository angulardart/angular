import 'dart:async';

/// A wrapper interface around a [Timer] that allows test access to internals.
class InterceptedTimer implements Timer {
  /// Creates and returns a new [InterceptedTimer] instance.
  ///
  /// This API is meant to match [CreateTimerHandler].
  static InterceptedTimer createTimer(
    Zone self,
    ZoneDelegate parent,
    Zone zone,
    Duration duration,
    void Function() callback,
  ) {
    final timer = parent.createTimer(
      zone,
      duration,
      self.bindCallback(callback),
    );
    return InterceptedTimer._(timer, duration, callback);
  }

  final Timer _delegate;
  final void Function() _callback;

  /// Duration assigned to the timer when originally created.
  final Duration duration;

  InterceptedTimer._(
    this._delegate,
    this.duration,
    this._callback,
  );

  /// Forces the completion of this timer if it is currently active.
  ///
  /// This is equivalent to running the bound callback and cancelling the timer.
  void complete() {
    cancel();
    _callback();
  }

  @override
  void cancel() => _delegate.cancel();

  @override
  int get tick => _delegate.tick;

  @override
  bool get isActive => _delegate.isActive;
}
