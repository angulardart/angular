import 'package:angular_compiler/cli.dart';

import '../../compiler/compile_metadata.dart';
import '../../facade/lang.dart' show jsSplit;
import 'ast.dart'
    show
        AST,
        ASTWithSource,
        AstVisitor,
        Binary,
        BindingPipe,
        Chain,
        Conditional,
        EmptyExpr,
        FunctionCall,
        IfNull,
        ImplicitReceiver,
        Interpolation,
        KeyedRead,
        KeyedWrite,
        LiteralArray,
        LiteralMap,
        LiteralPrimitive,
        MethodCall,
        NamedExpr,
        PrefixNot,
        PropertyRead,
        PropertyWrite,
        SafeMethodCall,
        SafePropertyRead,
        StaticRead,
        TemplateBinding;
import 'lexer.dart'
    show
        Lexer,
        EOF,
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

final _implicitReceiver = ImplicitReceiver();
final INTERPOLATION_REGEXP = RegExp(r'{{([\s\S]*?)}}');

class ParseException extends BuildError {
  ParseException(
    String message,
    String input,
    String errLocation, [
    dynamic ctxLocation,
  ]) : super('Parser Error: $message $errLocation [$input] in $ctxLocation');
}

class SplitInterpolation {
  List<String> strings;
  List<String> expressions;
  SplitInterpolation(this.strings, this.expressions);
}

class TemplateBindingParseResult {
  List<TemplateBinding> templateBindings;
  List<String> warnings;
  TemplateBindingParseResult(this.templateBindings, this.warnings);
}

class Parser {
  final Lexer _lexer;

  Parser(this._lexer);

  ASTWithSource parseAction(
      String input, String location, List<CompileIdentifierMetadata> exports) {
    if (input == null) {
      throw ParseException(
        'Blank expressions are not allowed in event bindings.',
        input,
        location,
      );
    }
    this._checkNoInterpolation(input, location);
    var tokens = _lexer.tokenize(this._stripComments(input));
    var ast = _ParseAST(input, location, tokens, true, exports).parseChain();
    return ASTWithSource(ast, input, location);
  }

  ASTWithSource parseBinding(
      String input, String location, List<CompileIdentifierMetadata> exports) {
    var ast = _parseBindingAst(input, location, exports);
    return ASTWithSource(ast, input, location);
  }

  ASTWithSource parseSimpleBinding(
      String input, String location, List<CompileIdentifierMetadata> exports) {
    var ast = _parseBindingAst(input, location, exports);
    if (!SimpleExpressionChecker.check(ast)) {
      throw ParseException(
          'Host binding expression can only contain field access and constants',
          input,
          location);
    }
    return ASTWithSource(ast, input, location);
  }

  AST _parseBindingAst(
      String input, String location, List<CompileIdentifierMetadata> exports) {
    this._checkNoInterpolation(input, location);
    var tokens = _lexer.tokenize(this._stripComments(input));
    return _ParseAST(input, location, tokens, false, exports).parseChain();
  }

  TemplateBindingParseResult parseTemplateBindings(
      String input, String location, List<CompileIdentifierMetadata> exports) {
    var tokens = _lexer.tokenize(input);
    return _ParseAST(input, location, tokens, false, exports)
        .parseTemplateBindings();
  }

  ASTWithSource parseInterpolation(
      String input, String location, List<CompileIdentifierMetadata> exports) {
    var split = splitInterpolation(input, location);
    if (split == null) return null;
    var expressions = <AST>[];
    for (var i = 0; i < split.expressions.length; ++i) {
      var tokens = this._lexer.tokenize(_stripComments(split.expressions[i]));
      var ast = _ParseAST(input, location, tokens, false, exports).parseChain();
      expressions.add(ast);
    }
    return ASTWithSource(
        Interpolation(split.strings, expressions), input, location);
  }

