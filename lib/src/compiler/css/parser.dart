import "package:angular2/src/compiler/css/lexer.dart"
    show
        CssLexerMode,
        CssToken,
        CssTokenType,
        CssScanner,
        generateErrorMessage,
        $AT,
        $EOF,
        $RBRACE,
        $LBRACE,
        $LBRACKET,
        $RBRACKET,
        $LPAREN,
        $RPAREN,
        $COMMA,
        $COLON,
        $SEMICOLON,
        isNewline;
import "package:angular2/src/compiler/parse_util.dart"
    show ParseSourceSpan, ParseSourceFile, ParseLocation, ParseError;
import "package:angular2/src/facade/lang.dart"
    show bitWiseOr, bitWiseAnd, isPresent;

export "package:angular2/src/compiler/css/lexer.dart" show CssToken;

enum BlockType {
  Import,
  Charset,
  Namespace,
  Supports,
  Keyframes,
  MediaQuery,
  Selector,
  FontFace,
  Page,
  Document,
  Viewport,
  Unsupported
}
const EOF_DELIM = 1;
const RBRACE_DELIM = 2;
const LBRACE_DELIM = 4;
const COMMA_DELIM = 8;
const COLON_DELIM = 16;
const SEMICOLON_DELIM = 32;
const NEWLINE_DELIM = 64;
const RPAREN_DELIM = 128;
CssToken mergeTokens(List<CssToken> tokens, [String separator = ""]) {
  var mainToken = tokens[0];
  var str = mainToken.strValue;
  for (var i = 1; i < tokens.length; i++) {
    str += separator + tokens[i].strValue;
  }
  return new CssToken(
      mainToken.index, mainToken.column, mainToken.line, mainToken.type, str);
}

num getDelimFromToken(CssToken token) {
  return getDelimFromCharacter(token.numValue);
}

num getDelimFromCharacter(num code) {
  switch (code) {
    case $EOF:
      return EOF_DELIM;
    case $COMMA:
      return COMMA_DELIM;
    case $COLON:
      return COLON_DELIM;
    case $SEMICOLON:
      return SEMICOLON_DELIM;
    case $RBRACE:
      return RBRACE_DELIM;
    case $LBRACE:
      return LBRACE_DELIM;
    case $RPAREN:
      return RPAREN_DELIM;
    default:
      return isNewline(code) ? NEWLINE_DELIM : 0;
  }
}

bool characterContainsDelimiter(num code, num delimiters) {
  return bitWiseAnd([getDelimFromCharacter(code), delimiters]) > 0;
}

class CssAST {
  void visit(CssASTVisitor visitor, [dynamic context]) {}
}

abstract class CssASTVisitor {
  void visitCssValue(CssStyleValueAST ast, [dynamic context]);
  void visitInlineCssRule(CssInlineRuleAST ast, [dynamic context]);
  void visitCssKeyframeRule(CssKeyframeRuleAST ast, [dynamic context]);
  void visitCssKeyframeDefinition(CssKeyframeDefinitionAST ast,
      [dynamic context]);
  void visitCssMediaQueryRule(CssMediaQueryRuleAST ast, [dynamic context]);
  void visitCssSelectorRule(CssSelectorRuleAST ast, [dynamic context]);
  void visitCssSelector(CssSelectorAST ast, [dynamic context]);
  void visitCssDefinition(CssDefinitionAST ast, [dynamic context]);
  void visitCssBlock(CssBlockAST ast, [dynamic context]);
  void visitCssStyleSheet(CssStyleSheetAST ast, [dynamic context]);
  void visitUnkownRule(CssUnknownTokenListAST ast, [dynamic context]);
}

class ParsedCssResult {
  List<CssParseError> errors;
  CssStyleSheetAST ast;
  ParsedCssResult(this.errors, this.ast) {}
}

