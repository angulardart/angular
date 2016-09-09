import 'package:angular2/src/common/forms/directives/validators.dart'
    show Validator, ValidatorFn;

ValidatorFn normalizeValidator(dynamic validator) {
  if (validator is Validator) {
    return (c) => validator.validate(c);
  } else {
    return validator as ValidatorFn;
  }
}

Function normalizeAsyncValidator(dynamic validator) {
  if (validator is Validator) {
    return (c) => validator.validate(c);
  } else {
    return validator;
  }
}
