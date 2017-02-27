import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

/// An injectable service for executing work inside or outside of the
/// Angular zone.
///
/// The most common use of this service is to optimize performance when starting
/// a work consisting of one or more asynchronous tasks that don't require UI
/// updates or error handling to be handled by Angular. Such tasks can be
/// kicked off via [#runOutsideAngular] and if needed, these tasks
/// can reenter the Angular zone via [#run].
///
/// <!-- TODO: add/fix links to:
///   - docs explaining zones and the use of zones in Angular and
///   - change-detection link to runOutsideAngular/run (throughout this file!)
///   -->
///
/// ### Example ([live demo](http://plnkr.co/edit/lY9m8HLy7z06vDoUaSN2?p=preview))
/// ```
/// import {Component, View, NgZone} from 'angular2/core';
/// import {NgIf} from 'angular2/common';
///
/// @Component({
///   selector: 'ng-zone-demo'.
///   template: `
///     <h2>Demo: NgZone</h2>
///
///     <p>Progress: {{progress}}%</p>
///     <p *ngIf="progress >= 100">Done processing {{label}} of Angular zone!</p>
///
///     <button (click)="processWithinAngularZone()">Process within Angular zone
///     </button>
///     <button (click)="processOutsideOfAngularZone()">
///       Process outside of Angular zone
///     </button>
///   `,
///   directives: [NgIf]
/// })
/// export class NgZoneDemo {
///   progress: number = 0;
///   label: string;
///
///   constructor(private _ngZone: NgZone) {}
///
///   // Loop inside the Angular zone
///   // so the UI DOES refresh after each setTimeout cycle
///   processWithinAngularZone() {
///     this.label = 'inside';
///     this.progress = 0;
///     this._increaseProgress(() => console.log('Inside Done!'));
///   }
///
///   // Loop outside of the Angular zone
///   // so the UI DOES NOT refresh after each setTimeout cycle
///   processOutsideOfAngularZone() {
///     this.label = 'outside';
///     this.progress = 0;
///     this._ngZone.runOutsideAngular(() => {
///       this._increaseProgress(() => {
///       // reenter the Angular zone and display done
///       this._ngZone.run(() => {console.log('Outside Done!') });
///     }}));
///   }
///
///
///   _increaseProgress(doneCallback: () => void) {
///     this.progress += 1;
///     console.log(`Current progress: ${this.progress}%`);
///
///     if (this.progress < 100) {
///       window.setTimeout(() => this._increaseProgress(doneCallback)), 10)
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

  final StreamController _onUnstableController =
      new StreamController.broadcast(sync: true);
  final StreamController _onMicrotaskEmptyController =
      new StreamController.broadcast(sync: true);
  final StreamController _onStableController =
      new StreamController.broadcast(sync: true);
  final StreamController _onErrorController =
      new StreamController.broadcast(sync: true);

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
  List<Timer> _pendingTimers = [];

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
      {handleUncaughtError(
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

  dynamic _run(Zone self, ZoneDelegate parent, Zone zone, fn()) {
    try {
      _onEnter();
      return parent.run(zone, fn);
    } finally {
      _onLeave();
    }
  }

  dynamic _runUnary(Zone self, ZoneDelegate parent, Zone zone, fn(arg), arg) {
    try {
      _onEnter();
      return parent.runUnary(zone, fn, arg);
    } finally {
      _onLeave();
    }
  }

  dynamic _runBinary(
      Zone self, ZoneDelegate parent, Zone zone, fn(arg1, arg2), arg1, arg2) {
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
      _onUnstableController.add(null);
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
    _onErrorController.add(new NgZoneError(error, traces));
  }

  // Outer zone handleUnchaughtError when long stack traces are not used
  void _onErrorWithoutLongStackTrace(
      Zone self, ZoneDelegate parent, Zone zone, error, StackTrace trace) {
    _onErrorController.add(new NgZoneError(error, [trace.toString()]));
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
          // console.log('ZONE.microtaskEmpty');
          _nesting++;
          _isRunning = false;
          if (!_disposed) _onMicrotaskEmptyController.add(null);
        } finally {
          _nesting--;
          if (!_hasPendingMicrotasks) {
            try {
              // console.log('ZONE.stable', this._nesting, this._isStable);
              runOutsideAngular(() {
                if (!_disposed) _onStableController.add(null);
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
  R runGuarded<R>(R fn()) {
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
  Stream get onError => _onErrorController.stream;

  /// Notifies when there is no more microtasks enqueue in the current VM Turn.
  /// This is a hint for Angular to do change detection, which may enqueue more microtasks.
  /// For this reason this event can fire multiple times per VM Turn.
  Stream get onMicrotaskEmpty => _onMicrotaskEmptyController.stream;

  /// A synchronous stream that fires when the VM turn has started, which means
  /// that the inner (managed) zone has not executed any microtasks.
  ///
  /// Note:
  /// - Causing any turn action, e.g., spawning a Future, within this zone will
  ///   cause an infinite loop.
  Stream get onTurnStart => _onUnstableController.stream;

  /// A synchronous stream that fires when the VM turn is finished, which means
  /// when the inner (managed) zone has completed it's private microtask queue.
  ///
  /// Note:
  /// - This won't wait for microtasks schedules in outer zones.
  /// - Causing any turn action, e.g., spawning a Future, within this zone will
  ///   cause an infinite loop.
  Stream get onTurnDone => _onStableController.stream;

  /// A synchronous stream that fires when the last turn in an event completes.
  /// This indicates VM event loop end.
  ///
  /// Note:
  /// - This won't wait for microtasks schedules in outer zones.
  /// - Causing any turn action, e.g., spawning a Future, within this zone will
  ///   cause an infinite loop.
  Stream get onEventDone => _onMicrotaskEmptyController.stream;

  @Deprecated('Use onTurnDone')
  Stream get onStable => _onStableController.stream;

  @Deprecated('Use onTurnStart')
  Stream get onUnstable => _onUnstableController.stream;
}

typedef void ZeroArgFunction();
typedef void ErrorHandlingFn(error, stackTrace);

/// A `Timer` wrapper that lets you specify additional functions to call when it
/// is cancelled.
class WrappedTimer implements Timer {
  Timer _timer;
  ZeroArgFunction _onCancelCb;

  WrappedTimer(Timer timer) {
    _timer = timer;
  }

  void addOnCancelCb(ZeroArgFunction onCancelCb) {
    if (this._onCancelCb != null) {
      throw "On cancel cb already registered";
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
}

/// Stores error information; delivered via [NgZone.onError] stream.
class NgZoneError {
  /// Error object thrown.
  final error;

  /// Either long or short chain of stack traces.
  final List stackTrace;
  NgZoneError(this.error, this.stackTrace);
}
