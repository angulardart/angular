import '../model.dart' show AbstractControl;

/// Base class for control directives.
///
/// Only used internally in the forms package.
abstract class AbstractControlDirective<T extends AbstractControl> {
  String name;

  T get control;

  dynamic get value => control?.value;

  bool get valid => control?.valid;

  bool get disabled => control?.disabled;

  bool get enabled => control?.enabled;

  Map<String, dynamic> get errors => control?.errors;

  bool get pristine => control?.pristine;

  bool get dirty => control?.dirty;

  bool get touched => control?.touched;

  bool get untouched => control?.untouched;

  List<String> get path => null;

  void toggleDisabled(bool isDisabled) {
    if (isDisabled && !control.disabled) control.markAsDisabled();
    if (!isDisabled && !control.enabled) control.markAsEnabled();
  }

  /// Resets the form control.
  ///
  /// This means by default:
  /// * it is marked as `pristine`
  /// * it is marked as `untouched`
  /// * value is set to null
  ///
  /// For more information, see `AbstractControl`.
  void reset({value}) {
    control?.reset(value: value);
  }
}
