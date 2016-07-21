import "package:angular2/src/compiler/chars.dart"
    show
        isWhitespace,
        $EOF,
        $HASH,
        $TILDA,
        $CARET,
        $PERCENT,
        $$,
        $_,
        $COLON,
        $SQ,
        $DQ,
        $EQ,
        $SLASH,
        $BACKSLASH,
        $PERIOD,
        $STAR,
        $PLUS,
        $LPAREN,
        $RPAREN,
        $PIPE,
        $COMMA,
        $SEMICOLON,
        $MINUS,
        $BANG,
        $QUESTION,
        $AT,
        $AMPERSAND,
        $GT,
        $a,
        $A,
        $z,
        $Z,
        $0,
        $9,
        $FF,
        $CR,
        $LF,
        $VTAB;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart"
    show StringWrapper, isPresent, resolveEnumToken;

export "package:angular2/src/compiler/chars.dart"
    show
        $EOF,
        $AT,
        $RBRACE,
        $LBRACE,
        $LBRACKET,
        $RBRACKET,
        $LPAREN,
        $RPAREN,
        $COMMA,
        $COLON,
        $SEMICOLON,
        isWhitespace;

enum CssTokenType {
  EOF,
  String,
  Comment,
  Identifier,
  Number,
  IdentifierOrNumber,
  AtKeyword,
  Character,
  Whitespace,
  Invalid
}
enum CssLexerMode {
  ALL,
  ALL_TRACK_WS,
  SELECTOR,
  PSEUDO_SELECTOR,
  ATTRIBUTE_SELECTOR,
  AT_RULE_QUERY,
  MEDIA_QUERY,
  BLOCK,
  KEYFRAME_BLOCK,
  STYLE_BLOCK,
  STYLE_VALUE,
  STYLE_VALUE_FUNCTION,
  STYLE_CALC_FUNCTION
}

class LexedCssResult {
  CssScannerError error;
  CssToken token;
  LexedCssResult(this.error, this.token) {}
}

String generateErrorMessage(String input, String message, String errorValue,
    num index, num row, num column) {
  return '''${ message} at column ${ row}:${ column} in expression [''' +
      findProblemCode(input, errorValue, index, column) +
      "]";
}

String findProblemCode(String input, String errorValue, num index, num column) {
  var endOfProblemLine = index;
  var current = charCode(input, index);
  while (current > 0 && !isNewline(current)) {
    current = charCode(input, ++endOfProblemLine);
  }
  var choppedString = input.substring(0, endOfProblemLine);
  var pointerPadding = "";
  for (var i = 0; i < column; i++) {
    pointerPadding += " ";
  }
  var pointerString = "";
  for (var i = 0; i < errorValue.length; i++) {
    pointerString += "^";
  }
  return choppedString + "\n" + pointerPadding + pointerString + "\n";
}

class CssToken {
  num index;
  num column;
  num line;
  CssTokenType type;
  String strValue;
  num numValue;
  CssToken(this.index, this.column, this.line, this.type, this.strValue) {
    this.numValue = charCode(strValue, 0);
  }
}

class CssLexer {
  CssScanner scan(String text, [bool trackComments = false]) {
    return new CssScanner(text, trackComments);
  }
}

class CssScannerError extends BaseException {
  CssToken token;
  String rawMessage;
  String message;
  CssScannerError(this.token, message) : super("Css Parse Error: " + message) {
    /* super call moved to initializer */;
    this.rawMessage = message;
  }
  String toString() {
    return this.message;
  }
}

_trackWhitespace(CssLexerMode mode) {
  switch (mode) {
    case CssLexerMode.SELECTOR:
    case CssLexerMode.ALL_TRACK_WS:
    case CssLexerMode.STYLE_VALUE:
      return true;
    default:
      return false;
  }
}

