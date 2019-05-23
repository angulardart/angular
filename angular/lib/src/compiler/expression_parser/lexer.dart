enum TokenType { Character, Identifier, Keyword, String, Operator, Number }

class LexerError extends Error {
  String input;
  int position;
  String message;

  String get messageWithPosition =>
      '$message at offset $position of expression';

  @override
  toString() =>
      'Lexer Error: $message at column $position in expression [$input]';

  LexerError(this.message, this.position, this.input);
}

class Lexer {
  List<Token> tokenize(String text) {
    var scanner = _Scanner(text);
    var tokens = <Token>[];
    var token = scanner.scanToken();
    while (token != null) {
      tokens.add(token);
      token = scanner.scanToken();
    }
    return tokens;
  }
}

class Token {
  final int index;
  final TokenType type;
  final num numValue;
  final String strValue;

  Token(this.index, this.type, this.numValue, this.strValue);

  bool isCharacter(num code) => type == TokenType.Character && numValue == code;

  bool get isNumber => type == TokenType.Number;

  bool get isString => type == TokenType.String;

  bool isOperator(String operator) =>
      type == TokenType.Operator && strValue == operator;

  bool get isIdentifier => type == TokenType.Identifier;

  bool get isKeyword => type == TokenType.Keyword;

  bool get isKeywordDeprecatedVar =>
      type == TokenType.Keyword && strValue == 'var';

  bool get isKeywordLet => type == TokenType.Keyword && strValue == 'let';

  bool get isKeywordNull => type == TokenType.Keyword && strValue == 'null';

  bool get isKeywordUndefined =>
      type == TokenType.Keyword && strValue == 'undefined';

  bool get isKeywordTrue => type == TokenType.Keyword && strValue == 'true';

  bool get isKeywordFalse => type == TokenType.Keyword && strValue == 'false';

  /// Returns numeric value or -1 if not a number token type. -1 is parsed as
  /// unaryminus(1) so it is ok to use here.
  num toNumber() => type == TokenType.Number ? numValue : -1;

  @override
  String toString() {
    switch (type) {
      case TokenType.Character:
      case TokenType.Identifier:
      case TokenType.Keyword:
      case TokenType.Operator:
      case TokenType.String:
        return strValue;
      case TokenType.Number:
        return numValue.toString();
      default:
        return null;
    }
  }
}

Token newCharacterToken(int index, int code) =>
    Token(index, TokenType.Character, code, String.fromCharCode(code));

Token newIdentifierToken(int index, String text) =>
    Token(index, TokenType.Identifier, 0, text);

Token newKeywordToken(int index, String text) =>
    Token(index, TokenType.Keyword, 0, text);

Token newOperatorToken(int index, String text) =>
    Token(index, TokenType.Operator, 0, text);

Token newStringToken(int index, String text) =>
    Token(index, TokenType.String, 0, text);

Token newNumberToken(int index, num n) => Token(index, TokenType.Number, n, '');

final Token EOF = Token(-1, TokenType.Character, 0, '');

const int $EOF = 0;
const int $TAB = 9;
const int $LF = 10;
const int $VTAB = 11;
const int $FF = 12;
const int $CR = 13;
const int $SPACE = 32;
const int $BANG = 33;
const int $DQ = 34;
const int $HASH = 35;
const int $$ = 36;
const int $PERCENT = 37;
const int $AMPERSAND = 38;
const int $SQ = 39;
const int $LPAREN = 40;
const int $RPAREN = 41;
const int $STAR = 42;
const int $PLUS = 43;
const int $COMMA = 44;
const int $MINUS = 45;
const int $PERIOD = 46;
const int $SLASH = 47;
const int $COLON = 58;
const int $SEMICOLON = 59;
const int $LT = 60;
const int $EQ = 61;
const int $GT = 62;
const int $QUESTION = 63;
const int $0 = 48;
const int $9 = 57;
const int $A = 65, $E = 69, $Z = 90;
const int $LBRACKET = 91;
const int $BACKSLASH = 92;
const int $RBRACKET = 93;
const int $CARET = 94;
const int $_ = 95;
const int $BT = 96;
const int $a = 97,
    $e = 101,
    $f = 102,
    $n = 110,
    $r = 114,
    $t = 116,
    $u = 117,
    $v = 118,
    $z = 122;
