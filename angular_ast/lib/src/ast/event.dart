// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../hash.dart';
import '../token/tokens.dart';
import '../visitor.dart';

const _listEquals = const ListEquality<dynamic>();

/// Represents an event listener `(eventName.reductions)="expression"` on an
/// element.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class EventAst implements TemplateAst {
  /// Create a new synthetic [EventAst] listening to [name].
  factory EventAst(
    String name,
    String value, [
    ExpressionAst expression,
    List<String> reductions,
  ]) = _SyntheticEventAst;

  /// Create a new synthetic [EventAst] that originated from [origin].
  factory EventAst.from(
    TemplateAst origin,
    String name,
    String value, [
    ExpressionAst expression,
    List<String> reductions,
  ]) = _SyntheticEventAst.from;

  /// Create a new [EventAst] parsed from tokens in [sourceFile].
  factory EventAst.parsed(
    SourceFile sourceFile,
    NgToken prefixToken,
    NgToken elementDecoratorToken,
    NgToken suffixToken, [
    NgAttributeValueToken valueToken,
    NgToken equalSignToken,
  ]) = ParsedEventAst;

  @override
  bool operator ==(Object o) =>
      o is EventAst &&
      name == o.name &&
      expression == o.expression &&
      _listEquals.equals(reductions, o.reductions);

  @override
  int get hashCode => hash3(name, expression, reductions);

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitEvent(this, context);
  }

  /// Bound expression.
  ExpressionAst get expression;
  set expression(ExpressionAst expression);

  /// Name of the event being listened to.
  String get name;

  /// Unquoted value being bound to event.
  String get value;

  /// An optional list of postfixes used to filter events that support it.
  ///
  /// For example `(keydown.ctrl.space)`.
  List<String> get reductions;

  @override
  String toString() {
    if (reductions.isNotEmpty) {
      return '$EventAst {$name.${reductions.join(',')}="$value", Expression=$expression}';
    }
    return '$EventAst {$name=$value, Expression=$expression}';
  }
}

/// Represents a real, non-synthetic event listener `(event)="expression"`
/// on an element.
///
/// Clients should not extend, implement, or mix-in this class.
class ParsedEventAst extends TemplateAst
    with EventAst
    implements ParsedDecoratorAst, TagOffsetInfo {
  @override
  final NgToken prefixToken;

  @override
  final NgToken nameToken;

  // [suffixToken] may be null if 'on-' is used instead of '('.
  @override
  final NgToken suffixToken;

  /// [NgAttributeValueToken] that represents `"expression"`; may be `null` to
  /// have no value.
  @override
  final NgAttributeValueToken valueToken;

  /// [NgToken] that represents the equal sign token; may be `null` to have no
  /// value.
  final NgToken equalSignToken;

  ParsedEventAst(
    SourceFile sourceFile,
    this.prefixToken,
    this.nameToken,
    this.suffixToken, [
    this.valueToken,
    this.equalSignToken,
  ]) : super.parsed(
          prefixToken,
          valueToken == null ? suffixToken : valueToken.rightQuote,
          sourceFile,
        );

  String get _nameWithoutParentheses {
    return nameToken.lexeme;
  }

  /// ExpressionAst of `"expression"`; may be `null` to have no value.
  @override
  ExpressionAst expression;

  /// Name `eventName` in `(eventName.reductions)`.
  @override
  String get name => _nameWithoutParentheses.split('.').first;

  /// Offset of name.
  @override
  int get nameOffset => nameToken.offset;

  /// Offset of equal sign; may be `null` if no value.
  @override
  int get equalSignOffset => equalSignToken?.offset;

  /// Expression value as [String] bound to event; may be `null` if no value.
  @override
  String get value => valueToken?.innerValue?.lexeme;

  /// Offset of value; may be `null` to have no value.
  @override
  int get valueOffset => valueToken?.innerValue?.offset;

  /// Offset of value starting at left quote; may be `null` to have no value.
  @override
  int get quotedValueOffset => valueToken?.leftQuote?.offset;

  /// Offset of `(` prefix in `(eventName.reductions)`.
  @override
  int get prefixOffset => prefixToken.offset;

  /// Offset of `)` suffix in `(eventName.reductions)`.
  @override
  int get suffixOffset => suffixToken.offset;

  /// Name `reductions` in `(eventName.ctrl.shift.a)`; may be empty.
  @override
  List<String> get reductions {
    final split = _nameWithoutParentheses.split('.');
    return split.sublist(1);
  }
}

class _SyntheticEventAst extends SyntheticTemplateAst with EventAst {
  @override
  final String name;

  @override
  final String value;

  @override
  ExpressionAst expression;

  @override
  final List<String> reductions;

  _SyntheticEventAst(
    this.name,
    this.value, [
    this.expression,
    this.reductions = const [],
  ]);

  _SyntheticEventAst.from(
    TemplateAst origin,
    this.name,
    this.value, [
    this.expression,
    this.reductions = const [],
  ]) : super.from(origin);
}
