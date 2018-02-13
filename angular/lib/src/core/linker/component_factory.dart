import 'dart:html';

import 'package:angular/src/core/di.dart' show Injector;
import 'package:angular/src/di/reflector.dart' show runtimeTypeProvider;
import 'package:angular/src/runtime.dart';

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
    this._nodeIndex,
    this._parentView,
    this._nativeElement,
    this._component,
  );

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

  /// Returns the type of component [C].
  @Deprecated('No longer supported, and throws an error in most applications')
  Type get componentType => runtimeTypeProvider(_component);

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

class ComponentFactory<T> {
  final String selector;

  // Not intuitive, but the _Host{Comp}View0 is NOT AppView<{Comp}>, but is a
  // special (not-typed to a user-defined class) AppView that itself creates a
  // AppView<{Comp}> as a child view.
  final NgViewFactory<dynamic> _viewFactory;

  const ComponentFactory(
    this.selector,
    this._viewFactory, [
    this.metadata = const [],
  ]);

  @Deprecated('Used for the deprecated router only.')
  Type get componentType => T;

  @Deprecated('Used for the deprecated router only.')
  final List<dynamic> metadata;

  /// Creates a new component.
  ComponentRef<T> create(
    Injector injector, [
    List<List> projectableNodes,
  ]) {
    // Note: Host views don't need a declarationViewContainer!
    final AppView<dynamic> hostView = _viewFactory(null, null);
    return unsafeCast<ComponentRef<T>>(
      hostView.createHostView(injector, projectableNodes ?? const []),
    );
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
typedef AppView<T> NgViewFactory<T>(AppView<T> parentView, int parentIndex);