const int $LBRACE = 123;
const int $BAR = 124;
const int $RBRACE = 125;
const int $NBSP = 160;

class ScannerError extends Error {
  final String message;

  ScannerError(this.message);

  @override
  String toString() => message;
}

class _Scanner {
  String input;
  num length;
  int peek = 0;
  int index = -1;

  _Scanner(this.input) {
    this.length = input.length;
    this.advance();
  }
  void advance() {
    peek = ++index >= length ? $EOF : input.codeUnitAt(index);
  }

  Token scanToken() {
    var input = this.input,
        length = this.length,
        charAfterWhitespace = peek,
        indexAfterWhitespace = index;
    // Skip whitespace.
    while (charAfterWhitespace <= $SPACE) {
      if (++indexAfterWhitespace >= length) {
        charAfterWhitespace = $EOF;
        break;
      } else {
        charAfterWhitespace = input.codeUnitAt(indexAfterWhitespace);
      }
    }
    peek = charAfterWhitespace;
    index = indexAfterWhitespace;

    if (index >= length) {
      return null;
    }

    // Handle identifiers and numbers.
    if (isIdentifierStart(peek)) return scanIdentifier();
    if (isDigit(peek)) return scanNumber(index);
    int start = index;
    switch (peek) {
      case $PERIOD:
        advance();
        return isDigit(peek)
            ? scanNumber(start)
            : newCharacterToken(start, $PERIOD);
      case $LPAREN:
      case $RPAREN:
      case $LBRACE:
      case $RBRACE:
      case $LBRACKET:
      case $RBRACKET:
      case $COMMA:
      case $COLON:
      case $SEMICOLON:
        return scanCharacter(start, peek);
      case $SQ:
      case $DQ:
        return scanString();
      case $HASH:
      case $PLUS:
      case $MINUS:
      case $STAR:
      case $SLASH:
      case $PERCENT:
      case $CARET:
        return scanOperator(start, String.fromCharCode(peek));
      case $QUESTION:
        return scanComplexOperator(start, '?', $PERIOD, '.', $QUESTION, '?');
      case $LT:
      case $GT:
        return scanComplexOperator(start, String.fromCharCode(peek), $EQ, '=');
      case $BANG:
      case $EQ:
        return scanComplexOperator(
            start, String.fromCharCode(peek), $EQ, '=', $EQ, '=');
      case $AMPERSAND:
        return scanComplexOperator(start, '&', $AMPERSAND, '&');
      case $BAR:
        return scanComplexOperator(start, '|', $BAR, '|');
      case $NBSP:
        while (isWhitespace(this.peek)) {
          advance();
        }
        return scanToken();
    }
    error('Unexpected character [${String.fromCharCode(peek)}]', 0);
    return null;
  }

  Token scanCharacter(int start, int code) {
    advance();
    return newCharacterToken(start, code);
  }

  Token scanOperator(int start, String str) {
    advance();
    return newOperatorToken(start, str);
  }

  /// Tokenize a 2/3 char long operator
  Token scanComplexOperator(int start, String one, int twoCode, String two,
      [int threeCode, String three]) {
    advance();
    String str = one;
    if (peek == twoCode) {
      advance();
      str += two;
    }
    if (threeCode != null && peek == threeCode) {
      advance();
      str += three;
    }
    return newOperatorToken(start, str);
  }

  Token scanIdentifier() {
    int startIndex = index;
    advance();
    while (isIdentifierPart(peek)) {
      advance();
    }
    String str = input.substring(startIndex, index);
    if (keywords.contains(str)) {
      return newKeywordToken(startIndex, str);
    } else {
      return newIdentifierToken(startIndex, str);
    }
  }

  Token scanNumber(int start) {
    bool simple = index == start;
    advance();
    while (true) {
      if (isDigit(peek)) {
        // Intentionally left blank.
      } else if (peek == $PERIOD) {
        simple = false;
      } else if (isExponentStart(peek)) {
        advance();
        if (isExponentSign(peek)) advance();
        if (!isDigit(this.peek)) error('Invalid exponent', -1);
        simple = false;
      } else {
        break;
      }
      advance();
    }
    String str = input.substring(start, index);
    num value = simple ? int.parse(str) : double.parse(str);
    return newNumberToken(start, value);
  }

