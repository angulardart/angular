import 'dart:async';
import 'dart:html';

import 'package:angular/src/core/change_detection/change_detection.dart'
    show ChangeDetectorRef, ChangeDetectionStrategy, ChangeDetectorState;
import 'package:angular/src/core/change_detection/host.dart';
import 'package:angular/src/core/linker/style_encapsulation.dart';
import 'package:angular/src/di/errors.dart' as di_errors;
import 'package:angular/src/di/injector/element.dart';
import 'package:angular/src/di/injector/injector.dart'
    show throwIfNotFound, Injector;
import 'package:angular/src/runtime.dart';
import 'package:angular/src/runtime/dom_helpers.dart';
import 'package:meta/meta.dart';
import 'package:meta/dart2js.dart' as dart2js;

import 'app_view_base.dart';
import 'app_view_utils.dart';
import 'component_factory.dart';
import 'template_ref.dart';
import 'view_container.dart';
import 'view_ref.dart' show ViewRefImpl;
import 'view_type.dart' show ViewType;

export 'package:angular/src/core/change_detection/component_state.dart';

const _UndefinedInjectorResult = Object();

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

  List<void Function()> _onDestroyCallbacks;

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
      : ref = ViewRefImpl(appView);

  @dart2js.noInline
  factory AppViewData(
      AppView<T> appView, int cdMode, ViewType viewType, int parentIndex) {
    return AppViewData._(appView, cdMode, viewType, parentIndex);
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
    _skipChangeDetection = _cdMode == ChangeDetectionStrategy.Detached ||
        _cdMode == ChangeDetectionStrategy.Checked ||
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

  void addDestroyCallback(void Function() callback) {
    _onDestroyCallbacks ??= [];
    _onDestroyCallbacks.add(callback);
  }
}

/// Base class for a generated template for a given [Component] type [T].
abstract class AppView<T> extends View<T> {
  AppViewData<T> viewData;

  /// Local values scoped to this view.
  final Map<String, dynamic> locals;

  /// Parent generated view.
  final AppView parentView;

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
    viewData = AppViewData(this, cdMode, type, parentIndex);
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
  @override
  ComponentRef<T> build() => null;

  /// Specialized init when component has a single root node.
  @dart2js.noInline
  void init0(dynamic e) {
    viewData.rootNodesOrViewContainers = <dynamic>[e];
  }

  /// Called by build once all dom nodes are available.
  @dart2js.noInline
  void init(List rootNodesOrViewContainers, List subscriptions) {
    viewData.rootNodesOrViewContainers = rootNodesOrViewContainers;
    viewData.subscriptions = subscriptions;
  }

  void addInlinedNodes(
    Node anchor,
    List<Node> inlinedNodes, [
    bool isRoot = false,
  ]) {
    insertNodesAsSibling(inlinedNodes, anchor);
    if (isRoot) {
      viewData.rootNodesOrViewContainers.addAll(inlinedNodes);
    } else {
      viewData.addInlinedNodes(inlinedNodes);
    }
  }

  void removeInlinedNodes(List<Node> inlinedNodes, [bool isRoot = false]) {
    removeNodes(inlinedNodes);
    var nodeList =
        isRoot ? viewData.rootNodesOrViewContainers : viewData.inlinedNodes;
    for (int i = nodeList.length - 1; i >= 0; i--) {
      var node = nodeList[i];
      if (inlinedNodes.contains(node)) {
        nodeList.remove(node);
      }
    }
    domRootRendererIsDirty = true;
  }

