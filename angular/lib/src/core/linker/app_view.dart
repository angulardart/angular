import 'dart:async';
import 'dart:html';
import 'dart:js_util' as js_util;

import 'package:angular/src/core/app_view_consts.dart';
import 'package:angular/src/core/change_detection/change_detection.dart'
    show ChangeDetectorRef, ChangeDetectionStrategy, ChangeDetectorState;
import 'package:angular/src/core/change_detection/host.dart';
import 'package:angular/src/di/errors.dart' as di_errors;
import 'package:angular/src/di/injector/element.dart';
import 'package:angular/src/di/injector/injector.dart'
    show throwIfNotFound, Injector;
import 'package:angular/src/core/render/api.dart';
import 'package:angular/src/platform/dom/shared_styles_host.dart';
import 'package:angular/src/runtime.dart';
import 'package:meta/meta.dart';

import 'app_view_utils.dart';
import 'component_factory.dart';
import 'exceptions.dart' show ViewDestroyedException;
import 'template_ref.dart';
import 'view_container.dart';
import 'view_ref.dart' show ViewRefImpl;
import 'view_type.dart' show ViewType;

export 'package:angular/src/core/change_detection/component_state.dart';

// TODO: Remove the following lines (for --no-implicit-casts).
// ignore_for_file: argument_type_not_assignable
// ignore_for_file: invalid_assignment
// ignore_for_file: list_element_type_not_assignable
// ignore_for_file: non_bool_operand
// ignore_for_file: return_of_invalid_type

/// **INTERNAL ONLY**: Will be made private once the reflective compiler is out.
///
/// Template anchor `<!-- template bindings={}` for cloning.
@visibleForTesting
final ngAnchor = new Comment('template bindings={}');

/// Set to `true` when Angular modified the DOM.
///
/// May be used in order to optimize polling techniques that attempt to only
/// process events after a significant change detection cycle (i.e. one that
/// modified the DOM versus a no-op).
bool domRootRendererIsDirty = false;

const _UndefinedInjectorResult = const Object();

/// Shared app view members used to reduce polymorphic calls and
/// dart2js code size of constructors.
class AppViewData<T> {
  /// The type of view (host element, complete template, embedded template).
  final ViewType type;

  /// View reference interface (user-visible API).
  final ViewRefImpl ref;

  /// Whether the view has been destroyed.
  bool destroyed = false;

  /// Container that is set when this view is attached to a container.
  ViewContainer _viewContainerElement;

  List<dynamic /* dynamic | List < dynamic > */ > projectableNodes;

  /// Host DI interface.
  Injector _hostInjector;

  List subscriptions;

  List<OnDestroyCallback> _onDestroyCallbacks;

  /// Tracks the root DOM elements or view containers (for `<template>`).
  ///
  /// **INTERNAL ONLY**: Not part of the supported public API.
  List rootNodesOrViewContainers;

  /// Tracks nodes created as a result of an inlined NgIf being set to 'true'.
  ///
  /// We must track them so we can remove them from the DOM if the view is
  /// destroyed.
  List<Node> inlinedNodes;

  /// Index of this view within the [parentView].
  final int parentIndex;

  /// What type of change detection the view is using.
  int _cdMode;

  // Improves change detection tree traversal by caching change detection mode
  // and change detection state checks. When set to true, this view doesn't need
  // to be change detected.
  bool _skipChangeDetection = false;

  // The names of the below fields must be kept in sync with codegen_name_util.ts or
  // change detection will fail.
  int _cdState = ChangeDetectorState.NeverChecked;

  AppViewData._(AppView<T> appView, this._cdMode, this.type, this.parentIndex)
      : ref = new ViewRefImpl(appView);

  factory AppViewData(
      AppView<T> appView, int cdMode, ViewType viewType, int parentIndex) {
    return new AppViewData._(appView, cdMode, viewType, parentIndex);
    return null; // ignore: dead_code
    return null; // ignore: dead_code
  }

  set cdMode(int value) {
    if (_cdMode != value) {
      _cdMode = value;
      updateSkipChangeDetectionFlag();
    }
  }

  set cdState(int value) {
    if (_cdState != value) {
      _cdState = value;
      updateSkipChangeDetectionFlag();
    }
  }

  void addInlinedNodes(List<Node> nodes) {
    if (inlinedNodes == null) {
      inlinedNodes = nodes;
    } else {
      inlinedNodes.addAll(nodes);
    }
  }