  Token scanString() {
    final quote = peek;
    final start = index;
    advance(); // Consume opening quote.
    StringBuffer buffer;
    var marker = index;
    while (true) {
      if (peek == quote) {
        var value = input.substring(marker, index);
        if (buffer != null) {
          // Only use buffer if it was created for an escaped code point.
          buffer.write(value);
          value = buffer.toString();
        }
        advance(); // Consume closing quote.
        return newStringToken(start, value);
      } else if (peek == $BACKSLASH) {
        buffer ??= StringBuffer();
        buffer.write(input.substring(marker, index));
        buffer.writeCharCode(_consumeEscape());
        marker = index;
      } else if (peek == $EOF) {
        error('Unterminated quote', 0);
      } else {
        advance();
      }
    }
  }

  void error(String message, int offset) {
    int position = this.index + offset;
    throw LexerError(message, position, input);
  }

  int _consumeEscape() {
    advance(); // Consume '\'.
    final escapeStart = index;
    // Check if we're consuming a Unicode code point.
    if (peek == $u) {
      advance(); // Consume 'u'.
      String hex;
      if (peek == $LBRACE) {
        advance(); // Consume '{'.
        final start = index;
        // Consume 1-6 hexadecimal digits.
        for (var i = 0; i < 6; ++i) {
          if (peek == $EOF) {
            error('Incomplete escape sequence', escapeStart - index);
          } else if (i != 0 && peek == $RBRACE) {
            break;
          } else {
            advance();
          }
        }
        hex = input.substring(start, index);
        if (peek != $RBRACE) {
          error("Expected '}'", 0);
        }
        advance(); // Consume '}'.
      } else {
        // Consume exactly 4 hexadecimal digits.
        if (index + 4 >= input.length) {
          error('Expected four hexadecimal digits', 0);
        }
        final start = index;
        for (var i = 4; i > 0; --i) {
          advance();
        }
        hex = input.substring(start, index);
      }
      final unescaped = int.tryParse(hex, radix: 16);
      if (unescaped == null || unescaped > 0x10FFFF) {
        error('Invalid unicode escape [\\u$hex]', escapeStart - index);
      }
      return unescaped;
    } else {
      final unescaped = unescape(peek);
      advance();
      return unescaped;
    }
  }
}

bool isWhitespace(num code) =>
    (code >= $TAB && code <= $SPACE) || (code == $NBSP);

bool isIdentifierStart(num code) =>
    ($a <= code && code <= $z) ||
    ($A <= code && code <= $Z) ||
    (code == $_) ||
    (code == $$);

bool isIdentifier(String input) {
  if (input.isEmpty) return false;
  var scanner = _Scanner(input);
  if (!isIdentifierStart(scanner.peek)) return false;
  scanner.advance();
  while (!identical(scanner.peek, $EOF)) {
    if (!isIdentifierPart(scanner.peek)) return false;
    scanner.advance();
  }
  return true;
}

bool isIdentifierPart(int code) =>
    ($a <= code && code <= $z) ||
    ($A <= code && code <= $Z) ||
    ($0 <= code && code <= $9) ||
    (code == $_) ||
    (code == $$);

bool isDigit(int code) => $0 <= code && code <= $9;

bool isExponentStart(int code) => code == $e || code == $E;

bool isExponentSign(num code) => code == $MINUS || code == $PLUS;

bool isQuote(int code) =>
    identical(code, $SQ) || identical(code, $DQ) || identical(code, $BT);

int unescape(int code) {
  switch (code) {
    case $n:
      return $LF;
    case $f:
      return $FF;
    case $r:
      return $CR;
    case $t:
      return $TAB;
    case $v:
      return $VTAB;
    default:
      return code;
  }
}

const keywords = {
  'var',
  'let',
  'null',
  'undefined',
  'true',
  'false',
  'if',
  'else',
};
