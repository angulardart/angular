import 'dart:html';

import 'package:meta/meta.dart';

import '../core/app.dart';
import '../core/linker/views/component_view.dart';
import '../core/linker/views/view.dart';
import 'reference_counter.dart';
import 'register_service_extension.dart';

/// A service for inspecting components via service protocol extensions.
class ComponentInspector {
  /// The current [ComponentInspector].
  static final instance = ComponentInspector._();

  ComponentInspector._();

  /// Maps a component instance to its bound inputs.
  ///
  /// A component's inputs are mapped from template name to last bound value. An
  /// input that has not yet been set by the parent view, meaning the bound
  /// expression has never produced a non-null value, will not be present in the
  /// map. Consequently, unused inputs will never appear in the map.
  final _componentToInputs = Expando<Map<String, Object?>>();

  /// Maps a [ComponentView.rootElement] to its [ComponentView].
  ///
  /// The [View] model isn't well-suited for traversal, primarily because view
  /// children are stored in generated fields. This means there's no generalized
  /// mechanism for traversing the component tree. Methods such as [View.build]
  /// and [View.detectChangesInternal] rely on generated instructions to
  /// recursively traverse the component tree.
  ///
  /// Rather than relying on more code generation to construct the component
  /// tree, this mapping enables its construction via walking the DOM. This is
  /// also a convenient way to collect components in document order - the order
  /// in which they appear - as opposed to the order in which they're
  /// constructed.  This is particularly important for projected content and
  /// transplanted embedded views whose location in the DOM may not correspond
  /// to where they were constructed.
  final _elementToComponentView = Expando<ComponentView<Object>>();

  /// Used to retain [ComponentView] instances between requests.
  final _referenceCounter = ReferenceCounter<ComponentView<Object>>();

  /// Frees all object references held by this service.
  void dispose() {
    _referenceCounter.dispose();
  }

  /// Frees all object references held by a group.
  ///
  /// The objects may be kept alive by references from another group.
  void _disposeGroup(String groupName) {
    _referenceCounter.disposeGroup(groupName);
  }

  /// Registers service protocol extensions for inspecting components.
  void registerServiceExtensions() {
    registerObjectGroupServiceExtension('disposeGroup', _disposeGroup);
    registerObjectGroupServiceExtension('getComponents', _getComponents);
  }

  /// Registers a component [view] to be inspected by this service.
  ///
  /// This must be called after [view] has initialized its root element.
  void registerComponentView(ComponentView<Object> view) {
    _elementToComponentView[view.rootElement] = view;
  }

  /// Records the latest [value] assigned to input [name] on [component].
  void recordInput(Object component, String name, Object? value) {
    final inputs = _componentToInputs[component] ??= {};
    inputs[name] = value;
  }

  /// Returns the root element of the component for [id].
  HtmlElement getComponentElement(int id) {
    final componentView = _referenceCounter.toObject(id);
    return componentView.rootElement;
  }

  /// Returns the [id] of the component that rendered [node].
  ///
  /// The [groupName] should be the same one passed to the latest
  /// [getComponents] call.
  ///
  /// Returns `-1` if [node] has no corresponding component.
  int getComponentIdForNode(Node node, String groupName) {
    Node? current = node;
    while (current != null) {
      final componentView = _elementToComponentView[current];
      if (componentView != null) {
        return _referenceCounter.toId(componentView, groupName);
      }
      current = current.parent;
    }
    return -1;
  }

  /// Returns the inputs bound to a component as a map from name to value.
  ///
  /// The component is identified using the [id] obtained from [getComponents].
  /// Returns an empty map if no inputs have been set on the component.
  Map<String, Object?> getComponentInputs(int id) {
    final componentView = _referenceCounter.toObject(id);
    final component = componentView.ctx;
    return _componentToInputs[component] ?? {};
  }

  /// A public version of [_getComponents] for testing.
  ///
  /// This is used for testing without a service protocol extension.
  @visibleForTesting
  List<Map<String, Object>> getComponents(String groupName) {
    return _getComponents(groupName);
  }

  /// Returns a JSON representation of the component tree.
  ///
  /// All components referenced in the JSON representation are kept alive at
  /// least until [groupName] is disposed.
  List<Map<String, Object>> _getComponents(String groupName) {
    final json = <Map<String, Object>>[];
    for (final element in App.instance.rootElements) {
      final treeWalker = TreeWalker(element, NodeFilter.SHOW_ELEMENT);
      _collectJson(treeWalker, groupName, json);
    }
    return json;
  }

  /// Uses [treeWalker] to populate [result] with the component tree.
  ///
  /// The [result] is a recursive structure where each element is a JSON object
  /// describing the component and its children in document order.
  ///
  /// See [_elementToComponentView] regarding why the component tree is
  /// collected by traversing the DOM.
  void _collectJson(
    TreeWalker treeWalker,
    String groupName,
    List<Map<String, Object>> result,
  ) {
    final currentNode = treeWalker.currentNode;
    final componentView = _elementToComponentView[currentNode];
    final children = componentView != null ? <Map<String, Object>>[] : result;
    for (var node = treeWalker.firstChild();
        node != null;
        node = treeWalker.nextSibling()) {
      _collectJson(treeWalker, groupName, children);
    }
    if (componentView != null) {
      final json = _toJson(componentView, groupName);
      // Only include children if they exits. This keeps the JSON representation
      // lighter by avoiding empty collections.
      if (children.isNotEmpty) {
        json['children'] = children;
      }
      result.add(json);
    }
    treeWalker.currentNode = currentNode;
  }

  /// Returns a JSON representation of the [view]'s component.
  Map<String, Object> _toJson(ComponentView<Object> view, String groupName) {
    return {
      'name': view.ctx.runtimeType.toString(),
      'id': _referenceCounter.toId(view, groupName),
    };
  }
}