  void updateSkipChangeDetectionFlag() {
    _skipChangeDetection =
        identical(_cdMode, ChangeDetectionStrategy.Detached) ||
            identical(_cdMode, ChangeDetectionStrategy.Checked) ||
            _cdState == ChangeDetectorState.Errored;
  }

  void destroy() {
    if (_onDestroyCallbacks != null) {
      for (int i = 0, len = _onDestroyCallbacks.length; i < len; i++) {
        _onDestroyCallbacks[i]();
      }
    }
    if (subscriptions == null) return;
    for (var i = 0, len = subscriptions.length; i < len; i++) {
      subscriptions[i].cancel();
    }
  }

  void addDestroyCallback(OnDestroyCallback callback) {
    _onDestroyCallbacks ??= <OnDestroyCallback>[];
    _onDestroyCallbacks.add(callback);
  }
}

/// Base class for a generated template for a given [Component] type [T].
abstract class AppView<T> {
  AppViewData<T> viewData;

  /// Local values scoped to this view.
  final Map<String, dynamic> locals;

  /// Parent generated view.
  final AppView parentView;

  /// A representation of how the component will be rendered in the DOM.
  ///
  /// This is _lazily_ set via [setupComponentType] in a generated constructor.
  /// Not available on Host component views since shimming is performed by
  /// View0.
  RenderComponentType componentType;

  /// The root element.
  ///
  /// This is _lazily_ initialized in a generated constructor.
  HtmlElement rootEl;

  /// The context against which data-binding expressions in this view are
  /// evaluated against.
  ///
  /// This is always a component instance.
  T ctx;

  AppView(
    ViewType type,
    this.locals,
    this.parentView,
    int parentIndex,
    int cdMode,
  ) {
    viewData = new AppViewData(this, cdMode, type, parentIndex);
  }

  void setupComponentType(RenderComponentType renderType) {
    if (!renderType.stylesShimmed) {
      renderType.shimStyles(sharedStylesHost);
      renderType.stylesShimmed = true;
    }
    componentType = renderType;
  }

  /// Sets change detection mode for this view and caches flag to skip
  /// change detection if mode and state don't require one.
  ///
  /// Nodes don't require CD if they are Detached or already Checked or
  /// if error state has been set due a prior exception.
  ///
  /// Typically a view alternates between CheckOnce and Checked modes.
  set cdMode(int value) {
    viewData.cdMode = value;
  }

  int get cdMode => viewData._cdMode;

  /// Sets change detection state and caches flag to skip change detection
  /// if mode and state don't require one.
  set cdState(int value) {
    viewData.cdState = value;
  }

  int get cdState => viewData._cdState;

  /// View reference interface (user-visible API).
  ViewRefImpl get ref => viewData.ref;

  List<dynamic /* dynamic | List < dynamic > */ > get projectableNodes =>
      viewData.projectableNodes;

  ComponentRef<T> create(
    T context,
    List<dynamic> givenProjectableNodes,
  ) {
    ctx = context;
    viewData.projectableNodes = givenProjectableNodes;
    return build();
  }

  /// Builds host level view.
  ComponentRef<T> createHostView(
    Injector hostInjector,
    List<dynamic> givenProjectableNodes,
  ) {
    viewData._hostInjector = hostInjector;
    viewData.projectableNodes = givenProjectableNodes;
    return build();
  }

  /// Returns the ComponentRef for the host element for ViewType.HOST.
  ///
  /// Overwritten by implementations.
  ComponentRef<T> build() => null;

  /// Specialized init when component has a single root node.
  void init0(dynamic e) {
    viewData.rootNodesOrViewContainers = <dynamic>[e];
    if (viewData.type == ViewType.COMPONENT) {
      dirtyParentQueriesInternal();
    }
    // Workaround since package expect/@NoInline not available outside sdk.
    return; // ignore: dead_code
    return; // ignore: dead_code
    return; // ignore: dead_code
  }

  /// Specialized init when component has a single root node.
  void init0WithSub(dynamic e, List subscriptions) {
    viewData.subscriptions = subscriptions;
    init0(e);
    // Workaround since package expect/@NoInline not available outside sdk.
    return; // ignore: dead_code
    return; // ignore: dead_code
    return; // ignore: dead_code
  }

