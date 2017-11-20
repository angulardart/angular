// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of angular_ast.src.recovery_protocol.recovery_protocol;

class NgAnalyzerRecoveryProtocol extends RecoveryProtocol {
  @override
  RecoverySolution hasError(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    return new RecoverySolution.skip();
  }

  @override
  RecoverySolution isEndOfFile(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    return new RecoverySolution.skip();
  }

  @override
  RecoverySolution scanAfterComment(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;

    if (current.type == NgSimpleTokenType.EOF) {
      reader.putBack(current);
      returnState = NgScannerState.scanStart;
      returnToken = new NgToken.generateErrorSynthetic(
          current.offset, NgTokenType.commentEnd);
      return new RecoverySolution(returnState, returnToken);
    }
    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanAfterElementDecorator(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;
    var offset = current.offset;

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
      reader.putBack(current);
      returnState = NgScannerState.scanElementDecorator;
      returnToken = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.beforeElementDecorator,
          lexeme: ' ');
    } else if (type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart) {
      reader.putBack(current);
      returnState = NgScannerState.scanStart;
      returnToken = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.openElementEnd);
    } else if (type == NgSimpleTokenType.doubleQuote ||
        type == NgSimpleTokenType.singleQuote) {
      reader.putBack(current);
      returnState = NgScannerState.scanElementDecoratorValue;
      returnToken = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.beforeElementDecoratorValue);
    }

    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanAfterElementDecoratorValue(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;
    var offset = current.offset;

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
      reader.putBack(current);
      returnState = NgScannerState.scanElementDecorator;
      returnToken = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.beforeElementDecorator,
          lexeme: ' ');
    } else if (type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart) {
      reader.putBack(current);
      returnToken = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.openElementEnd);
      returnState = NgScannerState.scanStart;
    }

    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanAfterElementIdentifierClose(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;
    var offset = current.offset;

    if (type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.voidCloseTag) {
      if (type != NgSimpleTokenType.voidCloseTag) {
        reader.putBack(current);
      }
      returnToken = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.closeElementEnd);
      returnState = NgScannerState.scanStart;
    }

    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanAfterElementIdentifierOpen(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;

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
      reader.putBack(current);
      returnToken = new NgToken.generateErrorSynthetic(
          current.offset, NgTokenType.beforeElementDecorator,
          lexeme: ' ');
      returnState = NgScannerState.scanElementDecorator;
    } else if (type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF) {
      reader.putBack(current);
      returnToken = new NgToken.generateErrorSynthetic(
          current.offset, NgTokenType.openElementEnd);
      returnState = NgScannerState.scanStart;
    }

    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanAfterInterpolation(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    var type = current.type;
    if (type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.mustacheBegin ||
        type == NgSimpleTokenType.whitespace) {
      reader.putBack(current);
      return new RecoverySolution(
          NgScannerState.scanStart,
          new NgToken.generateErrorSynthetic(
              current.offset, NgTokenType.interpolationEnd));
    }
    return new RecoverySolution.skip();
  }

  @override
  RecoverySolution scanBeforeElementDecorator(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    return new RecoverySolution.skip();
  }

  @override
  RecoverySolution scanBeforeInterpolation(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    if (current.type == NgSimpleTokenType.text ||
        current.type == NgSimpleTokenType.mustacheEnd) {
      reader.putBack(current);
      returnToken = new NgToken.generateErrorSynthetic(
          current.offset, NgTokenType.interpolationStart);
      returnState = NgScannerState.scanInterpolation;
    }
    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanComment(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    if (current.type == NgSimpleTokenType.EOF) {
      return new RecoverySolution(
          NgScannerState.scanStart,
          new NgToken.generateErrorSynthetic(
              current.offset, NgTokenType.commentEnd));
    }
    return new RecoverySolution.skip();
  }

  @override
  RecoverySolution scanInterpolation(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;

    if (type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.mustacheBegin ||
        type == NgSimpleTokenType.mustacheEnd ||
        type == NgSimpleTokenType.whitespace) {
      reader.putBack(current);
      returnToken = new NgToken.generateErrorSynthetic(
          current.offset, NgTokenType.interpolationValue,
          lexeme: '');
      returnState = NgScannerState.scanAfterInterpolation;
    }
    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanElementDecorator(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;
    var offset = current.offset;

    if (type == NgSimpleTokenType.equalSign ||
        type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.doubleQuote ||
        type == NgSimpleTokenType.singleQuote) {
      reader.putBack(current);
      returnToken = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.elementDecorator);
      returnState = NgScannerState.scanAfterElementDecorator;
    } else if (type == NgSimpleTokenType.closeBracket) {
      reader.putBack(current);
      returnState = NgScannerState.scanSpecialPropertyDecorator;
      returnToken = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.propertyPrefix);
    } else if (type == NgSimpleTokenType.closeParen) {
      reader.putBack(current);
      returnState = NgScannerState.scanSpecialEventDecorator;
      returnToken =
          new NgToken.generateErrorSynthetic(offset, NgTokenType.eventPrefix);
    } else if (type == NgSimpleTokenType.closeBanana) {
      reader.putBack(current);
      returnState = NgScannerState.scanSpecialBananaDecorator;
      returnToken =
          new NgToken.generateErrorSynthetic(offset, NgTokenType.bananaPrefix);
    }

    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanElementDecoratorValue(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;
    var offset = current.offset;

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
      reader.putBack(current);
      returnState = NgScannerState.scanAfterElementDecoratorValue;

      var left =
          new NgToken.generateErrorSynthetic(offset, NgTokenType.doubleQuote);
      var value = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.elementDecoratorValue);
      var right =
          new NgToken.generateErrorSynthetic(offset, NgTokenType.doubleQuote);

      returnToken = new NgAttributeValueToken.generate(left, value, right);
    }
    if (type == NgSimpleTokenType.identifier) {
      returnState = NgScannerState.scanAfterElementDecoratorValue;
      var left =
          new NgToken.generateErrorSynthetic(offset, NgTokenType.doubleQuote);
      var value = new NgToken.elementDecoratorValue(offset, current.lexeme);
      var right = new NgToken.generateErrorSynthetic(
          offset + current.length, NgTokenType.doubleQuote);

      returnToken = new NgAttributeValueToken.generate(left, value, right);
    }

    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanElementEndClose(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;
    var offset = current.offset;

    if (type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.voidCloseTag) {
      if (type != NgSimpleTokenType.voidCloseTag) {
        reader.putBack(current);
      }
      returnToken = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.closeElementEnd);
      returnState = NgScannerState.scanStart;
    }

    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanElementEndOpen(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    return new RecoverySolution.skip();
  }

  @override
  RecoverySolution scanElementIdentifierClose(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;
    var offset = current.offset;

    if (type == NgSimpleTokenType.closeTagStart ||
        type == NgSimpleTokenType.openTagStart ||
        type == NgSimpleTokenType.tagEnd ||
        type == NgSimpleTokenType.commentBegin ||
        type == NgSimpleTokenType.EOF ||
        type == NgSimpleTokenType.whitespace) {
      reader.putBack(current);
      returnToken = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.elementIdentifier);
      returnState = NgScannerState.scanAfterElementIdentifierClose;
    }

    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanElementIdentifierOpen(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;
    var offset = current.offset;

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
      reader.putBack(current);
      returnToken = new NgToken.generateErrorSynthetic(
          offset, NgTokenType.elementIdentifier);
      returnState = NgScannerState.scanAfterElementIdentifierOpen;
    }
    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanOpenElementEnd(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    return new RecoverySolution.skip();
  }

  @override
  RecoverySolution scanElementStart(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    return new RecoverySolution.skip();
  }

  @override
  RecoverySolution scanSimpleElementDecorator(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.period ||
        type == NgSimpleTokenType.unexpectedChar ||
        type == NgSimpleTokenType.percent ||
        type == NgSimpleTokenType.backSlash) {
      return new RecoverySolution.skip();
    }
    reader.putBack(current);
    returnState = NgScannerState.scanAfterElementDecorator;
    returnToken = new NgToken.generateErrorSynthetic(
        current.offset, NgTokenType.elementDecorator);
    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanSpecialBananaDecorator(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.unexpectedChar ||
        type == NgSimpleTokenType.percent ||
        type == NgSimpleTokenType.backSlash) {
      return new RecoverySolution.skip();
    }
    reader.putBack(current);
    returnState = NgScannerState.scanSuffixBanana;
    returnToken = new NgToken.generateErrorSynthetic(
        current.offset, NgTokenType.elementDecorator);
    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanSpecialEventDecorator(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.unexpectedChar ||
        type == NgSimpleTokenType.percent ||
        type == NgSimpleTokenType.backSlash) {
      return new RecoverySolution.skip();
    }
    reader.putBack(current);
    returnState = NgScannerState.scanSuffixEvent;
    returnToken = new NgToken.generateErrorSynthetic(
        current.offset, NgTokenType.elementDecorator);
    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanSpecialPropertyDecorator(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.unexpectedChar ||
        type == NgSimpleTokenType.percent ||
        type == NgSimpleTokenType.backSlash) {
      return new RecoverySolution.skip();
    }
    reader.putBack(current);
    returnState = NgScannerState.scanSuffixProperty;
    returnToken = new NgToken.generateErrorSynthetic(
        current.offset, NgTokenType.elementDecorator);
    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanStart(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    return new RecoverySolution.skip();
  }

  @override
  RecoverySolution scanSuffixBanana(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.unexpectedChar ||
        type == NgSimpleTokenType.percent ||
        type == NgSimpleTokenType.backSlash) {
      return new RecoverySolution.skip();
    }
    reader.putBack(current);
    returnState = NgScannerState.scanAfterElementDecorator;
    returnToken = new NgToken.generateErrorSynthetic(
        current.offset, NgTokenType.bananaSuffix);
    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanSuffixEvent(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.unexpectedChar ||
        type == NgSimpleTokenType.percent ||
        type == NgSimpleTokenType.backSlash) {
      return new RecoverySolution.skip();
    }
    reader.putBack(current);
    returnState = NgScannerState.scanAfterElementDecorator;
    returnToken = new NgToken.generateErrorSynthetic(
        current.offset, NgTokenType.eventSuffix);
    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanSuffixProperty(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    NgScannerState returnState;
    NgToken returnToken;
    var type = current.type;

    if (type == NgSimpleTokenType.bang ||
        type == NgSimpleTokenType.forwardSlash ||
        type == NgSimpleTokenType.dash ||
        type == NgSimpleTokenType.unexpectedChar ||
        type == NgSimpleTokenType.percent ||
        type == NgSimpleTokenType.backSlash) {
      return new RecoverySolution.skip();
    }

    reader.putBack(current);
    returnState = NgScannerState.scanAfterElementDecorator;
    returnToken = new NgToken.generateErrorSynthetic(
        current.offset, NgTokenType.propertySuffix);
    return new RecoverySolution(returnState, returnToken);
  }

  @override
  RecoverySolution scanText(
      NgSimpleToken current, NgTokenReversibleReader reader) {
    return new RecoverySolution.skip();
  }
}
