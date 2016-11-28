import 'dart:html';

import "package:angular2/core.dart" show Directive, ElementRef, Provider;

import "control_value_accessor.dart"
    show NG_VALUE_ACCESSOR, ControlValueAccessor;

const CHECKBOX_VALUE_ACCESSOR = const Provider(NG_VALUE_ACCESSOR,
    useExisting: CheckboxControlValueAccessor, multi: true);

/// The accessor for writing a value and listening to changes on a checkbox input element.
///
/// ### Example
///     <input type="checkbox" ngControl="rememberLogin">
@Directive(
    selector:
        "input[type=checkbox][ngControl],input[type=checkbox][ngFormControl],input[type=checkbox][ngModel]",
    host: const {
      "(change)": "onChange(\$event.target.checked)",
      "(blur)": "onTouched()"
    },
    providers: const [
      CHECKBOX_VALUE_ACCESSOR
    ])
class CheckboxControlValueAccessor implements ControlValueAccessor {
  final ElementRef _elementRef;
  var onChange = (dynamic _) {};
  var onTouched = () {};
  CheckboxControlValueAccessor(this._elementRef);
  @override
  void writeValue(dynamic value) {
    InputElement elm = this._elementRef.nativeElement;
    elm.checked = value;
  }

  @override
  void registerOnChange(dynamic fn) {
    this.onChange = fn;
  }

  @override
  void registerOnTouched(dynamic fn) {
    this.onTouched = fn;
  }
}
