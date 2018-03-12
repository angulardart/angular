// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:quiver/core.dart';
import 'package:source_span/source_span.dart';

import '../../ast.dart';
import '../../token/tokens.dart';
import '../../visitor.dart';

/// Represents the sugared form of `*directive="value"`.
///
/// This AST may only exist in the parses that do not de-sugar directives (i.e.
/// useful for tooling, but not useful for compilers).
///
/// Clients should not extend, implement, or mix-in this class.
abstract class StarAst implements TemplateAst {
  /// Create a new synthetic [StarAst] assigned to [name].
  factory StarAst(
    String name, [
    String value,
  ]) = _SyntheticStarAst;

  /// Create a new synthetic property AST that originated from another AST.
  factory StarAst.from(
    TemplateAst origin,
    String name, [
    String value,
  ]) = _SyntheticStarAst.from;

  /// Create a new property assignment parsed from tokens in [sourceFile].
  factory StarAst.parsed(
    SourceFile sourceFile,
    NgToken prefixToken,
    NgToken elementDecoratorToken, [
    NgAttributeValueToken valueToken,
    NgToken equalSignToken,
  ]) = ParsedStarAst;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitStar(this, context);
  }

  @override
  bool operator ==(Object o) {
    if (o is PropertyAst) {
      return value == o.value && name == o.name;
    }
    return false;
  }

  @override
  int get hashCode => hash2(value, name);

  /// Name of the directive being created.
  String get name;

  /// Name of expression string. Can be null.
  String get value;

  @override
  String toString() {
    if (value != null) {
      return '$StarAst {$name="$value"}';
    }
    return '$StarAst {$name}';
  }
}

/// Represents a real, non-synthetic sugared form of `*directive="value"`.
///
/// This AST may only exist in the parses that do not de-sugar directives (i.e.
/// useful for tooling, but not useful for compilers). Preserves offsets.
///
/// Clients should not extend, implement, or mix-in this class.
class ParsedStarAst extends TemplateAst
    with StarAst
    implements ParsedDecoratorAst, TagOffsetInfo {
  @override
  final NgToken prefixToken;

  @override
  final NgToken nameToken;

  @override
  NgToken get suffixToken => null;

  /// [NgAttributeValueToken] that represents `"value"`; may be `null` to have
  /// no value.
  @override
  final NgAttributeValueToken valueToken;

  /// [NgToken] that represents the equal sign token; may be `null` to have no
  /// value.
  final NgToken equalSignToken;

  ParsedStarAst(
    SourceFile sourceFile,
    this.prefixToken,
    this.nameToken, [
    this.valueToken,
    this.equalSignToken,
  ]) : super.parsed(prefixToken,
            valueToken != null ? valueToken.rightQuote : nameToken, sourceFile);

  /// Name `directive` in `*directive`.
  @override
  String get name => nameToken.lexeme;

  /// Offset of `directive` in `*directive`.
  @override
  int get nameOffset => nameToken.offset;

  /// Offset of equal sign; may be `null` to have no value.
  @override
  int get equalSignOffset => equalSignToken.offset;

  /// Value bound to `*directive`; may be `null` to have no value.
  @override
  String get value => valueToken?.innerValue?.lexeme;

  /// Offset of value; may be `null to have no value.
  @override
  int get valueOffset => valueToken?.innerValue?.offset;

  /// Offset of value starting at left quote; may be `null` to have no value.
  @override
  int get quotedValueOffset => valueToken?.leftQuote?.offset;

  /// Offset of template prefix `*`.
  @override
  int get prefixOffset => prefixToken.offset;

  /// Always returns `null` since `*directive` has no suffix.
  @override
  int get suffixOffset => null;
}

class _SyntheticStarAst extends SyntheticTemplateAst with StarAst {
  _SyntheticStarAst(
    this.name, [
    this.value,
  ]);

  _SyntheticStarAst.from(
    TemplateAst origin,
    this.name, [
    this.value,
  ]) : super.from(origin);

  @override
  final String name;

  @override
  final String value;
}
