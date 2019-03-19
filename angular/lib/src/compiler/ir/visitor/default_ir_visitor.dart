import '../model.dart';

/// An [IRVisitor] which simply returns null for every node visited.
///
/// This is intended to be a base class for other [IRVisitors], allowing other
/// visitors to implement only the methods needed.
class DefaultIRVisitor<R, C> implements IRVisitor<R, C> {
  @override
  R visitLibrary(Library library, [C context]) => null;

  @override
  R visitComponent(Component component, [C context]) => null;

  @override
  R visitDirective(Directive directive, [C context]) => null;

  @override
  R visitComponentView(ComponentView componentView, [C context]) => null;

  @override
  R visitHostView(HostView hostView, [C context]) => null;

  @override
  R visitBinding(Binding binding, [C context]) => null;

  @override
  R visitAttributeBinding(AttributeBinding attributeBinding, [C context]) =>
      null;

  @override
  R visitClassBinding(ClassBinding classBinding, [C context]) => null;

  @override
  R visitHtmlBinding(HtmlBinding htmlBinding, [C context]) => null;

  @override
  R visitPropertyBinding(PropertyBinding propertyBinding, [C context]) => null;

  @override
  R visitStyleBinding(StyleBinding styleBinding, [C context]) => null;

  @override
  R visitTabIndexBinding(TabIndexBinding tabIndexBinding, [C context]) => null;

  @override
  R visitTextBinding(TextBinding textBinding, [C context]) => null;

  @override
  R visitBoundExpression(BoundExpression boundExpression, [C context]) => null;

  @override
  R visitBoundI18nMessage(BoundI18nMessage boundI18nMessage, [C context]) =>
      null;

  @override
  R visitStringLiteral(StringLiteral stringLiteral, [C context]) => null;

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
