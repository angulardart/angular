import 'dart:async';

import "package:angular2/src/facade/async.dart" show EventEmitter;

import "directives/validators.dart" show ValidatorFn, AsyncValidatorFn;

/// Indicates that a Control is valid, i.e. that no errors exist in the input
/// value.
const VALID = "VALID";

/// Indicates that a Control is invalid, i.e. that an error exists in the input
/// value.
const INVALID = "INVALID";

/// Indicates that a Control is pending, i.e. that async validation is occurring
/// and errors are not yet available for the input value.
const PENDING = "PENDING";
bool isControl(Object control) {
  return control is AbstractControl;
}

AbstractControl _find(AbstractControl control,
    dynamic /* List< dynamic /* String | num */ > | String */ path) {
  if (path == null) return null;
  if (!(path is List)) {
    path = ((path as String)).split("/");
  }
  if (path is List && path.isEmpty) return null;
  return ((path as List<dynamic /* String | num */ >)).fold(control, (v, name) {
    if (v is ControlGroup) {
      return v.controls[name];
    } else if (v is ControlArray) {
      var index = (name as num);
      return v.at(index);
    } else {
      return null;
    }
  });
}

Stream<dynamic> _toStream(futureOrStream) {
  return futureOrStream is Future ? futureOrStream.asStream() : futureOrStream;
}

abstract class AbstractControl {
  ValidatorFn validator;
  AsyncValidatorFn asyncValidator;
  dynamic _value;
  EventEmitter<dynamic> _valueChanges;
  EventEmitter<dynamic> _statusChanges;
  String _status;
  Map<String, dynamic> _errors;
  bool _pristine = true;
  bool _touched = false;
  dynamic /* ControlGroup | ControlArray */ _parent;
  dynamic _asyncValidationSubscription;
  AbstractControl(this.validator, this.asyncValidator);
  dynamic get value {
    return this._value;
  }

  String get status {
    return this._status;
  }

  bool get valid {
    return identical(this._status, VALID);
  }

  /// Returns the errors of this control.
  Map<String, dynamic> get errors {
    return this._errors;
  }

  bool get pristine {
    return this._pristine;
  }

  bool get dirty {
    return !this.pristine;
  }

  bool get touched {
    return this._touched;
  }

  bool get untouched {
    return !this._touched;
  }

  Stream<dynamic> get valueChanges {
    return this._valueChanges;
  }

  Stream<dynamic> get statusChanges {
    return this._statusChanges;
  }

  bool get pending {
    return this._status == PENDING;
  }

  void markAsTouched() {
    this._touched = true;
  }

  void markAsDirty({bool onlySelf}) {
    onlySelf = onlySelf == true;
    this._pristine = false;
    if (_parent != null && !onlySelf) {
      this._parent.markAsDirty(onlySelf: onlySelf);
    }
  }

  void markAsPending({bool onlySelf}) {
    onlySelf = onlySelf == true;
    this._status = PENDING;
    if (_parent != null && !onlySelf) {
      this._parent.markAsPending(onlySelf: onlySelf);
    }
  }

  void setParent(dynamic /* ControlGroup | ControlArray */ parent) {
    this._parent = parent;
  }

  void updateValueAndValidity({bool onlySelf, bool emitEvent}) {
    onlySelf = onlySelf == true;
    emitEvent = emitEvent ?? true;
    this._updateValue();
    this._errors = this._runValidator();
    this._status = this._calculateStatus();
    if (this._status == VALID || this._status == PENDING) {
      this._runAsyncValidator(emitEvent);
    }
    if (emitEvent) {
      this._valueChanges.add(this._value);
      this._statusChanges.add(this._status);
    }
    if (_parent != null && !onlySelf) {
      this
          ._parent
          .updateValueAndValidity(onlySelf: onlySelf, emitEvent: emitEvent);
    }
  }

  Map<String, dynamic> _runValidator() {
    return validator != null ? validator(this) : null;
  }

  void _runAsyncValidator(bool emitEvent) {
    if (asyncValidator != null) {
      this._status = PENDING;
      this._cancelExistingSubscription();
      var obs = _toStream(this.asyncValidator(this));
      this._asyncValidationSubscription = obs.listen(
          (Map<String, dynamic> res) =>
              this.setErrors(res, emitEvent: emitEvent));
    }
  }

