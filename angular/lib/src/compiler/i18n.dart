import 'package:angular_ast/angular_ast.dart' as ast;

import 'i18n/message.dart';
import 'i18n/metadata.dart';
import 'template_ast.dart' as ng;

export 'i18n/message.dart';
export 'i18n/metadata.dart';

List<ng.TemplateAst> internationalize(
  List<ast.StandaloneTemplateAst> nodes,
  Metadata metadata,
  int ngContentIndex,
) {
  if (nodes.isEmpty) {
    // TODO(leonsenft): warn that i18n node is missing a message.
    throw new UnsupportedError('Too few nodes');
  }
  if (nodes.length > 1) {
    throw new UnsupportedError('Too many nodes');
  }
  final result = <ng.TemplateAst>[];
  final node = nodes.first;
  if (node is ast.TextAst) {
    final message = new Message(
      node.value,
      metadata.description,
      meaning: metadata.meaning,
    );
    result.add(new ng.I18nTextAst(message, ngContentIndex, node.sourceSpan));
  } else {
    throw new UnsupportedError('Not texty enough');
  }
  return result;
}
