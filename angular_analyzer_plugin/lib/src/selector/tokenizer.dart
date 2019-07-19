import 'package:angular_analyzer_plugin/src/selector/parse_error.dart';
import 'package:angular_analyzer_plugin/src/selector/regex.dart' as regex;

/// A token from tokenizing CSS via regex.
class Token {
  final TokenType type;
  final String lexeme;
  final int offset;
  final int endOffset;
  Token(this.type, this.lexeme, this.offset, this.endOffset);
}

/// A regex-based tokenizer for CSS.
///
/// To tokenize, merely construct this tokenizer and call [advance] to get new
/// [Token]s. The last token is available via [current].
///
/// Due to the way CSS and regex works, a few special tokens require their own
/// methods: these are [currentContainsString], [currentOperator], and
/// [currentValue]. These are essentially subtokens of "contains" and attribute
/// tokens.
class Tokenizer with ReportParseErrors {
  /// The current regex [Match] from the [_matches] iterator.
  Match _currentMatch;

  /// The iterator of regex matches against the selector [str].
  final Iterator<Match> _matches;

  /// The end offset of the last token from the [str].
  int lastOffset = 0;

  /// The offset of [str] in the file, for error reporting.
  final int fileOffset;

  /// The selector itself, for error reporting.
  @override
  final String str;

  /// The latest token produced by calling [advance].
  Token current;

  Tokenizer(this.str, this.fileOffset)
      : _matches = regex.tokenizer.allMatches(str).iterator {
    advance();
  }

  /// Get "foo" in ":contains(foo)" as a token when [current] is a [Contains].
  ///
  /// This token is special and does not get offset info.
  Token get currentContainsString {
    assert(current.type == TokenType.Contains);
    final lexeme = _currentMatch[regex.subTokenContainsStr];
    if (lexeme == null) {
      return null;
    }
    return Token(TokenType.ContainsString, lexeme, null, null);
  }

  /// Get "=" in "a=x" as a token when [current] is an [Attribute].
  ///
  /// This token is special and does not get offset info.
  Token get currentOperator {
    assert(current.type == TokenType.Attribute);
    final lexeme = _currentMatch[regex.subTokenOperator];
    if (lexeme == null) {
      return null;
    }
    return Token(TokenType.Operator, lexeme, null, null);
  }

  /// Get "x" in "a=x" as a token when [current] is an [Attribute].
  ///
  /// This token is special and does not get offset info.
  Token get currentValue {
    assert(current.type == TokenType.Attribute);
    final lexeme = _currentMatch[regex.subTokenUnquotedValue] ??
        _currentMatch[regex.subTokenDoubleQuotedValue] ??
        _currentMatch[regex.subTokenSingleQuotedValue];
    if (lexeme == null) {
      return null;
    }
    return Token(TokenType.Value, lexeme, null, null);
  }

  //Try to pull another token off the stream, and report tokenization errors.
  Token advance() {
    if (!_matches.moveNext()) {
      _currentMatch = null;
      current = null;
      return null;
    }

    _currentMatch = _matches.current;

    // no content should be skipped
    final skipStr = str.substring(lastOffset, _currentMatch.start);
    if (!_isBlank(skipStr)) {
      unexpected(skipStr, lastOffset + fileOffset);
    }
    lastOffset = _currentMatch.end;

    for (final index in regex.matchIndexToToken.keys) {
      if (_currentMatch[index] != null) {
        return current = Token(
            regex.matchIndexToToken[index],
            _currentMatch[index],
            fileOffset + _currentMatch.start,
            fileOffset + _currentMatch.end);
      }
    }

    return current = null;
  }

  /// Checks if [str] is `null`, empty or is whitespace.
  bool _isBlank(String str) => (str ?? '').trim().isEmpty;
}

/// Various types of tokens that may be tokenized.
enum TokenType {
  NotStart, // :not(
  NotEnd, // )
  Attribute, // x=y
  Tag, // tag-name
  Comma, // ,
  Class, // .class
  Contains, // :contains(...)
  ContainsString, // :contains(string)
  Value, // x=value
  Operator, // =, ^=, etc.
}
