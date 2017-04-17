import 'dart:async';
import 'dart:html';

import 'package:angular2/src/core/di.dart' show Injector, Injectable;

import 'app_view_utils.dart' show OnDestroyCallback;
import 'component_factory.dart' show ComponentRef;
import 'component_resolver.dart' show ComponentResolver;
import 'view_container_ref.dart' show ViewContainerRef;

/// Service for instantiating a Component and attaching it to a View at a
/// specified location.
abstract class DynamicComponentLoader {
  /// Creates an instance of a Component `type` and attaches it to the first
  /// element in the platform-specific global view that matches the component's
  /// selector.
  ///
  /// In a browser the platform-specific global view is the main DOM Document.
  ///
  /// If needed, the component's selector can be overridden via
  /// `overrideSelector`.
  ///
  /// You can optionally provide `injector` and this [Injector] will be used
  /// to instantiate the Component.
  ///
  /// To be notified when this Component instance is destroyed, you can also
  /// optionally provide
  /// `onDispose` callback.
  ///
  /// Returns a promise for the [ComponentRef] representing the newly created
  /// Component.
  ///
  /// ### Example
  ///
  ///     ```
  ///     @Component(
  ///       selector: 'child-component',
  ///       template: 'Child'
  ///     )
  ///     class ChildComponent {
  ///     }
  ///
  ///     @Component(
  ///       selector: 'my-app',
  ///       template: 'Parent (<div id="container"></div>)'
  ///     )
  ///     class MyApp {
  ///       MyApp(DynamicComponentLoader dcl, Injector injector) {
  ///         dcl.load(ChildComponent, injector).then(
  ///           (ComponentRef comp) {
  ///              document.querySelector('#container').append(
  ///                 comp.location.nativeElement);
  ///           });
  ///       });
  ///     }
  ///
  ///     bootstrap(MyApp);
  ///     ```
  ///
  ///     Resulting DOM:
  ///
  ///     ```
  ///     <my-app>
  ///       Parent (
  ///         <div id="container"><child>Child</child></div>
  ///       )
  ///     </my-app>
  ///     ```
  Future<ComponentRef> load(Type type, Injector injector,
      {OnDestroyCallback onDestroy, List<List> projectableNodes});

  /// Creates an instance of a Component and attaches it to the View Container
  /// found at the `location` specified as [ViewContainerRef].
  ///
  /// You can optionally provide `providers` to configure the [Injector]
  /// provisioned for this Component Instance.
  ///
  /// Returns a promise for the [ComponentRef] representing the newly created Component.
  ///
  ///
  ///     ### Example
  ///
  ///     ```
  ///     @Component(
  ///       selector: 'child-component',
  ///       template: 'Child'
  ///     )
  ///     class ChildComponent {
  ///     }
  ///
  ///     @Component(
  ///       selector: 'my-app',
  ///       template: 'Parent'
  ///     )
  ///     class MyApp {
  ///       MyApp(DynamicComponentLoader dcl,
  ///           ViewContainerRef viewContainerRef) {
  ///         dcl.loadNextToLocation(ChildComponent, viewContainerRef);
  ///       }
  ///     }
  ///
  ///     bootstrap(MyApp);
  ///     ```
  ///
  ///     Resulting DOM:
  ///
  ///     ```
  ///     <my-app>Parent</my-app>
  ///     <child-component>Child</child-component>
  ///     ```
  Future<ComponentRef> loadNextToLocation(Type type, ViewContainerRef location,
      [Injector injector, List<List<dynamic>> projectableNodes]);
}

@Injectable()
class DynamicComponentLoaderImpl extends DynamicComponentLoader {
  final ComponentResolver _compiler;
  DynamicComponentLoaderImpl(this._compiler);

  @override
  Future<ComponentRef> load(Type type, Injector injector,
      {OnDestroyCallback onDestroy, List<List> projectableNodes}) {
    return _compiler.resolveComponent(type).then((componentFactory) {
      ComponentRef componentRef =
          componentFactory.create(injector, projectableNodes);
      componentRef.onDestroy(() {
        if (onDestroy != null) {
          onDestroy();
        }
        (componentRef.location.nativeElement as Element).remove();
      });
      return componentRef;
    });
  }

  Future<ComponentRef> loadNextToLocation(Type type, ViewContainerRef location,
      [Injector injector = null, List<List<dynamic>> projectableNodes = null]) {
    return _compiler.resolveComponent(type).then((componentFactory) {
      return location.createComponent(
          componentFactory, location.length, injector, projectableNodes);
    });
  }
}
