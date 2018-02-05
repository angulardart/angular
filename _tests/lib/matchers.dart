import 'dart:html';

import 'package:angular/src/di/errors.dart';
import 'package:angular/src/facade/lang.dart';
import 'package:test/test.dart';

/// Matches a missing provider error thrown at runtime.
final Matcher throwsMissingProviderError = (() {
  if (assertionsEnabled()) {
    return _throwsMissingProviderError;
  }
  return throwsArgumentError;
})();

final _isMissingProviderError = const isInstanceOf<MissingProviderError>();
final _throwsMissingProviderError = throwsA(_isMissingProviderError);

/// Matches textual content of an element including children.
Matcher hasTextContent(expected) => new _HasTextContent(expected);

// TODO(matanl): Add matcher to new test infrastructure.
class _HasTextContent extends Matcher {
  final String expectedText;

  const _HasTextContent(this.expectedText);

  bool matches(item, Map matchState) => _elementText(item) == expectedText;

  Description describe(Description description) =>
      description.add('$expectedText');

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    mismatchDescription.add('Text content of element: '
        '\'${_elementText(item)}\'');
    return mismatchDescription;
  }
}

String _elementText(n) {
  if (n is Iterable) {
    return n.map(_elementText).join("");
  }

  if (n is! Node) return '$n';

  if (n is Comment) {
    return '';
  }

  if (n is ContentElement) {
    return _elementText(n.getDistributedNodes());
  }

  if (n is Element && n.shadowRoot != null) {
    return _elementText(n.shadowRoot.nodes);
  }

  if (n.nodes != null && n.nodes.isNotEmpty) {
    return _elementText(n.nodes);
  }

  return n.text;
}
