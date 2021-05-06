import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';

/// Matches textual content of an element including children.
Matcher hasTextContent(String expected) => _HasTextContent(expected);

final throwsNoProviderError = throwsA(_isNoProviderError);
final _isNoProviderError = const TypeMatcher<NoProviderError>();

class _HasTextContent extends Matcher {
  final String expectedText;

  const _HasTextContent(this.expectedText);

  @override
  bool matches(Object? item, void _) => _elementText(item) == expectedText;

  @override
  Description describe(Description description) =>
      description.add('$expectedText');

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    void _,
    void __,
  ) {
    mismatchDescription.add('Text content of element: '
        '\'${_elementText(item)}\'');
    return mismatchDescription;
  }
}

String? _elementText(Object? n) {
  if (n is Iterable) {
    return n.map(_elementText).join('');
  } else if (n is Node) {
    if (n is Comment) {
      return '';
    }

    if (n is ContentElement) {
      return _elementText(n.getDistributedNodes());
    }

    if (n is Element && n.shadowRoot != null) {
      return _elementText(n.shadowRoot!.nodes);
    }

    if (n.nodes.isNotEmpty) {
      return _elementText(n.nodes);
    }

    return n.text;
  } else {
    return '$n';
  }
}
