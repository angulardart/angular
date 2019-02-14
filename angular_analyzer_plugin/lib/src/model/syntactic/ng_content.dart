import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:angular_analyzer_plugin/src/selector.dart';

/// The syntactic model of an `<ng-content>` tag. Note that while the tags
/// themselves are purely syntactic, the relationship between a component and
/// its [NgContent]s is not if it uses a `templateUrl`. See README.md for more.
class NgContent {
  /// The source range of the whole [NgContent] tag declaration.
  final SourceRange sourceRange;

  /// NOTE: May contain Null. Null in this case means no selector (all content).
  final Selector selector;

  /// The [SourceRange] for the [selector].
  final SourceRange selectorRange;

  NgContent(this.sourceRange)
      : selector = null,
        selectorRange = null;

  NgContent.withSelector(this.sourceRange, this.selector, this.selectorRange);

  bool get matchesAll => selector == null;
}
