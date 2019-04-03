import 'package:angular_analyzer_plugin/src/selector/attribute_selector_base.dart';
import 'package:angular_analyzer_plugin/src/selector/html_tag_for_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/name.dart';

/// The [AttributeContainsSelector] that matches elements that have attributes
/// with the given name, and that attribute contains the value of the selector.
class AttributeContainsSelector extends AttributeSelectorBase {
  @override
  final SelectorName nameElement;
  final String value;

  AttributeContainsSelector(this.nameElement, this.value);

  @override
  bool matchValue(String attributeValue) => attributeValue.contains(value);

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
    return '[$name*=$value]';
  }
}
