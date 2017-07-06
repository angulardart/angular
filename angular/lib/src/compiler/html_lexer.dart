import 'package:source_span/source_span.dart';

import 'html_tags.dart'
    show getHtmlTagDefinition, HtmlTagContentType, NAMED_ENTITIES;
import 'parse_util.dart' show ParseError;

enum HtmlTokenType {
  TAG_OPEN_START,
  TAG_OPEN_END,
  TAG_OPEN_END_VOID,
  TAG_CLOSE,
  TEXT,
  ESCAPABLE_RAW_TEXT,
  RAW_TEXT,
  COMMENT_START,
  COMMENT_END,
  CDATA_START,
  CDATA_END,
  ATTR_NAME,
  ATTR_VALUE,
  DOC_TYPE,
  EXPANSION_FORM_START,
  EXPANSION_CASE_VALUE,
  EXPANSION_CASE_EXP_START,
  EXPANSION_CASE_EXP_END,
  EXPANSION_FORM_END,
  EOF
}

class HtmlToken {
  final HtmlTokenType type;
  final List<String> parts;
  SourceSpan sourceSpan;
  HtmlToken(this.type, this.parts, this.sourceSpan);
}

class HtmlTokenError extends ParseError {
  final HtmlTokenType tokenType;
  HtmlTokenError(String errorMsg, this.tokenType, SourceSpan span)
      : super(span, errorMsg);
}

class HtmlTokenizeResult {
  final List<HtmlToken> tokens;
  final List<HtmlTokenError> errors;
  HtmlTokenizeResult(this.tokens, this.errors);
}

HtmlTokenizeResult tokenizeHtml(String sourceContent, String sourceUrl,
    [bool tokenizeExpansionForms = false]) {
  return new _HtmlTokenizer(
          new SourceFile.fromString(sourceContent, url: sourceUrl),
          tokenizeExpansionForms)
      .tokenize();
}

const $EOF = 0;
const $TAB = 9;
const $LF = 10;
const $FF = 12;
const $CR = 13;
const $SPACE = 32;
const $BANG = 33;
const $DQ = 34;
const $HASH = 35;
const $$ = 36;
const $AMPERSAND = 38;
const $SQ = 39;
const $MINUS = 45;
const $SLASH = 47;
const $0 = 48;
const $SEMICOLON = 59;
const $9 = 57;
const $COLON = 58;
const $LT = 60;
const $EQ = 61;
const $GT = 62;
const $QUESTION = 63;
const $LBRACKET = 91;
const $RBRACKET = 93;
const $LBRACE = 123;
const $RBRACE = 125;
const $COMMA = 44;
const $A = 65;
const $F = 70;
const $X = 88;
const $Z = 90;
const $a = 97;
const $f = 102;
const $z = 122;
const $x = 120;
const $NBSP = 160;
var CR_OR_CRLF_REGEXP = new RegExp(r'\r\n?');
String unexpectedCharacterErrorMsg(num charCode) {
  var char =
      identical(charCode, $EOF) ? "EOF" : new String.fromCharCode(charCode);
  return '''Unexpected character "$char"''';
}

String unknownEntityErrorMsg(String entitySrc) {
  return '''Unknown entity "$entitySrc" - use the "&#<decimal>;" or  "&#x<hex>;" syntax''';
}

class ControlFlowError extends Error {
  final HtmlTokenError error;
  ControlFlowError(this.error);
}

// See http://www.w3.org/TR/html51/syntax.html#writing
class _HtmlTokenizer {
  final SourceFile file;
  bool tokenizeExpansionForms;
  String input;
  num length;
  // Note: this is always lowercase!
  num peek = -1;
  num nextPeek = -1;
  num index = -1;
  num line = 0;
  num column = -1;
  SourceLocation currentTokenStart;
  HtmlTokenType currentTokenType;
  var expansionCaseStack = [];
  List<HtmlToken> tokens = [];
  List<HtmlTokenError> errors = [];
  _HtmlTokenizer(this.file, this.tokenizeExpansionForms) {
    this.input = file.getText(0);
    this.length = file.length;
    this._advance();
  }
  String _processCarriageReturns(String content) {
    // http://www.w3.org/TR/html5/syntax.html#preprocessing-the-input-stream
    // In order to keep the original position in the source, we can not
    // pre-process it.
    // Instead CRs are processed right before instantiating the tokens.
    return content.replaceAll(CR_OR_CRLF_REGEXP, "\n");
  }