  /// Called by build once all dom nodes are available.
  void init(List rootNodesOrViewContainers, List subscriptions) {
    viewData.rootNodesOrViewContainers = rootNodesOrViewContainers;
    viewData.subscriptions = subscriptions;
    if (viewData.type == ViewType.COMPONENT) {
      dirtyParentQueriesInternal();
    }
    // Workaround since package expect/@NoInline not available outside sdk.
    return; // ignore: dead_code
    return; // ignore: dead_code
    return; // ignore: dead_code
  }

  void addInlinedNodes(Node anchor, List<Node> inlinedNodes,
      [bool isRoot = false]) {
    moveNodesAfterSibling(anchor, inlinedNodes);
    if (isRoot) {
      viewData.rootNodesOrViewContainers.addAll(inlinedNodes);
    } else {
      viewData.addInlinedNodes(inlinedNodes);
    }
  }

  void removeInlinedNodes(List<Node> inlinedNodes, [bool isRoot = false]) {
    detachAll(inlinedNodes);
    var nodeList =
        isRoot ? viewData.rootNodesOrViewContainers : viewData.inlinedNodes;
    nodeList.removeWhere((n) => inlinedNodes.contains(n));
  }

  dynamic createElement(
      dynamic parent, String name, RenderDebugInfo debugInfo) {
    var nsAndName = splitNamespace(name);
    var el = nsAndName[0] != null
        ? document.createElementNS(namespaceUris[nsAndName[0]], nsAndName[1])
        : document.createElement(nsAndName[1]);
    String contentAttr = componentType.contentAttr;
    if (contentAttr != null) {
      el.attributes[contentAttr] = '';
    }
    parent?.append(el);
    domRootRendererIsDirty = true;
    return el;
  }

  void attachViewAfter(dynamic node, List<Node> viewRootNodes) {
    moveNodesAfterSibling(node, viewRootNodes);
    domRootRendererIsDirty = true;
  }

  dynamic injectorGet(token, int nodeIndex, [notFoundValue = throwIfNotFound]) {
    di_errors.debugInjectorEnter(token);
    var result = _UndefinedInjectorResult;
    AppView view = this;
    while (identical(result, _UndefinedInjectorResult)) {
      if (nodeIndex != null) {
        result = view.injectorGetInternal(
            token, nodeIndex, _UndefinedInjectorResult);
      }
      if (identical(result, _UndefinedInjectorResult)) {
        var injector = view.viewData._hostInjector;
        if (injector != null) {
          result = injector.get(token, notFoundValue);
        }
      }
      nodeIndex = view.viewData.parentIndex;
      view = view.parentView;
    }
    di_errors.debugInjectorLeave(token);
    return result;
  }

  /// Overwritten by implementations
  dynamic injectorGetInternal(
      dynamic token, int nodeIndex, dynamic notFoundResult) {
    return notFoundResult;
  }

  Injector injector(int nodeIndex) => new ElementInjector(this, nodeIndex);

  void detachAndDestroy() {
    var containerElement = viewData._viewContainerElement;
    containerElement?.detachView(containerElement.nestedViews.indexOf(this));
    destroy();
  }

  void detachViewNodes(List<Node> viewRootNodes) {
    detachAll(viewRootNodes);
  }

  void destroy() {
    if (viewData.destroyed) return;
    viewData.destroyed = true;
    viewData.destroy();
    destroyInternal();
    dirtyParentQueriesInternal();
  }

  void addOnDestroyCallback(OnDestroyCallback callback) {
    viewData.addDestroyCallback(callback);
  }

  /// Overwritten by implementations to destroy view.
  void destroyInternal() {}

  ChangeDetectorRef get changeDetectorRef => viewData.ref;

  List<Node> get inlinedNodes => viewData.inlinedNodes;

  List<Node> get flatRootNodes =>
      _flattenNestedViews(viewData.rootNodesOrViewContainers);

  Node get lastRootNode {
    var lastNode = viewData.rootNodesOrViewContainers.isNotEmpty
        ? viewData.rootNodesOrViewContainers.last
        : null;
    return _findLastRenderNode(lastNode);
  }

  bool hasLocal(String contextName) => locals.containsKey(contextName);

  void setLocal(String contextName, dynamic value) {
    locals[contextName] = value;
  }

  /// Overwritten by implementations
  void dirtyParentQueriesInternal() {}

