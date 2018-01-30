// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  final NgTokenReversibleReader _reader;
  NgScannerState _state = NgScannerState.scanStart;
  final ExceptionHandler exceptionHandler;

  final bool _recoverErrors;
  final RecoveryProtocol _rp = new NgAnalyzerRecoveryProtocol();

  NgSimpleToken _current;
  NgSimpleToken _lastToken;
  NgSimpleToken _lastErrorToken;

  // Storing last notable offsets to better generate exception offsets.
  // Due to the linear parsing nature of Angular, these values are recyclable.
  int _lastElementStartOffset;
  NgSimpleToken _lastDecoratorPrefix;
  int _lastOpenMustacheOffset;
  int _lastCommentStartOffset;
  int _lastEqualSignOffset;

  NgSimpleToken _moveNext() {
    _lastToken = _current;
    _current = _reader.next();
    return _current;
  }

  factory NgScanner(
    String html,
    ExceptionHandler exceptionHandler, {
    Uri sourceUrl,
  }) {
    var reader = new NgTokenReversibleReader<NgSimpleTokenType>(
        new SourceFile.fromString(html, url: sourceUrl),
        new NgSimpleTokenizer().tokenize(html));
    var recoverError = exceptionHandler is RecoveringExceptionHandler;

    return new NgScanner._(reader, recoverError, exceptionHandler);
  }

  NgScanner._(this._reader, this._recoverErrors, this.exceptionHandler);

  /// Scans and returns the next token, or `null` if there is none more.
  NgToken scan() {
    _moveNext();
    NgToken returnToken;

    while (returnToken == null) {
      switch (_state) {
        case NgScannerState.hasError:
          throw new StateError('An error occurred');
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
          if (_current.type == NgSimpleTokenType.EOF && _reader.isDone) {
            _state = NgScannerState.isEndOfFile;
            return null;
          } else if (_current.type == NgSimpleTokenType.openTagStart ||
              _current.type == NgSimpleTokenType.closeTagStart) {
            returnToken = scanElementStart();
          } else if (_current.type == NgSimpleTokenType.commentBegin) {
            returnToken = scanBeforeComment();
          } else if (_current.type == NgSimpleTokenType.mustacheBegin ||
              _current.type == NgSimpleTokenType.mustacheEnd) {
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
  NgToken scanAfterComment() {
    if (_current.type == NgSimpleTokenType.commentEnd) {
      _state = NgScannerState.scanStart;
      return new NgToken.commentEnd(_current.offset);
    }
    // Only triggered by EOF.
    return handleError(
      NgParserWarningCode.UNTERMINATED_COMMENT,
      _lastCommentStartOffset,
      _current.offset - _lastCommentStartOffset,
    );
  }

  // TODO: Max: Better handle cases like 'prop]'. Instead of
  // TODO: 'prop []' resolve, resolve as '[prop].
  @protected
  NgToken scanAfterElementDecorator() {
    var type = _current.type;

    if (type == NgSimpleTokenType.equalSign) {
      _state = NgScannerState.scanElementDecoratorValue;
      _lastEqualSignOffset = _current.offset;
      return new NgToken.beforeElementDecoratorValue(_current.offset);
    } else if (type == NgSimpleTokenType.tagEnd ||
        type == NgSimpleTokenType.voidCloseTag) {
      return scanElementEndOpen();
    } else if (type == NgSimpleTokenType.whitespace) {
      var nextType = _reader.peekType();
      // Trailing whitespace check.
      if (nextType == NgSimpleTokenType.equalSign ||
          nextType == NgSimpleTokenType.voidCloseTag ||
          nextType == NgSimpleTokenType.tagEnd) {
        return new NgToken.whitespace(_current.offset, _current.lexeme);
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
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR,
        _current.offset,
        _current.length,
      );
    }

    if (type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart) {
      return handleError(
        NgParserWarningCode.EXPECTED_TAG_CLOSE,
        _lastToken.offset,
        _lastToken.length,
      );
    }

    if (type == NgSimpleTokenType.doubleQuote ||
        type == NgSimpleTokenType.singleQuote) {
      return handleError(
        NgParserWarningCode.EXPECTED_EQUAL_SIGN,
        _lastToken.offset,
        _current.end - _lastToken.offset,
      );
    }

    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanAfterElementDecoratorValue() {
    var type = _current.type;

    if (type == NgSimpleTokenType.tagEnd ||
        type == NgSimpleTokenType.voidCloseTag) {
      return scanElementEndOpen();
    } else if (type == NgSimpleTokenType.whitespace) {
      var nextType = _reader.peekType();
      if (nextType == NgSimpleTokenType.voidCloseTag ||
          nextType == NgSimpleTokenType.tagEnd) {
        return new NgToken.whitespace(_current.offset, _current.lexeme);
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
      return handleError(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR,
        _lastToken.offset,
        _lastToken.length,
      );
    }

    if (type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart) {
      return handleError(
        NgParserWarningCode.EXPECTED_TAG_CLOSE,
        _lastToken.offset,
        _lastToken.length,
      );
    }

    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanAfterElementIdentifierClose() {
    var type = _current.type;
    if (type == NgSimpleTokenType.whitespace) {
      _state = NgScannerState.scanElementEndClose;
      return new NgToken.whitespace(_current.offset, _current.lexeme);
    }
    if (type == NgSimpleTokenType.tagEnd) {
      _state = NgScannerState.scanStart;
      return scanElementEndClose();
    }

    if (type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF) {
      return handleError(
        NgParserWarningCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER,
        _lastToken.offset,
        _lastToken.length,
      );
    }

    if (type == NgSimpleTokenType.voidCloseTag) {
      return handleError(
        NgParserWarningCode.VOID_CLOSE_IN_CLOSE_TAG,
        _current.offset,
        _current.length,
      );
    }
    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanAfterElementIdentifierOpen() {
    var type = _current.type;
    if (type == NgSimpleTokenType.whitespace) {
      if (_reader.peek().type == NgSimpleTokenType.voidCloseTag ||
          _reader.peek().type == NgSimpleTokenType.tagEnd) {
        _state = NgScannerState.scanElementEndOpen;
        return new NgToken.whitespace(_current.offset, _current.lexeme);
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
      return handleError(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR,
        _lastToken.offset,
        _lastToken.length,
      );
    }

    if (type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF) {
      return handleError(
        NgParserWarningCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER,
        _lastToken.offset,
        _lastToken.length,
      );
    }

    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanAfterInterpolation() {
    var type = _current.type;
    if (type == NgSimpleTokenType.mustacheEnd) {
      _state = NgScannerState.scanStart;
      return new NgToken.interpolationEnd(_current.offset);
    }

    if (type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.mustacheBegin ||
        type == NgSimpleTokenType.whitespace) {
      return handleError(
        NgParserWarningCode.UNTERMINATED_MUSTACHE,
        _lastOpenMustacheOffset,
        '{{'.length,
      );
    }
    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanBeforeComment() {
    if (_current.type == NgSimpleTokenType.commentBegin) {
      _state = NgScannerState.scanComment;
      _lastCommentStartOffset = _current.offset;
      return new NgToken.commentStart(_current.offset);
    }
    // Transient state, should theoretically never hit.
    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanBeforeElementDecorator() {
    if (_current.type == NgSimpleTokenType.whitespace) {
      if (_reader.peekType() == NgSimpleTokenType.voidCloseTag ||
          _reader.peekType() == NgSimpleTokenType.tagEnd) {
        _state = NgScannerState.scanAfterElementDecorator;
        return new NgToken.whitespace(_current.offset, _current.lexeme);
      }
      _state = NgScannerState.scanElementDecorator;
      return new NgToken.beforeElementDecorator(
          _current.offset, _current.lexeme);
    }
    // Transient state, should theoretically never hit.
    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanBeforeInterpolation() {
    if (_current.type == NgSimpleTokenType.mustacheBegin) {
      _state = NgScannerState.scanInterpolation;
      _lastOpenMustacheOffset = _current.offset;
      return new NgToken.interpolationStart(_current.offset);
    }

    var errorToken = _current;
    if (_current.type == NgSimpleTokenType.text &&
        _reader.peekType() == NgSimpleTokenType.mustacheEnd) {
      errorToken = _reader.peek();
    }
    return handleError(
      NgParserWarningCode.UNOPENED_MUSTACHE,
      errorToken.offset,
      errorToken.length,
    );
  }

  @protected
  NgToken scanComment() {
    if (_current.type == NgSimpleTokenType.text) {
      _state = NgScannerState.scanAfterComment;
      return new NgToken.commentValue(_current.offset, _current.lexeme);
    }
    if (_current.type == NgSimpleTokenType.commentEnd) {
      _state = NgScannerState.scanAfterComment;
      return scanAfterComment();
    }
    // Only EOF should enable error.
    return handleError(
      NgParserWarningCode.UNTERMINATED_COMMENT,
      _lastCommentStartOffset,
      '<!--'.length,
    );
  }

  // Doesn't switch states or check validity of current token.
  NgToken _scanCompoundDecorator() {
    var offset = _current.offset;
    var sb = new StringBuffer();
    sb.write(_current.lexeme);
    while (_reader.peekType() == NgSimpleTokenType.period ||
        _reader.peekType() == NgSimpleTokenType.identifier ||
        _reader.peekType() == NgSimpleTokenType.dash ||
        _reader.peekType() == NgSimpleTokenType.percent ||
        _reader.peekType() == NgSimpleTokenType.backSlash) {
      _moveNext();
      sb.write(_current.lexeme);
    }
    return new NgToken.elementDecorator(offset, sb.toString());
  }

  @protected
  NgToken scanElementDecorator() {
    var type = _current.type;
    var offset = _current.offset;
    if (type == NgSimpleTokenType.identifier) {
      _state = NgScannerState.scanAfterElementDecorator;
      return _scanCompoundDecorator();
    }
    if (type == NgSimpleTokenType.openParen) {
      _state = NgScannerState.scanSpecialEventDecorator;
      _lastDecoratorPrefix = _current;
      return new NgToken.eventPrefix(offset);
    }
    if (type == NgSimpleTokenType.openBracket) {
      _state = NgScannerState.scanSpecialPropertyDecorator;
      _lastDecoratorPrefix = _current;
      return new NgToken.propertyPrefix(offset);
    }
    if (type == NgSimpleTokenType.openBanana) {
      _state = NgScannerState.scanSpecialBananaDecorator;
      _lastDecoratorPrefix = _current;
      return new NgToken.bananaPrefix(offset);
    }
    if (type == NgSimpleTokenType.hash) {
      _state = NgScannerState.scanSimpleElementDecorator;
      _lastDecoratorPrefix = _current;
      return new NgToken.referencePrefix(offset);
    }
    if (type == NgSimpleTokenType.star) {
      _state = NgScannerState.scanSimpleElementDecorator;
      _lastDecoratorPrefix = _current;
      return new NgToken.templatePrefix(offset);
    }
    if (type == NgSimpleTokenType.atSign) {
      _state = NgScannerState.scanSimpleElementDecorator;
      _lastDecoratorPrefix = _current;
      return new NgToken.annotationPrefix(offset);
    }

    if (type == NgSimpleTokenType.equalSign ||
        type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.doubleQuote ||
        type == NgSimpleTokenType.singleQuote) {
      return handleError(
        NgParserWarningCode.ELEMENT_DECORATOR,
        _lastToken.offset,
        _lastToken.length,
      );
    }

    if (type == NgSimpleTokenType.closeBracket ||
        type == NgSimpleTokenType.closeParen ||
        type == NgSimpleTokenType.closeBanana) {
      return handleError(
        NgParserWarningCode.ELEMENT_DECORATOR_SUFFIX_BEFORE_PREFIX,
        _current.offset,
        _current.length,
      );
    }
    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanElementDecoratorValue() {
    var type = _current.type;
    if (_current is NgSimpleQuoteToken) {
      var current = _current as NgSimpleQuoteToken;
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
          rightQuoteOffset = current.end;
          exceptionHandler.handle(_generateException(
            NgParserWarningCode.UNCLOSED_QUOTE,
            current.offset,
            current.length,
          ));
        } else {
          return handleError(
            NgParserWarningCode.UNCLOSED_QUOTE,
            current.offset,
            current.length,
          );
        }
      } else {
        rightQuoteOffset = current.quoteEndOffset;
      }

      if (isDouble) {
        leftQuoteToken = new NgToken.doubleQuote(leftQuoteOffset);
        rightQuoteToken = new NgToken.doubleQuote(rightQuoteOffset);
      } else {
        leftQuoteToken = new NgToken.singleQuote(leftQuoteOffset);
        rightQuoteToken = new NgToken.singleQuote(rightQuoteOffset);
      }
      innerValueToken =
          new NgToken.elementDecoratorValue(current.contentOffset, innerValue);

      _state = NgScannerState.scanAfterElementDecoratorValue;
      return new NgAttributeValueToken.generate(
          leftQuoteToken, innerValueToken, rightQuoteToken);
    }
    if (type == NgSimpleTokenType.whitespace) {
      return new NgToken.whitespace(_current.offset, _current.lexeme);
    }

    if (type == NgSimpleTokenType.identifier) {
      return handleError(
        NgParserWarningCode.ELEMENT_DECORATOR_VALUE_MISSING_QUOTES,
        _current.offset,
        _current.length,
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
        NgParserWarningCode.ELEMENT_DECORATOR_VALUE,
        _lastEqualSignOffset,
        _current.offset - _lastEqualSignOffset,
      );
    }
    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanElementIdentifier({@required bool wasOpenTag}) {
    var type = _current.type;
    if (type == NgSimpleTokenType.identifier) {
      _state = wasOpenTag
          ? NgScannerState.scanAfterElementIdentifierOpen
          : NgScannerState.scanAfterElementIdentifierClose;
      return new NgToken.elementIdentifier(_current.offset, _current.lexeme);
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
          NgParserWarningCode.ELEMENT_IDENTIFIER,
          _lastElementStartOffset,
          _current.end - _lastElementStartOffset,
        );
      }
      return handleError(
        NgParserWarningCode.UNEXPECTED_TOKEN,
        _current.offset,
        _current.length,
      );
    } else {
      if (type == NgSimpleTokenType.closeTagStart ||
          type == NgSimpleTokenType.openTagStart ||
          type == NgSimpleTokenType.tagEnd ||
          type == NgSimpleTokenType.commentBegin ||
          type == NgSimpleTokenType.EOF ||
          type == NgSimpleTokenType.whitespace) {
        return handleError(
          NgParserWarningCode.ELEMENT_IDENTIFIER,
          _lastElementStartOffset,
          _current.end - _lastElementStartOffset,
        );
      }
      return handleError(
        NgParserWarningCode.UNEXPECTED_TOKEN,
        _current.offset,
        _current.length,
      );
    }
  }

  // This state is technically a duplicate for [scanAfterElementIdentifierClose],
  // but keep for now in case we want to expand on recovery for close tags.
  @protected
  NgToken scanElementEndClose() {
    var type = _current.type;
    if (type == NgSimpleTokenType.tagEnd) {
      _state = NgScannerState.scanStart;
      return new NgToken.closeElementEnd(_current.offset);
    }

    if (type == NgSimpleTokenType.whitespace) {
      return new NgToken.whitespace(_current.offset, _current.lexeme);
    }

    if (type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF) {
      return handleError(
        NgParserWarningCode.EXPECTED_TAG_CLOSE,
        _lastElementStartOffset,
        _current.end - _lastElementStartOffset,
      );
    }

    if (type == NgSimpleTokenType.voidCloseTag) {
      return handleError(
        NgParserWarningCode.VOID_CLOSE_IN_CLOSE_TAG,
        _current.offset,
        _current.length,
      );
    }

    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanElementEndOpen() {
    if (_current.type == NgSimpleTokenType.voidCloseTag) {
      _state = NgScannerState.scanStart;
      return new NgToken.openElementEndVoid(_current.offset);
    }
    if (_current.type == NgSimpleTokenType.tagEnd) {
      _state = NgScannerState.scanStart;
      return new NgToken.openElementEnd(_current.offset);
    }
    // Directed state, should theoretically never hit.
    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanElementStart() {
    if (_current.type == NgSimpleTokenType.openTagStart) {
      _state = NgScannerState.scanElementIdentifierOpen;
      _lastElementStartOffset = _current.offset;
      return new NgToken.openElementStart(_current.offset);
    }
    if (_current.type == NgSimpleTokenType.closeTagStart) {
      _state = NgScannerState.scanElementIdentifierClose;
      _lastElementStartOffset = _current.offset;
      return new NgToken.closeElementStart(_current.offset);
    }
    // Transient state, should theoretically never hit.
    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanInterpolation() {
    var type = _current.type;
    if (type == NgSimpleTokenType.text) {
      _state = NgScannerState.scanAfterInterpolation;
      return new NgToken.interpolationValue(_current.offset, _current.lexeme);
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
        NgParserWarningCode.UNTERMINATED_MUSTACHE,
        _lastOpenMustacheOffset,
        '{{'.length,
      );
    }
    if (type == NgSimpleTokenType.mustacheEnd) {
      return handleError(
        NgParserWarningCode.EMPTY_INTERPOLATION,
        _lastOpenMustacheOffset,
        _current.end - _lastOpenMustacheOffset,
      );
    }
    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  @protected
  NgToken scanSimpleElementDecorator() {
    var type = _current.type;
    if (type == NgSimpleTokenType.identifier) {
      _state = NgScannerState.scanAfterElementDecorator;
      return new NgToken.elementDecorator(_current.offset, _current.lexeme);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.period ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        NgParserWarningCode.UNEXPECTED_TOKEN,
        _current.offset,
        _current.length,
      );
    }

    return handleError(
      NgParserWarningCode.ELEMENT_DECORATOR,
      _lastToken.offset,
      _lastToken.length,
    );
  }

  @protected
  NgToken scanSpecialBananaDecorator() {
    var type = _current.type;
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
        NgParserWarningCode.UNEXPECTED_TOKEN,
        _current.offset,
        _current.length,
      );
    }

    return handleError(
      NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX,
      _lastDecoratorPrefix.offset,
      _lastDecoratorPrefix.length,
    );
  }

  @protected
  NgToken scanSpecialEventDecorator() {
    var type = _current.type;
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
        NgParserWarningCode.UNEXPECTED_TOKEN,
        _current.offset,
        _current.length,
      );
    }

    return handleError(
      NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX,
      _lastDecoratorPrefix.offset,
      _lastDecoratorPrefix.length,
    );
  }

  @protected
  NgToken scanSpecialPropertyDecorator() {
    var type = _current.type;
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
        NgParserWarningCode.UNEXPECTED_TOKEN,
        _current.offset,
        _current.length,
      );
    }

    return handleError(
      NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX,
      _lastDecoratorPrefix.offset,
      _lastDecoratorPrefix.length,
    );
  }

  @protected
  NgToken scanSuffixBanana() {
    var type = _current.type;
    if (type == NgSimpleTokenType.closeBanana) {
      _state = NgScannerState.scanAfterElementDecorator;
      return new NgToken.bananaSuffix(_current.offset);
    }

    if (_current == _lastErrorToken) {
      return handleError(null, null, null);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        NgParserWarningCode.UNEXPECTED_TOKEN,
        _current.offset,
        _current.length,
      );
    }

    return handleError(
        NgParserWarningCode.SUFFIX_BANANA,
        _lastDecoratorPrefix.offset,
        _current.offset - _lastDecoratorPrefix.offset);
  }

  @protected
  NgToken scanSuffixEvent() {
    var type = _current.type;
    if (type == NgSimpleTokenType.closeParen) {
      _state = NgScannerState.scanAfterElementDecorator;
      return new NgToken.eventSuffix(_current.offset);
    }

    if (_current == _lastErrorToken) {
      return handleError(null, null, null);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        NgParserWarningCode.UNEXPECTED_TOKEN,
        _current.offset,
        _current.length,
      );
    }

    return handleError(
      NgParserWarningCode.SUFFIX_EVENT,
      _lastDecoratorPrefix.offset,
      _current.offset - _lastDecoratorPrefix.offset,
    );
  }

  @protected
  NgToken scanSuffixProperty() {
    var type = _current.type;
    if (type == NgSimpleTokenType.closeBracket) {
      _state = NgScannerState.scanAfterElementDecorator;
      return new NgToken.propertySuffix(_current.offset);
    }

    if (_current == _lastErrorToken) {
      return handleError(null, null, null);
    }

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.unexpectedChar) {
      return handleError(
        NgParserWarningCode.UNEXPECTED_TOKEN,
        _current.offset,
        _current.length,
      );
    }

    return handleError(
        NgParserWarningCode.SUFFIX_PROPERTY,
        _lastDecoratorPrefix.offset,
        _current.offset - _lastDecoratorPrefix.offset);
  }

  @protected
  NgToken scanText() {
    if (_current.type == NgSimpleTokenType.text ||
        _current.type == NgSimpleTokenType.whitespace) {
      if (_reader.peekType() == NgSimpleTokenType.mustacheEnd) {
        _state = NgScannerState.scanBeforeInterpolation;
        return scanBeforeInterpolation();
      }
      var offset = _current.offset;
      var sb = new StringBuffer();
      sb.write(_current.lexeme);
      while (_reader.peekType() == NgSimpleTokenType.text ||
          _reader.peekType() == NgSimpleTokenType.whitespace) {
        // Specific use case for this is when newline splits dangling {{
        sb.write(_moveNext().lexeme);
      }
      _state = NgScannerState.scanStart;
      return new NgToken.text(offset, sb.toString());
    }
    // No real errors in scanText state, but just in case.
    return handleError(
      NgParserWarningCode.UNEXPECTED_TOKEN,
      _current.offset,
      _current.length,
    );
  }

  /// Handles the exception provided by [NgParserWarningCode] and
  /// positional information. If this value is null, no exception will
  /// be generated, but synthetic token will still be generated.
  NgToken handleError(
    NgParserWarningCode errorCode,
    int offset,
    int length,
  ) {
    var currentState = _state;
    _state = NgScannerState.hasError;
    if (errorCode != null) {
      var e = _generateException(
        errorCode,
        offset,
        length,
      );
      exceptionHandler.handle(e);
    }

    if (_recoverErrors) {
      var solution = _rp.recover(currentState, _current, _reader);
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
  /// [NgParserWarningCode] and positional information.
  AngularParserException _generateException(
    NgParserWarningCode errorCode,
    int offset,
    int length,
  ) {
    // Avoid throwing same error
    if (_lastErrorToken == _current) {
      return null;
    }
    _lastErrorToken = _current;
    return new AngularParserException(
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
  scanSpecialBananaDecorator,
  scanSpecialEventDecorator,
  scanSpecialPropertyDecorator,
  scanStart,
  scanSuffixBanana,
  scanSuffixEvent,
  scanSuffixProperty,
  scanText,
}
