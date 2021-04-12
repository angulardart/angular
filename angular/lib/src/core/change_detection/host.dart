import 'dart:async';

import 'package:meta/dart2js.dart' as dart2js;
import 'package:meta/meta.dart';
import 'package:angular/src/core/linker/views/view.dart';
import 'package:angular/src/runtime/check_binding.dart';
import 'package:angular/src/utilities.dart';

import 'change_detector_ref.dart';

/// A host for tracking the current application.
///
/// This is expected to the base class for an `ApplicationRef`, and eventually
/// could be merged in directly to avoid having inheritance if necessary. For
/// now this is just for ease of testing and not breaking existing code.
abstract class ChangeDetectionHost {
  /// The current host being executed (synchronously) via [tick].
  static ChangeDetectionHost? _current;

  /// **INTERNAL ONLY**: Whether a crash was detected during the last `tick()`.
  static bool get checkForCrashes => _current?._lastGuardedView != null;

  /// **INTERNAL ONLY**: Register a crash during [view.detectCrash].
  static void handleCrash(View view, Object error, StackTrace trace) {
    final current = _current!;
    current
      .._lastGuardedView = view
      .._lastCaughtException = error
      .._lastCaughtTrace = trace;
  }

  /// If a crash is detected during zone-based change detection, then this view
  /// is set (non-null). Change detection is re-run (synchronously) in a
  /// slow-mode that individually checks component, and disables change
  /// detection for them if there is failure detected.
  View? _lastGuardedView;

  /// An exception caught for [_lastGuardedView], if any.
  Object? _lastCaughtException;

  /// A stack trace caught for [_lastGuardedView].
  StackTrace? _lastCaughtTrace;

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

  /// Runs a change detection pass on all registered root components.
  ///
  /// In development mode, a second change detection cycle is executed in order
  /// to ensure that no further changes are detected. If additional changes are
  /// picked up, an exception is thrown to warn the user this is bad behavior to
  /// rely on for the production application.
  @nonVirtual
  @protected
  void tick() {
    if (isDevMode && _runningTick) {
      throw StateError('Change detecion (tick) was called recursively');
    }

    // Checks all components for change detection errors.
    //
    // If at least one occurs, we will re-run looking for the failing component.
    try {
      _current = this;
      _runningTick = true;
      _runTick();
    } catch (e, s) {
      // A crash (uncaught exception) was found. That means at least one
      // directive in the application tree is throwing. We need to re-run
      // change detection to disable offending directives.
      if (!_runTickGuarded()) {
        // Propagate the original exception/stack upwards, with 'DigestTick'
        // keyword. Then application can join tick exception with original
        // exception, which usually named "AppView.detectCrash".
        handleUncaughtException(e, s, 'DigestTick');
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
    if (isDevMode) {
      debugEnterThrowOnChanged();
      for (var i = 0; i < length; i++) {
        detectors[i].detectChanges();
      }
      debugThrowIfUnstableExpressionsFound();
      debugExitThrowOnChanged();
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
    if (isDevMode) {
      debugThrowOnChangedImmediately();
    }
    for (var i = 0; i < length; i++) {
      final detector = detectors[i];
      if (detector is View) {
        final view = detector;
        _lastGuardedView = view;
        view.detectChanges();
      }
    }
    if (isDevMode) {
      debugExitThrowOnChanged();
    }
    return _checkForChangeDetectionError();
  }

  static const _isSoundNullSafety = <Object?>[] is! List<Object>;

  /// Checks for any uncaught exception that occurred during change detection.
  @dart2js.noInline
  bool _checkForChangeDetectionError() {
    final lastGuardedView = _lastGuardedView;
    // TODO(b/168837384): _lastCaughtException != null.
    if (lastGuardedView != null) {
      reportViewException(
        lastGuardedView,
        // TODO(b/168837384): Better handle the cases where this is null or make
        // the value being null part of the explicit contract. By changing this
        // to `_lastCaughtException!` and running our test cases multiple tests
        // start failing!
        _isSoundNullSafety
            ? _lastCaughtException ?? Error()
            : _lastCaughtException as Object,
        _lastCaughtTrace,
      );
      _resetViewErrors();
      return true;
    }
    return false;
  }

  @dart2js.noInline
  void _resetViewErrors() {
    _lastGuardedView = _lastCaughtException = _lastCaughtTrace = null;
  }

  /// Disables the [view] as an error, and forwards to [reportException].
  @dart2js.noInline
  void reportViewException(
    View view,
    Object error, [
    StackTrace? trace,
  ]) {
    view.disableChangeDetection();
    handleUncaughtException(error, trace);
  }

  /// Forwards an [error] and [trace] to the user's error handler.
  ///
  /// This is expected to be provided by the current application.
  @protected
  @visibleForOverriding
  void handleUncaughtException(
    Object error, [
    StackTrace? trace,
    String? reason,
  ]);

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
    final completer = Completer<R>();
    FutureOr<R>? result;
    runInZone(() {
      try {
        result = callback();
        if (result is Future<Object>) {
          final resultCast = unsafeCast<Future<R>>(result);
          resultCast.then((result) {
            completer.complete(result);
          }, onError: (e, s) {
            final sCasted = unsafeCast<StackTrace>(s);
            final eCasted = unsafeCast<Object>(e);
            completer.completeError(eCasted, sCasted);
            handleUncaughtException(eCasted, sCasted);
          });
        }
      } catch (e, s) {
        handleUncaughtException(e, s);
        // Note, due to the rethrow a synchronous error thrown in callback will
        // cause the `run` function never to return. This is important to note
        // because of the handling logic below.
        rethrow;
      }
    });
    // Some complexity in null-safety: `FutureOr<R>` can mean:
    // 1. Future<R> where R might be nullable or non-nullable.
    // 2. R, where R is non-nullable.
    // 3. R, where R is nullable.
    //
    // We need to carefully evaluate the three different cases to avoid a subtle
    // breaking API change (we still want our users to be allowed to return null
    // if they expect a nullable value) - i.e.:
    //
    //   // Should continue to be valid.
    //   String? name = run(() => null);
    //
    // See also: https://dart.dev/null-safety/understanding-null-safety#nullability-and-generics.
    final r = result;
    if (r == null) {
      // The variable r can only be null here if the callback returned null,
      // which in turn can only happen if either we were called from opted-in
      // code and R is nullable, or if we were called from opted-out code.
      //
      // In either case, the case here should always suceed. By explicitly
      // checking for null, we avoid having a cast in the final (and likely more
      // frequently executed) branch of the conditional.
      return r as R;
    } else if (r is Future<Object>) {
      // Return as a Future<R>.
      return completer.future;
    } else {
      // Return as R.
      return r;
    }
  }

  /// Executes the [callback] function within the current `NgZone`.
  ///
  /// This is expected to be provided by the current application.
  @protected
  @visibleForOverriding
  R runInZone<R>(R Function() callback);
}
