import "package:angular2/core.dart"
    show Directive, ElementRef, Renderer, Provider;

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
  Renderer _renderer;
  ElementRef _elementRef;
  var onChange = (_) {};
  var onTouched = () {};
  NumberValueAccessor(this._renderer, this._elementRef);
  void writeValue(value) {
    this
        ._renderer
        .setElementProperty(this._elementRef.nativeElement, "value", value);
  }

  void registerOnChange(dynamic fn) {
    this.onChange = (value) {
      fn(value == "" ? null : double.parse(value));
    };
  }

  void registerOnTouched(dynamic fn) {
    this.onTouched = fn;
  }
}
