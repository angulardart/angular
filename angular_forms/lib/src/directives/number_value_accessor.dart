import 'dart:html';

import 'package:angular/angular.dart';

import 'control_value_accessor.dart'
    show ChangeFunction, ControlValueAccessor, NG_VALUE_ACCESSOR, TouchFunction;

const NUMBER_VALUE_ACCESSOR = const ExistingProvider.forToken(
  NG_VALUE_ACCESSOR,
  NumberValueAccessor,
);

typedef dynamic _SimpleChangeFn(value);

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
  host: const {
    '(change)': 'onChange(\$event.target.value)',
    '(input)': 'onChange(\$event.target.value)',
    '(blur)': 'touchHandler()'
  },
  providers: const [NUMBER_VALUE_ACCESSOR],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NumberValueAccessor implements ControlValueAccessor {
  final HtmlElement _element;
  _SimpleChangeFn onChange = (_) {};
  void touchHandler() {
    onTouched();
  }

  TouchFunction onTouched = () {};
  NumberValueAccessor(this._element);
  @override
  void writeValue(value) {
    InputElement elm = _element;
    elm.value = '$value';
  }

  @override
  void registerOnChange(ChangeFunction fn) {
    onChange = (value) {
      // TODO(het): also provide rawValue to fn?
      fn(value == '' ? null : double.parse(value));
    };
  }

  @override
  void registerOnTouched(TouchFunction fn) {
    onTouched = fn;
  }
}
