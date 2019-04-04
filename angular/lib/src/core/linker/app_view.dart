import 'dart:async';
import 'dart:html';

import 'package:angular/src/core/change_detection/change_detection.dart';
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

import 'app_view_utils.dart';
import 'component_factory.dart';
import 'template_ref.dart';
import 'view_container.dart';
import 'view_fragment.dart';
import 'view_ref.dart' show EmbeddedViewRef;
import 'view_type.dart' show ViewType;
import 'views/view.dart';

export 'package:angular/src/core/change_detection/component_state.dart';

const _UndefinedInjectorResult = Object();

/// Shared app view members used to reduce polymorphic calls and
/// dart2js code size of constructors.
class AppViewData {
  /// The type of view (host element, complete template, embedded template).
  final ViewType type;

  /// Local values scoped to the view.
  ///
  /// Directives may create views and set additional variables accessible to
  /// the template (for example, `NgFor` sets the current element iterated).
  ///
  /// TODO: When we can rely on locals always being typed, encode as <, Object>.
  final locals = <String, dynamic>{};

  /// Whether the view has been destroyed.
  bool destroyed = false;

  /// Container that is set when this view is attached to a container.
  ViewContainer _viewContainerElement;

  /// Nodes that are given to this view by a parent view via content projection.
  ///
  /// A view will only attempt to _use_ this value if and only if it has at
  /// least one `<ng-content>` slot. These nodes are not created by the view
  /// itself but rather by the view's parent.
  ///
  /// See [AppView.create].
  List<Object> projectedNodes;

  /// Host DI interface.
  Injector _hostInjector;

  List<StreamSubscription<void>> subscriptions;

  List<void Function()> _onDestroyCallbacks;

  /// Tracks the root DOM elements or view containers (for `<template>`).
  ///
  /// TODO(b/129013000): It would be preferable to make this `final` and have it
  /// created eagerly in the constructor of the view based on whether the view
  /// has a single root node (init1), no root nodes (init0), or many (init), and
  /// could be optimized further.
  ViewFragment rootFragment;

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

  // TODO(b/129876510): remove factory indirection.
  @dart2js.noInline
  factory AppViewData(int cdMode, ViewType type, int parentIndex) {
    return AppViewData._(cdMode, type, parentIndex);
  }

