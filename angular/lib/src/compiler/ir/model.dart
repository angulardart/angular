/// Base class for all intermediate representation (IR) data model classes.
abstract class IRNode {
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]);
}

/// The core reusable UI building blocks for an application.
class Component implements IRNode {
  final String name;

  Component(this.name);

  @override
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]) =>
      visitor.visitComponent(this, context);
}

abstract class IRVisitor<R, C> {
  R visitComponent(Component component, [C context]);
}
