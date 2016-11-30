import 'dart:html';

import 'package:angular2/src/core/change_detection/change_detection.dart'
    show ChangeDetectorRef, ChangeDetectionStrategy, ChangeDetectorState;
import 'package:angular2/src/core/di.dart' show Injector;
import 'package:angular2/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular2/src/core/render/api.dart';
import 'package:angular2/src/platform/dom/shared_styles_host.dart';

import 'view_container.dart';
import 'app_view_utils.dart';
import 'element_injector.dart' show ElementInjector;
import 'exceptions.dart' show ViewDestroyedException;
import 'view_ref.dart' show ViewRefImpl;
import 'view_type.dart' show ViewType;
import 'dart:js_util' as js_util;

export 'package:angular2/src/core/change_detection/component_state.dart';

const EMPTY_CONTEXT = const Object();

bool domRootRendererIsDirty = false;

/// Cost of making objects: http://jsperf.com/instantiate-size-of-object
abstract class AppView<T> {
  dynamic clazz;
  RenderComponentType componentType;
  ViewType type;
  Map<String, dynamic> locals;
  Injector parentInjector;
  ViewContainer declarationViewContainer;
  ChangeDetectionStrategy _cdMode;
  // Improves change detection tree traversal by caching change detection mode
  // and change detection state checks. When set to true, this view doesn't need
  // to be change detected.
  bool _skipChangeDetection = false;
  ViewRefImpl ref;
  List rootNodesOrViewContainers;
  List allNodes;
  final List<OnDestroyCallback> _onDestroyCallbacks = <OnDestroyCallback>[];
  List subscriptions;
  List<AppView> contentChildren = [];
  List<AppView> viewChildren = [];
  AppView renderParent;
  ViewContainer viewContainerElement;

  // The names of the below fields must be kept in sync with codegen_name_util.ts or
  // change detection will fail.
  ChangeDetectorState _cdState = ChangeDetectorState.NeverChecked;

  /// The context against which data-binding expressions in this view are
  /// evaluated against.
  ///
  /// This is always a component instance.
  T ctx;
  List<dynamic /* dynamic | List < dynamic > */ > projectableNodes;
  bool destroyed = false;
  bool _hasExternalHostElement;
  AppView(this.clazz, this.componentType, this.type, this.locals,
      this.parentInjector, this.declarationViewContainer, this._cdMode) {
    ref = new ViewRefImpl(this);
    sharedStylesHost ??= new DomSharedStylesHost(document);
    if (!componentType.stylesShimmed) {
      componentType.shimStyles(sharedStylesHost);
      componentType.stylesShimmed = true;
    }
  }

  /// Sets change detection mode for this view and caches flag to skip
  /// change detection if mode and state don't require one.
  ///
  /// Nodes don't require CD if they are Detached or already Checked or
  /// if error state has been set due a prior exception.
  ///
  /// Typically a view alternates between CheckOnce and Checked modes.
  set cdMode(ChangeDetectionStrategy value) {
    if (_cdMode != value) {
      _cdMode = value;
      _updateSkipChangeDetectionFlag();
    }
  }

  ChangeDetectionStrategy get cdMode => _cdMode;

  /// Sets change detection state and caches flag to skip change detection
  /// if mode and state don't require one.
  set cdState(ChangeDetectorState value) {
    if (_cdState != value) {
      _cdState = value;
      _updateSkipChangeDetectionFlag();
    }
  }

  ChangeDetectorState get cdState => _cdState;

  void _updateSkipChangeDetectionFlag() {
    _skipChangeDetection =
        identical(_cdMode, ChangeDetectionStrategy.Detached) ||
            identical(_cdMode, ChangeDetectionStrategy.Checked) ||
            identical(_cdState, ChangeDetectorState.Errored);
  }

  ViewContainer create(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | Node */ rootSelectorOrNode) {
    T context;
    var projectableNodes;
    switch (this.type) {
      case ViewType.COMPONENT:
        context = declarationViewContainer.component as T;
        projectableNodes = ensureSlotCount(
            givenProjectableNodes, this.componentType.slotCount);
        break;
      case ViewType.EMBEDDED:
        return createEmbedded(givenProjectableNodes, rootSelectorOrNode);
      case ViewType.HOST:
        return createHost(givenProjectableNodes, rootSelectorOrNode);
    }
    this._hasExternalHostElement = rootSelectorOrNode != null;
    this.ctx = context;
    this.projectableNodes = projectableNodes;
    return this.createInternal(rootSelectorOrNode);
  }

