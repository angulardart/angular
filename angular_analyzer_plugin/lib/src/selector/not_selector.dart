import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_view.dart';
import 'package:angular_analyzer_plugin/src/selector/html_tag_for_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/match.dart';
import 'package:angular_analyzer_plugin/src/selector/name.dart';

/// The [Selector] that confirms the inner [Selector] condition does NOT match.
class NotSelector extends Selector {
  final Selector condition;

  NotSelector(this.condition);

  @override
  bool availableTo(ElementView element) =>
      condition.match(element, null) == SelectorMatch.NoMatch;

  @override
  List<SelectorName> getAttributes(ElementView element) => [];

  @override
  SelectorMatch match(ElementView element, Template template) =>
      // pass null into the lower condition -- don't record NOT matches.
      condition.match(element, null) == SelectorMatch.NoMatch
          ? SelectorMatch.NonTagMatch
          : SelectorMatch.NoMatch;

  @override
  void recordElementNameSelectors(List<ElementNameSelector> recordingList) {
    // empty
  }

  @override
  List<HtmlTagForSelector> refineTagSuggestions(
          List<HtmlTagForSelector> context) =>
      context;

  @override
  String toString() => ":not($condition)";
}
