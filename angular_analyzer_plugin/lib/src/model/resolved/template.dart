import 'package:analyzer/src/generated/source.dart' show Source, SourceRange;
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/component.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/resolved_range.dart';

/// An Angular template in an HTML file.
class HtmlTemplate extends Template {
  /// The [Source] of the template.
  final Source source;

  HtmlTemplate(Component component, this.source, ElementInfo ast)
      : super(component, ast);
}

/// An Angular template AST and metadata about its context.
///
/// This represents the AST itself with metadata around that ast: which
/// [Component] it belongs to, which [AnlaysisError]s it ignores, and which
/// [ResolvedRange]s it has collected.
class Template {
  /// The [Component] that desfined the template.
  final Component component;

  /// The [ResolvedRange]s of the template.
  final ranges = <ResolvedRange>[];

  /// The [ElementInfo] that begins the AST of the resolved template
  final ElementInfo ast;

  /// The errors that are ignored in this template
  final ignoredErrors = <String>{};

  Template(this.component, this.ast);

  /// Records that the given [navigable] is referenced at the given [range].
  void addRange(SourceRange range, Navigable navigable) {
    assert(range != null);
    assert(range.offset != null);
    assert(range.offset >= 0);
    ranges.add(ResolvedRange(range, navigable));
  }

  @override
  String toString() => 'Template(ranges=$ranges)';
}
