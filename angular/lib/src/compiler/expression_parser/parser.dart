import 'package:angular_compiler/cli.dart';

import '../../compiler/compile_metadata.dart';
import '../../facade/lang.dart' show jsSplit;
import 'ast.dart'
    show
        AST,
        ASTWithSource,
        Binary,
        BindingPipe,
        Conditional,
        EmptyExpr,
        FunctionCall,
        IfNull,
        ImplicitReceiver,
        Interpolation,
        KeyedRead,
        KeyedWrite,
        LiteralArray,
        LiteralPrimitive,
        MethodCall,
        NamedExpr,
        PrefixNot,
        PropertyRead,
        PropertyWrite,
        SafeMethodCall,
        SafePropertyRead,
        StaticRead;
import 'lexer.dart'
    show
        LexerError,
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
        $LPAREN,
        $RPAREN,
        $SLASH;

final _implicitReceiver = ImplicitReceiver();
final _pipeOperator = PropertyRead(_implicitReceiver, r'$pipe');
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

class Parser {
  final Lexer _lexer;
  final bool supportNewPipeSyntax;

  Parser(this._lexer, {this.supportNewPipeSyntax = false});

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
    var tokens = _tokenizeOrThrow(this._stripComments(input), input, location);
    var ast = _ParseAST(
      input,
      location,
      tokens,
      true,
      exports,
      supportNewPipeSyntax,
    ).parse();
    return ASTWithSource(ast, input, location);
  }

  ASTWithSource parseBinding(
      String input, String location, List<CompileIdentifierMetadata> exports) {
    var ast = _parseBindingAst(input, location, exports);
    return ASTWithSource(ast, input, location);
  }

  List<Token> _tokenizeOrThrow(String text, String input, String location) {
    try {
      return _lexer.tokenize(text);
    } on LexerError catch (e) {
      throw ParseException(e.messageWithPosition, input, '', location);
    }
  }

  AST _parseBindingAst(
      String input, String location, List<CompileIdentifierMetadata> exports) {
    this._checkNoInterpolation(input, location);
    var tokens = _tokenizeOrThrow(this._stripComments(input), input, location);
    return _ParseAST(
      input,
      location,
      tokens,
      false,
      exports,
      supportNewPipeSyntax,
    ).parse();
  }

  ASTWithSource parseInterpolation(
      String input, String location, List<CompileIdentifierMetadata> exports) {
    var split = _splitInterpolation(input, location);
    if (split == null) return null;
    var expressions = <AST>[];
    for (var i = 0; i < split.expressions.length; ++i) {
      var tokens = _tokenizeOrThrow(
          _stripComments(split.expressions[i]), input, location);
      var ast = _ParseAST(
        input,
        location,
        tokens,
        false,
        exports,
        supportNewPipeSyntax,
      ).parse();
      expressions.add(ast);
    }
    return ASTWithSource(
        Interpolation(split.strings, expressions), input, location);
  }

  SplitInterpolation _splitInterpolation(String input, String location) {
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
      } else if (part.trim().isNotEmpty) {
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
      if (identical(char, $SLASH) && nextChar == $SLASH && outerQuote == null) {
        return i;
      }
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
  final bool supportNewPipeSyntax;

  Map<String, CompileIdentifierMetadata> exports;
  Map<String, Map<String, CompileIdentifierMetadata>> prefixes;
  int index = 0;
  bool _parseCall = false;

  _ParseAST(
    this.input,
    this.location,
    this.tokens,
    this.parseAction,
    List<CompileIdentifierMetadata> exports,
    this.supportNewPipeSyntax,
  ) {
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

  AST parse() {
    if (tokens.isEmpty) {
      return EmptyExpr();
    }
    final expr = parsePipe();
    if (optionalCharacter($SEMICOLON)) {
      if (parseAction) {
        error('Event bindings no longer support multiple statements');
      } else {
        error('Expression binding cannot contain multiple statements');
      }
    }
    if (index < tokens.length) {
      error("Unexpected token '$next'");
    }
    return expr;
  }

  AST parsePipe() {
    var result = parseExpression();
    if (optionalOperator('|')) {
      if (parseAction) {
        error('Cannot have a pipe in an action expression');
      }
      do {
        var name = expectIdentifierOrKeyword();
        var args = <AST>[];
        var prevParseCall = _parseCall;
        _parseCall = false;
        while (optionalCharacter($COLON)) {
          args.add(parseExpression());
        }
        _parseCall = prevParseCall;
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
        if (result is PropertyRead) {
          result = NamedExpr((result as PropertyRead).name, expression);
        } else if (result is StaticRead && result.id.prefix == null) {
          result = NamedExpr((result as StaticRead).id.name, expression);
        } else {
          error('Expected previous token to be an identifier');
        }
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
      throwForLiteralMap();
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

  // Despite no longer being supported, we want an actionable error message.
  void throwForLiteralMap() {
    throw ParseException(
      'UNSUPPORTED: Map literals are no longer supported in the template.\n'
      'Move code that constructs or maintains Map instances inside of your '
      '@Component-annotated Dart class, or prefer syntax such as '
      '[class.active]="isActive" over [ngClass]="{\'active\': isActive}".',
      input,
      location,
    );
  }

  AST parseAccessMemberOrMethodCall(AST receiver, [bool isSafe = false]) {
    var id = expectIdentifierOrKeyword();
    if (supportNewPipeSyntax &&
        id == r'$pipe' &&
        receiver == _implicitReceiver) {
      return _parsePipeNewSyntax();
    }
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

  AST _parsePipeNewSyntax() {
    expectCharacter($PERIOD);
    final pipeCall = parseAccessMemberOrMethodCall(_pipeOperator);
    if (pipeCall is MethodCall) {
      final name = pipeCall.name;
      if (pipeCall.namedArgs.isNotEmpty) {
        error('Pipes may only contain positional, not named, arguments');
        return null;
      }
      if (pipeCall.args.isEmpty) {
        error('Pipes must contain at least one positional argument');
        return null;
      }
      return BindingPipe(pipeCall.args.first, name, pipeCall.args.sublist(1));
    } else {
      error(r'Pipes must be defined as "$pipe.nameOfPipe(target, argsIfany)');
      return null;
    }
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

  void error(String message, [int index]) {
    index ??= this.index;
    var location = (index < tokens.length)
        ? 'at column ${tokens[index].index + 1} in'
        : 'at the end of the expression';
    throw ParseException(message, input, location, this.location);
  }
}

class _CallArguments {
  List<AST> positional;
  List<NamedExpr> named;

  _CallArguments(this.positional, this.named);
}
