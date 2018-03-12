// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../token/tokens.dart';
import '../visitor.dart';

/// Represents a comment block of static text.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class CommentAst implements StandaloneTemplateAst {
  /// Create a new synthetic [CommentAst] with a string [value].
  factory CommentAst(String value) = _SyntheticCommentAst;

  /// Create a new synthetic [CommentAst] that originated from node [origin].
  factory CommentAst.from(
    TemplateAst origin,
    String value,
  ) = _SyntheticCommentAst.from;

  /// Create a new [CommentAst] parsed from tokens in [sourceFile].
  factory CommentAst.parsed(
    SourceFile sourceFile,
    NgToken startCommentToken,
    NgToken valueToken,
    NgToken endCommentToken,
  ) = _ParsedCommentAst;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitComment(this, context);
  }

  @override
  bool operator ==(Object o) => o is CommentAst && value == o.value;

  @override
  int get hashCode => value.hashCode;

  /// Static text value.
  String get value;

  @override
  String toString() => '$CommentAst {$value}';
}

class _ParsedCommentAst extends TemplateAst with CommentAst {
  final NgToken _valueToken;

  _ParsedCommentAst(
    SourceFile sourceFile,
    NgToken startCommentToken,
    this._valueToken,
    NgToken endCommentToken,
  ) : super.parsed(
          startCommentToken,
          endCommentToken,
          sourceFile,
        );

  @override
  String get value => _valueToken.lexeme;
}

class _SyntheticCommentAst extends SyntheticTemplateAst with CommentAst {
  @override
  final String value;

  _SyntheticCommentAst(this.value);

  _SyntheticCommentAst.from(
    TemplateAst origin,
    this.value,
  ) : super.from(origin);
}
