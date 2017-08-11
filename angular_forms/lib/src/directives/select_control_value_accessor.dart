import 'dart:html';

import 'package:func/func.dart' show Func0, VoidFunc1;
import 'package:angular/angular.dart'
    show Directive, Provider, ElementRef, Input, OnDestroy, Host, Optional;
import 'package:angular/src/facade/lang.dart' show isPrimitive, looseIdentical;

import 'control_value_accessor.dart'
    show NG_VALUE_ACCESSOR, ControlValueAccessor;

const SELECT_VALUE_ACCESSOR = const Provider(NG_VALUE_ACCESSOR,
    useExisting: SelectControlValueAccessor, multi: true);
String _buildValueString(String id, dynamic value) {
  if (id == null) return '$value';
  if (!isPrimitive(value)) value = 'Object';
  var s = '$id: $value';
  // TODO: Fix this magic maximum 50 characters (from TS-transpile).
  if (s.length > 50) {
    s = s.substring(0, 50);
  }
  return s;
}

String _extractId(String valueString) => valueString.split(':')[0];

/// The accessor for writing a value and listening to changes on a select
/// element.
///
/// Note: We have to listen to the 'change' event because 'input' events aren't
/// fired for selects in Firefox and IE:
/// https://bugzilla.mozilla.org/show_bug.cgi?id=1024350
/// https://developer.microsoft.com/en-us/microsoft-edge/platform/issues/4660045
@Directive(
    selector: 'select[ngControl],select[ngFormControl],select[ngModel]',
    host: const {
      '(change)': 'onChange(\$event.target.value)',
      '(blur)': 'touchHandler()'
    },
    providers: const [
      SELECT_VALUE_ACCESSOR
    ])
class SelectControlValueAccessor implements ControlValueAccessor {
  final ElementRef _elementRef;
  dynamic value;
  final Map<String, dynamic> _optionMap = new Map<String, dynamic>();
  num _idCounter = 0;
  VoidFunc1 onChange = (dynamic _) {};

  void touchHandler() {
    onTouched();
  }

  Func0 onTouched = () {};
  SelectControlValueAccessor(this._elementRef);

  @override
  void writeValue(dynamic value) {
    this.value = value;
    var valueString = _buildValueString(_getOptionId(value), value);
    SelectElement elm = _elementRef.nativeElement;
    elm.value = valueString;
  }

  @override
  void registerOnChange(dynamic fn(dynamic value)) {
    onChange = (String valueString) {
      fn(_getOptionValue(valueString));
    };
  }

  @override
  void registerOnTouched(dynamic fn()) {
    onTouched = fn;
  }

  String _registerOption() => (_idCounter++).toString();

  String _getOptionId(dynamic value) {
    for (var id in _optionMap.keys) {
      if (looseIdentical(_optionMap[id], value)) return id;
    }
    return null;
  }

  dynamic _getOptionValue(String valueString) {
    var value = _optionMap[_extractId(valueString)];
    return value ?? valueString;
  }
}

/// Marks `<option>` as dynamic, so Angular can be notified when options change.
///
/// ### Example
///
///     <select ngControl="city">
///       <option *ngFor="let c of cities" [value]="c"></option>
///     </select>
@Directive(selector: 'option')
class NgSelectOption implements OnDestroy {
  final ElementRef _element;
  SelectControlValueAccessor _select;
  String id;
  NgSelectOption(this._element, @Optional() @Host() this._select) {
    if (_select != null) id = _select._registerOption();
  }

  @Input('ngValue')
  set ngValue(dynamic value) {
    if (_select == null) return;
    _select._optionMap[id] = value;
    _setElementValue(_buildValueString(id, value));
    _select.writeValue(_select.value);
  }

  @Input('value')
  set value(dynamic value) {
    _setElementValue(value);
    if (_select != null) _select.writeValue(_select.value);
  }

  void _setElementValue(String value) {
    OptionElement elm = _element.nativeElement;
    elm.value = value;
  }

  @override
  void ngOnDestroy() {
    if (_select != null) {
      (_select._optionMap.containsKey(id) &&
          (_select._optionMap.remove(id) != null || true));
      _select.writeValue(_select.value);
    }
  }
}
