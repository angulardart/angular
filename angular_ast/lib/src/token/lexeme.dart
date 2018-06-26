// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of angular_ast.src.token.tokens;

/// A [NgSimpleToken] that has a custom lexeme, i.e. not predefined by type.
///
/// For example, a `text` is (almost) any arbitrary string.
class _LexemeNgSimpleToken extends NgSimpleToken {
  const _LexemeNgSimpleToken(
      int offset, this.lexeme, this.length, NgSimpleTokenType type)
      : super._(type, offset);

  @override
  bool operator ==(Object o) {
    if (o is _LexemeNgSimpleToken) {
      return super == o && lexeme == o.lexeme;
    }
    return false;
  }

  @override
  int get hashCode => hash2(super.hashCode, lexeme);

  @override
  final String lexeme;

  @override
  final int length;
}

/// A [NgToken] that has a custom lexeme, i.e. not predefined by a token type.
///
/// For example, an `elementIdentifier` is (almost) any arbitrary string.
class _LexemeNgToken extends NgToken {
  const _LexemeNgToken(int offset, this.lexeme, NgTokenType type,
      {errorSynthetic = false})
      : super._(type, offset, errorSynthetic: errorSynthetic);

  @override
  bool operator ==(Object o) {
    if (o is _LexemeNgToken) {
      return super == o && lexeme == o.lexeme;
    }
    return false;
  }

  @override
  int get hashCode => hash2(super.hashCode, lexeme);

  @override
  final String lexeme;
}
