import 'dart:html';

import 'package:angular/src/core/di.dart' show Injector;

import '../change_detection/change_detection.dart' show ChangeDetectorRef;
import 'app_view.dart';
import 'app_view_utils.dart' show OnDestroyCallback;
import 'view_ref.dart' show ViewRef;

/// Represents an instance of a Component created via a [ComponentFactory].
///
/// [ComponentRef] provides access to the Component Instance as well other
/// objects related to this Component Instance and allows you to destroy the
/// Component Instance via the [#destroy] method.
class ComponentRef<C> {
  final AppView _parentView;
  final int _nodeIndex;
  final Element _nativeElement;
  final C _component;

  ComponentRef(
      this._nodeIndex, this._parentView, this._nativeElement, this._component);

  /// Location of the Host Element of this Component Instance.
  Element get location => _nativeElement;

  /// The injector on which the component instance exists.
  Injector get injector => _parentView.injector(_nodeIndex);

  /// The instance of the Component.
  C get instance => _component;

  /// The [ViewRef] of the Host View of this Component instance.
  ViewRef get hostView => _parentView.viewData.ref;

  /// The [ChangeDetectorRef] of the Component instance.
  ChangeDetectorRef get changeDetectorRef => _parentView.viewData.ref;

  /// Returns type of component.
  /// TODO: remove use from angular router and deprecate.
  Type get componentType => _component.runtimeType;

  /// Destroys the component instance and all of the data structures associated
  /// with it.
  void destroy() {
    _parentView.detachAndDestroy();
  }

  /// Allows to register a callback that will be called when the component is
  /// destroyed.
  void onDestroy(OnDestroyCallback callback) {
    hostView.onDestroy(callback);
  }
}

class ComponentFactory {
  final String selector;
  final NgViewFactory _viewFactory;
  final Type _componentType;

  const ComponentFactory(
    this.selector,
    this._viewFactory,
    this._componentType, [
    this.metadata = const [],
  ]);

  Type get componentType => _componentType;

  final List<dynamic> metadata;

  /// Creates a new component.
  ComponentRef create(Injector injector, [List<List> projectableNodes]) {
    projectableNodes ??= [];
    // Note: Host views don't need a declarationViewContainer!
    AppView hostView = _viewFactory(null, null);
    return hostView.createHostView(injector, projectableNodes);
  }
}

/// Angular Component Factory signature.
///
/// Do not rely on parameters of this signature in your code. Instead use
/// the typedef only and ViewContainer(sync) apis to pass this factory to
/// construct the component.
/// This signature will likely change over time as actual implementation
/// of views change for further optimizations.
///
/// Example:
///     const ComponentFactory MaterialFabComponentNgFactory =
///     const ComponentFactory('material-fab',
///         viewFactory_MaterialFabComponentHost0,
///         import5.MaterialFabComponent,_METADATA);
typedef AppView NgViewFactory(AppView parentView, int parentIndex);
