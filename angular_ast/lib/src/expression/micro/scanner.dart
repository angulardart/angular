// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:string_scanner/string_scanner.dart';

import '../../exception_handler/exception_handler.dart';
import 'token.dart';

class NgMicroScanner {
  static final _findBeforeAssignment = new RegExp(r':(\s*)');
  static final _findEndExpression = new RegExp(r';\s*');
  static final _findExpression = new RegExp(r'[^;]+');
  static final _findImplicitBind = new RegExp(r'[^ ]+');
  static final _findLetAssignmentBefore = new RegExp(r'\s*=\s*');
  static final _findLetIdentifier = new RegExp(r'[^\s=;]+');
  static final _findStartExpression = new RegExp(r'[^\s:;]+');
  static final _findWhitespace = new RegExp(r'\s+');

  final StringScanner _scanner;
  int _expressionOffset;
  int _expressionLength;

  _NgMicroScannerState _state = _NgMicroScannerState.scanInitial;

  factory NgMicroScanner(String html, {sourceUrl}) {
    return new NgMicroScanner._(new StringScanner(html, sourceUrl: sourceUrl));
  }

  NgMicroScanner._(this._scanner) {
    _scanner.scan(_findWhitespace);
    _expressionOffset = _scanner.position;
    _expressionLength = _scanner.string.length - _expressionOffset;
  }

  NgMicroToken scan() {
    switch (_state) {
      case _NgMicroScannerState.hasError:
        throw new StateError('An error occurred');
      case _NgMicroScannerState.isEndOfFile:
        return null;
      case _NgMicroScannerState.scanAfterBindIdentifier:
        return _scanAfterBindIdentifier();
      case _NgMicroScannerState.scanAfterLetIdentifier:
        return _scanAfterLetIdentifier();
      case _NgMicroScannerState.scanAfterLetKeyword:
        return _scanAfterLetKeyword();
      case _NgMicroScannerState.scanBeforeBindExpression:
        return _scanBeforeBindExpression();
      case _NgMicroScannerState.scanBindExpression:
        return _scanBindExpression();
      case _NgMicroScannerState.scanEndExpression:
        return _scanEndExpression();
      case _NgMicroScannerState.scanImplicitBind:
        return _scanImplicitBind();
      case _NgMicroScannerState.scanInitial:
        return _scanInitial();
      case _NgMicroScannerState.scanLetAssignment:
        return _scanLetAssignment();
      case _NgMicroScannerState.scanLetIdentifier:
        return _scanLetIdentifier();
    }
    throw _unexpected();
  }

  String _lexeme(int offset) => _scanner.substring(offset);

  NgMicroToken _scanAfterBindIdentifier() {
    var offset = _scanner.position;
    if (_scanner.scan(_findBeforeAssignment)) {
      _state = _NgMicroScannerState.scanBindExpression;
      return new NgMicroToken.bindExpressionBefore(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanAfterLetIdentifier() {
    var offset = _scanner.position;
    if (_scanner.scan(_findEndExpression)) {
      _state = _NgMicroScannerState.scanInitial;
      return new NgMicroToken.endExpression(offset, _lexeme(offset));
    }
    if (_scanner.scan(_findLetAssignmentBefore)) {
      _state = _NgMicroScannerState.scanLetAssignment;
      return new NgMicroToken.letAssignmentBefore(offset, _lexeme(offset));
    }
    if (_scanner.scan(_findWhitespace)) {
      _state = _NgMicroScannerState.scanImplicitBind;
      return new NgMicroToken.endExpression(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanAfterLetKeyword() {
    var offset = _scanner.position;
    if (_scanner.scan(_findWhitespace)) {
      _state = _NgMicroScannerState.scanLetIdentifier;
      return new NgMicroToken.letKeywordAfter(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanBeforeBindExpression() {
    var offset = _scanner.position;
    if (_scanner.scan(_findWhitespace)) {
      _state = _NgMicroScannerState.scanBindExpression;
      return new NgMicroToken.bindExpressionBefore(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanBindExpression() {
    var offset = _scanner.position;
    if (_scanner.scan(_findExpression)) {
      _state = _NgMicroScannerState.scanEndExpression;
      return new NgMicroToken.bindExpression(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanEndExpression() {
    if (_scanner.isDone) {
      _state = _NgMicroScannerState.isEndOfFile;
      return null;
    }
    var offset = _scanner.position;
    if (_scanner.scan(_findEndExpression)) {
      _state = _NgMicroScannerState.scanInitial;
      return new NgMicroToken.endExpression(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanImplicitBind() {
    var offset = _scanner.position;
    if (_scanner.scan(_findImplicitBind)) {
      _state = _NgMicroScannerState.scanBeforeBindExpression;
      return new NgMicroToken.bindIdentifier(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanInitial() {
    var offset = _scanner.position;
    if (_scanner.scan(_findStartExpression)) {
      var lexeme = _lexeme(offset);
      if (lexeme == 'let') {
        _state = _NgMicroScannerState.scanAfterLetKeyword;
        return new NgMicroToken.letKeyword(offset, lexeme);
      }
      if (_scanner.matches(_findBeforeAssignment)) {
        _state = _NgMicroScannerState.scanAfterBindIdentifier;
        return new NgMicroToken.bindIdentifier(offset, lexeme);
      } else {
        _state = _NgMicroScannerState.scanEndExpression;
        return new NgMicroToken.bindExpression(offset, lexeme);
      }
    }
    throw _unexpected();
  }

  NgMicroToken _scanLetAssignment() {
    var offset = _scanner.position;
    if (_scanner.scan(_findExpression)) {
      _state = _NgMicroScannerState.scanEndExpression;
      return new NgMicroToken.letAssignment(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanLetIdentifier() {
    var offset = _scanner.position;
    if (_scanner.scan(_findLetIdentifier)) {
      if (_scanner.isDone) {
        _state = _NgMicroScannerState.isEndOfFile;
      } else {
        _state = _NgMicroScannerState.scanAfterLetIdentifier;
      }
      return new NgMicroToken.letIdentifier(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  AngularParserException _unexpected() {
    _state = _NgMicroScannerState.hasError;
    return new AngularParserException(
      NgParserWarningCode.INVALID_MICRO_EXPRESSION,
      _expressionOffset,
      _expressionLength,
    );
  }
}

enum _NgMicroScannerState {
  hasError,
  isEndOfFile,
  scanAfterLetIdentifier,
  scanAfterLetKeyword,
  scanAfterBindIdentifier,
  scanBeforeBindExpression,
  scanBindExpression,
  scanEndExpression,
  scanImplicitBind,
  scanInitial,
  scanLetAssignment,
  scanLetIdentifier,
}
