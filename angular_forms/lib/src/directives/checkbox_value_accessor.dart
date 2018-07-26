import 'dart:html';

import 'package:angular/angular.dart';

import 'control_value_accessor.dart'
    show ChangeHandler, ControlValueAccessor, ngValueAccessor, TouchHandler;

const CHECKBOX_VALUE_ACCESSOR = ExistingProvider.forToken(
  ngValueAccessor,
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
  providers: [CHECKBOX_VALUE_ACCESSOR],
)
class CheckboxControlValueAccessor extends Object
    with TouchHandler, ChangeHandler<bool>
    implements ControlValueAccessor<bool> {
  final InputElement _element;

  CheckboxControlValueAccessor(HtmlElement element)
      : _element = element as InputElement;

  @HostListener('change', ['\$event.target.checked'])
  void handleChange(bool checked) {
    onChange(checked, rawValue: '$checked');
  }

  @override
  void writeValue(bool value) {
    _element.checked = value;
  }

  @override
  void onDisabledChanged(bool isDisabled) {
    _element.disabled = isDisabled;
  }
}
