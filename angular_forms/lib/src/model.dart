import 'dart:async';

import 'package:meta/meta.dart';

import 'directives/validators.dart' show ValidatorFn;

AbstractControl _find(AbstractControl control, List<String> path) {
  if (path == null || path.isEmpty) return null;
  return path.fold(control, (v, name) {
    if (v is AbstractControlGroup) {
      return v.controls[name];
    } else if (v is ControlArray) {
      var index = int.parse(name);
      return v.at(index);
    } else {
      return null;
    }
  });
}

@optionalTypeArgs
abstract class AbstractControl<T> {
  /// Indicates that a Control is valid, i.e. that no errors exist in the input
  /// value.
  static const VALID = 'VALID';

  /// Indicates that a Control is invalid, i.e. that an error exists in the
  /// input value.
  static const INVALID = 'INVALID';

  /// Indicates that a Control is pending, i.e. that async validation is
  /// occurring and errors are not yet available for the input value.
  static const PENDING = 'PENDING';

  /// Indicates that a FormControl is disabled, i.e. that the control is exempt
  /// from ancestor calculations of validity or value.
  static const DISABLED = 'DISABLED';

  ValidatorFn validator;
  T _value;
  final _valueChanges = StreamController<T>.broadcast();
  final _statusChanges = StreamController<String>.broadcast();
  final _disabledChanges = StreamController<bool>.broadcast();
  String _status;
  Map<String, dynamic> _errors;
  bool _pristine = true;
  bool _touched = false;
  AbstractControl _parent;

  AbstractControl(this.validator, {value}) : _value = value {
    updateValueAndValidity(onlySelf: true, emitEvent: false);
  }

  T get value => _value;

  /// The validation status of the control.
  String get status => _status;

  bool get valid => _status == VALID;

  bool get invalid => _status == INVALID;

  bool get disabled => _status == DISABLED;

  bool get enabled => !disabled;

  /// Returns the errors of this control.
  Map<String, dynamic> get errors => _errors;

  bool get pristine => _pristine;

  bool get dirty => !pristine;

  bool get touched => _touched;

  bool get untouched => !_touched;

  Stream<T> get valueChanges => _valueChanges.stream;

  Stream<String> get statusChanges => _statusChanges.stream;

  Stream<bool> get disabledChanges => _disabledChanges.stream;

  bool get pending => _status == PENDING;

  /// Marks the control as `touched`.
  ///
  /// This will also mark all direct ancestors as `touched` to maintain the
  /// model.
  void markAsTouched({bool updateParent}) {
    updateParent = updateParent ?? true;

    _touched = true;

    if (_parent != null && updateParent) {
      _parent.markAsTouched(updateParent: updateParent);
    }
  }

  /// Marks the control as `untouched`.
  ///
  /// If the control has any children, it will also mark all children as
  /// `untouched` to maintain the model, and re-calculate the `touched` status
  /// of all parent controls.
  void markAsUntouched({bool updateParent}) {
    updateParent = updateParent ?? true;
    _touched = false;

    _forEachChild(
        // Only set self, so that children don't try to update their parent,
        // and thus create a loop of updates.
        (c) => c.markAsUntouched(updateParent: false));

    if (_parent != null && updateParent) {
      _parent._updateTouched(updateParent: updateParent);
    }
  }

  /// Mark the control as `dirty`.
  ///
  /// This will also mark all direct ancestors as `dirty` to maintain the model.
  void markAsDirty({bool onlySelf, bool emitEvent}) {
    onlySelf = onlySelf == true;
    emitEvent = emitEvent ?? true;
    _pristine = false;
    if (emitEvent) _statusChanges.add(_status);
    if (_parent != null && !onlySelf) {
      _parent.markAsDirty(onlySelf: onlySelf);
    }
  }

  /// Marks the control as `pristine`.
  ///
  /// If the control has any children, it will also mark all children as
  /// `pristine` to maintain the model, and re-calculate the `pristine` status
  /// of all parent controls.
  void markAsPristine({bool updateParent}) {
    updateParent = updateParent ?? true;
    _pristine = true;

    _forEachChild(
        // Only set self, so that children don't try to update their parent,
        // and thus create a loop of updates.
        (c) => c.markAsPristine(updateParent: false));

    if (_parent != null && updateParent) {
      _parent._updatePristine(updateParent: updateParent);
    }
  }

