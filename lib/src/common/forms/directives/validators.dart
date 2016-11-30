import 'dart:async';

import "package:angular2/core.dart" show Provider, Attribute, Directive;

import "../model.dart" show AbstractControl;
import "../validators.dart" show Validators, NG_VALIDATORS;

/// An interface that can be implemented by classes that can act as validators.
///
/// ## Usage
///
/// ```dart
/// @Directive(
///   selector: '[custom-validator]',
///   providers: const [provide(NG_VALIDATORS, {useExisting: CustomValidatorDirective, multi: true})]
/// )
/// class CustomValidatorDirective implements Validator {
///   Map<String, dynamic> validate(Control c) {
///     return {"custom": true};
///   }
/// }
/// ```
abstract class Validator {
  Map<String, dynamic> validate(AbstractControl c);
}

const REQUIRED = Validators.required;
const REQUIRED_VALIDATOR =
    const Provider(NG_VALIDATORS, useValue: REQUIRED, multi: true);

/// A Directive that adds the `required` validator to any controls marked with
/// the `required` attribute, via the [NG_VALIDATORS] binding.
///
/// ### Example
///
///     <input ngControl="fullName" required>
@Directive(
    selector:
        "[required][ngControl],[required][ngFormControl],[required][ngModel]",
    providers: const [REQUIRED_VALIDATOR])
class RequiredValidator {}

typedef Map<String, dynamic> ValidatorFn(AbstractControl c);
typedef Future AsyncValidatorFn<T extends AbstractControl>(T c);

/// Provider which adds [MinLengthValidator] to [NG_VALIDATORS].
const MIN_LENGTH_VALIDATOR =
    const Provider(NG_VALIDATORS, useExisting: MinLengthValidator, multi: true);

/// A directive which installs the [MinLengthValidator] for any `ngControl`,
/// `ngFormControl`, or control with `ngModel` that also has a `minlength`
/// attribute.
@Directive(
    selector:
        "[minlength][ngControl],[minlength][ngFormControl],[minlength][ngModel]",
    providers: const [MIN_LENGTH_VALIDATOR])
class MinLengthValidator implements Validator {
  ValidatorFn _validator;
  MinLengthValidator(@Attribute("minlength") String minLength) {
    this._validator = Validators.minLength(int.parse(minLength, radix: 10));
  }

  @override
  Map<String, dynamic> validate(AbstractControl c) {
    return this._validator(c);
  }
}

/// Provider which adds [MaxLengthValidator] to [NG_VALIDATORS].
const MAX_LENGTH_VALIDATOR =
    const Provider(NG_VALIDATORS, useExisting: MaxLengthValidator, multi: true);

/// A directive which installs the [MaxLengthValidator] for any `ngControl`,
/// `ngFormControl`, or control with `ngModel` that also has a `maxlength`
/// attribute.
@Directive(
    selector:
        "[maxlength][ngControl],[maxlength][ngFormControl],[maxlength][ngModel]",
    providers: const [MAX_LENGTH_VALIDATOR])
class MaxLengthValidator implements Validator {
  ValidatorFn _validator;
  MaxLengthValidator(@Attribute("maxlength") String maxLength) {
    this._validator = Validators.maxLength(int.parse(maxLength, radix: 10));
  }
  @override
  Map<String, dynamic> validate(AbstractControl c) {
    return this._validator(c);
  }
}

/// A Directive that adds the `pattern` validator to any controls marked with
/// the `pattern` attribute, via the [NG_VALIDATORS] binding. Uses attribute
/// value as the regex to validate Control value against.  Follows pattern
/// attribute semantics; i.e. regex must match entire Control value.
///
/// ### Example
///
///     <input [ngControl]="fullName" pattern="[a-zA-Z ]*">
const PATTERN_VALIDATOR =
    const Provider(NG_VALIDATORS, useExisting: PatternValidator, multi: true);

@Directive(
    selector:
        "[pattern][ngControl],[pattern][ngFormControl],[pattern][ngModel]",
    providers: const [PATTERN_VALIDATOR])
class PatternValidator implements Validator {
  ValidatorFn _validator;
  PatternValidator(@Attribute("pattern") String pattern) {
    this._validator = Validators.pattern(pattern);
  }
  @override
  Map<String, dynamic> validate(AbstractControl c) {
    return this._validator(c);
  }
}
