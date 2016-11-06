part of angular2_template_parser.src.lexer;

/// Simple interface for using an [NgTemplateLexer] to parse nodes.
abstract class NgTemplateScanner<T> {
  final List<T> _stack = <T>[];

  Iterator<NgToken> _iterator;
  bool _canAcceptChildren = true;

  /// Whether child nodes (not decorators) can be added.
  bool get canAcceptChildren => _canAcceptChildren;

  /// Peeks at the top of the stack.
  T peek() => _stack.last;

  /// Pops the top of the stack.
  T pop() => _stack.removeLast();

  /// Push an item to the top of the stack.
  void push(T node) {
    _stack.add(node);
  }

  /// Returns the next token.
  NgToken next() => (_iterator..moveNext()).current;

  /// Scans from [lexer].
  List<T> scan(NgTemplateLexer lexer) {
    _iterator = lexer.tokenize().iterator;
    scanToken(next());
    return result();
  }

  /// Scans a [token].
  void scanToken(NgToken token) {
    switch (token.type) {
      case NgTokenType.textNode:
        scanText(token);
        break;
      case NgTokenType.startInterpolate:
        scanInterpolation(token);
        break;
      case NgTokenType.startOpenElement:
        scanOpenElement(token);
        _canAcceptChildren = false;
        break;
      case NgTokenType.startCloseElement:
        scanCloseElement(token);
        break;
      case NgTokenType.beginComment:
        scanComment(token);
        break;
      case NgTokenType.beforeElementDecorator:
        var decorator = next();
        if (decorator.type == NgTokenType.attributeName) {
          scanAttribute(token, decorator);
        } else if (decorator.type == NgTokenType.startProperty) {
          scanProperty(token, decorator);
        } else if (decorator.type == NgTokenType.startEvent) {
          scanEvent(token, decorator);
        } else if (decorator.type == NgTokenType.startBinding) {
          scanBinding(token, decorator);
        } else if (decorator.type == NgTokenType.startBanana) {
          scanBanana(token, decorator);
        } else if (decorator.type == NgTokenType.startStructural) {
          scanStructural(token, decorator);
        }
        var after = next();
        if (after.type == NgTokenType.endOpenElement) {
          _canAcceptChildren = true;
        } else {
          scanToken(after);
        }
        break;
      default:
        throw new UnsupportedError(
            '${token.source.message(token.type.toString())}');
    }
    var after = next();
    if (after != null) {
      scanToken(after);
    }
  }

  /// Returns the scanned result.
  List<T> result();

  /// Called when ...
  void scanAttribute(NgToken before, NgToken actual);

  /// Called when...
  void scanBinding(NgToken before, NgToken start);

  /// Called when [NgTokenType.beginComment] is scanned.
  void scanComment(NgToken token);

  /// Called when ...
  void scanEvent(NgToken before, NgToken start);

  /// Called when [NgTokenType.startOpenElement] is scanned.
  ///
  /// Expected to return the `<tag>` being opened.
  void scanOpenElement(NgToken token);

  /// Called when ...
  void scanProperty(NgToken before, NgToken start);

  /// Called when [NgTokenType.startCloseElement]
  void scanCloseElement(NgToken token);

  /// Called when ...
  void scanInterpolation(NgToken token);

  /// Called when [NgTokenType.textNode] is scanned.
  void scanText(NgToken token);

  /// Called when [NgTokenType.startBanana] is scanned.
  ///
  /// Creates both a property and an event.
  void scanBanana(NgToken token, NgToken start);

  /// Called when [NgTokenType.startStructural] is scanned.
  ///
  /// Creates a parent template tag with a property
  void scanStructural(NgToken token, NgToken start);

  /// Called to notify that warnings or errors were found in a template.
  ///
  /// It is an implementation detail how the parser should recover.
  void onError(Error error);
}
