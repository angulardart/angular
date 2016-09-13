// TODO(matanl): Consider moving this as a sub package, as concept is common.
// Almost any UI-based framework will have the concept of asynchronous services
// that will later modify the state of DOM (or another UI-layer).
import 'dart:async';

import 'package:angular2/di.dart';
import 'package:angular2/src/core/zone/ng_zone.dart';

/// Abstraction around services that change the state of the DOM asynchronously.
///
/// One strategy of testing Angular components is to interact with their emitted
/// DOM as-if you were a user with a browser, and assert the state of the DOM
/// instead of the state of the component. For example, a toggle button that
/// switches between 'Yes' and 'No' when clicked:
///     testToggleButton(ButtonElement button) {
///       expect(button.text, 'Yes');
///       button.click();
///       expect(button.text, 'No');
///     }
///
/// In the case of Angular, and of other DOM-related libraries, however, the
/// changes are not always applied immediately (synchronously). Instead, we need
/// a contract that lets us `await` any possible changes, and then assert state:
///     testToggleButton(ButtonElement button, NgDomStabilizer dom) async {
///       expect(button.text, 'Yes');
///       await dom.execute(() => button.click());
///       expect(button.text, 'No');
///     }
///
/// Either `extend` or `implement` [NgDomStabilizer].
abstract class NgDomStabilizer {
  /// Create a [NgDomStabilizer] that delegates to all [stabilizers].
  ///
  /// The stabilizer will report 'stable' when _every_ stabilizer reports so.
  factory NgDomStabilizer.all(Iterable<NgDomStabilizer> stabilizers) =
      _CompoundStabilizer;

  // Allow extending.
  const NgDomStabilizer();

  /// May implement in order to be aware of any side-effects of [fn].
  ///
  /// For example, stabilizers that use the [Zone] API will run within:
  ///     @override
  ///     Future<Null> execute(void fn()) {
  ///       // Track the results of running fn, which may spawn async events.
  ///       _zone.run(fn);
  ///
  ///       // Wait until we know our async events are done.
  ///       return stabilize();
  ///     }
  // TODO(matanl): @mustCallSuper? https://github.com/dart-lang/sdk/issues/27275
  Future<Null> execute(void fn()) => stabilize();

  /// Returns a [Future] that completes when no DOM updating events are pending.
  ///
  /// May be `await`ed in tests in order to wait until any possible DOM changes
  /// are complete before asserting future state.
  ///
  /// Implementations should default to a single microtask/[Future.value] (or
  /// call `super.stabilize()` if no events are pending in order to always
  /// return a [Future].
  Future<Null> stabilize() => new Future<Null>.value();
}

/// A stabilizer implementation that delegates to multiple other stabilizers.
class _CompoundStabilizer implements NgDomStabilizer {
  final List<NgDomStabilizer> _stabilizers;

  _CompoundStabilizer(Iterable<NgDomStabilizer> stabilizers)
      : _stabilizers = stabilizers.toList(growable: false);

  @override
  Future<Null> execute(void fn()) async {
    for (var stabilizer in _stabilizers) {
      await stabilizer.execute(fn);
    }
  }

  @override
  Future<Null> stabilize() async {
    for (var stabilizer in _stabilizers) {
      await stabilizer.stabilize();
    }
  }
}

/// A wrapper API that reports stability based on [NgZone].
@Injectable()
class NgZoneStabilizer extends NgDomStabilizer {
  final NgZone _ngZone;

  /// Create a new stabilizer around a [NgZone].
  NgZoneStabilizer(this._ngZone);

  bool get _isUnstable =>
      _ngZone.hasPendingMicrotasks || _ngZone.hasPendingMacrotasks;

  @override
  Future<Null> execute(void fn()) {
    _ngZone.run(fn);
    return super.execute(fn);
  }

  @override
  Future<Null> stabilize() async {
    while (_isUnstable) {
      await _ngZone.onStable.first;
    }
  }
}
