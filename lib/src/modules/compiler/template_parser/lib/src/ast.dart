import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';

import 'schema.dart';

/// Parsed attribute AST.
abstract class NgAttributeAst implements NgTemplateAst {
  /// Create a new attribute node with [name] set to [value].
  factory NgAttributeAst(String name, String value, [SourceSpan source]) =
      _NgAttributeAst;

  /// Create a new attribute node with [name] without a value.
  factory NgAttributeAst.noValue(String name, [SourceSpan source]) =>
      new _NgAttributeAst(name, null, source);

  /// Attribute name.
  String get name;

  /// Attribute value.
  String get value;
}

class _NgAttributeAst extends _AbstractLeafAst implements NgAttributeAst {
  @override
  final String name;

  @override
  final String value;

  _NgAttributeAst(this.name, [this.value, SourceSpan source]) : super(source);
}

/// Parsed comment AST.
abstract class NgCommentAst implements NgTemplateAst {
  /// Create a new comment node AST of [value].
  factory NgCommentAst(String value, [SourceSpan source]) = _NgCommentAst;

  /// Comment content.
  String get value;
}

class _NgCommentAst extends _AbstractLeafAst implements NgCommentAst {
  @override
  final String value;

  _NgCommentAst(this.value, [SourceSpan source]) : super(source);
}

/// Parsed element AST.
abstract class NgElementAst implements NgTemplateAst {
  /// Create a new [NgElementAst] defined by [schema].
  factory NgElementAst(String tagName, NgElementSchema schema,
      [Iterable<NgTemplateAst> nodes]) = _RecognizedNgElementAst;

  /// Create a new [NgElementAst] from an unrecognized [tagName].
  factory NgElementAst.unknown(String tagName, [Iterable<NgTemplateAst> nodes]) = _UnknownNgElementAst;

  /// Whether [schema] is `null`.
  bool get isUnknown;

  /// Which schema the element was recognized from.
  NgElementSchema get schema;

  /// Tag name.
  String get tagName;
}

class _RecognizedNgElementAst extends _AbstractParentAst
    implements NgElementAst {
  @override
  final bool isUnknown = false;

  @override
  final NgElementSchema schema;

  @override
  final String tagName;

  _RecognizedNgElementAst(
    this.tagName,
    this.schema, [
    Iterable<NgTemplateAst> childNodes = const [],
  ])
      : super(childNodes.toList(growable: false));
}

class _UnknownNgElementAst extends _AbstractParentAst implements NgElementAst {
  @override
  final bool isUnknown = true;

  @override
  final NgElementSchema schema = null;

  @override
  final String tagName;

  _UnknownNgElementAst(this.tagName, [Iterable<NgTemplateAst> nodes = const []]) : super(nodes.toList());
}

/// Parsed event AST.
abstract class NgEventAst implements NgTemplateAst {
  /// Create an event [name] node AST bound to [value].
  factory NgEventAst(String name, NgExpressionAst value, [SourceSpan source]) =
      _NgEventAst;

  /// Event name.
  String get name;

  /// Event value.
  NgExpressionAst get value;
}

class _NgEventAst extends _AbstractLeafAst implements NgEventAst {
  @override
  final String name;

  @override
  final NgExpressionAst value;

  _NgEventAst(this.name, this.value, [SourceSpan source]) : super(source);
}

/// Parsed expression AST.
abstract class NgExpressionAst implements NgTemplateAst {}

/// Parsed interpolated text AST.
abstract class NgInterpolateAst implements NgTemplateAst {
  /// Create a new interpolated [expression].
  factory NgInterpolateAst(NgExpressionAst expression, [SourceSpan source]) =
      _NgInterpolateAst;

  /// Expression content.
  NgExpressionAst get expression;
}

class _NgInterpolateAst extends _AbstractLeafAst implements NgInterpolateAst {
  @override
  final NgExpressionAst expression;

  _NgInterpolateAst(this.expression, [SourceSpan source]) : super(source);
}

/// Parsed property AST.
abstract class NgPropertyAst implements NgTemplateAst {
  /// Creates a property [name] node AST bound to [value].
  factory NgPropertyAst(String name, NgExpressionAst value,
      [SourceSpan source]) = _NgPropertyAst;

  /// Property name.
  String get name;

  /// Property value.
  NgExpressionAst get value;
}

class _NgPropertyAst extends _AbstractLeafAst implements NgPropertyAst {
  @override
  final String name;

  @override
  final NgExpressionAst value;

  _NgPropertyAst(this.name, this.value, [SourceSpan source]) : super(source);
}

/// A recognized Angular Dart template AST.
abstract class NgTemplateAst implements List<NgTemplateAst> {
  /// Original parsed source.
  SourceSpan get source;
}

abstract class _AbstractParentAst extends UnmodifiableListView<NgTemplateAst>
    implements NgTemplateAst {
  @override
  final SourceSpan source;

  _AbstractParentAst(List<NgTemplateAst> childNodes, [this.source])
      : super(childNodes);
}

class _AbstractLeafAst extends ListMixin<NgTemplateAst>
    implements NgTemplateAst {
  @override
  final SourceSpan source;

  _AbstractLeafAst([this.source]);

  @override
  NgTemplateAst operator [](_) => throw new RangeError('No elements.');

  @override
  operator []=(_, __) {
    throw new RangeError('No elements.');
  }

  @override
  int get length => 0;

  @override
  set length(_) => throw new RangeError('No elements.');
}

/// Parsed text AST.
abstract class NgTextAst implements NgTemplateAst {
  /// Create a new text node of [value].
  factory NgTextAst(String value, [SourceSpan source]) = _NgTextAst;

  /// Text content.
  String get value;
}

class _NgTextAst extends _AbstractLeafAst implements NgTextAst {
  final String value;

  _NgTextAst(this.value, [SourceSpan source]) : super(source);
}
