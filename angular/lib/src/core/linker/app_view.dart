import 'dart:async';
import 'dart:html';

import 'package:angular/src/core/change_detection/constants.dart';
import 'package:angular/src/core/change_detection/host.dart';
import 'package:angular/src/di/injector/injector.dart'
    show throwIfNotFound, Injector;
import 'package:angular/src/runtime.dart';
import 'package:angular/src/runtime/dom_helpers.dart';
import 'package:meta/meta.dart';
import 'package:meta/dart2js.dart' as dart2js;

import 'component_factory.dart';
import 'style_encapsulation.dart';
import 'view_container.dart';
import 'view_fragment.dart';
import 'view_ref.dart' show EmbeddedViewRef;
import 'view_type.dart' show ViewType;
import 'views/dynamic_view.dart';
import 'views/render_view.dart';

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
// TODO(b/129013000): only embedded and host views should extend `DynamicView`.
// TODO(b/129013000): only component and embedded views implement `RenderView`.
abstract class AppView<T> extends RenderView
    implements DynamicView, EmbeddedViewRef {
  /// The root element.
  ///
  /// This is _lazily_ initialized in a generated constructor.
  HtmlElement rootEl;

  @override
  T ctx;

  @override
  ComponentStyles componentStyles;

  @override
  final RenderView parentView;
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

  @override
  bool get firstCheck => cdState == ChangeDetectorState.NeverChecked;

  Map<String, dynamic> get locals => viewData.locals;

  @override
  int get parentIndex => viewData.parentIndex;

  @override
  List<Object> get projectedNodes => viewData.projectedNodes;

  @override
  List<Node> get rootNodes => flatRootNodes;

  @override
  ViewFragment get viewFragment => viewData.rootFragment;

  @override
  void detach() {
    cdMode = ChangeDetectionStrategy.Detached;
  }

  @override
  void markForCheck() {
    if (cdMode == ChangeDetectionStrategy.Detached) return;
    if (viewData.type == ViewType.component) {
      if (cdMode == ChangeDetectionStrategy.Checked) {
        cdMode = ChangeDetectionStrategy.CheckOnce;
      }
      parentView.markForCheck();
    } else {
      viewData._viewContainerElement?.parentView?.markForCheck();
    }
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

  @override
  Object injectorGetViewInternal(
    Object token,
    int nodeIndex, [
    Object notFoundValue = throwIfNotFound,
  ]) {
    if (nodeIndex != null) {
      final result =
          injectorGetInternal(token, nodeIndex, _UndefinedInjectorResult);
      if (!identical(result, _UndefinedInjectorResult)) {
        // This view has a provider for `token`.
        return result;
      }
    }
    final injector = viewData._hostInjector;
    if (injector != null) {
      // This must be a host view, which has an injector, but no parent view.
      return injector.get(token, notFoundValue);
    }
    return parentView.injectorGetViewInternal(
        token, parentIndex, notFoundValue);
  }

  @override
  void destroy() {
    var containerElement = viewData._viewContainerElement;
    containerElement?.detachView(containerElement.nestedViews.indexOf(this));
    destroyInternalState();
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
  @override
  List<Node> get flatRootNodes {
    return viewData.rootFragment.flattenDomNodes();
  }

  @dart2js.noInline
  @override
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

  /// Generated code that is called by hosts.
  /// This is needed since deferred components don't allow call sites
  /// to use the explicit AppView type but require base class.
  void detectHostChanges(bool firstCheck) {}

  @override
  void addRootNodesAfter(Node node) {
    insertNodesAsSibling(flatRootNodes, node);
    domRootRendererIsDirty = true;
  }

  @override
  void removeRootNodes() {
    final nodes = flatRootNodes;
    removeNodes(nodes);
    domRootRendererIsDirty = domRootRendererIsDirty || nodes.isNotEmpty;
  }

  @override
  void disableChangeDetection() {
    cdState = ChangeDetectorState.Errored;
  }

  @override
  void wasInserted(ViewContainer viewContainer) {
    viewData._viewContainerElement = viewContainer;
    dirtyParentQueriesInternal();
  }

  @override
  void wasMoved() {
    dirtyParentQueriesInternal();
  }

  @override
  void wasRemoved() {
    dirtyParentQueriesInternal();
    viewData._viewContainerElement = null;
  }

  void markAsCheckOnce() {
    cdMode = ChangeDetectionStrategy.CheckOnce;
  }

  @protected
  void initComponentStyles() {
    componentStyles = parentView.componentStyles;
  }

  /// Initializes styling to enable css shim for host element.
  ///
  /// The return value serves as a more efficient way of referencing [rootEl]
  /// within a component view's [build] implementation. It requires less code to
  /// assign the return value of a function that's going to be called anyways,
  /// than to generate an extra statement to load a field.
  @dart2js.noInline
  HtmlElement initViewRoot() {
    final hostElement = rootEl;
    final styles = componentStyles;
    if (styles.usesStyleEncapsulation) {
      updateClassBinding(hostElement, styles.hostPrefix, true);
    }
    return hostElement;
  }

  @dart2js.noInline
  @override
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

  @dart2js.noInline
  @override
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
}