class CssScanner {
  String input;
  bool _trackComments;
  num peek;
  num peekPeek;
  num length = 0;
  num index = -1;
  num column = -1;
  num line = 0;
  /** @internal */
  CssLexerMode _currentMode = CssLexerMode.BLOCK;
  /** @internal */
  CssScannerError _currentError = null;
  CssScanner(this.input, [this._trackComments = false]) {
    this.length = this.input.length;
    this.peekPeek = this.peekAt(0);
    this.advance();
  }
  CssLexerMode getMode() {
    return this._currentMode;
  }

  setMode(CssLexerMode mode) {
    if (this._currentMode != mode) {
      if (_trackWhitespace(this._currentMode)) {
        this.consumeWhitespace();
      }
      this._currentMode = mode;
    }
  }

  void advance() {
    if (isNewline(this.peek)) {
      this.column = 0;
      this.line++;
    } else {
      this.column++;
    }
    this.index++;
    this.peek = this.peekPeek;
    this.peekPeek = this.peekAt(this.index + 1);
  }

  num peekAt(num index) {
    return index >= this.length
        ? $EOF
        : StringWrapper.charCodeAt(this.input, index);
  }

  void consumeEmptyStatements() {
    this.consumeWhitespace();
    while (this.peek == $SEMICOLON) {
      this.advance();
      this.consumeWhitespace();
    }
  }

  void consumeWhitespace() {
    while (isWhitespace(this.peek) || isNewline(this.peek)) {
      this.advance();
      if (!this._trackComments && isCommentStart(this.peek, this.peekPeek)) {
        this.advance();
        this.advance();
        while (!isCommentEnd(this.peek, this.peekPeek)) {
          if (this.peek == $EOF) {
            this.error("Unterminated comment");
          }
          this.advance();
        }
        this.advance();
        this.advance();
      }
    }
  }

  LexedCssResult consume(CssTokenType type, [String value = null]) {
    var mode = this._currentMode;
    this.setMode(CssLexerMode.ALL);
    var previousIndex = this.index;
    var previousLine = this.line;
    var previousColumn = this.column;
    var output = this.scan();
    // just incase the inner scan method returned an error
    if (isPresent(output.error)) {
      this.setMode(mode);
      return output;
    }
    var next = output.token;
    if (!isPresent(next)) {
      next = new CssToken(0, 0, 0, CssTokenType.EOF, "end of file");
    }
    var isMatchingType;
    if (type == CssTokenType.IdentifierOrNumber) {
      // TODO (matsko): implement array traversal for lookup here
      isMatchingType = next.type == CssTokenType.Number ||
          next.type == CssTokenType.Identifier;
    } else {
      isMatchingType = next.type == type;
    }
    // before throwing the error we need to bring back the former

    // mode so that the parser can recover...
    this.setMode(mode);
    var error = null;
    if (!isMatchingType || (isPresent(value) && value != next.strValue)) {
      var errorMessage = resolveEnumToken(CssTokenType, next.type) +
          " does not match expected " +
          resolveEnumToken(CssTokenType, type) +
          " value";
      if (isPresent(value)) {
        errorMessage +=
            " (\"" + next.strValue + "\" should match \"" + value + "\")";
      }
      error = new CssScannerError(
          next,
          generateErrorMessage(this.input, errorMessage, next.strValue,
              previousIndex, previousLine, previousColumn));
    }
    return new LexedCssResult(error, next);
  }

  LexedCssResult scan() {
    var trackWS = _trackWhitespace(this._currentMode);
    if (this.index == 0 && !trackWS) {
      this.consumeWhitespace();
    }
    var token = this._scan();
    if (token == null) return null;
    var error = this._currentError;
    this._currentError = null;
    if (!trackWS) {
      this.consumeWhitespace();
    }
    return new LexedCssResult(error, token);
  }

