import 'package:angular_ast/angular_ast.dart';

import '../template_parser.dart' show TemplateContext;
import 'message.dart';
import 'metadata.dart';

/// Builds an internationalized message by visiting [TemplateAst] nodes.
class I18nBuilder extends TemplateAstVisitor<void, StringBuffer> {
  final _args = <String, String>{};
  final _messageBuffer = StringBuffer();
  final TemplateContext _templateContext;

  I18nBuilder(this._templateContext);

  /// Whether the message this builds has any text to translate.
  var _hasText = false;

  /// Used to name start and end tag argument pairs.
  var _tagCount = 0;

  /// Builds an internationalized message from the nodes this has visited.
  ///
  /// Returns null if this has not yet visited any text, as the resulting
  /// message would not need translation.
  I18nMessage build(I18nMetadata metadata) {
    return _hasText
        ? I18nMessage(_messageBuffer.toString(), metadata, args: _args)
        : null;
  }

  void visitAll(List<TemplateAst> astNodes, [StringBuffer context]) {
    for (final astNode in astNodes) {
      astNode.accept(this, context);
    }
  }

  @override
  void visitAnnotation(AnnotationAst astNode, [_]) {
    if (astNode.name == i18nDescription ||
        astNode.name.startsWith(i18nDescriptionPrefix)) {
      _templateContext.reportError(
        "Internationalized messages can't be nested",
        astNode.sourceSpan,
      );
    }
  }

  @override
  void visitAttribute(AttributeAst astNode, [StringBuffer context]) {
    if (astNode.mustaches != null && astNode.mustaches.isNotEmpty) {
      _templateContext.reportError(
        "Interpolations aren't permitted in internationalized messages",
        astNode.sourceSpan,
      );
      return;
    }
    context.write(' ${astNode.name}');
    if (astNode.quotedValue != null) {
      context.write('=${astNode.quotedValue}');
    }
  }

  @override
  void visitBanana(_, [__]) {
    throw UnimplementedError();
  }

  @override
  void visitCloseElement(_, [__]) {
    throw UnimplementedError();
  }

  @override
  void visitComment(_, [__]) {}

  @override
  void visitContainer(ContainerAst astNode, [_]) {
    visitAll(astNode.annotations);
    visitAll(astNode.childNodes);
  }

  @override
  void visitElement(ElementAst astNode, [_]) {
    if (astNode.isVoidElement) {
      _templateContext.reportError(
        "Void elements aren't permitted in internationalized messages",
        astNode.sourceSpan,
      );
      return;
    }
    // Visit unpermitted AST nodes to report errors.
    visitAll(astNode.annotations);
    visitAll(astNode.events);
    visitAll(astNode.properties);
    visitAll(astNode.references);
    final tagIndex = _tagCount++;
    _addArgument('startTag$tagIndex', _start(astNode));
    visitAll(astNode.childNodes);
    _addArgument('endTag$tagIndex', _end(astNode));
  }

  @override
  void visitEmbeddedContent(EmbeddedContentAst astNode, [_]) {
    _reportUnpermitted(astNode);
  }

  @override
  void visitEmbeddedTemplate(EmbeddedTemplateAst astNode, [_]) {
    _reportUnpermitted(astNode);
  }

  @override
  void visitEvent(EventAst astNode, [_]) {
    _reportUnpermitted(astNode);
  }

  @override
  void visitExpression(_, [__]) {
    throw UnimplementedError();
  }

  @override
  void visitInterpolation(InterpolationAst astNode, [_]) {
    _reportUnpermitted(astNode);
  }

  @override
  void visitLetBinding(LetBindingAst astNode, [_]) {
    throw UnimplementedError();
  }

  @override
  void visitProperty(PropertyAst astNode, [_]) {
    _reportUnpermitted(astNode);
  }

  @override
  void visitReference(ReferenceAst astNode, [_]) {
    _reportUnpermitted(astNode);
  }

  @override
  void visitStar(StarAst starAst, [_]) {
    throw UnimplementedError();
  }

  @override
  void visitText(TextAst astNode, [_]) {
    // We must escape any newline characters, '$', and '\' so that the generated
    // message string is valid Dart.
    final text = _escape(astNode.value);
    _hasText = _hasText || text.trim().isNotEmpty;
    _messageBuffer.write(text);
  }

  /// Adds an argument to be interpolated in the message.
  void _addArgument(String name, String value) {
    _args[name] = value;
    _messageBuffer.write('\${$name}');
  }

  /// Returns the end tag of [astNode].
  String _end(ElementAst astNode) => '</${astNode.name}>';

  /// Returns the start tag of [astNode]
  String _start(ElementAst astNode) {
    final buffer = StringBuffer('<${astNode.name}');
    visitAll(astNode.attributes, buffer);
    buffer.write('>');
    return buffer.toString();
  }

  void _reportUnpermitted(TemplateAst astNode) {
    _templateContext.reportError(
      'Not permitted in internationalized messages',
      astNode.sourceSpan,
    );
  }
}

final _escapeRe = RegExp(r"(\n)|(\r)|['$\\]");

// TODO(leonsenft): see if this can be shared across compiler.
String _escape(String text) {
  return text.replaceAllMapped(_escapeRe, (match) {
    if (match[1] != null) {
      return r'\n';
    } else if (match[2] != null) {
      return r'\r';
    }
    return '\\${match[0]}';
  });
}