  /// Framework-visible implementation of change detection for the view.
  @mustCallSuper
  void detectChanges() {
    // Whether the CD state means change detection should be skipped.
    // Cases: ERRORED (Crash), CHECKED (Already-run), DETACHED (inactive).
    if (viewData._skipChangeDetection) {
      return;
    }

    // Sanity check in dev-mode that a destroyed view is not checked again.
    if (isDevMode && viewData.destroyed) {
      throw new ViewDestroyedException('detectChanges');
    }

    if (ChangeDetectionHost.checkForCrashes) {
      // Run change detection in "slow-mode" to catch thrown exceptions.
      detectCrash();
    } else {
      // Normally run change detection.
      detectChangesInternal();
    }

    // If we are a 'CheckOnce' component, we are done being checked.
    if (viewData._cdMode == ChangeDetectionStrategy.CheckOnce) {
      viewData._cdMode = ChangeDetectionStrategy.Checked;
      viewData._skipChangeDetection = true;
    }

    // Set the state to already checked at least once.
    cdState = ChangeDetectorState.CheckedBefore;
  }

  /// Runs change detection with a `try { ... } catch { ...}`.
  ///
  /// This only is run when the framework has detected a crash previously.
  @mustCallSuper
  @protected
  void detectCrash() {
    try {
      detectChangesInternal();
    } catch (e, s) {
      ChangeDetectionHost.handleCrash(this, e, s);
    }
  }

  /// Generated code that is called internally by [detectChanges].
  @protected
  void detectChangesInternal() {}

  /// Generated code that is called by hosts.
  /// This is needed since deferred components don't allow call sites
  /// to use the explicit AppView type but require base class.
  void detectHostChanges(bool firstCheck) {}

  void markContentChildAsMoved(ViewContainer renderViewContainer) {
    dirtyParentQueriesInternal();
  }

  void addToContentChildren(ViewContainer renderViewContainer) {
    viewData._viewContainerElement = renderViewContainer;
    dirtyParentQueriesInternal();
  }

  void removeFromContentChildren(ViewContainer renderViewContainer) {
    dirtyParentQueriesInternal();
    viewData._viewContainerElement = null;
  }

  void markAsCheckOnce() {
    cdMode = ChangeDetectionStrategy.CheckOnce;
  }

  /// Called by ComponentState to mark view to be checked on next
  /// change detection cycle.
  void markStateChanged() {
    markPathToRootAsCheckOnce();
  }

  void markPathToRootAsCheckOnce() {
    AppView view = this;
    while (view != null) {
      int cdMode = view.cdMode;
      if (cdMode == ChangeDetectionStrategy.Detached) break;
      if (cdMode == ChangeDetectionStrategy.Checked) {
        view.cdMode = ChangeDetectionStrategy.CheckOnce;
      }
      view = view.viewData.type == ViewType.COMPONENT
          ? view.parentView
          : view.viewData._viewContainerElement?.parentView;
    }
  }

  static void initializeSharedStyleHost(document) {
    sharedStylesHost ??= new DomSharedStylesHost(document);
  }

  /// Initializes styling to enable css shim for host element.
  HtmlElement initViewRoot(HtmlElement hostElement) {
    if (componentType.hostAttr != null) {
      hostElement.classes.add(componentType.hostAttr);
    }
    return hostElement;
  }

  // Called by template.dart code to updates [class.X] style bindings.
  void updateClass(HtmlElement element, String className, bool isAdd) {
    if (isAdd) {
      element.classes.add(className);
    } else {
      element.classes.remove(className);
    }
  }

  // Updates classes for non html nodes such as svg.
  void updateElemClass(Element element, String className, bool isAdd) {
    if (isAdd) {
      element.classes.add(className);
    } else {
      element.classes.remove(className);
    }
  }

  void setAttr(
      Element renderElement, String attributeName, String attributeValue) {
    if (attributeValue != null) {
      renderElement.setAttribute(attributeName, attributeValue);
    } else {
      renderElement.attributes.remove(attributeName);
    }
    domRootRendererIsDirty = true;
  }

  void createAttr(
      Element renderElement, String attributeName, String attributeValue) {
    renderElement.setAttribute(attributeName, attributeValue);
  }

