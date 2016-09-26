import "package:angular2/src/core/di/decorators.dart" show Injectable;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

enum TokenType { Character, Identifier, Keyword, String, Operator, Number }

@Injectable()
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
  num index;
  TokenType type;
  num numValue;
  String strValue;
  Token(this.index, this.type, this.numValue, this.strValue);
  bool isCharacter(num code) {
    return (this.type == TokenType.Character && this.numValue == code);
  }

  bool isNumber() {
    return (this.type == TokenType.Number);
  }

  bool isString() {
    return (this.type == TokenType.String);
  }

  bool isOperator(String operator) {
    return (this.type == TokenType.Operator && this.strValue == operator);
  }

  bool isIdentifier() {
    return (this.type == TokenType.Identifier);
  }

  bool isKeyword() {
    return (this.type == TokenType.Keyword);
  }

  bool isKeywordDeprecatedVar() {
    return (this.type == TokenType.Keyword && this.strValue == "var");
  }

  bool isKeywordLet() {
    return (this.type == TokenType.Keyword && this.strValue == "let");
  }

  bool isKeywordNull() {
    return (this.type == TokenType.Keyword && this.strValue == "null");
  }

  bool isKeywordUndefined() {
    return (this.type == TokenType.Keyword && this.strValue == "undefined");
  }

  bool isKeywordTrue() {
    return (this.type == TokenType.Keyword && this.strValue == "true");
  }

  bool isKeywordFalse() {
    return (this.type == TokenType.Keyword && this.strValue == "false");
  }

  num toNumber() {
    // -1 instead of NULL ok?
    return (this.type == TokenType.Number) ? this.numValue : -1;
  }

  String toString() {
    switch (this.type) {
      case TokenType.Character:
      case TokenType.Identifier:
      case TokenType.Keyword:
      case TokenType.Operator:
      case TokenType.String:
        return this.strValue;
      case TokenType.Number:
        return this.numValue.toString();
      default:
        return null;
    }
  }
}

Token newCharacterToken(num index, num code) {
  return new Token(
      index, TokenType.Character, code, new String.fromCharCode(code));
}

Token newIdentifierToken(num index, String text) {
  return new Token(index, TokenType.Identifier, 0, text);
}

Token newKeywordToken(num index, String text) {
  return new Token(index, TokenType.Keyword, 0, text);
}

Token newOperatorToken(num index, String text) {
  return new Token(index, TokenType.Operator, 0, text);
}

Token newStringToken(num index, String text) {
  return new Token(index, TokenType.String, 0, text);
}

Token newNumberToken(num index, num n) {
  return new Token(index, TokenType.Number, n, "");
}

Token EOF = new Token(-1, TokenType.Character, 0, "");
const $EOF = 0;
const $TAB = 9;
const $LF = 10;
const $VTAB = 11;
const $FF = 12;
const $CR = 13;
const $SPACE = 32;
const $BANG = 33;
const $DQ = 34;
const $HASH = 35;
const $$ = 36;
const $PERCENT = 37;
const $AMPERSAND = 38;
const $SQ = 39;
const $LPAREN = 40;
const $RPAREN = 41;
const $STAR = 42;
const $PLUS = 43;
const $COMMA = 44;
const $MINUS = 45;
const $PERIOD = 46;
const $SLASH = 47;
const $COLON = 58;
const $SEMICOLON = 59;
const $LT = 60;
const $EQ = 61;
const $GT = 62;
const $QUESTION = 63;
const $0 = 48;
const $9 = 57;
const $A = 65, $E = 69, $Z = 90;
const $LBRACKET = 91;
const $BACKSLASH = 92;
const $RBRACKET = 93;
const $CARET = 94;
const $_ = 95;
const $BT = 96;
const $a = 97,
    $e = 101,
    $f = 102,
    $n = 110,
    $r = 114,
    $t = 116,
    $u = 117,
    $v = 118,
    $z = 122;
const $LBRACE = 123;
const $BAR = 124;
const $RBRACE = 125;
const $NBSP = 160;

class ScannerError extends BaseException {
  final String message;
  ScannerError(this.message);
  String toString() {
    return this.message;
  }
}

class _Scanner {
  String input;
  num length;
  num peek = 0;
  num index = -1;
  _Scanner(this.input) {
    this.length = input.length;
    this.advance();
  }
  void advance() {
    this.peek =
        ++this.index >= this.length ? $EOF : this.input.codeUnitAt(this.index);
  }

  Token scanToken() {
    var input = this.input,
        length = this.length,
        peek = this.peek,
        index = this.index;
    // Skip whitespace.
    while (peek <= $SPACE) {
      if (++index >= length) {
        peek = $EOF;
        break;
      } else {
        peek = input.codeUnitAt(index);
      }
    }
    this.peek = peek;
    this.index = index;
    if (index >= length) {
      return null;
    }
    // Handle identifiers and numbers.
    if (isIdentifierStart(peek)) return this.scanIdentifier();
    if (isDigit(peek)) return this.scanNumber(index);
    num start = index;
    switch (peek) {
      case $PERIOD:
        this.advance();
        return isDigit(this.peek)
            ? this.scanNumber(start)
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
        return this.scanCharacter(start, peek);
      case $SQ:
      case $DQ:
        return this.scanString();
      case $HASH:
      case $PLUS:
      case $MINUS:
      case $STAR:
      case $SLASH:
      case $PERCENT:
      case $CARET:
        return this.scanOperator(start, new String.fromCharCode(peek));
      case $QUESTION:
        return this
            .scanComplexOperator(start, "?", $PERIOD, ".", $QUESTION, "?");
      case $LT:
      case $GT:
        return this.scanComplexOperator(
            start, new String.fromCharCode(peek), $EQ, "=");
      case $BANG:
      case $EQ:
        return this.scanComplexOperator(
            start, new String.fromCharCode(peek), $EQ, "=", $EQ, "=");
      case $AMPERSAND:
        return this.scanComplexOperator(start, "&", $AMPERSAND, "&");
      case $BAR:
        return this.scanComplexOperator(start, "|", $BAR, "|");
      case $NBSP:
        while (isWhitespace(this.peek)) this.advance();
        return this.scanToken();
    }
    this.error(
        '''Unexpected character [${ new String . fromCharCode ( peek )}]''', 0);
    return null;
  }

