import 'dart:html';

import 'package:angular/angular.dart';

import 'control_value_accessor.dart'
    show ChangeHandler, ControlValueAccessor, NG_VALUE_ACCESSOR, TouchHandler;

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
  providers: const [CHECKBOX_VALUE_ACCESSOR],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  void onDisabledChanged(bool isDisabled) {}
}
