import 'dart:html';

import 'package:meta/dart2js.dart' as dart2js;
import 'package:angular/src/utilities.dart';

import 'view_container.dart';

/// Provides a collection of [Node] and/or [ViewContainer]s and access to them.
class ViewFragment {
  final List<Object> _nodesOrViewContainers;

  // We use noInline so the constructor is not inlined into the caller, which
  // does not always work properly on non-factory constructors (i.e. essentially
  // methods).
  //
  // This will also let us make specialized constructors, such as
  // * ViewFragment.empty
  // * ViewFragment.single
  //
  // ... if that ends up being beneficial.
  @dart2js.noInline
  factory ViewFragment(List<Object> nodesOrViewContainers) {
    // Ideally we would be able to assert that this is a JSArray.
    return ViewFragment._(nodesOrViewContainers);
  }

  const ViewFragment._(this._nodesOrViewContainers);

  /// Appends all DOM [Node]s from this fragment into [target].
  @dart2js.noInline
  void appendDomNodesInto(Element target) {
    appendDomNodes(target, _nodesOrViewContainers);
  }

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
    final nodes = nodesOrViewContainers;
    final length = nodes.length;
    for (var i = 0; i < length; i++) {
      final node = nodes[i];
      if (node is ViewContainer) {
        target.append(node.nativeElement);
        final nestedViews = node.nestedViews;
        if (nestedViews != null) {
          final length = nestedViews.length;
          for (var n = 0; n < length; n++) {
            nestedViews[n].viewFragment!.appendDomNodesInto(target);
          }
        }
      } else {
        target.append(unsafeCast(node));
      }
    }
  }

  /// Returns the last (as defined by a DFS - depth first search) DOM [Node].
  @dart2js.noInline
  Node? findLastDomNode() {
    // Finds the last Node or uses the anchor node of a ViewContainer.
    final nodesOrViewContainers = _nodesOrViewContainers;
    if (nodesOrViewContainers.isNotEmpty) {
      final lastNode = nodesOrViewContainers.last;
      return lastNode is ViewContainer
          ? _findLastDomNode(lastNode)
          : unsafeCast(lastNode);
    } else {
      return null;
    }
  }

  static Node? _findLastDomNode(ViewContainer container) {
    final nestedViews = container.nestedViews;
    return nestedViews != null && nestedViews.isNotEmpty
        ? nestedViews.last.viewFragment!.findLastDomNode()
        : container.nativeElement;
  }

  /// Returns all DOM [Node]s (as defined by a DFS - depth first search).
  ///
  /// In the case where [nodesOrViewContainers] is `null`, this returns `[]`.
  @dart2js.noInline
  List<Node> flattenDomNodes() => _flattenDomNodes([], _nodesOrViewContainers);

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
              nestedViews[n].viewFragment!._nodesOrViewContainers,
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
