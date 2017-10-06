// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:source_span/source_span.dart';

import '../token/tokens.dart';

/// A narrow interface for reading tokens from a series of tokens.
/// Can only move forward within token iterable.
///
/// Not compatible with error recovery.
class NgTokenReader<TokenType> {
  final Iterator<NgBaseToken> _iterator;

  NgBaseToken _peek;

  factory NgTokenReader(SourceFile source, Iterable<NgBaseToken> tokens) {
    return new NgTokenReader._(source, tokens.iterator);
  }

  NgTokenReader._(SourceFile source, this._iterator);

  /// Returns the next token, if any, otherwise `null`.
  NgBaseToken next() {
    if (_peek != null) {
      var token = _peek;
      _peek = null;
      return token;
    }
    return _iterator.moveNext() ? _iterator.current : null;
  }

  /// Returns the next token without incrementing.
  /// Returns null otherwise.
  NgBaseToken peek() => _peek = next();

  /// Returns the next token type without incrementing.
  /// Returns null otherwise.
  TokenType peekType() {
    _peek = next();
    if (_peek != null) {
      return _peek.type;
    }
    return null;
  }

  /// Returns whether the current token is of [type].
  bool when(TokenType type) => _iterator.current.type == type;

  /// Returns whether there is any more tokens to return.
  bool get isDone {
    if (_peek != null) {
      return false;
    }
    if (peek() == null) {
      return true;
    }
    return false;
  }
}

/// A more advanced interface for reading tokens from a series of tokens.
/// Can move forward within iterable of Tokens, and put tokens back.
///
/// Compatible with Error Recovery.
class NgTokenReversibleReader<TokenType> extends NgTokenReader<TokenType> {
  final Queue<NgBaseToken> _seen = new Queue<NgBaseToken>();

  factory NgTokenReversibleReader(
    SourceFile source,
    Iterable<NgBaseToken> tokens,
  ) {
    return new NgTokenReversibleReader._(source, tokens.iterator);
  }

  NgTokenReversibleReader._(
    SourceFile source,
    Iterator<NgBaseToken> iterator,
  )
      : super._(source, iterator);

  /// Scans forward for the next peek type that isn't ignoreType
  /// For example, `peekTypeIgnoringType(whitespace)` will peek
  /// for the next type that isn't whitespace.
  /// Returns `null` if there are no further types aside from ignoreType
  /// or iterator is empty.
  TokenType peekTypeIgnoringType(TokenType ignoreType) {
    var buffer = new Queue<NgBaseToken>();

    peek();
    while (_peek != null && _peek.type == ignoreType) {
      buffer.add(_peek);
      _peek = null;
      peek();
    }

    var returnType = (_peek == null) ? null : _peek.type;
    if (_peek != null) {
      buffer.add(_peek);
      _peek = null;
    }
    _seen.addAll(buffer);

    return returnType;
  }

  @override
  NgBaseToken next() {
    if (_peek != null) {
      var token = _peek;
      _peek = null;
      return token;
    } else if (_seen.isNotEmpty) {
      return _seen.removeFirst();
    }
    return _iterator.moveNext() ? _iterator.current : null;
  }

  NgBaseToken putBack(NgBaseToken token) {
    if (_peek != null) {
      _seen.addFirst(_peek);
      _peek = token;
      return _peek;
    } else {
      _peek = token;
      return _peek;
    }
  }
}
