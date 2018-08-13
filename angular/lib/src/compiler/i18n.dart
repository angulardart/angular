import 'package:angular_ast/angular_ast.dart' as ast;
import 'package:source_span/source_span.dart';

import 'i18n/builder.dart';
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
  final i18nBuilder = I18nBuilder(context)..visitAll(parent.childNodes);
  final i18nMessage = i18nBuilder.build(metadata);
  if (i18nMessage == null) {
    context.reportError(
      'Internationalized messages must contain text',
      parent.sourceSpan,
    );
    return [];
  }
  return [
    ng.I18nTextAst(
      i18nMessage,
      ngContentIndex,
      _spanWithin(parent),
    )
  ];
}

SourceSpan _spanWithin(ast.StandaloneTemplateAst parent) {
  final firstSpan = parent.childNodes.first.sourceSpan;
  final lastSpan = parent.childNodes.last.sourceSpan;
  if (firstSpan is FileSpan && lastSpan is FileSpan) {
    return firstSpan.expand(lastSpan);
  }
  // We shouldn't ever reach this state, but if we do somehow, we want it
  // reported as a compiler bug with an explicit error message.
  throw StateError("Couldn't compute source span of internationalized node");
}
