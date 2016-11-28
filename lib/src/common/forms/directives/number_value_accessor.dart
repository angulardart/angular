import 'dart:html';
import "package:angular2/core.dart" show Directive, ElementRef, Provider;

import "control_value_accessor.dart"
    show NG_VALUE_ACCESSOR, ControlValueAccessor;

const NUMBER_VALUE_ACCESSOR = const Provider(NG_VALUE_ACCESSOR,
    useExisting: NumberValueAccessor, multi: true);

/// The accessor for writing a number value and listening to changes that is used by the
/// [NgModel], [NgFormControl], and [NgControlName] directives.
///
///  ### Example
///
///  <input type="number" [(ngModel)]="age">
@Directive(
    selector:
        "input[type=number][ngControl],input[type=number][ngFormControl],input[type=number][ngModel]",
    host: const {
      "(change)": "onChange(\$event.target.value)",
      "(input)": "onChange(\$event.target.value)",
      "(blur)": "onTouched()"
    },
    providers: const [
      NUMBER_VALUE_ACCESSOR
    ])
class NumberValueAccessor implements ControlValueAccessor {
  ElementRef _elementRef;
  var onChange = (_) {};
  var onTouched = () {};
  NumberValueAccessor(this._elementRef);
  @override
  void writeValue(value) {
    InputElement elm = _elementRef.nativeElement;
    elm.value = '$value';
  }

  @override
  void registerOnChange(dynamic fn) {
    this.onChange = (value) {
      fn(value == "" ? null : double.parse(value));
    };
  }

  @override
  void registerOnTouched(dynamic fn) {
    this.onTouched = fn;
  }
}
