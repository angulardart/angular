// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:quiver/core.dart';
import 'package:source_span/source_span.dart';

import '../../ast.dart';
import '../../token/tokens.dart';
import '../../visitor.dart';

/// Represents the `[(property)]="value"` syntax.
///
/// This AST may only exist in the parses that do not de-sugar directives (i.e.
/// useful for tooling, but not useful for compilers).
///
/// Clients should not extend, implement, or mix-in this class.
abstract class BananaAst implements TemplateAst {
  /// Create a new synthetic [BananaAst] with a string [field].
  factory BananaAst(
    String name, [
    String field,
  ]) = _SyntheticBananaAst;

  /// Create a new synthetic [BananaAst] that originated from node [origin].
  factory BananaAst.from(
    TemplateAst origin,
    String name, [
    String field,
  ]) = _SyntheticBananaAst.from;

  /// Create a new [BananaAst] parsed from tokens from [sourceFile].
  factory BananaAst.parsed(
    SourceFile sourceFile,
    NgToken prefixToken,
    NgToken elementDecoratorToken,
    NgToken suffixToken,
    NgAttributeValueToken valueToken,
    NgToken equalSignToken,
  ) = ParsedBananaAst;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitBanana(this, context);
  }

  @override
  bool operator ==(Object o) {
    if (o is BananaAst) {
      return name == o.name && value == o.value;
    }
    return false;
  }

  @override
  int get hashCode => hash2(name, value);

  /// Name of the property.
  String get name;

  /// Value bound to.
  String get value;

  @override
  String toString() {
    return '$BananaAst {$name="$value"}';
  }
}

/// Represents a real, non-synthetic `[(property)]="value"` syntax.
///
/// This AST may only exist in the parses that do not de-sugar directives (i.e.
/// useful for tooling, but not useful for compilers). Preserves offsets.
///
/// Clients should not extend, implement, or mix-in this class.
class ParsedBananaAst extends TemplateAst
    with BananaAst
    implements ParsedDecoratorAst, TagOffsetInfo {
  /// Components of element decorator representing [(banana)].
  @override
  final NgToken prefixToken;

  @override
  final NgToken nameToken;

  @override
  final NgToken suffixToken;

  /// [NgAttributeValueToken] that represents `"value"`; may be `null` to have
  /// no value.
  @override
  final NgAttributeValueToken valueToken;

  /// [NgToken] that represents the equal sign token; may be `null` to have
  /// no value.
  final NgToken equalSignToken;

  ParsedBananaAst(
    SourceFile sourceFile,
    this.prefixToken,
    this.nameToken,
    this.suffixToken,
    this.valueToken,
    this.equalSignToken,
  ) : super.parsed(
            prefixToken,
            (valueToken != null ? valueToken.rightQuote : suffixToken),
            sourceFile);

  /// Inner name `property` in `[(property)]`.
  @override
  String get name => nameToken.lexeme;

  /// Offset of `property` in `[(property)]`.
  @override
  int get nameOffset => nameToken.offset;

  /// Offset of equal sign; may be `null` to have no value.
  @override
  int get equalSignOffset => equalSignToken?.offset;

  /// Value bound to banana property; may be `null` to have no value.
  @override
  String get value => valueToken?.innerValue?.lexeme;

  /// Offset of value; may be `null` to have no value.
  @override
  int get valueOffset => valueToken?.innerValue?.offset;

  /// Offset of value starting at left quote; may be `null` to have no value.
  @override
  int get quotedValueOffset => valueToken?.leftQuote?.offset;

  /// Offset of banana prefix `[(`.
  @override
  int get prefixOffset => prefixToken.offset;

  /// Offset of banana suffix `)]`.
  @override
  int get suffixOffset => suffixToken.offset;
}

class _SyntheticBananaAst extends SyntheticTemplateAst with BananaAst {
  @override
  final String name;

  @override
  final String value;

  _SyntheticBananaAst(this.name, [this.value]);

  _SyntheticBananaAst.from(
    TemplateAst origin,
    this.name, [
    this.value,
  ]) : super.from(origin);
}
