import 'dart:html';

import 'package:meta/dart2js.dart' as dart2js;
import 'package:meta/meta.dart';
import 'package:angular/src/core/change_detection/constants.dart';
import 'package:angular/src/core/change_detection/host.dart';
import 'package:angular/src/core/linker/component_factory.dart';
import 'package:angular/src/core/linker/view_container.dart';
import 'package:angular/src/core/linker/view_fragment.dart';
import 'package:angular/src/di/injector/injector.dart';
import 'package:angular/src/runtime.dart';
import 'package:angular/src/runtime/dom_helpers.dart';

import 'component_view.dart';
import 'dynamic_view.dart';
import 'view.dart';

/// The base type of a view that hosts a [component] for imperative use.
///
/// For every component (a class annotated with `@Component()`), the compiler
/// will generate exactly one host view that extends this class. This view is
/// used to back a [ComponentFactory], whose purpose is to instantiate the
/// [component] imperatively. Once instantiated, the [ComponentRef] can be used
/// to manage the underlying [componentView].
///
/// The responsibilities of this view include:
///
///   * Initializing [component] and its [componentView].
///
///   * Making any services provided by [component] available for injection by
///   [component] and its descendants.
///
///   * Invoking any life cycle interfaces implemented by the [component] at the
///   appropriate times.
///
/// The type parameter [T] is the type of the hosted [component].
abstract class HostView<T> extends View implements DynamicView {
  /// The hosted component instance.
  ///
  /// To be instantiated in [build] by the generated implementation.
  T component;

  /// The hosted component view.
  ///
  /// To be instantiated in [build] by the generated implementation.
  ComponentView<T> componentView;

  /// The host injector provided by this view's creator.
  // Ideally this field should be final and initialized in the constructor (as
  // it historically was), but late initializing it in `create()` produces less
  // generated code.
  // TODO(b/133171082): make this field `late`.
  Injector _injector;

  final _data = _HostViewData();

  @override
  bool get destroyed => _data.destroyed;

  // TODO(b/132122866): this could just return `componentView.firstCheck`.
  @override
  bool get firstCheck =>
      _data.changeDetectorState == ChangeDetectorState.NeverChecked;

  @override
  int get parentIndex => null;

  @override
  View get parentView => throw UnsupportedError('$HostView has no parentView');

  @override
  ViewFragment get viewFragment => _data.viewFragment;

  // Initialization ------------------------------------------------------------

  /// Creates this view and returns a reference to the hosted component.
  ///
  /// The [projectedNodes] specify the nodes and [ViewContainer]s to project
  /// into each content slot by index in the [componentView].
  ///
  /// The [injector] is provided by the caller, and is typically used to connect
  /// this host view to the rest of the dependency injection hierarchy. See
  /// [ViewContainer.createComponent] for details.
  ComponentRef<T> create(List<List<Object>> projectedNodes, Injector injector) {
    _injector = injector;
    build(); // This initializes `component` and `componentView`.
    componentView.createAndProject(component, projectedNodes);
    return ComponentRef(this, componentView.rootElement, component);
  }

  /// Called by [build] once all root nodes are created.
  @dart2js.noInline
  void initRootNode(Object nodeOrViewContainer) {
    _data.viewFragment = ViewFragment([nodeOrViewContainer]);
  }

  // Destruction ---------------------------------------------------------------

  void destroy() {
    final viewContainer = _data.viewContainer;
    viewContainer?.detachView(viewContainer.nestedViews.indexOf(this));
    destroyInternalState();
  }

  // Default implementation for simple host views whose component meets the
  // following criteria:
  //
  //    * Does not inject the following classes:
  //        * `ComponentLoader`
  //        * `ViewContainerRef`
  //
  //    * Does not implement the following lifecycle interfaces:
  //        * `OnDestroy`
  //
  // If the above criteria aren't met, a new implementation responsible for
  // destroying any additional state and calling the appropriate lifecycle
  // methods will be generated.
  @override
  void destroyInternal() {}

  @override
  void destroyInternalState() {
    if (!_data.destroyed) {
      _data.destroy();
      componentView.destroyInternalState();
      destroyInternal();
    }
  }

  @override
  void onDestroy(void Function() callback) {
    _data.addOnDestroyCallback(callback);
  }

  // Change detection ----------------------------------------------------------

  @override
  void detectChanges() {
    if (_data.shouldSkipChangeDetection) return;

    // Sanity check in dev-mode that a destroyed view is not checked again.
    if (isDevMode && _data.destroyed) {
      throw StateError('detectChanges');
    }

    if (ChangeDetectionHost.checkForCrashes) {
      // Run change detection in "slow-mode" to catch thrown exceptions.
      detectCrash();
    } else {
      // Normally run change detection.
      detectChangesInternal();
    }

    // Set the state to already checked at least once.
    _data.changeDetectorState = ChangeDetectorState.CheckedBefore;
  }