  /// Builds a host view.
  ViewContainer createHost(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | Node */ rootSelectorOrNode) {
    assert(type == ViewType.HOST);
    ctx = null;
    // Note: Don't ensure the slot count for the projectableNodes as
    // we store them only for the contained component view (which will
    // later check the slot count...)
    projectableNodes = givenProjectableNodes;
    _hasExternalHostElement = rootSelectorOrNode != null;
    return createInternal(rootSelectorOrNode);
  }

  /// Builds a nested embedded view.
  ViewContainer createEmbedded(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | Node */ rootSelectorOrNode) {
    projectableNodes = declarationViewContainer.parentView.projectableNodes;
    _hasExternalHostElement = rootSelectorOrNode != null;
    ctx = declarationViewContainer.parentView.ctx as T;
    return createInternal(rootSelectorOrNode);
  }

  /// Builds a component view.
  ViewContainer createComp(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | Node */ rootSelectorOrNode) {
    projectableNodes =
        ensureSlotCount(givenProjectableNodes, componentType.slotCount);
    _hasExternalHostElement = rootSelectorOrNode != null;
    ctx = declarationViewContainer.component as T;
    return createInternal(rootSelectorOrNode);
  }

  /// Returns the ViewContainer for the host element for ViewType.HOST.
  ///
  /// Overwritten by implementations.
  ViewContainer createInternal(
          dynamic /* String | Node */ rootSelectorOrNode) =>
      null;

  /// Called by createInternal once all dom nodes are available.
  void init(List rootNodesOrViewContainers, List allNodes, List subscriptions) {
    this.rootNodesOrViewContainers = rootNodesOrViewContainers;
    this.allNodes = allNodes;
    this.subscriptions = subscriptions;
    if (type == ViewType.COMPONENT) {
      // Note: the render nodes have been attached to their host element
      // in the ViewFactory already.
      declarationViewContainer.parentView.viewChildren.add(this);
      dirtyParentQueriesInternal();
    }
  }

  dynamic selectOrCreateHostElement(String elementName,
      dynamic /* String | Node */ rootSelectorOrNode, debugCtx) {
    var hostElement;
    if (type == ViewType.COMPONENT || type == ViewType.HOST) {
      if (rootSelectorOrNode != null) {
        hostElement = selectRootElement(rootSelectorOrNode, debugCtx);
      } else {
        hostElement = createElement(null, elementName, debugCtx);
      }
    } else {
      var target = declarationViewContainer.parentView;
      if (rootSelectorOrNode != null) {
        hostElement = target.selectRootElement(rootSelectorOrNode, debugCtx);
      } else {
        hostElement = target.createElement(null, elementName, debugCtx);
      }
    }
    return hostElement;
  }

  dynamic selectRootElement(
      dynamic /* String | Node */ selectorOrNode, RenderDebugInfo debugInfo) {
    Node el;
    if (selectorOrNode is String) {
      el = querySelector(selectorOrNode);
      if (el == null) {
        throw new Exception(
            'The selector "${selectorOrNode}" did not match any elements');
      }
    } else {
      el = selectorOrNode;
    }
    el.nodes = [];
    return el;
  }

