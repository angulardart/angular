import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_view.dart';
import 'package:angular_analyzer_plugin/src/selector/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/match.dart';
import 'package:angular_analyzer_plugin/src/selector/name.dart';

/// Base functionality for selectors that begin by finding a named attribute.
abstract class AttributeSelectorBase extends Selector {
  SelectorName get nameElement;

  @override
  bool availableTo(ElementView element) =>
      !element.attributes.keys.contains(findAttribute(element)) ||
      match(element, null) != SelectorMatch.NoMatch;

  String findAttribute(ElementView element) => nameElement.string;

  @override
  List<SelectorName> getAttributes(ElementView element) =>
      element.attributes.keys.contains(findAttribute(element))
          ? []
          : [nameElement];

  @override
  SelectorMatch match(ElementView element, Template template) {
    // Different selectors may find attributes differently
    final matchedName = findAttribute(element);
    if (matchedName == null) {
      return SelectorMatch.NoMatch;
    }

    final attributeSpan = element.attributeNameSpans[matchedName];
    final attributeValue = element.attributes[matchedName];

    if (attributeSpan == null) {
      return SelectorMatch.NoMatch;
    }

    // Different selectors may match the attribute value differently
    if (!matchValue(attributeValue)) {
      return SelectorMatch.NoMatch;
    }

    // OK
    template?.addRange(
        SourceRange(attributeSpan.offset, attributeSpan.length), nameElement);
    return SelectorMatch.NonTagMatch;
  }

  bool matchValue(String attributeValue);

  @override
  void recordElementNameSelectors(List<ElementNameSelector> recordingList) {
    // empty
  }
}
