import '../../facade/exceptions.dart' show BaseException;

// TODO: Remove the following lines (for --no-implicit-casts).
// ignore_for_file: argument_type_not_assignable
// ignore_for_file: invalid_assignment
// ignore_for_file: list_element_type_not_assignable
// ignore_for_file: non_bool_operand
// ignore_for_file: return_of_invalid_type

enum TokenType { Character, Identifier, Keyword, String, Operator, Number }

class Lexer {
  List<Token> tokenize(String text) {
    var scanner = new _Scanner(text);
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
  final num index;
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

Token newCharacterToken(num index, num code) =>
    new Token(index, TokenType.Character, code, new String.fromCharCode(code));

Token newIdentifierToken(num index, String text) =>
    new Token(index, TokenType.Identifier, 0, text);

Token newKeywordToken(num index, String text) =>
    new Token(index, TokenType.Keyword, 0, text);

Token newOperatorToken(num index, String text) =>
    new Token(index, TokenType.Operator, 0, text);

Token newStringToken(num index, String text) =>
    new Token(index, TokenType.String, 0, text);

Token newNumberToken(num index, num n) =>
    new Token(index, TokenType.Number, n, '');

final Token EOF = new Token(-1, TokenType.Character, 0, '');

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

class ScannerError extends BaseException {
  @override
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
    num start = index;
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
        return scanOperator(start, new String.fromCharCode(peek));
      case $QUESTION:
        return scanComplexOperator(start, '?', $PERIOD, '.', $QUESTION, '?');
      case $LT:
      case $GT:
        return scanComplexOperator(
            start, new String.fromCharCode(peek), $EQ, '=');
      case $BANG:
      case $EQ:
        return scanComplexOperator(
            start, new String.fromCharCode(peek), $EQ, '=', $EQ, '=');
      case $AMPERSAND:
        return scanComplexOperator(start, '&', $AMPERSAND, '&');
      case $BAR:
        return scanComplexOperator(start, '|', $BAR, '|');
      case $NBSP:
        while (isWhitespace(this.peek)) advance();
        return scanToken();
    }
    error('Unexpected character [${ new String.fromCharCode(peek)}]', 0);
    return null;
  }

  Token scanCharacter(num start, num code) {
    advance();
    return newCharacterToken(start, code);
  }

  Token scanOperator(num start, String str) {
    advance();
    return newOperatorToken(start, str);
  }

  /// Tokenize a 2/3 char long operator
  Token scanComplexOperator(num start, String one, num twoCode, String two,
      [num threeCode, String three]) {
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
    num startIndex = index;
    advance();
    while (isIdentifierPart(peek)) advance();
    String str = input.substring(startIndex, index);
    if (KEYWORDS.contains(str)) {
      return newKeywordToken(startIndex, str);
    } else {
      return newIdentifierToken(startIndex, str);
    }
  }

  Token scanNumber(int start) {
    bool simple = index == start;
    advance();
    while (true) {
      if (isDigit(peek)) {} else if (peek == $PERIOD) {
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
    num start = index;
    num quote = peek;
    this.advance();
    List<String> buffer;
    num marker = index;
    String input = this.input;
    while (peek != quote) {
      if (peek == $BACKSLASH) {
        buffer ??= <String>[];
        buffer.add(input.substring(marker, index));
        advance();
        num unescapedCode;
        if (peek == $u) {
          // 4 character hex code for unicode character.
          String hex = input.substring(index + 1, index + 5);
          try {
            unescapedCode = int.parse(hex, radix: 16);
          } catch (e) {
            this.error('Invalid unicode escape [\\u$hex]', 0);
          }
          for (num i = 0; i < 5; i++) {
            advance();
          }
        } else {
          unescapedCode = unescape(peek);
          advance();
        }
        buffer.add(new String.fromCharCode(unescapedCode));
        marker = index;
      } else if (peek == $EOF) {
        error('Unterminated quote', 0);
      } else {
        advance();
      }
    }
    String last = input.substring(marker, index);
    advance();
    // Compute the unescaped string value.
    String unescaped = last;
    if (buffer != null) {
      buffer.add(last);
      unescaped = buffer.join('');
    }
    return newStringToken(start, unescaped);
  }

  void error(String message, int offset) {
    int position = this.index + offset;
    throw new ScannerError(
        'Lexer Error: $message at column $position in expression [$input]');
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
  if (input.length == 0) return false;
  var scanner = new _Scanner(input);
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

num unescape(int code) {
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

final OPERATORS = new Set<String>.from(const [
  '+',
  '-',
  '*',
  '/',
  '%',
  '^',
  '=',
  '==',
  '!=',
  '===',
  '!==',
  '<',
  '>',
  '<=',
  '>=',
  '&&',
  '||',
  '&',
  '|',
  '!',
  '?',
  '#',
  '?.',
  '??',
]);

final KEYWORDS = new Set<String>.from(const [
  'var',
  'let',
  'null',
  'undefined',
  'true',
  'false',
  'if',
  'else',
]);
