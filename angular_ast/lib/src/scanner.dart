import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';
import 'package:string_scanner/string_scanner.dart';

import 'exception_handler/exception_handler.dart';
import 'parser/reader.dart';
import 'recovery_protocol/recovery_protocol.dart';
import 'simple_tokenizer.dart';
import 'token/tokens.dart';

/// A wrapper around [StringScanner] that scans tokens from an HTML string.
class NgScanner {
  final NgTokenReversibleReader<Object> _reader;
  NgScannerState _state = NgScannerState.scanStart;
  final ExceptionHandler exceptionHandler;

  final bool _recoverErrors;
  final RecoveryProtocol _rp = NgAnalyzerRecoveryProtocol();

  NgSimpleToken? _current;
  NgSimpleToken? _lastToken;
  NgSimpleToken? _lastErrorToken;

  // Storing last notable offsets to better generate exception offsets.
  // Due to the linear parsing nature of Angular, these values are recyclable.
  late int _lastElementStartOffset;
  NgSimpleToken? _lastDecoratorPrefix;
  int? _lastOpenMustacheOffset;
  late int _lastCommentStartOffset;
  late int _lastEqualSignOffset;

  NgSimpleToken? _moveNext() {
    _lastToken = _current;
    _current = _reader.next() as NgSimpleToken;
    return _current;
  }

  factory NgScanner(
    String html,
    ExceptionHandler exceptionHandler, {
    Uri? sourceUrl,
  }) {
    var reader = NgTokenReversibleReader<NgSimpleTokenType>(
        SourceFile.fromString(html, url: sourceUrl),
        const NgSimpleTokenizer().tokenize(html));
    var recoverError = exceptionHandler is RecoveringExceptionHandler;

    return NgScanner._(reader, recoverError, exceptionHandler);
  }

  NgScanner._(this._reader, this._recoverErrors, this.exceptionHandler);

  /// Scans and returns the next token, or `null` if there is none more.
  NgToken? scan() {
    _moveNext();
    NgToken? returnToken;

    while (returnToken == null) {
      switch (_state) {
        case NgScannerState.hasError:
          throw StateError('An error occurred');
        case NgScannerState.isEndOfFile:
          return null;
        case NgScannerState.scanAfterComment:
          returnToken = scanAfterComment();
          break;
        case NgScannerState.scanAfterElementDecorator:
          returnToken = scanAfterElementDecorator();
          _lastDecoratorPrefix = null;
          break;
        case NgScannerState.scanAfterElementDecoratorValue:
          returnToken = scanAfterElementDecoratorValue();
          break;
        case NgScannerState.scanAfterElementIdentifierClose:
          returnToken = scanAfterElementIdentifierClose();
          break;
        case NgScannerState.scanAfterElementIdentifierOpen:
          returnToken = scanAfterElementIdentifierOpen();
          break;
        case NgScannerState.scanAfterInterpolation:
          returnToken = scanAfterInterpolation();
          _lastOpenMustacheOffset = null;
          break;
        case NgScannerState.scanBeforeElementDecorator:
          returnToken = scanBeforeElementDecorator();
          break;
        case NgScannerState.scanBeforeInterpolation:
          returnToken = scanBeforeInterpolation();
          break;
        case NgScannerState.scanElementEndClose:
          returnToken = scanElementEndClose();
          break;
        case NgScannerState.scanElementEndOpen:
          returnToken = scanElementEndOpen();
          break;
        case NgScannerState.scanComment:
          returnToken = scanComment();
          break;
        case NgScannerState.scanElementDecorator:
          returnToken = scanElementDecorator();
          break;
        case NgScannerState.scanElementDecoratorValue:
          returnToken = scanElementDecoratorValue();
          break;
        case NgScannerState.scanElementIdentifierClose:
          returnToken = scanElementIdentifier(wasOpenTag: false);
          break;
        case NgScannerState.scanElementIdentifierOpen:
          returnToken = scanElementIdentifier(wasOpenTag: true);
          break;
        case NgScannerState.scanElementStart:
          returnToken = scanElementStart();
          break;
        case NgScannerState.scanInterpolation:
          returnToken = scanInterpolation();
          break;
        case NgScannerState.scanSimpleElementDecorator:
          returnToken = scanSimpleElementDecorator();
          break;
        case NgScannerState.scanSpecialAnnotationDecorator:
          returnToken = scanSpecialAnnotationDecorator();
          break;
        case NgScannerState.scanSpecialBananaDecorator:
          returnToken = scanSpecialBananaDecorator();
          break;
        case NgScannerState.scanSpecialEventDecorator:
          returnToken = scanSpecialEventDecorator();
          break;
        case NgScannerState.scanSpecialPropertyDecorator:
          returnToken = scanSpecialPropertyDecorator();
          break;
        case NgScannerState.scanSuffixBanana:
          returnToken = scanSuffixBanana();
          break;
        case NgScannerState.scanSuffixEvent:
          returnToken = scanSuffixEvent();
          break;
        case NgScannerState.scanSuffixProperty:
          returnToken = scanSuffixProperty();
          break;
        case NgScannerState.scanStart:
          var type = _current!.type;
          if (type == NgSimpleTokenType.EOF && _reader.isDone) {
            _state = NgScannerState.isEndOfFile;
            return null;
          } else if (type == NgSimpleTokenType.openTagStart ||
              type == NgSimpleTokenType.closeTagStart) {
            returnToken = scanElementStart();
          } else if (type == NgSimpleTokenType.commentBegin) {
            returnToken = scanBeforeComment();
          } else if (type == NgSimpleTokenType.mustacheBegin ||
              type == NgSimpleTokenType.mustacheEnd) {
            // If [NgSimpleTokenType.mustacheEnd], then error - but let
            // scanBeforeInterpolation handle it.
            _state = NgScannerState.scanBeforeInterpolation;
            return scanBeforeInterpolation();
          } else {
            returnToken = scanText();
          }
          break;
        case NgScannerState.scanText:
          returnToken = scanText();
          break;
      }
    }
    return returnToken;
  }

