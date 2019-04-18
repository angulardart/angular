import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_view.dart';
import 'package:angular_analyzer_plugin/src/selector/html_tag_for_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/match.dart';
import 'package:angular_analyzer_plugin/src/selector/name.dart';

/// The [Selector] that matches elements with the given (static) classes.
class ClassSelector extends Selector {
  final SelectorName nameElement;

  ClassSelector(this.nameElement);

  @override
  bool availableTo(ElementView element) => true;

  // Always return true - classes can always be added to satisfy without
  // having to remove or change existing classes.
  @override
  List<SelectorName> getAttributes(ElementView element) => [];

  @override
  SelectorMatch match(ElementView element, Template template) {
    final name = nameElement.string;
    final val = element.attributes['class'];
    // no 'class' attribute
    if (val == null) {
      return SelectorMatch.NoMatch;
    }
    // no such class
    if (!val.split(' ').contains(name)) {
      return SelectorMatch.NoMatch;
    }
    // prepare index of "name" int the "class" attribute value
    int index;
    if (val == name || val.startsWith('$name ')) {
      index = 0;
    } else if (val.endsWith(' $name')) {
      index = val.length - name.length;
    } else {
      index = val.indexOf(' $name ') + 1;
    }
    // add resolved range
    final valueOffset = element.attributeValueSpans['class'].offset;
    final offset = valueOffset + index;
    template?.addRange(SourceRange(offset, name.length), nameElement);
    return SelectorMatch.NonTagMatch;
  }

  @override
  void recordElementNameSelectors(List<ElementNameSelector> recordingList) {
    // empty
  }

  @override
  List<HtmlTagForSelector> refineTagSuggestions(
      List<HtmlTagForSelector> context) {
    for (final tag in context) {
      tag.addClass(nameElement.string);
    }
    return context;
  }

  @override
  String toString() => '.${nameElement.string}';
}
