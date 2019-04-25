/// A state for machine for transitioning how change detection is run.
///
/// Internal state is hidden, and instead the relevant bits that are needed for
/// views are exposed - for example, [shouldBeChecked] is `true` iff the
/// internal state determines that change detection is needed.
///
/// A view must invoke:
/// * [afterCheck]
/// * [afterError]
/// * [afterDetach]
///
/// ... in order to properly transition the states of the state machine.
///
/// TODO(b/129351696): Complete this class, test it, and replace cdMode/cdState.
/// TODO(b/129351696): Consider using bit-masks to store this more efficiently.
abstract class ChangeDetectionStrategy {
  ChangeDetectionStrategy._();

  /// Creates an instance of the state machine that uses the `Default` strategy.
  factory ChangeDetectionStrategy.defaultStrategy() = _DefaultChangeDetection;

  /// Creates an instance of the state machine that uses the `OnPush` strategy.
  factory ChangeDetectionStrategy.onPushStrategy() = _OnPushChangeDetection;

  /// Whether `AppView.detectChanges()` should be run.
  bool get shouldBeChecked;

  /// Report that change detection was run on the view.
  ///
  /// Returns whether this was the _first_ time change detection was executed.
  ///
  /// ```
  /// @override
  /// void detectChanges() {
  ///   var currExpr = ctx.boundValue;
  ///   if (checkBinding(currExpr, this._expr_0)) {
  ///     this._expr_0 = this._comp_0.bindTo = currExpr;
  ///   }
  ///   if (this._changeDetection.afterCheck()) {
  ///     this._comp_0.ngOnInit();
  ///   }
  /// }
  /// ```
  bool afterCheck();

  /// Report that an unhandled error caused this view to crash.
  void afterError();

  /// Report that the view should be detached from the tree.
  void afterDetach();
}

/// Has never been checked for change detection.
const _neverChecked = 0;

/// Has been checked at least once.
const _wasChecked = 1;

/// Has been checked at least once, but is not currently considered dirty.
const _wasCheckedNotDirty = 2;

/// Is not currently part of the change detection tree.
const _wasDetached = 3;

/// Crashed during change detection.
const _uncaughtError = 4;

class _DefaultChangeDetection implements ChangeDetectionStrategy {
  /// Used to track what part of the lifecycle the view is currently in.
  ///
  /// * [_neverChecked]: Before `ngOnInit`.
  /// * [_wasChecked]: After `ngOnInit`, before `ngOnDestroy`.
  /// * [_wasDestroyed]: After `ngOnDestroy`.
  /// * [_uncaughtError]: Crashed during change detection.
  var _lifecycleState = _neverChecked;

  /// Whether `AppView.detectChanges()` should be run.
  bool get shouldBeChecked => _lifecycleState < _wasCheckedNotDirty;

  /// Report that change detection was run on the view.
  ///
  /// Returns whether this was the _first_ time change detection was executed.
  ///
  /// ```
  /// @override
  /// void detectChanges() {
  ///   var currExpr = ctx.boundValue;
  ///   if (checkBinding(currExpr, this._expr_0)) {
  ///     this._expr_0 = this._comp_0.bindTo = currExpr;
  ///   }
  ///   if (this._changeDetection.afterCheck()) {
  ///     this._comp_0.ngOnInit();
  ///   }
  /// }
  /// ```
  bool afterCheck() {
    if (_lifecycleState == _neverChecked) {
      _lifecycleState = _wasChecked;
      return true;
    }
    return false;
  }

  /// Report that an unhandled error caused this view to crash.
  void afterError() {
    _lifecycleState = _uncaughtError;
  }

  /// Report that the view should be detached from the tree.
  void afterDetach() {
    _lifecycleState = _wasDetached;
  }
}

class _OnPushChangeDetection extends _DefaultChangeDetection {
  // TODO: Avoid setting `_lifecycleState` twice per call to this method.
  @override
  bool afterCheck() {
    final wasFirst = super.afterCheck();
    _lifecycleState = _wasCheckedNotDirty;
    return wasFirst;
  }
}