  SplitInterpolation splitInterpolation(String input, String location) {
    var parts = jsSplit(input, INTERPOLATION_REGEXP);
    if (parts.length <= 1) {
      return null;
    }
    var strings = <String>[];
    var expressions = <String>[];
    for (var i = 0; i < parts.length; i++) {
      String part = parts[i];
      if (i.isEven) {
        // fixed string
        strings.add(part);
      } else if (part.trim().length > 0) {
        expressions.add(part);
      } else {
        throw ParseException(
            'Blank expressions are not allowed in interpolated strings',
            input,
            'at column ${_findInterpolationErrorColumn(parts, i)} in',
            location);
      }
    }
    return SplitInterpolation(strings, expressions);
  }

  ASTWithSource wrapLiteralPrimitive(String input, String location) {
    return ASTWithSource(LiteralPrimitive(input), input, location);
  }

  String _stripComments(String input) {
    var i = _commentStart(input);
    return i != null ? input.substring(0, i).trim() : input;
  }

  int _commentStart(String input) {
    var outerQuote;
    for (var i = 0; i < input.length - 1; i++) {
      var char = input.codeUnitAt(i);
      var nextChar = input.codeUnitAt(i + 1);
      if (identical(char, $SLASH) && nextChar == $SLASH && outerQuote == null)
        return i;
      if (identical(outerQuote, char)) {
        outerQuote = null;
      } else if (outerQuote == null && isQuote(char)) {
        outerQuote = char;
      }
    }
    return null;
  }

  void _checkNoInterpolation(String input, String location) {
    if (input == null) {
      throw ParseException('Expected non-null value', input, location);
    }
    var parts = jsSplit(input, INTERPOLATION_REGEXP);
    if (parts.length > 1) {
      throw ParseException(
          'Got interpolation ({{}}) where expression was expected',
          input,
          'at column ${_findInterpolationErrorColumn(parts, 1)} in',
          location);
    }
  }

  int _findInterpolationErrorColumn(List<String> parts, int partInErrIdx) {
    var errLocation = '';
    for (var j = 0; j < partInErrIdx; j++) {
      errLocation += j.isEven ? parts[j] : '{{${parts[j]}}}';
    }
    return errLocation.length;
  }
}

class _ParseAST {
  final String input;
  final String location;
  final List<Token> tokens;
  final bool parseAction;

  Map<String, CompileIdentifierMetadata> exports;
  Map<String, Map<String, CompileIdentifierMetadata>> prefixes;
  int index = 0;
  bool _parseCall = false;

  _ParseAST(this.input, this.location, this.tokens, this.parseAction,
      List<CompileIdentifierMetadata> exports) {
    this.exports = <String, CompileIdentifierMetadata>{};
    this.prefixes = <String, Map<String, CompileIdentifierMetadata>>{};
    for (var export in exports) {
      if (export.prefix == null) {
        this.exports[export.name] = export;
      } else {
        this.prefixes.putIfAbsent(
            export.prefix, () => <String, CompileIdentifierMetadata>{});
        this.prefixes[export.prefix][export.name] = export;
      }
    }
  }

  Token peek(int offset) {
    var i = index + offset;
    return i < tokens.length ? tokens[i] : EOF;
  }

  Token get next => peek(0);

  int get inputIndex => index < tokens.length ? next.index : input.length;

  void advance() {
    index++;
  }

  bool optionalCharacter(int code) {
    if (next.isCharacter(code)) {
      advance();
      return true;
    }
    return false;
  }

  bool peekKeywordLet() => next.isKeywordLet;

  bool peekDeprecatedKeywordVar() => next.isKeywordDeprecatedVar;

  bool peekDeprecatedOperatorHash() => next.isOperator('#');

  void expectCharacter(int code) {
    if (optionalCharacter(code)) return;
    error('Missing expected ${String.fromCharCode(code)}');
  }

  bool optionalOperator(String op) {
    if (next.isOperator(op)) {
      advance();
      return true;
    }
    return false;
  }