  void markAsPending({bool onlySelf}) {
    onlySelf = onlySelf == true;
    _status = PENDING;
    if (_parent != null && !onlySelf) {
      _parent.markAsPending(onlySelf: onlySelf);
    }
  }

  /// Disables the control. This means the control will be exempt from
  /// validation checks and excluded from the aggregate value of any
  /// parent. Its status is `DISABLED`.
  ///
  /// If the control has children, all children will be disabled to
  /// maintain the model.
  void markAsDisabled({bool updateParent, bool emitEvent}) {
    updateParent = updateParent ?? true;
    emitEvent = emitEvent ?? true;

    _status = DISABLED;

    _forEachChild(
        // Only set self, so that children don't try to update their parent,
        // and thus create a loop of updates.
        (c) => c.markAsDisabled(updateParent: false, emitEvent: emitEvent));
    onUpdate();

    if (emitEvent) _emitEvent();

    _updateAncestors(updateParent: updateParent, emitEvent: emitEvent);
    _disabledChanges.add(true);
  }

  /// Enables the control. This means the control will be included in
  /// validation checks and the aggregate value of its parent. Its
  /// status is re-calculated based on its value and its validators.
  ///
  /// If the control has children, all children will be enabled.
  void markAsEnabled({bool updateParent, bool emitEvent}) {
    updateParent = updateParent ?? true;
    emitEvent = emitEvent ?? true;
    _status = VALID;
    _forEachChild(
        // Only set self, so that children don't try to update their parent,
        // and thus create a loop of updates.
        (c) => c.markAsEnabled(updateParent: false, emitEvent: emitEvent));
    updateValueAndValidity(onlySelf: true, emitEvent: emitEvent);
    _updateAncestors(updateParent: updateParent, emitEvent: emitEvent);
    _disabledChanges.add(false);
  }

  /// Resets the form control.
  ///
  /// This means by default:
  /// * it is marked as `pristine`
  /// * it is marked as `untouched`
  /// * value is set to null
  ///
  /// You can also reset to a specific form state by passing through a
  /// standalone value or a disabled state. We allow setting value and
  /// disabled here because these are the only two properties that
  /// cannot be calculated.
  void reset({T value, bool isDisabled, bool updateParent, bool emitEvent}) {
    updateParent ??= true;
    emitEvent ??= true;

    updateValue(value, onlySelf: !updateParent, emitEvent: emitEvent);
    if (isDisabled != null) {
      isDisabled
          ? markAsDisabled(updateParent: updateParent, emitEvent: emitEvent)
          : markAsEnabled(updateParent: updateParent, emitEvent: emitEvent);
    }
    markAsPristine(updateParent: updateParent);
    markAsUntouched(updateParent: updateParent);
  }

  void _updateAncestors({bool updateParent, bool emitEvent}) {
    if (_parent != null && updateParent) {
      _parent.updateValueAndValidity(
          onlySelf: !updateParent, emitEvent: emitEvent);
      // TODO(alorenzen): Update parent pristine and touched.
    }
  }

  void setParent(AbstractControl parent) {
    _parent = parent;
  }

  // TODO(alorenzen): Consider renaming `onlySelf` to `updateParent`.
  void updateValueAndValidity({bool onlySelf, bool emitEvent}) {
    onlySelf = onlySelf == true;
    emitEvent = emitEvent ?? true;
    onUpdate();
    _errors = _runValidator();
    _status = _calculateStatus();
    if (emitEvent) _emitEvent();
    if (_parent != null && !onlySelf) {
      _parent.updateValueAndValidity(onlySelf: onlySelf, emitEvent: emitEvent);
    }
  }

  void _emitEvent() {
    _valueChanges.add(value);
    _statusChanges.add(_status);
  }

  Map<String, dynamic> _runValidator() =>
      validator != null ? validator(this) : null;

  /// Sets errors on a control.
  ///
  /// This is used when validations are run not automatically, but manually by
  /// the user.
  ///
  /// Calling `setErrors` will also update the validity of the parent control.
  ///
  /// ## Usage
  ///
  /// ```dart
  /// Control login = new Control("someLogin");
  /// login.setErrors({
  ///   "notUnique": true
  /// });
  ///
  /// expect(login.valid).toEqual(false);
  /// expect(login.errors).toEqual({"notUnique": true});
  ///
  /// login.updateValue("someOtherLogin");
  ///
  /// expect(login.valid).toEqual(true);
  /// ```
  void setErrors(Map<String, dynamic> errors, {bool emitEvent}) {
    emitEvent = emitEvent ?? true;
    _errors = errors;
    _status = _calculateStatus();
    if (emitEvent) {
      _statusChanges.add(_status);
    }
    _parent?._updateControlsErrors();
    // If a control's errors were specifically set then mark the control as
    // changed.
    markAsDirty(emitEvent: false);
  }

