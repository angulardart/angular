// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../hash.dart';

/// Represents a section of parsed text from an Angular micro expression.
///
/// Clients should not extend, implement, or mix-in this class.
class NgMicroToken {
  factory NgMicroToken.bindExpressionBefore(int offset, String lexeme) {
    return new NgMicroToken._(
      NgMicroTokenType.bindExpressionBefore,
      lexeme,
      offset,
    );
  }

  factory NgMicroToken.bindExpression(int offset, String lexeme) {
    return new NgMicroToken._(NgMicroTokenType.bindExpression, lexeme, offset);
  }

  factory NgMicroToken.bindIdentifier(int offset, String lexeme) {
    return new NgMicroToken._(NgMicroTokenType.bindIdentifier, lexeme, offset);
  }

  factory NgMicroToken.endExpression(int offset, String lexeme) {
    return new NgMicroToken._(NgMicroTokenType.endExpression, lexeme, offset);
  }

  factory NgMicroToken.letAssignment(int offset, String lexeme) {
    return new NgMicroToken._(NgMicroTokenType.letAssignment, lexeme, offset);
  }

  factory NgMicroToken.letAssignmentBefore(int offset, String lexeme) {
    return new NgMicroToken._(
      NgMicroTokenType.letAssignmentBefore,
      lexeme,
      offset,
    );
  }

  factory NgMicroToken.letIdentifier(int offset, String lexeme) {
    return new NgMicroToken._(
      NgMicroTokenType.letIdentifier,
      lexeme,
      offset,
    );
  }

  factory NgMicroToken.letKeyword(int offset, String lexeme) {
    return new NgMicroToken._(NgMicroTokenType.letKeyword, lexeme, offset);
  }

  factory NgMicroToken.letKeywordAfter(int offset, String lexeme) {
    return new NgMicroToken._(NgMicroTokenType.letKeywordAfter, lexeme, offset);
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
  static const endExpression = const NgMicroTokenType._('endExpression');
  static const bindExpression = const NgMicroTokenType._('bindExpression');
  static const bindExpressionBefore = const NgMicroTokenType._(
    'bindExpressionBefore',
  );
  static const bindIdentifier = const NgMicroTokenType._('bindIdentifier');
  static const letAssignment = const NgMicroTokenType._('letAssignment');
  static const letAssignmentBefore = const NgMicroTokenType._(
    'letAssignmentBefore',
  );
  static const letIdentifier = const NgMicroTokenType._('letIdentifier');
  static const letKeyword = const NgMicroTokenType._('letKeyword');
  static const letKeywordAfter = const NgMicroTokenType._('letKeywordAfter');

  final String _name;

  const NgMicroTokenType._(this._name);
}
