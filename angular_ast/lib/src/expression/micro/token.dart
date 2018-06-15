// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../hash.dart';

/// Represents a section of parsed text from an Angular micro expression.
///
/// Clients should not extend, implement, or mix-in this class.
class NgMicroToken {
  factory NgMicroToken.bindExpressionBefore(int offset, String lexeme) {
    return NgMicroToken._(
      NgMicroTokenType.bindExpressionBefore,
      lexeme,
      offset,
    );
  }

  factory NgMicroToken.bindExpression(int offset, String lexeme) {
    return NgMicroToken._(NgMicroTokenType.bindExpression, lexeme, offset);
  }

  factory NgMicroToken.bindIdentifier(int offset, String lexeme) {
    return NgMicroToken._(NgMicroTokenType.bindIdentifier, lexeme, offset);
  }

  factory NgMicroToken.endExpression(int offset, String lexeme) {
    return NgMicroToken._(NgMicroTokenType.endExpression, lexeme, offset);
  }

  factory NgMicroToken.letAssignment(int offset, String lexeme) {
    return NgMicroToken._(NgMicroTokenType.letAssignment, lexeme, offset);
  }

  factory NgMicroToken.letAssignmentBefore(int offset, String lexeme) {
    return NgMicroToken._(
      NgMicroTokenType.letAssignmentBefore,
      lexeme,
      offset,
    );
  }

  factory NgMicroToken.letIdentifier(int offset, String lexeme) {
    return NgMicroToken._(
      NgMicroTokenType.letIdentifier,
      lexeme,
      offset,
    );
  }

  factory NgMicroToken.letKeyword(int offset, String lexeme) {
    return NgMicroToken._(NgMicroTokenType.letKeyword, lexeme, offset);
  }

  factory NgMicroToken.letKeywordAfter(int offset, String lexeme) {
    return NgMicroToken._(NgMicroTokenType.letKeywordAfter, lexeme, offset);
  }

  const NgMicroToken._(this.type, this.lexeme, this.offset);

  @override
  bool operator ==(Object o) {
    if (o is NgMicroToken) {
      return o.offset == offset && o.type == type;
    }
    return false;
  }

  @override
  int get hashCode => hash3(offset, lexeme, type);

  /// Indexed location where the token ends in the original source text.
  int get end => offset + length;

  /// Number of characters in this token.
  int get length => lexeme.length;

  /// What characters were scanned and represent this token.
  final String lexeme;

  /// Indexed location where the token begins in the original source text.
  final int offset;

  /// Type of token scanned.
  final NgMicroTokenType type;

  @override
  String toString() => '#$NgMicroToken(${type._name}) {$offset:$lexeme}';
}

class NgMicroTokenType {
  static const endExpression = NgMicroTokenType._('endExpression');
  static const bindExpression = NgMicroTokenType._('bindExpression');
  static const bindExpressionBefore = NgMicroTokenType._(
    'bindExpressionBefore',
  );
  static const bindIdentifier = NgMicroTokenType._('bindIdentifier');
  static const letAssignment = NgMicroTokenType._('letAssignment');
  static const letAssignmentBefore = NgMicroTokenType._(
    'letAssignmentBefore',
  );
  static const letIdentifier = NgMicroTokenType._('letIdentifier');
  static const letKeyword = NgMicroTokenType._('letKeyword');
  static const letKeywordAfter = NgMicroTokenType._('letKeywordAfter');

  final String _name;

  const NgMicroTokenType._(this._name);
}