  /// Walks the path supplied to find matching control.
  ///
  /// Uses `/` as a deliminator.
  ///
  /// If no match is found, returns null.
  AbstractControl find(String path) => findPath(path?.split('/'));

  /// Walks the path to find the matching control.
  ///
  /// If no match is found, returns null.
  ///
  /// For [ControlGroups], matches on name. For [ControlArray], it parses an int
  /// to match on index.
  AbstractControl findPath(List<String> path) => _find(this, path);

  getError(String errorCode, [List<String> path]) {
    AbstractControl control = this;
    if (path != null && path.isNotEmpty) {
      control = findPath(path);
    }
    if (control == null || control._errors == null) {
      return null;
    }
    return control._errors[errorCode];
  }

  bool hasError(String errorCode, [List<String> path]) =>
      getError(errorCode, path) != null;

  AbstractControl get root {
    AbstractControl x = this;
    while (x._parent != null) {
      x = x._parent;
    }
    return x;
  }

  void _updateControlsErrors() {
    _status = _calculateStatus();
    _parent?._updateControlsErrors();
  }

  String _calculateStatus() {
    if (_allControlsHaveStatus(DISABLED)) return DISABLED;
    if (_errors != null) return INVALID;
    if (_anyControlsHaveStatus(PENDING)) return PENDING;
    if (_anyControlsHaveStatus(INVALID)) return INVALID;
    return VALID;
  }

  void _updateTouched({bool updateParent}) {
    _touched = _anyControlsTouched();

    if (_parent != null && updateParent) {
      _parent._updateTouched(updateParent: updateParent);
    }
  }

  void _updatePristine({bool updateParent}) {
    _pristine = !_anyControlsDirty();

    if (_parent != null && updateParent) {
      _parent._updatePristine(updateParent: updateParent);
    }
  }

  /// Set the value of the AbstractControl to `value`.
  ///
  /// If `onlySelf` is `true`, this change will only affect the validation of
  /// this `Control` and not its parent component. This defaults to `false`.
  ///
  /// If `emitEvent` is `true`, this change will cause a `valueChanges` event on
  /// the `Control` to be emitted. This is the default behavior.
  ///
  /// If `emitModelToViewChange` is `true`, the view will be notified about the
  /// new value via an `onChange` event. This is the default behavior if
  /// `emitModelToViewChange` is not specified.
  void updateValue(T value,
      {bool onlySelf,
      bool emitEvent,
      bool emitModelToViewChange,
      String rawValue});

  /// Callback when control is asked to update it's value.
  ///
  /// Allows controls to calculate their value. For example control groups
  /// to calculate it's value based on their children.
  @protected
  void onUpdate();

  bool _anyControlsHaveStatus(String status) =>
      _anyControls((c) => c.status == status);
  bool _allControlsHaveStatus(String status);
  bool _anyControlsTouched() => _anyControls((c) => c.touched);
  bool _anyControlsDirty() => _anyControls((c) => c.dirty);

  void _forEachChild(void callback(AbstractControl c));

  bool _anyControls(bool condition(AbstractControl c));
}

/// Defines a part of a form that cannot be divided into other controls.
/// `Control`s have values and validation state, which is determined by an
/// optional validation function.
///
/// `Control` is one of the three fundamental building blocks used to define
/// forms in Angular, along with [ControlGroup] and [ControlArray].
///
/// ## Usage
///
/// By default, a `Control` is created for every `<input>` or other form
/// component.
/// With [NgFormControl] or [NgFormModel] an existing [Control] can be
/// bound to a DOM element instead. This `Control` can be configured with a
/// custom validation function.
@optionalTypeArgs
class Control<T> extends AbstractControl<T> {
  Function _onChange;
  String _rawValue;

  Control([dynamic value, ValidatorFn validator])
      : super(validator, value: value);