  /** @internal */
  CssToken _scan() {
    var peek = this.peek;
    var peekPeek = this.peekPeek;
    if (peek == $EOF) return null;
    if (isCommentStart(peek, peekPeek)) {
      // even if comments are not tracked we still lex the

      // comment so we can move the pointer forward
      var commentToken = this.scanComment();
      if (this._trackComments) {
        return commentToken;
      }
    }
    if (_trackWhitespace(this._currentMode) &&
        (isWhitespace(peek) || isNewline(peek))) {
      return this.scanWhitespace();
    }
    peek = this.peek;
    peekPeek = this.peekPeek;
    if (peek == $EOF) return null;
    if (isStringStart(peek, peekPeek)) {
      return this.scanString();
    }
    // something like url(cool)
    if (this._currentMode == CssLexerMode.STYLE_VALUE_FUNCTION) {
      return this.scanCssValueFunction();
    }
    var isModifier = peek == $PLUS || peek == $MINUS;
    var digitA = isModifier ? false : isDigit(peek);
    var digitB = isDigit(peekPeek);
    if (digitA ||
        (isModifier && (peekPeek == $PERIOD || digitB)) ||
        (peek == $PERIOD && digitB)) {
      return this.scanNumber();
    }
    if (peek == $AT) {
      return this.scanAtExpression();
    }
    if (isIdentifierStart(peek, peekPeek)) {
      return this.scanIdentifier();
    }
    if (isValidCssCharacter(peek, this._currentMode)) {
      return this.scanCharacter();
    }
    return this.error(
        '''Unexpected character [${ StringWrapper . fromCharCode ( peek )}]''');
  }

  CssToken scanComment() {
    if (this.assertCondition(isCommentStart(this.peek, this.peekPeek),
        "Expected comment start value")) {
      return null;
    }
    var start = this.index;
    var startingColumn = this.column;
    var startingLine = this.line;
    this.advance();
    this.advance();
    while (!isCommentEnd(this.peek, this.peekPeek)) {
      if (this.peek == $EOF) {
        this.error("Unterminated comment");
      }
      this.advance();
    }
    this.advance();
    this.advance();
    var str = this.input.substring(start, this.index);
    return new CssToken(
        start, startingColumn, startingLine, CssTokenType.Comment, str);
  }

  CssToken scanWhitespace() {
    var start = this.index;
    var startingColumn = this.column;
    var startingLine = this.line;
    while (isWhitespace(this.peek) && this.peek != $EOF) {
      this.advance();
    }
    var str = this.input.substring(start, this.index);
    return new CssToken(
        start, startingColumn, startingLine, CssTokenType.Whitespace, str);
  }

  CssToken scanString() {
    if (this.assertCondition(isStringStart(this.peek, this.peekPeek),
        "Unexpected non-string starting value")) {
      return null;
    }
    var target = this.peek;
    var start = this.index;
    var startingColumn = this.column;
    var startingLine = this.line;
    var previous = target;
    this.advance();
    while (!isCharMatch(target, previous, this.peek)) {
      if (this.peek == $EOF || isNewline(this.peek)) {
        this.error("Unterminated quote");
      }
      previous = this.peek;
      this.advance();
    }
    if (this.assertCondition(this.peek == target, "Unterminated quote")) {
      return null;
    }
    this.advance();
    var str = this.input.substring(start, this.index);
    return new CssToken(
        start, startingColumn, startingLine, CssTokenType.String, str);
  }

  CssToken scanNumber() {
    var start = this.index;
    var startingColumn = this.column;
    if (this.peek == $PLUS || this.peek == $MINUS) {
      this.advance();
    }
    var periodUsed = false;
    while (isDigit(this.peek) || this.peek == $PERIOD) {
      if (this.peek == $PERIOD) {
        if (periodUsed) {
          this.error("Unexpected use of a second period value");
        }
        periodUsed = true;
      }
      this.advance();
    }
    var strValue = this.input.substring(start, this.index);
    return new CssToken(
        start, startingColumn, this.line, CssTokenType.Number, strValue);
  }

