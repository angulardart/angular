import 'dart:html';

import 'package:angular/angular.dart';

import 'control_value_accessor.dart'
    show ChangeHandler, ControlValueAccessor, ngValueAccessor, TouchHandler;

const NUMBER_VALUE_ACCESSOR = ExistingProvider.forToken(
  ngValueAccessor,
  NumberValueAccessor,
);

/// The accessor for writing a number value and listening to changes that is used by the
/// [NgModel], [NgFormControl], and [NgControlName] directives.
///
///  ### Example
///
///  <input type="number" [(ngModel)]="age">
@Directive(
  selector: 'input[type=number][ngControl],'
      'input[type=number][ngFormControl],'
      'input[type=number][ngModel]',
  providers: [NUMBER_VALUE_ACCESSOR],
)
class NumberValueAccessor extends Object
    with TouchHandler, ChangeHandler<double>
    implements ControlValueAccessor {
  final InputElement _element;

  NumberValueAccessor(HtmlElement element) : _element = element as InputElement;

  @HostListener('change', ['\$event.target.value'])
  @HostListener('input', ['\$event.target.value'])
  void handleChange(String value) {
    onChange(value == '' ? null : double.parse(value), rawValue: value);
  }

  @override
  void writeValue(value) {
    _element.value = '$value';
  }

  @override
  void onDisabledChanged(bool isDisabled) {
    _element.disabled = isDisabled;
  }
}
