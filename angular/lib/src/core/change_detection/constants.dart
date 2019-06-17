/// Describes the current state of the change detector.
class ChangeDetectorState {
  /// [NeverChecked] means that the change detector has not been checked yet,
  /// and initialization methods should be called during detection.
  static const int NeverChecked = 0;

  /// [CheckedBefore] means that the change detector has successfully completed
  /// at least one detection previously.
  static const int CheckedBefore = 1;

  /// [Errored] means that the change detector encountered an error checking a
  /// binding or calling a directive lifecycle method and is now in an
  /// inconsistent state. Change detectors in this state will no longer detect
  /// changes.
  static const int Errored = 2;
}

/// Describes within the change detector which strategy will be used the next
/// time change detection is triggered.
///
/// ! Changes to this class require updates to view_compiler/constants.dart.
class ChangeDetectionStrategy {
  /// The default type of change detection, always checking for changes.
  ///
  /// When an asynchronous event (such as user interaction or an RPC) occurs
  /// within the app, the root component of the app is checked for changes,
  /// and then all children in a depth-first search.
  static const Default = 0;

  @Deprecated('Not intended to be a public API. Use "OnPush"')
  static const CheckOnce = ChangeDetectionCheckedState.checkOnce;

  @Deprecated('Not intended to be a public API. Use "OnPush"')
  static const Checked = ChangeDetectionCheckedState.waitingForMarkForCheck;

  @Deprecated('Not intended to be a public API. Use "Default"')
  static const CheckAlways = ChangeDetectionCheckedState.checkAlways;

  @Deprecated('Not intended to be a public API. Use "ChangeDetectorRef.detach"')
  static const Detached = ChangeDetectionCheckedState.waitingToBeAttached;

  /// An optimized form of change detection, skipping some checks for changes.
  ///
  /// Unlike [Default], [OnPush] waits for the following signals to check:
  /// * An `@Input()` being changed.
  /// * An `@Output()` or event listener (i.e. `(click)="..."`) being executed.
  /// * A call to `<ChangeDetectorRef>.markForCheck()`.
  ///
  /// Otherwise, change detection is skipped for this component. An [OnPush]
  /// configured component as a result can afford to be a bit less defensive
  /// about caching the result of bindings, for example.
  ///
  /// **WARNING**: It is currently _undefined behavior_ to have a [Default]
  /// configured component as a child (or directive) of a component that is
  /// using [OnPush]. We hope to introduce more guidance here in the future.
  static const OnPush = 5;

  static const _prettyStrings = <int, String>{
    Default: 'Default',
    OnPush: 'OnPush',
  };

  static toPrettyString(int strategy) {
    if (_prettyStrings.containsKey(strategy)) {
      return _prettyStrings[strategy];
    }
    // When internal change detection strategies are banned from the
    // public API, this code will be unreachable.
    return 'Internal';
  }
}

/// **TRANSITIONAL**: These are runtime internal states to the `AppView`.
///
/// TODO(b/128441899): Refactor into a change detection state machine.
class ChangeDetectionCheckedState {
  /// `AppView.detectChanges` should be invoked once.
  ///
  /// The next state is [waitingForMarkForCheck].
  static const checkOnce = 1;

  /// `AppView.detectChanges` should bail out.
  ///
  /// Upon use of `AppView.markForCheck`, the next state is [checkOnce].
  static const waitingForMarkForCheck = 2;

  /// `AppView.detectChanges` should always be invoked.
  static const checkAlways = 3;

  /// `AppView.detectChanges` should bail out.
  ///
  /// Attaching a view should transition to either [checkOnce] or [checkAlways]
  /// depending on whether `OnPush` or `Default` change detection strategies are
  /// configured for the view.
  static const waitingToBeAttached = 4;
}
