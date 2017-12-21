// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of angular_ast.src.exceptions;

/// Exception class to be used in AngularAst parser.
class AngularParserException extends Error {
  /// Length of error segment/token.
  final int length;

  /// Reasoning for exception to be raised.
  final ErrorCode errorCode;

  /// Offset of where the exception was detected.
  final int offset;

  AngularParserException(
    this.errorCode,
    this.offset,
    this.length,
  );

  @override
  bool operator ==(Object o) {
    if (o is AngularParserException) {
      return errorCode == o.errorCode &&
          length == o.length &&
          offset == o.offset;
    }
    return false;
  }

  @override
  int get hashCode => hash3(errorCode, length, offset);

  @override
  String toString() => 'AngularParserException{$errorCode}';
}