class CssParser {
  CssScanner _scanner;
  String _fileName;
  List<CssParseError> _errors = [];
  ParseSourceFile _file;
  CssParser(this._scanner, this._fileName) {
    this._file = new ParseSourceFile(this._scanner.input, _fileName);
  }
  /** @internal */
  BlockType _resolveBlockType(CssToken token) {
    switch (token.strValue) {
      case "@-o-keyframes":
      case "@-moz-keyframes":
      case "@-webkit-keyframes":
      case "@keyframes":
        return BlockType.Keyframes;
      case "@charset":
        return BlockType.Charset;
      case "@import":
        return BlockType.Import;
      case "@namespace":
        return BlockType.Namespace;
      case "@page":
        return BlockType.Page;
      case "@document":
        return BlockType.Document;
      case "@media":
        return BlockType.MediaQuery;
      case "@font-face":
        return BlockType.FontFace;
      case "@viewport":
        return BlockType.Viewport;
      case "@supports":
        return BlockType.Supports;
      default:
        return BlockType.Unsupported;
    }
  }

  ParsedCssResult parse() {
    num delimiters = EOF_DELIM;
    var ast = this._parseStyleSheet(delimiters);
    var errors = this._errors;
    this._errors = [];
    return new ParsedCssResult(errors, ast);
  }

  /** @internal */
  CssStyleSheetAST _parseStyleSheet(delimiters) {
    var results = <CssAST>[];
    this._scanner.consumeEmptyStatements();
    while (this._scanner.peek != $EOF) {
      this._scanner.setMode(CssLexerMode.BLOCK);
      results.add(this._parseRule(delimiters));
    }
    return new CssStyleSheetAST(results);
  }

  /** @internal */
  CssRuleAST _parseRule(num delimiters) {
    if (this._scanner.peek == $AT) {
      return this._parseAtRule(delimiters);
    }
    return this._parseSelectorRule(delimiters);
  }

  /** @internal */
  CssRuleAST _parseAtRule(num delimiters) {
    this._scanner.setMode(CssLexerMode.BLOCK);
    var token = this._scan();
    this._assertCondition(
        token.type == CssTokenType.AtKeyword,
        '''The CSS Rule ${ token . strValue} is not a valid [@] rule.''',
        token);
    var block, type = this._resolveBlockType(token);
    switch (type) {
      case BlockType.Charset:
      case BlockType.Namespace:
      case BlockType.Import:
        var value = this._parseValue(delimiters);
        this._scanner.setMode(CssLexerMode.BLOCK);
        this._scanner.consumeEmptyStatements();
        return new CssInlineRuleAST(type, value);
      case BlockType.Viewport:
      case BlockType.FontFace:
        block = this._parseStyleBlock(delimiters);
        return new CssBlockRuleAST(type, block);
      case BlockType.Keyframes:
        var tokens = this._collectUntilDelim(
            bitWiseOr([delimiters, RBRACE_DELIM, LBRACE_DELIM]));
        // keyframes only have one identifier name
        var name = tokens[0];
        return new CssKeyframeRuleAST(
            name, this._parseKeyframeBlock(delimiters));
      case BlockType.MediaQuery:
        this._scanner.setMode(CssLexerMode.MEDIA_QUERY);
        var tokens = this._collectUntilDelim(
            bitWiseOr([delimiters, RBRACE_DELIM, LBRACE_DELIM]));
        return new CssMediaQueryRuleAST(tokens, this._parseBlock(delimiters));
      case BlockType.Document:
      case BlockType.Supports:
      case BlockType.Page:
        this._scanner.setMode(CssLexerMode.AT_RULE_QUERY);
        var tokens = this._collectUntilDelim(
            bitWiseOr([delimiters, RBRACE_DELIM, LBRACE_DELIM]));
        return new CssBlockDefinitionRuleAST(
            type, tokens, this._parseBlock(delimiters));
      // if a custom @rule { ... } is used it should still tokenize the insides
      default:
        var listOfTokens = <CssToken>[];
        this._scanner.setMode(CssLexerMode.ALL);
        this._error(
            generateErrorMessage(
                this._scanner.input,
                '''The CSS "at" rule "${ token . strValue}" is not allowed to used here''',
                token.strValue,
                token.index,
                token.line,
                token.column),
            token);
        this
            ._collectUntilDelim(
                bitWiseOr([delimiters, LBRACE_DELIM, SEMICOLON_DELIM]))
            .forEach((token) {
          listOfTokens.add(token);
        });
        if (this._scanner.peek == $LBRACE) {
          this._consume(CssTokenType.Character, "{");
          this
              ._collectUntilDelim(
                  bitWiseOr([delimiters, RBRACE_DELIM, LBRACE_DELIM]))
              .forEach((token) {
            listOfTokens.add(token);
          });
          this._consume(CssTokenType.Character, "}");
        }
        return new CssUnknownTokenListAST(token, listOfTokens);
    }
  }

