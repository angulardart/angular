import 'package:angular_analyzer_plugin/src/selector/attribute_selector_base.dart';
import 'package:angular_analyzer_plugin/src/selector/html_tag_for_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/name.dart';

/// The [Selector] that matches elements that have an attribute with any name,
/// and with contents that match the given regex.
class AttributeStartsWithSelector extends AttributeSelectorBase {
  @override
  final SelectorName nameElement;

  final String value;

  AttributeStartsWithSelector(this.nameElement, this.value);

  @override
  bool matchValue(String attributeValue) => attributeValue.startsWith(value);

  @override
  List<HtmlTagForSelector> refineTagSuggestions(
          List<HtmlTagForSelector> context) =>
      context;

  @override
  String toString() => '[$nameElement^=$value]';
}
