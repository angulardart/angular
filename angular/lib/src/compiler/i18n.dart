import 'package:angular_ast/angular_ast.dart' as ast;

import 'i18n/message.dart';
import 'i18n/metadata.dart';
import 'template_ast.dart' as ng;

export 'i18n/message.dart';
export 'i18n/metadata.dart';

// TODO(leonsenft): improve handling of error cases.
/// Internationalizes the child [nodes] of a [metadata]-annotated node.
///
/// The [nodes] are converted to an internationalization-aware AST that
/// handles rendering the translation for the current locale.
///
/// The provided [ngContentIndex] should match text within the parent element's
/// context.
List<ng.TemplateAst> internationalize(
  List<ast.StandaloneTemplateAst> nodes,
  I18nMetadata metadata,
  int ngContentIndex,
) {
  if (nodes.isEmpty) {
    throw new UnsupportedError('Too few nodes');
  }
  if (nodes.length > 1) {
    throw new UnsupportedError('Too many nodes');
  }
  final result = <ng.TemplateAst>[];
  final node = nodes.first;
  if (node is ast.TextAst) {
    final message = new I18nMessage(node.value, metadata);
    result.add(new ng.I18nTextAst(message, ngContentIndex, node.sourceSpan));
  } else {
    throw new UnsupportedError('Expected a text node');
  }
  return result;
}