  /** @internal */
  CssSelectorRuleAST _parseSelectorRule(num delimiters) {
    var selectors = this._parseSelectors(delimiters);
    var block = this._parseStyleBlock(delimiters);
    this._scanner.setMode(CssLexerMode.BLOCK);
    this._scanner.consumeEmptyStatements();
    return new CssSelectorRuleAST(selectors, block);
  }

  /** @internal */
  List<CssSelectorAST> _parseSelectors(num delimiters) {
    delimiters = bitWiseOr([delimiters, LBRACE_DELIM]);
    var selectors = <CssSelectorAST>[];
    var isParsingSelectors = true;
    while (isParsingSelectors) {
      selectors.add(this._parseSelector(delimiters));
      isParsingSelectors =
          !characterContainsDelimiter(this._scanner.peek, delimiters);
      if (isParsingSelectors) {
        this._consume(CssTokenType.Character, ",");
        isParsingSelectors =
            !characterContainsDelimiter(this._scanner.peek, delimiters);
      }
    }
    return selectors;
  }

  /** @internal */
  CssToken _scan() {
    var output = this._scanner.scan();
    var token = output.token;
    var error = output.error;
    if (isPresent(error)) {
      this._error(error.rawMessage, token);
    }
    return token;
  }

  /** @internal */
  CssToken _consume(CssTokenType type, [String value = null]) {
    var output = this._scanner.consume(type, value);
    var token = output.token;
    var error = output.error;
    if (isPresent(error)) {
      this._error(error.rawMessage, token);
    }
    return token;
  }

  /** @internal */
  CssBlockAST _parseKeyframeBlock(num delimiters) {
    delimiters = bitWiseOr([delimiters, RBRACE_DELIM]);
    this._scanner.setMode(CssLexerMode.KEYFRAME_BLOCK);
    this._consume(CssTokenType.Character, "{");
    var definitions = <CssAST>[];
    while (!characterContainsDelimiter(this._scanner.peek, delimiters)) {
      definitions.add(this._parseKeyframeDefinition(delimiters));
    }
    this._consume(CssTokenType.Character, "}");
    return new CssBlockAST(definitions);
  }

  /** @internal */
  CssKeyframeDefinitionAST _parseKeyframeDefinition(num delimiters) {
    var stepTokens = <CssToken>[];
    delimiters = bitWiseOr([delimiters, LBRACE_DELIM]);
    while (!characterContainsDelimiter(this._scanner.peek, delimiters)) {
      stepTokens
          .add(this._parseKeyframeLabel(bitWiseOr([delimiters, COMMA_DELIM])));
      if (this._scanner.peek != $LBRACE) {
        this._consume(CssTokenType.Character, ",");
      }
    }
    var styles = this._parseStyleBlock(bitWiseOr([delimiters, RBRACE_DELIM]));
    this._scanner.setMode(CssLexerMode.BLOCK);
    return new CssKeyframeDefinitionAST(stepTokens, styles);
  }

  /** @internal */
  CssToken _parseKeyframeLabel(num delimiters) {
    this._scanner.setMode(CssLexerMode.KEYFRAME_BLOCK);
    return mergeTokens(this._collectUntilDelim(delimiters));
  }

