import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_view.dart';
import 'package:angular_analyzer_plugin/src/selector/html_tag_for_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/match.dart';
import 'package:angular_analyzer_plugin/src/selector/name.dart';

/// The base class for all Angular selectors.
///
/// To parse a selector, use [SelectorParser] from
/// `lib/src/selector/parser.dart`.
///
/// [Selector]s can be tested for a match against [ElementView]s, and record
/// matching ranges against a [Template], and they have other methods that are
/// mostly for autocompletion, such as [getAttributes], [availableTo],
/// [suggestTags].
///
/// Specific selectors such as [AndSelector], [ElementNameSelector], etc, all
/// extend this class.
abstract class Selector {
  String originalString;
  int offset;

  /// Whether the given [element] can potentially match with this selector.
  ///
  /// Essentially, if the [ElementView] does not violate the current selector,
  /// then the given [element] is 'availableTo' this selector without
  /// contradiction.
  ///
  /// This is used in code completion; 'availableTo' should be true if the
  /// selector can match the [element] without having to change/remove an
  /// existing decorator on the [element].
  bool availableTo(ElementView element);

  /// Attributes that could be added to [element] and preserve [availableTo].
  ///
  /// Used by code completion. Returns a list of all [SelectorName]s where
  /// each is an attribute name to possibly suggest.
  List<SelectorName> getAttributes(ElementView element);

  /// Check whether the given [element] matches this selector.
  ///
  /// [Template] may be provided or null; if it is provided then the selector
  /// should record the match on the template. If it is not provided, then we
  /// either are matching where it can't be recorded, or we are not yet ready to
  /// record (for instance, we're checking a part of an AND selector and can't
  /// record until all parts are known to match).
  SelectorMatch match(ElementView element, Template template);

  /// Collect all [ElementNameSelector]s in this [Selector]'s full AST.
  void recordElementNameSelectors(List<ElementNameSelector> recordingList);

  /// Further constrain [HtmlTagForSelector] list for suggesting tag names.
  ///
  /// See [HtmlTagForSelector] for detailed info on what this does.
  List<HtmlTagForSelector> refineTagSuggestions(
      List<HtmlTagForSelector> context);

  /// Generate constraint list of [HtmlTagForSelector] for suggesting tag names.
  ///
  /// See [HtmlTagForSelector] for detailed info on what this does.
  ///
  /// Selectors should NOT override this method, but rather override
  /// [refineTagSuggestions].
  List<HtmlTagForSelector> suggestTags() {
    // create a seed tag: ORs will copy this, everything else modifies. Each
    // selector returns the newest set of tags to be transformed.
    final tags = [HtmlTagForSelector()];
    return refineTagSuggestions(tags).where((t) => t.isValid).toList();
  }
}