  HtmlTokenizeResult tokenize() {
    while (!identical(this.peek, $EOF)) {
      var start = this._getLocation();
      try {
        if (this._attemptCharCode($LT)) {
          if (this._attemptCharCode($BANG)) {
            if (this._attemptCharCode($LBRACKET)) {
              this._consumeCdata(start);
            } else if (this._attemptCharCode($MINUS)) {
              this._consumeComment(start);
            } else {
              this._consumeDocType(start);
            }
          } else if (this._attemptCharCode($SLASH)) {
            this._consumeTagClose(start);
          } else {
            this._consumeTagOpen(start);
          }
        } else if (isSpecialFormStart(this.peek, this.nextPeek) &&
            this.tokenizeExpansionForms) {
          this._consumeExpansionFormStart();
        } else if (identical(this.peek, $EQ) && this.tokenizeExpansionForms) {
          this._consumeExpansionCaseStart();
        } else if (identical(this.peek, $RBRACE) &&
            this.isInExpansionCase() &&
            this.tokenizeExpansionForms) {
          this._consumeExpansionCaseEnd();
        } else if (identical(this.peek, $RBRACE) &&
            this.isInExpansionForm() &&
            this.tokenizeExpansionForms) {
          this._consumeExpansionFormEnd();
        } else {
          this._consumeText();
        }
      } catch (e) {
        if (e is ControlFlowError) {
          this.errors.add(e.error);
        } else {
          rethrow;
        }
      }
    }
    this._beginToken(HtmlTokenType.EOF);
    this._endToken([]);
    return new HtmlTokenizeResult(
        mergeTextTokens(this.tokens, file), this.errors);
  }

  SourceLocation _getLocation() {
    return file.location(index);
  }

  SourceSpan _getSpan([SourceLocation start, SourceLocation end]) {
    start ??= _getLocation();
    end ??= _getLocation();
    return new SourceSpan(
      start,
      end,
      file.getText(start.offset, end.offset),
    );
  }

  void _beginToken(HtmlTokenType type, [SourceLocation start]) {
    start ??= this._getLocation();
    this.currentTokenStart = start;
    this.currentTokenType = type;
  }

  HtmlToken _endToken(List<String> parts, [SourceLocation end]) {
    end ??= this._getLocation();
    var token = new HtmlToken(
        this.currentTokenType,
        parts,
        new SourceSpan(this.currentTokenStart, end,
            file.getText(currentTokenStart.offset, end.offset)));
    this.tokens.add(token);
    this.currentTokenStart = null;
    this.currentTokenType = null;
    return token;
  }

  ControlFlowError _createError(String msg, SourceSpan span) {
    var error = new HtmlTokenError(msg, this.currentTokenType, span);
    this.currentTokenStart = null;
    this.currentTokenType = null;
    return new ControlFlowError(error);
  }

  void _advance() {
    if (this.index >= this.length) {
      throw this
          ._createError(unexpectedCharacterErrorMsg($EOF), this._getSpan());
    }
    if (identical(this.peek, $LF)) {
      this.line++;
      this.column = 0;
    } else if (!identical(this.peek, $LF) && !identical(this.peek, $CR)) {
      this.column++;
    }
    this.index++;
    this.peek =
        this.index >= this.length ? $EOF : this.input.codeUnitAt(this.index);
    this.nextPeek = this.index + 1 >= this.length
        ? $EOF
        : this.input.codeUnitAt(this.index + 1);
  }

  bool _attemptCharCode(num charCode) {
    if (identical(this.peek, charCode)) {
      this._advance();
      return true;
    }
    return false;
  }

  bool _attemptCharCodeCaseInsensitive(num charCode) {
    if (compareCharCodeCaseInsensitive(this.peek, charCode)) {
      this._advance();
      return true;
    }
    return false;
  }

  void _requireCharCode(num charCode) {
    var location = this._getLocation();
    if (!this._attemptCharCode(charCode)) {
      throw this._createError(unexpectedCharacterErrorMsg(this.peek),
          this._getSpan(location, location));
    }
  }

