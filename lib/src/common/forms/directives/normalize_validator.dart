import 'package:angular2/src/common/forms/directives/validators.dart'
    show AsyncValidatorFn, Validator, ValidatorFn;

ValidatorFn normalizeValidator(dynamic validator) {
  if (validator is Validator) {
    return (c) => validator.validate(c);
  } else {
    return validator as ValidatorFn;
  }
}

AsyncValidatorFn normalizeAsyncValidator(validatorOrFunction) {
  if (validatorOrFunction is Validator) {
    return (c) => validatorOrFunction.validate(c);
  } else {
    return validatorOrFunction;
  }
}
