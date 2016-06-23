library angular2.src.common.forms.directives.number_value_accessor;

import "package:angular2/core.dart"
    show Directive, ElementRef, Renderer, Self, Provider;
import "control_value_accessor.dart"
    show NG_VALUE_ACCESSOR, ControlValueAccessor;
import "package:angular2/src/facade/lang.dart" show isBlank, NumberWrapper;

const NUMBER_VALUE_ACCESSOR = const Provider(NG_VALUE_ACCESSOR,
    useExisting: NumberValueAccessor, multi: true);

/**
 * The accessor for writing a number value and listening to changes that is used by the
 * [NgModel], [NgFormControl], and [NgControlName] directives.
 *
 *  ### Example
 *  ```
 *  <input type="number" [(ngModel)]="age">
 *  ```
 */
@Directive(
    selector:
        "input[type=number][ngControl],input[type=number][ngFormControl],input[type=number][ngModel]",
    host: const {
      "(change)": "onChange(\$event.target.value)",
      "(input)": "onChange(\$event.target.value)",
      "(blur)": "onTouched()"
    },
    bindings: const [
      NUMBER_VALUE_ACCESSOR
    ])
class NumberValueAccessor implements ControlValueAccessor {
  Renderer _renderer;
  ElementRef _elementRef;
  var onChange = (dynamic _) {};
  var onTouched = () {};
  NumberValueAccessor(this._renderer, this._elementRef) {}
  void writeValue(num value) {
    this
        ._renderer
        .setElementProperty(this._elementRef.nativeElement, "value", value);
  }

  void registerOnChange(void fn(num _)) {
    this.onChange = (value) {
      fn(value == "" ? null : NumberWrapper.parseFloat(value));
    };
  }

  void registerOnTouched(void fn()) {
    this.onTouched = fn;
  }
}
