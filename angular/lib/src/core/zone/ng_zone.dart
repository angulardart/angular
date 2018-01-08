import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

// TODO: add/fix links to:
// - docs explaining zones and the use of zones in Angular and
// - change-detection link to runOutsideAngular/run (throughout this file!)

/// An injectable service for executing work inside or outside of the
/// Angular zone.
///
/// The most common use of this service is to optimize performance when starting
/// a work consisting of one or more asynchronous tasks that don't require UI
/// updates or error handling to be handled by Angular. Such tasks can be
/// kicked off via [#runOutsideAngular] and if needed, these tasks
/// can reenter the Angular zone via [#run].
///
/// ## Example
///
/// <?code-excerpt "core/ngzone/lib/app_component.dart"?>
/// ```dart
/// import 'dart:async';
///
/// import 'package:angular/angular.dart';
///
/// @Component(
///     selector: 'my-app',
///     template: '''
///       <h1>Demo: NgZone</h1>
///       <p>
///         Progress: {{progress}}%<br>
///         <span *ngIf="progress >= 100">Done processing {{label}} of Angular zone!</span>
///         &nbsp;
///       </p>
///       <button (click)="processWithinAngularZone()">Process within Angular zone</button>
///       <button (click)="processOutsideOfAngularZone()">Process outside of Angular zone</button>
///     ''')
/// class AppComponent {
///   int progress = 0;
///   String label;
///   final NgZone _ngZone;
///
///   AppComponent(this._ngZone);
///
///   // Loop inside the Angular zone
///   // so the UI DOES refresh after each setTimeout cycle
///   void processWithinAngularZone() {
///     label = 'inside';
///     progress = 0;
///     _increaseProgress(() => print('Inside Done!'));
///   }
///
///   // Loop outside of the Angular zone
///   // so the UI DOES NOT refresh after each setTimeout cycle
///   void processOutsideOfAngularZone() {
///     label = 'outside';
///     progress = 0;
///     _ngZone.runOutsideAngular(() {
///       _increaseProgress(() {
///         // reenter the Angular zone and display done
///         _ngZone.run(() => print('Outside Done!'));
///       });
///     });
///   }
///
///   void _increaseProgress(void doneCallback()) {
///     progress += 1;
///     print('Current progress: $progress%');
///     if (progress < 100) {
///       new Future<Null>.delayed(const Duration(milliseconds: 10),
///           () => _increaseProgress(doneCallback));
///     } else {
///       doneCallback();
///     }
///   }
/// }
/// ```
class NgZone {
  static bool isInAngularZone() {
    return Zone.current['isAngularZone'] == true;
  }

  static void assertInAngularZone() {
    if (!isInAngularZone()) {
      throw new Exception("Expected to be in Angular Zone, but it is not!");
    }
  }

  static void assertNotInAngularZone() {
    if (isInAngularZone()) {
      throw new Exception("Expected to not be in Angular Zone, but it is!");
    }
  }

  final StreamController<Null> _onTurnStart =
      new StreamController.broadcast(sync: true);
  final StreamController<Null> _onMicrotaskEmpty =
      new StreamController.broadcast(sync: true);
  final StreamController<Null> _onTurnDone =
      new StreamController.broadcast(sync: true);
  final StreamController<NgZoneError> _onError =
      new StreamController<NgZoneError>.broadcast(sync: true);

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
  final List<Timer> _pendingTimers = <Timer>[];

  /// enabled in development mode as they significantly impact perf.
  NgZone({enableLongStackTrace: false}) {
    _outerZone = Zone.current;

    if (enableLongStackTrace) {
      _innerZone = Chain.capture(() => _createInnerZone(Zone.current),
          onError: _onErrorWithLongStackTrace);
    } else {
      _innerZone = _createInnerZone(Zone.current,
          handleUncaughtError: _onErrorWithoutLongStackTrace);
    }
  }

  /// Whether we are currently executing in the inner zone. This can be used by
  /// clients to optimize and call [runOutside] when needed.
  bool get inInnerZone => Zone.current == _innerZone;

  /// Whether we are currently executing in the outer zone. This can be used by
  /// clients to optimize and call [runInside] when needed.
  bool get inOuterZone => Zone.current == _outerZone;

  Zone _createInnerZone(Zone zone,
      {void handleUncaughtError(
          Zone _, ZoneDelegate __, Zone ___, dynamic ____, StackTrace s)}) {
    return zone.fork(
        specification: new ZoneSpecification(
            scheduleMicrotask: _scheduleMicrotask,
            run: _run,
            runUnary: _runUnary,
            runBinary: _runBinary,
            handleUncaughtError: handleUncaughtError,
            createTimer: _createTimer),
        zoneValues: {'isAngularZone': true});
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
    try {
      _onEnter();
      return parent.run(zone, fn);
    } finally {
      _onLeave();
    }
  }

  R _runUnary<R, T>(
      Zone self, ZoneDelegate parent, Zone zone, R fn(T arg), T arg) {
    try {
      _onEnter();
      return parent.runUnary(zone, fn, arg);
    } finally {
      _onLeave();
    }
  }

