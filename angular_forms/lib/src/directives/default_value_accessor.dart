import 'dart:html';
import 'dart:js_util' as js_util;

import 'package:func/func.dart' show VoidFunc0, VoidFunc1;
import 'package:angular/angular.dart' show Directive, Provider;

import 'control_value_accessor.dart';

const DEFAULT_VALUE_ACCESSOR = const Provider(NG_VALUE_ACCESSOR,
    useExisting: DefaultValueAccessor, multi: true);

/// The default accessor for writing a value and listening to changes that is used by the
/// [NgModel], [NgFormControl], and [NgControlName] directives.
///
/// ### Example
///     <input type="text" ngControl="searchQuery">
@Directive(
    selector: 'input:not([type=checkbox])[ngControl],'
        'textarea[ngControl],'
        'input:not([type=checkbox])[ngFormControl],'
        'textarea[ngFormControl],'
        'input:not([type=checkbox])[ngModel],'
        'textarea[ngModel],[ngDefaultControl]',
    host: const {
      '(input)': 'onChange(\$event.target.value)',
      '(blur)': 'touchHandler()'
    },
    providers: const [
      DEFAULT_VALUE_ACCESSOR
    ])
class DefaultValueAccessor implements ControlValueAccessor {
  HtmlElement _elementRef;
  VoidFunc1 onChange = (dynamic _) {};
  void touchHandler() {
    onTouched();
  }

  VoidFunc0 onTouched = () {};
  DefaultValueAccessor(this._elementRef);
  @override
  void writeValue(dynamic value) {
    var normalizedValue = value ?? '';
    js_util.setProperty(_elementRef, 'value', normalizedValue);
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
