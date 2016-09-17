import 'dart:html';

import 'package:angular2/src/core/change_detection/change_detection.dart'
    show ChangeDetectorRef, ChangeDetectionStrategy, ChangeDetectorState;
import 'package:angular2/src/core/di.dart' show Injector;
import 'package:angular2/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular2/src/core/render/api.dart'
    show Renderer, RenderComponentType;
import 'package:angular2/src/platform/dom/shared_styles_host.dart';
import 'package:angular2/src/platform/dom/dom_renderer.dart'
    show DomRootRenderer;

import 'app_element.dart';
import 'element_injector.dart' show ElementInjector;
import 'exceptions.dart' show ViewDestroyedException;
import 'view_ref.dart' show ViewRef_;
import 'view_type.dart' show ViewType;
import 'app_view_utils.dart'
    show appViewUtils, ensureSlotCount, OnDestroyCallback;

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
  ViewRef_ ref;
  List<dynamic> rootNodesOrAppElements;
  List<dynamic> allNodes;
  final List<OnDestroyCallback> _onDestroyCallbacks = <OnDestroyCallback>[];
  List<dynamic> subscriptions;
  List<AppView<dynamic>> contentChildren = [];
  List<AppView<dynamic>> viewChildren = [];
  AppView<dynamic> renderParent;
  AppElement viewContainerElement;

  // The names of the below fields must be kept in sync with codegen_name_util.ts or
  // change detection will fail.
  ChangeDetectorState _cdState = ChangeDetectorState.NeverChecked;

  /// The context against which data-binding expressions in this view are
  /// evaluated against.
  ///
  /// This is always a component instance.
  T context;
  List<dynamic /* dynamic | List < dynamic > */ > projectableNodes;
  bool destroyed = false;
  Renderer renderer;
  bool _hasExternalHostElement;
  AppView(this.clazz, this.componentType, this.type, this.locals,
      this.parentInjector, this.declarationAppElement, this._cdMode) {
    this.ref = new ViewRef_(this);
    if (identical(type, ViewType.COMPONENT) || identical(type, ViewType.HOST)) {
      this.renderer = appViewUtils.renderComponent(componentType);
    } else {
      this.renderer = declarationAppElement.parentView.renderer;
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
        context = this.declarationAppElement.component as T;
        projectableNodes = ensureSlotCount(
            givenProjectableNodes, this.componentType.slotCount);
        break;
      case ViewType.EMBEDDED:
        return createEmbedded(givenProjectableNodes, rootSelectorOrNode);
      case ViewType.HOST:
        return createHost(givenProjectableNodes, rootSelectorOrNode);
    }
    this._hasExternalHostElement = rootSelectorOrNode != null;
    this.context = context;
    this.projectableNodes = projectableNodes;
    return this.createInternal(rootSelectorOrNode);
  }

  /// Builds a host view.
  AppElement createHost(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | dynamic */ rootSelectorOrNode) {
    assert(this.type == ViewType.HOST);
    context = null;
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
    context = declarationAppElement.parentView.context as T;
    return createInternal(rootSelectorOrNode);
  }

  /// Builds a component view.
  AppElement createComp(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | dynamic */ rootSelectorOrNode) {
    projectableNodes =
        ensureSlotCount(givenProjectableNodes, componentType.slotCount);
    _hasExternalHostElement = rootSelectorOrNode != null;
    context = declarationAppElement.component as T;
    return createInternal(rootSelectorOrNode);
  }

  /// Returns the AppElement for the host element for ViewType.HOST.
  ///
  /// Overwritten by implementations.
  AppElement createInternal(dynamic /* String | dynamic */ rootSelectorOrNode) {
    return null;
  }

  /// Called by createInternal once all dom nodes are available.
  void init(List<dynamic> rootNodesOrAppElements, List<dynamic> allNodes,
      List<dynamic> subscriptions) {
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
      hostElement =
          this.renderer.selectRootElement(rootSelectorOrNode, debugCtx);
    } else {
      hostElement = this.renderer.createElement(null, elementName, debugCtx);
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

  Injector injector(num nodeIndex) {
    if (nodeIndex == null) {
      return parentInjector;
    }
    return new ElementInjector(this, nodeIndex);
  }

  void destroy() {
    if (this._hasExternalHostElement) {
      this.renderer.detachView(flatRootNodes);
    } else {
      viewContainerElement
          ?.detachView(viewContainerElement.nestedViews.indexOf(this));
    }
    this._destroyRecurse();
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

  destroyLocal() {
    var hostElement = identical(this.type, ViewType.COMPONENT)
        ? this.declarationAppElement.nativeElement
        : null;
    for (int i = 0; i < _onDestroyCallbacks.length; i++) {
      _onDestroyCallbacks[i]();
    }
    for (var i = 0; i < this.subscriptions.length; i++) {
      this.subscriptions[i].cancel();
    }
    this.destroyInternal();
    this.dirtyParentQueriesInternal();
    this.renderer.destroyView(hostElement, this.allNodes);
  }

  void addOnDestroyCallback(OnDestroyCallback callback) {
    _onDestroyCallbacks.add(callback);
  }

  /// Overwritten by implementations to destroy view.
  void destroyInternal() {}

  ChangeDetectorRef get changeDetectorRef => ref;

  AppView<dynamic> get parent => this.declarationAppElement?.parentView;

  List<dynamic> get flatRootNodes =>
      flattenNestedViewRenderNodes(rootNodesOrAppElements);

  dynamic get lastRootNode {
    var lastNode = rootNodesOrAppElements.length > 0
        ? rootNodesOrAppElements[rootNodesOrAppElements.length - 1]
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
    if (this.destroyed) {
      this.throwDestroyedError('detectChanges');
    }
    this.detectChangesInternal();
    if (identical(_cdMode, ChangeDetectionStrategy.CheckOnce)) {
      _cdMode = ChangeDetectionStrategy.Checked;
      _skipChangeDetection = true;
    }
    cdState = ChangeDetectorState.CheckedBefore;
  }

  /// Overwritten by implementations
  void detectChangesInternal() {
    this.detectContentChildrenChanges();
    this.detectViewChildrenChanges();
  }

  void detectContentChildrenChanges() {
    int length = contentChildren.length;
    for (var i = 0; i < length; ++i) {
      contentChildren[i].detectChanges();
    }
  }

  void detectViewChildrenChanges() {
    int len = viewChildren.length;
    for (var i = 0; i < len; ++i) {
      viewChildren[i].detectChanges();
    }
  }

  void addToContentChildren(AppElement renderAppElement) {
    renderAppElement.parentView.contentChildren.add(this);
    this.viewContainerElement = renderAppElement;
    this.dirtyParentQueriesInternal();
  }

  void removeFromContentChildren(AppElement renderAppElement) {
    renderAppElement.parentView.contentChildren.remove(this);
    this.dirtyParentQueriesInternal();
    this.viewContainerElement = null;
  }

  void markAsCheckOnce() {
    cdMode = ChangeDetectionStrategy.CheckOnce;
  }

  void markPathToRootAsCheckOnce() {
    AppView<dynamic> c = this;
    while (c != null) {
      ChangeDetectionStrategy cdMode = c.cdMode;
      if (cdMode == ChangeDetectionStrategy.Detached) break;
      if (cdMode == ChangeDetectionStrategy.Checked) {
        c.cdMode = ChangeDetectionStrategy.CheckOnce;
      }
      var parentEl = c.type == ViewType.COMPONENT
          ? c.declarationAppElement
          : c.viewContainerElement;
      c = parentEl?.parentView;
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
    sharedStylesHost = new DomSharedStylesHost(document);
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
      nodesParent.append(createStyleElement(styles[i]));
    }
    return nodesParent;
  }

  StyleElement createStyleElement(String css) {
    StyleElement el = document.createElement('STYLE');
    el.text = css;
    return el;
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
        if (nestedView.rootNodesOrAppElements.length > 0) {
          lastNode = _findLastRenderNode(nestedView.rootNodesOrAppElements[
              nestedView.rootNodesOrAppElements.length - 1]);
        }
      }
    }
  } else {
    lastNode = node;
  }
  return lastNode;
}

List flattenNestedViewRenderNodes(List nodes) {
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
