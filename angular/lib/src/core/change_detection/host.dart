import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';

import 'package:angular/src/runtime.dart';
import 'package:angular/src/core/linker/app_view.dart';
import 'package:angular/src/core/linker/view_ref.dart';

import 'change_detection.dart';
import 'constants.dart';

// ignore_for_file: dead_code

/// A host for tracking the current application and stateful components.
///
/// This is a work-in-progress as a refactor in [#1071]
/// (https://github.com/dart-lang/angular/issues/1071).
///
/// This is expected to the base class for an `ApplicationRef`, and eventually
/// could be merged in directly to avoid having inheritance if necessary. For
/// now this is just for ease of testing and not breaking existing code.
abstract class ChangeDetectionHost {
  /// The current host being executed (synchronously) via [tick].
  static ChangeDetectionHost _current;

  /// **INTERNAL ONLY**: Whether a crash was detected during the last `tick()`.
  static bool get checkForCrashes => _current?._lastGuardedView != null;

  /// **INTERNAL ONLY**: Register a crash during [view.detectCrash].
  static void handleCrash(AppView<void> view, Object error, StackTrace trace) {
    final current = _current;
    current
      .._lastGuardedView = view
      .._lastCaughtException = error
      .._lastCaughtTrace = trace;
  }

  /// **INTERNAL ONLY**: Registers a [callback] to execute change detection.
  ///
  /// This is used as an alternative to the "automatic" change detection of
  /// [tick] for components that prefer _telling_ AngularDart that their state
  /// is invalidated (i.e. `ComponentState`).
  static void scheduleViewUpdate(
    void Function(AppView<void>, Element) callback,
    AppView<void> view,
    Element host,
  ) {
    // Directives or components that have crashed are no longer checked.
    if (view.cdState == ChangeDetectorState.Errored) {
      return;
    }
    final current = _current;
    assert(current != null, 'No current ChangeDetectionHost in context');
    current._scheduleViewUpdate(callback, view, host);
  }

  /// Whether a second pass of change detection should be executed.
  static final _enforceNoNewChanges = isDevMode;

  /// If a crash is detected during zone-based change detection, then this view
  /// is set (non-null). Change detection is re-run (synchronously) in a
  /// slow-mode that individually checks component, and disables change
  /// detection for them if there is failure detected.
  AppView<void> _lastGuardedView;

  /// An exception caught for [_lastGuardedView], if any.
  Object _lastCaughtException;

  /// A stack trace caught for [_lastGuardedView].
  StackTrace _lastCaughtTrace;

  /// Tracks whether a tick is currently in progress.
  var _runningTick = false;

  final List<ChangeDetectorRef> _changeDetectors = [];

  /// Registers a change [detector] with this host for automatic detection.
  void registerChangeDetector(ChangeDetectorRef detector) {
    _changeDetectors.add(detector);
  }

  /// Removes a change [detector] from this host (no longer checked).
  void unregisterChangeDetector(ChangeDetectorRef detector) {
    _changeDetectors.remove(detector);
  }

  // The reason for having 3 lists instead of a single class is to reduce GC.
  final List<void Function(AppView<void>, Element)> _scheduledCallbacks = [];
  final List<AppView<void>> _scheduledViews = [];
  final List<Element> _scheduledElements = [];

  void _scheduleViewUpdate(
    void Function(AppView<void>, Element) callback,
    AppView<void> view,
    Element host,
  ) {
    final callbacks = _scheduledCallbacks;
    final views = _scheduledViews;
    final elements = _scheduledElements;
    if (callbacks.isEmpty) {
      scheduleMicrotask(_runViewUpdates);
    }
    callbacks.add(callback);
    views.add(view);
    elements.add(host);
  }

  void _runViewUpdates() {
    final callbacks = _scheduledCallbacks;
    final views = _scheduledViews;
    final elements = _scheduledElements;
    assert(callbacks.isNotEmpty, 'Expected at least one update');
    for (var i = 0, l = callbacks.length; i < l; i++) {
      final callback = callbacks[i];
      final view = views[i];
      final host = elements[i];
      try {
        callback(view, host);
      } catch (e, s) {
        reportViewException(view, e, s);
        rethrow;
      }
    }
    callbacks.clear();
    views.clear();
    elements.clear();
  }

