library angular2.src.core.change_detection.constants;

import "package:angular2/src/facade/lang.dart"
    show StringWrapper, normalizeBool, isBlank;

/**
 * Describes the current state of the change detector.
 */
enum ChangeDetectorState {
  /**
   * `NeverChecked` means that the change detector has not been checked yet, and
   * initialization methods should be called during detection.
   */
  NeverChecked,
  /**
   * `CheckedBefore` means that the change detector has successfully completed at least
   * one detection previously.
   */
  CheckedBefore,
  /**
   * `Errored` means that the change detector encountered an error checking a binding
   * or calling a directive lifecycle method and is now in an inconsistent state. Change
   * detectors in this state will no longer detect changes.
   */
  Errored
}
/**
 * Describes within the change detector which strategy will be used the next time change
 * detection is triggered.
 */
enum ChangeDetectionStrategy {
  /**
   * `CheckedOnce` means that after calling detectChanges the mode of the change detector
   * will become `Checked`.
   */
  CheckOnce,
  /**
   * `Checked` means that the change detector should be skipped until its mode changes to
   * `CheckOnce`.
   */
  Checked,
  /**
   * `CheckAlways` means that after calling detectChanges the mode of the change detector
   * will remain `CheckAlways`.
   */
  CheckAlways,
  /**
   * `Detached` means that the change detector sub tree is not a part of the main tree and
   * should be skipped.
   */
  Detached,
  /**
   * `OnPush` means that the change detector's mode will be set to `CheckOnce` during hydration.
   */
  OnPush,
  /**
   * `Default` means that the change detector's mode will be set to `CheckAlways` during hydration.
   */
  Default
}
/**
 * List of possible [ChangeDetectionStrategy] values.
 */
var CHANGE_DETECTION_STRATEGY_VALUES = [
  ChangeDetectionStrategy.CheckOnce,
  ChangeDetectionStrategy.Checked,
  ChangeDetectionStrategy.CheckAlways,
  ChangeDetectionStrategy.Detached,
  ChangeDetectionStrategy.OnPush,
  ChangeDetectionStrategy.Default
];
/**
 * List of possible [ChangeDetectorState] values.
 */
var CHANGE_DETECTOR_STATE_VALUES = [
  ChangeDetectorState.NeverChecked,
  ChangeDetectorState.CheckedBefore,
  ChangeDetectorState.Errored
];
bool isDefaultChangeDetectionStrategy(
    ChangeDetectionStrategy changeDetectionStrategy) {
  return isBlank(changeDetectionStrategy) ||
      identical(changeDetectionStrategy, ChangeDetectionStrategy.Default);
}