  dynamic createElement(
      dynamic parent, String name, RenderDebugInfo debugInfo) {
    var nsAndName = splitNamespace(name);
    var el = nsAndName[0] != null
        ? document.createElementNS(NAMESPACE_URIS[nsAndName[0]], nsAndName[1])
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

  dynamic injectorGet(dynamic token, int nodeIndex, dynamic notFoundResult) {
    return this.injectorGetInternal(token, nodeIndex, notFoundResult);
  }

  /// Overwritten by implementations
  dynamic injectorGetInternal(
      dynamic token, int nodeIndex, dynamic notFoundResult) {
    return notFoundResult;
  }

  Injector injector(int nodeIndex) {
    if (nodeIndex == null) {
      return parentInjector;
    }
    return new ElementInjector(this, nodeIndex);
  }

  void destroy() {
    if (_hasExternalHostElement) {
      detachViewNodes(flatRootNodes);
    } else {
      viewContainerElement
          ?.detachView(viewContainerElement.nestedViews.indexOf(this));
    }
    _destroyRecurse();
  }

  void detachViewNodes(List<dynamic> viewRootNodes) {
    int len = viewRootNodes.length;
    for (var i = 0; i < len; i++) {
      var node = viewRootNodes[i];
      node.remove();
      domRootRendererIsDirty = true;
    }
  }

  void _destroyRecurse() {
    if (destroyed) {
      return;
    }
    var children = contentChildren;
    int length = children.length;
    for (var i = 0; i < length; i++) {
      children[i]._destroyRecurse();
    }
    children = viewChildren;
    int viewChildCount = viewChildren.length;
    for (var i = 0; i < viewChildCount; i++) {
      children[i]._destroyRecurse();
    }
    destroyLocal();
    destroyed = true;
  }

  void destroyLocal() {
    var hostElement = type == ViewType.COMPONENT
        ? declarationViewContainer.nativeElement
        : null;
    for (int i = 0, len = _onDestroyCallbacks.length; i < len; i++) {
      _onDestroyCallbacks[i]();
    }
    for (var i = 0, len = subscriptions.length; i < len; i++) {
      this.subscriptions[i].cancel();
    }
    destroyInternal();
    dirtyParentQueriesInternal();
    destroyViewNodes(hostElement, allNodes);
  }

  void destroyViewNodes(dynamic hostElement, List<dynamic> viewAllNodes) {
    if (componentType.encapsulation == ViewEncapsulation.Native &&
        hostElement != null) {
      sharedStylesHost.removeHost(hostElement.shadowRoot);
      domRootRendererIsDirty = true;
    }
  }

  void addOnDestroyCallback(OnDestroyCallback callback) {
    _onDestroyCallbacks.add(callback);
  }

  /// Overwritten by implementations to destroy view.
  void destroyInternal() {}

  ChangeDetectorRef get changeDetectorRef => ref;

  AppView<dynamic> get parent => declarationViewContainer?.parentView;

  List<Node> get flatRootNodes =>
      _flattenNestedViews(rootNodesOrViewContainers);

  Node get lastRootNode {
    var lastNode = rootNodesOrViewContainers.isNotEmpty
        ? rootNodesOrViewContainers.last
        : null;
    return _findLastRenderNode(lastNode);
  }

  // TODO: remove when all tests use codegen=debug.
  void dbgElm(element, num nodeIndex, num rowNum, num colNum) {}

  bool hasLocal(String contextName) => locals.containsKey(contextName);

  void setLocal(String contextName, dynamic value) {
    locals[contextName] = value;
  }

  /// Overwritten by implementations
  void dirtyParentQueriesInternal() {}

  void detectChanges() {
    if (_skipChangeDetection) return;
    if (destroyed) throwDestroyedError('detectChanges');

    detectChangesInternal();
    if (_cdMode == ChangeDetectionStrategy.CheckOnce) {
      _cdMode = ChangeDetectionStrategy.Checked;
      _skipChangeDetection = true;
    }
    cdState = ChangeDetectorState.CheckedBefore;
  }

  /// Overwritten by implementations
  void detectChangesInternal() {
    detectContentChildrenChanges();
    detectViewChildrenChanges();
  }

  void detectContentChildrenChanges() {
    for (var i = 0, length = contentChildren.length; i < length; ++i) {
      contentChildren[i].detectChanges();
    }
  }

  void detectViewChildrenChanges() {
    for (var i = 0, len = viewChildren.length; i < len; ++i) {
      viewChildren[i].detectChanges();
    }
  }

  void markContentChildAsMoved(ViewContainer renderViewContainer) {
    dirtyParentQueriesInternal();
  }

  void addToContentChildren(ViewContainer renderViewContainer) {
    renderViewContainer.parentView.contentChildren.add(this);
    viewContainerElement = renderViewContainer;
    dirtyParentQueriesInternal();
  }

  void removeFromContentChildren(ViewContainer renderViewContainer) {
    renderViewContainer.parentView.contentChildren.remove(this);
    dirtyParentQueriesInternal();
    viewContainerElement = null;
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
      ChangeDetectionStrategy cdMode = view.cdMode;
      if (cdMode == ChangeDetectionStrategy.Detached) break;
      if (cdMode == ChangeDetectionStrategy.Checked) {
        view.cdMode = ChangeDetectionStrategy.CheckOnce;
      }
      var parentEl = view.type == ViewType.COMPONENT
          ? view.declarationViewContainer
          : view.viewContainerElement;
      view = parentEl?.parentView;
    }
  }