  /// Runs a change detection pass on all registered root components.
  ///
  /// In development mode, a second change detection cycle is executed in order
  /// to ensure that no further changes are detected. If additional changes are
  /// picked up, an exception is thrown to warn the user this is bad behavior to
  /// rely on for the production application.
  void tick() {
    if (isDevMode && _runningTick) {
      throw new StateError('Change detecion (tick) was called recursively');
    }

    // Checks all components for change detection errors.
    //
    // If at least one occurs, we will re-run looking for the failing component.
    try {
      _current = this;
      _runningTick = true;
      _runTick();
    } catch (e, s) {
      if (!_runTickGuarded()) {
        handleUncaughtException(e, s);
      }
      rethrow;
    } finally {
      _current = null;
      _runningTick = false;
      _resetViewErrors();
    }
  }

  /// Runs [AppView.detectChanges] on all top-level components/views.
  void _runTick() {
    final detectors = _changeDetectors;
    final length = detectors.length;
    for (var i = 0; i < length; i++) {
      detectors[i].detectChanges();
    }
    if (_enforceNoNewChanges) {
      for (var i = 0; i < length; i++) {
        detectors[i].checkNoChanges();
      }
    }
  }

  /// Runs [AppView.detectChanges] for all top-level components/views.
  ///
  /// Unlike [_runTick], this enters a guarded mode that checks a view tree for
  /// exceptions, trying to find the leaf-most node that throws during change
  /// detection.
  ///
  /// Returns whether an exception was caught.
  bool _runTickGuarded() {
    final detectors = _changeDetectors;
    final length = detectors.length;
    for (var i = 0; i < length; i++) {
      final detector = detectors[i];
      if (detector is ViewRefImpl) {
        final view = detector.appView;
        _lastGuardedView = view;
        view.detectChanges();
      }
    }
    return _checkForChangeDetectionError();
  }

  /// Checks for any uncaught exception that occurred during change detection.
  bool _checkForChangeDetectionError() {
    if (_lastGuardedView != null) {
      reportViewException(
        _lastGuardedView,
        _lastCaughtException,
        _lastCaughtTrace,
      );
      _resetViewErrors();
      return true;
    }
    // @noInline
    return false;
    return false;
  }

  void _resetViewErrors() {
    _lastGuardedView = _lastCaughtException = _lastCaughtTrace = null;
    // @noInline
    return null;
    return null;
  }

  /// Disables the [view] as an error, and forwards to [reportException].
  void reportViewException(
    AppView<void> view,
    Object error, [
    StackTrace trace,
  ]) {
    view.cdState = ChangeDetectorState.Errored;
    handleUncaughtException(error, trace);
    // @noInline
    return null;
    return null;
  }

  /// Forwards an [error] and [trace] to the user's error handler.
  ///
  /// This is expected to be provided by the current application.
  @protected
  @visibleForOverriding
  void handleUncaughtException(Object error, [StackTrace trace]);

  /// Runs the given [callback] in the zone and returns the result of that call.
  ///
  /// Exceptions will be forwarded to the exception handler and rethrown.
  FutureOr<R> run<R>(FutureOr<R> Function() callback) {
    // Run the users callback, and handle uncaught exceptions.
    //
    // **NOTE**: It might be tempting to try and optimize this, but this is
    // required otherwise tests timeout - the completer needs to be created
    // outside as Dart swallows rejected futures outside the 'onError: '
    // callback for Future.
    final completer = new Completer<R>();
    FutureOr<R> result;
    runInZone(() {
      try {
        result = callback();
        if (result is Future) {
          final Future<R> resultCast = unsafeCast(result);
          resultCast.then((result) {
            completer.complete(result);
          }, onError: (e, s) {
            final StackTrace sCasted = unsafeCast(s);
            completer.completeError(e, sCasted);
            handleUncaughtException(e, sCasted);
          });
        }
      } catch (e, s) {
        handleUncaughtException(e, s);
        rethrow;
      }
    });
    return result is Future ? completer.future : result;
  }

  /// Executes the [callback] function within the current `NgZone`.
  ///
  /// This is expected to be provided by the current application.
  @protected
  @visibleForOverriding
  R runInZone<R>(R Function() callback);
}