  /// Set the value of the control to `value`.
  ///
  /// If `onlySelf` is `true`, this change will only affect the validation of
  /// this `Control` and not its parent component. If `emitEvent` is `true`,
  /// this change will cause a `valueChanges` event on the `Control` to be
  /// emitted. Both of these options default to `false`.
  ///
  /// If `emitModelToViewChange` is `true`, the view will be notified about the
  /// new value via an `onChange` event. This is the default behavior if
  /// `emitModelToViewChange` is not specified.
  @override
  void updateValue(T value,
      {bool onlySelf,
      bool emitEvent,
      bool emitModelToViewChange,
      String rawValue}) {
    emitModelToViewChange = emitModelToViewChange ?? true;
    _value = value;
    _rawValue = rawValue;
    if (_onChange != null && emitModelToViewChange) _onChange(_value);
    updateValueAndValidity(onlySelf: onlySelf, emitEvent: emitEvent);
  }

  /// If [value] was coerced from a HTML element this is the original value from
  /// that element.
  ///
  /// This allows validators to validate either the raw value which was provided
  /// by HTML, or the coerced value that was provided by the accessor.
  String get rawValue => _rawValue;

  @override
  void onUpdate() {}

  @override
  bool _anyControls(_) => false;

  @override
  bool _allControlsHaveStatus(String status) => this.status == status;

  @override
  void _forEachChild(void callback(AbstractControl c)) {}

  /// Register a listener for change events.
  ///
  /// Used internally to connect the model with the [ValueAccessor] which will
  /// write the model value to the View.
  /// NOTE: Should only be called internally by angular. Use [valueChanges] or
  /// [statusChanges] to get updates on the [Control].
  void registerOnChange(Function fn) {
    _onChange = fn;
  }
}

/// Defines a part of a form, of fixed length, that can contain other controls.
///
/// A `ControlGroup` aggregates the values of each [Control] in the group.
/// The status of a `ControlGroup` depends on the status of its children.
/// If one of the controls in a group is invalid, the entire group is invalid.
/// Similarly, if a control changes its value, the entire group changes as well.
///
/// `ControlGroup` is one of the three fundamental building blocks used to
/// define forms in Angular, along with [Control] and [ControlArray].
/// [ControlArray] can also contain other controls, but is of variable length.
class ControlGroup extends AbstractControlGroup<Map<String, dynamic>> {
  ControlGroup(Map<String, AbstractControl> controls, [ValidatorFn validator])
      : super(controls, validator);

  @override
  void updateValue(Map<String, dynamic> value,
      {bool onlySelf,
      bool emitEvent,
      bool emitModelToViewChange,
      String rawValue}) {
    // Treat null and empty as the same thing.
    if (value?.isEmpty ?? false) value = null;
    _checkAllValuesPresent(value);
    for (var name in controls.keys) {
      controls[name].updateValue(value == null ? null : value[name],
          onlySelf: true,
          emitEvent: emitEvent,
          emitModelToViewChange: emitModelToViewChange);
    }
    updateValueAndValidity(onlySelf: onlySelf, emitEvent: emitEvent);
  }

  @override
  void onUpdate() {
    _value = _reduceValue();
  }

  Map<String, dynamic> _reduceValue() {
    final res = <String, dynamic>{};
    for (var name in controls.keys) {
      if (included(name) || disabled) {
        res[name] = controls[name].value;
      }
    }
    return res;
  }

  void _checkAllValuesPresent(Map<String, dynamic> value) {
    if (value == null) return;

    assert(() {
      for (var name in controls.keys) {
        if (!value.containsKey(name)) {
          throw ArgumentError.value(
              value, 'Must supply a value for form control with name: $name.');
        }
      }
      for (var name in value.keys) {
        if (!controls.containsKey(name)) {
          throw ArgumentError.value(
              value, 'No form control found with name: $name.');
        }
      }
      return true;
    }());
  }
}

/// Generic control group that allows creating your own group that is backed
/// by a value that is not a Map.
@optionalTypeArgs
abstract class AbstractControlGroup<T> extends AbstractControl<T> {
  final Map<String, AbstractControl> controls;

  AbstractControlGroup(this.controls, [ValidatorFn validator])
      : super(validator) {
    _setParentForControls(this, controls.values);
  }

  /// Add a control to this group.
  void addControl(String name, AbstractControl control) {
    controls[name] = control;
    control.setParent(this);
  }

  /// Remove a control from this group.
  void removeControl(String name) {
    controls.remove(name);
  }

