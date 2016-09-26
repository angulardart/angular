import "package:angular2/src/facade/async.dart" show EventEmitter;

import "ng_zone_impl.dart" show NgZoneImpl, NgZoneError;

export "ng_zone_impl.dart" show NgZoneError;

/// An injectable service for executing work inside or outside of the Angular zone.
///
/// The most common use of this service is to optimize performance when starting a work consisting of
/// one or more asynchronous tasks that don't require UI updates or error handling to be handled by
/// Angular. Such tasks can be kicked off via [#runOutsideAngular] and if needed, these tasks
/// can reenter the Angular zone via [#run].
///
/// <!-- TODO: add/fix links to:
///   - docs explaining zones and the use of zones in Angular and change-detection
///   - link to runOutsideAngular/run (throughout this file!)
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
///     <button (click)="processWithinAngularZone()">Process within Angular zone</button>
///     <button (click)="processOutsideOfAngularZone()">Process outside of Angular zone</button>
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
    return NgZoneImpl.isInAngularZone();
  }

  static void assertInAngularZone() {
    if (!NgZoneImpl.isInAngularZone()) {
      throw new Exception("Expected to be in Angular Zone, but it is not!");
    }
  }

  static void assertNotInAngularZone() {
    if (NgZoneImpl.isInAngularZone()) {
      throw new Exception("Expected to not be in Angular Zone, but it is!");
    }
  }

  NgZoneImpl _zoneImpl;
  bool _hasPendingMicrotasks = false;
  bool _hasPendingMacrotasks = false;
  /** @internal */
  var _isStable = true;
  /** @internal */
  var _nesting = 0;
  /** @internal */
  EventEmitter<dynamic> _onUnstable = new EventEmitter(false);
  /** @internal */
  EventEmitter<dynamic> _onMicrotaskEmpty = new EventEmitter(false);
  /** @internal */
  EventEmitter<dynamic> _onStable = new EventEmitter(false);
  /** @internal */
  EventEmitter<dynamic> _onErrorEvents = new EventEmitter(false);

  /// enabled in development mode as they significantly impact perf.
  NgZone({enableLongStackTrace: false}) {
    this._zoneImpl = new NgZoneImpl(
        trace: enableLongStackTrace,
        onEnter: () {
          // console.log('ZONE.enter', this._nesting, this._isStable);
          this._nesting++;
          if (this._isStable) {
            this._isStable = false;
            this._onUnstable.emit(null);
          }
        },
        onLeave: () {
          this._nesting--;
          // console.log('ZONE.leave', this._nesting, this._isStable);
          this._checkStable();
        },
        setMicrotask: (bool hasMicrotasks) {
          this._hasPendingMicrotasks = hasMicrotasks;
          this._checkStable();
        },
        setMacrotask: (bool hasMacrotasks) {
          this._hasPendingMacrotasks = hasMacrotasks;
        },
        onError: (NgZoneError error) => this._onErrorEvents.emit(error));
  }
  void _checkStable() {
    if (this._nesting == 0) {
      if (!this._hasPendingMicrotasks && !this._isStable) {
        try {
          // console.log('ZONE.microtaskEmpty');
          this._nesting++;
          this._onMicrotaskEmpty.emit(null);
        } finally {
          this._nesting--;
          if (!this._hasPendingMicrotasks) {
            try {
              // console.log('ZONE.stable', this._nesting, this._isStable);
              this.runOutsideAngular(() => this._onStable.emit(null));
            } finally {
              this._isStable = true;
            }
          }
        }
      }
    }
  }

  /// Notifies when code enters Angular Zone. This gets fired first on VM Turn.
  EventEmitter<dynamic> get onUnstable {
    return this._onUnstable;
  }

  /// Notifies when there is no more microtasks enqueue in the current VM Turn.
  /// This is a hint for Angular to do change detection, which may enqueue more microtasks.
  /// For this reason this event can fire multiple times per VM Turn.
  EventEmitter<dynamic> get onMicrotaskEmpty {
    return this._onMicrotaskEmpty;
  }

  /// Notifies when the last `onMicrotaskEmpty` has run and there are no more microtasks, which
  /// implies we are about to relinquish VM turn.
  /// This event gets called just once.
  EventEmitter<dynamic> get onStable => this._onStable;

  /// Notify that an error has been delivered.
  EventEmitter<dynamic> get onError => this._onErrorEvents;

  /// Whether there are any outstanding microtasks.
  bool get hasPendingMicrotasks => this._hasPendingMicrotasks;

  /// Whether there are any outstanding microtasks.
  bool get hasPendingMacrotasks => this._hasPendingMacrotasks;

  /// Executes the `fn` function synchronously within the Angular zone and returns value returned by
  /// the function.
  ///
  /// Running functions via `run` allows you to reenter Angular zone from a task that was executed
  /// outside of the Angular zone (typically started via [#runOutsideAngular]).
  ///
  /// Any future tasks or microtasks scheduled from within this function will continue executing from
  /// within the Angular zone.
  ///
  /// If a synchronous error happens it will be rethrown and not reported via `onError`.
  dynamic/*=R*/ run/*<R>*/(/*=R*/ fn()) {
    return this._zoneImpl.runInner(fn);
  }

  /// Same as #run, except that synchronous errors are caught and forwarded
  /// via `onError` and not rethrown.
  dynamic/*=R*/ runGuarded/*<R>*/(/*=R*/ fn()) {
    return this._zoneImpl.runInnerGuarded(fn);
  }

  /// Executes the `fn` function synchronously in Angular's parent zone and returns value returned by
  /// the function.
  ///
  /// Running functions via `runOutsideAngular` allows you to escape Angular's zone and do work that
  /// doesn't trigger Angular change-detection or is subject to Angular's error handling.
  ///
  /// Any future tasks or microtasks scheduled from within this function will continue executing from
  /// outside of the Angular zone.
  ///
  /// Use [#run] to reenter the Angular zone and do work that updates the application model.
  dynamic runOutsideAngular(dynamic fn()) {
    return this._zoneImpl.runOuter(fn);
  }
}