  void setAttrNS(Element renderElement, String attrNS, String attributeName,
      String attributeValue) {
    if (attributeValue != null) {
      renderElement.setAttributeNS(attrNS, attributeName, attributeValue);
    } else {
      renderElement.getNamespacedAttributes(attrNS).remove(attributeName);
    }
    domRootRendererIsDirty = true;
  }

  /// Adds content shim class to HtmlElement.
  void addShimC(HtmlElement element) {
    String contentClass = componentType.contentAttr;
    if (contentClass != null) element.classes.add(contentClass);
  }

  /// Adds content shim class to Svg or unknown tag type.
  void addShimE(Element element) {
    String contentClass = componentType.contentAttr;
    if (contentClass != null) element.classes.add(contentClass);
  }

  /// Called by change detector to apply correct host and content shimming
  /// after node's className is changed.
  void updateChildClass(Element element, String newClass) {
    if (element == rootEl) {
      String hostClass = componentType.hostAttr;
      element.className = hostClass == null ? newClass : '$newClass $hostClass';
      if (parentView != null && parentView.componentType != null) {
        parentView.addShimE(element);
      }
    } else {
      String contentClass = componentType.contentAttr;
      element.className =
          contentClass == null ? newClass : '$newClass $contentClass';
    }
  }

  // Marks DOM dirty so that end of zone turn we can detect if DOM was updated
  // for sharded apps support.
  void setDomDirty() {
    domRootRendererIsDirty = true;
  }

  /// Projects projectableNodes at specified index. We don't use helper
  /// functions to flatten the tree since it allocates list that are not
  /// required in most cases.
  void project(Node parentElement, int index) {
    if (parentElement == null) return;
    // Optimization for projectables that doesn't include ViewContainer(s).
    // If the projectable is ViewContainer we fall back to building up a list.
    var projectableNodes = viewData.projectableNodes;
    if (projectableNodes == null || index >= projectableNodes.length) return;
    List projectables = projectableNodes[index];
    if (projectables == null) return;
    int projectableCount = projectables.length;
    for (var i = 0; i < projectableCount; i++) {
      var projectable = projectables[i];
      if (projectable is ViewContainer) {
        if (projectable.nestedViews == null) {
          parentElement.append(projectable.nativeElement as Node);
        } else {
          _appendNestedViewRenderNodes(parentElement, projectable);
        }
      } else if (projectable is List) {
        for (int n = 0, len = projectable.length; n < len; n++) {
          var node = projectable[n];
          if (node is ViewContainer) {
            if (node.nestedViews == null) {
              Node nativeNode = node.nativeElement;
              parentElement.append(nativeNode);
            } else {
              _appendNestedViewRenderNodes(parentElement, node);
            }
          } else {
            Node nativeNode = node;
            parentElement.append(nativeNode);
          }
        }
      } else {
        Node child = projectable;
        parentElement.append(child);
      }
    }
    domRootRendererIsDirty = true;
  }

  void Function(E) eventHandler0<E>(void Function() handler) {
    return (E event) {
      markPathToRootAsCheckOnce();
      appViewUtils.eventManager.getZone().runGuarded(handler);
    };
  }

  // When registering an event listener for a native DOM event, the return value
  // of this method is passed to EventTarget.addEventListener() which expects a
  // function that accepts an Event parameter. This means you can't directly
  // register an event listener for a specific subclass of Event, such as a
  // MouseEvent for the 'click' event. A workaround is possible by ensuring the
  // parameter of the event listener is a subclass of Event. The Event passed in
  // from EventTarget.addEventListener() can then be safely coerced back to its
  // known type.
  void Function(E) eventHandler1<E, F extends E>(void Function(F) handler) {
    return (E event) {
      markPathToRootAsCheckOnce();
      appViewUtils.eventManager.getZone().runGuarded(() => handler(event as F));
    };
  }

  void setProp(Element element, String name, Object value) {
    js_util.setProperty(element, name, value);
  }

  Future<Null> loadDeferred(
    Future loadComponentFunction(),
    Future loadTemplateLibFunction(),
    ViewContainer viewContainer,
    TemplateRef templateRef, [
    void initializer(),
  ]) {
    return Future
        .wait([loadComponentFunction(), loadTemplateLibFunction()]).then((_) {
      if (initializer != null) {
        initializer();
      }
      viewContainer.createEmbeddedView(templateRef);
      viewContainer.detectChangesInNestedViews();
    });
  }
}