  /// Check whether there is a control with the given name in the group.
  bool contains(String controlName) =>
      controls.containsKey(controlName) && controls[controlName].enabled;

  @override
  bool _anyControls(bool condition(AbstractControl c)) {
    for (var name in controls.keys) {
      if (contains(name) && condition(controls[name])) return true;
    }
    return false;
  }

  @override
  bool _allControlsHaveStatus(String status) {
    if (controls.isEmpty) return this.status == status;

    for (var name in controls.keys) {
      if (controls[name].status != status) return false;
    }
    return true;
  }

  @override
  void _forEachChild(void callback(AbstractControl c)) {
    for (var control in controls.values) {
      callback(control);
    }
  }

  @protected
  bool included(String controlName) => controls[controlName]?.enabled ?? false;
}

/// Defines a part of a form, of variable length, that can contain other
/// controls.
///
/// A `ControlArray` aggregates the values of each [Control] in the group.
/// The status of a `ControlArray` depends on the status of its children.
/// If one of the controls in a group is invalid, the entire array is invalid.
/// Similarly, if a control changes its value, the entire array changes as well.
///
/// `ControlArray` is one of the three fundamental building blocks used to
/// define forms in Angular, along with [Control] and [ControlGroup].
/// [ControlGroup] can also contain other controls, but is of fixed length.
///
/// ## Adding or removing controls
///
/// To change the controls in the array, use the `push`, `insert`, or `removeAt`
/// methods in `ControlArray` itself. These methods ensure the controls are
/// properly tracked in the form's hierarchy. Do not modify the array of
/// `AbstractControl`s used to instantiate the `ControlArray` directly, as that
/// will result in strange and unexpected behavior such as broken change
/// detection.
class ControlArray extends AbstractControl<List> {
  List<AbstractControl> controls;

  ControlArray(this.controls, [ValidatorFn validator]) : super(validator) {
    _setParentForControls(this, controls);
  }

  /// Get the [AbstractControl] at the given `index` in the list.
  AbstractControl at(num index) => controls[index];

  /// Insert a new [AbstractControl] at the end of the array.
  void push(AbstractControl control) {
    controls.add(control);
    control.setParent(this);
    updateValueAndValidity();
  }

  /// Insert a new [AbstractControl] at the given `index` in the array.
  void insert(num index, AbstractControl control) {
    controls.insert(index, control);
    control.setParent(this);
    updateValueAndValidity();
  }

  /// Remove the control at the given `index` in the array.
  void removeAt(num index) {
    controls.removeAt(index);
    updateValueAndValidity();
  }

  /// Length of the control array.
  num get length => controls.length;

  @override
  void updateValue(List value,
      {bool onlySelf,
      bool emitEvent,
      bool emitModelToViewChange,
      String rawValue}) {
    // Treat empty and null as the same.
    if (value?.isEmpty ?? false) value = null;
    _checkAllValuesPresent(value);
    for (int i = 0; i < controls.length; i++) {
      controls[i].updateValue(value == null ? null : value[i],
          onlySelf: true,
          emitEvent: emitEvent,
          emitModelToViewChange: emitModelToViewChange);
    }
    updateValueAndValidity(onlySelf: onlySelf, emitEvent: emitEvent);
  }

  @override
  void onUpdate() {
    _value = [];
    for (var control in controls) {
      if (control.enabled || disabled) {
        _value.add(control.value);
      }
    }
  }

  @override
  bool _anyControls(bool condition(AbstractControl c)) {
    for (var control in controls) {
      if (condition(control)) return true;
    }
    return false;
  }

  @override
  bool _allControlsHaveStatus(String status) {
    if (controls.isEmpty) return this.status == status;

    for (var control in controls) {
      if (control.status != status) return false;
    }
    return true;
  }

  @override
  void _forEachChild(void callback(AbstractControl c)) {
    for (var control in controls) {
      callback(control);
    }
  }

  void _checkAllValuesPresent(List value) {
    if (value == null) return;

    assert(() {
      if (value.length != controls.length) {
        throw ArgumentError.value(
            value,
            'ControlArray has ${controls.length} controls, but received a list '
            'of ${value.length} values.');
      }
      return true;
    }());
  }
}

void _setParentForControls(
    AbstractControl parent, Iterable<AbstractControl> children) {
  for (final control in children) {
    control.setParent(parent);
  }
}
