import "package:angular2/core.dart"
    show
        Directive,
        ElementRef,
        Renderer,
        Provider,
        Input,
        OnInit,
        OnDestroy,
        Injector,
        Injectable;
import "package:angular2/src/common/forms/directives/control_value_accessor.dart"
    show NG_VALUE_ACCESSOR, ControlValueAccessor;
import "package:angular2/src/common/forms/directives/ng_control.dart"
    show NgControl;

const RADIO_VALUE_ACCESSOR = const Provider(NG_VALUE_ACCESSOR,
    useExisting: RadioControlValueAccessor, multi: true);

/// Internal class used by Angular to uncheck radio buttons with the matching
/// name.
@Injectable()
class RadioControlRegistry {
  List<dynamic> _accessors = [];
  void add(NgControl control, RadioControlValueAccessor accessor) {
    this._accessors.add([control, accessor]);
  }

  void remove(RadioControlValueAccessor accessor) {
    var indexToRemove = -1;
    for (var i = 0; i < this._accessors.length; ++i) {
      if (identical(this._accessors[i][1], accessor)) {
        indexToRemove = i;
      }
    }
    _accessors.removeAt(indexToRemove);
  }

  void select(RadioControlValueAccessor accessor) {
    this._accessors.forEach((c) {
      if (identical(c[0].control.root, accessor._control.control.root) &&
          !identical(c[1], accessor)) {
        c[1].fireUncheck();
      }
    });
  }
}

/// The value provided by the forms API for radio buttons.
class RadioButtonState {
  bool checked;
  String value;
  RadioButtonState(this.checked, this.value);
}

/// The accessor for writing a radio control value and listening to changes that
/// is used by the [NgModel], [NgFormControl], and [NgControlName] directives.
///
/// ### Example
///
/// ```dart
/// @Component(
///   template: '''
///     <input type="radio" name="food" [(ngModel)]="foodChicken">
///     <input type="radio" name="food" [(ngModel)]="foodFish">
///   '''
/// )
/// class FoodCmp {
///   RadioButtonState foodChicken = new RadioButtonState(true, "chicken");
///   RadioButtonState foodFish = new RadioButtonState(false, "fish");
/// }
/// ```
@Directive(
    selector:
        "input[type=radio][ngControl],input[type=radio][ngFormControl],input[type=radio][ngModel]",
    host: const {"(change)": "onChange()", "(blur)": "onTouched()"},
    providers: const [RADIO_VALUE_ACCESSOR])
class RadioControlValueAccessor
    implements ControlValueAccessor, OnDestroy, OnInit {
  Renderer _renderer;
  ElementRef _elementRef;
  RadioControlRegistry _registry;
  Injector _injector;
  RadioButtonState _state;
  NgControl _control;
  @Input()
  String name;
  Function _fn;
  var onChange = () {};
  var onTouched = () {};
  RadioControlValueAccessor(
      this._renderer, this._elementRef, this._registry, this._injector);
  void ngOnInit() {
    this._control = this._injector.get(NgControl);
    this._registry.add(this._control, this);
  }

  void ngOnDestroy() {
    this._registry.remove(this);
  }

  void writeValue(dynamic value) {
    this._state = value;
    if (value?.checked ?? false) {
      _renderer.setElementProperty(_elementRef.nativeElement, "checked", true);
    }
  }

  void registerOnChange(dynamic fn(dynamic _)) {
    this._fn = fn;
    this.onChange = () {
      fn(new RadioButtonState(true, this._state.value));
      this._registry.select(this);
    };
  }

  void fireUncheck() {
    this._fn(new RadioButtonState(false, this._state.value));
  }

  void registerOnTouched(dynamic fn()) {
    this.onTouched = fn;
  }
}
