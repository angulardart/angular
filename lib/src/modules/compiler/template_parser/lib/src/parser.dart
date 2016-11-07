import 'ast.dart';
import 'lexer.dart';
import 'errors.dart';
import 'utils.dart';

import 'package:source_span/src/span.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/token.dart' as analyzer;

// WIP - stll sorting out what is a valid element.
final RegExp _elementValidator = new RegExp(r'[a-zA-Z][a-zA-Z0-9_\-]+');


/// Parses an Angular Dart template into a concrete AST.
///
/// See `./doc/syntax.md` for more information.
class NgTemplateParser {
  const NgTemplateParser();

  /// Parses [template] from [sourceUrl] into a series of AST nodes.
  ///
  /// If [onError] is set, errors are *not* thrown during parsing, and instead
  /// are emitted as events on the callback.
  Iterable<NgAstNode> parse(
    String template, {
    ErrorCallback onError,
    /* Uri|String*/
    sourceUrl,
  }) {
    if (template == null || template.isEmpty) return const [];
    var scanner = new _ScannerParser(errorHandler: onError);
    scanner.scan(new NgTemplateLexer(template, sourceUrl: sourceUrl));
    return scanner.result();
  }
}

class _Fragment implements NgAstNode {
  @override
  final List<NgAstNode> childNodes = <NgAstNode>[];

  @override
  final List<NgToken> parsedTokens = <NgToken>[];

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

  /// Adds parsed tokens to an NgElement tag.
  void addTokens(NgToken token) {
    peek().parsedTokens.add(token);
  }

  void addAllTokens(Iterable<NgToken> tokens) {
    peek().parsedTokens.addAll(tokens);
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
      final end = next();
      addChild(
        new NgAttribute.fromTokensWithValue(before, name, space, value, end),
      );
      addAllTokens([before, name, space, value, end]);
    } else if (after.type == NgTokenType.endAttribute) {
      addChild(
        new NgAttribute.fromTokens(before, name, after),
      );
      addAllTokens([before, name, after]);
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
    var node = new NgEvent.fromTokens(before, start, name, equals, value, end);
    try {
      node..expression = parseAngularExpression(value.text, 'event node');
    } on AnalyzerErrorGroup catch (e) {
      onError(new InvalidDartExpressionError(value, e));
      return;
    }
    addChild(node);
    addAllTokens([before, start, name, equals, value, end]);
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
    if (_elementValidator.stringMatch(tagName.text) != tagName.text) {
      onError(new IllegalTagNameError(tagName));
    }
    var element = new NgElement.unknown(tagName.text, parsedTokens: [token, tagName]);
    addChild(element);
    push(element);
    while (token.type != NgTokenType.endOpenElement &&
        token.type != NgTokenType.beforeElementDecorator) {
      token = next();
      addTokens(token);
    }
    if (token.type == NgTokenType.beforeElementDecorator) {
      scanToken(token);
      var end = next();
      addTokens(end);
      assert(end == null || end.type == NgTokenType.endOpenElement);
    }
  }

  @override
  void scanProperty(NgToken before, NgToken start) {
    var name = next();
    var equals = next();
    var value = next();
    var end = next();
    var node = new NgProperty.fromTokens(before, start, name, equals, value, end);
    try {
      node..expression = parseAngularExpression(value.text, 'property node');
    } on AnalyzerErrorGroup catch (e) {
      onError(new InvalidDartExpressionError(value, e));
      return;
    }
    addChild(node);
    addAllTokens([before, start, name, equals, value, end]);
  }

  @override
  void scanInterpolation(NgToken start) {
    var value = next();
    var end = next();
    var node = new NgInterpolation.fromTokens(start, value, end);
    try {
      node..expression = parseAngularExpression(value.text, 'interpolation node');
    } on AnalyzerErrorGroup catch (e) {
      onError(new InvalidDartExpressionError(value, e));
      return;
    }
    addChild(node);
  }

  @override
  void scanText(NgToken token) {
    addChild(new NgText(token.text, token));
  }

  @override
  void scanBanana(NgToken before, NgToken start) {
    const String location = 'bananan (in a box)';
    var name = next();
    var equals = next();
    var value = next();
    var end = next();
    Expression expression;
    try {
      expression = parseAngularExpression(value.text, location);
      if (expression.beginToken.type != analyzer.TokenType.IDENTIFIER ||
          expression.beginToken != expression.endToken) {
            onError(new BananaLimitedIdentifierError(value));
            return;
          }
    } on AnalyzerErrorGroup catch (e) {
      onError(new InvalidDartExpressionError(value, e));
      return;
    }
    addChild(
      new NgProperty.fromTokens(before, start, name, equals, value, end)
        ..expression = expression);
    // In theory, this second parse should never fail provided the first
    // is only an identifier.
    addChild(
      new NgEvent.fromBanana(before, start, name, equals, value, end)
        ..expression = parseAngularExpression('${value.text} = \$event',
          location));
    addAllTokens([before, start, name, equals, value, end]);
  }

  @override
  void scanStructural(NgToken before, NgToken start) {
    // The element that the structural directive will exist on.
    final NgElement element = peek();

    // Parse all of the tokens that make up the structual directive.
    var name = next();
    var equals = next();
    var value = next();
    var end = next();
    var old = pop();

    // will this work in general?  what about duplicate tags?
    final idx = peek().childNodes.lastIndexOf(old);

    // if the index is -1, then we have already added a structural tag.
    if (idx == -1) {
      final NgProperty firstDirective = peek().childNodes.first.childNodes.first;
      onError(
        new ExtraStructuralDirectiveError(
          element,
          start,
          name,
          value,
          firstDirective.parsedTokens[2],
          firstDirective.parsedTokens[4],
        ),
      );
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
    addAllTokens([before, start, name, equals, value, end]);
  }

  @override
  void onError(Error error) {
    if (errorHandler != null) {
      errorHandler(error);
    } else {
      throw error;
    }
  }
}
