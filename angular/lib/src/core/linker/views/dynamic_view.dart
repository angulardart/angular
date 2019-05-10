import 'dart:html';

import 'package:angular/src/core/linker/view_container.dart';
import 'package:angular/src/core/linker/view_fragment.dart';
import 'package:angular/src/core/linker/view_ref.dart';

import 'view.dart';

/// An interface for views that can be dynamically created and destroyed.
///
/// Note that generated views should never extend this class directly, but
/// rather one of its specializations.
abstract class DynamicView implements View, ViewRef {
  /// This view's root DOM nodes.
  ///
  /// Any root view containers are recursively flattened until only HTML nodes
  /// remain.
  // TODO(b/132109022): replace with `viewFragment.flattenRootNodes()`.
  List<Node> get flatRootNodes;

  /// This view's last root DOM node.
  ///
  /// If the last root element is a view container, the view container's last
  /// root node is returned.
  // TODO(b/132109022): replace with `viewFragment.findLastDomNode()`.
  Node get lastRootNode;

  /// Tracks the root DOM nodes or view containers of this view.
  ViewFragment get viewFragment;

  /// Appends this view's root DOM nodes as siblings after [node].
  // TODO(b/132109599): replace with single static method or function.
  void addRootNodesAfter(Node node);

  /// Removes this view's root DOM nodes from their parent [ViewContainer].
  // TODO(b/132109599): replace with single static method or function.
  void removeRootNodes();

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

/// The interface for [DynamicView] data bundled together as an optimization.
///
/// Similar to [ViewData], this interface exists solely as a common point for
/// documentation.
abstract class DynamicViewData implements ViewData {
  /// The container in which this view is currently inserted.
  ///
  /// Null if this view is currently detached.
  ViewContainer get viewContainer;

  /// Storage for [DynamicView.viewFragment].
  ViewFragment get viewFragment;

  /// Registers a [callback] to be invoked by [destroy].
  void addOnDestroyCallback(void Function() callback);
}
