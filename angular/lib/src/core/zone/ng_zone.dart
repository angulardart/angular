import 'dart:async';

import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:angular/src/facade/exception_handler.dart';
import 'package:angular/src/runtime.dart';

/// **INTERNAL**: Creates [NgZone] with asynchronous stack traces enabled.
NgZone debugAsyncStackTracesNgZone() => NgZone._debugAsyncStackTraces();

/// Handles and observes the side-effects of executing callbacks in AngularDart.
///
/// _Most_ applications will not need to access or use this class. It _may_ be
/// used in order to get hooks into the application lifecycle or for hiding
/// asynchronous actions from AngularDart that occur frequently (such as mouse
/// movement, or a polling timer) and have a costly impact on change detection.
class NgZone {
  /// Private object used to specify whether any [NgZone] is currently running.
  static final _anyZoneKey = Object();

  /// Private object used to specify whether [NgZone] exists in this [NgZone].
  final _thisZoneKey = Object();

  /// Returns whether an instance of [NgZone] is currently executing.
  ///
  /// If `true`, the side-effects of executing callbacks are being observed,
  /// though not necessarily by the current application's [NgZone] in the case
  /// of multiple applications running at the same time.
  ///
  /// It is highly preferred to use [inInnerZone] and [inOuterZone] instead.
  ///
  /// See the [Zone] documentation for details:
  /// https://www.dartlang.org/articles/libraries/zones
  static bool isInAngularZone() {
    return identical(Zone.current[_anyZoneKey], true);
  }

  /// In development mode, throws an error if [isInAngularZone] returns `false`.
  ///
  /// It is highly preferred to use `assert(ngZone.inInnerZone)` instead.
  static void assertInAngularZone() {
    if (!isInAngularZone()) {
      throw Exception("Expected to be in Angular Zone, but it is not!");
    }
  }

  /// In development mode, throws an error if [isInAngularZone] returns `true`.
  ///
  /// It is highly preferred to use `assert(ngZone.inOuterZone)` instead.
  static void assertNotInAngularZone() {
    if (isInAngularZone()) {
      throw Exception("Expected to not be in Angular Zone, but it is!");
    }
  }

  final _onTurnStart = StreamController<void>.broadcast(sync: true);
  final _onMicrotaskEmpty = StreamController<void>.broadcast(sync: true);
  final _onTurnDone = StreamController<void>.broadcast(sync: true);
  final _onError = StreamController<NgZoneError>.broadcast(sync: true);

  Zone _outerZone;
  Zone _innerZone;
  bool _hasPendingMicrotasks = false;
  bool _hasPendingMacrotasks = false;
  bool _isStable = true;
  int _nesting = 0;
  bool _isRunning = false;
  bool _disposed = false;

  // Number of microtasks pending from _innerZone (& descendants)
  int _pendingMicrotasks = 0;
  final _pendingTimers = <_WrappedTimer>[];

  factory NgZone() => isDevMode && debugAsyncStackTraces
      ? NgZone._debugAsyncStackTraces()
      : NgZone._();

  NgZone._() {
    _outerZone = Zone.current;
    _innerZone = _createInnerZone(
      Zone.current,
      handleUncaughtError: _onErrorWithoutLongStackTrace,
    );
  }

  NgZone._debugAsyncStackTraces() {
    _outerZone = Zone.current;
    _innerZone = Chain.capture(
      () => _createInnerZone(Zone.current),
      onError: _onErrorWithLongStackTrace,
    );
  }

  /// Whether we are currently executing within this AngularDart zone.
  ///
  /// If `true`, the side-effects of executing callbacks are being observed.
  bool get inInnerZone => Zone.current == _innerZone;

  /// Whether we are currently executing outside of the AngularDart zone.
  ///
  /// If `true`, the side-effects of executing callbacks are not being observed.
  bool get inOuterZone => Zone.current == _outerZone;

  Zone _createInnerZone(Zone zone,
      {void handleUncaughtError(
          Zone _, ZoneDelegate __, Zone ___, Object ____, StackTrace s)}) {
    return zone.fork(
      specification: ZoneSpecification(
        scheduleMicrotask: _scheduleMicrotask,
        run: _run,
        runUnary: _runUnary,
        runBinary: _runBinary,
        handleUncaughtError: handleUncaughtError,
        createTimer: _createTimer,
      ),
      zoneValues: {_thisZoneKey: true, _anyZoneKey: true},
    );
  }

  void _scheduleMicrotask(
      Zone self, ZoneDelegate parent, Zone zone, void fn()) {
    if (_pendingMicrotasks == 0) {
      _setMicrotask(true);
    }
    _pendingMicrotasks++;
    // TODO: optimize using a pool.
    var safeMicrotask = () {
      try {
        fn();
      } finally {
        _pendingMicrotasks--;
        if (_pendingMicrotasks == 0) {
          _setMicrotask(false);
        }
      }
    };
    parent.scheduleMicrotask(zone, safeMicrotask);
  }