  bool _attemptStr(String chars) {
    for (var i = 0; i < chars.length; i++) {
      if (!this._attemptCharCode(chars.codeUnitAt(i))) {
        return false;
      }
    }
    return true;
  }

  bool _attemptStrCaseInsensitive(String chars) {
    for (var i = 0; i < chars.length; i++) {
      if (!this._attemptCharCodeCaseInsensitive(chars.codeUnitAt(i))) {
        return false;
      }
    }
    return true;
  }

  void _requireStr(String chars) {
    var location = this._getLocation();
    if (!this._attemptStr(chars)) {
      throw this._createError(
          unexpectedCharacterErrorMsg(this.peek), this._getSpan(location));
    }
  }

  void _attemptCharCodeUntilFn(Function predicate) {
    while (!predicate(this.peek)) {
      this._advance();
    }
  }

  void _requireCharCodeUntilFn(Function predicate, num len) {
    var start = this._getLocation();
    this._attemptCharCodeUntilFn(predicate);
    if (this.index - start.offset < len) {
      throw this._createError(
          unexpectedCharacterErrorMsg(this.peek), this._getSpan(start, start));
    }
  }

  void _attemptUntilChar(num char) {
    while (!identical(this.peek, char)) {
      this._advance();
    }
  }

  String _readChar(bool decodeEntities) {
    if (decodeEntities && identical(this.peek, $AMPERSAND)) {
      return this._decodeEntity();
    } else {
      var index = this.index;
      this._advance();
      return this.input[index];
    }
  }

  String _decodeEntity() {
    var start = this._getLocation();
    this._advance();
    if (this._attemptCharCode($HASH)) {
      var isHex = this._attemptCharCode($x) || this._attemptCharCode($X);
      var numberStart = this._getLocation().offset;
      this._attemptCharCodeUntilFn(isDigitEntityEnd);
      if (this.peek != $SEMICOLON) {
        throw this._createError(
            unexpectedCharacterErrorMsg(this.peek), this._getSpan());
      }
      this._advance();
      var strNum = this.input.substring(numberStart, this.index - 1);
      try {
        var charCode = int.parse(strNum, radix: isHex ? 16 : 10);
        return new String.fromCharCode(charCode);
      } catch (e) {
        var entity = this.input.substring(start.offset + 1, this.index - 1);
        throw this
            ._createError(unknownEntityErrorMsg(entity), this._getSpan(start));
      }
    } else {
      var startPosition = this._savePosition();
      this._attemptCharCodeUntilFn(isNamedEntityEnd);
      if (this.peek != $SEMICOLON) {
        this._restorePosition(startPosition);
        return "&";
      }
      this._advance();
      var name = this.input.substring(start.offset + 1, this.index - 1);
      var char = NAMED_ENTITIES[name];
      if (char == null) {
        throw this
            ._createError(unknownEntityErrorMsg(name), this._getSpan(start));
      }
      return char;
    }
  }

  HtmlToken _consumeRawText(
      bool decodeEntities, num firstCharOfEnd, Function attemptEndRest) {
    var tagCloseStart;
    var textStart = this._getLocation();
    this._beginToken(
        decodeEntities
            ? HtmlTokenType.ESCAPABLE_RAW_TEXT
            : HtmlTokenType.RAW_TEXT,
        textStart);
    var parts = [];
    while (true) {
      tagCloseStart = this._getLocation();
      if (this._attemptCharCode(firstCharOfEnd) && attemptEndRest()) {
        break;
      }
      if (this.index > tagCloseStart.offset) {
        parts.add(this.input.substring(tagCloseStart.offset, this.index));
      }
      while (!identical(this.peek, firstCharOfEnd)) {
        parts.add(this._readChar(decodeEntities));
      }
    }
    return this._endToken(
        [this._processCarriageReturns(parts.join(""))], tagCloseStart);
  }

  void _consumeComment(SourceLocation start) {
    this._beginToken(HtmlTokenType.COMMENT_START, start);
    this._requireCharCode($MINUS);
    this._endToken([]);
    var textToken =
        this._consumeRawText(false, $MINUS, () => this._attemptStr("->"));
    this._beginToken(HtmlTokenType.COMMENT_END, textToken.sourceSpan.end);
    this._endToken([]);
  }

