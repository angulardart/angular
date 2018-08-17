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
///     const ExistingProvider.forToken(
///       NG_VALIDATORS,
///       CustomValidatorDirective,
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

/// A [Directive] adding a required validator to controls with `required`:
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
  providers: [
    ExistingProvider.forToken(NG_VALIDATORS, RequiredValidator),
  ],
)
class RequiredValidator implements Validator {
  @Input()
  bool required = true;

  @override
  Map<String, dynamic> validate(AbstractControl c) =>
      required ? Validators.required(c) : null;
}

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
  providers: [
    ExistingProvider.forToken(NG_VALIDATORS, MinLengthValidator),
  ],
)
class MinLengthValidator implements Validator {
  @HostBinding('attr.minlength')
  String minLengthAttr;

  int _minLength;
  int get minLength => _minLength;

  @Input('minlength')
  set minLength(int value) {
    _minLength = value;
    minLengthAttr = value?.toString();
  }

  @override
  Map<String, dynamic> validate(AbstractControl c) {
    final v = c?.value?.toString();
    if (v == null || v == '') return null;
    return v.length < minLength
        ? {
            'minlength': {'requiredLength': minLength, 'actualLength': v.length}
          }
        : null;
  }
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
  providers: [
    ExistingProvider.forToken(NG_VALIDATORS, MaxLengthValidator),
  ],
)
class MaxLengthValidator implements Validator {
  @HostBinding('attr.maxlength')
  String maxLengthAttr;

  int _maxLength;
  int get maxLength => _maxLength;

  @Input('maxlength')
  set maxlength(int value) {
    _maxLength = value;
    maxLengthAttr = value?.toString();
  }

  @override
  Map<String, dynamic> validate(AbstractControl c) {
    final v = c?.value?.toString();
    if (v == null || v == '') return null;
    return v.length > maxLength
        ? {
            'maxlength': {'requiredLength': maxLength, 'actualLength': v.length}
          }
        : null;
  }
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
  providers: [
    ExistingProvider.forToken(NG_VALIDATORS, PatternValidator),
  ],
)
class PatternValidator implements Validator {
  @HostBinding('attr.pattern')
  @Input()
  String pattern;

  @override
  Map<String, dynamic> validate(AbstractControl c) =>
      Validators.pattern(pattern)(c);
}