  @protected
  NgToken? scanAfterComment() {
    var current = _current!;
    if (current.type == NgSimpleTokenType.commentEnd) {
      _state = NgScannerState.scanStart;
      return NgToken.commentEnd(current.offset);
    }
    // Only triggered by EOF.
    return handleError(
      ParserErrorCode.UNTERMINATED_COMMENT,
      _lastCommentStartOffset,
      current.offset - _lastCommentStartOffset,
    );
  }

  // TODO: Max: Better handle cases like 'prop]'. Instead of
  // TODO: 'prop []' resolve, resolve as '[prop].
  @protected
  NgToken? scanAfterElementDecorator() {
    var current = _current!;
    var type = current.type;

    if (type == NgSimpleTokenType.equalSign) {
      _state = NgScannerState.scanElementDecoratorValue;
      _lastEqualSignOffset = current.offset;
      return NgToken.beforeElementDecoratorValue(current.offset);
    } else if (type == NgSimpleTokenType.tagEnd ||
        type == NgSimpleTokenType.voidCloseTag) {
      return scanElementEndOpen();
    } else if (type == NgSimpleTokenType.whitespace) {
      var nextType = _reader.peekType();
      // Trailing whitespace check.
      if (nextType == NgSimpleTokenType.equalSign ||
          nextType == NgSimpleTokenType.voidCloseTag ||
          nextType == NgSimpleTokenType.tagEnd) {
        return NgToken.whitespace(current.offset, current.lexeme);
      }
      return scanBeforeElementDecorator();
    }

    if (type == NgSimpleTokenType.openBracket ||
        type == NgSimpleTokenType.openParen ||
        type == NgSimpleTokenType.openBanana ||
        type == NgSimpleTokenType.hash ||
        type == NgSimpleTokenType.star ||
        type == NgSimpleTokenType.atSign ||
        type == NgSimpleTokenType.closeBracket ||
        type == NgSimpleTokenType.closeParen ||
        type == NgSimpleTokenType.closeBanana ||
        type == NgSimpleTokenType.identifier) {
      return handleError(
        ParserErrorCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR,
        current.offset,
        current.length,
      );
    }

    if (type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart) {
      var lastToken = _lastToken!;
      return handleError(
        ParserErrorCode.EXPECTED_TAG_CLOSE,
        lastToken.offset,
        lastToken.length,
      );
    }

    if (type == NgSimpleTokenType.doubleQuote ||
        type == NgSimpleTokenType.singleQuote) {
      var lastToken = _lastToken!;
      return handleError(
        ParserErrorCode.EXPECTED_EQUAL_SIGN,
        lastToken.offset,
        current.end - lastToken.offset,
      );
    }

    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanAfterElementDecoratorValue() {
    var current = _current!;
    var type = current.type;

    if (type == NgSimpleTokenType.tagEnd ||
        type == NgSimpleTokenType.voidCloseTag) {
      return scanElementEndOpen();
    } else if (type == NgSimpleTokenType.whitespace) {
      var nextType = _reader.peekType();
      if (nextType == NgSimpleTokenType.voidCloseTag ||
          nextType == NgSimpleTokenType.tagEnd) {
        return NgToken.whitespace(current.offset, current.lexeme);
      }
      return scanBeforeElementDecorator();
    }

    if (type == NgSimpleTokenType.openBracket ||
        type == NgSimpleTokenType.openParen ||
        type == NgSimpleTokenType.openBanana ||
        type == NgSimpleTokenType.hash ||
        type == NgSimpleTokenType.star ||
        type == NgSimpleTokenType.atSign ||
        type == NgSimpleTokenType.identifier ||
        type == NgSimpleTokenType.closeBracket ||
        type == NgSimpleTokenType.closeParen ||
        type == NgSimpleTokenType.closeBanana ||
        type == NgSimpleTokenType.equalSign ||
        type == NgSimpleTokenType.doubleQuote ||
        type == NgSimpleTokenType.singleQuote) {
      var lastToken = _lastToken!;
      return handleError(
        ParserErrorCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR,
        lastToken.offset,
        lastToken.length,
      );
    }

    if (type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart) {
      var lastToken = _lastToken!;
      return handleError(
        ParserErrorCode.EXPECTED_TAG_CLOSE,
        lastToken.offset,
        lastToken.length,
      );
    }

    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanAfterElementIdentifierClose() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.whitespace) {
      _state = NgScannerState.scanElementEndClose;
      return NgToken.whitespace(current.offset, current.lexeme);
    }
    if (type == NgSimpleTokenType.tagEnd) {
      _state = NgScannerState.scanStart;
      return scanElementEndClose();
    }

    if (type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF) {
      var lastToken = _lastToken!;
      return handleError(
        ParserErrorCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER,
        lastToken.offset,
        lastToken.length,
      );
    }

    if (type == NgSimpleTokenType.voidCloseTag) {
      return handleError(
        ParserErrorCode.VOID_CLOSE_IN_CLOSE_TAG,
        current.offset,
        current.length,
      );
    }
    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanAfterElementIdentifierOpen() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.whitespace) {
      var peeked = _reader.peek()!;
      if (peeked.type == NgSimpleTokenType.voidCloseTag ||
          peeked.type == NgSimpleTokenType.tagEnd) {
        _state = NgScannerState.scanElementEndOpen;
        return NgToken.whitespace(current.offset, current.lexeme);
      }
      _state = NgScannerState.scanElementDecorator;
      return scanBeforeElementDecorator();
    }
    if (type == NgSimpleTokenType.voidCloseTag ||
        type == NgSimpleTokenType.tagEnd) {
      return scanElementEndOpen();
    }