  void expectOperator(String operator) {
    if (optionalOperator(operator)) return;
    error('Missing expected operator $operator');
  }

  String expectIdentifierOrKeyword() {
    var n = next;
    if (!n.isIdentifier && !n.isKeyword) {
      error('Unexpected token $n, expected identifier or keyword');
    }
    advance();
    return n.toString();
  }

  String expectIdentifierOrKeywordOrString() {
    var n = next;
    if (!n.isIdentifier && !n.isKeyword && !n.isString) {
      error('Unexpected token $n, expected identifier, keyword, or string');
    }
    advance();
    return n.toString();
  }

  AST parseChain() {
    var exprs = <AST>[];
    while (index < tokens.length) {
      var expr = parsePipe();
      exprs.add(expr);
      if (optionalCharacter($SEMICOLON)) {
        if (!parseAction) {
          error('Binding expression cannot contain chained expression');
        }
        while (optionalCharacter($SEMICOLON)) {}
      } else if (index < tokens.length) {
        error("Unexpected token '$next'");
      }
    }
    if (exprs.length == 0) return EmptyExpr();
    if (exprs.length == 1) return exprs[0];
    return Chain(exprs);
  }

  AST parseArgument() => parseExpression();

  AST parsePipe() {
    var result = parseExpression();
    if (optionalOperator('|')) {
      if (parseAction) {
        error('Cannot have a pipe in an action expression');
      }
      do {
        var name = expectIdentifierOrKeyword();
        var args = <AST>[];
        while (optionalCharacter($COLON)) {
          args.add(parseExpression());
        }
        result = BindingPipe(result, name, args);
      } while (optionalOperator('|'));
    }
    return result;
  }

  AST parseExpression() => parseConditional();

  AST parseConditional() {
    var start = inputIndex;
    var result = parseLogicalOr();
    if (optionalOperator('??')) {
      var nullExp = parsePipe();
      return IfNull(result, nullExp);
    } else if (optionalOperator('?')) {
      var prevParseCall = _parseCall;
      _parseCall = false;
      var yes = parsePipe();
      if (!optionalCharacter($COLON)) {
        var end = inputIndex;
        var expression = input.substring(start, end);
        error('Conditional expression $expression requires all 3 expressions');
      }
      var no = parsePipe();
      _parseCall = prevParseCall;
      return Conditional(result, yes, no);
    } else {
      return result;
    }
  }

  AST parseLogicalOr() {
    // '||'
    var result = parseLogicalAnd();
    while (optionalOperator('||')) {
      result = Binary('||', result, parseLogicalAnd());
    }
    return result;
  }

  AST parseLogicalAnd() {
    // '&&'
    var result = parseEquality();
    while (optionalOperator('&&')) {
      result = Binary('&&', result, parseEquality());
    }
    return result;
  }

  AST parseEquality() {
    // '==','!=','===','!=='
    var result = parseRelational();
    while (true) {
      if (optionalOperator('==')) {
        result = Binary('==', result, parseRelational());
      } else if (optionalOperator('===')) {
        result = Binary('===', result, parseRelational());
      } else if (optionalOperator('!=')) {
        result = Binary('!=', result, parseRelational());
      } else if (optionalOperator('!==')) {
        result = Binary('!==', result, parseRelational());
      } else {
        return result;
      }
    }
  }

  AST parseRelational() {
    // '<', '>', '<=', '>='
    var result = parseAdditive();
    while (true) {
      if (optionalOperator('<')) {
        result = Binary('<', result, parseAdditive());
      } else if (optionalOperator('>')) {
        result = Binary('>', result, parseAdditive());
      } else if (optionalOperator('<=')) {
        result = Binary('<=', result, parseAdditive());
      } else if (optionalOperator('>=')) {
        result = Binary('>=', result, parseAdditive());
      } else {
        return result;
      }
    }
  }

