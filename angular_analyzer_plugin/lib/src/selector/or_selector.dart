import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_view.dart';
import 'package:angular_analyzer_plugin/src/selector/html_tag_for_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/match.dart';
import 'package:angular_analyzer_plugin/src/selector/name.dart';
import 'package:angular_analyzer_plugin/src/selector/selector.dart';

/// The [Selector] that matches one of the given [selectors].
class OrSelector extends Selector {
  final List<Selector> selectors;

  OrSelector(this.selectors);

  @override
  bool availableTo(ElementView element) =>
      selectors.any((selector) => selector.availableTo(element));

  @override
  List<SelectorName> getAttributes(ElementView element) =>
      selectors.expand((selector) => selector.getAttributes(element)).toList();

  @override
  SelectorMatch match(ElementView element, Template template) {
    var match = SelectorMatch.NoMatch;
    for (final selector in selectors) {
      // Eagerly record: if *any* matches, we want it recorded immediately.
      final subMatch = selector.match(element, template);

      if (match == SelectorMatch.NoMatch) {
        match = subMatch;
      }

      if (subMatch == SelectorMatch.TagMatch) {
        return SelectorMatch.TagMatch;
      }
    }

    return match;
  }

  @override
  void recordElementNameSelectors(List<ElementNameSelector> recordingList) {
    selectors.forEach(
        (selector) => selector.recordElementNameSelectors(recordingList));
  }

  @override
  List<HtmlTagForSelector> refineTagSuggestions(
      List<HtmlTagForSelector> context) {
    final response = <HtmlTagForSelector>[];
    for (final selector in selectors) {
      final newContext = context.map((t) => t.clone()).toList();
      response.addAll(selector.refineTagSuggestions(newContext));
    }

    return response;
  }

  @override
  String toString() => selectors.join(' || ');
}
