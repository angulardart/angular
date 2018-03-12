// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:quiver/core.dart';
import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../token/tokens.dart';
import '../visitor.dart';

/// Represents a 'let-' binding attribute within a <template> AST.
/// This AST cannot exist anywhere else except as part of the attribute
/// for a [EmbeddedTemplateAst].
///
/// Clients should not extend, implement, or mix-in this class.
abstract class LetBindingAst implements TemplateAst {
  /// Create a new synthetic [LetBindingAst] listening to [name].
  /// [value] is an optional parameter, which indicates that the variable is
  /// bound to a the value '$implicit'.
  factory LetBindingAst(
    String name, [
    String value,
  ]) = _SyntheticLetBindingAst;

  /// Create a new synthetic [LetBindingAst] that originated from [origin].
  factory LetBindingAst.from(
    TemplateAst origin,
    String name, [
    String value,
  ]) = _SyntheticLetBindingAst.from;

  /// Create a new [LetBindingAst] parsed from tokens in [sourceFile].
  /// The [prefixToken] is the 'let-' component, the [elementDecoratorToken]
  /// is the variable name, and [valueToken] is the value bound to the
  /// variable.
  factory LetBindingAst.parsed(
    SourceFile sourceFile,
    NgToken prefixToken,
    NgToken elementDecoratorToken, [
    NgAttributeValueToken valueToken,
    NgToken equalSignToken,
  ]) = ParsedLetBindingAst;

  @override
  bool operator ==(Object o) =>
      o is LetBindingAst && name == o.name && value == o.value;

  @override
  int get hashCode => hash2(name, value);

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitLetBinding(this, context);
  }

  /// Name of the variable.
  String get name;

  /// Name of the value assigned to the variable.
  String get value;

  @override
  String toString() {
    if (value != null) {
      return '$LetBindingAst {let-$name="$value"}';
    }
    return '$LetBindingAst {let-$name}';
  }
}

/// Represents a real, non-synthetic `let-` binding: `let-var="value"`.
///
/// Clients should not extend, implement, or mix-in this class.
class ParsedLetBindingAst extends TemplateAst
    with LetBindingAst
    implements ParsedDecoratorAst, TagOffsetInfo {
  @override
  final NgToken prefixToken;

  @override
  final NgToken nameToken;

  /// [suffixToken] will always be null for this AST.
  @override
  final suffixToken = null;

  /// [NgAttributeValueToken] that represents the value bound to the
  /// let- variable; may be `null` to have no value implying $implicit.
  @override
  final NgAttributeValueToken valueToken;

  /// [NgToken] that represents the equal sign; may be `null` to have no
  /// value.
  final NgToken equalSignToken;

  ParsedLetBindingAst(
    SourceFile sourceFile,
    this.prefixToken,
    this.nameToken, [
    this.valueToken,
    this.equalSignToken,
  ]) : super.parsed(
          prefixToken,
          valueToken == null ? nameToken : valueToken.rightQuote,
          sourceFile,
        );

  /// Name of the variable following `let-`.
  @override
  String get name => nameToken.lexeme;

  /// Offset of the variable following `let-`.
  @override
  int get nameOffset => nameToken.offset;

  /// Offset of equal sign; may be `null` if no value.
  @override
  int get equalSignOffset => equalSignToken?.offset;

  @override
  String get value => valueToken?.innerValue?.lexeme;

  @override
  int get valueOffset => valueToken?.innerValue?.offset;

  /// Offset of value starting at left quote; may be `null` to have no value.
  @override
  int get quotedValueOffset => valueToken?.leftQuote?.offset;

  /// Offset of `let` prefix in `let-someVariable`.
  @override
  int get prefixOffset => prefixToken.offset;

  /// There is no suffix token, always returns null.
  @override
  int get suffixOffset => null;
}

class _SyntheticLetBindingAst extends SyntheticTemplateAst with LetBindingAst {
  @override
  final String name;

  @override
  final String value;

  _SyntheticLetBindingAst(this.name, [this.value]);

  _SyntheticLetBindingAst.from(
    TemplateAst origin,
    this.name, [
    this.value,
  ]) : super.from(origin);
}