  CssToken scanIdentifier() {
    if (this.assertCondition(isIdentifierStart(this.peek, this.peekPeek),
        "Expected identifier starting value")) {
      return null;
    }
    var start = this.index;
    var startingColumn = this.column;
    while (isIdentifierPart(this.peek)) {
      this.advance();
    }
    var strValue = this.input.substring(start, this.index);
    return new CssToken(
        start, startingColumn, this.line, CssTokenType.Identifier, strValue);
  }

  CssToken scanCssValueFunction() {
    var start = this.index;
    var startingColumn = this.column;
    while (this.peek != $EOF && this.peek != $RPAREN) {
      this.advance();
    }
    var strValue = this.input.substring(start, this.index);
    return new CssToken(
        start, startingColumn, this.line, CssTokenType.Identifier, strValue);
  }

  CssToken scanCharacter() {
    var start = this.index;
    var startingColumn = this.column;
    if (this.assertCondition(isValidCssCharacter(this.peek, this._currentMode),
        charStr(this.peek) + " is not a valid CSS character")) {
      return null;
    }
    var c = this.input.substring(start, start + 1);
    this.advance();
    return new CssToken(
        start, startingColumn, this.line, CssTokenType.Character, c);
  }

  CssToken scanAtExpression() {
    if (this.assertCondition(this.peek == $AT, "Expected @ value")) {
      return null;
    }
    var start = this.index;
    var startingColumn = this.column;
    this.advance();
    if (isIdentifierStart(this.peek, this.peekPeek)) {
      var ident = this.scanIdentifier();
      var strValue = "@" + ident.strValue;
      return new CssToken(
          start, startingColumn, this.line, CssTokenType.AtKeyword, strValue);
    } else {
      return this.scanCharacter();
    }
  }

  bool assertCondition(bool status, String errorMessage) {
    if (!status) {
      this.error(errorMessage);
      return true;
    }
    return false;
  }

  CssToken error(String message,
      [String errorTokenValue = null, bool doNotAdvance = false]) {
    num index = this.index;
    num column = this.column;
    num line = this.line;
    errorTokenValue = isPresent(errorTokenValue)
        ? errorTokenValue
        : StringWrapper.fromCharCode(this.peek);
    var invalidToken = new CssToken(
        index, column, line, CssTokenType.Invalid, errorTokenValue);
    var errorMessage = generateErrorMessage(
        this.input, message, errorTokenValue, index, line, column);
    if (!doNotAdvance) {
      this.advance();
    }
    this._currentError = new CssScannerError(invalidToken, errorMessage);
    return invalidToken;
  }
}

bool isAtKeyword(CssToken current, CssToken next) {
  return current.numValue == $AT && next.type == CssTokenType.Identifier;
}

bool isCharMatch(num target, num previous, num code) {
  return code == target && previous != $BACKSLASH;
}

bool isDigit(num code) {
  return $0 <= code && code <= $9;
}

bool isCommentStart(num code, num next) {
  return code == $SLASH && next == $STAR;
}

bool isCommentEnd(num code, num next) {
  return code == $STAR && next == $SLASH;
}

bool isStringStart(num code, num next) {
  var target = code;
  if (target == $BACKSLASH) {
    target = next;
  }
  return target == $DQ || target == $SQ;
}

bool isIdentifierStart(num code, num next) {
  var target = code;
  if (target == $MINUS) {
    target = next;
  }
  return ($a <= target && target <= $z) ||
      ($A <= target && target <= $Z) ||
      target == $BACKSLASH ||
      target == $MINUS ||
      target == $_;
}

bool isIdentifierPart(num target) {
  return ($a <= target && target <= $z) ||
      ($A <= target && target <= $Z) ||
      target == $BACKSLASH ||
      target == $MINUS ||
      target == $_ ||
      isDigit(target);
}

bool isValidPseudoSelectorCharacter(num code) {
  switch (code) {
    case $LPAREN:
    case $RPAREN:
      return true;
    default:
      return false;
  }
}

bool isValidKeyframeBlockCharacter(num code) {
  return code == $PERCENT;
}