  R _run<R>(Zone self, ZoneDelegate parent, Zone zone, R fn()) {
    return parent.run(zone, () {
      try {
        _onEnter();
        return fn();
      } finally {
        _onLeave();
      }
    });
  }

  R _runUnary<R, T>(
      Zone self, ZoneDelegate parent, Zone zone, R fn(T arg), T arg) {
    return parent.runUnary(zone, (T arg) {
      try {
        _onEnter();
        return fn(arg);
      } finally {
        _onLeave();
      }
    }, arg);
  }

  R _runBinary<R, T1, T2>(Zone self, ZoneDelegate parent, Zone zone,
      R fn(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
    return parent.runBinary(zone, (T1 arg1, T2 arg2) {
      try {
        _onEnter();
        return fn(arg1, arg2);
      } finally {
        _onLeave();
      }
    }, arg1, arg2);
  }

  void _onEnter() {
    _nesting++;
    if (_isStable) {
      _isStable = false;
      _isRunning = true;
      _onTurnStart.add(null);
    }
  }

  void _onLeave() {
    _nesting--;
    _checkStable();
  }

  // Called by Chain.capture() on errors when long stack traces are enabled
  void _onErrorWithLongStackTrace(error, Chain chain) {
    final traces = chain.terse.traces.map((t) => t.toString()).toList();
    _onError.add(NgZoneError(error, traces));
  }

  // Outer zone handleUnchaughtError when long stack traces are not used
  void _onErrorWithoutLongStackTrace(
      Zone self, ZoneDelegate parent, Zone zone, error, StackTrace trace) {
    _onError.add(NgZoneError(error, [trace.toString()]));
  }

  Timer _createTimer(
    Zone self,
    ZoneDelegate parent,
    Zone zone,
    Duration duration,
    void Function() fn,
  ) {
    _WrappedTimer wrappedTimer;
    final onDone = () {
      _pendingTimers.remove(wrappedTimer);
      _setMacrotask(_pendingTimers.isNotEmpty);
    };
    final callback = () {
      try {
        fn();
      } finally {
        onDone();
      }
    };
    Timer timer = parent.createTimer(zone, duration, callback);
    wrappedTimer = _WrappedTimer(timer, duration, onDone);
    _pendingTimers.add(wrappedTimer);
    _setMacrotask(true);
    return wrappedTimer;
  }

  /// **INTERNAL ONLY**: See [longestPendingTimer].
  Duration get _longestPendingTimer {
    var duration = Duration.zero;
    for (final timer in _pendingTimers) {
      if (timer._duration > duration) {
        duration = timer._duration;
      }
    }
    return duration;
  }

  void _setMicrotask(bool hasMicrotasks) {
    _hasPendingMicrotasks = hasMicrotasks;
    _checkStable();
  }

  void _setMacrotask(bool hasMacrotasks) {
    _hasPendingMacrotasks = hasMacrotasks;
  }

  void _checkStable() {
    if (_nesting == 0) {
      if (!_hasPendingMicrotasks && !_isStable) {
        try {
          _nesting++;
          _isRunning = false;
          if (!_disposed) _onMicrotaskEmpty.add(null);
        } finally {
          _nesting--;
          if (!_hasPendingMicrotasks) {
            try {
              runOutsideAngular(() {
                if (!_disposed) {
                  _onTurnDone.add(null);
                }
              });
            } finally {
              _isStable = true;
            }
          }
        }
      }
    }
  }

  /// Whether there are any outstanding microtasks.
  ///
  /// If `true`, one or more `scheduleMicrotask(...)` calls (or similar) that
  /// were started while [inInnerZone] is `true` have yet to be completed.
  ///
  /// Most users should not need or use this value.
  bool get hasPendingMicrotasks => _hasPendingMicrotasks;

  /// Whether there are any outstanding microtasks.
  ///
  /// If `true`, one or more `Timer.run(...)` calls (or similar) that
  /// were started while [inInnerZone] is `true` have yet to be completed.
  ///
  /// Most users should not need or use this value.
  bool get hasPendingMacrotasks => _hasPendingMacrotasks;

  /// Executes and returns [callback] function synchronously within this zone.
  ///
  /// Typically, this API should _only_ be used when [inOuterZone] is `true`,
  /// e.g. a frequent event such as a polling timer or mouse movement is being
  /// observed via [runOutsideAngular] for performance reasons.
  ///
  /// Future tasks or microtasks scheduled from within the [callback] will
  /// continue executing from within this zone.
  ///
  /// **NOTE**: If a _synchronous_ error happens it will be rethrown, and not
  /// reported via the [onError] stream. To opt-in to that behavior, use
  /// [runGuarded].
  R run<R>(R Function() callback) {
    return _innerZone.run(callback);
  }

  /// Executes [callback] function synchronously within this zone.
  ///
  /// This API is identical to [run], except that _synchronous_ errors that are
  /// thrown will _also_ be reported via the [onError] stream (and eventually
  /// the application exception handler).
  void runGuarded(void Function() callback) {
    return _innerZone.runGuarded(callback);
  }

  /// Executes and returns [callback] function synchronously outside this zone.
  ///
  /// Typically, this API should be used when a high-frequency event such as
  /// a polling timer or mouse movement is being observed within [callback],
  /// and for performance reasons you want to only react _sometimes_:
  /// ```
  /// // Just an example, not ideal!
  /// void example(NgZone zone) {
  ///   zone.runOutsideAngular(() {
  ///     Timer(Duration.zero, () {
  ///       if (someOtherValue) {
  ///         zone.run(() => computeSomething());
  ///       }
  ///     });
  ///   });
  /// }
  /// ```
  R runOutsideAngular<R>(R Function() callback) {
    return _outerZone.run(callback);
  }

  /// Whether [onTurnStart] has been triggered and [onTurnDone] has not.
  bool get isRunning => _isRunning;

  /// Notifies that an error has been caught.
  ///
  /// This is the callback hook used by exception handling behind the scenes.
  Stream<NgZoneError> get onError => _onError.stream;

  /// Notifies when there are no more microtasks enqueued within this zone.
  ///
  /// This is normally used as a hint for AngularDart to perform change
  /// detection, which in turn may enqueue additional microtasks; this event
  /// may fire multiple times before [onTurnDone] occurs.
  Stream<void> get onMicrotaskEmpty => _onMicrotaskEmpty.stream;

  /// Notifies when there are no more microtasks enqueued within this zone.
  ///
  /// **NOTE**: This is currently an alias for [onMicrotaskEmpty].
  Stream<void> get onEventDone => _onMicrotaskEmpty.stream;

  /// Notifies when an initial callback is executed within this zone.
  ///
  /// At this point in the execution AngularDart will start recording pending
  /// microtasks and some macrotasks (such as timers), and fire any number of
  /// [onMicrotaskEmpty] events until [onTurnDone].
  ///
  /// **WARNING**: Causing an asynchronous task while listening to this stream
  /// will cause an infinite loop, as the zone constantly starts and ends
  /// indefinitely.
  Stream<void> get onTurnStart => _onTurnStart.stream;

  /// Notifies when a final callback is executed within this zone.
  ///
  /// At this point in the execution, future tasks are being executed within the
  /// parent (outer) zone, until another event occurs within the zone, which in
  /// turn will start [onTurnStart] again.
  ///
  /// **WARNING**: Causing an asynchronous task while listening to this stream
  /// will cause an infinite loop, as the zone constantly starts and ends
  /// indefinitely.
  Stream<void> get onTurnDone => _onTurnDone.stream;

  /// Executes a callback after changes were observed by the zone.
  ///
  /// Instead of adding arbitrary `Timer.run` and `scheduleMicrotask` calls to
  /// user-code to try and simulate this event, instead `await` directly from
  /// the `NgZone`:
  ///
  /// ```
  /// void example(NgZone zone) async {
  ///   someValue = true;
  ///   zone.runAfterChangesObserved(() {
  ///     doSomethingDependentOnSomeValueChanging();
  ///   });
  /// }
  /// ```
  void runAfterChangesObserved(void Function() callback) {
    if (isRunning) {
      onTurnDone.first.whenComplete(() => scheduleMicrotask(callback));
    } else {
      scheduleMicrotask(callback);
    }
  }

  /// Disables additional collection of asynchronous tasks.
  ///
  /// This effectively permanently shuts down the events of this instance. Most
  /// applications will not need to invoke this, it is used internally in cases
  /// such as tests.
  void dispose() {
    _disposed = true;
  }
}

/// For a [zone], returns the [Duration] of the longest pending timer.
///
/// If no timers are scheduled this will always return [Duration.zero].
///
/// **INTERNAL ONLY**: This is an experimental API subject to change.
@experimental
Duration longestPendingTimer(NgZone zone) => zone._longestPendingTimer;

/// For a [zone], returns whether there are pending timers yet to execute.
///
/// **INTERNAL ONLY**: This is an experimental API subject to change.
@experimental
bool hasPendingMacrotasks(NgZone zone) => zone._hasPendingMacrotasks;

/// For a [zone], returns whether it is within AngularDart [ngZone].
///
/// **INTERNAL ONLY**: This is an experimental API subject to change.
@experimental
bool inAngularZone(NgZone ngZone, Zone zone) {
  return identical(zone[ngZone._thisZoneKey], true);
}

/// A `Timer` wrapper that lets you specify additional functions to call when it
/// is cancelled.
class _WrappedTimer implements Timer {
  final Timer _timer;
  final Duration _duration;
  final void Function() _onCancel;

  _WrappedTimer(this._timer, this._duration, this._onCancel);

  void cancel() {
    _onCancel();
    _timer.cancel();
  }

  bool get isActive => _timer.isActive;

  @override
  int get tick => _timer.tick;
}

/// Stores error information; delivered via [NgZone.onError] stream.
class NgZoneError {
  /// Error object thrown.
  final error;

  /// Either a single or multiple stack traces.
  ///
  /// For legacy reasons, this is not typed `List<StackTrace>` or `StackTrace`
  /// at this time. It may be possible to change the typing at a later point.
  final List<Object> stackTrace;

  NgZoneError(this.error, this.stackTrace);
}
