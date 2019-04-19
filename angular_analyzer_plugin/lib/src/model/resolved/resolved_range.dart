import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:angular_analyzer_plugin/src/model/navigable.dart';

/// A pair of an [SourceRange] and the referenced [Navigable].
///
/// This is used for navigation from a template to dart or other templates.
class ResolvedRange {
  /// The [SourceRange] where [navigable] is referenced.
  final SourceRange range;

  /// The [Navigable] referenced at [range].
  final Navigable navigable;

  ResolvedRange(this.range, this.navigable);

  @override
  String toString() => '$range=[$navigable, '
      'navigable=$navigable, '
      'source=${navigable.source}]';
}
