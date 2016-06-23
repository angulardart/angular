library angular2.src.compiler.expression_parser.parser;

import "package:angular2/src/core/di/decorators.dart" show Injectable;
import "package:angular2/src/facade/lang.dart"
    show isBlank, isPresent, StringWrapper;
import "package:angular2/src/facade/exceptions.dart"
    show BaseException, WrappedException;
import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "lexer.dart"
    show
        Lexer,
        EOF,
        isIdentifier,
        isQuote,
        Token,
        $PERIOD,
        $COLON,
        $SEMICOLON,
        $LBRACKET,
        $RBRACKET,
        $COMMA,
        $LBRACE,
        $RBRACE,
        $LPAREN,
        $RPAREN,
        $SLASH;
import "ast.dart"
    show
        AST,
        EmptyExpr,
        ImplicitReceiver,
        PropertyRead,
        PropertyWrite,
        SafePropertyRead,
        LiteralPrimitive,
        Binary,
        PrefixNot,
        Conditional,
        BindingPipe,
        Chain,
        KeyedRead,
        KeyedWrite,
        LiteralArray,
        LiteralMap,
        Interpolation,
        MethodCall,
        SafeMethodCall,
        FunctionCall,
        TemplateBinding,
        ASTWithSource,
        AstVisitor,
        Quote;

var _implicitReceiver = new ImplicitReceiver();
// TODO(tbosch): Cannot make this const/final right now because of the transpiler...
var INTERPOLATION_REGEXP = new RegExp(r'\{\{([\s\S]*?)\}\}');

class ParseException extends BaseException {
  ParseException(String message, String input, String errLocation,
      [dynamic ctxLocation])
      : super(
            '''Parser Error: ${ message} ${ errLocation} [${ input}] in ${ ctxLocation}''') {
    /* super call moved to initializer */;
  }
}

class SplitInterpolation {
  List<String> strings;
  List<String> expressions;
  SplitInterpolation(this.strings, this.expressions) {}
}

@Injectable()
class Parser {
  Lexer _lexer;
  Parser(this._lexer) {}
  ASTWithSource parseAction(String input, dynamic location) {
    this._checkNoInterpolation(input, location);
    var tokens = this._lexer.tokenize(this._stripComments(input));
    var ast = new _ParseAST(input, location, tokens, true).parseChain();
    return new ASTWithSource(ast, input, location);
  }

  ASTWithSource parseBinding(String input, dynamic location) {
    var ast = this._parseBindingAst(input, location);
    return new ASTWithSource(ast, input, location);
  }

  ASTWithSource parseSimpleBinding(String input, String location) {
    var ast = this._parseBindingAst(input, location);
    if (!SimpleExpressionChecker.check(ast)) {
      throw new ParseException(
          "Host binding expression can only contain field access and constants",
          input,
          location);
    }
    return new ASTWithSource(ast, input, location);
  }

  AST _parseBindingAst(String input, String location) {
    // Quotes expressions use 3rd-party expression language. We don't want to use

    // our lexer or parser for that, so we check for that ahead of time.
    var quote = this._parseQuote(input, location);
    if (isPresent(quote)) {
      return quote;
    }
    this._checkNoInterpolation(input, location);
    var tokens = this._lexer.tokenize(this._stripComments(input));
    return new _ParseAST(input, location, tokens, false).parseChain();
  }

  AST _parseQuote(String input, dynamic location) {
    if (isBlank(input)) return null;
    var prefixSeparatorIndex = input.indexOf(":");
    if (prefixSeparatorIndex == -1) return null;
    var prefix = input.substring(0, prefixSeparatorIndex).trim();
    if (!isIdentifier(prefix)) return null;
    var uninterpretedExpression = input.substring(prefixSeparatorIndex + 1);
    return new Quote(prefix, uninterpretedExpression, location);
  }

  List<TemplateBinding> parseTemplateBindings(String input, dynamic location) {
    var tokens = this._lexer.tokenize(input);
    return new _ParseAST(input, location, tokens, false)
        .parseTemplateBindings();
  }

  ASTWithSource parseInterpolation(String input, dynamic location) {
    var split = this.splitInterpolation(input, location);
    if (split == null) return null;
    var expressions = [];
    for (var i = 0; i < split.expressions.length; ++i) {
      var tokens =
          this._lexer.tokenize(this._stripComments(split.expressions[i]));
      var ast = new _ParseAST(input, location, tokens, false).parseChain();
      expressions.add(ast);
    }
    return new ASTWithSource(
        new Interpolation(split.strings, expressions), input, location);
  }

