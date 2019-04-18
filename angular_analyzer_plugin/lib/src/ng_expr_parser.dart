import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';

/// Override the old analyzer parser and give it pipe support.
///
/// This should not exist, as the old parser is no longer being maintained.
/// However, we cannot use the core angular expression parser because it does
/// not generate the Dart AST, and it does not have error recovery for auto
/// completion.
///
/// In practice, the fact that it is not maintained has not been a problem,
/// because new syntax added to Dart is not available in the angular parser
/// anyway. However, it is not immune to bit-rot, and a longer-term solution
/// here that uses the CFE fasta parser will eventually be required.
class NgExprParser extends Parser {
  NgExprParser(Source source, AnalysisErrorListener errorListener)
      : super.withoutFasta(source, errorListener);

  /// Override the bitwise or operator to parse pipes instead
  @override
  Expression parseBitwiseOrExpression() => parsePipeExpression();

  /// Parse pipe expression.
  ///
  /// We cannot safely extend the dart AST to add a PipeExpression class because
  /// the visitor pattern is a closed design. Instead, return the result as a
  /// cast expression `as dynamic` with _ng_pipeXXX properties to be resolved
  /// specially later.
  ///
  ///     bitwiseOrExpression ::=
  ///         bitwiseXorExpression ('|' pipeName [: arg]*)*
  Expression parsePipeExpression() {
    Token beforePipeToken;
    var expression = parseBitwiseXorExpression();
    while (currentToken.type == TokenType.BAR) {
      beforePipeToken ??= currentToken.previous;
      getAndAdvance();
      final pipeEntities = parsePipeExpressionEntities();
      final asToken = KeywordToken(Keyword.AS, 0);
      final dynamicIdToken = SyntheticStringToken(TokenType.IDENTIFIER,
          "dynamic", currentToken.offset - "dynamic".length);

      beforePipeToken.setNext(asToken);
      asToken.setNext(dynamicIdToken);
      dynamicIdToken.setNext(currentToken);

      final dynamicIdentifier = astFactory.simpleIdentifier(dynamicIdToken);

      // TODO(mfairhurst) Now that we are resolving pipes, probably should store
      // the result in a different expression type -- a function call, most
      // likely. This will be required so that the pipeArgs become part of the
      // tree, but it may create secondary fallout inside the analyzer
      // resolution code if done wrong.
      expression = astFactory.asExpression(
          expression, asToken, astFactory.typeName(dynamicIdentifier, null))
        ..setProperty('_ng_pipeName', pipeEntities.name)
        ..setProperty('_ng_pipeArgs', pipeEntities.arguments);
    }
    return expression;
  }

  /// Parse a bitwise or expression to be treated as a pipe.
  ///
  /// Return the resolved left-hand expression as a dynamic type.
  ///
  ///     pipeExpression ::= identifier[':' expression]*
  _PipeEntities parsePipeExpressionEntities() {
    final identifier = parseSimpleIdentifier();
    final expressions = <Expression>[];
    while (currentToken.type == TokenType.COLON) {
      getAndAdvance();
      expressions.add(parseExpression2());
    }

    return _PipeEntities(identifier, expressions);
  }
}

class _PipeEntities {
  final SimpleIdentifier name;
  final List<Expression> arguments;

  _PipeEntities(this.name, this.arguments);
}