  @override
  void detectChangesInCheckAlwaysViews() {
    if (componentView.usesDefaultChangeDetection) {
      // Change detect the component, and any view containers it injects.
      detectChanges();
    }
  }

  // Default implementation for simple host views whose component meets the
  // following criteria:
  //
  //    * Does not inject the following classes:
  //        * `ComponentLoader`
  //        * `ViewContainerRef`
  //
  //    * Does not implement the following life cycle interfaces:
  //        * `OnInit`
  //        * `AfterChanges`
  //        * `AfterContentInit`
  //        * `AfterContentChecked`
  //        * `AfterViewInit`
  //        * `AfterViewChecked`
  //
  // If the above criteria aren't met, a new implementation responsible for
  // change detecting any additional state and calling the appropriate life
  // cycle methods will be generated.
  @override
  void detectChangesInternal() {
    componentView.detectChanges();
  }

  @override
  void disableChangeDetection() {
    _data.changeDetectorState = ChangeDetectorState.Errored;
  }

  @override
  void markForCheck() {
    // TODO(b/129780288): remove check for whether this view is detached.
    if (_data.changeDetectionMode != ChangeDetectionStrategy.Detached) {
      _data.viewContainer?.parentView?.markForCheck();
    }
  }

  @override
  void detach() {
    _data.changeDetectionMode = ChangeDetectionStrategy.Detached;
  }

  @override
  void reattach() {
    _data.changeDetectionMode = ChangeDetectionStrategy.CheckAlways;
    markForCheck();
  }

  // Dependency injection ------------------------------------------------------

  @override
  Object injectFromAncestry(Object token, Object notFoundValue) =>
      _injector.get(token, notFoundValue);

  // View manipulation ---------------------------------------------------------

  @override
  void addRootNodesAfter(Node node) {
    final rootNodes = viewFragment.flattenDomNodes();
    insertNodesAsSibling(rootNodes, node);
    domRootRendererIsDirty = true;
  }

  @override
  void removeRootNodes() {
    final rootNodes = viewFragment.flattenDomNodes();
    removeNodes(rootNodes);
    domRootRendererIsDirty = domRootRendererIsDirty || rootNodes.isNotEmpty;
  }

  @override
  void wasInserted(ViewContainer viewContainer) {
    _data.viewContainer = viewContainer;
  }

  @override
  void wasMoved() {
    // Nothing to update.
  }

  @override
  void wasRemoved() {
    _data.viewContainer = null;
  }
}

/// Data for [HostView] bundled together as an optimization.
@sealed
class _HostViewData implements DynamicViewData {
  @override
  ViewContainer viewContainer;

  @override
  ViewFragment viewFragment;

  /// Storage for any callbacks registered with [addOnDestroyCallback].
  List<void Function()> _onDestroyCallbacks;

  @override
  int get changeDetectionMode => _changeDetectionMode;
  int _changeDetectionMode = ChangeDetectionStrategy.CheckAlways;
  set changeDetectionMode(int mode) {
    if (_changeDetectionMode != mode) {
      _changeDetectionMode = mode;
      _updateShouldSkipChangeDetection();
    }
  }

  @override
  int get changeDetectorState => _changeDetectorState;
  int _changeDetectorState = ChangeDetectorState.NeverChecked;
  set changeDetectorState(int state) {
    if (_changeDetectorState != state) {
      _changeDetectorState = state;
      _updateShouldSkipChangeDetection();
    }
  }

  @override
  bool get destroyed => _destroyed;
  bool _destroyed = false;

  @override
  bool get shouldSkipChangeDetection => _shouldSkipChangeDetection;
  bool _shouldSkipChangeDetection = false;

  /// Registers a [callback] to be invoked by [destroy].
  void addOnDestroyCallback(void Function() callback) {
    _onDestroyCallbacks ??= [];
    _onDestroyCallbacks.add(callback);
  }

  @override
  void destroy() {
    _destroyed = true;
    if (_onDestroyCallbacks != null) {
      for (var i = 0, length = _onDestroyCallbacks.length; i < length; ++i) {
        _onDestroyCallbacks[i]();
      }
    }
  }

  void _updateShouldSkipChangeDetection() {
    _shouldSkipChangeDetection =
        _changeDetectionMode == ChangeDetectionStrategy.Detached ||
            _changeDetectorState == ChangeDetectorState.Errored;
  }
}