  void attachViewAfter(Node node, List<Node> viewRootNodes) {
    insertNodesAsSibling(viewRootNodes, node);
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

  @override
  Injector injector(int nodeIndex) => ElementInjector(this, nodeIndex);

  void detachAndDestroy() {
    var containerElement = viewData._viewContainerElement;
    containerElement?.detachView(containerElement.nestedViews.indexOf(this));
    destroy();
  }

  @dart2js.noInline
  void detachViewNodes(List<Node> viewRootNodes) {
    removeNodes(viewRootNodes);
    domRootRendererIsDirty = domRootRendererIsDirty || viewRootNodes.isNotEmpty;
  }

  @override
  void destroy() {
    if (viewData.destroyed) return;
    viewData.destroyed = true;
    viewData.destroy();
    destroyInternal();
    dirtyParentQueriesInternal();
  }

  void addOnDestroyCallback(void Function() callback) {
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

  @mustCallSuper
  @override
  void detectChanges() {
    // Whether the CD state means change detection should be skipped.
    // Cases: ERRORED (Crash), CHECKED (Already-run), DETACHED (inactive).
    if (viewData._skipChangeDetection) {
      return;
    }

    // Sanity check in dev-mode that a destroyed view is not checked again.
    if (isDevMode && viewData.destroyed) {
      throw StateError('detectChanges');
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
      view = view.viewData.type == ViewType.component
          ? view.parentView
          : view.viewData._viewContainerElement?.parentView;
    }
  }

  @protected
  void initComponentStyles() {
    componentStyles = parentView?.componentStyles;
  }

  @protected
  ComponentStyles componentStyles;

  /// Initializes styling to enable css shim for host element.
  @dart2js.noInline
  HtmlElement initViewRoot(HtmlElement hostElement) {
    final styles = componentStyles;
    if (styles.usesStyleEncapsulation) {
      updateClassBinding(hostElement, styles.hostPrefix, true);
    }
    return hostElement;
  }

  /// Adds content shim class to HtmlElement.
  @dart2js.noInline
  void addShimC(HtmlElement element) {
    final styles = componentStyles;
    if (styles.usesStyleEncapsulation) {
      updateClassBinding(element, styles.contentPrefix, true);
    }
  }

  /// Adds content shim class to Svg or unknown tag type.
  @dart2js.noInline
  void addShimE(Element element) {
    final styles = componentStyles;
    if (styles.usesStyleEncapsulation) {
      updateClassBindingNonHtml(element, styles.contentPrefix, true);
    }
  }

  /// Called by change detector to apply correct host and content shimming
  /// after node's className is changed.

  /// Used by [detectChanges] when changing [element.className] directly.
  ///
  /// For example, through the `[class]="..."` or `[attr.class]="..."` syntax.
  @dart2js.noInline
  void updateChildClass(Element element, String newClass) {
    final styles = componentStyles;
    final shim = styles.usesStyleEncapsulation;
    if (element == rootEl) {
      element.className = shim ? '$newClass ${styles.hostPrefix}' : newClass;
      if (parentView?.componentStyles != null) {
        parentView.addShimE(element);
      }
    } else {
      element.className = shim ? '$newClass ${styles.contentPrefix}' : newClass;
    }
  }

  /// Projects projectableNodes at specified index. We don't use helper
  /// functions to flatten the tree since it allocates list that are not
  /// required in most cases.
  void project(Element parentElement, int index) {
    if (parentElement == null) return;
    // Optimization for projectables that doesn't include ViewContainer(s).
    // If the projectable is ViewContainer we fall back to building up a list.
    var projectableNodes = viewData.projectableNodes;
    if (projectableNodes == null || index >= projectableNodes.length) return;
    List projectables = unsafeCast(projectableNodes[index]);
    if (projectables == null) return;
    int projectableCount = projectables.length;
    for (var i = 0; i < projectableCount; i++) {
      var projectable = projectables[i];
      if (projectable is ViewContainer) {
        if (projectable.nestedViews == null) {
          parentElement.append(projectable.nativeElement);
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
            Node nativeNode = unsafeCast(node);
            parentElement.append(nativeNode);
          }
        }
      } else {
        Node child = unsafeCast(projectable);
        parentElement.append(child);
      }
    }
    domRootRendererIsDirty = true;
  }

  void Function(E) eventHandler0<E>(void Function() handler) {
    return (E event) {
      markPathToRootAsCheckOnce();
      appViewUtils.eventManager.zone.runGuarded(handler);
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
    assert(
        E == Null || F != Null,
        "Event handler '$handler' isn't assignable to expected type "
        "'($E) => void'");
    return (E event) {
      markPathToRootAsCheckOnce();
      appViewUtils.eventManager.zone
          .runGuarded(() => handler(unsafeCast<F>(event)));
    };
  }

  /// Loads dart code used in [templateRef] lazily.
  ///
  /// Returns a function, than when executed, cancels the creation of the view.
  void Function() loadDeferred(
    Future<void> Function() loadComponent,
    Future<void> Function() loadTemplateLib,
    ViewContainer viewContainer,
    TemplateRef templateRef, [
    void Function() initializer,
  ]) {
    var cancelled = false;
    Future.wait([loadComponent(), loadTemplateLib()]).then((_) {
      if (cancelled) {
        return;
      }
      if (initializer != null) {
        initializer();
      }
      viewContainer.createEmbeddedView(templateRef);
      viewContainer.detectChangesInNestedViews();
    });
    return () {
      cancelled = true;
    };
  }
}

Node _findLastRenderNode(dynamic node) {
  Node lastNode;
  if (node is ViewContainer) {
    final ViewContainer appEl = node;
    lastNode = appEl.nativeElement;
    var nestedViews = appEl.nestedViews;
    if (nestedViews != null) {
      // Note: Views might have no root nodes at all!
      for (var i = nestedViews.length - 1; i >= 0; i--) {
        var nestedViewData = appEl.nestedViews[i].viewData;
        if (nestedViewData.rootNodesOrViewContainers.isNotEmpty) {
          return _findLastRenderNode(
              nestedViewData.rootNodesOrViewContainers.last);
        }
      }
    }
  } else {
    lastNode = unsafeCast(node);
  }
  return lastNode;
}

/// Recursively appends app element and nested view nodes to target element.
void _appendNestedViewRenderNodes(
    Element targetElement, ViewContainer appElement) {
  targetElement.append(appElement.nativeElement);
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
        Node child = unsafeCast(projectable);
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
      final ViewContainer appEl = node;
      renderNodes.add(appEl.nativeElement);
      final nestedViews = appEl.nestedViews;
      if (nestedViews != null) {
        for (var k = 0, len = nestedViews.length; k < len; k++) {
          _flattenNestedViewRenderNodes(
              nestedViews[k].viewData.rootNodesOrViewContainers, renderNodes);
        }
      }
    } else {
      renderNodes.add(unsafeCast(node));
    }
  }
  return renderNodes;
}
