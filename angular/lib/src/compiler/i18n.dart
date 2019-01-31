import 'package:source_span/source_span.dart';
import 'package:angular_ast/angular_ast.dart' as ast;

import 'i18n/builder.dart';
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
  final i18nMessage = _message(parent.childNodes, metadata, context);
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

/// Creates an internationalized messages from [nodes].
I18nMessage _message(
  List<ast.StandaloneTemplateAst> nodes,
  I18nMetadata metadata,
  TemplateContext context,
) {
  /// This disambiguation is important to ensure the message contents are
  /// properly escaped. The `I18nBuilder` used to construct messages does
  /// manual escaping, while messages without nested HTML are automatically
  /// escaped later during code generation.
  return _isText(nodes)
      ? _textMessage(nodes.single as ast.TextAst, metadata)
      : _htmlMessage(nodes, metadata, context);
}

/// Whether [nodes] contains only a plain text node.
bool _isText(List<ast.StandaloneTemplateAst> nodes) =>
    nodes.length == 1 && nodes[0] is ast.TextAst;

/// Creates an internationalized message from [nodes] that contain nested HTML.
I18nMessage _htmlMessage(
  List<ast.StandaloneTemplateAst> nodes,
  I18nMetadata metadata,
  TemplateContext context,
) {
  final i18nBuilder = I18nBuilder(context);
  for (final child in nodes) {
    child.accept(i18nBuilder);
  }
  return i18nBuilder.build(metadata);
}

/// Creates an internationalized message from a [text] node.
I18nMessage _textMessage(ast.TextAst text, I18nMetadata metadata) {
  return I18nMessage(text.value, metadata);
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
