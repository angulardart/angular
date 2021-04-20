import 'dart:html';
import 'dart:js_util' as js_util;

import '../model.dart' show Control, AbstractControlGroup;
import '../validators.dart' show Validators;
import 'abstract_control_directive.dart' show AbstractControlDirective;
import 'checkbox_value_accessor.dart' show CheckboxControlValueAccessor;
import 'control_container.dart' show ControlContainer;
import 'control_value_accessor.dart' show ControlValueAccessor;
import 'default_value_accessor.dart' show DefaultValueAccessor;
import 'ng_control.dart' show NgControl;
import 'ng_control_group.dart' show NgControlGroup;
import 'normalize_validator.dart' show normalizeValidator;
import 'number_value_accessor.dart' show NumberValueAccessor;
import 'radio_control_value_accessor.dart' show RadioControlValueAccessor;
import 'select_control_value_accessor.dart' show SelectControlValueAccessor;
import 'validators.dart' show ValidatorFn;

List<String?> controlPath(String? name, ControlContainer parent) =>
    <String?>[...parent.path!, name];

void setUpControl(Control control, NgControl dir) {
  assert(
      dir.valueAccessor != null,
      'No value accessor for '
      '(${dir.path!.join(' -> ')}) or you may be missing formDirectives in '
      'your directives list.');
  control.validator = Validators.compose([control.validator, dir.validator]);
  var valueAccessor = dir.valueAccessor!;
  valueAccessor.writeValue(control.value);
  // view -> model
  valueAccessor.registerOnChange((dynamic newValue, {String? rawValue}) {
    dir.viewToModelUpdate(newValue);
    control.updateValue(newValue,
        emitModelToViewChange: false, rawValue: rawValue);
    control.markAsDirty(emitEvent: false);
  });
  // model -> view
  control.registerOnChange(
      (dynamic newValue) => dir.valueAccessor?.writeValue(newValue));
  control.disabledChanges.listen(valueAccessor.onDisabledChanged);
  if (control.disabled) valueAccessor.onDisabledChanged(control.disabled);
  // touched
  valueAccessor.registerOnTouched(() => control.markAsTouched());
}

void setUpControlGroup(AbstractControlGroup control, NgControlGroup dir) {
  control.validator = Validators.compose([control.validator, dir.validator]);
}

void _throwError(AbstractControlDirective? dir, String message) {
  var path = dir?.path;
  if (path != null) {
    message = "$message (${path.join(" -> ")})";
  }
  throw ArgumentError(message);
}

ValidatorFn? composeValidators(List<dynamic>? validators) {
  return validators != null
      ? Validators.compose(
          validators.map<ValidatorFn>(normalizeValidator).toList())
      : null;
}

ControlValueAccessor<dynamic>? selectValueAccessor(
  List<ControlValueAccessor<dynamic>>? valueAccessors,
) {
  if (valueAccessors == null) return null;
  ControlValueAccessor<dynamic>? defaultAccessor;
  ControlValueAccessor<dynamic>? builtinAccessor;
  ControlValueAccessor<dynamic>? customAccessor;
  for (var v in valueAccessors) {
    if (v is DefaultValueAccessor) {
      defaultAccessor = v;
    } else if (v is CheckboxControlValueAccessor ||
        v is NumberValueAccessor ||
        v is SelectControlValueAccessor ||
        v is RadioControlValueAccessor) {
      if (builtinAccessor != null) {
        _throwError(null, 'More than one built-in value accessor matches');
      }
      builtinAccessor = v;
    } else {
      if (customAccessor != null) {
        _throwError(null, 'More than one custom value accessor matches');
      }
      customAccessor = v;
    }
  }
  if (customAccessor != null) return customAccessor;
  if (builtinAccessor != null) return builtinAccessor;
  if (defaultAccessor != null) return defaultAccessor;
  _throwError(null, 'No valid value accessor for');
  return null;
}

void setElementDisabled(HtmlElement element, bool isDisabled) {
  js_util.setProperty(element, 'disabled', isDisabled);
}