  AST parseAdditive() {
    // '+', '-'
    var result = parseMultiplicative();
    while (true) {
      if (optionalOperator('+')) {
        result = Binary('+', result, parseMultiplicative());
      } else if (optionalOperator('-')) {
        result = Binary('-', result, parseMultiplicative());
      } else {
        return result;
      }
    }
  }

  AST parseMultiplicative() {
    // '*', '%', '/'
    var result = parsePrefix();
    while (true) {
      if (optionalOperator('*')) {
        result = Binary('*', result, parsePrefix());
      } else if (optionalOperator('%')) {
        result = Binary('%', result, parsePrefix());
      } else if (optionalOperator('/')) {
        result = Binary('/', result, parsePrefix());
      } else {
        return result;
      }
    }
  }

  AST parsePrefix() {
    if (optionalOperator('+')) {
      return parsePrefix();
    } else if (optionalOperator('-')) {
      return Binary('-', LiteralPrimitive(0), parsePrefix());
    } else if (optionalOperator('!')) {
      return PrefixNot(parsePrefix());
    } else {
      return parseCallChain();
    }
  }

  AST parseCallChain() {
    var result = parsePrimary();
    while (true) {
      if (optionalCharacter($PERIOD)) {
        result = parseAccessMemberOrMethodCall(result, false);
      } else if (optionalOperator('?.')) {
        result = parseAccessMemberOrMethodCall(result, true);
      } else if (optionalCharacter($LBRACKET)) {
        var key = parsePipe();
        expectCharacter($RBRACKET);
        if (optionalOperator('=')) {
          var value = parseConditional();
          result = KeyedWrite(result, key, value);
        } else {
          result = KeyedRead(result, key);
        }
      } else if (_parseCall && optionalCharacter($COLON)) {
        _parseCall = false;
        var expression = parseExpression();
        _parseCall = true;
        if (result is! PropertyRead) {
          error('Expected previous token to be an identifier');
        }
        result = NamedExpr((result as PropertyRead).name, expression);
      } else if (optionalCharacter($LPAREN)) {
        var args = parseCallArguments();
        expectCharacter($RPAREN);
        result = FunctionCall(result, args.positional, args.named);
      } else {
        return result;
      }
    }
  }

  AST parsePrimary() {
    if (optionalCharacter($LPAREN)) {
      var result = parsePipe();
      expectCharacter($RPAREN);
      return result;
    } else if (next.isKeywordNull || next.isKeywordUndefined) {
      advance();
      return LiteralPrimitive(null);
    } else if (next.isKeywordTrue) {
      advance();
      return LiteralPrimitive(true);
    } else if (next.isKeywordFalse) {
      advance();
      return LiteralPrimitive(false);
    } else if (optionalCharacter($LBRACKET)) {
      var elements = parseExpressionList($RBRACKET);
      expectCharacter($RBRACKET);
      return LiteralArray(elements);
    } else if (next.isCharacter($LBRACE)) {
      return parseLiteralMap();
    } else if (next.isIdentifier) {
      AST receiver = _implicitReceiver;
      if (exports != null) {
        var identifier = next.strValue;
        if (exports.containsKey(identifier)) {
          advance();
          return StaticRead(exports[identifier]);
        }
        if (prefixes.containsKey(identifier)) {
          if (peek(1).isCharacter($PERIOD)) {
            var nextId = peek(2);
            if (nextId.isIdentifier &&
                prefixes[identifier].containsKey(nextId.strValue)) {
              // consume the prefix, the '.', and the next identifier
              advance();
              advance();
              advance();
              return StaticRead(prefixes[identifier][nextId.strValue]);
            }
          }
        }
      }
      return parseAccessMemberOrMethodCall(receiver, false);
    } else if (next.isNumber) {
      var value = next.toNumber();
      advance();
      return LiteralPrimitive(value);
    } else if (next.isString) {
      var literalValue = next.toString();
      advance();
      return LiteralPrimitive(literalValue);
    } else if (index >= tokens.length) {
      error('Unexpected end of expression: $input');
    } else {
      error('Unexpected token $next');
    }
    // error() throws, so we don't reach here.
    throw StateError('Fell through all cases in parsePrimary');
  }

