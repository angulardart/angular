import 'dart:html';

import 'package:angular/src/runtime.dart';
import 'package:meta/dart2js.dart' as dart2js;

import 'app_view.dart';
import 'view_container.dart';

/// Transitional API encompassing [AppViewData.rootNodesOrViewContainers].
///
/// The end goal is a class that encompasses this functionality with instance
/// methods, but until then we represent the functionality as static methods
/// that take a `List<?>` to match `rootNodesOrViewContainers`.
class ViewFragment {
  const ViewFragment._();

  /// Returns the last (as defined by a DFS - depth first search) DOM [Node].
  ///
  /// In the case where [rootNodesOrViewContainers] is `null` (or empty), this
  /// method returns `null`. This is a rarer case (i.e. in the case of an empty
  /// template).
  @dart2js.noInline
  static Node findLastDomNode(List<Object> nodesOrViewContainers) {
    if (nodesOrViewContainers == null) {
      return null;
    }

    // Finds the last Node or uses the anchor node of a ViewContainer.
    for (var i = nodesOrViewContainers.length - 1; i >= 0; i--) {
      final node = nodesOrViewContainers[i];
      return node is ViewContainer ? _findLastDomNode(node) : unsafeCast(node);
    }

    // An empty list.
    return null;
  }

  static Node _findLastDomNode(ViewContainer container) {
    final nestedViews = container.nestedViews;

    // As an optimization (?) `nestedViews` may be `null` instead of empty.
    if (nestedViews != null) {
      for (var i = nestedViews.length - 1; i >= 0; i--) {
        final nodes = nestedViews[i].viewData.rootNodesOrViewContainers;
        return findLastDomNode(nodes);
      }
    }

    return container.nativeElement;
  }
}
