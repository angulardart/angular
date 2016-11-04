library angular2_template_parser.src.lexer;

import 'package:charcode/charcode.dart';
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';
import 'package:source_span/source_span.dart';
import 'package:string_scanner/string_scanner.dart';

import 'utils.dart';

part 'lexer/sync_lexer.dart';
part 'lexer/template_scanner.dart';
part 'lexer/token.dart';
part 'lexer/token_type.dart';

/// A tokenizer for the Angular Dart template language.
abstract class NgTemplateLexer {
  /// Constructs a lexer which tokenizes the contents of [input].
  factory NgTemplateLexer(String input, {/* String | Uri*/ sourceUrl}) {
    final scanner = new SpanScanner(input, sourceUrl: sourceUrl);
    return new _SyncNgTemplateLexer(scanner);
  }

  /// Whether one or more [NgTokenType.errorToken]s were produced scanning.
  ///
  /// The Lexer may attempt to recover from errors, but clients should not
  /// rely on the results of scanning if this flag is set.
  bool get hasErrors;

  /// Constructs and returns a series of scanned tokens frm the input source.
  ///
  /// Any errors during lexing are represented as [NgTokenType.errorToken]s.
  Iterable<NgToken> tokenize();
}

/// A partial implementation of [NgTemplateLexer] with convenience functions.
abstract class NgTemplateLexerBase implements NgTemplateLexer {
  final SpanScanner _scanner;

  // Last significant state. Used in computing a large span.
  LineScannerState _sentinel;

  // Represents an executing [tokenize] call.
  final List<NgToken> _tokenizer = <NgToken>[];

  NgTemplateLexerBase(this._scanner) {
    _sentinel = _scanner.state;
  }

  bool _hasErrors = false;

  /// Triggers an error [message].
  @protected
  void addError(String message, [int offset]) {
    throw new FormatException(
      message,
      _scanner.string,
      offset ?? _scanner.position,
    );
    // _hasErrors = true;
  }

  /// Adds a token [type] with [source] scanned.
  @protected
  void addToken(NgTokenType type, [FileSpan source]) {
    source ??= span();
    _tokenizer.add(new NgToken.fromSource(type, source));
  }

  /// Moves ahead a space and returns the current character.
  int advance() => _scanner.readChar();

  /// Called after [tokenize] is initiated.
  @protected
  void doTokenize();

  /// Returns a [FileSpan] representing the current pointer of the scanner.
  FileSpan point() => _scanner.location.pointSpan();

  @override
  bool get hasErrors => _hasErrors;

  /// Whether additional input is remaining.
  bool get hasNext => !_scanner.isDone;

  /// Moves the scanner back n positions.
  void backTrack(int n) {
    _scanner.position -= n;
  }

  /// Returns the next character without advancing the position.
  int peek() => _scanner.peekChar();

  /// Advances and returns `true` if the next character matches [c].
  bool scan(int c) => _scanner.scanChar(c);

  /// Returns a [FileSpan] from the last invocation to the current position.
  ///
  /// Resets the sentinel value to the current position.
  FileSpan span() {
    final span = _scanner.spanFrom(_sentinel);
    _sentinel = _scanner.state;
    return span;
  }

  @override
  Iterable<NgToken> tokenize() {
    _scanner.position = 0;
    doTokenize();
    return _tokenizer;
  }
}