  List<AST> parseExpressionList(int terminator) {
    var result = <AST>[];
    if (!next.isCharacter(terminator)) {
      do {
        result.add(parsePipe());
      } while (optionalCharacter($COMMA));
    }
    return result;
  }

  LiteralMap parseLiteralMap() {
    var keys = <String>[];
    var values = <AST>[];
    expectCharacter($LBRACE);
    if (!optionalCharacter($RBRACE)) {
      do {
        var key = expectIdentifierOrKeywordOrString();
        keys.add(key);
        expectCharacter($COLON);
        values.add(parsePipe());
      } while (optionalCharacter($COMMA));
      expectCharacter($RBRACE);
    }
    return LiteralMap(keys, values);
  }

  AST parseAccessMemberOrMethodCall(AST receiver, [bool isSafe = false]) {
    var id = expectIdentifierOrKeyword();
    if (optionalCharacter($LPAREN)) {
      var args = parseCallArguments();
      expectCharacter($RPAREN);
      return isSafe
          ? SafeMethodCall(receiver, id, args.positional, args.named)
          : MethodCall(receiver, id, args.positional, args.named);
    } else {
      if (isSafe) {
        if (optionalOperator('=')) {
          error("The '?.' operator cannot be used in the assignment");
        } else {
          return SafePropertyRead(receiver, id);
        }
      } else {
        if (optionalOperator('=')) {
          if (!parseAction) {
            error('Bindings cannot contain assignments');
          }
          var value = parseConditional();
          return PropertyWrite(receiver, id, value);
        } else {
          return PropertyRead(receiver, id);
        }
      }
    }
    return null;
  }

  _CallArguments parseCallArguments() {
    if (next.isCharacter($RPAREN)) {
      return _CallArguments([], []);
    }
    final positional = <AST>[];
    final named = <NamedExpr>[];
    do {
      _parseCall = true;
      final ast = parsePipe();
      if (ast is NamedExpr) {
        named.add(ast);
      } else {
        positional.add(ast);
      }
    } while (optionalCharacter($COMMA));
    _parseCall = false;
    return _CallArguments(positional, named);
  }

  AST parseBlockContent() {
    if (!parseAction) {
      error('Binding expression cannot contain chained expression');
    }
    var exprs = <AST>[];
    while (index < tokens.length && !next.isCharacter($RBRACE)) {
      var expr = parseExpression();
      exprs.add(expr);
      if (optionalCharacter($SEMICOLON)) {
        while (optionalCharacter($SEMICOLON)) {}
      }
    }
    if (exprs.length == 0) return EmptyExpr();
    if (exprs.length == 1) return exprs[0];
    return Chain(exprs);
  }

  /// An identifier, a keyword, a string with an optional `-` inbetween.
  String expectTemplateBindingKey() {
    var result = '';
    var operatorFound = false;
    do {
      result += expectIdentifierOrKeywordOrString();
      operatorFound = optionalOperator('-');
      if (operatorFound) {
        result += '-';
      }
    } while (operatorFound);
    return result.toString();
  }

