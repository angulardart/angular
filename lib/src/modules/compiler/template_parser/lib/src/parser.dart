import 'ast.dart';
import 'lexer.dart';

import 'package:source_span/src/span.dart';

/// Parses an Angular Dart template into a concrete AST.
///
/// See `./doc/syntax.md` for more information.
class NgTemplateParser {
  /// Creates a new default template parser.
  final ErrorCallback errorHandler;
  const NgTemplateParser({this.errorHandler});

  /// Parses [template] into a series of root nodes.
  Iterable<NgAstNode> parse(
    String template, {
    /* Uri|String*/
    sourceUrl,
  }) {
    if (template == null || template.isEmpty) return const [];
    var scanner = new _ScannerParser(errorHandler: errorHandler);
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

typedef void ErrorCallback(Error error);

class _ScannerParser extends NgTemplateScanner<NgAstNode> {
  final ErrorCallback errorHandler;

  _ScannerParser({this.errorHandler}) {
    push(new _Fragment());
  }

  void addChild(NgAstNode node) {
    peek().childNodes.add(node);
  }

  @override
  List<NgAstNode> result() => peek().childNodes;

  @override
  void scanAttribute(NgToken before, NgToken name) {
    assert(name.type == NgTokenType.attributeName);
    final after = next();
    if (after.type == NgTokenType.beforeDecoratorValue) {
      final space = after;
      final value = next();
      addChild(
        new NgAttribute.fromTokensWithValue(before, name, space, value, next()),
      );
    } else if (after.type == NgTokenType.endAttribute) {
      addChild(
        new NgAttribute.fromTokens(before, name, after),
      );
    } else {
      onError(new UnsupportedError('${after.type}'));
    }
  }

  @override
  void scanBinding(NgToken before, NgToken start) {
    var name = next();
    var end = next();
    addChild(new NgBinding.fromTokens(before, start, name, end));
  }

  @override
  void scanCloseElement(NgToken token) {
    while (token.type != NgTokenType.endCloseElement) {
      token = next();
    }
    pop();
  }

  @override
  void scanEvent(NgToken before, NgToken start) {
    var name = next();
    var equals = next();
    var value = next();
    var end = next();
    addChild(new NgEvent.fromTokens(before, start, name, equals, value, end));
  }

  @override
  void scanComment(NgToken token) {
    final comment = next();
    assert(comment.type == NgTokenType.commentNode);
    addChild(new NgComment.fromTokens(token, comment, next()));
  }

  @override
  void scanOpenElement(NgToken token) {
    var tagName = next();
    assert(tagName.type == NgTokenType.elementName);
    var element = new NgElement.unknown(tagName.text);
    addChild(element);
    push(element);
    while (token.type != NgTokenType.endOpenElement &&
        token.type != NgTokenType.beforeElementDecorator) {
      token = next();
    }
    if (token.type == NgTokenType.beforeElementDecorator) {
      scanToken(token);
      var end = next();
      assert(end == null || end.type == NgTokenType.endOpenElement);
    }
  }

  @override
  void scanProperty(NgToken before, NgToken start) {
    var name = next();
    var equals = next();
    var value = next();
    var end = next();
    addChild(
        new NgProperty.fromTokens(before, start, name, equals, value, end));
  }

  @override
  void scanInterpolation(NgToken start) {
    addChild(new NgInterpolation.fromTokens(start, next(), next()));
  }

  @override
  void scanText(NgToken token) {
    addChild(new NgText(token.text, token));
  }

  @override
  void scanBanana(NgToken before, NgToken start) {
    var name = next();
    var equals = next();
    var value = next();
    var end = next();
    addChild(
      new NgProperty.fromTokens(before, start, name, equals, value, end));
    addChild(
      new NgEvent.fromBanana(before, start, name, equals, value, end));
  }

  @override
  void scanStructural(NgToken before, NgToken start) {
    var name = next();
    var equals = next();
    var value = next();
    var end = next();
    var old = pop();
    // will this work in general?  what about duplicate tags?
    final idx = peek().childNodes.lastIndexOf(old);
    // if the index is -1, then we have already added a structural tag.
    if (idx == -1) {
      onError(new StateError('Elements can only have one structural directive'));
      push(old);
      return;
    }
    peek().childNodes.removeAt(idx);
    var newOld = new NgElement.unknown('template', childNodes: [
      new NgProperty.fromTokens(before, start, name, equals, value, end),
      old
    ]);
    addChild(newOld);
    push(old);
  }

  @override
  onError(Error error) => errorHandler != null ? errorHandler(error) : null;
}