  SplitInterpolation splitInterpolation(String input, String location) {
    var parts = StringWrapper.split(input, INTERPOLATION_REGEXP);
    if (parts.length <= 1) {
      return null;
    }
    var strings = [];
    var expressions = [];
    for (var i = 0; i < parts.length; i++) {
      String part = parts[i];
      if (identical(i % 2, 0)) {
        // fixed string
        strings.add(part);
      } else if (part.trim().length > 0) {
        expressions.add(part);
      } else {
        throw new ParseException(
            "Blank expressions are not allowed in interpolated strings",
            input,
            '''at column ${ this . _findInterpolationErrorColumn ( parts , i )} in''',
            location);
      }
    }
    return new SplitInterpolation(strings, expressions);
  }

  ASTWithSource wrapLiteralPrimitive(String input, dynamic location) {
    return new ASTWithSource(new LiteralPrimitive(input), input, location);
  }

  String _stripComments(String input) {
    var i = this._commentStart(input);
    return isPresent(i) ? input.substring(0, i).trim() : input;
  }

  num _commentStart(String input) {
    var outerQuote = null;
    for (var i = 0; i < input.length - 1; i++) {
      var char = StringWrapper.charCodeAt(input, i);
      var nextChar = StringWrapper.charCodeAt(input, i + 1);
      if (identical(char, $SLASH) && nextChar == $SLASH && isBlank(outerQuote))
        return i;
      if (identical(outerQuote, char)) {
        outerQuote = null;
      } else if (isBlank(outerQuote) && isQuote(char)) {
        outerQuote = char;
      }
    }
    return null;
  }

  void _checkNoInterpolation(String input, dynamic location) {
    var parts = StringWrapper.split(input, INTERPOLATION_REGEXP);
    if (parts.length > 1) {
      throw new ParseException(
          "Got interpolation ({{}}) where expression was expected",
          input,
          '''at column ${ this . _findInterpolationErrorColumn ( parts , 1 )} in''',
          location);
    }
  }

  num _findInterpolationErrorColumn(List<String> parts, num partInErrIdx) {
    var errLocation = "";
    for (var j = 0; j < partInErrIdx; j++) {
      errLocation += identical(j % 2, 0) ? parts[j] : '''{{${ parts [ j ]}}}''';
    }
    return errLocation.length;
  }
}

class _ParseAST {
  String input;
  dynamic location;
  List<dynamic> tokens;
  bool parseAction;
  num index = 0;
  _ParseAST(this.input, this.location, this.tokens, this.parseAction) {}
  Token peek(num offset) {
    var i = this.index + offset;
    return i < this.tokens.length ? this.tokens[i] : EOF;
  }

  Token get next {
    return this.peek(0);
  }

  num get inputIndex {
    return (this.index < this.tokens.length)
        ? this.next.index
        : this.input.length;
  }

  advance() {
    this.index++;
  }

  bool optionalCharacter(num code) {
    if (this.next.isCharacter(code)) {
      this.advance();
      return true;
    } else {
      return false;
    }
  }

  bool optionalKeywordVar() {
    if (this.peekKeywordVar()) {
      this.advance();
      return true;
    } else {
      return false;
    }
  }

  bool peekKeywordVar() {
    return this.next.isKeywordVar() || this.next.isOperator("#");
  }

  expectCharacter(num code) {
    if (this.optionalCharacter(code)) return;
    this.error(
        '''Missing expected ${ StringWrapper . fromCharCode ( code )}''');
  }

  bool optionalOperator(String op) {
    if (this.next.isOperator(op)) {
      this.advance();
      return true;
    } else {
      return false;
    }
  }

  expectOperator(String operator) {
    if (this.optionalOperator(operator)) return;
    this.error('''Missing expected operator ${ operator}''');
  }

  String expectIdentifierOrKeyword() {
    var n = this.next;
    if (!n.isIdentifier() && !n.isKeyword()) {
      this.error('''Unexpected token ${ n}, expected identifier or keyword''');
    }
    this.advance();
    return n.toString();
  }

  String expectIdentifierOrKeywordOrString() {
    var n = this.next;
    if (!n.isIdentifier() && !n.isKeyword() && !n.isString()) {
      this.error(
          '''Unexpected token ${ n}, expected identifier, keyword, or string''');
    }
    this.advance();
    return n.toString();
  }

