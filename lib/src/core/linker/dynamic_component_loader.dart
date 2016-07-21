import "dart:async";

import "package:angular2/src/core/di.dart" show Injector, Injectable;

import "component_factory.dart" show ComponentRef;
import "component_resolver.dart" show ComponentResolver;
import "view_container_ref.dart" show ViewContainerRef;

/**
 * Service for instantiating a Component and attaching it to a View at a specified location.
 */
abstract class DynamicComponentLoader {
  /**
   * Creates an instance of a Component `type` and attaches it to the first element in the
   * platform-specific global view that matches the component's selector.
   *
   * In a browser the platform-specific global view is the main DOM Document.
   *
   * If needed, the component's selector can be overridden via `overrideSelector`.
   *
   * You can optionally provide `injector` and this [Injector] will be used to instantiate the
   * Component.
   *
   * To be notified when this Component instance is destroyed, you can also optionally provide
   * `onDispose` callback.
   *
   * Returns a promise for the [ComponentRef] representing the newly created Component.
   *
   * ### Example
   *
   * ```
   * @Component({
   *   selector: 'child-component',
   *   template: 'Child'
   * })
   * class ChildComponent {
   * }
   *
   * @Component({
   *   selector: 'my-app',
   *   template: 'Parent (<child id="child"></child>)'
   * })
   * class MyApp {
   *   constructor(dcl: DynamicComponentLoader, injector: Injector) {
   *     dcl.loadAsRoot(ChildComponent, '#child', injector);
   *   }
   * }
   *
   * bootstrap(MyApp);
   * ```
   *
   * Resulting DOM:
   *
   * ```
   * <my-app>
   *   Parent (
   *     <child id="child">Child</child>
   *   )
   * </my-app>
   * ```
   */
  Future<ComponentRef> loadAsRoot(Type type,
      dynamic /* String | dynamic */ overrideSelectorOrNode, Injector injector,
      [void onDispose(), List<List<dynamic>> projectableNodes]);
  /**
   * Creates an instance of a Component and attaches it to the View Container found at the
   * `location` specified as [ViewContainerRef].
   *
   * You can optionally provide `providers` to configure the [Injector] provisioned for this
   * Component Instance.
   *
   * Returns a promise for the [ComponentRef] representing the newly created Component.
   *
   *
   * ### Example
   *
   * ```
   * @Component({
   *   selector: 'child-component',
   *   template: 'Child'
   * })
   * class ChildComponent {
   * }
   *
   * @Component({
   *   selector: 'my-app',
   *   template: 'Parent'
   * })
   * class MyApp {
   *   constructor(dcl: DynamicComponentLoader, viewContainerRef: ViewContainerRef) {
   *     dcl.loadNextToLocation(ChildComponent, viewContainerRef);
   *   }
   * }
   *
   * bootstrap(MyApp);
   * ```
   *
   * Resulting DOM:
   *
   * ```
   * <my-app>Parent</my-app>
   * <child-component>Child</child-component>
   * ```
   */
  Future<ComponentRef> loadNextToLocation(Type type, ViewContainerRef location,
      [Injector injector, List<List<dynamic>> projectableNodes]);
}

@Injectable()
class DynamicComponentLoader_ extends DynamicComponentLoader {
  ComponentResolver _compiler;
  DynamicComponentLoader_(this._compiler) : super() {
    /* super call moved to initializer */;
  }
  Future<ComponentRef> loadAsRoot(Type type,
      dynamic /* String | dynamic */ overrideSelectorOrNode, Injector injector,
      [void onDispose(), List<List<dynamic>> projectableNodes]) {
    return this._compiler.resolveComponent(type).then((componentFactory) {
      var componentRef = componentFactory.create(injector, projectableNodes,
          overrideSelectorOrNode ?? componentFactory.selector);
      if (onDispose != null) {
        componentRef.onDestroy(onDispose);
      }
      return componentRef;
    });
  }

  Future<ComponentRef> loadNextToLocation(Type type, ViewContainerRef location,
      [Injector injector = null, List<List<dynamic>> projectableNodes = null]) {
    return this._compiler.resolveComponent(type).then((componentFactory) {
      return location.createComponent(
          componentFactory, location.length, injector, projectableNodes);
    });
  }
}
