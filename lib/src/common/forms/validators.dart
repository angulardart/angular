import 'dart:async';

import "package:angular2/di.dart" show OpaqueToken;

import "directives/validators.dart" show ValidatorFn, AsyncValidatorFn;
import "model.dart" as model_module;

///  Providers for validators to be used for [Control]s in a form.
///
///  Provide this using `multi: true` to add validators.
const OpaqueToken NG_VALIDATORS = const OpaqueToken("NgValidators");

///  Providers for asynchronous validators to be used for [Control]s
///  in a form.
///
///  Provide this using `multi: true` to add validators.
///
///  See [NG_VALIDATORS] for more details.
const OpaqueToken NG_ASYNC_VALIDATORS = const OpaqueToken("NgAsyncValidators");

///  Provides a set of validators used by form controls.
///
///  A validator is a function that processes a [Control] or collection of
///  controls and returns a map of errors. A null map means that validation has passed.
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
        ? {"required": true}
        : null;
  }

  ///  Validator that requires controls to have a value of a minimum length.
  static ValidatorFn minLength(num minLength) {
    return /* Map < String , dynamic > */ (model_module
        .AbstractControl control) {
      if (Validators.required(control) != null) return null;
      String v = control.value;
      return v.length < minLength
          ? {
              "minlength": {
                "requiredLength": minLength,
                "actualLength": v.length
              }
            }
          : null;
    };
  }

  ///  Validator that requires controls to have a value of a maximum length.
  static ValidatorFn maxLength(num maxLength) {
    return /* Map < String , dynamic > */ (model_module
        .AbstractControl control) {
      if (Validators.required(control) != null) return null;
      String v = control.value;
      return v.length > maxLength
          ? {
              "maxlength": {
                "requiredLength": maxLength,
                "actualLength": v.length
              }
            }
          : null;
    };
  }

  ///  Validator that requires a control to match a regex to its value.
  static ValidatorFn pattern(String pattern) {
    return /* Map < String , dynamic > */ (model_module
        .AbstractControl control) {
      if (Validators.required(control) != null) return null;
      var regex = new RegExp('''^${ pattern}\$''');
      String v = control.value;
      return regex.hasMatch(v)
          ? null
          : {
              "pattern": {
                "requiredPattern": '''^${ pattern}\$''',
                "actualValue": v
              }
            };
    };
  }

  ///  No-op validator.
  static Map<String, bool> nullValidator(model_module.AbstractControl c) {
    return null;
  }

  ///  Compose multiple validators into a single function that returns the union
  ///  of the individual error maps.
  static ValidatorFn compose(List<ValidatorFn> validators) {
    if (validators == null) return null;
    var presentValidators = validators.where((v) => v != null).toList();
    if (presentValidators.length == 0) return null;
    return (model_module.AbstractControl control) {
      return _mergeErrors(_executeValidators(control, presentValidators));
    };
  }

  static AsyncValidatorFn composeAsync(List<AsyncValidatorFn> validators) {
    if (validators == null) return null;
    var presentValidators = validators.where((v) => v != null).toList();
    if (presentValidators.length == 0) return null;
    return (model_module.AbstractControl control) {
      var promises =
          _executeAsyncValidators(control, presentValidators).map(_toFuture);
      return Future.wait(promises).then(_mergeErrors);
    };
  }
}

Future _toFuture(futureOrStream) {
  if (futureOrStream is Stream) {
    return futureOrStream.single;
  }
  return futureOrStream;
}

List<dynamic> _executeValidators(
    model_module.AbstractControl control, List<ValidatorFn> validators) {
  return validators.map((v) => v(control)).toList();
}

List<dynamic> _executeAsyncValidators(
    model_module.AbstractControl control, List<AsyncValidatorFn> validators) {
  return validators.map((v) => v(control)).toList();
}

Map<String, dynamic> _mergeErrors(List<dynamic> arrayOfErrors) {
  Map<String, dynamic> res = arrayOfErrors.fold({},
      (Map<String, dynamic> res, Map<String, dynamic> errors) {
    res.addAll(errors ?? const {});
    return res;
  });
  return res.isEmpty ? null : res;
}