  /** @internal */
  CssSelectorAST _parseSelector(num delimiters) {
    delimiters = bitWiseOr([delimiters, COMMA_DELIM, LBRACE_DELIM]);
    this._scanner.setMode(CssLexerMode.SELECTOR);
    var selectorCssTokens = <CssToken>[];
    var isComplex = false;
    var wsCssToken;
    var previousToken;
    var parenCount = 0;
    while (!characterContainsDelimiter(this._scanner.peek, delimiters)) {
      var code = this._scanner.peek;
      switch (code) {
        case $LPAREN:
          parenCount++;
          break;
        case $RPAREN:
          parenCount--;
          break;
        case $COLON:
          this._scanner.setMode(CssLexerMode.PSEUDO_SELECTOR);
          previousToken = this._consume(CssTokenType.Character, ":");
          selectorCssTokens.add(previousToken);
          continue;
        case $LBRACKET:
          // if we are already inside an attribute selector then we can't

          // jump into the mode again. Therefore this error will get picked

          // up when the scan method is called below.
          if (this._scanner.getMode() != CssLexerMode.ATTRIBUTE_SELECTOR) {
            selectorCssTokens.add(this._consume(CssTokenType.Character, "["));
            this._scanner.setMode(CssLexerMode.ATTRIBUTE_SELECTOR);
            continue;
          }
          break;
        case $RBRACKET:
          selectorCssTokens.add(this._consume(CssTokenType.Character, "]"));
          this._scanner.setMode(CssLexerMode.SELECTOR);
          continue;
      }
      var token = this._scan();
      // special case for the ":not(" selector since it

      // contains an inner selector that needs to be parsed

      // in isolation
      if (this._scanner.getMode() == CssLexerMode.PSEUDO_SELECTOR &&
          isPresent(previousToken) &&
          previousToken.numValue == $COLON &&
          token.strValue == "not" &&
          this._scanner.peek == $LPAREN) {
        selectorCssTokens.add(token);
        selectorCssTokens.add(this._consume(CssTokenType.Character, "("));
        // the inner selector inside of :not(...) can only be one

        // CSS selector (no commas allowed) therefore we parse only

        // one selector by calling the method below
        this
            ._parseSelector(bitWiseOr([delimiters, RPAREN_DELIM]))
            .tokens
            .forEach((innerSelectorToken) {
          selectorCssTokens.add(innerSelectorToken);
        });
        selectorCssTokens.add(this._consume(CssTokenType.Character, ")"));
        continue;
      }
      previousToken = token;
      if (token.type == CssTokenType.Whitespace) {
        wsCssToken = token;
      } else {
        if (isPresent(wsCssToken)) {
          selectorCssTokens.add(wsCssToken);
          wsCssToken = null;
          isComplex = true;
        }
        selectorCssTokens.add(token);
      }
    }
    if (this._scanner.getMode() == CssLexerMode.ATTRIBUTE_SELECTOR) {
      this._error(
          '''Unbalanced CSS attribute selector at column ${ previousToken . line}:${ previousToken . column}''',
          previousToken);
    } else if (parenCount > 0) {
      this._error(
          '''Unbalanced pseudo selector function value at column ${ previousToken . line}:${ previousToken . column}''',
          previousToken);
    }
    return new CssSelectorAST(selectorCssTokens, isComplex);
  }

  /** @internal */
  CssStyleValueAST _parseValue(num delimiters) {
    delimiters =
        bitWiseOr([delimiters, RBRACE_DELIM, SEMICOLON_DELIM, NEWLINE_DELIM]);
    this._scanner.setMode(CssLexerMode.STYLE_VALUE);
    var strValue = "";
    var tokens = <CssToken>[];
    CssToken previous;
    while (!characterContainsDelimiter(this._scanner.peek, delimiters)) {
      var token;
      if (isPresent(previous) &&
          previous.type == CssTokenType.Identifier &&
          this._scanner.peek == $LPAREN) {
        token = this._consume(CssTokenType.Character, "(");
        tokens.add(token);
        strValue += token.strValue;
        this._scanner.setMode(CssLexerMode.STYLE_VALUE_FUNCTION);
        token = this._scan();
        tokens.add(token);
        strValue += token.strValue;
        this._scanner.setMode(CssLexerMode.STYLE_VALUE);
        token = this._consume(CssTokenType.Character, ")");
        tokens.add(token);
        strValue += token.strValue;
      } else {
        token = this._scan();
        if (token.type != CssTokenType.Whitespace) {
          tokens.add(token);
        }
        strValue += token.strValue;
      }
      previous = token;
    }
    this._scanner.consumeWhitespace();
    var code = this._scanner.peek;
    if (code == $SEMICOLON) {
      this._consume(CssTokenType.Character, ";");
    } else if (code != $RBRACE) {
      this._error(
          generateErrorMessage(
              this._scanner.input,
              '''The CSS key/value definition did not end with a semicolon''',
              previous.strValue,
              previous.index,
              previous.line,
              previous.column),
          previous);
    }
    return new CssStyleValueAST(tokens, strValue);
  }

  /** @internal */
  List<CssToken> _collectUntilDelim(num delimiters,
      [CssTokenType assertType = null]) {
    var tokens = <CssToken>[];
    while (!characterContainsDelimiter(this._scanner.peek, delimiters)) {
      var val =
          isPresent(assertType) ? this._consume(assertType) : this._scan();
      tokens.add(val);
    }
    return tokens;
  }

