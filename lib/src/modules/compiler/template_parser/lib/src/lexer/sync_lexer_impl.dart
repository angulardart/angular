part of angular2_template_parser.src.lexer;

class _SyncNgTemplateLexer extends NgTemplateLexerBase {
  _State state;

  _SyncNgTemplateLexer(SpanScanner scanner) : super(scanner);

  @override
  void doTokenize() {
    state = _State.scanningText;
    while (hasNext) {
      var char = peek();
      switch (state) {
        case _State.scanningText:
          if (char == $lt) {
            final textNode = span();
            if (textNode.length > 0) {
              addToken(NgTokenType.textNode, textNode);
            }
            advance();
            if (peek() == $slash) {
              advance();
              addToken(NgTokenType.startCloseElement, span());
              while (peek() != $gt) {
                advance();
              }
              addToken(NgTokenType.closeElementName, span());
              advance();
              addToken(NgTokenType.endCloseElement, span());
              state = _State.scanningText;
            } else {
              addToken(NgTokenType.startOpenElement, span());
              state = _State.startingElement;
            }
          } else {
            advance();
          }
          break;
        case _State.startingElement:
          if (char == $gt) {
            addToken(NgTokenType.elementName, span());
            advance();
            addToken(NgTokenType.endOpenElement, span());
            state = _State.scanningText;
          } else {
            advance();
          }
          break;
      }
    }
    if (state == _State.scanningText) {
      final textNode = span();
      if (textNode.length > 0) {
        addToken(NgTokenType.textNode, textNode);
      }
    }
    _tokenizer.close();
  }
}

enum _State {
  scanningText,
  startingElement,
}