  Token scanCharacter(num start, num code) {
    this.advance();
    return newCharacterToken(start, code);
  }

  Token scanOperator(num start, String str) {
    this.advance();
    return newOperatorToken(start, str);
  }

  /// Tokenize a 2/3 char long operator
  Token scanComplexOperator(num start, String one, num twoCode, String two,
      [num threeCode, String three]) {
    this.advance();
    String str = one;
    if (this.peek == twoCode) {
      this.advance();
      str += two;
    }
    if (threeCode != null && this.peek == threeCode) {
      this.advance();
      str += three;
    }
    return newOperatorToken(start, str);
  }

  Token scanIdentifier() {
    num start = this.index;
    this.advance();
    while (isIdentifierPart(this.peek)) this.advance();
    String str = this.input.substring(start, this.index);
    if (KEYWORDS.contains(str)) {
      return newKeywordToken(start, str);
    } else {
      return newIdentifierToken(start, str);
    }
  }

  Token scanNumber(num start) {
    bool simple = (identical(this.index, start));
    this.advance();
    while (true) {
      if (isDigit(this.peek)) {} else if (this.peek == $PERIOD) {
        simple = false;
      } else if (isExponentStart(this.peek)) {
        this.advance();
        if (isExponentSign(this.peek)) this.advance();
        if (!isDigit(this.peek)) this.error("Invalid exponent", -1);
        simple = false;
      } else {
        break;
      }
      this.advance();
    }
    String str = this.input.substring(start, this.index);
    // TODO
    num value = simple ? int.parse(str) : double.parse(str);
    return newNumberToken(start, value);
  }

  Token scanString() {
    num start = this.index;
    num quote = this.peek;
    this.advance();
    List<String> buffer;
    num marker = this.index;
    String input = this.input;
    while (this.peek != quote) {
      if (this.peek == $BACKSLASH) {
        if (buffer == null) buffer = <String>[];
        buffer.add(input.substring(marker, this.index));
        this.advance();
        num unescapedCode;
        if (this.peek == $u) {
          // 4 character hex code for unicode character.
          String hex = input.substring(this.index + 1, this.index + 5);
          try {
            unescapedCode = int.parse(hex, radix: 16);
          } catch (e) {
            this.error('''Invalid unicode escape [\\u${ hex}]''', 0);
          }
          for (num i = 0; i < 5; i++) {
            this.advance();
          }
        } else {
          unescapedCode = unescape(this.peek);
          this.advance();
        }
        buffer.add(new String.fromCharCode(unescapedCode));
        marker = this.index;
      } else if (this.peek == $EOF) {
        this.error("Unterminated quote", 0);
      } else {
        this.advance();
      }
    }
    String last = input.substring(marker, this.index);
    this.advance();
    // Compute the unescaped string value.
    String unescaped = last;
    if (buffer != null) {
      buffer.add(last);
      unescaped = buffer.join('');
    }
    return newStringToken(start, unescaped);
  }

  void error(String message, num offset) {
    num position = this.index + offset;
    throw new ScannerError(
        '''Lexer Error: ${ message} at column ${ position} in expression [${ this . input}]''');
  }
}

bool isWhitespace(num code) {
  return (code >= $TAB && code <= $SPACE) || (code == $NBSP);
}

bool isIdentifierStart(num code) {
  return ($a <= code && code <= $z) ||
      ($A <= code && code <= $Z) ||
      (code == $_) ||
      (code == $$);
}

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

bool isIdentifierPart(num code) {
  return ($a <= code && code <= $z) ||
      ($A <= code && code <= $Z) ||
      ($0 <= code && code <= $9) ||
      (code == $_) ||
      (code == $$);
}

bool isDigit(num code) {
  return $0 <= code && code <= $9;
}

bool isExponentStart(num code) {
  return code == $e || code == $E;
}

bool isExponentSign(num code) {
  return code == $MINUS || code == $PLUS;
}

bool isQuote(num code) {
  return identical(code, $SQ) || identical(code, $DQ) || identical(code, $BT);
}

num unescape(num code) {
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

var OPERATORS = new Set.from([
  "+",
  "-",
  "*",
  "/",
  "%",
  "^",
  "=",
  "==",
  "!=",
  "===",
  "!==",
  "<",
  ">",
  "<=",
  ">=",
  "&&",
  "||",
  "&",
  "|",
  "!",
  "?",
  "#",
  "?.",
  "??"
]);
var KEYWORDS = new Set.from(
    ["var", "let", "null", "undefined", "true", "false", "if", "else"]);
