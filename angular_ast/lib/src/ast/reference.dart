// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../hash.dart';
import '../token/tokens.dart';
import '../visitor.dart';

/// Represents a reference to an element or exported directive instance.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class ReferenceAst implements TemplateAst {
  /// Create a new synthetic reference of [variable].
  factory ReferenceAst(
    String variable, [
    String identifier,
  ]) = _SyntheticReferenceAst;

  /// Create a new synthetic reference of [variable] from AST node [origin].
  factory ReferenceAst.from(
    TemplateAst origin,
    String variable, [
    String identifier,
  ]) = _SyntheticReferenceAst.from;

  /// Create new reference from tokens in [sourceFile].
  factory ReferenceAst.parsed(
    SourceFile sourceFile,
    NgToken prefixToken,
    NgToken elementDecoratorToken, [
    NgAttributeValueToken valueToken,
    NgToken equalSignToken,
  ]) = ParsedReferenceAst;

  @override
  bool operator ==(Object o) {
    if (o is ReferenceAst) {
      return identifier == o.identifier && variable == o.variable;
    }
    return false;
  }

  @override
  int get hashCode => hash2(identifier, variable);

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitReference(this, context);
  }

  /// What `exportAs` identifier to assign to [variable].
  ///
  /// If not set (i.e. `null`), the reference is the raw DOM element.
  String get identifier;

  /// Local variable name being assigned.
  String get variable;

  @override
  String toString() {
    if (identifier != null) {
      return '$ReferenceAst {#$variable="$identifier"}';
    }
    return '$ReferenceAst {#$variable}';
  }
}

/// Represents a real, non-synthetic reference to an element or exported
/// directive instance.
///
/// Clients should not extend, implement, or mix-in this class.
class ParsedReferenceAst extends TemplateAst
    with ReferenceAst
    implements ParsedDecoratorAst, TagOffsetInfo {
  /// Tokens representing the `#reference` element decorator
  @override
  final NgToken prefixToken;

  @override
  final NgToken nameToken;

  @override
  NgToken get suffixToken => null;

  /// [NgAttributeValueToken] that represents `identifier` in
  /// `#variable="reference"`.
  @override
  final NgAttributeValueToken valueToken;

  /// [NgToken] that represents the equal sign token; may be `null` to have no
  /// value.
  final NgToken equalSignToken;

  ParsedReferenceAst(
    SourceFile sourceFile,
    this.prefixToken,
    this.nameToken, [
    this.valueToken,
    this.equalSignToken,
  ]) : super.parsed(
          prefixToken,
          valueToken != null ? valueToken.rightQuote : nameToken,
          sourceFile,
        );

  /// Offset of `variable` in `#variable="identifier"`.
  @override
  int get nameOffset => nameToken.offset;

  /// Offset of equal sign; may be `null` if no value.
  @override
  int get equalSignOffset => equalSignToken.offset;

  /// Offset of `identifier` in `#variable="identifier"`; may be `null` if no
  /// value.
  @override
  int get valueOffset => valueToken?.innerValue?.offset;

  /// Offset of `identifier` starting at left quote; may be `null` if no value.
  @override
  int get quotedValueOffset => valueToken?.leftQuote?.offset;

  /// Offset of `#` in `#variable`.
  @override
  int get prefixOffset => nameToken.offset;

  /// Always returns `null` since `#ref` has no suffix.
  @override
  int get suffixOffset => null;

  /// Name `identifier` in `#variable="identifier"`.
  @override
  String get identifier => valueToken?.innerValue?.lexeme;

  /// Name `variable` in `#variable="identifier"`.
  @override
  String get variable => nameToken.lexeme;
}

class _SyntheticReferenceAst extends SyntheticTemplateAst with ReferenceAst {
  _SyntheticReferenceAst(this.variable, [this.identifier]);

  _SyntheticReferenceAst.from(
    TemplateAst origin,
    this.variable, [
    this.identifier,
  ]) : super.from(origin);

  @override
  final String identifier;

  @override
  final String variable;
}
