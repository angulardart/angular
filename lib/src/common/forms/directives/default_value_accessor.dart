import "package:angular2/core.dart" show Directive, ElementRef, Provider;

import 'dart:js_util' as js_util;
import 'control_value_accessor.dart';
import "control_value_accessor.dart"
    show NG_VALUE_ACCESSOR, ControlValueAccessor;

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
      "(blur)": "touchHandler()"
    },
    providers: const [
      DEFAULT_VALUE_ACCESSOR
    ])
class DefaultValueAccessor implements ControlValueAccessor {
  ElementRef _elementRef;
  var onChange = (dynamic _) {};
  void touchHandler() {
    onTouched();
  }

  var onTouched = () {};
  DefaultValueAccessor(this._elementRef);
  @override
  void writeValue(dynamic value) {
    var normalizedValue = value ?? '';
    js_util.setProperty(_elementRef.nativeElement, 'value', normalizedValue);
  }

  @override
  void registerOnChange(void fn(dynamic _, {String rawValue})) {
    this.onChange = (value) {
      fn(value, rawValue: value);
    };
  }

  @override
  void registerOnTouched(void fn()) {
    onTouched = fn;
  }
}