  R _runBinary<R, T1, T2>(Zone self, ZoneDelegate parent, Zone zone,
      R fn(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
    try {
      _onEnter();
      return parent.runBinary(zone, fn, arg1, arg2);
    } finally {
      _onLeave();
    }
  }

  void _onEnter() {
    // console.log('ZONE.enter', this._nesting, this._isStable);
    _nesting++;
    if (_isStable) {
      _isStable = false;
      _isRunning = true;
      _onTurnStart.add(null);
    }
  }

  void _onLeave() {
    _nesting--;
    // console.log('ZONE.leave', this._nesting, this._isStable);
    _checkStable();
  }

  // Called by Chain.capture() on errors when long stack traces are enabled
  void _onErrorWithLongStackTrace(error, Chain chain) {
    final traces = chain.terse.traces.map((t) => t.toString()).toList();
    _onError.add(new NgZoneError(error, traces));
  }

  // Outer zone handleUnchaughtError when long stack traces are not used
  void _onErrorWithoutLongStackTrace(
      Zone self, ZoneDelegate parent, Zone zone, error, StackTrace trace) {
    _onError.add(new NgZoneError(error, [trace.toString()]));
  }

  Timer _createTimer(
      Zone self, ZoneDelegate parent, Zone zone, Duration duration, fn()) {
    WrappedTimer wrappedTimer;
    var cb = () {
      try {
        fn();
      } finally {
        _pendingTimers.remove(wrappedTimer);
        _setMacrotask(_pendingTimers.isNotEmpty);
      }
    };
    Timer timer = parent.createTimer(zone, duration, cb);
    wrappedTimer = new WrappedTimer(timer);
    wrappedTimer.addOnCancelCb(() {
      _pendingTimers.remove(wrappedTimer);
      _setMacrotask(_pendingTimers.isNotEmpty);
    });

    _pendingTimers.add(wrappedTimer);
    _setMacrotask(true);
    return wrappedTimer;
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
  bool get hasPendingMicrotasks => _hasPendingMicrotasks;

  /// Whether there are any outstanding microtasks.
  bool get hasPendingMacrotasks => _hasPendingMacrotasks;

  /// Executes the `fn` function synchronously within the Angular zone and
  /// returns value returned by the function.
  ///
  /// Running functions via `run` allows you to reenter Angular zone from a task
  /// that was executed outside of the Angular zone (typically started via
  /// [#runOutsideAngular]).
  ///
  /// Any future tasks or microtasks scheduled from within this function will
  /// continue executing from within the Angular zone.
  ///
  /// If a synchronous error happens it will be rethrown and not reported via
  /// `onError`.
  R run<R>(R fn()) {
    return _innerZone.run(fn);
  }

  /// Same as #run, except that synchronous errors are caught and forwarded
  /// via `onError` and not rethrown.
  void runGuarded(void fn()) {
    return _innerZone.runGuarded(fn);
  }

  /// Executes the `fn` function synchronously in Angular's parent zone and
  /// returns value returned by the function.
  ///
  /// Running functions via `runOutsideAngular` allows you to escape Angular's
  /// zone and do work that doesn't trigger Angular change-detection or is
  /// subject to Angular's error handling.
  ///
  /// Any future tasks or microtasks scheduled from within this function will
  /// continue executing from outside of the Angular zone.
  ///
  /// Use [#run] to reenter the Angular zone and do work that updates the
  /// application model.
  dynamic runOutsideAngular(dynamic fn()) {
    return _outerZone.run(fn);
  }

  /// Whether [onTurnStart] has been triggered and [onTurnDone] has not.
  bool get isRunning => _isRunning;

  /// Notify that an error has been delivered.
  Stream<NgZoneError> get onError => _onError.stream;

  /// Notifies when there is no more microtasks enqueue in the current VM Turn.
  ///
  /// This is a hint for Angular to do change detection, which may enqueue more
  /// microtasks.
  /// For this reason this event can fire multiple times per VM Turn.
  Stream<Null> get onMicrotaskEmpty => _onMicrotaskEmpty.stream;

  /// A synchronous stream that fires when the VM turn has started, which means
  /// that the inner (managed) zone has not executed any microtasks.
  ///
  /// Note:
  /// - Causing any turn action, e.g., spawning a Future, within this zone will
  ///   cause an infinite loop.
  Stream<Null> get onTurnStart => _onTurnStart.stream;

  /// A synchronous stream that fires when the VM turn is finished, which means
  /// when the inner (managed) zone has completed it's private microtask queue.
  ///
  /// Note:
  /// - This won't wait for microtasks schedules in outer zones.
  /// - Causing any turn action, e.g., spawning a Future, within this zone will
  ///   cause an infinite loop.
  Stream<Null> get onTurnDone => _onTurnDone.stream;

  /// A synchronous stream that fires when the last turn in an event completes.
  /// This indicates VM event loop end.
  ///
  /// Note:
  /// - This won't wait for microtasks schedules in outer zones.
  /// - Causing any turn action, e.g., spawning a Future, within this zone will
  ///   cause an infinite loop.
  Stream<Null> get onEventDone => _onMicrotaskEmpty.stream;

  /// App is disposed stop sending events.
  void dispose() {
    _disposed = true;
  }
}

/// A `Timer` wrapper that lets you specify additional functions to call when it
/// is cancelled.
class WrappedTimer implements Timer {
  Timer _timer;
  void Function() _onCancelCb;

  WrappedTimer(Timer timer) {
    _timer = timer;
  }

  void addOnCancelCb(void Function() onCancelCb) {
    if (this._onCancelCb != null) {
      throw new StateError("On cancel cb already registered");
    }
    this._onCancelCb = onCancelCb;
  }

  void cancel() {
    if (this._onCancelCb != null) {
      this._onCancelCb();
    }
    _timer.cancel();
  }

  bool get isActive => _timer.isActive;

  @override
  // TODO: Dart 2.0 requires this method to be implemented.
  // See https://github.com/dart-lang/sdk/issues/31664
  // ignore: override_on_non_overriding_getter
  int get tick {
    throw new UnimplementedError("tick");
  }
}

/// Stores error information; delivered via [NgZone.onError] stream.
class NgZoneError {
  /// Error object thrown.
  final error;

  /// Either long or short chain of stack traces.
  final List stackTrace;
  NgZoneError(this.error, this.stackTrace);
}
