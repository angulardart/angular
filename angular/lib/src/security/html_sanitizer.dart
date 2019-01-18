import 'dart:html';

final _inertFragment = DocumentFragment();

/// Sanitizes the given unsafe, untrusted HTML fragment, and returns HTML text
/// that is safe to add to the DOM in a browser environment.
///
/// This function uses the builtin Dart innerHTML sanitization provided by
/// NodeTreeSanitizer on an inert element.
String sanitizeHtmlInternal(String value) {
  final inertFragment = _inertFragment..innerHtml = value;
  final safeHtml = inertFragment.innerHtml;
  inertFragment.children.clear();
  return safeHtml;
}
