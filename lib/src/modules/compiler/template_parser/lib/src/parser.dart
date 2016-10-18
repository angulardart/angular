import 'ast.dart';

/// Parses an Angular Dart template into a concrete AST.
///
/// See `GRAMMAR.md` for more information.
abstract class NgTemplateParser {
  /// Parses [template] into a series of root nodes.
  List<NgAstNode> parse(String template);
}
