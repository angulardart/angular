import '../model.dart';

/// An [IRVisitor] which simply returns null for every node visited.
///
/// This is intended to be a base class for other [IRVisitors], allowing other
/// visitors to implement only the methods needed.
class DefaultIRVisitor<R, C> implements IRVisitor<R, C> {
  @override
  R visitComponent(Component component, [C context]) => null;

  @override
  R visitDirective(Directive directive, [C context]) => null;

  @override
  R visitComponentView(ComponentView componentView, [C context]) => null;

  @override
  R visitHostView(HostView hostView, [C context]) => null;

  /// Visits all nodes provided, aggregating the result.
  ///
  /// If the visitor returns [null], then the result is removed from the list.
  List<T> visitAll<T extends R>(Iterable<IRNode> nodes, [C context]) {
    final results = <T>[];
    for (var node in nodes) {
      var result = node.accept(this, context) as T;
      if (result != null) results.add(result);
    }
    return results;
  }
}
