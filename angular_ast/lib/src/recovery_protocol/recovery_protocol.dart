// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library angular_ast.src.recovery_protocol.recovery_protocol;

import '../parser/reader.dart';
import '../scanner.dart';
import '../token/tokens.dart';

part 'angular_analyzer_protocol.dart';

abstract class RecoveryProtocol {
  RecoverySolution recover(NgScannerState state, NgSimpleToken current,
      NgTokenReversibleReader reader) {
    switch (state) {
      case NgScannerState.hasError:
        return hasError(current, reader);
      case NgScannerState.isEndOfFile:
        return isEndOfFile(current, reader);
      case NgScannerState.scanAfterComment:
        return scanAfterComment(current, reader);
      case NgScannerState.scanAfterElementDecorator:
        return scanAfterElementDecorator(current, reader);
      case NgScannerState.scanAfterElementDecoratorValue:
        return scanAfterElementDecoratorValue(current, reader);
      case NgScannerState.scanAfterElementIdentifierClose:
        return scanAfterElementIdentifierClose(current, reader);
      case NgScannerState.scanAfterElementIdentifierOpen:
        return scanAfterElementIdentifierOpen(current, reader);
      case NgScannerState.scanAfterInterpolation:
        return scanAfterInterpolation(current, reader);
      case NgScannerState.scanBeforeElementDecorator:
        return scanBeforeElementDecorator(current, reader);
      case NgScannerState.scanBeforeInterpolation:
        return scanBeforeInterpolation(current, reader);
      case NgScannerState.scanComment:
        return scanComment(current, reader);
      case NgScannerState.scanInterpolation:
        return scanInterpolation(current, reader);
      case NgScannerState.scanElementDecorator:
        return scanElementDecorator(current, reader);
      case NgScannerState.scanElementDecoratorValue:
        return scanElementDecoratorValue(current, reader);
      case NgScannerState.scanElementEndClose:
        return scanElementEndClose(current, reader);
      case NgScannerState.scanElementEndOpen:
        return scanElementEndOpen(current, reader);
      case NgScannerState.scanElementIdentifierClose:
        return scanElementIdentifierClose(current, reader);
      case NgScannerState.scanElementIdentifierOpen:
        return scanElementIdentifierOpen(current, reader);
      case NgScannerState.scanElementStart:
        return scanElementStart(current, reader);
      case NgScannerState.scanSimpleElementDecorator:
        return scanSimpleElementDecorator(current, reader);
      case NgScannerState.scanSpecialBananaDecorator:
        return scanSpecialBananaDecorator(current, reader);
      case NgScannerState.scanSpecialEventDecorator:
        return scanSpecialEventDecorator(current, reader);
      case NgScannerState.scanSpecialPropertyDecorator:
        return scanSpecialPropertyDecorator(current, reader);
      case NgScannerState.scanStart:
        return scanStart(current, reader);
      case NgScannerState.scanSuffixBanana:
        return scanSuffixBanana(current, reader);
      case NgScannerState.scanSuffixEvent:
        return scanSuffixEvent(current, reader);
      case NgScannerState.scanSuffixProperty:
        return scanSuffixProperty(current, reader);
      case NgScannerState.scanText:
        return scanText(current, reader);
    }
    return new RecoverySolution.skip();
  }

  RecoverySolution hasError(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution isEndOfFile(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanAfterComment(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanAfterElementDecorator(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanAfterElementDecoratorValue(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanAfterElementIdentifierClose(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanAfterElementIdentifierOpen(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanAfterInterpolation(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanBeforeElementDecorator(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanBeforeInterpolation(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanComment(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanInterpolation(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanElementDecorator(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanElementDecoratorValue(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanElementEndClose(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanElementEndOpen(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanElementIdentifierClose(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanElementIdentifierOpen(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanOpenElementEnd(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanElementStart(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanSimpleElementDecorator(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanSpecialBananaDecorator(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanSpecialEventDecorator(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanSpecialPropertyDecorator(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanStart(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanSuffixBanana(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanSuffixEvent(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanSuffixProperty(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();

  RecoverySolution scanText(
          NgSimpleToken current, NgTokenReversibleReader reader) =>
      new RecoverySolution.skip();
}

/// Setting nextState as `null` causes scanner to retain original state.
/// Setting tokenToReturn as `null` causes scanner to consume current token
/// and simply move to next token.
class RecoverySolution {
  final NgScannerState nextState;
  final NgToken tokenToReturn;

  RecoverySolution(this.nextState, this.tokenToReturn);

  factory RecoverySolution.skip() => new RecoverySolution(null, null);
}