  void _consumeCdata(SourceLocation start) {
    this._beginToken(HtmlTokenType.CDATA_START, start);
    this._requireStr("CDATA[");
    this._endToken([]);
    var textToken =
        this._consumeRawText(false, $RBRACKET, () => this._attemptStr("]>"));
    this._beginToken(HtmlTokenType.CDATA_END, textToken.sourceSpan.end);
    this._endToken([]);
  }

  void _consumeDocType(SourceLocation start) {
    this._beginToken(HtmlTokenType.DOC_TYPE, start);
    this._attemptUntilChar($GT);
    this._advance();
    this._endToken([this.input.substring(start.offset + 2, this.index - 1)]);
  }

  List<String> _consumePrefixAndName() {
    var nameOrPrefixStart = this.index;
    String prefix;
    while (!identical(this.peek, $COLON) && !isPrefixEnd(this.peek)) {
      this._advance();
    }
    var nameStart;
    if (identical(this.peek, $COLON)) {
      this._advance();
      prefix = this.input.substring(nameOrPrefixStart, this.index - 1);
      nameStart = this.index;
    } else {
      nameStart = nameOrPrefixStart;
    }
    this._requireCharCodeUntilFn(
        isNameEnd, identical(this.index, nameStart) ? 1 : 0);
    var name = this.input.substring(nameStart, this.index);
    return [prefix, name];
  }

  void _consumeTagOpen(SourceLocation start) {
    var savedPos = this._savePosition();
    var lowercaseTagName;
    try {
      if (!isAsciiLetter(this.peek)) {
        throw this._createError(
            unexpectedCharacterErrorMsg(this.peek), this._getSpan());
      }
      var nameStart = this.index;
      this._consumeTagOpenStart(start);
      lowercaseTagName =
          this.input.substring(nameStart, this.index).toLowerCase();
      this._attemptCharCodeUntilFn(isNotWhitespace);
      while (!identical(this.peek, $SLASH) && !identical(this.peek, $GT)) {
        this._consumeAttributeName();
        this._attemptCharCodeUntilFn(isNotWhitespace);
        if (this._attemptCharCode($EQ)) {
          this._attemptCharCodeUntilFn(isNotWhitespace);
          this._consumeAttributeValue();
        }
        this._attemptCharCodeUntilFn(isNotWhitespace);
      }
      this._consumeTagOpenEnd();
    } catch (e) {
      if (e is ControlFlowError) {
        // When the start tag is invalid, assume we want a "<"
        this._restorePosition(savedPos);
        // Back to back text tokens are merged at the end
        this._beginToken(HtmlTokenType.TEXT, start);
        this._endToken(["<"]);
        return;
      }
      rethrow;
    }
    var contentTokenType = getHtmlTagDefinition(lowercaseTagName).contentType;
    if (identical(contentTokenType, HtmlTagContentType.RAW_TEXT)) {
      this._consumeRawTextWithTagClose(lowercaseTagName, false);
    } else if (identical(
        contentTokenType, HtmlTagContentType.ESCAPABLE_RAW_TEXT)) {
      this._consumeRawTextWithTagClose(lowercaseTagName, true);
    }
  }

  void _consumeRawTextWithTagClose(
      String lowercaseTagName, bool decodeEntities) {
    var textToken = this._consumeRawText(decodeEntities, $LT, () {
      if (!this._attemptCharCode($SLASH)) return false;
      this._attemptCharCodeUntilFn(isNotWhitespace);
      if (!this._attemptStrCaseInsensitive(lowercaseTagName)) return false;
      this._attemptCharCodeUntilFn(isNotWhitespace);
      if (!this._attemptCharCode($GT)) return false;
      return true;
    });
    this._beginToken(HtmlTokenType.TAG_CLOSE, textToken.sourceSpan.end);
    this._endToken([null, lowercaseTagName]);
  }

  void _consumeTagOpenStart(SourceLocation start) {
    this._beginToken(HtmlTokenType.TAG_OPEN_START, start);
    var parts = this._consumePrefixAndName();
    this._endToken(parts);
  }

  void _consumeAttributeName() {
    this._beginToken(HtmlTokenType.ATTR_NAME);
    var prefixAndName = this._consumePrefixAndName();
    this._endToken(prefixAndName);
  }

