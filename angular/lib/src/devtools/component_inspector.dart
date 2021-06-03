import 'dart:async';
import 'dart:convert' show json;
import 'dart:developer';
import 'dart:html';

import 'package:meta/meta.dart';
import 'package:stream_transform/stream_transform.dart';

import '../core/application_ref.dart';
import '../core/linker/views/component_view.dart';
import '../core/linker/views/view.dart';
import 'reference_counter.dart';

/// A service for inspecting components via service protocol extensions.
class ComponentInspector {
  /// The current [ComponentInspector].
  static final instance = ComponentInspector._();

  ComponentInspector._() {
    _registerServiceExtensions();

    // Indicates that all service extensions have been registered. Any external
    // tool intending to call service extensions should ensure this event has
    // been posted.
    // TODO(b/158602712): register extension for querying this state.
    postEvent('angular.initialized', {});
  }

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

  /// Additional locations in the DOM to search for components.
  final _contentRoots = <Element>[];

  ApplicationRef? _applicationRef;

  /// Designates an [applicationRef] to inspect.
  ///
  /// This only supports inspecting one [ApplicationRef] at a time. The caller
  /// must invoke [ApplicationRef.dispose] on the [applicationRef] before
  /// inspecting another.
  void inspect(ApplicationRef applicationRef) {
    if (_applicationRef != null) {
      window.console.error('''
AngularDart DevTools does not yet support apps with multiple runApp()
invocations. Please contact dart-framework-eng@ if you encounter this error.
''');
      return;
    }

    // Post an event for each zone turn in the app, but no more frequently
    // than this interval. Despite wanting to signal when the zone turn is
    // done, we post this event at the *start* of the zone turn because
    // incoming service extension methods are handled at the end of the zone
    // turn. This allows clients to respond to this event and receive
    // updates at the end of the zone turn more quickly than if we posted
    // the event at the end of the zone turn.
    const updateInterval = Duration(milliseconds: 500);
    final onTurnStartSubscription = applicationRef.zone.onTurnStart
        .throttle(updateInterval, trailing: true)
        .listen((_) {
      postEvent('angular.update', {});
    });

    _applicationRef = applicationRef
      ..registerDisposeListener(() {
        onTurnStartSubscription.cancel();
        _dispose();
      });
  }

  /// Frees all object references held by this service.
  void _dispose() {
    _applicationRef = null;
    _referenceCounter.dispose();
    _contentRoots.clear();
  }

  /// Frees all object references held by a group.
  ///
  /// The objects may be kept alive by references from another group.
  void _disposeGroup(String groupName) {
    _referenceCounter.disposeGroup(groupName);
  }

  /// Registers service protocol extensions for inspecting components.
  void _registerServiceExtensions() {
    _registerObjectGroupServiceExtension('disposeGroup', _disposeGroup);
    _registerObjectGroupServiceExtension('getComponents', getComponents);
  }

  /// Registers a service extension [handler] that manages a group of objects.
  ///
  /// The [handler] takes a single parameter, `groupName`, that specifies the
  /// group used to manage the life cycle of any object references returned in
  /// the response. Any object references created for a group will be retained
  /// until that group is explicitly disposed.
  ///
  /// The service extension is registered as "ext.angular.[name]".
  void _registerObjectGroupServiceExtension(
    String name,
    FutureOr<Object?> Function(String groupName) handler,
  ) {
    _registerServiceExtension(name, (parameters) {
      return handler(parameters['groupName']!);
    });
  }

  /// Registers a service extension [handler] as "ext.angular.[name]".
  void _registerServiceExtension(
    String name,
    FutureOr<Object?> Function(Map<String, String> args) handler,
  ) {
    final method = 'ext.angular.$name';
    registerExtension(method, (_, args) {
      final completer = Completer<String>();
      final applicationRef = _applicationRef;

      if (applicationRef != null) {
        // Wait until the app is stable to invoke the handler. This ensures that
        // any state collected by the handler is coherent with the latest change
        // detection pass. Note this does not trigger another change detection
        // pass because it's called from outside the Angular zone.
        applicationRef.zone.runAfterChangesObserved(() async {
          try {
            final result = await handler(args);
            final encoded = json.encode({'result': result});
            completer.complete(encoded);
          } catch (exception, stackTrace) {
            completer.completeError(exception, stackTrace);
          }
        });
      } else {
        completer.completeError('The inspected app was disposed');
      }

      return completer.future.then((result) {
        return ServiceExtensionResponse.result(result);
      }, onError: (Object exception, StackTrace stackTrace) {
        final context =
            'The following exception was thrown while handling the service '
            'extension "$method"';
        // This could be null if the error was thrown because there's no active
        // application.
        applicationRef?.exceptionHandler('$context:\n$exception', stackTrace);
        return ServiceExtensionResponse.error(
          ServiceExtensionResponse.extensionError,
          json.encode({
            'exception': exception.toString(),
            'stackTrace': stackTrace.toString(),
          }),
        );
      });
    });
  }

  /// Registers a component [view] to be inspected by this service.
  ///
  /// This must be called after [view] has initialized its root element.
  void registerComponentView(ComponentView<Object> view) {
    _elementToComponentView[view.rootElement] = view;
  }

  /// Registers [element] as a location to search for components.
  void registerContentRoot(Element element) {
    for (var i = _contentRoots.length - 1; i >= 0; i--) {
      final root = _contentRoots[i];
      if (root.contains(element)) {
        /// The element is already visited when searching for components.
        return;
      } else if (element.contains(root)) {
        /// Remove any existing content roots contained by the new one.
        _contentRoots.removeAt(i);
      }
    }
    _contentRoots.add(element);
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

  /// Returns a JSON representation of the component tree.
  ///
  /// All components referenced in the JSON representation are kept alive at
  /// least until [groupName] is disposed.
  @visibleForTesting
  List<Map<String, Object>> getComponents(String groupName) {
    final json = <Map<String, Object>>[];
    for (final element in _contentRoots) {
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
      'name': view.debugComponentTypeName,
      'id': _referenceCounter.toId(view, groupName),
    };
  }
}
