import 'dart:html';

import 'package:angular/src/core/linker/view_container.dart';
import 'package:angular/src/core/linker/view_ref.dart' show ViewRef;

import 'view.dart';

/// An interface for views that can be dynamically created and destroyed.
abstract class DynamicView implements View, ViewRef {
  /// This view's root DOM nodes.
  ///
  /// Any root view containers are recursively flattened until only HTML nodes
  /// remain.
  List<Node> get flatRootNodes;

  /// This view's last root DOM node.
  ///
  /// If the last root element is a view container, the view container's last
  /// root node is returned.
  Node get lastRootNode;

  /// Appends this view's root DOM nodes as siblings after [node].
  void addRootNodesAfter(Node node);

  /// Removes this view's root DOM nodes from their parent [ViewContainer].
  void removeRootNodes();

  /// Appends this view's root DOM nodes to [target].
  ///
  /// This method is equivalent to appending [flatRootNodes] to [target], but is
  /// more efficient since it doesn't store them in an intermediate list.
  void addRootNodesTo(List<Node> target);

  /// Appends this view's root DOM nodes to [parent]'s children.
  ///
  /// This method is equivalent to `addRootNodesTo(parent.children)`, but is
  /// more efficient since it doesn't require computing `[Element.children]`.
  void addRootNodesToChildrenOf(Element parent);

  /// Notifies this view that it was inserted into [viewContainer].
  ///
  /// This is invoked by the [viewContainer] into which this view was inserted.
  void wasInserted(ViewContainer viewContainer);

  /// Notifies this view that it was moved within a view container.
  ///
  /// This is invoked by the [ViewContainer] within which this view was moved.
  void wasMoved();

  /// Notifies this view that it was removed from a view container.
  ///
  /// This is invoked by the [ViewContainer] from which this view was removed.
  void wasRemoved();
}