  void _consumeAttributeValue() {
    this._beginToken(HtmlTokenType.ATTR_VALUE);
    var value;
    if (identical(this.peek, $SQ) || identical(this.peek, $DQ)) {
      var quoteChar = this.peek;
      this._advance();
      var parts = [];
      while (!identical(this.peek, quoteChar)) {
        parts.add(this._readChar(true));
      }
      value = parts.join("");
      this._advance();
    } else {
      var valueStart = this.index;
      this._requireCharCodeUntilFn(isNameEnd, 1);
      value = this.input.substring(valueStart, this.index);
    }
    this._endToken([this._processCarriageReturns(value)]);
  }

  void _consumeTagOpenEnd() {
    var tokenType = this._attemptCharCode($SLASH)
        ? HtmlTokenType.TAG_OPEN_END_VOID
        : HtmlTokenType.TAG_OPEN_END;
    this._beginToken(tokenType);
    this._requireCharCode($GT);
    this._endToken([]);
  }

  void _consumeTagClose(SourceLocation start) {
    this._beginToken(HtmlTokenType.TAG_CLOSE, start);
    this._attemptCharCodeUntilFn(isNotWhitespace);
    List<String> prefixAndName;
    prefixAndName = this._consumePrefixAndName();
    this._attemptCharCodeUntilFn(isNotWhitespace);
    this._requireCharCode($GT);
    this._endToken(prefixAndName);
  }

  void _consumeExpansionFormStart() {
    this._beginToken(HtmlTokenType.EXPANSION_FORM_START, this._getLocation());
    this._requireCharCode($LBRACE);
    this._endToken([]);
    this._beginToken(HtmlTokenType.RAW_TEXT, this._getLocation());
    var condition = this._readUntil($COMMA);
    this._endToken([condition], this._getLocation());
    this._requireCharCode($COMMA);
    this._attemptCharCodeUntilFn(isNotWhitespace);
    this._beginToken(HtmlTokenType.RAW_TEXT, this._getLocation());
    var type = this._readUntil($COMMA);
    this._endToken([type], this._getLocation());
    this._requireCharCode($COMMA);
    this._attemptCharCodeUntilFn(isNotWhitespace);
    this.expansionCaseStack.add(HtmlTokenType.EXPANSION_FORM_START);
  }

  void _consumeExpansionCaseStart() {
    this._requireCharCode($EQ);
    this._beginToken(HtmlTokenType.EXPANSION_CASE_VALUE, this._getLocation());
    var value = this._readUntil($LBRACE).trim();
    this._endToken([value], this._getLocation());
    this._attemptCharCodeUntilFn(isNotWhitespace);
    this._beginToken(
        HtmlTokenType.EXPANSION_CASE_EXP_START, this._getLocation());
    this._requireCharCode($LBRACE);
    this._endToken([], this._getLocation());
    this._attemptCharCodeUntilFn(isNotWhitespace);
    this.expansionCaseStack.add(HtmlTokenType.EXPANSION_CASE_EXP_START);
  }

  void _consumeExpansionCaseEnd() {
    this._beginToken(HtmlTokenType.EXPANSION_CASE_EXP_END, this._getLocation());
    this._requireCharCode($RBRACE);
    this._endToken([], this._getLocation());
    this._attemptCharCodeUntilFn(isNotWhitespace);
    this.expansionCaseStack.removeLast();
  }

  void _consumeExpansionFormEnd() {
    this._beginToken(HtmlTokenType.EXPANSION_FORM_END, this._getLocation());
    this._requireCharCode($RBRACE);
    this._endToken([]);
    this.expansionCaseStack.removeLast();
  }

  void _consumeText() {
    var start = this._getLocation();
    this._beginToken(HtmlTokenType.TEXT, start);
    var parts = [];
    var interpolation = false;
    if (identical(this.peek, $LBRACE) && identical(this.nextPeek, $LBRACE)) {
      parts.add(this._readChar(true));
      parts.add(this._readChar(true));
      interpolation = true;
    } else {
      parts.add(this._readChar(true));
    }
    while (!this.isTextEnd(interpolation)) {
      if (identical(this.peek, $LBRACE) && identical(this.nextPeek, $LBRACE)) {
        parts.add(this._readChar(true));
        parts.add(this._readChar(true));
        interpolation = true;
      } else if (identical(this.peek, $RBRACE) &&
          identical(this.nextPeek, $RBRACE) &&
          interpolation) {
        parts.add(this._readChar(true));
        parts.add(this._readChar(true));
        interpolation = false;
      } else {
        parts.add(this._readChar(true));
      }
    }
    this._endToken([this._processCarriageReturns(parts.join(""))]);
  }

