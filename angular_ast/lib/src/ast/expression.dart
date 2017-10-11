// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:meta/meta.dart';
import 'package:source_span/src/span.dart';

import '../ast.dart';
import '../exception_handler/exception_handler.dart';
import '../expression/parser.dart';
import '../token/tokens.dart';
import '../visitor.dart';

/// Wraps a parsed Dart [Expression] as an Angular [ExpressionAst].
class ExpressionAst implements TemplateAst {
  /// Dart expression.
  final analyzer.Expression expression;

  /// Create a new expression AST wrapping a Dart expression.
  const ExpressionAst(this.expression);

  /// Create a new expression AST by parsing [expression].
  factory ExpressionAst.parse(
    String expression,
    int offset, {
    @required String sourceUrl,
    ExceptionHandler exceptionHandler,
  }) {
    var paddedExpression = ' ' * offset + expression;
    return new ExpressionAst(parseExpression(
      paddedExpression,
      sourceUrl: sourceUrl,
    ));
  }

  @override
  bool operator ==(Object o) {
    if (o is ExpressionAst) {
      return o.expression.toSource() == expression.toSource();
    }
    return false;
  }

  @override
  int get hashCode => expression.hashCode;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitExpression(this, context);
  }

  @override
  NgToken get beginToken => null;

  @override
  List<StandaloneTemplateAst> get childNodes => const [];

  @override
  NgToken get endToken => null;

  @override
  bool get isParent => false;

  @override
  bool get isStandalone => false;

  @override
  bool get isSynthetic => true;

  @override
  SourceSpan get sourceSpan => null;

  @override
  String get sourceUrl => null;

  @override
  String toString() => '$ExpressionAst {$expression}';
}
