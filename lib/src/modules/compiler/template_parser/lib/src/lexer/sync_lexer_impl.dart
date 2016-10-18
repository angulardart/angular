part of angular2_template_parser.src.lexer;

class _SyncNgTemplateLexer extends NgTemplateLexerBase {
  _SyncNgTemplateLexer(SpanScanner scanner) : super(scanner);

  // Returns the first non-whitespace character while scanning forward.
  int _consumeWhitespace() {
    var char = peek();
    while (isWhiteSpace(char)) {
      advance();
      char = peek();
    }
    return char;
  }

  // <button class="foo" [title]="title" (click)="onClick"></button>
  //         ^           ^               ^
  void _scanDecorator() {
    switch (peek()) {
      case $openEvent:
        advance();
        addToken(NgTokenType.startEvent);
        return _scanEvent();
      case $openProperty:
        advance();
        addToken(NgTokenType.startProperty);
        return _scanProperty();
      default:
        return _scanAttributeName();
    }
  }

  // <button class="foo" disabled title="Hello"></button>
  //         ^^^^^       ^^^^^^^^ ^^^^^
  void _scanAttributeName() {
    // Stop once we encounter whitespace, `=`, or `>`.
    var char = peek();
    while (!isWhiteSpace(char) && char != $equal && char != $gt) {
      advance();
      char = peek();
    }
    switch (char) {
      case $equal: // Value
        addToken(NgTokenType.attributeName);
        advance();
        return _scanAttributeValue();
      case $gt: // End of element
        addToken(NgTokenType.attributeName);
        addToken(NgTokenType.endAttribute);
        advance();
        addToken(NgTokenType.endOpenElement);
        return _scanText();
      default: // Whitespace
        addToken(NgTokenType.attributeName);
        addToken(NgTokenType.endAttribute);
        advance();
        return _scanDecorator();
    }
  }

  void _scanAfterDecorator() {
    _consumeWhitespace();
    if (peek() == $gt) {
      advance();
      addToken(NgTokenType.endOpenElement);
      _scanText();
    } else {
      addToken(NgTokenType.beforeElementDecorator);
      advance();
      _scanDecorator();
    }
  }

  // <button class="foo" disabled title="Hello"></button>
  //               ^^^^^                ^^^^^^^
  void _scanAttributeValue() {
    _consumeWhitespace();
    // Assume this is a `"` character, for now.
    advance();
    addToken(NgTokenType.beforeDecoratorValue);
    var char = peek();
    while (char != $double_quote) {
      advance();
      char = peek();
    }
    addToken(NgTokenType.attributeValue);
    advance();
    addToken(NgTokenType.endAttribute);
    _scanAfterDecorator();
  }

  void _scanProperty() {
    throw new UnimplementedError();
  }

  void _scanEvent() {
    throw new UnimplementedError();
  }

  void _scanText() {
    var char = peek();
    while (char != $lt && char != null) {
      advance();
      char = peek();
    }
    var textSpan = span();
    if (textSpan.length > 0) {
      addToken(NgTokenType.textNode, textSpan);
    }
    if (char == null) {
      return;
    }
    // Either a new element or close the last one.
    advance();
    if (peek() == $slash) {
      advance();
      _scanCloseElement();
    } else {
      _scanOpenElement();
    }
  }

  void _scanOpenElement() {
    addToken(NgTokenType.startOpenElement);
    _scanElementName();
  }

  void _scanCloseElement() {
    addToken(NgTokenType.startCloseElement);
    _scanElementName(true);
  }

  void _scanElementName([bool closingTag = false]) {
    var char = peek();
    while (!isWhiteSpace(char) && char != $gt) {
      advance();
      char = peek();
    }
    addToken(NgTokenType.elementName);
    if (char == $gt) {
      if (closingTag) {
        advance();
        addToken(NgTokenType.endCloseElement);
      } else {
        advance();
        addToken(NgTokenType.endOpenElement);
      }
      _scanText();
    } else {
      advance();
      _consumeWhitespace();
      addToken(NgTokenType.beforeElementDecorator);
      _scanDecorator();
    }
  }

  @override
  void doTokenize() {
    _scanText();
    final textNode = span();
    if (textNode.length > 0) {
      addToken(NgTokenType.textNode, textNode);
    }
    _tokenizer.close();
  }
}
