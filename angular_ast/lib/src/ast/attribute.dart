// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:quiver/core.dart';
import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../token/tokens.dart';
import '../visitor.dart';

const _listEquals = const ListEquality<dynamic>();

/// Represents a static attribute assignment (i.e. not bound to an expression).
///
/// Clients should not extend, implement, or mix-in this class.
abstract class AttributeAst implements TemplateAst {
  /// Create a new synthetic [AttributeAst] with a string [value].
  factory AttributeAst(
    String name, [
    String value,
    List<InterpolationAst> mustaches,
  ]) = _SyntheticAttributeAst;

  /// Create a new synthetic [AttributeAst] that originated from node [origin].
  factory AttributeAst.from(
    TemplateAst origin,
    String name, [
    String value,
    List<InterpolationAst> mustaches,
  ]) = _SyntheticAttributeAst.from;

  /// Create a new [AttributeAst] parsed from tokens from [sourceFile].
  factory AttributeAst.parsed(
    SourceFile sourceFile,
    NgToken nameToken, [
    NgAttributeValueToken valueToken,
    NgToken equalSignToken,
    List<InterpolationAst> mustaches,
  ]) = ParsedAttributeAst;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitAttribute(this, context);
  }

  @override
  bool operator ==(Object o) {
    if (o is AttributeAst) {
      return name == o.name &&
          value == o.value &&
          _listEquals.equals(mustaches, o.mustaches);
    }
    return false;
  }

  @override
  int get hashCode => hash2(name, value);

  /// Static attribute name.
  String get name;

  /// Static attribute value; may be `null` to have no value.
  String get value;

  /// Mustaches found within value; may be `null` if value is null.
  /// If value exists but has no mustaches, will be empty list.
  List<InterpolationAst> get mustaches;

  /// Static attribute value with quotes attached;
  /// may be `null` to have no value.
  String get quotedValue;

  @override
  String toString() {
    if (quotedValue != null) {
      return '$AttributeAst {$name=$quotedValue}';
    }
    return '$AttributeAst {$name}';
  }
}

/// Represents a real(non-synthetic) parsed AttributeAst. Preserves offsets.
///
/// Clients should not extend, implement, or mix-in this class.
class ParsedAttributeAst extends TemplateAst
    with AttributeAst
    implements ParsedDecoratorAst, TagOffsetInfo {
  /// [NgToken] that represents the attribute name.
  @override
  final NgToken nameToken;

  /// [NgAttributeValueToken] that represents the attribute value. May be `null`
  /// to have no value.
  @override
  final NgAttributeValueToken valueToken;

  /// [NgToken] that represents the equal sign token. May be `null` to have no
  /// value.
  final NgToken equalSignToken;

  ParsedAttributeAst(
    SourceFile sourceFile,
    this.nameToken, [
    this.valueToken,
    this.equalSignToken,
    this.mustaches,
  ])
      : super.parsed(
          nameToken,
          (valueToken == null ? nameToken : valueToken.rightQuote),
          sourceFile,
        );

  /// Static attribute name.
  @override
  String get name => nameToken.lexeme;

  /// Static attribute name offset.
  @override
  int get nameOffset => nameToken.offset;

  /// Static offset of equal sign; may be `null` to have no value.
  @override
  int get equalSignOffset => equalSignToken?.offset;

  /// Static attribute value; may be `null` to have no value.
  @override
  String get value => valueToken?.innerValue?.lexeme;

  /// Parsed static attribute parts that are mustache-expressions.
  @override
  final List<InterpolationAst> mustaches;

  /// Static attribute value including quotes; may be `null` to have no value.
  @override
  String get quotedValue => valueToken?.lexeme;

  /// Static attribute value offset; may be `null` to have no value.
  @override
  int get valueOffset => valueToken?.innerValue?.offset;

  /// Static attribute value including quotes offset; may be `null` to have no
  /// value.
  @override
  int get quotedValueOffset => valueToken?.leftQuote?.offset;

  @override
  NgToken get prefixToken => null;

  @override
  int get prefixOffset => null;

  @override
  NgToken get suffixToken => null;

  @override
  int get suffixOffset => null;
}

class _SyntheticAttributeAst extends SyntheticTemplateAst with AttributeAst {
  @override
  final String name;

  @override
  final String value;

  @override
  final List<InterpolationAst> mustaches;

  @override
  String get quotedValue => value == null ? null : '"$value"';

  _SyntheticAttributeAst(this.name, [this.value, this.mustaches]);

  _SyntheticAttributeAst.from(
    TemplateAst origin,
    this.name, [
    this.value,
    this.mustaches,
  ])
      : super.from(origin);
}