  AppViewData._(this._cdMode, this.type, this.parentIndex);

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
///
/// NOTE: Since this class is extended by many generated View classes, the
/// ordering of the fields matters.
///
/// dart2js will preserve the field ordering, but can initialize 'null' fields
/// more compactly by combining them into a single statement. e.g.
/// `viewData = _rootEl = null`
///
/// In the generated View classes, the compiler will list initialized fields
/// followed by non-initialized fields.  In this base class, the
/// non-initialized fields are listed first, so the non-initialized fields
/// from the two classes can be combined into a single statement.
abstract class AppView<T> extends View
    implements ChangeDetectorRef, EmbeddedViewRef {
  /// The root element.
  ///
  /// This is _lazily_ initialized in a generated constructor.
  HtmlElement rootEl;

  /// The context against which data-binding expressions in this view are
  /// evaluated against.
  ///
  /// This is always a component instance.
  T ctx;

  @protected
  ComponentStyles componentStyles;

  /// Parent generated view.
  final AppView<Object> parentView;
  final AppViewData viewData;

  AppView(
    ViewType type,
    this.parentView,
    int parentIndex,
    int cdMode,
  ) : viewData = AppViewData(cdMode, type, parentIndex);

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

  @override
  bool get destroyed => viewData.destroyed;

  Map<String, dynamic> get locals => viewData.locals;

  List<Object> get projectedNodes => viewData.projectedNodes;

  @override
  List<Node> get rootNodes => flatRootNodes;

  @override
  void checkNoChanges() {
    AppViewUtils.enterThrowOnChanges();
    detectChanges();
    AppViewUtils.exitThrowOnChanges();
  }

  @override
  void detach() {
    cdMode = ChangeDetectionStrategy.Detached;
  }

  @override
  void markForCheck() {
    markPathToRootAsCheckOnce();
  }

  @override
  void onDestroy(void Function() callback) {
    viewData.addDestroyCallback(callback);
  }

  @override
  void reattach() {
    cdMode = ChangeDetectionStrategy.CheckAlways;
    markForCheck();
  }

  @override
  void setLocal(String name, dynamic value) {
    locals[name] = value;
  }

  ComponentRef<T> create(
    T context,
    List<Object> projectedNodes,
  ) {
    ctx = context;
    viewData.projectedNodes = projectedNodes;
    return build();
  }

  /// Specialized [create] when there are no `projectedNodes`.
  @dart2js.noInline
  ComponentRef<T> create0(T context) => create(context, const []);

  /// Builds host level view.
  ComponentRef<T> createHostView(
    Injector hostInjector,
    List<Object> projectedNodes,
  ) {
    viewData._hostInjector = hostInjector;
    viewData.projectedNodes = projectedNodes;
    return build();
  }

  // For legacy reasons and as an transitional API, this overrides the signature
  // of `View.build()` to return a `ComponentRef<T>`. The concrete
  // implementation is currently needed for b/129005490.
  @override
  ComponentRef<T> build() => null;

  /// Specialized [init] when a view does not need to track root nodes.
  @dart2js.noInline
  void init0() {
    init(const [], null);
  }

  /// Specialized [init] when component has a single root node (usually a host).
  @dart2js.noInline
  void init1(Object rootElement) {
    init([rootElement], null);
  }

  /// Called by [build] once all root DOM nodes/containers are available.
  @dart2js.noInline
  void init(
    List<Object> rootNodesOrViewContainers,
    List<StreamSubscription<void>> subscriptions,
  ) {
    viewData
      ..rootFragment = ViewFragment(rootNodesOrViewContainers)
      ..subscriptions = subscriptions;
  }

  /// Attaches this view's root nodes as siblings after [node].
  void attachRootNodesAfter(Node node) {
    insertNodesAsSibling(flatRootNodes, node);
    domRootRendererIsDirty = true;
  }

  @override
  Object injectorGet(
    Object token,
    int nodeIndex, [
    Object notFoundValue = throwIfNotFound,
  ]) {
    di_errors.debugInjectorEnter(token);
    var result = _UndefinedInjectorResult;
    AppView<Object> view = this;
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

  @override
  void destroy() {
    var containerElement = viewData._viewContainerElement;
    containerElement?.detachView(containerElement.nestedViews.indexOf(this));
    destroyInternalState();
  }

  void detachRootNodes() {
    final nodes = flatRootNodes;
    removeNodes(nodes);
    domRootRendererIsDirty = domRootRendererIsDirty || nodes.isNotEmpty;
  }

  @override
  void destroyInternalState() {
    if (viewData.destroyed) {
      return;
    }
    viewData.destroyed = true;
    viewData.destroy();
    destroyInternal();
    dirtyParentQueriesInternal();
  }

  @dart2js.noInline
  List<Node> get flatRootNodes {
    return viewData.rootFragment.flattenDomNodes();
  }

  @dart2js.noInline
  Node get lastRootNode {
    return viewData.rootFragment.findLastDomNode();
  }

  @override
  bool hasLocal(String name) => locals.containsKey(name);

  /// Overwritten by implementations
  void dirtyParentQueriesInternal() {}

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
    AppView<Object> view = this;
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
    componentStyles = parentView.componentStyles;
  }

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
  ///
  /// Used by [detectChanges] when changing [element.className] directly.
  ///
  /// For example, through the `[class]="..."` or `[attr.class]="..."` syntax.
  @dart2js.noInline
  void updateChildClass(HtmlElement element, String newClass) {
    final styles = componentStyles;
    final shim = styles.usesStyleEncapsulation;
    if (element == rootEl) {
      element.className = shim ? '$newClass ${styles.hostPrefix}' : newClass;
      if (parentView?.componentStyles != null) {
        parentView.addShimC(element);
      }
    } else {
      element.className = shim ? '$newClass ${styles.contentPrefix}' : newClass;
    }
  }

  /// Similar to [updateChildClass], for an [element] not guaranteed to be HTML.
  @dart2js.noInline
  void updateChildClassNonHtml(Element element, String newClass) {
    final styles = componentStyles;
    final shim = styles.usesStyleEncapsulation;
    if (element == rootEl) {
      updateAttribute(
          element, 'class', shim ? '$newClass ${styles.hostPrefix}' : newClass);
      if (parentView?.componentStyles != null) {
        parentView.addShimE(element);
      }
    } else {
      updateAttribute(element, 'class',
          shim ? '$newClass ${styles.contentPrefix}' : newClass);
    }
  }

  /// Moves (appends) appropriate DOM [Node]s of [ViewData.projectedNodes].
  ///
  /// In the case of multiple `<ng-content>` slots [index] is used as the
  /// discriminator to determine which parts of the template are mapped to
  /// what parts of the DOM.
  @dart2js.noInline
  void project(Element target, int index) {
    // TODO: Determine in what case this is `null`.
    if (target == null) {
      return;
    }

    // TODO: Determine why this would be `null` or out of bounds.
    final projectedNodesByContentIndex = viewData.projectedNodes;
    if (projectedNodesByContentIndex == null ||
        index >= projectedNodesByContentIndex.length) {
      return;
    }

    // TODO: Also determine why this might be `null`.
    final nodesToProjectIntoTarget = unsafeCast<List<Object>>(
      projectedNodesByContentIndex[index],
    );
    if (nodesToProjectIntoTarget == null) {
      return;
    }

    // This is slightly duplicated with ViewFragment due to the fact that nodes
    // stored in the projection list are sometimes stored as a List and
    // sometimes not as an optimization.
    final length = nodesToProjectIntoTarget.length;
    for (var i = 0; i < length; i++) {
      final node = nodesToProjectIntoTarget[i];
      if (node is ViewContainer) {
        target.append(node.nativeElement);
        final nestedViews = node.nestedViews;
        if (nestedViews != null) {
          final length = nestedViews.length;
          for (var n = 0; n < length; n++) {
            nestedViews[n].viewData.rootFragment.appendDomNodesInto(target);
          }
        }
      } else if (node is List<Object>) {
        ViewFragment.appendDomNodes(target, node);
      } else {
        target.append(unsafeCast(node));
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