  TemplateBindingParseResult parseTemplateBindings() {
    List<TemplateBinding> bindings = [];
    String prefix;
    List<String> warnings = [];
    while (index < tokens.length) {
      bool keyIsVar = peekKeywordLet();
      if (!keyIsVar && peekDeprecatedKeywordVar()) {
        keyIsVar = true;
        warnings.add(
            '"var" inside of expressions is deprecated. Use "let" instead!');
      }
      if (!keyIsVar && peekDeprecatedOperatorHash()) {
        keyIsVar = true;
        warnings
            .add('"#" inside of expressions is deprecated. Use "let" instead!');
      }
      if (keyIsVar) {
        advance();
      }
      var key = expectTemplateBindingKey();
      if (!keyIsVar) {
        if (prefix == null) {
          prefix = key;
        } else {
          key = prefix + key[0].toUpperCase() + key.substring(1);
        }
      }
      optionalCharacter($COLON);
      String name;
      ASTWithSource expression;
      if (keyIsVar) {
        if (optionalOperator('=')) {
          name = expectTemplateBindingKey();
        }
      } else if (!identical(next, EOF) &&
          !peekKeywordLet() &&
          !peekDeprecatedKeywordVar() &&
          !peekDeprecatedOperatorHash()) {
        var start = inputIndex;
        var ast = parsePipe();
        var source = input.substring(start, inputIndex);
        expression = ASTWithSource(ast, source, location);
      }
      bindings.add(TemplateBinding(key, keyIsVar, name, expression));
      if (!optionalCharacter($SEMICOLON)) {
        optionalCharacter($COMMA);
      }
    }
    return TemplateBindingParseResult(bindings, warnings);
  }

  void error(String message, [int index]) {
    index ??= this.index;
    var location = (index < tokens.length)
        ? 'at column ${tokens[index].index + 1} in'
        : 'at the end of the expression';
    throw ParseException(message, input, location, this.location);
  }
}

class SimpleExpressionChecker implements AstVisitor {
  static bool check(AST ast) {
    var s = SimpleExpressionChecker();
    ast.visit(s);
    return s.simple;
  }

  var simple = true;
  @override
  void visitImplicitReceiver(ImplicitReceiver ast, dynamic context) {}
  @override
  void visitEmptyExpr(EmptyExpr ast, dynamic context) {}
  @override
  void visitStaticRead(StaticRead ast, dynamic context) {}
  @override
  void visitInterpolation(Interpolation ast, dynamic context) {
    simple = false;
  }

  @override
  void visitLiteralPrimitive(LiteralPrimitive ast, dynamic context) {}
  @override
  void visitPropertyRead(PropertyRead ast, dynamic context) {}
  @override
  void visitPropertyWrite(PropertyWrite ast, dynamic context) {
    simple = false;
  }

  @override
  void visitSafePropertyRead(SafePropertyRead ast, dynamic context) {
    simple = false;
  }

  @override
  void visitMethodCall(MethodCall ast, dynamic context) {
    simple = false;
  }

  @override
  void visitSafeMethodCall(SafeMethodCall ast, dynamic context) {
    simple = false;
  }

  @override
  void visitFunctionCall(FunctionCall ast, dynamic context) {
    simple = false;
  }

  @override
  void visitLiteralArray(LiteralArray ast, dynamic context) {
    _visitAll(ast.expressions);
  }

  @override
  void visitLiteralMap(LiteralMap ast, dynamic context) {
    _visitAll(ast.values);
  }

  @override
  void visitNamedExpr(NamedExpr ast, dynamic context) {
    ast.expression.visit(this);
  }

  @override
  void visitBinary(Binary ast, dynamic context) {
    simple = false;
  }

  @override
  void visitPrefixNot(PrefixNot ast, dynamic context) {
    simple = false;
  }

  @override
  void visitConditional(Conditional ast, dynamic context) {
    simple = false;
  }

  @override
  void visitIfNull(IfNull ast, dynamic context) {
    simple = false;
  }

  @override
  void visitPipe(BindingPipe ast, dynamic context) {
    simple = false;
  }

  @override
  void visitKeyedRead(KeyedRead ast, dynamic context) {
    simple = false;
  }

  @override
  void visitKeyedWrite(KeyedWrite ast, dynamic context) {
    simple = false;
  }

  @override
  void visitChain(Chain ast, dynamic context) {
    simple = false;
  }

  List<dynamic> _visitAll(List<dynamic> asts) {
    var res = List(asts.length);
    for (var i = 0; i < asts.length; ++i) {
      res[i] = asts[i].visit(this);
    }
    return res;
  }
}

class _CallArguments {
  List<AST> positional;
  List<NamedExpr> named;

  _CallArguments(this.positional, this.named);
}
