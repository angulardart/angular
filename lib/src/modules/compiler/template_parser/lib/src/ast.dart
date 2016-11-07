library angular2_template_parser.src.ast;

import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';
import 'package:quiver/core.dart';
import 'package:analyzer/analyzer.dart';

import 'lexer.dart';
import 'schema.dart';
import 'utils.dart';

part 'ast/attribute.dart';
part 'ast/binding.dart';
part 'ast/comment.dart';
part 'ast/element.dart';
part 'ast/event.dart';
part 'ast/interpolation.dart';
part 'ast/property.dart';
part 'ast/text.dart';

String stringifyAstTree(NgAstNode node, {int indent: 0}) {
  var buffer = new StringBuffer(' ' * indent);
  if (node is NgAttribute) {
    buffer.write('$NgAttribute ${node.name}');
    if (node.value != null) {
      buffer.write(' = ${node.value}');
    }
  } else if (node is NgComment) {
    buffer.writeln('$NgComment ${node.value}');
  } else if (node is NgElement) {
    buffer.writeln('$NgElement ${node.name}');
    for (var childNode in node.childNodes) {
      buffer.writeln(stringifyAstTree(childNode, indent: indent + 2));
    }
  } else if (node is NgText) {
    buffer.writeln('$NgText ${node.value}');
  } else {
    buffer.writeln('${node.runtimeType}');
  }
  return buffer.toString();
}

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

  NgAstNode._(this.parsedTokens);

  @override
  bool operator ==(Object o) =>
      o is NgAstNode &&
      _listEquals.equals(childNodes, o.childNodes);

  @override
  int get hashCode => hash2(_listEquals.hash(childNodes), null);

  /// Where the node was parsed from.
  ///
  /// When the AST is parsed in development or debug mode, the span maintains
  /// the original context that was parsed to create this node. Useful to
  /// reference when errors occur or to emit source maps.
  SourceSpan get source;
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

/// May be mixed in to implement [NgAstNode.source] from existing tokens.
abstract class NgAstSourceTokenMixin implements NgAstNode {
  @override
  SourceSpan get source {
    if (parsedTokens?.isNotEmpty != true) return null;
    var span = parsedTokens.first.source;
    for (var i = 1; i < parsedTokens.length; i++) {
      span = span.union(parsedTokens[i].source);
    }
    return span;
  }
}
