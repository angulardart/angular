import "package:angular2/core.dart"
    show
        Directive,
        Renderer,
        Provider,
        ElementRef,
        Input,
        Host,
        OnDestroy,
        Optional;
import "package:angular2/src/facade/lang.dart" show isPrimitive, looseIdentical;

import "control_value_accessor.dart"
    show NG_VALUE_ACCESSOR, ControlValueAccessor;

const SELECT_VALUE_ACCESSOR = const Provider(NG_VALUE_ACCESSOR,
    useExisting: SelectControlValueAccessor, multi: true);
String _buildValueString(String id, dynamic value) {
  if (id == null) return '${value}';
  if (!isPrimitive(value)) value = "Object";
  var s = '${id}: ${value}';
  // TODO: Fix this magic maximum 50 characters (from TS-transpile).
  if (s.length > 50) {
    s = s.substring(0, 50);
  }
  return s;
}

String _extractId(String valueString) {
  return valueString.split(":")[0];
}

/// The accessor for writing a value and listening to changes on a select
/// element.
///
/// Note: We have to listen to the 'change' event because 'input' events aren't
/// fired for selects in Firefox and IE:
/// https://bugzilla.mozilla.org/show_bug.cgi?id=1024350
/// https://developer.microsoft.com/en-us/microsoft-edge/platform/issues/4660045
@Directive(
    selector: "select[ngControl],select[ngFormControl],select[ngModel]",
    host: const {
      "(change)": "onChange(\$event.target.value)",
      "(blur)": "onTouched()"
    },
    providers: const [
      SELECT_VALUE_ACCESSOR
    ])
class SelectControlValueAccessor implements ControlValueAccessor {
  Renderer _renderer;
  ElementRef _elementRef;
  dynamic value;
  Map<String, dynamic> _optionMap = new Map<String, dynamic>();
  num _idCounter = 0;
  var onChange = (dynamic _) {};
  var onTouched = () {};
  SelectControlValueAccessor(this._renderer, this._elementRef);
  void writeValue(dynamic value) {
    this.value = value;
    var valueString = _buildValueString(this._getOptionId(value), value);
    this._renderer.setElementProperty(
        this._elementRef.nativeElement, "value", valueString);
  }

  void registerOnChange(dynamic fn(dynamic value)) {
    this.onChange = (String valueString) {
      fn(this._getOptionValue(valueString));
    };
  }

  void registerOnTouched(dynamic fn()) {
    this.onTouched = fn;
  }

  String _registerOption() {
    return (this._idCounter++).toString();
  }

  String _getOptionId(dynamic value) {
    for (var id in _optionMap.keys) {
      if (looseIdentical(this._optionMap[id], value)) return id;
    }
    return null;
  }

  dynamic _getOptionValue(String valueString) {
    var value = this._optionMap[_extractId(valueString)];
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
@Directive(selector: "option")
class NgSelectOption implements OnDestroy {
  ElementRef _element;
  Renderer _renderer;
  SelectControlValueAccessor _select;
  String id;
  NgSelectOption(
      this._element, this._renderer, @Optional() @Host() this._select) {
    if (_select != null) this.id = this._select._registerOption();
  }
  @Input("ngValue")
  set ngValue(dynamic value) {
    if (this._select == null) return;
    this._select._optionMap[this.id] = value;
    this._setElementValue(_buildValueString(this.id, value));
    this._select.writeValue(this._select.value);
  }

  @Input("value")
  set value(dynamic value) {
    this._setElementValue(value);
    if (_select != null) this._select.writeValue(this._select.value);
  }

  void _setElementValue(String value) {
    this
        ._renderer
        .setElementProperty(this._element.nativeElement, "value", value);
  }

  void ngOnDestroy() {
    if (_select != null) {
      (this._select._optionMap.containsKey(this.id) &&
          (this._select._optionMap.remove(this.id) != null || true));
      this._select.writeValue(this._select.value);
    }
  }
}
