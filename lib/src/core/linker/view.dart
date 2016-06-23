library angular2.src.core.linker.view;

import "package:angular2/src/facade/collection.dart"
    show
        ListWrapper,
        MapWrapper,
        Map,
        StringMapWrapper,
        isListLikeIterable,
        areIterablesEqual;
import "package:angular2/src/core/di.dart" show Injector;
import "element.dart" show AppElement;
import "package:angular2/src/facade/lang.dart"
    show
        assertionsEnabled,
        isPresent,
        isBlank,
        Type,
        isArray,
        isNumber,
        stringify,
        isPrimitive,
        isString;
import "package:angular2/src/facade/async.dart" show ObservableWrapper;
import "package:angular2/src/core/render/api.dart"
    show Renderer, RootRenderer, RenderComponentType;
import "view_ref.dart" show ViewRef_;
import "view_type.dart" show ViewType;
import "view_utils.dart"
    show
        ViewUtils,
        flattenNestedViewRenderNodes,
        ensureSlotCount,
        arrayLooseIdentical,
        mapLooseIdentical;
import "package:angular2/src/core/change_detection/change_detection.dart"
    show
        ChangeDetectorRef,
        ChangeDetectionStrategy,
        ChangeDetectorState,
        isDefaultChangeDetectionStrategy,
        devModeEqual;
import "../profile/profile.dart" show wtfCreateScope, wtfLeave, WtfScopeFn;
import "exceptions.dart"
    show
        ExpressionChangedAfterItHasBeenCheckedException,
        ViewDestroyedException,
        ViewWrappedException;
import "debug_context.dart" show StaticNodeDebugInfo, DebugContext;
import "element_injector.dart" show ElementInjector;

const EMPTY_CONTEXT = const Object();
WtfScopeFn _scope_check = wtfCreateScope('''AppView#check(ascii id)''');

/**
 * Cost of making objects: http://jsperf.com/instantiate-size-of-object
 *
 */
abstract class AppView<T> {
  dynamic clazz;
  RenderComponentType componentType;
  ViewType type;
  Map<String, dynamic> locals;
  ViewUtils viewUtils;
  Injector parentInjector;
  AppElement declarationAppElement;
  ChangeDetectionStrategy cdMode;
  ViewRef_ ref;
  List<dynamic> rootNodesOrAppElements;
  List<dynamic> allNodes;
  List<Function> disposables;
  List<dynamic> subscriptions;
  List<AppView<dynamic>> contentChildren = [];
  List<AppView<dynamic>> viewChildren = [];
  AppView<dynamic> renderParent;
  AppElement viewContainerElement = null;
  List<List<dynamic>> _literalArrayCache;
  List<Map<String, dynamic>> _literalMapCache;
  // The names of the below fields must be kept in sync with codegen_name_util.ts or

  // change detection will fail.
  ChangeDetectorState cdState = ChangeDetectorState.NeverChecked;
  /**
   * The context against which data-binding expressions in this view are evaluated against.
   * This is always a component instance.
   */
  T context = null;
  List<dynamic /* dynamic | List < dynamic > */ > projectableNodes;
  bool destroyed = false;
  Renderer renderer;
  bool _hasExternalHostElement;
  AppView(
      this.clazz,
      this.componentType,
      this.type,
      this.locals,
      this.viewUtils,
      this.parentInjector,
      this.declarationAppElement,
      this.cdMode,
      num literalArrayCacheSize,
      num literalMapCacheSize) {
    this.ref = new ViewRef_(this);
    if (identical(type, ViewType.COMPONENT) || identical(type, ViewType.HOST)) {
      this.renderer = viewUtils.renderComponent(componentType);
    } else {
      this.renderer = declarationAppElement.parentView.renderer;
    }
    this._literalArrayCache =
        ListWrapper.createFixedSize(literalArrayCacheSize);
    this._literalMapCache = ListWrapper.createFixedSize(literalMapCacheSize);
  }
  AppElement create(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | dynamic */ rootSelectorOrNode) {
    var context;
    var projectableNodes;
    switch (this.type) {
      case ViewType.COMPONENT:
        context = this.declarationAppElement.component;
        projectableNodes = ensureSlotCount(
            givenProjectableNodes, this.componentType.slotCount);
        break;
      case ViewType.EMBEDDED:
        context = this.declarationAppElement.parentView.context;
        projectableNodes =
            this.declarationAppElement.parentView.projectableNodes;
        break;
      case ViewType.HOST:
        context = EMPTY_CONTEXT;
        // Note: Don't ensure the slot count for the projectableNodes as we store

        // them only for the contained component view (which will later check the slot count...)
        projectableNodes = givenProjectableNodes;
        break;
    }
    this._hasExternalHostElement = isPresent(rootSelectorOrNode);
    this.context = context;
    this.projectableNodes = projectableNodes;
    return this.createInternal(rootSelectorOrNode);
  }

