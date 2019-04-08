import 'dart:html';

import 'package:angular/src/core/linker/view_container.dart';
import 'package:angular/src/core/linker/view_ref.dart' show ViewRef;
import 'package:angular/src/runtime/dom_helpers.dart';

import 'view.dart';

/// A view that can be dynamically created and destroyed.
abstract class DynamicView extends View implements ViewRef {
  /// This view's root HTML nodes.
  ///
  /// Any root view containers are recursively flattened until only HTML nodes
  /// remain.
  List<Node> get flatRootNodes;

  /// This view's last root HTML node.
  ///
  /// If the last root element is a view container, the view container's last
  /// root node is returned.
  Node get lastRootNode;

  /// Attaches this view's root nodes as siblings after [node].
  void attachRootNodesAfter(Node node) {
    insertNodesAsSibling(flatRootNodes, node);
    domRootRendererIsDirty = true;
  }

  /// Detaches this view's root nodes from their parent.
  void detachRootNodes() {
    final nodes = flatRootNodes;
    removeNodes(nodes);
    domRootRendererIsDirty = domRootRendererIsDirty || nodes.isNotEmpty;
  }

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