  // Used to get around strong mode error due to loosely typed
  // subscription handlers.
  /*<R>*/ evt/*<E,R>*/(/*<R>*/ cb(/*<E>*/ e)) {
    return cb;
  }

  void throwDestroyedError(String details) {
    throw new ViewDestroyedException(details);
  }

  static void initializeSharedStyleHost(document) {
    sharedStylesHost ??= new DomSharedStylesHost(document);
  }

  // Returns content attribute to add to elements for css encapsulation.
  String get shimCAttr => componentType.contentAttr;

  /// Initializes styling to enable css shim for host element.
  Element initViewRoot(dynamic hostElement) {
    assert(componentType.encapsulation != ViewEncapsulation.Native);
    if (componentType.hostAttr != null) {
      Element host = hostElement;
      host.attributes[componentType.hostAttr] = '';
    }
    return hostElement;
  }

  /// Creates native shadowdom root and initializes styles.
  ShadowRoot createViewShadowRoot(dynamic hostElement) {
    assert(componentType.encapsulation == ViewEncapsulation.Native);
    var nodesParent;
    Element host = hostElement;
    nodesParent = host.createShadowRoot();
    sharedStylesHost.addHost(nodesParent);
    List<String> styles = componentType.styles;
    int styleCount = styles.length;
    for (var i = 0; i < styleCount; i++) {
      StyleElement style = sharedStylesHost.createStyleElement(styles[i]);
      nodesParent.append(style);
    }
    return nodesParent;
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

  // Marks DOM dirty so that end of zone turn we can detect if DOM was updated
  // for sharded apps support.
  void setDomDirty() {
    domRootRendererIsDirty = true;
  }

  /// Projects projectableNodes at specified index. We don't use helper
  /// functions to flatten the tree since it allocates list that are not
  /// required in most cases.
  void project(Element parentElement, int index) {
    if (parentElement == null) return;
    // Optimization for projectables that doesn't include ViewContainer(s).
    // If the projectable is ViewContainer we fall back to building up a list.
    List projectables = projectableNodes[index];
    int projectableCount = projectables.length;
    for (var i = 0; i < projectableCount; i++) {
      var projectable = projectables[i];
      if (projectable is ViewContainer) {
        if (projectable.nestedViews == null) {
          parentElement.append(projectable.nativeElement as Node);
        } else {
          _appendNestedViewRenderNodes(parentElement, projectable);
        }
      } else {
        Node child = projectable;
        parentElement.append(child);
      }
    }
    domRootRendererIsDirty = true;
  }

  Function listen(dynamic renderElement, String name, Function callback) {
    return appViewUtils.eventManager.addEventListener(renderElement, name,
        (Event event) {
      var result = callback(event);
      if (identical(result, false)) {
        event.preventDefault();
      }
    });
  }

  void setProp(Element element, String name, Object value) {
    js_util.setProperty(element, name, value);
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
        if (nestedView.rootNodesOrViewContainers.isNotEmpty) {
          lastNode =
              _findLastRenderNode(nestedView.rootNodesOrViewContainers.last);
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
    List projectables = nestedViews[viewIndex].rootNodesOrViewContainers;
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
              appEl.nestedViews[k].rootNodesOrViewContainers, renderNodes);
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

/// TODO(ferhat): Remove once dynamic(s) are changed in codegen and class.
/// This prevents unused import error in dart_analyzed_library build.
Element _temporaryTodo;
