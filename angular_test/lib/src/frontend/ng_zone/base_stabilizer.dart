import 'dart:async';

import 'package:angular/angular.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';

import '../stabilizer.dart';

/// A stabilizer expected to manage and use [NgZone] *and* its own [Zone].
abstract class BaseNgZoneStabilizer<T extends Timer> extends NgTestStabilizer {
  /// Instance of [NgZone] that was created for this stabilizer.
  final NgZone ngZone;

  /// Timer instances that are currently pending execution.
  @protected
  final PriorityQueue<T> pendingTimers;

  /// Creates the stabilizer wrapping an instance of [NgZone].
  ///
  /// Concrete classes should make sure this zone is created with a zone
  /// specification that utilizes [ZoneSpecification.createTimer].
  BaseNgZoneStabilizer(this.ngZone, this.pendingTimers);

  @mustCallSuper
  @override
  bool get isStable => !ngZone.hasPendingMicrotasks;

  static void _noSideEffects() {}

  @override
  Future<bool> update([
    void Function() runAndTrackSideEffects,
  ]) {
    // Future.sync() ensures that any errors thrown by `runAndTrackSideEffects`
    // are propagated through the returned Future instead of being thrown
    // synchronously.
    return Future<void>.sync(() {
      _triggerSideEffects(runAndTrackSideEffects ?? _noSideEffects);
      return _waitForAsyncEventsOrErrors();
    }).then((_) => isStable);
  }

  void _triggerSideEffects(void Function() withCallback) {
    scheduleMicrotask(() => ngZone.runGuarded(() => withCallback()));
  }

  /// May be overridden to change what is awaited.
  ///
  /// The default implementation is only microtasks in the [NgZone].
  @protected
  Future<void> waitForAsyncEvents() => ngZone.onTurnDone.first;

  @protected
  static StackTrace rebuildStackTrace(List<Object> traceOrChain) {
    return StackTrace.fromString(traceOrChain.join('\n'));
  }

  Future<void> _waitForAsyncEventsOrErrors() async {
    Object uncaughtError;
    StackTrace uncaughtStack;
    StreamSubscription<void> onErrorSub;

    // Used instead of .first in order to allow cancellation.
    onErrorSub = ngZone.onError.listen((e) {
      uncaughtError = e.error;
      uncaughtStack = rebuildStackTrace(e.stackTrace);
      onErrorSub.cancel();
    });

    // Wait for significant async events.
    await waitForAsyncEvents();

    // End the microtask loop to give a chance to catch other errors.
    await Future(() {});
    unawaited(onErrorSub.cancel());

    // Return the caught error or just a blank future to continue.
    return uncaughtError != null
        ? Future.error(uncaughtError, uncaughtStack)
        : Future.value();
  }
}
