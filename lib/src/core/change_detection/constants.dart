/// Describes the current state of the change detector.
enum ChangeDetectorState {
  /// [NeverChecked] means that the change detector has not been checked yet,
  /// and initialization methods should be called during detection.
  NeverChecked,

  /// [CheckedBefore] means that the change detector has successfully completed
  /// at least one detection previously.
  CheckedBefore,

  /// [Errored] means that the change detector encountered an error checking a
  /// binding or calling a directive lifecycle method and is now in an
  /// inconsistent state. Change detectors in this state will no longer detect
  /// changes.
  Errored
}

/// Describes within the change detector which strategy will be used the next
/// time change detection is triggered.
enum ChangeDetectionStrategy {
  /// After calling detectChanges the mode of the change detector will become
  /// `Checked`.
  CheckOnce,

  /// The change detector should be skipped until its mode changes to
  /// `CheckOnce`.
  Checked,

  /// After calling detectChanges the mode of the change detector will remain
  /// `CheckAlways`.
  CheckAlways,

  /// The change detector sub tree is not a part of the main tree and should be
  /// skipped.
  Detached,

  /// The change detector's mode will be set to `CheckOnce` during hydration.
  OnPush,

  /// The component manages state itself and explicitly calls setState to
  /// notify Angular to update template.
  Stateful,

  /// The change detector's mode will be set to `CheckAlways` during hydration.
  Default
}

bool isDefaultChangeDetectionStrategy(
    ChangeDetectionStrategy changeDetectionStrategy) {
  return changeDetectionStrategy == null ||
      identical(changeDetectionStrategy, ChangeDetectionStrategy.Default);
}