  AST parseChain() {
    var exprs = [];
    while (this.index < this.tokens.length) {
      var expr = this.parsePipe();
      exprs.add(expr);
      if (this.optionalCharacter($SEMICOLON)) {
        if (!this.parseAction) {
          this.error("Binding expression cannot contain chained expression");
        }
        while (this.optionalCharacter($SEMICOLON)) {}
      } else if (this.index < this.tokens.length) {
        this.error('''Unexpected token \'${ this . next}\'''');
      }
    }
    if (exprs.length == 0) return new EmptyExpr();
    if (exprs.length == 1) return exprs[0];
    return new Chain(exprs);
  }

  AST parsePipe() {
    var result = this.parseExpression();
    if (this.optionalOperator("|")) {
      if (this.parseAction) {
        this.error("Cannot have a pipe in an action expression");
      }
      do {
        var name = this.expectIdentifierOrKeyword();
        var args = [];
        while (this.optionalCharacter($COLON)) {
          args.add(this.parseExpression());
        }
        result = new BindingPipe(result, name, args);
      } while (this.optionalOperator("|"));
    }
    return result;
  }

  AST parseExpression() {
    return this.parseConditional();
  }

  AST parseConditional() {
    var start = this.inputIndex;
    var result = this.parseLogicalOr();
    if (this.optionalOperator("?")) {
      var yes = this.parsePipe();
      if (!this.optionalCharacter($COLON)) {
        var end = this.inputIndex;
        var expression = this.input.substring(start, end);
        this.error(
            '''Conditional expression ${ expression} requires all 3 expressions''');
      }
      var no = this.parsePipe();
      return new Conditional(result, yes, no);
    } else {
      return result;
    }
  }

  AST parseLogicalOr() {
    // '||'
    var result = this.parseLogicalAnd();
    while (this.optionalOperator("||")) {
      result = new Binary("||", result, this.parseLogicalAnd());
    }
    return result;
  }

  AST parseLogicalAnd() {
    // '&&'
    var result = this.parseEquality();
    while (this.optionalOperator("&&")) {
      result = new Binary("&&", result, this.parseEquality());
    }
    return result;
  }

  AST parseEquality() {
    // '==','!=','===','!=='
    var result = this.parseRelational();
    while (true) {
      if (this.optionalOperator("==")) {
        result = new Binary("==", result, this.parseRelational());
      } else if (this.optionalOperator("===")) {
        result = new Binary("===", result, this.parseRelational());
      } else if (this.optionalOperator("!=")) {
        result = new Binary("!=", result, this.parseRelational());
      } else if (this.optionalOperator("!==")) {
        result = new Binary("!==", result, this.parseRelational());
      } else {
        return result;
      }
    }
  }

  AST parseRelational() {
    // '<', '>', '<=', '>='
    var result = this.parseAdditive();
    while (true) {
      if (this.optionalOperator("<")) {
        result = new Binary("<", result, this.parseAdditive());
      } else if (this.optionalOperator(">")) {
        result = new Binary(">", result, this.parseAdditive());
      } else if (this.optionalOperator("<=")) {
        result = new Binary("<=", result, this.parseAdditive());
      } else if (this.optionalOperator(">=")) {
        result = new Binary(">=", result, this.parseAdditive());
      } else {
        return result;
      }
    }
  }

  AST parseAdditive() {
    // '+', '-'
    var result = this.parseMultiplicative();
    while (true) {
      if (this.optionalOperator("+")) {
        result = new Binary("+", result, this.parseMultiplicative());
      } else if (this.optionalOperator("-")) {
        result = new Binary("-", result, this.parseMultiplicative());
      } else {
        return result;
      }
    }
  }

  AST parseMultiplicative() {
    // '*', '%', '/'
    var result = this.parsePrefix();
    while (true) {
      if (this.optionalOperator("*")) {
        result = new Binary("*", result, this.parsePrefix());
      } else if (this.optionalOperator("%")) {
        result = new Binary("%", result, this.parsePrefix());
      } else if (this.optionalOperator("/")) {
        result = new Binary("/", result, this.parsePrefix());
      } else {
        return result;
      }
    }
  }

  AST parsePrefix() {
    if (this.optionalOperator("+")) {
      return this.parsePrefix();
    } else if (this.optionalOperator("-")) {
      return new Binary("-", new LiteralPrimitive(0), this.parsePrefix());
    } else if (this.optionalOperator("!")) {
      return new PrefixNot(this.parsePrefix());
    } else {
      return this.parseCallChain();
    }
  }

