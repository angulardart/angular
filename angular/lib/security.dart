/// API for customizing AngularDart's built-in security checks.
///
/// Import this library as follows:
///
/// ```
/// import 'package:angular/security.dart';
/// ```
///
/// For examples of using this API, see the [Security page][]
/// in the [AngularDart guide][].
///
/// [Security page]: https://webdev.dartlang.org/angular/guide/security
/// [AngularDart guide]: https://webdev.dartlang.org/angular/guide

library angular.security;

// LINT.IfChange
export 'src/security/dom_sanitization_service.dart';
export 'src/security/safe_inner_html.dart';
export 'src/security/sanitization_service.dart';
// LINT.ThenChange(//depot/google3/third_party/dart_lang/v2/g3_linter/lib/src/rules/avoid_bypassing_html_security.dart)
