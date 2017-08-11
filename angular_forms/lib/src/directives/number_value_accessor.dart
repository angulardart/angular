import 'dart:html';

import 'package:angular/angular.dart' show Directive, Provider;

import 'control_value_accessor.dart'
    show ChangeFunction, ControlValueAccessor, NG_VALUE_ACCESSOR, TouchFunction;

const NUMBER_VALUE_ACCESSOR = const Provider(NG_VALUE_ACCESSOR,
    useExisting: NumberValueAccessor, multi: true);

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
    providers: const [
      NUMBER_VALUE_ACCESSOR
    ])
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
