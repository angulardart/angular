import 'package:angular/src/compiler/compile_metadata.dart'
    show CompileTokenMetadata;
import 'package:angular/src/compiler/output/output_ast.dart' as o;

import 'constants.dart' show InjectMethodVars;
import 'view_compiler_utils.dart' show createDiTokenExpression;

/// Represents the dependency injection hierarchy of a view.
///
/// This may closely resemble the template structure, as any element that
/// contributes a provider is represented by a [ProviderNode]; however, any
/// element without a provider is omitted.
///
/// Isolating the provider hierarchy like this allows us to optimize it
/// independently from view construction.
///
/// Note that since a view may have multiple root nodes, so may it's dependency
/// injection hierarchy, and thus this is technically a *forest* (consisting of
/// multiple independently rooted trees) in data-structure parlance.
class ProviderForest {
  /// Creates a forest of providers from a copy of [roots].
  ProviderForest.from(Iterable<ProviderNode> roots) : _roots = roots.toList();

  final List<ProviderNode> _roots;

  /// Returns statements for querying the dependency injection hierarchy.
  ///
  /// These statements assume that the local variables [InjectMethodVars.token]
  /// and [InjectMethodVars.nodeIndex] are in scope.
  List<o.Statement> build() {
    final statements = <o.Statement>[];
    _build(_roots, statements);
    return statements;
  }

  /// Traverses [nodes] and their descendants in post-order.
  ///
  /// The post-order traversal is important so that a child provider for the
  /// same token comes before its parent.
  static void _build(Iterable<ProviderNode> nodes, List<o.Statement> target) {
    for (final node in nodes) {
      _build(node.children, target);
      for (final provider in node.providers) {
        final tokenCondition = provider.tokens
            .map(_createTokenCondition)
            .reduce((expression, condition) => expression.or(condition));
        final indexCondition = _createIndexCondition(node.start, node.end);
        final condition = tokenCondition.and(indexCondition);
        target.add(o.IfStmt(condition, [
          o.ReturnStatement(provider.expression),
        ]));
      }
    }
  }

  /// Creates an expression to check that 'nodeIndex' is within [start, end].
  static o.Expression _createIndexCondition(int start, int end) {
    final index = InjectMethodVars.nodeIndex;
    final lowerBound = o.literal(start);
    if (start != end) {
      final upperBound = o.literal(end);
      final withinUpperBound = index.lowerEquals(upperBound);
      if (start == 0) {
        // It's unnecessary to check that the index is greater than zero, since
        // we would never generate a negative index. Furthermore, dart2js can
        // tell that this is always true, which confuses its logic for
        // recreating the expression in JavaScript (b/30508405).
        return withinUpperBound;
      }
      return lowerBound.lowerEquals(index).and(withinUpperBound);
    } else {
      return lowerBound.equals(index);
    }
  }

  /// Creates an expression to check that 'token' is identical to a [token].
  static o.Expression _createTokenCondition(CompileTokenMetadata token) =>
      InjectMethodVars.token.identical(createDiTokenExpression(token));
}

/// Represents a provider's runtime value.
///
/// This may be injectable via multiple distinct tokens.
class ProviderInstance {
  ProviderInstance(this.tokens, this.expression);

  /// The tokens this provider can satisfy.
  final List<CompileTokenMetadata> tokens;

  /// The expression of the provided value.
  final o.Expression expression;
}

/// Represents a node in the dependency injection hierarchy of a view.
class ProviderNode {
  ProviderNode(
    this.start,
    this.end, {
    this.providers = const [],
    this.children = const [],
  });

  /// The lowest index of the range within which this provider is injectable.
  ///
  /// In practice this is the node index of the element this node represents.
  final int start;

  /// The highest index of the range within which this provider is injectable.
  ///
  /// In practice this is the node index of the last child of the element this
  /// node represents.
  final int end;

  /// The providers which are available for injection from this node.
  final List<ProviderInstance> providers;

  /// The children of this node.
  final List<ProviderNode> children;
}
