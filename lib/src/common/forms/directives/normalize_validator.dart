import 'validators.dart' show Validator, ValidatorFn;

ValidatorFn normalizeValidator(dynamic validator) {
  if (validator is Validator) {
    return (c) => validator.validate(c);
  } else {
    return validator as ValidatorFn;
  }
}