  /**
   * Overwritten by implementations.
   * Returns the AppElement for the host element for ViewType.HOST.
   */
  AppElement createInternal(dynamic /* String | dynamic */ rootSelectorOrNode) {
    return null;
  }

  init(List<dynamic> rootNodesOrAppElements, List<dynamic> allNodes,
      List<Function> disposables, List<dynamic> subscriptions) {
    this.rootNodesOrAppElements = rootNodesOrAppElements;
    this.allNodes = allNodes;
    this.disposables = disposables;
    this.subscriptions = subscriptions;
    if (identical(this.type, ViewType.COMPONENT)) {
      // Note: the render nodes have been attached to their host element

      // in the ViewFactory already.
      this.declarationAppElement.parentView.viewChildren.add(this);
      this.dirtyParentQueriesInternal();
    }
  }

  dynamic selectOrCreateHostElement(
      String elementName,
      dynamic /* String | dynamic */ rootSelectorOrNode,
      DebugContext debugCtx) {
    var hostElement;
    if (isPresent(rootSelectorOrNode)) {
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

  /**
   * Overwritten by implementations
   */
  dynamic injectorGetInternal(
      dynamic token, num nodeIndex, dynamic notFoundResult) {
    return notFoundResult;
  }

  Injector injector(num nodeIndex) {
    if (isPresent(nodeIndex)) {
      return new ElementInjector(this, nodeIndex);
    } else {
      return this.parentInjector;
    }
  }

  destroy() {
    if (this._hasExternalHostElement) {
      this.renderer.detachView(this.flatRootNodes);
    } else if (isPresent(this.viewContainerElement)) {
      this
          .viewContainerElement
          .detachView(this.viewContainerElement.nestedViews.indexOf(this));
    }
    this._destroyRecurse();
  }

  _destroyRecurse() {
    if (this.destroyed) {
      return;
    }
    var children = this.contentChildren;
    for (var i = 0; i < children.length; i++) {
      children[i]._destroyRecurse();
    }
    children = this.viewChildren;
    for (var i = 0; i < children.length; i++) {
      children[i]._destroyRecurse();
    }
    this.destroyLocal();
    this.destroyed = true;
  }

  destroyLocal() {
    var hostElement = identical(this.type, ViewType.COMPONENT)
        ? this.declarationAppElement.nativeElement
        : null;
    for (var i = 0; i < this.disposables.length; i++) {
      this.disposables[i]();
    }
    for (var i = 0; i < this.subscriptions.length; i++) {
      ObservableWrapper.dispose(this.subscriptions[i]);
    }
    this.destroyInternal();
    this.dirtyParentQueriesInternal();
    this.renderer.destroyView(hostElement, this.allNodes);
  }

  /**
   * Overwritten by implementations
   */
  void destroyInternal() {}
  ChangeDetectorRef get changeDetectorRef {
    return this.ref;
  }

  List<dynamic> get flatRootNodes {
    return flattenNestedViewRenderNodes(this.rootNodesOrAppElements);
  }

  dynamic get lastRootNode {
    var lastNode = this.rootNodesOrAppElements.length > 0
        ? this.rootNodesOrAppElements[this.rootNodesOrAppElements.length - 1]
        : null;
    return _findLastRenderNode(lastNode);
  }

  bool hasLocal(String contextName) {
    return StringMapWrapper.contains(this.locals, contextName);
  }

  void setLocal(String contextName, dynamic value) {
    this.locals[contextName] = value;
  }

  /**
   * Overwritten by implementations
   */
  void dirtyParentQueriesInternal() {}
  void detectChanges(bool throwOnChange) {
    var s = _scope_check(this.clazz);
    if (identical(this.cdMode, ChangeDetectionStrategy.Detached) ||
        identical(this.cdMode, ChangeDetectionStrategy.Checked) ||
        identical(this.cdState, ChangeDetectorState.Errored)) return;
    if (this.destroyed) {
      this.throwDestroyedError("detectChanges");
    }
    this.detectChangesInternal(throwOnChange);
    if (identical(this.cdMode, ChangeDetectionStrategy.CheckOnce))
      this.cdMode = ChangeDetectionStrategy.Checked;
    this.cdState = ChangeDetectorState.CheckedBefore;
    wtfLeave(s);
  }

  /**
   * Overwritten by implementations
   */
  void detectChangesInternal(bool throwOnChange) {
    this.detectContentChildrenChanges(throwOnChange);
    this.detectViewChildrenChanges(throwOnChange);
  }

  detectContentChildrenChanges(bool throwOnChange) {
    for (var i = 0; i < this.contentChildren.length; ++i) {
      this.contentChildren[i].detectChanges(throwOnChange);
    }
  }

  detectViewChildrenChanges(bool throwOnChange) {
    for (var i = 0; i < this.viewChildren.length; ++i) {
      this.viewChildren[i].detectChanges(throwOnChange);
    }
  }

  void addToContentChildren(AppElement renderAppElement) {
    renderAppElement.parentView.contentChildren.add(this);
    this.viewContainerElement = renderAppElement;
    this.dirtyParentQueriesInternal();
  }

  void removeFromContentChildren(AppElement renderAppElement) {
    ListWrapper.remove(renderAppElement.parentView.contentChildren, this);
    this.dirtyParentQueriesInternal();
    this.viewContainerElement = null;
  }

  List<dynamic> literalArray(num id, List<dynamic> value) {
    var prevValue = this._literalArrayCache[id];
    if (isBlank(value)) {
      return value;
    }
    if (isBlank(prevValue) || !arrayLooseIdentical(prevValue, value)) {
      prevValue = this._literalArrayCache[id] = value;
    }
    return prevValue;
  }

  Map<String, dynamic> literalMap(num id, Map<String, dynamic> value) {
    var prevValue = this._literalMapCache[id];
    if (isBlank(value)) {
      return value;
    }
    if (isBlank(prevValue) || !mapLooseIdentical(prevValue, value)) {
      prevValue = this._literalMapCache[id] = value;
    }
    return prevValue;
  }

  void markAsCheckOnce() {
    this.cdMode = ChangeDetectionStrategy.CheckOnce;
  }

  void markPathToRootAsCheckOnce() {
    AppView<dynamic> c = this;
    while (isPresent(c) &&
        !identical(c.cdMode, ChangeDetectionStrategy.Detached)) {
      if (identical(c.cdMode, ChangeDetectionStrategy.Checked)) {
        c.cdMode = ChangeDetectionStrategy.CheckOnce;
      }
      var parentEl = identical(c.type, ViewType.COMPONENT)
          ? c.declarationAppElement
          : c.viewContainerElement;
      c = isPresent(parentEl) ? parentEl.parentView : null;
    }
  }

  Function eventHandler(Function cb) {
    return cb;
  }

  void throwDestroyedError(String details) {
    throw new ViewDestroyedException(details);
  }
}

class DebugAppView<T> extends AppView<T> {
  List<StaticNodeDebugInfo> staticNodeDebugInfos;
  DebugContext _currentDebugContext = null;
  DebugAppView(
      dynamic clazz,
      RenderComponentType componentType,
      ViewType type,
      Map<String, dynamic> locals,
      ViewUtils viewUtils,
      Injector parentInjector,
      AppElement declarationAppElement,
      ChangeDetectionStrategy cdMode,
      num literalArrayCacheSize,
      num literalMapCacheSize,
      this.staticNodeDebugInfos)
      : super(
            clazz,
            componentType,
            type,
            locals,
            viewUtils,
            parentInjector,
            declarationAppElement,
            cdMode,
            literalArrayCacheSize,
            literalMapCacheSize) {
    /* super call moved to initializer */;
  }
  AppElement create(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      String rootSelector) {
    this._resetDebug();
    try {
      return super.create(givenProjectableNodes, rootSelector);
    } catch (e, e_stack) {
      this._rethrowWithContext(e, e_stack);
      rethrow;
    }
  }

  dynamic injectorGet(dynamic token, num nodeIndex, dynamic notFoundResult) {
    this._resetDebug();
    try {
      return super.injectorGet(token, nodeIndex, notFoundResult);
    } catch (e, e_stack) {
      this._rethrowWithContext(e, e_stack);
      rethrow;
    }
  }

  destroyLocal() {
    this._resetDebug();
    try {
      super.destroyLocal();
    } catch (e, e_stack) {
      this._rethrowWithContext(e, e_stack);
      rethrow;
    }
  }

  void detectChanges(bool throwOnChange) {
    this._resetDebug();
    try {
      super.detectChanges(throwOnChange);
    } catch (e, e_stack) {
      this._rethrowWithContext(e, e_stack);
      rethrow;
    }
  }

  _resetDebug() {
    this._currentDebugContext = null;
  }

  DebugContext debug(num nodeIndex, num rowNum, num colNum) {
    return this._currentDebugContext =
        new DebugContext(this, nodeIndex, rowNum, colNum);
  }

  _rethrowWithContext(dynamic e, dynamic stack) {
    if (!(e is ViewWrappedException)) {
      if (!(e is ExpressionChangedAfterItHasBeenCheckedException)) {
        this.cdState = ChangeDetectorState.Errored;
      }
      if (isPresent(this._currentDebugContext)) {
        throw new ViewWrappedException(e, stack, this._currentDebugContext);
      }
    }
  }

  Function eventHandler(Function cb) {
    var superHandler = super.eventHandler(cb);
    return (event) {
      this._resetDebug();
      try {
        return superHandler(event);
      } catch (e, e_stack) {
        this._rethrowWithContext(e, e_stack);
        rethrow;
      }
    };
  }
}

dynamic _findLastRenderNode(dynamic node) {
  var lastNode;
  if (node is AppElement) {
    var appEl = (node as AppElement);
    lastNode = appEl.nativeElement;
    if (isPresent(appEl.nestedViews)) {
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