  bool isTextEnd(bool interpolation) {
    if (identical(this.peek, $LT) || identical(this.peek, $EOF)) return true;
    if (this.tokenizeExpansionForms) {
      if (isSpecialFormStart(this.peek, this.nextPeek)) return true;
      if (identical(this.peek, $RBRACE) &&
          !interpolation &&
          (this.isInExpansionCase() || this.isInExpansionForm())) return true;
    }
    return false;
  }

  List<num> _savePosition() {
    return [this.peek, this.index, this.column, this.line, this.tokens.length];
  }

  String _readUntil(num char) {
    var start = this.index;
    this._attemptUntilChar(char);
    return this.input.substring(start, this.index);
  }

  void _restorePosition(List<num> position) {
    this.peek = position[0];
    this.index = position[1];
    this.column = position[2];
    this.line = position[3];
    var nbTokens = position[4];
    if (nbTokens < this.tokens.length) {
      // remove any extra tokens
      this.tokens = tokens.sublist(0, nbTokens);
    }
  }

  bool isInExpansionCase() {
    return this.expansionCaseStack.length > 0 &&
        identical(this.expansionCaseStack[this.expansionCaseStack.length - 1],
            HtmlTokenType.EXPANSION_CASE_EXP_START);
  }

  bool isInExpansionForm() {
    return this.expansionCaseStack.length > 0 &&
        identical(this.expansionCaseStack[this.expansionCaseStack.length - 1],
            HtmlTokenType.EXPANSION_FORM_START);
  }
}

bool isNotWhitespace(num code) {
  return !isWhitespace(code) || identical(code, $EOF);
}

bool isWhitespace(num code) {
  return (code >= $TAB && code <= $SPACE) || (identical(code, $NBSP));
}

bool isNameEnd(num code) {
  return isWhitespace(code) ||
      identical(code, $GT) ||
      identical(code, $SLASH) ||
      identical(code, $SQ) ||
      identical(code, $DQ) ||
      identical(code, $EQ);
}

bool isPrefixEnd(num code) {
  return (code < $a || $z < code) &&
      (code < $A || $Z < code) &&
      (code < $0 || code > $9);
}

bool isDigitEntityEnd(num code) {
  return code == $SEMICOLON || code == $EOF || !isAsciiHexDigit(code);
}

bool isNamedEntityEnd(num code) {
  return code == $SEMICOLON || code == $EOF || !isAsciiLetter(code);
}

bool isSpecialFormStart(num peek, num nextPeek) {
  return identical(peek, $LBRACE) && nextPeek != $LBRACE;
}

bool isAsciiLetter(num code) {
  return code >= $a && code <= $z || code >= $A && code <= $Z;
}

bool isAsciiHexDigit(num code) {
  return code >= $a && code <= $f ||
      code >= $A && code <= $F ||
      code >= $0 && code <= $9;
}

bool compareCharCodeCaseInsensitive(num code1, num code2) {
  return toUpperCaseCharCode(code1) == toUpperCaseCharCode(code2);
}

num toUpperCaseCharCode(num code) {
  return code >= $a && code <= $z ? code - $a + $A : code;
}

List<HtmlToken> mergeTextTokens(List<HtmlToken> srcTokens, SourceFile file) {
  var dstTokens = <HtmlToken>[];
  HtmlToken lastDstToken;
  for (var i = 0; i < srcTokens.length; i++) {
    var token = srcTokens[i];
    if (lastDstToken != null &&
        lastDstToken.type == HtmlTokenType.TEXT &&
        token.type == HtmlTokenType.TEXT) {
      lastDstToken.parts[0] += token.parts[0];
      lastDstToken.sourceSpan = new SourceSpan(
        lastDstToken.sourceSpan.start,
        token.sourceSpan.end,
        file.getText(
          lastDstToken.sourceSpan.start.offset,
          token.sourceSpan.end.offset,
        ),
      );
    } else {
      lastDstToken = token;
      dstTokens.add(lastDstToken);
    }
  }
  return dstTokens;
}
