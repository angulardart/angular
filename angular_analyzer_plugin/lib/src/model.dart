import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/src/model/navigable.dart';

/// Placeholder so tests pass.
class Template {
  void addRange(SourceRange range, Navigable navigable) {}
}

/// Placeholder so tests pass.
class ResolvedRange {
  /// The [SourceRange] where [element] is referenced.
  final SourceRange range;

  /// The [Navigable] concept referenced at [range].
  final Navigable element;

  ResolvedRange(this.range, this.element);
}