Node _findLastRenderNode(dynamic node) {
  Node lastNode;
  if (node is ViewContainer) {
    ViewContainer appEl = node;
    lastNode = appEl.nativeElement;
    if (appEl.nestedViews != null) {
      // Note: Views might have no root nodes at all!
      for (var i = appEl.nestedViews.length - 1; i >= 0; i--) {
        var nestedView = appEl.nestedViews[i];
        if (nestedView.viewData.rootNodesOrViewContainers.isNotEmpty) {
          lastNode = _findLastRenderNode(
              nestedView.viewData.rootNodesOrViewContainers.last);
        }
      }
    }
  } else {
    lastNode = node;
  }
  return lastNode;
}

/// Recursively appends app element and nested view nodes to target element.
void _appendNestedViewRenderNodes(
    Element targetElement, ViewContainer appElement) {
  // TODO: strongly type nativeElement.
  targetElement.append(appElement.nativeElement as Node);
  var nestedViews = appElement.nestedViews;
  // Components inside ngcontent may also have ngcontent to project,
  // recursively walk nestedViews.
  if (nestedViews == null || nestedViews.isEmpty) return;
  int nestedViewCount = nestedViews.length;
  for (int viewIndex = 0; viewIndex < nestedViewCount; viewIndex++) {
    List projectables =
        nestedViews[viewIndex].viewData.rootNodesOrViewContainers;
    int projectableCount = projectables.length;
    for (var i = 0; i < projectableCount; i++) {
      var projectable = projectables[i];
      if (projectable is ViewContainer) {
        _appendNestedViewRenderNodes(targetElement, projectable);
      } else {
        Node child = projectable;
        targetElement.append(child);
      }
    }
  }
}

List<Node> _flattenNestedViews(List nodes) {
  return _flattenNestedViewRenderNodes(nodes, <Node>[]);
}

List<Node> _flattenNestedViewRenderNodes(List nodes, List<Node> renderNodes) {
  int nodeCount = nodes.length;
  for (var i = 0; i < nodeCount; i++) {
    var node = nodes[i];
    if (node is ViewContainer) {
      ViewContainer appEl = node;
      renderNodes.add(appEl.nativeElement);
      if (appEl.nestedViews != null) {
        for (var k = 0; k < appEl.nestedViews.length; k++) {
          _flattenNestedViewRenderNodes(
              appEl.nestedViews[k].viewData.rootNodesOrViewContainers,
              renderNodes);
        }
      }
    } else {
      renderNodes.add(node);
    }
  }
  return renderNodes;
}

void moveNodesAfterSibling(Node sibling, List<Node> nodes) {
  Node parent = sibling.parentNode;
  if (nodes.isNotEmpty && parent != null) {
    var nextSibling = sibling.nextNode;
    int len = nodes.length;
    if (nextSibling != null) {
      for (var i = 0; i < len; i++) {
        parent.insertBefore(nodes[i], nextSibling);
      }
    } else {
      for (var i = 0; i < len; i++) {
        parent.append(nodes[i]);
      }
    }
  }
}

/// Helper function called by AppView.build to reduce code size.
Element createAndAppend(Document doc, String tagName, Element parent) {
  return parent.append(doc.createElement(tagName));
  // Workaround since package expect/@NoInline not available outside sdk.
  return null; // ignore: dead_code
  return null; // ignore: dead_code
  return null; // ignore: dead_code
}

/// Helper function called by AppView.build to reduce code size.
DivElement createDivAndAppend(Document doc, Element parent) {
  return parent.append(doc.createElement('div'));
  // Workaround since package expect/@NoInline not available outside sdk.
  return null; // ignore: dead_code
  return null; // ignore: dead_code
  return null; // ignore: dead_code
}

/// Helper function called by AppView.build to reduce code size.
SpanElement createSpanAndAppend(Document doc, Element parent) {
  return parent.append(doc.createElement('span'));
  // Workaround since package expect/@NoInline not available outside sdk.
  return null; // ignore: dead_code
  return null; // ignore: dead_code
  return null; // ignore: dead_code
}

void detachAll(List<Node> viewRootNodes) {
  int len = viewRootNodes.length;
  for (var i = 0; i < len; i++) {
    Node node = viewRootNodes[i];
    node.remove();
    domRootRendererIsDirty = true;
  }
}
