import 'dart:html';

import 'package:angular2/src/core/change_detection/change_detection.dart'
    show ChangeDetectorRef, ChangeDetectionStrategy, ChangeDetectorState;
import 'package:angular2/src/core/di.dart' show Injector;
import 'package:angular2/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular2/src/core/render/api.dart';
import 'package:angular2/src/platform/dom/dom_renderer.dart'
    show DomRootRenderer;
import 'package:angular2/src/platform/dom/shared_styles_host.dart';

import 'app_element.dart';
import 'app_view_utils.dart'
    show appViewUtils, ensureSlotCount, OnDestroyCallback;
import 'element_injector.dart' show ElementInjector;
import 'exceptions.dart' show ViewDestroyedException;
import 'view_ref.dart' show ViewRefImpl;
import 'view_type.dart' show ViewType;

export 'package:angular2/src/core/change_detection/component_state.dart';

const EMPTY_CONTEXT = const Object();

/// Cost of making objects: http://jsperf.com/instantiate-size-of-object
abstract class AppView<T> {
  dynamic clazz;
  RenderComponentType componentType;
  ViewType type;
  Map<String, dynamic> locals;
  Injector parentInjector;
  AppElement declarationAppElement;
  ChangeDetectionStrategy _cdMode;
  // Improves change detection tree traversal by caching change detection mode
  // and change detection state checks. When set to true, this view doesn't need
  // to be change detected.
  bool _skipChangeDetection = false;
  ViewRefImpl ref;
  List rootNodesOrAppElements;
  List allNodes;
  final List<OnDestroyCallback> _onDestroyCallbacks = <OnDestroyCallback>[];
  List subscriptions;
  List<AppView> contentChildren = [];
  List<AppView> viewChildren = [];
  AppView renderParent;
  AppElement viewContainerElement;

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
  Renderer renderer;
  bool _hasExternalHostElement;
  AppView(this.clazz, this.componentType, this.type, this.locals,
      this.parentInjector, this.declarationAppElement, this._cdMode) {
    ref = new ViewRefImpl(this);
    sharedStylesHost ??= new DomSharedStylesHost(document);
    if (type == ViewType.COMPONENT || type == ViewType.HOST) {
      renderer = appViewUtils.renderComponent(componentType);
    } else {
      renderer = declarationAppElement.parentView.renderer;
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

  AppElement create(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | dynamic */ rootSelectorOrNode) {
    T context;
    var projectableNodes;
    switch (this.type) {
      case ViewType.COMPONENT:
        context = declarationAppElement.component as T;
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
  AppElement createHost(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | dynamic */ rootSelectorOrNode) {
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
  AppElement createEmbedded(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | dynamic */ rootSelectorOrNode) {
    projectableNodes = declarationAppElement.parentView.projectableNodes;
    _hasExternalHostElement = rootSelectorOrNode != null;
    ctx = declarationAppElement.parentView.ctx as T;
    return createInternal(rootSelectorOrNode);
  }

  /// Builds a component view.
  AppElement createComp(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | dynamic */ rootSelectorOrNode) {
    projectableNodes =
        ensureSlotCount(givenProjectableNodes, componentType.slotCount);
    _hasExternalHostElement = rootSelectorOrNode != null;
    ctx = declarationAppElement.component as T;
    return createInternal(rootSelectorOrNode);
  }

  /// Returns the AppElement for the host element for ViewType.HOST.
  ///
  /// Overwritten by implementations.
  AppElement createInternal(
          dynamic /* String | dynamic */ rootSelectorOrNode) =>
      null;

  /// Called by createInternal once all dom nodes are available.
  void init(List rootNodesOrAppElements, List allNodes, List subscriptions) {
    this.rootNodesOrAppElements = rootNodesOrAppElements;
    this.allNodes = allNodes;
    this.subscriptions = subscriptions;
    if (type == ViewType.COMPONENT) {
      // Note: the render nodes have been attached to their host element
      // in the ViewFactory already.
      declarationAppElement.parentView.viewChildren.add(this);
      dirtyParentQueriesInternal();
    }
  }

  dynamic selectOrCreateHostElement(String elementName,
      dynamic /* String | dynamic */ rootSelectorOrNode, debugCtx) {
    var hostElement;
    if (rootSelectorOrNode != null) {
      hostElement = renderer.selectRootElement(rootSelectorOrNode, debugCtx);
    } else {
      hostElement = renderer.createElement(null, elementName, debugCtx);
    }
    return hostElement;
  }

  dynamic injectorGet(dynamic token, num nodeIndex, dynamic notFoundResult) {
    return this.injectorGetInternal(token, nodeIndex, notFoundResult);
  }

  /// Overwritten by implementations
  dynamic injectorGetInternal(
      dynamic token, num nodeIndex, dynamic notFoundResult) {
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
      renderer.detachView(flatRootNodes);
    } else {
      viewContainerElement
          ?.detachView(viewContainerElement.nestedViews.indexOf(this));
    }
    _destroyRecurse();
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
    var hostElement =
        type == ViewType.COMPONENT ? declarationAppElement.nativeElement : null;
    for (int i = 0, len = _onDestroyCallbacks.length; i < len; i++) {
      _onDestroyCallbacks[i]();
    }
    for (var i = 0, len = subscriptions.length; i < len; i++) {
      this.subscriptions[i].cancel();
    }
    destroyInternal();
    dirtyParentQueriesInternal();
    renderer.destroyView(hostElement, allNodes);
  }

  void addOnDestroyCallback(OnDestroyCallback callback) {
    _onDestroyCallbacks.add(callback);
  }

  /// Overwritten by implementations to destroy view.
  void destroyInternal() {}

  ChangeDetectorRef get changeDetectorRef => ref;

  AppView<dynamic> get parent => declarationAppElement?.parentView;

  List<dynamic> get flatRootNodes =>
      _flattenNestedViews(rootNodesOrAppElements);

  dynamic get lastRootNode {
    var lastNode =
        rootNodesOrAppElements.isNotEmpty ? rootNodesOrAppElements.last : null;
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

  void markContentChildAsMoved(AppElement renderAppElement) {
    dirtyParentQueriesInternal();
  }

  void addToContentChildren(AppElement renderAppElement) {
    renderAppElement.parentView.contentChildren.add(this);
    viewContainerElement = renderAppElement;
    dirtyParentQueriesInternal();
  }

  void removeFromContentChildren(AppElement renderAppElement) {
    renderAppElement.parentView.contentChildren.remove(this);
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
          ? view.declarationAppElement
          : view.viewContainerElement;
      view = parentEl?.parentView;
    }
  }

  // Used to get around strong mode error due to loosely typed
  // subscription handlers.
  Function evt(Function cb) {
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
    DomRootRenderer.isDirty = true;
  }

  void setAttrNS(Element renderElement, String attrNS, String attributeName,
      String attributeValue) {
    if (attributeValue != null) {
      renderElement.setAttributeNS(attrNS, attributeName, attributeValue);
    } else {
      renderElement.getNamespacedAttributes(attrNS).remove(attributeName);
    }
    DomRootRenderer.isDirty = true;
  }

  // Marks DOM dirty so that end of zone turn we can detect if DOM was updated
  // for sharded apps support.
  void setDomDirty() {
    DomRootRenderer.isDirty = true;
  }

  /// Projects projectableNodes at specified index. We don't use helper
  /// functions to flatten the tree since it allocates list that are not
  /// required in most cases.
  void project(Element parentElement, int index) {
    if (parentElement == null) return;
    // Optimization for projectables that doesn't include AppElement(s).
    // If the projectable is AppElement we fall back to building up a list.
    List projectables = projectableNodes[index];
    int projectableCount = projectables.length;
    for (var i = 0; i < projectableCount; i++) {
      var projectable = projectables[i];
      if (projectable is AppElement) {
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
    DomRootRenderer.isDirty = true;
  }
}

dynamic _findLastRenderNode(dynamic node) {
  var lastNode;
  if (node is AppElement) {
    AppElement appEl = node;
    lastNode = appEl.nativeElement;
    if (appEl.nestedViews != null) {
      // Note: Views might have no root nodes at all!
      for (var i = appEl.nestedViews.length - 1; i >= 0; i--) {
        var nestedView = appEl.nestedViews[i];
        if (nestedView.rootNodesOrAppElements.isNotEmpty) {
          lastNode =
              _findLastRenderNode(nestedView.rootNodesOrAppElements.last);
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
    Element targetElement, AppElement appElement) {
  // TODO: strongly type nativeElement.
  targetElement.append(appElement.nativeElement as Node);
  var nestedViews = appElement.nestedViews;
  // Components inside ngcontent may also have ngcontent to project,
  // recursively walk nestedViews.
  if (nestedViews == null || nestedViews.isEmpty) return;
  int nestedViewCount = nestedViews.length;
  for (int viewIndex = 0; viewIndex < nestedViewCount; viewIndex++) {
    List projectables = nestedViews[viewIndex].rootNodesOrAppElements;
    int projectableCount = projectables.length;
    for (var i = 0; i < projectableCount; i++) {
      var projectable = projectables[i];
      if (projectable is AppElement) {
        _appendNestedViewRenderNodes(targetElement, projectable);
      } else {
        Node child = projectable;
        targetElement.append(child);
      }
    }
  }
}

List _flattenNestedViews(List nodes) {
  return _flattenNestedViewRenderNodes(nodes, []);
}

List _flattenNestedViewRenderNodes(List nodes, List renderNodes) {
  int nodeCount = nodes.length;
  for (var i = 0; i < nodeCount; i++) {
    var node = nodes[i];
    if (node is AppElement) {
      AppElement appEl = node;
      renderNodes.add(appEl.nativeElement);
      if (appEl.nestedViews != null) {
        for (var k = 0; k < appEl.nestedViews.length; k++) {
          _flattenNestedViewRenderNodes(
              appEl.nestedViews[k].rootNodesOrAppElements, renderNodes);
        }
      }
    } else {
      renderNodes.add(node);
    }
  }
  return renderNodes;
}

/// TODO(ferhat): Remove once dynamic(s) are changed in codegen and class.
/// This prevents unused import error in dart_analyzed_library build.
Element _temporaryTodo;
