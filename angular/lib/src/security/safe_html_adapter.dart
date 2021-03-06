/// The top-level methods are intended to be used only by code generated by the
/// compiler when it "sees" that a potential unsafe operation would otherwise be
/// used (i.e. `<div [innerHtml]="someValue"></div>`).
import 'html_sanitizer.dart';
import 'style_sanitizer.dart';
import 'url_sanitizer.dart';

/// Converts [stringOrSafeOrBypass] into a `String` safe to use within the DOM.
String? sanitizeHtml(Object? stringOrSafeOrBypass) {
  if (stringOrSafeOrBypass == null) {
    return null;
  }
  final unsafeString = stringOrSafeOrBypass.toString();
  return sanitizeHtmlInternal(unsafeString);
}

/// Converts [stringOrSafeOrBypass] into a `String` safe to use within the DOM.
String? sanitizeStyle(Object? stringOrSafeOrBypass) {
  if (stringOrSafeOrBypass == null) {
    return null;
  }
  final unsafeString = stringOrSafeOrBypass.toString();
  return internalSanitizeStyle(unsafeString);
}

/// Converts [stringOrSafeOrBypass] into a `String` safe to use within the DOM.
String? sanitizeUrl(Object? stringOrSafeOrBypass) {
  if (stringOrSafeOrBypass == null) {
    return null;
  }
  final unsafeString = stringOrSafeOrBypass.toString();
  return internalSanitizeUrl(unsafeString);
}

/// Converts [stringOrSafeOrBypass] into a `String` safe to use within the DOM.
String? sanitizeResourceUrl(Object? stringOrSafeOrBypass) {
  if (stringOrSafeOrBypass == null) {
    return null;
  }
  return stringOrSafeOrBypass.toString();
}
