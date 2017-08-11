import 'package:angular/angular.dart';

import '../model.dart' show AbstractControl;
import '../validators.dart' show Validators, NG_VALIDATORS;

/// An interface to be implemented as classes acting as validators.
///
/// ## Usage
///
/// ```dart
/// @Directive(
///   selector: '[custom-validator]',
///   providers: const [
///     const Provider(
///       NG_VALIDATORS,
///       useExisting: CustomValidatorDirective,
///       multi: true,
///     ),
///   ]
/// )
/// class CustomValidatorDirective implements Validator {
///   @override
///   Map<String, dynamic> validate(AbstractControl control) {
///     // The length of the input string can't be longer than 14 characters.
///     final value = c.value;
///     if (value is String && value.length > 14) {
///       return {
///         'length': value.length,
///       };
///     }
///     return null;
///   }
/// }
/// ```
abstract class Validator {
  /// Returns a map of the errors associated with this control.
  ///
  /// Each entry in the map is a separate error associated with the control.
  /// The key is an identifier for the error while the value is additional
  /// information used by the component to display the error. For instance a
  /// length validator could provide information about how long the current
  /// invalid string is and the max string length for the input to display.
  Map<String, dynamic> validate(AbstractControl control);
}

/// Returns a map of the errors associated with this control.
///
/// Each entry in the map is a separate error associated with the control.
/// The key is an identifier for the error while the value is additional
/// information used by the component to display the error. For instance a
/// length validator could provide information about how long the current
/// invalid string is and the max string length for the input to display.
typedef Map<String, dynamic> ValidatorFn(AbstractControl c);

/// Validator that requires controls to have a non-empty value.
const ValidatorFn REQUIRED = Validators.required;

/// A [Directive] adding a [REQUIRED] validator to controls with `required`:
///
/// ```html
/// <input ngControl="fullName" required />
/// ```
///
/// A _required_ control must have a non-empty value.
@Directive(
  selector: ''
      '[required][ngControl],'
      '[required][ngFormControl],'
      '[required][ngModel]',
  providers: const [
    const Provider(
      NG_VALIDATORS,
      useValue: REQUIRED,
      multi: true,
    ),
  ],
)
class RequiredValidator {}

/// A [Directive] adding minimum-length validator to controls with `minlength`.
///
/// ```html
/// <input ngControl="fullName" minLength="10" />
/// ```
@Directive(
  selector: ''
      '[minlength][ngControl],'
      '[minlength][ngFormControl],'
      '[minlength][ngModel]',
  providers: const [
    const Provider(
      NG_VALIDATORS,
      useExisting: MinLengthValidator,
      multi: true,
    ),
  ],
)
class MinLengthValidator implements Validator {
  final ValidatorFn _validator;

  MinLengthValidator(@Attribute('minlength') String minLength)
      : _validator = Validators.minLength(int.parse(minLength, radix: 10));

  @override
  Map<String, dynamic> validate(AbstractControl c) => _validator(c);
}

/// A [Directive] adding minimum-length validator to controls with `maxlength`.
///
/// ```html
/// <input ngControl="fullName" maxLength="10" />
/// ```
@Directive(
  selector: ''
      '[maxlength][ngControl],'
      '[maxlength][ngFormControl],'
      '[maxlength][ngModel]',
  providers: const [
    const Provider(
      NG_VALIDATORS,
      useExisting: MaxLengthValidator,
      multi: true,
    ),
  ],
)
class MaxLengthValidator implements Validator {
  final ValidatorFn _validator;

  MaxLengthValidator(@Attribute('maxlength') String maxLength)
      : _validator = Validators.maxLength(int.parse(maxLength, radix: 10));

  @override
  Map<String, dynamic> validate(AbstractControl c) => _validator(c);
}

/// A [Directive] that adds a pattern validator to any controls with `pattern`:
///
/// ```html
/// <input ngControl="fullName" pattern="[a-zA-Z ]*" />
/// ```
///
/// The attribute value is parsed and used as a [RegExp] to validate the control
/// value against. The regular expression must match the entire control value.
@Directive(
  selector: ''
      '[pattern][ngControl],'
      '[pattern][ngFormControl],'
      '[pattern][ngModel]',
  providers: const [
    const Provider(
      NG_VALIDATORS,
      useExisting: PatternValidator,
      multi: true,
    ),
  ],
)
class PatternValidator implements Validator {
  final ValidatorFn _validator;

  PatternValidator(@Attribute('pattern') String pattern)
      : _validator = Validators.pattern(pattern);

  @override
  Map<String, dynamic> validate(AbstractControl c) => _validator(c);
}
