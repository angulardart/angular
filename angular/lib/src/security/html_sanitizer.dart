import 'dart:html';

Node _inertElement;
bool _inertIsTemplate = false;

Node _getInertElement() {
  if (_inertElement == null) {
    // Prefer using <template> element if supported.
    TemplateElement templateEl = new TemplateElement();
    if (templateEl != null) {
      // TODO: investigate template.children.clear and remove extra div.
      _inertElement = document.createElement('div');
      templateEl.append(_inertElement);
      _inertIsTemplate = false;
    } else {
      _inertElement = new DocumentFragment();
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
  mXSSProtection(element, value);
  String safeHtml = element.innerHtml;
  element.children?.clear();
  return safeHtml;
}

/// Protect against mXSS.
///
/// Repeatedly parse the document to make sure it stabilizes, so that a browser
/// trying to auto-correct incorrect HTML cannot cause formerly inert HTML to
/// become dangerous.
void mXSSProtection(Element containerElement, String unsafeHtml) {
  int mXSSAttempts = 5;
  String parsedHtml = unsafeHtml;
  do {
    if (mXSSAttempts == 0) {
      throw new Exception(
          'Failed to sanitize html because the input is unstable');
    }
    if (mXSSAttempts == 1) {
      // For IE<=11 strip custom-namespaced attributes on IE<=11.
      stripCustomNsAttrs(containerElement);
    }
    mXSSAttempts--;
    unsafeHtml = parsedHtml;
    containerElement.innerHtml = unsafeHtml;
    parsedHtml = containerElement.innerHtml;
  } while (unsafeHtml != parsedHtml);
}

/// When IE9-11 comes across an unknown namespaced attribute e.g. 'xlink:foo'
/// it adds 'xmlns:ns1' attribute to declare ns1 namespace and prefixes the
/// attribute with 'ns1' (e.g. 'ns1:xlink:foo').
///
/// This is undesirable since we don't want to allow any of these custom
/// attributes. This method strips them all.
void stripCustomNsAttrs(Element element) {
  for (var attrName in element.attributes.keys) {
    if (attrName == 'xmlns:ns1' || attrName.startsWith('ns1:')) {
      element.attributes.remove(attrName);
    }
  }
  for (var n in element.childNodes) {
    if (n is Element) stripCustomNsAttrs(n);
  }
}
