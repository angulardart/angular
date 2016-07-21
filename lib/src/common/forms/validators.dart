import "package:angular2/core.dart" show OpaqueToken;
import "package:angular2/src/facade/async.dart" show ObservableWrapper;
import "package:angular2/src/facade/collection.dart" show StringMapWrapper;
import "package:angular2/src/facade/lang.dart"
    show isBlank, isPresent, isString;
import "package:angular2/src/facade/promise.dart" show PromiseWrapper;

import "directives/validators.dart" show ValidatorFn, AsyncValidatorFn;
import "model.dart" as modelModule;

/**
 * Providers for validators to be used for [Control]s in a form.
 *
 * Provide this using `multi: true` to add validators.
 *
 * ### Example
 *
 * {@example core/forms/ts/ng_validators/ng_validators.ts region='ng_validators'}
 */
const OpaqueToken NG_VALIDATORS = const OpaqueToken("NgValidators");
/**
 * Providers for asynchronous validators to be used for [Control]s
 * in a form.
 *
 * Provide this using `multi: true` to add validators.
 *
 * See [NG_VALIDATORS] for more details.
 */
const OpaqueToken NG_ASYNC_VALIDATORS = const OpaqueToken("NgAsyncValidators");

/**
 * Provides a set of validators used by form controls.
 *
 * A validator is a function that processes a [Control] or collection of
 * controls and returns a map of errors. A null map means that validation has passed.
 *
 * ### Example
 *
 * ```typescript
 * var loginControl = new Control("", Validators.required)
 * ```
 */
class Validators {
  /**
   * Validator that requires controls to have a non-empty value.
   */
  static Map<String, bool> required(modelModule.AbstractControl control) {
    return isBlank(control.value) ||
            (isString(control.value) && control.value == "")
        ? {"required": true}
        : null;
  }

  /**
   * Validator that requires controls to have a value of a minimum length.
   */
  static ValidatorFn minLength(num minLength) {
    return /* Map < String , dynamic > */ (modelModule
        .AbstractControl control) {
      if (isPresent(Validators.required(control))) return null;
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

  /**
   * Validator that requires controls to have a value of a maximum length.
   */
  static ValidatorFn maxLength(num maxLength) {
    return /* Map < String , dynamic > */ (modelModule
        .AbstractControl control) {
      if (isPresent(Validators.required(control))) return null;
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

  /**
   * Validator that requires a control to match a regex to its value.
   */
  static ValidatorFn pattern(String pattern) {
    return /* Map < String , dynamic > */ (modelModule
        .AbstractControl control) {
      if (isPresent(Validators.required(control))) return null;
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

  /**
   * No-op validator.
   */
  static Map<String, bool> nullValidator(modelModule.AbstractControl c) {
    return null;
  }

  /**
   * Compose multiple validators into a single function that returns the union
   * of the individual error maps.
   */
  static ValidatorFn compose(List<ValidatorFn> validators) {
    if (isBlank(validators)) return null;
    var presentValidators = validators.where(isPresent).toList();
    if (presentValidators.length == 0) return null;
    return (modelModule.AbstractControl control) {
      return _mergeErrors(_executeValidators(control, presentValidators));
    };
  }

  static AsyncValidatorFn composeAsync(List<AsyncValidatorFn> validators) {
    if (isBlank(validators)) return null;
    var presentValidators = validators.where(isPresent).toList();
    if (presentValidators.length == 0) return null;
    return (modelModule.AbstractControl control) {
      var promises = _executeAsyncValidators(control, presentValidators)
          .map(_convertToPromise)
          .toList();
      return PromiseWrapper.all(promises).then(_mergeErrors);
    };
  }
}

dynamic _convertToPromise(dynamic obj) {
  return PromiseWrapper.isPromise(obj) ? obj : ObservableWrapper.toPromise(obj);
}

List<dynamic> _executeValidators(
    modelModule.AbstractControl control, List<ValidatorFn> validators) {
  return validators.map((v) => v(control)).toList();
}

List<dynamic> _executeAsyncValidators(
    modelModule.AbstractControl control, List<AsyncValidatorFn> validators) {
  return validators.map((v) => v(control)).toList();
}

Map<String, dynamic> _mergeErrors(List<dynamic> arrayOfErrors) {
  Map<String, dynamic> res = arrayOfErrors.fold({},
      (Map<String, dynamic> res, Map<String, dynamic> errors) {
    return isPresent(errors) ? StringMapWrapper.merge(res, errors) : res;
  });
  return StringMapWrapper.isEmpty(res) ? null : res;
}
