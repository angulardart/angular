import 'dart:html';

import 'package:angular/core.dart' show Directive, ElementRef, Provider;

import 'control_value_accessor.dart'
    show ChangeFunction, ControlValueAccessor, NG_VALUE_ACCESSOR, TouchFunction;

const NUMBER_VALUE_ACCESSOR = const Provider(NG_VALUE_ACCESSOR,
    useExisting: NumberValueAccessor, multi: true);

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
  final ElementRef _elementRef;
  dynamic Function(dynamic) onChange = (_) {};
  void touchHandler() {
    onTouched();
  }

  TouchFunction onTouched = () {};
  NumberValueAccessor(this._elementRef);
  @override
  void writeValue(value) {
    InputElement elm = _elementRef.nativeElement;
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
