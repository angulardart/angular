import 'dart:html';

import 'package:angular/src/core/change_detection.dart'
    show ChangeDetectionStrategy, ChangeDetectorRef;
import 'package:angular/src/core/di.dart' show Injector;
import 'package:angular/src/runtime.dart' show isDevMode;

import 'app_view.dart';
import 'view_ref.dart' show ViewRef;

/// Returns whether [componentRef] uses [ChangeDetectionStrategy.Default].
///
/// In practice this can be used to assert that a component does *not* use
/// default change detection in non-default or performance sensitive contexts.
///
/// ```
/// final componentRef = viewContainerRef.createComponent(componentFactory);
/// assert(!debugUsesDefaultChangeDetection(componentRef));
/// ```
///
/// Note that at runtime, we can only tell whether a component uses default
/// change detection or not. It's not possible to distinguish which non-default
/// change detection strategy is used because they all use the same runtime
/// representation.
bool debugUsesDefaultChangeDetection(ComponentRef componentRef) {
  if (!isDevMode) {
    throw StateError(
      'This function should only be used for assertions. Consider wrapping the '
      'invocation in an "assert()" statement.\n'
      '\n'
      'See "debugUsesDefaultChangeDetection()" documentation for details.',
    );
  }
  // `ComponentRef._parentView` should only ever be a host view.
  final hostView = componentRef._parentView;
  final componentView = hostView.hostedComponentView;
  if (componentView == null) {
    throw StateError(
      'A "ComponentRef" should always reference a host view that hosts a '
      'non-null component view.',
    );
  }
  return componentView.cdMode == ChangeDetectionStrategy.CheckAlways;
}

/// Represents an instance of a Component created via a [ComponentFactory].
///
/// [ComponentRef] provides access to the Component Instance as well other
/// objects related to this Component Instance and allows you to destroy the
/// Component Instance via the [ComponentRef.destroy] method.
class ComponentRef<C> {
  final AppView<Object> _parentView;
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
  ViewRef get hostView => _parentView;

  /// The [ChangeDetectorRef] of the Component instance.
  ChangeDetectorRef get changeDetectorRef => _parentView;

  /// Destroys the component instance and all of the data structures associated
  /// with it.
  void destroy() {
    _parentView.destroy();
  }

  /// Register a callback that will be called when the component is destroyed.
  void onDestroy(void Function() callback) {
    hostView.onDestroy(callback);
  }
}

/// Backing implementation behind a `class` [T] annotated with `@Component`.
///
/// For example, if this lives in `example.dart`:
/// ```dart
/// @Component(
///   selector: 'example',
///   template: '...',
/// )
/// class Example {}
/// ```
///
/// ... then `ExampleNgFactory` is generated in `example.template.dart`, and
/// can be accessed by importing this generated file. For example:
/// ```dart
/// import 'example.template.dart' as ng;
///
/// getComponentFactory() {
///   final ComponentFactory<ng.Example> comp = ng.ExampleNgFactory;
///   // Can now use 'comp' as a ComponentFactory<Example>.
/// }
/// ```
///
/// It is *not* valid to implement, extend, mix-in, or construct this type.
class ComponentFactory<T> {
  final String selector;

  // Not intuitive, but the _Host{Comp}View0 is NOT AppView<{Comp}>, but is a
  // special (not-typed to a user-defined class) AppView that itself creates a
  // AppView<{Comp}> as a child view.
  final AppView<T> Function() _viewFactory;

  /// Internal constructor for generated code only - **do not invoke**.
  const ComponentFactory(
    this.selector,
    this._viewFactory,
  );

  @Deprecated('Used for the deprecated router only.')
  Type get componentType => T;

  /// Creates a new component.
  ComponentRef<T> create(
    Injector injector, [
    List<List<Object>> projectableNodes,
  ]) {
    final hostView = _viewFactory();
    return hostView.createHostView(injector, projectableNodes ?? const []);
  }
}
