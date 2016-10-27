import 'ast.dart';
import 'lexer.dart';

import 'package:source_span/src/span.dart';

/// Parses an Angular Dart template into a concrete AST.
///
/// See `./doc/syntax.md` for more information.
class NgTemplateParser {
  /// Creates a new default template parser.
  const NgTemplateParser();

  /// Parses [template] into a series of root nodes.
  Iterable<NgAstNode> parse(
    String template, {
    /* Uri|String*/
    sourceUrl,
  }) {
    var scanner = new _ScannerParser();
    scanner.scan(new NgTemplateLexer(template, sourceUrl: sourceUrl));
    return scanner.result();
  }
}

class _Fragment implements NgAstNode {
  @override
  final List<NgAstNode> childNodes = <NgAstNode>[];

  @override
  final List<NgToken> parsedTokens = const <NgToken>[];

  @override
  final SourceSpan source = null;
}

class _ScannerParser extends NgTemplateScanner<NgAstNode> {
  _ScannerParser() {
    push(new _Fragment());
  }

  void addChild(NgAstNode node) {
    peek().childNodes.add(node);
  }

  @override
  List<NgAstNode> result() => peek().childNodes;

  @override
  void scanCloseElement(NgToken token) {
    while (token.type != NgTokenType.endCloseElement) {
      token = next();
    }
    pop();
  }

  @override
  void scanOpenElement(NgToken token) {
    var tagName = next();
    assert(tagName.type == NgTokenType.elementName);
    var element = new NgElement.unknown(tagName.text);
    addChild(element);
    push(element);
    while (token.type != NgTokenType.endOpenElement) {
      token = next();
    }
  }

  @override
  void scanText(NgToken token) {
    addChild(new NgText(token.text, token, token.source));
  }
}
