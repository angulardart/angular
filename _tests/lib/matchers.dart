import 'dart:html';

import 'package:angular/angular.dart';
import 'package:test/test.dart';

/// Matches textual content of an element including children.
Matcher hasTextContent(expected) => _HasTextContent(expected);

final throwsNoProviderError = throwsA(_isNoProviderError);
final _isNoProviderError = const TypeMatcher<NoProviderError>();

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
