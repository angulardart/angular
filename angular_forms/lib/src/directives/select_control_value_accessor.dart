import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/src/facade/lang.dart' show isPrimitive;

import 'control_value_accessor.dart'
    show ChangeHandler, ControlValueAccessor, ngValueAccessor, TouchHandler;

const SELECT_VALUE_ACCESSOR = ExistingProvider.forToken(
  ngValueAccessor,
  SelectControlValueAccessor,
);

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
  providers: [SELECT_VALUE_ACCESSOR],
  // SelectControlValueAccessor must be visible to NgSelectOption.
  visibility: Visibility.all,
)
class SelectControlValueAccessor extends Object
    with TouchHandler, ChangeHandler
    implements ControlValueAccessor {
  final SelectElement _element;
  dynamic value;
  final Map<String, dynamic> _optionMap = Map<String, dynamic>();
  num _idCounter = 0;

  SelectControlValueAccessor(HtmlElement element)
      : _element = element as SelectElement;

  @HostListener('change', ['\$event.target.value'])
  void handleChange(String value) {
    onChange(_getOptionValue(value), rawValue: value);
  }

  @override
  void writeValue(dynamic value) {
    this.value = value;
    var valueString = _buildValueString(_getOptionId(value), value);
    _element.value = valueString;
  }

  @override
  void onDisabledChanged(bool isDisabled) {
    _element.disabled = isDisabled;
  }

  String _registerOption() => (_idCounter++).toString();

  String _getOptionId(dynamic value) {
    for (var id in _optionMap.keys) {
      if (identical(_optionMap[id], value)) return id;
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
@Directive(
  selector: 'option',
)
class NgSelectOption implements OnDestroy {
  final OptionElement _element;
  final SelectControlValueAccessor _select;
  String id;
  NgSelectOption(HtmlElement element, @Optional() @Host() this._select)
      : _element = element as OptionElement {
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
    _element.value = value;
  }

  @override
  void ngOnDestroy() {
    if (_select != null) {
      _select._optionMap.containsKey(id) &&
          (_select._optionMap.remove(id) != null || true);
      _select.writeValue(_select.value);
    }
  }
}