  /** @internal */
  CssBlockAST _parseBlock(num delimiters) {
    delimiters = bitWiseOr([delimiters, RBRACE_DELIM]);
    this._scanner.setMode(CssLexerMode.BLOCK);
    this._consume(CssTokenType.Character, "{");
    this._scanner.consumeEmptyStatements();
    var results = <CssAST>[];
    while (!characterContainsDelimiter(this._scanner.peek, delimiters)) {
      results.add(this._parseRule(delimiters));
    }
    this._consume(CssTokenType.Character, "}");
    this._scanner.setMode(CssLexerMode.BLOCK);
    this._scanner.consumeEmptyStatements();
    return new CssBlockAST(results);
  }

  /** @internal */
  CssBlockAST _parseStyleBlock(num delimiters) {
    delimiters = bitWiseOr([delimiters, RBRACE_DELIM, LBRACE_DELIM]);
    this._scanner.setMode(CssLexerMode.STYLE_BLOCK);
    this._consume(CssTokenType.Character, "{");
    this._scanner.consumeEmptyStatements();
    var definitions = <CssAST>[];
    while (!characterContainsDelimiter(this._scanner.peek, delimiters)) {
      definitions.add(this._parseDefinition(delimiters));
      this._scanner.consumeEmptyStatements();
    }
    this._consume(CssTokenType.Character, "}");
    this._scanner.setMode(CssLexerMode.STYLE_BLOCK);
    this._scanner.consumeEmptyStatements();
    return new CssBlockAST(definitions);
  }

  /** @internal */
  CssDefinitionAST _parseDefinition(num delimiters) {
    this._scanner.setMode(CssLexerMode.STYLE_BLOCK);
    var prop = this._consume(CssTokenType.Identifier);
    var parseValue, value = null;
    // the colon value separates the prop from the style.

    // there are a few cases as to what could happen if it

    // is missing
    switch (this._scanner.peek) {
      case $COLON:
        this._consume(CssTokenType.Character, ":");
        parseValue = true;
        break;
      case $SEMICOLON:
      case $RBRACE:
      case $EOF:
        parseValue = false;
        break;
      default:
        var propStr = [prop.strValue];
        if (this._scanner.peek != $COLON) {
          // this will throw the error
          var nextValue = this._consume(CssTokenType.Character, ":");
          propStr.add(nextValue.strValue);
          var remainingTokens = this._collectUntilDelim(
              bitWiseOr([delimiters, COLON_DELIM, SEMICOLON_DELIM]),
              CssTokenType.Identifier);
          if (remainingTokens.length > 0) {
            remainingTokens.forEach((token) {
              propStr.add(token.strValue);
            });
          }
          prop = new CssToken(
              prop.index, prop.column, prop.line, prop.type, propStr.join(" "));
        }
        // this means we've reached the end of the definition and/or block
        if (this._scanner.peek == $COLON) {
          this._consume(CssTokenType.Character, ":");
          parseValue = true;
        } else {
          parseValue = false;
        }
        break;
    }
    if (parseValue) {
      value = this._parseValue(delimiters);
    } else {
      this._error(
          generateErrorMessage(
              this._scanner.input,
              '''The CSS property was not paired with a style value''',
              prop.strValue,
              prop.index,
              prop.line,
              prop.column),
          prop);
    }
    return new CssDefinitionAST(prop, value);
  }

  /** @internal */
  bool _assertCondition(
      bool status, String errorMessage, CssToken problemToken) {
    if (!status) {
      this._error(errorMessage, problemToken);
      return true;
    }
    return false;
  }

  /** @internal */
  _error(String message, CssToken problemToken) {
    var length = problemToken.strValue.length;
    var error = CssParseError.create(
        this._file, 0, problemToken.line, problemToken.column, length, message);
    this._errors.add(error);
  }
}

class CssStyleValueAST extends CssAST {
  List<CssToken> tokens;
  String strValue;
  CssStyleValueAST(this.tokens, this.strValue) : super() {
    /* super call moved to initializer */;
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitCssValue(this);
  }
}

class CssRuleAST extends CssAST {}