bool isValidAttributeSelectorCharacter(num code) {
  // value^*|$~=something
  switch (code) {
    case $$:
    case $PIPE:
    case $CARET:
    case $TILDA:
    case $STAR:
    case $EQ:
      return true;
    default:
      return false;
  }
}

bool isValidSelectorCharacter(num code) {
  // selector [ key   = value ]

  // IDENT    C IDENT C IDENT C

  // #id, .class, *+~>

  // tag:PSEUDO
  switch (code) {
    case $HASH:
    case $PERIOD:
    case $TILDA:
    case $STAR:
    case $PLUS:
    case $GT:
    case $COLON:
    case $PIPE:
    case $COMMA:
      return true;
    default:
      return false;
  }
}

bool isValidStyleBlockCharacter(num code) {
  // key:value;

  // key:calc(something ... )
  switch (code) {
    case $HASH:
    case $SEMICOLON:
    case $COLON:
    case $PERCENT:
    case $SLASH:
    case $BACKSLASH:
    case $BANG:
    case $PERIOD:
    case $LPAREN:
    case $RPAREN:
      return true;
    default:
      return false;
  }
}

bool isValidMediaQueryRuleCharacter(num code) {
  // (min-width: 7.5em) and (orientation: landscape)
  switch (code) {
    case $LPAREN:
    case $RPAREN:
    case $COLON:
    case $PERCENT:
    case $PERIOD:
      return true;
    default:
      return false;
  }
}

bool isValidAtRuleCharacter(num code) {
  // @document url(http://www.w3.org/page?something=on#hash),
  switch (code) {
    case $LPAREN:
    case $RPAREN:
    case $COLON:
    case $PERCENT:
    case $PERIOD:
    case $SLASH:
    case $BACKSLASH:
    case $HASH:
    case $EQ:
    case $QUESTION:
    case $AMPERSAND:
    case $STAR:
    case $COMMA:
    case $MINUS:
    case $PLUS:
      return true;
    default:
      return false;
  }
}

bool isValidStyleFunctionCharacter(num code) {
  switch (code) {
    case $PERIOD:
    case $MINUS:
    case $PLUS:
    case $STAR:
    case $SLASH:
    case $LPAREN:
    case $RPAREN:
    case $COMMA:
      return true;
    default:
      return false;
  }
}

bool isValidBlockCharacter(num code) {
  // @something { }

  // IDENT
  return code == $AT;
}

bool isValidCssCharacter(num code, CssLexerMode mode) {
  switch (mode) {
    case CssLexerMode.ALL:
    case CssLexerMode.ALL_TRACK_WS:
      return true;
    case CssLexerMode.SELECTOR:
      return isValidSelectorCharacter(code);
    case CssLexerMode.PSEUDO_SELECTOR:
      return isValidPseudoSelectorCharacter(code);
    case CssLexerMode.ATTRIBUTE_SELECTOR:
      return isValidAttributeSelectorCharacter(code);
    case CssLexerMode.MEDIA_QUERY:
      return isValidMediaQueryRuleCharacter(code);
    case CssLexerMode.AT_RULE_QUERY:
      return isValidAtRuleCharacter(code);
    case CssLexerMode.KEYFRAME_BLOCK:
      return isValidKeyframeBlockCharacter(code);
    case CssLexerMode.STYLE_BLOCK:
    case CssLexerMode.STYLE_VALUE:
      return isValidStyleBlockCharacter(code);
    case CssLexerMode.STYLE_CALC_FUNCTION:
      return isValidStyleFunctionCharacter(code);
    case CssLexerMode.BLOCK:
      return isValidBlockCharacter(code);
    default:
      return false;
  }
}

num charCode(input, index) {
  return index >= input.length ? $EOF : StringWrapper.charCodeAt(input, index);
}

String charStr(num code) {
  return StringWrapper.fromCharCode(code);
}

bool isNewline(code) {
  switch (code) {
    case $FF:
    case $CR:
    case $LF:
    case $VTAB:
      return true;
    default:
      return false;
  }
}
