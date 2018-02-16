import 'dart:html';

import 'package:angular/angular.dart';

import 'control_value_accessor.dart'
    show ChangeFunction, ControlValueAccessor, NG_VALUE_ACCESSOR, TouchFunction;

const CHECKBOX_VALUE_ACCESSOR = const ExistingProvider.forToken(
  NG_VALUE_ACCESSOR,
  CheckboxControlValueAccessor,
);

/// The accessor for writing a value and listening to changes on a checkbox input element.
///
/// ### Example
///
/// ```html
/// <input type="checkbox" ngControl="rememberLogin">
/// ```
@Directive(
  selector: 'input[type=checkbox][ngControl],'
      'input[type=checkbox][ngFormControl],'
      'input[type=checkbox][ngModel]',
  host: const {
    '(change)': 'onChange(\$event.target.checked)',
    '(blur)': 'touchHandler()'
  },
  providers: const [CHECKBOX_VALUE_ACCESSOR],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CheckboxControlValueAccessor implements ControlValueAccessor {
  final HtmlElement _elementRef;
  ChangeFunction onChange = (_, {String rawValue}) {};
  void touchHandler() {
    onTouched();
  }

  TouchFunction onTouched = () {};
  CheckboxControlValueAccessor(this._elementRef);
  @override
  void writeValue(dynamic value) {
    InputElement elm = _elementRef;
    elm.checked = value;
  }

  @override
  void registerOnChange(ChangeFunction fn) {
    onChange = fn;
  }

  @override
  void registerOnTouched(TouchFunction fn) {
    onTouched = fn;
  }
}
