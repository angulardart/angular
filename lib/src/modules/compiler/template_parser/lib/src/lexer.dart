library angular2_template_parser.src.lexer;

import 'dart:async';

import 'package:charcode/charcode.dart';
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';
import 'package:source_span/source_span.dart';
import 'package:string_scanner/string_scanner.dart';

import 'utils.dart';

part 'lexer/sync_lexer.dart';

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

/// A recognized token while scanning a template.
class NgToken {
  /// What text was scanned.
  final SourceSpan source;

  /// Token text.
  final String text;

  /// What type of token.
  final NgTokenType type;

  /// Creates a new [NgToken] from a [type] and [text].
  NgToken(this.type, this.text) : source = null;

  /// Creates a new [NgToken] of [type] from [source].
  NgToken.fromSource(this.type, SourceSpan source)
      : this.text = source.text,
        this.source = source;

  @override
  bool operator ==(Object o) {
    if (o is NgToken) {
      return type == o.type && text == o.text;
    }
    return false;
  }

  @override
  int get hashCode => hash2(source, type);

  @override
  String toString() => '{$type: $text}';
}

/// Type of [NgToken].
enum NgTokenType {
  /// Parsed text.
  textNode,

  /// <!-- before comment
  beginComment,

  /// Parsed comment.
  commentNode,

  /// --> after comment
  endComment,

  /// Parsed interpolated expression.
  interplateNode,

  /// Before parsing the [elementName].
  startOpenElement,

  /// After parsing the [elementName].
  endOpenElement,

  /// After parsing an [endOpenElement] that does not have content.
  endVoidElement,

  /// Parsed element name.
  elementName,

  /// After parsing an element tag and child nodes.
  startCloseElement,

  /// After parsing an element.
  endCloseElement,

  /// Before the start of an attribute, event, or property (i.e. whitespace).
  beforeElementDecorator,

  /// Before parsing a decorator value.
  beforeDecoratorValue,

  /// Parsed attribute name.
  attributeName,

  /// Parsed attribute value.
  attributeValue,

  /// After parsing an [attributeName], and optionally, [attributeValue].
  endAttribute,

  /// Before parsing a [propertyName].
  startProperty,

  /// Parsed property name.
  propertyName,

  /// Parsed property value.
  propertyValue,

  /// After parsing a [propertyName], and optionally, [propertyValue].
  endProperty,

  /// Before parsing an [eventName].
  startEvent,

  /// Parsed event name.
  eventName,

  /// Parsed event value.
  eventValue,

  /// After parsing an [eventName] and [eventValue].
  endEvent,

  /// Before parsing a binding.
  startBinding,

  /// Binding name.
  bindingName,

  /// Before parsing a banana (in a box).
  startBanana,

  /// The name of the banana (in a box).
  bananaName,

  /// The banana value.
  bananaValue,

  /// After parsing a [bananaName] and [bananaValue].
  endBanana,

  /// An unexpected or invalid token.
  ///
  /// In a stricter mode, this should cause the parsing to fail. It can also be
  /// ignored in order to attempt to produce valid output - for example a user
  /// may want to still validate the rest of the (seemingly valid) template
  /// even if there is an error somewhere at the beginning.
  errorToken,
}

/// Simple interface for using an [NgTemplateLexer] to parse nodes.
abstract class NgTemplateScanner<T> {
  final List<T> _stack = <T>[];

  Iterator<NgToken> _iterator;
  bool _canAcceptChildren = true;

  /// Whether child nodes (not decorators) can be added.
  bool get canAcceptChildren => _canAcceptChildren;

  /// Peeks at the top of the stack.
  T peek() => _stack.last;

  /// Pops the top of the stack.
  T pop() => _stack.removeLast();

  /// Push an item to the top of the stack.
  void push(T node) {
    _stack.add(node);
  }

  /// Returns the next token.
  NgToken next() => (_iterator..moveNext()).current;

  /// Scans from [lexer].
  List<T> scan(NgTemplateLexer lexer) {
    _iterator = lexer.tokenize().iterator;
    scanToken(next());
    return result();
  }

  /// Scans a [token].
  void scanToken(NgToken token) {
    switch (token.type) {
      case NgTokenType.textNode:
        scanText(token);
        break;
      case NgTokenType.startOpenElement:
        scanOpenElement(token);
        _canAcceptChildren = false;
        break;
      case NgTokenType.startCloseElement:
        scanCloseElement(token);
        break;
      case NgTokenType.beginComment:
        scanComment(token);
        break;
      case NgTokenType.beforeElementDecorator:
        var attribute = next();
        if (attribute.type == NgTokenType.attributeName) {
          scanAttribute(token, attribute);
        }
        var after = next();
        if (after.type == NgTokenType.endOpenElement) {
          _canAcceptChildren = true;
        } else {
          scanToken(after);
        }
        break;
      default:
        throw new UnsupportedError('${token.source.message(token.type.toString())}');
    }
    var after = next();
    if (after != null) {
      scanToken(after);
    }
  }

  /// Returns the scanned result.
  List<T> result();

  /// Called when ...
  void scanAttribute(NgToken before, NgToken actual);

  /// Called when [NgTokenType.beginComment] is scanned.
  void scanComment(NgToken token);

  /// Called when [NgTokenType.startOpenElement] is scanned.
  ///
  /// Expected to return the `<tag>` being opened.
  void scanOpenElement(NgToken token);

  /// Called when [NgTokenType.startCloseElement]
  void scanCloseElement(NgToken token);

  /// Called when [NgTokenType.textNode] is scanned.
  ///
  /// Returns a [Future] that completes after processing.
  void scanText(NgToken token);
}
