import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_view.dart';
import 'package:angular_analyzer_plugin/src/selector/html_tag_for_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/match.dart';
import 'package:angular_analyzer_plugin/src/selector/name.dart';

/// The [Selector] that matches all of the given [selectors].
class AndSelector extends Selector {
  final List<Selector> selectors;

  AndSelector(this.selectors);

  @override
  bool availableTo(ElementView element) =>
      selectors.every((selector) => selector.availableTo(element));

  @override
  List<SelectorName> getAttributes(ElementView element) =>
      selectors.expand((selector) => selector.getAttributes(element)).toList();

  @override
  SelectorMatch match(ElementView element, Template template) {
    // Invalid selector case, should NOT match all.
    if (selectors.isEmpty) {
      return SelectorMatch.NoMatch;
    }

    var onSuccess = SelectorMatch.NonTagMatch;
    for (final selector in selectors) {
      // Important: do not pass the template down, as that will record matches.
      final theMatch = selector.match(element, null);
      if (theMatch == SelectorMatch.TagMatch) {
        onSuccess = theMatch;
      } else if (theMatch == SelectorMatch.NoMatch) {
        return SelectorMatch.NoMatch;
      }
    }

    // Record matches here now that we know the whole selector matched.
    if (template != null) {
      for (final selector in selectors) {
        selector.match(element, template);
      }
    }
    return onSuccess;
  }

  @override
  void recordElementNameSelectors(List<ElementNameSelector> recordingList) {
    selectors.forEach(
        (selector) => selector.recordElementNameSelectors(recordingList));
  }

  @override
  List<HtmlTagForSelector> refineTagSuggestions(
      List<HtmlTagForSelector> context) {
    for (final selector in selectors) {
      // ignore: parameter_assignments
      context = selector.refineTagSuggestions(context);
    }
    return context;
  }

  @override
  String toString() => selectors.join(' && ');
}
