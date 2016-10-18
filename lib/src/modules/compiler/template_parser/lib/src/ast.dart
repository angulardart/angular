library angular2_template_parser.src.ast;

import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';
import 'package:quiver/core.dart';

import 'lexer.dart';
import 'schema.dart';

part 'ast/element.dart';
part 'ast/text.dart';

/// A parsed AST node from an Angular Dart template.
///
/// The Angular Dart template AST conceptually is a tree-like structure, not
/// unlike HTML itself, of which it originated. Every [NgAstNode] may itself
/// have [childNodes].
abstract class NgAstNode {
  static const ListEquality _listEquals = const ListEquality();

  /// Child nodes.
  ///
  /// Some [NgAstNode] types never have child nodes (such as text nodes); the
  /// list will always be both empty and immutable.
  List<NgAstNode> get childNodes => const [];

  /// What tokens were parsed to create this AST.
  final List<NgToken> parsedTokens;

  /// Where the node was parsed from.
  ///
  /// When the AST is parsed in development or debug mode, the span maintains
  /// the original context that was parsed to create this node. Useful to
  /// reference when errors occur or to emit source maps.
  final SourceSpan source;

  NgAstNode._(this.parsedTokens, this.source);

  @override
  bool operator ==(Object o) =>
      o is NgAstNode &&
      _listEquals.equals(childNodes, o.childNodes) &&
      source == o.source;

  @override
  int get hashCode => hash2(_listEquals.hash(childNodes), source);
}

/// An [NgAstNode] that is expected to be recognized in a schema.
///
/// In `strict` mode, no nodes may be [unknown] - during development time this
/// enforces templates and components do not have missing configuration or
/// mispellings.
abstract class NgDefinedNode<T> implements NgAstNode {
  /// Element, property, or event definition the node was recognized from.
  T get schema;

  /// Whether [schema] is `null` (not recognized).
  bool get unknown => schema != null;
}
