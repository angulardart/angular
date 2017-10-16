import 'package:meta/meta.dart';

import '../../di/injector/injector.dart';
import '../di/decorators.dart';
import 'component_factory.dart';
import 'view_container_ref.dart';

/// Supports imperatively loading and binding new components at runtime.
///
/// AngularDart is most optimized when the entire application DOM and component
/// tree is known ahead of time, but sometimes an application will want to load
/// a new component at runtime.
///
/// _This class is replacing `SlowComponentLoader`, which has almost the same
/// API and properties, but uses runtime introspection in order to lookup and
/// then create the component. Going forward, `ComponentLoader` is preferred._
@Injectable()
class ComponentLoader {
  /// Creates and loads a new instance of the component defined by [component].
  ///
  /// Returns a [ComponentRef] that is detached from the physical DOM, and may
  /// be manually manipulated in order to be attached to DOM by the user. This
  /// API is considered to be a lower-level hook for higher-level components
  /// such as popups.
  ///
  /// May optionally define the parent [injector], otherwise defaults to the
  /// DI hierarchy that is present where this interface is injected:
  ///
  /// ```dart
  /// // An `ExampleComponent`s generated code, including a `ComponentFactory`.
  /// import 'example.template.dart' as ng;
  ///
  /// class AdBannerComponent implements AfterViewInit {
  ///   final ComponentLoader _loader;
  ///
  ///   AdBannerComponent(this._loader);
  ///
  ///   @override
  ///   ngAfterViewInit() {
  ///     final component = _loader.loadDetached(ng.ExampleComponentNgFactory);
  ///     // Do something with this reference.
  ///   }
  /// }
  /// ```
  ///
  /// See also [loadNextToLocation].
  @mustCallSuper
  ComponentRef<T> loadDetached<T>(
    ComponentFactory<T> component, {
    Injector injector,
  }) =>
      component.create(injector ?? const Injector.empty());

  /// Creates and loads a new instance of the component defined by [component].
  ///
  /// The returned [ComponentRef] is attached _next to_ the current directive -
  /// assuming the current directive is a_ structural directive_ (i.e. is either
  /// in a `<template>` or is used `*`, such as `*ngIf`) -otherwise throws an
  /// [UnsupportedError].
  ///
  /// See also [loadNextToLocation].
  ComponentRef<T> loadNextTo<T>(
    ComponentFactory<T> component, {
    Injector injector,
  }) =>
      throw new UnsupportedError('Not used within a structural directive');

  /// Creates and loads a new instance of the component defined by [component].
  ///
  /// The returned [ComponentRef] is attached _next to_ the provided [location]
  /// in the DOM, similar to how `*ngIf` and `*ngFor` operate.
  ///
  /// The following API would load a new component next to `currentAd`:
  /// ```dart
  /// @Component(
  ///   selector: 'ad-view',
  ///   template: r'''
  ///     This component is sponsored by:
  ///     <template #currentAd></template>
  ///   ''',
  /// )
  /// class AdViewComponent {
  ///   final ComponentLoader _loader;
  ///
  ///   @ViewChild('currentAd', read: ViewContainerRef)
  ///   ViewContainerRef currentAd;
  ///
  ///   AdViewComponent(this._loader);
  ///
  ///   @Input()
  ///   set component(ComponentFactory component) {
  ///     _loader.loadNextToLocation(component, currentAd);
  ///   }
  /// }
  /// ```
  ///
  /// May optionally define the parent [injector], otherwise defaults to the
  /// DI hierarchy that is present where in the view container [location].
  @mustCallSuper
  ComponentRef<T> loadNextToLocation<T>(
    ComponentFactory<T> component,
    ViewContainerRef location, {
    Injector injector,
  }) {
    return location.createComponent(
      component,
      location.length,
      injector ?? location.injector,
    );
  }
}
