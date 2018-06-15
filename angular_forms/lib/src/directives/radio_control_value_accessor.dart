import 'dart:html';
import 'dart:js_util' as js_util;

import 'package:angular/angular.dart';
import 'package:angular_forms/src/directives/shared.dart'
    show setElementDisabled;

import 'control_value_accessor.dart'
    show ChangeHandler, ControlValueAccessor, ngValueAccessor, TouchHandler;
import 'ng_control.dart' show NgControl;

const RADIO_VALUE_ACCESSOR = ExistingProvider.forToken(
  ngValueAccessor,
  RadioControlValueAccessor,
);

/// Internal class used by Angular to uncheck radio buttons with the matching
/// name.
@Injectable()
class RadioControlRegistry {
  final List<dynamic> _accessors = [];
  void add(NgControl control, RadioControlValueAccessor accessor) {
    _accessors.add([control, accessor]);
  }

  void remove(RadioControlValueAccessor accessor) {
    var indexToRemove = -1;
    for (var i = 0; i < _accessors.length; ++i) {
      if (identical(_accessors[i][1], accessor)) {
        indexToRemove = i;
      }
    }
    _accessors.removeAt(indexToRemove);
  }

  void select(RadioControlValueAccessor accessor) {
    for (var c in _accessors) {
      if (identical(c[0].control.root, accessor._control.control.root) &&
          !identical(c[1], accessor)) {
        c[1].fireUncheck();
      }
    }
  }
}

/// The value provided by the forms API for radio buttons.
class RadioButtonState {
  final bool checked;
  final String value;

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
  selector: 'input[type=radio][ngControl],'
      'input[type=radio][ngFormControl],'
      'input[type=radio][ngModel]',
  providers: [RADIO_VALUE_ACCESSOR],
)
class RadioControlValueAccessor extends Object
    with TouchHandler, ChangeHandler<RadioButtonState>
    implements ControlValueAccessor<RadioButtonState>, OnDestroy, OnInit {
  final HtmlElement _element;
  final RadioControlRegistry _registry;
  final Injector _injector;
  RadioButtonState _state;
  NgControl _control;

  @Input()
  String name;

  RadioControlValueAccessor(this._element, this._registry, this._injector);

  @HostListener('change')
  void changeHandler() {
    onChange(RadioButtonState(true, _state.value), rawValue: _state.value);
    _registry.select(this);
  }

  @override
  void ngOnInit() {
    _control = _injector.get(NgControl);
    _registry.add(_control, this);
  }

  @override
  void ngOnDestroy() {
    _registry.remove(this);
  }

  @override
  void writeValue(RadioButtonState value) {
    _state = value;
    if (value?.checked ?? false) {
      js_util.setProperty(_element, 'checked', true);
    }
  }

  void fireUncheck() {
    onChange(RadioButtonState(false, _state.value), rawValue: _state.value);
  }

  @override
  void onDisabledChanged(bool isDisabled) {
    setElementDisabled(_element, isDisabled);
  }
}
