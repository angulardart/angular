import 'dart:async';

import 'package:angular/angular.dart'
    show
        Directive,
        Attribute,
        ComponentResolver,
        ComponentFactory,
        ComponentRef,
        ViewContainerRef,
        OnDestroy,
        Output,
        Injector,
        Visibility;
import 'package:collection/collection.dart' show MapEquality;

import '../instruction.dart' show ComponentInstruction, RouteParams, RouteData;
import '../interfaces.dart'
    show OnActivate, CanReuse, OnReuse, OnDeactivate, CanDeactivate;
import '../lifecycle/lifecycle_annotations.dart' as hook_mod;
import '../lifecycle/route_lifecycle_reflector.dart' show hasLifecycleHook;
import '../router.dart' as router_mod;

var _resolveToTrue = new Future<bool>.value(true);

/// A router outlet is a placeholder that Angular dynamically fills based on the application's route.
///
/// ### Example
///
/// Here is an example from the [tutorial on routing][routing]:
///
/// <?code-excerpt "docs/toh-5/lib/app_component.dart (template)"?>
/// ```dart
/// template: '''
///   <h1>{{title}}</h1>
///   <nav>
///     <a [routerLink]="['Dashboard']">Dashboard</a>
///     <a [routerLink]="['Heroes']">Heroes</a>
///   </nav>
///   <router-outlet></router-outlet>''',
/// ```
///
/// [routing]: https://webdev.dartlang.org/angular/tutorial/toh-pt5.html#router-outlet
@Directive(selector: "router-outlet", visibility: Visibility.none)
class RouterOutlet implements OnDestroy {
  ViewContainerRef _viewContainerRef;
  ComponentResolver _loader;
  router_mod.Router _parentRouter;
  String name;
  Future<ComponentRef> _componentRef;
  ComponentInstruction _currentInstruction;

  @Output('activate')
  Stream<dynamic> get onActivate => _activateEvents.stream;
  final _activateEvents = new StreamController<dynamic>.broadcast();

  RouterOutlet(this._viewContainerRef, this._loader, this._parentRouter,
      @Attribute("name") String nameAttr) {
    if (nameAttr != null) {
      this.name = nameAttr;
      this._parentRouter.registerAuxOutlet(this);
    } else {
      this._parentRouter.registerPrimaryOutlet(this);
    }
  }

  /// Called by the Router to instantiate a new component during the commit phase of a navigation.
  /// This method in turn is responsible for calling the `routerOnActivate` hook of its child.
  Future<dynamic> activate(ComponentInstruction nextInstruction) {
    var previousInstruction = this._currentInstruction;
    this._currentInstruction = nextInstruction;
    var componentType = nextInstruction.componentType;
    var childRouter = this._parentRouter.childRouter(componentType);
    var providers = new Map<dynamic, dynamic>();
    providers[RouteData] = nextInstruction.routeData;
    providers[RouteParams] = new RouteParams(nextInstruction.params);
    providers[router_mod.Router] = childRouter;
    var injector =
        new Injector.map(providers, _viewContainerRef.parentInjector);
    Future<ComponentFactory> componentFactoryPromise;
    if (componentType is ComponentFactory) {
      componentFactoryPromise = new Future.value(componentType);
    } else {
      componentFactoryPromise = this._loader.resolveComponent(componentType);
    }
    this._componentRef = componentFactoryPromise.then((componentFactory) =>
        this._viewContainerRef.createComponent(componentFactory, 0, injector));
    return this._componentRef.then((componentRef) {
      _activateEvents.add(componentRef.instance);
      if (hasLifecycleHook(hook_mod.routerOnActivate, componentRef.instance)) {
        return ((componentRef.instance as OnActivate))
            .routerOnActivate(nextInstruction, previousInstruction);
      } else {
        return componentRef;
      }
    });
  }

  /// Called by the [Router] during the commit phase of a navigation when an outlet
  /// reuses a component between different routes.
  /// This method in turn is responsible for calling the `routerOnReuse` hook of its child.
  Future<dynamic> reuse(ComponentInstruction nextInstruction) {
    var previousInstruction = this._currentInstruction;
    this._currentInstruction = nextInstruction;
    // it's possible the component is removed before it can be reactivated (if nested withing

    // another dynamically loaded component, for instance). In that case, we simply activate

    // a new one.
    if (_componentRef == null) {
      return this.activate(nextInstruction);
    } else {
      return this._componentRef.then((ComponentRef ref) =>
          hasLifecycleHook(hook_mod.routerOnReuse, ref.instance)
              ? ((ref.instance as OnReuse))
                  .routerOnReuse(nextInstruction, previousInstruction)
              : true);
    }
  }

  /// Called by the [Router] when an outlet disposes of a component's contents.
  /// This method in turn is responsible for calling the `routerOnDeactivate` hook of its child.
  Future<dynamic> deactivate(ComponentInstruction nextInstruction) {
    var next = _resolveToTrue;
    if (_componentRef != null) {
      next = this._componentRef.then((ComponentRef ref) =>
          hasLifecycleHook(hook_mod.routerOnDeactivate, ref.instance)
              ? ((ref.instance as OnDeactivate))
                  .routerOnDeactivate(nextInstruction, this._currentInstruction)
              : true);
    }
    return next.then((_) {
      if (_componentRef != null) {
        var onDispose =
            this._componentRef.then((ComponentRef ref) => ref.destroy());
        this._componentRef = null;
        return onDispose;
      }
    });
  }

  /// Called by the [Router] during recognition phase of a navigation.
  ///
  /// If this resolves to `false`, the given navigation is cancelled.
  ///
  /// This method delegates to the child component's `routerCanDeactivate` hook if it exists,
  /// and otherwise resolves to true.
  Future<bool> routerCanDeactivate(ComponentInstruction nextInstruction) {
    if (_currentInstruction == null) {
      return new Future.value(true);
    }
    return this._componentRef.then((ComponentRef ref) =>
        hasLifecycleHook(hook_mod.routerCanDeactivate, ref.instance)
            ? ((ref.instance as CanDeactivate))
                .routerCanDeactivate(nextInstruction, this._currentInstruction)
            : true);
  }

  /// Called by the [Router] during recognition phase of a navigation.
  ///
  /// If the new child component has a different Type than the existing child component,
  /// this will resolve to `false`. You can't reuse an old component when the new component
  /// is of a different Type.
  ///
  /// Otherwise, this method delegates to the child component's `routerCanReuse` hook if it exists,
  /// or resolves to true if the hook is not present.
  Future<bool> routerCanReuse(ComponentInstruction nextInstruction) {
    Future<bool> result;
    if (this._currentInstruction == null ||
        this._currentInstruction.componentType !=
            nextInstruction.componentType) {
      result = new Future.value(false);
    } else {
      result = this._componentRef.then((ComponentRef ref) {
        if (hasLifecycleHook(hook_mod.routerCanReuse, ref.instance)) {
          return ((ref.instance as CanReuse))
              .routerCanReuse(nextInstruction, this._currentInstruction);
        } else {
          return nextInstruction == this._currentInstruction ||
              (nextInstruction.params != null) &&
                  (_currentInstruction.params != null) &&
                  const MapEquality().equals(
                      nextInstruction.params, this._currentInstruction.params);
        }
      });
    }
    return result;
  }

  void ngOnDestroy() {
    this._parentRouter.unregisterPrimaryOutlet(this);
  }
}
