import "package:angular2/core.dart" show Directive, ElementRef, Provider;

import "control_value_accessor.dart"
    show NG_VALUE_ACCESSOR, ControlValueAccessor;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;

const DEFAULT_VALUE_ACCESSOR = const Provider(NG_VALUE_ACCESSOR,
    useExisting: DefaultValueAccessor, multi: true);

/// The default accessor for writing a value and listening to changes that is used by the
/// [NgModel], [NgFormControl], and [NgControlName] directives.
///
/// ### Example
///     <input type="text" ngControl="searchQuery">
@Directive(
    selector:
        "input:not([type=checkbox])[ngControl],textarea[ngControl],input:not([type=checkbox])[ngFormControl],textarea[ngFormControl],input:not([type=checkbox])[ngModel],textarea[ngModel],[ngDefaultControl]",
    host: const {
      "(input)": "onChange(\$event.target.value)",
      "(blur)": "onTouched()"
    },
    providers: const [
      DEFAULT_VALUE_ACCESSOR
    ])
class DefaultValueAccessor implements ControlValueAccessor {
  ElementRef _elementRef;
  var onChange = (dynamic _) {};
  var onTouched = () {};
  DefaultValueAccessor(this._elementRef);
  @override
  void writeValue(dynamic value) {
    var normalizedValue = value ?? '';
    DOM.setProperty(_elementRef.nativeElement, 'value', normalizedValue);
  }

  @override
  void registerOnChange(void fn(dynamic _)) {
    this.onChange = fn;
  }

  @override
  void registerOnTouched(void fn()) {
    this.onTouched = fn;
  }
}
