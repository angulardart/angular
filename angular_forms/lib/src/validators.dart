import 'package:angular/angular.dart';

import 'directives/validators.dart' show ValidatorFn;
import 'model.dart' as model_module;

///  Providers for validators to be used for [Control]s in a form.
///
///  Provide this using `multi: true` to add validators.
const NG_VALIDATORS = MultiToken<dynamic>('NgValidators');

///  Provides a set of validators used by form controls.
///
///  A validator is a function that processes a [Control] or collection of
///  controls and returns a map of errors. A null map means that validation has
///  passed.
///
///  ### Example
///
/// ```dart
/// Control loginControl = new Control("", Validators.required)
/// ```
class Validators {
  ///  Validator that requires controls to have a non-empty value.
  static Map<String, bool> required(model_module.AbstractControl control) {
    return control.value == null || control.value == ''
        ? {'required': true}
        : null;
  }

  ///  Validator that requires controls to have a value of a minimum length.
  static ValidatorFn minLength(num minLength) {
    return /* Map < String , dynamic > */ (model_module.AbstractControl
        control) {
      if (Validators.required(control) != null) return null;
      String v = control.value;
      return v.length < minLength
          ? {
              'minlength': {
                'requiredLength': minLength,
                'actualLength': v.length
              }
            }
          : null;
    };
  }

  ///  Validator that requires controls to have a value of a maximum length.
  static ValidatorFn maxLength(num maxLength) {
    return /* Map < String , dynamic > */ (model_module.AbstractControl
        control) {
      if (Validators.required(control) != null) return null;
      String v = control.value;
      return v.length > maxLength
          ? {
              'maxlength': {
                'requiredLength': maxLength,
                'actualLength': v.length
              }
            }
          : null;
    };
  }

  ///  Validator that requires a control to match a regex to its value.
  static ValidatorFn pattern(String pattern) {
    return /* Map < String , dynamic > */ (model_module.AbstractControl
        control) {
      if (Validators.required(control) != null) return null;
      var regex = RegExp('^$pattern\$');
      String v = control.value;
      return regex.hasMatch(v)
          ? null
          : {
              'pattern': {'requiredPattern': '^$pattern\$', 'actualValue': v}
            };
    };
  }

  ///  No-op validator.
  static Map<String, bool> nullValidator(model_module.AbstractControl c) =>
      null;

  ///  Compose multiple validators into a single function that returns the union
  ///  of the individual error maps.
  static ValidatorFn compose(List<ValidatorFn> validators) {
    if (validators == null) return null;
    final presentValidators = _removeNullValidators(validators);
    if (presentValidators.isEmpty) return null;
    return (model_module.AbstractControl control) {
      return _executeValidators(control, presentValidators);
    };
  }

  // TODO(tsander): Remove the need to filter the validation. The list of
  // validators should not contain null values.
  static List<T> _removeNullValidators<T>(List<T> validators) {
    final result = List<T>();
    for (var i = 0, len = validators.length; i < len; i++) {
      var validator = validators[i];
      if (validator != null) result.add(validator);
    }
    return result;
  }
}

Map<String, dynamic> _executeValidators(
    model_module.AbstractControl control, List<ValidatorFn> validators) {
  var result = Map<String, dynamic>();
  for (var i = 0, len = validators.length; i < len; i++) {
    final validator = validators[i];
    assert(validator != null, 'Validator should be non-null');
    final localResult = validator(control);
    if (localResult != null) result.addAll(localResult);
  }
  return result.isEmpty ? null : result;
}
