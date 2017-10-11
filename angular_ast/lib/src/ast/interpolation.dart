// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../token/tokens.dart';
import '../visitor.dart';

/// Represents a bound text element to an expression.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class InterpolationAst implements StandaloneTemplateAst {
  /// Create a new synthetic [InterpolationAst] with a bound [expression].
  factory InterpolationAst(
    String value,
    ExpressionAst expression,
  ) = _SyntheticInterpolationAst;

  /// Create a new synthetic [InterpolationAst] that originated from [origin].
  factory InterpolationAst.from(
    TemplateAst origin,
    String value,
    ExpressionAst expression,
  ) = _SyntheticInterpolationAst.from;

  /// Create a new [InterpolationAst] parsed from tokens in [sourceFile].
  factory InterpolationAst.parsed(
    SourceFile sourceFile,
    NgToken beginToken,
    NgToken valueToken,
    NgToken endToken,
  ) = ParsedInterpolationAst;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitInterpolation(this, context);
  }

  /// Bound expression.
  ExpressionAst get expression;
  set expression(ExpressionAst expression);

  /// Bound String value used in expression; used to preserve offsets
  String get value;

  @override
  bool operator ==(Object o) {
    return o is InterpolationAst &&
        o.value == value &&
        o.expression == expression;
  }

  @override
  int get hashCode => expression.hashCode;

  @override
  String toString() => '$InterpolationAst {$value}';
}

class ParsedInterpolationAst extends TemplateAst with InterpolationAst {
  @override
  ExpressionAst expression;

  final NgToken valueToken;

  ParsedInterpolationAst(
    SourceFile sourceFile,
    NgToken beginToken,
    this.valueToken,
    NgToken endToken,
  )
      : super.parsed(beginToken, endToken, sourceFile);

  @override
  String get value => valueToken.lexeme;
}

class _SyntheticInterpolationAst extends SyntheticTemplateAst
    with InterpolationAst {
  @override
  ExpressionAst expression;

  _SyntheticInterpolationAst(this.value, this.expression);

  _SyntheticInterpolationAst.from(
    TemplateAst origin,
    this.value,
    this.expression,
  )
      : super.from(origin);

  @override
  final String value;
}
