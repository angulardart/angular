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

  /// Appends all DOM [Node]s (as defined by a DFS - depth first search).
  ///
  /// This is semantically similar to [flattenDomNodes], but operates based on
  /// appending elements to [target] instead of to a [List]. It is possible to
  /// create a generic "visit DOM nodes" method, but it would perform worse (it
  /// would require using `target.children.add` or passing callbacks).
  @dart2js.noInline
  static void appendDomNodes(
    Element target,
    List<Object> nodesOrViewContainers,
  ) {
    final length = nodesOrViewContainers.length;
    for (var i = 0; i < length; i++) {
      final node = nodesOrViewContainers[i];
      if (node is ViewContainer) {
        target.append(node.nativeElement);
        final nestedViews = node.nestedViews;
        if (nestedViews != null) {
          final length = nestedViews.length;
          for (var n = 0; n < length; n++) {
            appendDomNodes(
              target,
              nestedViews[n].viewData.rootNodesOrViewContainers,
            );
          }
        }
      } else {
        target.append(unsafeCast(node));
      }
    }
  }

  /// Returns the last (as defined by a DFS - depth first search) DOM [Node].
  ///
  /// In the case where [nodesOrViewContainers] is `null` (or empty), this
  /// method returns `null`. This is a rarer case (i.e. in the case of an empty
  /// template).
  @dart2js.noInline
  static Node findLastDomNode(List<Object> nodesOrViewContainers) {
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

  /// Returns all DOM [Node]s (as defined by a DFS - depth first search).
  ///
  /// In the case where [nodesOrViewContainers] is `null`, this returns `[]`.
  static List<Node> flattenDomNodes(List<Object> nodesOrViewContainers) {
    return _flattenDomNodes([], nodesOrViewContainers);
  }

  static List<Node> _flattenDomNodes(List<Node> target, List<Object> nodes) {
    final length = nodes.length;
    for (var i = 0; i < length; i++) {
      final node = nodes[i];
      if (node is ViewContainer) {
        target.add(node.nativeElement);
        final nestedViews = node.nestedViews;
        if (nestedViews != null) {
          final length = nestedViews.length;
          for (var n = 0; n < length; n++) {
            _flattenDomNodes(
              target,
              nestedViews[n].viewData.rootNodesOrViewContainers,
            );
          }
        }
      } else {
        target.add(unsafeCast(node));
      }
    }
    return target;
  }
}