    if (type == NgSimpleTokenType.openBracket ||
        type == NgSimpleTokenType.openParen ||
        type == NgSimpleTokenType.openBanana ||
        type == NgSimpleTokenType.hash ||
        type == NgSimpleTokenType.star ||
        type == NgSimpleTokenType.atSign ||
        type == NgSimpleTokenType.equalSign ||
        type == NgSimpleTokenType.closeBracket ||
        type == NgSimpleTokenType.closeParen ||
        type == NgSimpleTokenType.closeBanana ||
        type == NgSimpleTokenType.doubleQuote ||
        type == NgSimpleTokenType.singleQuote) {
      var lastToken = _lastToken!;
      return handleError(
        ParserErrorCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR,
        lastToken.offset,
        lastToken.length,
      );
    }

    if (type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF) {
      var lastToken = _lastToken!;
      return handleError(
        ParserErrorCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER,
        lastToken.offset,
        lastToken.length,
      );
    }

    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanAfterInterpolation() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.mustacheEnd) {
      _state = NgScannerState.scanStart;
      return NgToken.interpolationEnd(current.offset);
    }

    if (type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.mustacheBegin ||
        type == NgSimpleTokenType.whitespace) {
      return handleError(
        ParserErrorCode.UNTERMINATED_MUSTACHE,
        _lastOpenMustacheOffset,
        '{{'.length,
      );
    }
    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanBeforeComment() {
    var current = _current!;
    if (current.type == NgSimpleTokenType.commentBegin) {
      _state = NgScannerState.scanComment;
      _lastCommentStartOffset = current.offset;
      return NgToken.commentStart(current.offset);
    }
    // Transient state, should theoretically never hit.
    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanBeforeElementDecorator() {
    var current = _current!;
    if (current.type == NgSimpleTokenType.whitespace) {
      if (_reader.peekType() == NgSimpleTokenType.voidCloseTag ||
          _reader.peekType() == NgSimpleTokenType.tagEnd) {
        _state = NgScannerState.scanAfterElementDecorator;
        return NgToken.whitespace(current.offset, current.lexeme);
      }
      _state = NgScannerState.scanElementDecorator;
      return NgToken.beforeElementDecorator(current.offset, current.lexeme);
    }
    // Transient state, should theoretically never hit.
    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanBeforeInterpolation() {
    var current = _current!;
    if (current.type == NgSimpleTokenType.mustacheBegin) {
      _state = NgScannerState.scanInterpolation;
      _lastOpenMustacheOffset = current.offset;
      return NgToken.interpolationStart(current.offset);
    }

    var errorToken = current;
    if (current.type == NgSimpleTokenType.text &&
        _reader.peekType() == NgSimpleTokenType.mustacheEnd) {
      errorToken = _reader.peek() as NgSimpleToken;
    }
    return handleError(
      ParserErrorCode.UNOPENED_MUSTACHE,
      errorToken.offset,
      errorToken.length,
    );
  }

  @protected
  NgToken? scanComment() {
    var current = _current!;
    if (current.type == NgSimpleTokenType.text) {
      _state = NgScannerState.scanAfterComment;
      return NgToken.commentValue(current.offset, current.lexeme);
    }
    if (current.type == NgSimpleTokenType.commentEnd) {
      _state = NgScannerState.scanAfterComment;
      return scanAfterComment();
    }
    // Only EOF should enable error.
    return handleError(
      ParserErrorCode.UNTERMINATED_COMMENT,
      _lastCommentStartOffset,
      '<!--'.length,
    );
  }

  // Doesn't switch states or check validity of current token.
  NgToken _scanCompoundDecorator() {
    var current = _current!;
    var offset = current.offset;
    var sb = StringBuffer();
    sb.write(current.lexeme);
    while (_reader.peekType() == NgSimpleTokenType.period ||
        _reader.peekType() == NgSimpleTokenType.identifier ||
        _reader.peekType() == NgSimpleTokenType.dash ||
        _reader.peekType() == NgSimpleTokenType.percent ||
        _reader.peekType() == NgSimpleTokenType.backSlash) {
      _moveNext();
      sb.write(_current!.lexeme);
    }
    return NgToken.elementDecorator(offset, sb.toString());
  }

  @protected
  NgToken? scanElementDecorator() {
    var current = _current!;
    var type = current.type;
    var offset = current.offset;
    if (type == NgSimpleTokenType.identifier) {
      _state = NgScannerState.scanAfterElementDecorator;
      return _scanCompoundDecorator();
    }
    if (type == NgSimpleTokenType.openParen) {
      _state = NgScannerState.scanSpecialEventDecorator;
      _lastDecoratorPrefix = _current;
      return NgToken.eventPrefix(offset);
    }
    if (type == NgSimpleTokenType.openBracket) {
      _state = NgScannerState.scanSpecialPropertyDecorator;
      _lastDecoratorPrefix = _current;
      return NgToken.propertyPrefix(offset);
    }
    if (type == NgSimpleTokenType.openBanana) {
      _state = NgScannerState.scanSpecialBananaDecorator;
      _lastDecoratorPrefix = _current;
      return NgToken.bananaPrefix(offset);
    }
    if (type == NgSimpleTokenType.hash) {
      _state = NgScannerState.scanSimpleElementDecorator;
      _lastDecoratorPrefix = _current;
      return NgToken.referencePrefix(offset);
    }
    if (type == NgSimpleTokenType.star) {
      _state = NgScannerState.scanSimpleElementDecorator;
      _lastDecoratorPrefix = _current;
      return NgToken.templatePrefix(offset);
    }
    if (type == NgSimpleTokenType.atSign) {
      _state = NgScannerState.scanSpecialAnnotationDecorator;
      _lastDecoratorPrefix = _current;
      return NgToken.annotationPrefix(offset);
    }

    if (type == NgSimpleTokenType.equalSign ||
        type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.doubleQuote ||
        type == NgSimpleTokenType.singleQuote) {
      var lastToken = _lastToken!;
      return handleError(
        ParserErrorCode.ELEMENT_DECORATOR,
        lastToken.offset,
        lastToken.length,
      );
    }

    if (type == NgSimpleTokenType.closeBracket ||
        type == NgSimpleTokenType.closeParen ||
        type == NgSimpleTokenType.closeBanana) {
      return handleError(
        ParserErrorCode.ELEMENT_DECORATOR_SUFFIX_BEFORE_PREFIX,
        current.offset,
        current.length,
      );
    }
    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanElementDecoratorValue() {
    var current = _current!;
    var type = current.type;
    if (current is NgSimpleQuoteToken) {
      var isDouble = current.type == NgSimpleTokenType.doubleQuote;

      NgToken leftQuoteToken;
      NgToken innerValueToken;
      NgToken rightQuoteToken;
      int leftQuoteOffset;
      int rightQuoteOffset;

      var innerValue = current.contentLexeme;
      leftQuoteOffset = current.offset;

      if (current.quoteEndOffset == null) {
        if (_recoverErrors) {
          // Manual insertion to handler since there is no recovery step.
          // Normally the quote offset comes after the decorator value, but when
          // the quote itself is absent, it must point to the last character of
          // the decorator value. Otherwise, the token's source span would
          // extend beyond the decorator itself, past EOF, and crash.
          rightQuoteOffset = current.end - 1;
          exceptionHandler.handle(_generateException(
            ParserErrorCode.UNCLOSED_QUOTE,
            current.offset,
            current.length,
          ));
        } else {
          return handleError(
            ParserErrorCode.UNCLOSED_QUOTE,
            current.offset,
            current.length,
          );
        }
      } else {
        rightQuoteOffset = current.quoteEndOffset!;
      }

      if (isDouble) {
        leftQuoteToken = NgToken.doubleQuote(leftQuoteOffset);
        rightQuoteToken = NgToken.doubleQuote(rightQuoteOffset);
      } else {
        leftQuoteToken = NgToken.singleQuote(leftQuoteOffset);
        rightQuoteToken = NgToken.singleQuote(rightQuoteOffset);
      }
      innerValueToken =
          NgToken.elementDecoratorValue(current.contentOffset, innerValue);

      _state = NgScannerState.scanAfterElementDecoratorValue;
      return NgAttributeValueToken.generate(
          leftQuoteToken, innerValueToken, rightQuoteToken);
    }
    if (type == NgSimpleTokenType.whitespace) {
      return NgToken.whitespace(current.offset, current.lexeme);
    }

    if (type == NgSimpleTokenType.identifier) {
      return handleError(
        ParserErrorCode.ELEMENT_DECORATOR_VALUE_MISSING_QUOTES,
        current.offset,
        current.length,
      );
    }

    if (type == NgSimpleTokenType.openBracket ||
        type == NgSimpleTokenType.openParen ||
        type == NgSimpleTokenType.openBanana ||
        type == NgSimpleTokenType.closeBracket ||
        type == NgSimpleTokenType.closeParen ||
        type == NgSimpleTokenType.closeBanana ||
        type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.tagEnd ||
        type == NgSimpleTokenType.voidCloseTag ||
        type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.equalSign ||
        type == NgSimpleTokenType.hash ||
        type == NgSimpleTokenType.star ||
        type == NgSimpleTokenType.atSign) {
      return handleError(
        ParserErrorCode.ELEMENT_DECORATOR_VALUE,
        _lastEqualSignOffset,
        current.offset - _lastEqualSignOffset,
      );
    }
    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanElementIdentifier({bool wasOpenTag = false}) {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.identifier) {
      _state = wasOpenTag
          ? NgScannerState.scanAfterElementIdentifierOpen
          : NgScannerState.scanAfterElementIdentifierClose;
      return NgToken.elementIdentifier(current.offset, current.lexeme);
    }
    if (wasOpenTag) {
      if (type == NgSimpleTokenType.openBracket ||
          type == NgSimpleTokenType.openParen ||
          type == NgSimpleTokenType.openBanana ||
          type == NgSimpleTokenType.hash ||
          type == NgSimpleTokenType.star ||
          type == NgSimpleTokenType.atSign ||
          type == NgSimpleTokenType.closeBracket ||
          type == NgSimpleTokenType.closeParen ||
          type == NgSimpleTokenType.closeBanana ||
          type == NgSimpleTokenType.commentBegin ||
          type == NgSimpleTokenType.openTagStart ||
          type == NgSimpleTokenType.closeTagStart ||
          type == NgSimpleTokenType.tagEnd ||
          type == NgSimpleTokenType.EOF ||
          type == NgSimpleTokenType.equalSign ||
          type == NgSimpleTokenType.whitespace ||
          type == NgSimpleTokenType.doubleQuote ||
          type == NgSimpleTokenType.singleQuote) {
        return handleError(
          ParserErrorCode.ELEMENT_IDENTIFIER,
          _lastElementStartOffset,
          current.end - _lastElementStartOffset,
        );
      }
      return handleError(
        ParserErrorCode.UNEXPECTED_TOKEN,
        current.offset,
        current.length,
      );
    } else {
      if (type == NgSimpleTokenType.closeTagStart ||
          type == NgSimpleTokenType.openTagStart ||
          type == NgSimpleTokenType.tagEnd ||
          type == NgSimpleTokenType.commentBegin ||
          type == NgSimpleTokenType.EOF ||
          type == NgSimpleTokenType.whitespace) {
        return handleError(
          ParserErrorCode.ELEMENT_IDENTIFIER,
          _lastElementStartOffset,
          current.end - _lastElementStartOffset,
        );
      }
      return handleError(
        ParserErrorCode.UNEXPECTED_TOKEN,
        current.offset,
        current.length,
      );
    }
  }

  // This state is technically a duplicate for [scanAfterElementIdentifierClose],
  // but keep for now in case we want to expand on recovery for close tags.
  @protected
  NgToken? scanElementEndClose() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.tagEnd) {
      _state = NgScannerState.scanStart;
      return NgToken.closeElementEnd(current.offset);
    }

    if (type == NgSimpleTokenType.whitespace) {
      return NgToken.whitespace(current.offset, current.lexeme);
    }

    if (type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF) {
      return handleError(
        ParserErrorCode.EXPECTED_TAG_CLOSE,
        _lastElementStartOffset,
        current.end - _lastElementStartOffset,
      );
    }

    if (type == NgSimpleTokenType.voidCloseTag) {
      return handleError(
        ParserErrorCode.VOID_CLOSE_IN_CLOSE_TAG,
        current.offset,
        current.length,
      );
    }

    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanElementEndOpen() {
    var current = _current!;
    if (current.type == NgSimpleTokenType.voidCloseTag) {
      _state = NgScannerState.scanStart;
      return NgToken.openElementEndVoid(current.offset);
    }
    if (current.type == NgSimpleTokenType.tagEnd) {
      _state = NgScannerState.scanStart;
      return NgToken.openElementEnd(current.offset);
    }
    // Directed state, should theoretically never hit.
    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanElementStart() {
    var current = _current!;
    if (current.type == NgSimpleTokenType.openTagStart) {
      _state = NgScannerState.scanElementIdentifierOpen;
      _lastElementStartOffset = current.offset;
      return NgToken.openElementStart(current.offset);
    }
    if (current.type == NgSimpleTokenType.closeTagStart) {
      _state = NgScannerState.scanElementIdentifierClose;
      _lastElementStartOffset = current.offset;
      return NgToken.closeElementStart(current.offset);
    }
    // Transient state, should theoretically never hit.
    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanInterpolation() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.text) {
      _state = NgScannerState.scanAfterInterpolation;
      return NgToken.interpolationValue(current.offset, current.lexeme);
    }

    if (_current == _lastErrorToken) {
      return handleError(
        null,
        null,
        null,
      );
    }

    if (type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.mustacheBegin) {
      return handleError(
        ParserErrorCode.UNTERMINATED_MUSTACHE,
        _lastOpenMustacheOffset,
        '{{'.length,
      );
    }
    if (type == NgSimpleTokenType.mustacheEnd) {
      return handleError(
        ParserErrorCode.EMPTY_INTERPOLATION,
        _lastOpenMustacheOffset,
        current.end - _lastOpenMustacheOffset!,
      );
    }
    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  @protected
  NgToken? scanSimpleElementDecorator() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.identifier) {
      _state = NgScannerState.scanAfterElementDecorator;
      return NgToken.elementDecorator(current.offset, current.lexeme);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.period ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        ParserErrorCode.UNEXPECTED_TOKEN,
        current.offset,
        current.length,
      );
    }

    var lastToken = _lastToken!;
    return handleError(
      ParserErrorCode.ELEMENT_DECORATOR,
      lastToken.offset,
      lastToken.length,
    )!;
  }

  @protected
  NgToken? scanSpecialAnnotationDecorator() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.period ||
        type == NgSimpleTokenType.identifier) {
      _state = NgScannerState.scanAfterElementDecorator;
      return _scanCompoundDecorator();
    }

    if (_current == _lastErrorToken) {
      return handleError(null, null, null);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        ParserErrorCode.UNEXPECTED_TOKEN,
        current.offset,
        current.length,
      );
    }

    var lastDecoratorPrefix = _lastDecoratorPrefix!;
    return handleError(
      ParserErrorCode.ELEMENT_DECORATOR_AFTER_PREFIX,
      lastDecoratorPrefix.offset,
      lastDecoratorPrefix.length,
    );
  }

  @protected
  NgToken? scanSpecialBananaDecorator() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.period ||
        type == NgSimpleTokenType.identifier) {
      _state = NgScannerState.scanSuffixBanana;
      return _scanCompoundDecorator();
    }

    if (_current == _lastErrorToken) {
      return handleError(null, null, null);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        ParserErrorCode.UNEXPECTED_TOKEN,
        current.offset,
        current.length,
      );
    }

    var lastDecoratorPrefix = _lastDecoratorPrefix!;
    return handleError(
      ParserErrorCode.ELEMENT_DECORATOR_AFTER_PREFIX,
      lastDecoratorPrefix.offset,
      lastDecoratorPrefix.length,
    );
  }

  @protected
  NgToken? scanSpecialEventDecorator() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.period ||
        type == NgSimpleTokenType.identifier) {
      _state = NgScannerState.scanSuffixEvent;
      return _scanCompoundDecorator();
    }

    if (_current == _lastErrorToken) {
      return handleError(null, null, null);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        ParserErrorCode.UNEXPECTED_TOKEN,
        current.offset,
        current.length,
      );
    }

    var lastDecoratorPrefix = _lastDecoratorPrefix!;
    return handleError(
      ParserErrorCode.ELEMENT_DECORATOR_AFTER_PREFIX,
      lastDecoratorPrefix.offset,
      lastDecoratorPrefix.length,
    );
  }

  @protected
  NgToken? scanSpecialPropertyDecorator() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.period ||
        type == NgSimpleTokenType.identifier) {
      _state = NgScannerState.scanSuffixProperty;
      return _scanCompoundDecorator();
    }

    if (_current == _lastErrorToken) {
      return handleError(null, null, null);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        ParserErrorCode.UNEXPECTED_TOKEN,
        current.offset,
        current.length,
      );
    }

    var lastDecoratorPrefix = _lastDecoratorPrefix!;
    return handleError(
      ParserErrorCode.ELEMENT_DECORATOR_AFTER_PREFIX,
      lastDecoratorPrefix.offset,
      lastDecoratorPrefix.length,
    );
  }

  @protected
  NgToken? scanSuffixBanana() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.closeBanana) {
      _state = NgScannerState.scanAfterElementDecorator;
      return NgToken.bananaSuffix(current.offset);
    }

    if (_current == _lastErrorToken) {
      return handleError(null, null, null);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        ParserErrorCode.UNEXPECTED_TOKEN,
        current.offset,
        current.length,
      );
    }

    var lastDecoratorPrefix = _lastDecoratorPrefix!;
    return handleError(
        ParserErrorCode.SUFFIX_BANANA,
        lastDecoratorPrefix.offset,
        current.offset - lastDecoratorPrefix.offset);
  }

  @protected
  NgToken? scanSuffixEvent() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.closeParen) {
      _state = NgScannerState.scanAfterElementDecorator;
      return NgToken.eventSuffix(current.offset);
    }

    if (_current == _lastErrorToken) {
      return handleError(null, null, null);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        ParserErrorCode.UNEXPECTED_TOKEN,
        current.offset,
        current.length,
      );
    }

    var lastDecoratorPrefix = _lastDecoratorPrefix!;
    return handleError(
      ParserErrorCode.SUFFIX_EVENT,
      lastDecoratorPrefix.offset,
      current.offset - lastDecoratorPrefix.offset,
    );
  }

  @protected
  NgToken? scanSuffixProperty() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.closeBracket) {
      _state = NgScannerState.scanAfterElementDecorator;
      return NgToken.propertySuffix(current.offset);
    }

    if (_current == _lastErrorToken) {
      return handleError(null, null, null);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        ParserErrorCode.UNEXPECTED_TOKEN,
        current.offset,
        current.length,
      );
    }

    var lastDecoratorPrefix = _lastDecoratorPrefix!;
    return handleError(
        ParserErrorCode.SUFFIX_PROPERTY,
        lastDecoratorPrefix.offset,
        current.offset - lastDecoratorPrefix.offset);
  }

  @protected
  NgToken? scanText() {
    var current = _current!;
    var type = current.type;
    if (type == NgSimpleTokenType.text ||
        type == NgSimpleTokenType.whitespace) {
      if (_reader.peekType() == NgSimpleTokenType.mustacheEnd) {
        _state = NgScannerState.scanBeforeInterpolation;
        return scanBeforeInterpolation();
      }
      var offset = current.offset;
      var sb = StringBuffer();
      sb.write(current.lexeme);
      while (_reader.peekType() == NgSimpleTokenType.text ||
          _reader.peekType() == NgSimpleTokenType.whitespace) {
        // Specific use case for this is when newline splits dangling {{
        sb.write(_moveNext()!.lexeme);
      }
      _state = NgScannerState.scanStart;
      return NgToken.text(offset, sb.toString());
    }
    // No real errors in scanText state, but just in case.
    return handleError(
      ParserErrorCode.UNEXPECTED_TOKEN,
      current.offset,
      current.length,
    );
  }

  /// Handles the exception provided by [ParserErrorCode] and
  /// positional information. If this value is null, no exception will
  /// be generated, but synthetic token will still be generated.
  NgToken? handleError(
    ParserErrorCode? errorCode,
    int? offset,
    int? length,
  ) {
    var currentState = _state;
    _state = NgScannerState.hasError;
    if (errorCode != null) {
      var e = _generateException(
        errorCode,
        offset!,
        length!,
      );
      exceptionHandler.handle(e);
    }

    if (_recoverErrors) {
      var solution = _rp.recover(currentState, _current!, _reader);
      _state = solution.nextState ?? currentState;
      if (solution.tokenToReturn == null) {
        _moveNext();
        return null;
      }
      return solution.tokenToReturn;
    } else {
      return null;
    }
  }

  /// Generates an [AngularParserException] using the provided
  /// [ParserErrorCode] and positional information.
  AngularParserException? _generateException(
    ParserErrorCode errorCode,
    int offset,
    int length,
  ) {
    // Avoid throwing same error
    if (_lastErrorToken == _current) {
      return null;
    }
    _lastErrorToken = _current;
    return AngularParserException(
      errorCode,
      offset,
      length,
    );
  }
}

/// For consistency purposes:
///   Element `Open` indicates <blah>
///   Element `Close` indicates </blah>
///
/// Start indicates the left bracket (< or </)
/// End indicates the right bracket (> or />)
enum NgScannerState {
  hasError,
  isEndOfFile,
  scanAfterComment,
  scanAfterElementDecorator,
  scanAfterElementDecoratorValue,
  scanAfterElementIdentifierClose,
  scanAfterElementIdentifierOpen,
  scanAfterInterpolation,
  scanBeforeElementDecorator,
  scanBeforeInterpolation,
  scanComment,
  scanElementDecorator,
  scanElementDecoratorValue,
  scanElementEndClose,
  scanElementEndOpen,
  scanElementIdentifierClose,
  scanElementIdentifierOpen,
  scanElementStart,
  scanInterpolation,
  scanSimpleElementDecorator,
  scanSpecialAnnotationDecorator,
  scanSpecialBananaDecorator,
  scanSpecialEventDecorator,
  scanSpecialPropertyDecorator,
  scanStart,
  scanSuffixBanana,
  scanSuffixEvent,
  scanSuffixProperty,
  scanText,
}