class CssBlockRuleAST extends CssRuleAST {
  BlockType type;
  CssBlockAST block;
  CssToken name;
  CssBlockRuleAST(this.type, this.block, [this.name = null]) : super() {
    /* super call moved to initializer */;
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitCssBlock(this.block, context);
  }
}

class CssKeyframeRuleAST extends CssBlockRuleAST {
  CssKeyframeRuleAST(CssToken name, CssBlockAST block)
      : super(BlockType.Keyframes, block, name) {
    /* super call moved to initializer */;
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitCssKeyframeRule(this, context);
  }
}

class CssKeyframeDefinitionAST extends CssBlockRuleAST {
  var steps;
  CssKeyframeDefinitionAST(List<CssToken> _steps, CssBlockAST block)
      : super(BlockType.Keyframes, block, mergeTokens(_steps, ",")) {
    /* super call moved to initializer */;
    this.steps = _steps;
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitCssKeyframeDefinition(this, context);
  }
}

class CssBlockDefinitionRuleAST extends CssBlockRuleAST {
  List<CssToken> query;
  String strValue;
  CssBlockDefinitionRuleAST(BlockType type, this.query, CssBlockAST block)
      : super(type, block) {
    /* super call moved to initializer */;
    this.strValue = query.map((token) => token.strValue).toList().join("");
    CssToken firstCssToken = query[0];
    this.name = new CssToken(firstCssToken.index, firstCssToken.column,
        firstCssToken.line, CssTokenType.Identifier, this.strValue);
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitCssBlock(this.block, context);
  }
}

class CssMediaQueryRuleAST extends CssBlockDefinitionRuleAST {
  CssMediaQueryRuleAST(List<CssToken> query, CssBlockAST block)
      : super(BlockType.MediaQuery, query, block) {
    /* super call moved to initializer */;
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitCssMediaQueryRule(this, context);
  }
}

class CssInlineRuleAST extends CssRuleAST {
  BlockType type;
  CssStyleValueAST value;
  CssInlineRuleAST(this.type, this.value) : super() {
    /* super call moved to initializer */;
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitInlineCssRule(this, context);
  }
}

class CssSelectorRuleAST extends CssBlockRuleAST {
  List<CssSelectorAST> selectors;
  String strValue;
  CssSelectorRuleAST(this.selectors, CssBlockAST block)
      : super(BlockType.Selector, block) {
    /* super call moved to initializer */;
    this.strValue =
        selectors.map((selector) => selector.strValue).toList().join(",");
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitCssSelectorRule(this, context);
  }
}

class CssDefinitionAST extends CssAST {
  CssToken property;
  CssStyleValueAST value;
  CssDefinitionAST(this.property, this.value) : super() {
    /* super call moved to initializer */;
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitCssDefinition(this, context);
  }
}

class CssSelectorAST extends CssAST {
  List<CssToken> tokens;
  bool isComplex;
  var strValue;
  CssSelectorAST(this.tokens, [this.isComplex = false]) : super() {
    /* super call moved to initializer */;
    this.strValue = tokens.map((token) => token.strValue).toList().join("");
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitCssSelector(this, context);
  }
}

class CssBlockAST extends CssAST {
  List<CssAST> entries;
  CssBlockAST(this.entries) : super() {
    /* super call moved to initializer */;
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitCssBlock(this, context);
  }
}

class CssStyleSheetAST extends CssAST {
  List<CssAST> rules;
  CssStyleSheetAST(this.rules) : super() {
    /* super call moved to initializer */;
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitCssStyleSheet(this, context);
  }
}

class CssParseError extends ParseError {
  static CssParseError create(ParseSourceFile file, num offset, num line,
      num col, num length, String errMsg) {
    var start = new ParseLocation(file, offset, line, col);
    var end = new ParseLocation(file, offset, line, col + length);
    var span = new ParseSourceSpan(start, end);
    return new CssParseError(span, "CSS Parse Error: " + errMsg);
  }

  CssParseError(ParseSourceSpan span, String message) : super(span, message) {
    /* super call moved to initializer */;
  }
}

class CssUnknownTokenListAST extends CssRuleAST {
  var name;
  List<CssToken> tokens;
  CssUnknownTokenListAST(this.name, this.tokens) : super() {
    /* super call moved to initializer */;
  }
  visit(CssASTVisitor visitor, [dynamic context]) {
    visitor.visitUnkownRule(this, context);
  }
}
