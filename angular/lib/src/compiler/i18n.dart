import 'package:angular_ast/angular_ast.dart' as ast;

import 'i18n/message.dart';
import 'i18n/metadata.dart';
import 'template_ast.dart' as ng;
import 'template_parser.dart' show TemplateContext;

export 'i18n/message.dart';
export 'i18n/metadata.dart';

/// Internationalizes the children of a [metadata]-annotated [parent] node.
///
/// The children are converted to an internationalization-aware AST that handles
/// rendering the translation for the current locale.
///
/// The provided [ngContentIndex] should match text within the [parent]'s
/// context.
List<ng.TemplateAst> internationalize(
  ast.StandaloneTemplateAst parent,
  I18nMetadata metadata,
  int ngContentIndex,
  TemplateContext context,
) {
  if (parent.childNodes.length != 1) {
    context.reportError(
      'Expected a single, non-empty text node child in an "@i18n" context',
      parent.sourceSpan,
    );
    return [];
  }
  final result = <ng.TemplateAst>[];
  final node = parent.childNodes.first;
  if (node is ast.TextAst) {
    final message = new I18nMessage(node.value, metadata);
    result.add(new ng.I18nTextAst(message, ngContentIndex, node.sourceSpan));
  } else {
    context.reportError(
      'Only text is supported in an "@i18n" context',
      node.sourceSpan,
    );
  }
  return result;
}