  void _cancelExistingSubscription() {
    _asyncValidationSubscription?.cancel();
  }

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
    this._errors = errors;
    this._status = this._calculateStatus();
    if (emitEvent) {
      this._statusChanges.add(this._status);
    }
    _parent?._updateControlsErrors();
  }

  AbstractControl find(
      dynamic /* List< dynamic /* String | num */ > | String */ path) {
    return _find(this, path);
  }

  getError(String errorCode, [List<String> path]) {
    AbstractControl control = this;
    if (path != null && path.isNotEmpty) {
      control = find(path);
    }
    if (control == null || control._errors == null) {
      return null;
    }
    return control._errors[errorCode];
  }

  bool hasError(String errorCode, [List<String> path = null]) {
    return this.getError(errorCode, path) != null;
  }

  AbstractControl get root {
    AbstractControl x = this;
    while (x._parent != null) {
      x = x._parent;
    }
    return x;
  }

  void _updateControlsErrors() {
    _status = this._calculateStatus();
    _parent?._updateControlsErrors();
  }

  void _initObservables() {
    this._valueChanges = new EventEmitter();
    this._statusChanges = new EventEmitter();
  }

  String _calculateStatus() {
    if (_errors != null) return INVALID;
    if (this._anyControlsHaveStatus(PENDING)) return PENDING;
    if (this._anyControlsHaveStatus(INVALID)) return INVALID;
    return VALID;
  }

  void _updateValue();
  bool _anyControlsHaveStatus(String status);
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
class Control extends AbstractControl {
  Function _onChange;
  Control(
      [dynamic value = null,
      ValidatorFn validator = null,
      AsyncValidatorFn asyncValidator = null])
      : super(validator, asyncValidator) {
    //// super call moved to initializer */;
    this._value = value;
    this.updateValueAndValidity(onlySelf: true, emitEvent: false);
    this._initObservables();
  }

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
  void updateValue(dynamic value,
      {bool onlySelf, bool emitEvent, bool emitModelToViewChange}) {
    emitModelToViewChange = emitModelToViewChange ?? true;
    this._value = value;
    if (_onChange != null && emitModelToViewChange) this._onChange(this._value);
    this.updateValueAndValidity(onlySelf: onlySelf, emitEvent: emitEvent);
  }

  void _updateValue() {}

  bool _anyControlsHaveStatus(String status) {
    return false;
  }

  /// Register a listener for change events.
  void registerOnChange(Function fn) {
    this._onChange = fn;
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
class ControlGroup extends AbstractControl {
  Map<String, AbstractControl> controls;
  Map<String, bool> _optionals;
  ControlGroup(this.controls,
      [Map<String, bool> optionals = null,
      ValidatorFn validator = null,
      AsyncValidatorFn asyncValidator = null])
      : super(validator, asyncValidator) {
    this._optionals = optionals ?? {};
    this._initObservables();
    this._setParentForControls();
    this.updateValueAndValidity(onlySelf: true, emitEvent: false);
  }

  /// Add a control to this group.
  void addControl(String name, AbstractControl control) {
    this.controls[name] = control;
    control.setParent(this);
  }

  /// Remove a control from this group.
  void removeControl(String name) {
    controls.remove(name);
  }

  /// Mark the named control as non-optional.
  void include(String controlName) {
    _optionals[controlName] = true;
    updateValueAndValidity();
  }

  /// Mark the named control as optional.
  void exclude(String controlName) {
    _optionals[controlName] = false;
    updateValueAndValidity();
  }

  /// Check whether there is a control with the given name in the group.
  bool contains(String controlName) =>
      controls.containsKey(controlName) && _included(controlName);

  void _setParentForControls() {
    for (var control in controls.values) {
      control.setParent(this);
    }
  }

  void _updateValue() {
    this._value = this._reduceValue();
  }

  bool _anyControlsHaveStatus(String status) {
    return controls.keys.any((name) {
      return contains(name) && controls[name].status == status;
    });
  }

  Map<String, dynamic> _reduceValue() {
    return this._reduceChildren(<String, dynamic>{},
        (Map<String, dynamic> acc, AbstractControl control, String name) {
      acc[name] = control.value;
      return acc;
    });
  }

  Map<String, dynamic> _reduceChildren(
      Map<String, dynamic> initValue,
      Map<String, dynamic> fn(
          Map<String, dynamic> acc, AbstractControl control, String name)) {
    var res = initValue;
    controls.forEach((name, control) {
      if (_included(name)) {
        res = fn(res, control, name);
      }
    });
    return res;
  }

  bool _included(String controlName) => _optionals[controlName] != false;
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
class ControlArray extends AbstractControl {
  List<AbstractControl> controls;
  ControlArray(this.controls,
      [ValidatorFn validator = null, AsyncValidatorFn asyncValidator = null])
      : super(validator, asyncValidator) {
    this._initObservables();
    this._setParentForControls();
    this.updateValueAndValidity(onlySelf: true, emitEvent: false);
  }

  /// Get the [AbstractControl] at the given `index` in the list.
  AbstractControl at(num index) {
    return this.controls[index];
  }

  /// Insert a new [AbstractControl] at the end of the array.
  void push(AbstractControl control) {
    this.controls.add(control);
    control.setParent(this);
    this.updateValueAndValidity();
  }

  /// Insert a new [AbstractControl] at the given `index` in the array.
  void insert(num index, AbstractControl control) {
    controls.insert(index, control);
    control.setParent(this);
    this.updateValueAndValidity();
  }

  /// Remove the control at the given `index` in the array.
  void removeAt(num index) {
    controls.removeAt(index);
    this.updateValueAndValidity();
  }

  /// Length of the control array.
  num get length {
    return this.controls.length;
  }

  void _updateValue() {
    this._value = this.controls.map((control) => control.value).toList();
  }

  bool _anyControlsHaveStatus(String status) {
    return this.controls.any((c) => c.status == status);
  }

  void _setParentForControls() {
    this.controls.forEach((control) {
      control.setParent(this);
    });
  }
}
