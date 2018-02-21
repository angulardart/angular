import 'validators.dart' show Validator, ValidatorFn;

ValidatorFn normalizeValidator(dynamic validator) {
  if (validator is Validator) {
    return (c) => validator.validate(c);
  } else if (validator is Function) {
    return validator as ValidatorFn;
  } else {
    return validator.call as ValidatorFn;
  }
}
