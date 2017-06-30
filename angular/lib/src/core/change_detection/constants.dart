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
  /// After calling detectChanges the mode of the change detector will become
  /// `Checked`.
  static const int CheckOnce = 1;

  /// The change detector should be skipped until its mode changes to
  /// `CheckOnce`.
  static const int Checked = 2;

  /// After calling detectChanges the mode of the change detector will remain
  /// `CheckAlways`.
  static const int CheckAlways = 3;

  /// The change detector sub tree is not a part of the main tree and should be
  /// skipped.
  static const int Detached = 4;

  /// The change detector's mode will be set to `CheckOnce` during hydration.
  static const int OnPush = 5;

  /// The component manages state itself and explicitly calls setState to
  /// notify Angular to update template.
  static const int Stateful = 6;

  /// The change detector's mode will be set to `CheckAlways` during hydration.
  static const int Default = 0;
}

bool isDefaultChangeDetectionStrategy(int changeDetectionStrategy) {
  return changeDetectionStrategy == null ||
      changeDetectionStrategy == ChangeDetectionStrategy.Default;
}
