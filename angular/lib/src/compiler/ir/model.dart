/// Base class for all intermediate representation (IR) data model classes.
abstract class IRNode {
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]);
}

/// The core reusable UI building blocks for an application.
class Component implements IRNode {
  final String name;

  final List<View> views;

  Component(this.name, {this.views = const []});

  @override
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]) =>
      visitor.visitComponent(this, context);
}

abstract class View extends IRNode {
  List<IRNode> get children;
}

class ComponentView implements View {
  @override
  final List<IRNode> children;

  ComponentView({this.children = const []});

  @override
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]) =>
      visitor.visitComponentView(this, context);
}

class HostView implements View {
  final ComponentView componentView;

  HostView(this.componentView);

  @override
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]) =>
      visitor.visitHostView(this, context);

  @override
  List<IRNode> get children => [componentView];
}

abstract class IRVisitor<R, C> {
  R visitComponent(Component component, [C context]);

  R visitComponentView(ComponentView componentView, [C context]);
  R visitHostView(HostView hostView, [C context]);
}
