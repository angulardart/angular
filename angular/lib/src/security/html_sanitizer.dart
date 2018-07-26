import 'dart:html';

Node _inertElement;

Node _getInertElement() {
  if (_inertElement == null) {
    // Prefer using <template> element if supported.
    TemplateElement templateEl = TemplateElement();
    if (templateEl != null) {
      // TODO: investigate template.children.clear and remove extra div.
      _inertElement = document.createElement('div');
      templateEl.append(_inertElement);
    } else {
      _inertElement = DocumentFragment();
    }
  }
  return _inertElement;
}

/// Sanitizes the given unsafe, untrusted HTML fragment, and returns HTML text
/// that is safe to add to the DOM in a browser environment.
///
/// This function uses the builtin Dart innerHTML sanitization provided by
/// NodeTreeSanitizer on an inert element.
String sanitizeHtmlInternal(String value) {
  Element element = _getInertElement();
  element.innerHtml = value;
  String safeHtml = element.innerHtml;
  element.children?.clear();
  return safeHtml;
}
