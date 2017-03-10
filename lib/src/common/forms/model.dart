import 'dart:async';

import "package:angular2/src/facade/async.dart" show EventEmitter;

import "directives/validators.dart" show ValidatorFn, AsyncValidatorFn;

/// Indicates that a Control is valid, i.e. that no errors exist in the input
/// value.
@Deprecated('Use AbstractControl.VALID instead.')
const VALID = AbstractControl.VALID;

/// Indicates that a Control is invalid, i.e. that an error exists in the input
/// value.
@Deprecated('Use AbstractControl.INVALID instead.')
const INVALID = AbstractControl.INVALID;

/// Indicates that a Control is pending, i.e. that async validation is occurring
/// and errors are not yet available for the input value.
@Deprecated('Use AbstractControl.VALID instead.')
const PENDING = AbstractControl.PENDING;

bool isControl(Object control) => control is AbstractControl;

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
  /// Indicates that a Control is valid, i.e. that no errors exist in the input
  /// value.
  static const VALID = "VALID";

  /// Indicates that a Control is invalid, i.e. that an error exists in the
  /// input value.
  static const INVALID = "INVALID";

  /// Indicates that a Control is pending, i.e. that async validation is
  /// occurring and errors are not yet available for the input value.
  static const PENDING = "PENDING";

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
  dynamic get value => _value;

  /// The validation status of the control.
  ///
  /// One of [VALID], [INVALID], or [PENDING].
  String get status => _status;

  bool get valid => identical(_status, VALID);

  /// Returns the errors of this control.
  Map<String, dynamic> get errors => _errors;

  bool get pristine => _pristine;

  bool get dirty => !pristine;

  bool get touched => _touched;

  bool get untouched => !_touched;

  Stream<dynamic> get valueChanges => _valueChanges;

  Stream<dynamic> get statusChanges => _statusChanges;

  bool get pending => _status == PENDING;

  void markAsTouched() {
    _touched = true;
  }

  void markAsDirty({bool onlySelf, bool emitEvent}) {
    onlySelf = onlySelf == true;
    emitEvent = emitEvent ?? true;
    _pristine = false;
    if (emitEvent) _statusChanges.add(_status);
    if (_parent != null && !onlySelf) {
      _parent.markAsDirty(onlySelf: onlySelf);
    }
  }

  void markAsPending({bool onlySelf}) {
    onlySelf = onlySelf == true;
    _status = PENDING;
    if (_parent != null && !onlySelf) {
      _parent.markAsPending(onlySelf: onlySelf);
    }
  }

  void setParent(dynamic /* ControlGroup | ControlArray */ parent) {
    _parent = parent;
  }

  void updateValueAndValidity({bool onlySelf, bool emitEvent}) {
    onlySelf = onlySelf == true;
    emitEvent = emitEvent ?? true;
    _updateValue();
    _errors = _runValidator();
    _status = _calculateStatus();
    if (_status == VALID || _status == PENDING) {
      _runAsyncValidator(emitEvent);
    }
    if (emitEvent) {
      _valueChanges.add(_value);
      _statusChanges.add(_status);
    }
    if (_parent != null && !onlySelf) {
      this
          ._parent
          .updateValueAndValidity(onlySelf: onlySelf, emitEvent: emitEvent);
    }
  }

  Map<String, dynamic> _runValidator() =>
      validator != null ? validator(this) : null;

  void _runAsyncValidator(bool emitEvent) {
    if (asyncValidator != null) {
      _status = PENDING;
      _cancelExistingSubscription();
      var obs = _toStream(asyncValidator(this));
      _asyncValidationSubscription = obs.listen(
          (Map<String, dynamic> res) => setErrors(res, emitEvent: emitEvent));
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

  AbstractControl find(
          dynamic /* List< dynamic /* String | num */ > | String */ path) =>
      _find(this, path);

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

  bool hasError(String errorCode, [List<String> path = null]) =>
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

  void _initObservables() {
    _valueChanges = new EventEmitter();
    _statusChanges = new EventEmitter();
  }

  String _calculateStatus() {
    if (_errors != null) return INVALID;
    if (_anyControlsHaveStatus(PENDING)) return PENDING;
    if (_anyControlsHaveStatus(INVALID)) return INVALID;
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
  String _rawValue;
  Control(
      [dynamic value = null,
      ValidatorFn validator = null,
      AsyncValidatorFn asyncValidator = null])
      : super(validator, asyncValidator) {
    //// super call moved to initializer */;
    _value = value;
    updateValueAndValidity(onlySelf: true, emitEvent: false);
    _initObservables();
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
  void _updateValue() {}

  @override
  bool _anyControlsHaveStatus(String status) => false;

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
class ControlGroup extends AbstractControl {
  final Map<String, AbstractControl> controls;
  final Map<String, bool> _optionals;
  ControlGroup(this.controls,
      [Map<String, bool> optionals,
      ValidatorFn validator,
      AsyncValidatorFn asyncValidator])
      : _optionals = optionals ?? {},
        super(validator, asyncValidator) {
    _initObservables();
    _setParentForControls();
    updateValueAndValidity(onlySelf: true, emitEvent: false);
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

  @override
  void _updateValue() {
    _value = _reduceValue();
  }

  @override
  bool _anyControlsHaveStatus(String status) {
    return controls.keys.any((name) {
      return contains(name) && controls[name].status == status;
    });
  }

  Map<String, dynamic> _reduceValue() {
    return _reduceChildren(<String, dynamic>{},
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
    _initObservables();
    _setParentForControls();
    updateValueAndValidity(onlySelf: true, emitEvent: false);
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
  void _updateValue() {
    _value = controls.map((control) => control.value).toList();
  }

  @override
  bool _anyControlsHaveStatus(String status) =>
      controls.any((c) => c.status == status);

  void _setParentForControls() {
    controls.forEach((control) {
      control.setParent(this);
    });
  }
}
