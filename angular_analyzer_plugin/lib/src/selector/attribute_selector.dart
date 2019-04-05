import 'package:angular_analyzer_plugin/src/selector/attribute_selector_base.dart';
import 'package:angular_analyzer_plugin/src/selector/element_view.dart';
import 'package:angular_analyzer_plugin/src/selector/html_tag_for_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/match.dart';
import 'package:angular_analyzer_plugin/src/selector/name.dart';

/// The [Selector] that matches elements that have an attribute with the
/// given name, and (optionally) with the given value;
class AttributeSelector extends AttributeSelectorBase {
  @override
  final SelectorName nameElement;
  final String value;

  AttributeSelector(this.nameElement, this.value);

  @override
  List<SelectorName> getAttributes(ElementView element) =>
      match(element, null) == SelectorMatch.NonTagMatch ? [] : [nameElement];

  @override
  bool matchValue(String attributeValue) =>
      value == null || attributeValue == value;

  @override
  List<HtmlTagForSelector> refineTagSuggestions(
      List<HtmlTagForSelector> context) {
    for (final tag in context) {
      tag.setAttribute(nameElement.string, value: value);
    }
    return context;
  }

  @override
  String toString() {
    final name = nameElement.string;
    if (value != null) {
      return '[$name=$value]';
    }
    return '[$name]';
  }
}