  AST parseCallChain() {
    var result = this.parsePrimary();
    while (true) {
      if (this.optionalCharacter($PERIOD)) {
        result = this.parseAccessMemberOrMethodCall(result, false);
      } else if (this.optionalOperator("?.")) {
        result = this.parseAccessMemberOrMethodCall(result, true);
      } else if (this.optionalCharacter($LBRACKET)) {
        var key = this.parsePipe();
        this.expectCharacter($RBRACKET);
        if (this.optionalOperator("=")) {
          var value = this.parseConditional();
          result = new KeyedWrite(result, key, value);
        } else {
          result = new KeyedRead(result, key);
        }
      } else if (this.optionalCharacter($LPAREN)) {
        var args = this.parseCallArguments();
        this.expectCharacter($RPAREN);
        result = new FunctionCall(result, args);
      } else {
        return result;
      }
    }
  }

  AST parsePrimary() {
    if (this.optionalCharacter($LPAREN)) {
      var result = this.parsePipe();
      this.expectCharacter($RPAREN);
      return result;
    } else if (this.next.isKeywordNull() || this.next.isKeywordUndefined()) {
      this.advance();
      return new LiteralPrimitive(null);
    } else if (this.next.isKeywordTrue()) {
      this.advance();
      return new LiteralPrimitive(true);
    } else if (this.next.isKeywordFalse()) {
      this.advance();
      return new LiteralPrimitive(false);
    } else if (this.optionalCharacter($LBRACKET)) {
      var elements = this.parseExpressionList($RBRACKET);
      this.expectCharacter($RBRACKET);
      return new LiteralArray(elements);
    } else if (this.next.isCharacter($LBRACE)) {
      return this.parseLiteralMap();
    } else if (this.next.isIdentifier()) {
      return this.parseAccessMemberOrMethodCall(_implicitReceiver, false);
    } else if (this.next.isNumber()) {
      var value = this.next.toNumber();
      this.advance();
      return new LiteralPrimitive(value);
    } else if (this.next.isString()) {
      var literalValue = this.next.toString();
      this.advance();
      return new LiteralPrimitive(literalValue);
    } else if (this.index >= this.tokens.length) {
      this.error('''Unexpected end of expression: ${ this . input}''');
    } else {
      this.error('''Unexpected token ${ this . next}''');
    }
    // error() throws, so we don't reach here.
    throw new BaseException("Fell through all cases in parsePrimary");
  }

  List<dynamic> parseExpressionList(num terminator) {
    var result = [];
    if (!this.next.isCharacter(terminator)) {
      do {
        result.add(this.parsePipe());
      } while (this.optionalCharacter($COMMA));
    }
    return result;
  }

  LiteralMap parseLiteralMap() {
    var keys = [];
    var values = [];
    this.expectCharacter($LBRACE);
    if (!this.optionalCharacter($RBRACE)) {
      do {
        var key = this.expectIdentifierOrKeywordOrString();
        keys.add(key);
        this.expectCharacter($COLON);
        values.add(this.parsePipe());
      } while (this.optionalCharacter($COMMA));
      this.expectCharacter($RBRACE);
    }
    return new LiteralMap(keys, values);
  }

  AST parseAccessMemberOrMethodCall(AST receiver, [bool isSafe = false]) {
    var id = this.expectIdentifierOrKeyword();
    if (this.optionalCharacter($LPAREN)) {
      var args = this.parseCallArguments();
      this.expectCharacter($RPAREN);
      return isSafe
          ? new SafeMethodCall(receiver, id, args)
          : new MethodCall(receiver, id, args);
    } else {
      if (isSafe) {
        if (this.optionalOperator("=")) {
          this.error("The '?.' operator cannot be used in the assignment");
        } else {
          return new SafePropertyRead(receiver, id);
        }
      } else {
        if (this.optionalOperator("=")) {
          if (!this.parseAction) {
            this.error("Bindings cannot contain assignments");
          }
          var value = this.parseConditional();
          return new PropertyWrite(receiver, id, value);
        } else {
          return new PropertyRead(receiver, id);
        }
      }
    }
    return null;
  }

  List<BindingPipe> parseCallArguments() {
    if (this.next.isCharacter($RPAREN)) return [];
    var positionals = [];
    do {
      positionals.add(this.parsePipe());
    } while (this.optionalCharacter($COMMA));
    return positionals;
  }

