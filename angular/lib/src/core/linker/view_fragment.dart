import 'dart:html';

import 'package:angular/src/runtime.dart';
import 'package:meta/dart2js.dart' as dart2js;

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
            nestedViews[n].viewFragment.appendDomNodesInto(target);
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
  Node findLastDomNode() {
    // Finds the last Node or uses the anchor node of a ViewContainer.
    final nodes = _nodesOrViewContainers;
    for (var i = nodes.length - 1; i >= 0; i--) {
      final node = nodes[i];
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
        return nestedViews[i].viewFragment.findLastDomNode();
      }
    }

    return container.nativeElement;
  }

  /// Returns all DOM [Node]s (as defined by a DFS - depth first search).
  ///
  /// In the case where [nodesOrViewContainers] is `null`, this returns `[]`.
  @dart2js.noInline
  List<Node> flattenDomNodes() {
    return _flattenDomNodes([], _nodesOrViewContainers);
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
              nestedViews[n].viewFragment._nodesOrViewContainers,
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