  AST parseBlockContent() {
    if (!this.parseAction) {
      this.error("Binding expression cannot contain chained expression");
    }
    var exprs = [];
    while (this.index < this.tokens.length && !this.next.isCharacter($RBRACE)) {
      var expr = this.parseExpression();
      exprs.add(expr);
      if (this.optionalCharacter($SEMICOLON)) {
        while (this.optionalCharacter($SEMICOLON)) {}
      }
    }
    if (exprs.length == 0) return new EmptyExpr();
    if (exprs.length == 1) return exprs[0];
    return new Chain(exprs);
  }

  /**
   * An identifier, a keyword, a string with an optional `-` inbetween.
   */
  String expectTemplateBindingKey() {
    var result = "";
    var operatorFound = false;
    do {
      result += this.expectIdentifierOrKeywordOrString();
      operatorFound = this.optionalOperator("-");
      if (operatorFound) {
        result += "-";
      }
    } while (operatorFound);
    return result.toString();
  }

  List<dynamic> parseTemplateBindings() {
    var bindings = [];
    var prefix = null;
    while (this.index < this.tokens.length) {
      bool keyIsVar = this.optionalKeywordVar();
      var key = this.expectTemplateBindingKey();
      if (!keyIsVar) {
        if (prefix == null) {
          prefix = key;
        } else {
          key = prefix + key[0].toUpperCase() + key.substring(1);
        }
      }
      this.optionalCharacter($COLON);
      var name = null;
      var expression = null;
      if (keyIsVar) {
        if (this.optionalOperator("=")) {
          name = this.expectTemplateBindingKey();
        } else {
          name = "\$implicit";
        }
      } else if (!identical(this.next, EOF) && !this.peekKeywordVar()) {
        var start = this.inputIndex;
        var ast = this.parsePipe();
        var source = this.input.substring(start, this.inputIndex);
        expression = new ASTWithSource(ast, source, this.location);
      }
      bindings.add(new TemplateBinding(key, keyIsVar, name, expression));
      if (!this.optionalCharacter($SEMICOLON)) {
        this.optionalCharacter($COMMA);
      }
    }
    return bindings;
  }

  error(String message, [num index = null]) {
    if (isBlank(index)) index = this.index;
    var location = (index < this.tokens.length)
        ? '''at column ${ this . tokens [ index ] . index + 1} in'''
        : '''at the end of the expression''';
    throw new ParseException(message, this.input, location, this.location);
  }
}

class SimpleExpressionChecker implements AstVisitor {
  static bool check(AST ast) {
    var s = new SimpleExpressionChecker();
    ast.visit(s);
    return s.simple;
  }

  var simple = true;
  visitImplicitReceiver(ImplicitReceiver ast, dynamic context) {}
  visitInterpolation(Interpolation ast, dynamic context) {
    this.simple = false;
  }

  visitLiteralPrimitive(LiteralPrimitive ast, dynamic context) {}
  visitPropertyRead(PropertyRead ast, dynamic context) {}
  visitPropertyWrite(PropertyWrite ast, dynamic context) {
    this.simple = false;
  }

  visitSafePropertyRead(SafePropertyRead ast, dynamic context) {
    this.simple = false;
  }

  visitMethodCall(MethodCall ast, dynamic context) {
    this.simple = false;
  }

  visitSafeMethodCall(SafeMethodCall ast, dynamic context) {
    this.simple = false;
  }

  visitFunctionCall(FunctionCall ast, dynamic context) {
    this.simple = false;
  }

  visitLiteralArray(LiteralArray ast, dynamic context) {
    this.visitAll(ast.expressions);
  }

  visitLiteralMap(LiteralMap ast, dynamic context) {
    this.visitAll(ast.values);
  }

  visitBinary(Binary ast, dynamic context) {
    this.simple = false;
  }

  visitPrefixNot(PrefixNot ast, dynamic context) {
    this.simple = false;
  }

  visitConditional(Conditional ast, dynamic context) {
    this.simple = false;
  }

  visitPipe(BindingPipe ast, dynamic context) {
    this.simple = false;
  }

  visitKeyedRead(KeyedRead ast, dynamic context) {
    this.simple = false;
  }

  visitKeyedWrite(KeyedWrite ast, dynamic context) {
    this.simple = false;
  }

  List<dynamic> visitAll(List<dynamic> asts) {
    var res = ListWrapper.createFixedSize(asts.length);
    for (var i = 0; i < asts.length; ++i) {
      res[i] = asts[i].visit(this);
    }
    return res;
  }

  visitChain(Chain ast, dynamic context) {
    this.simple = false;
  }

  visitQuote(Quote ast, dynamic context) {
    this.simple = false;
  }
}
