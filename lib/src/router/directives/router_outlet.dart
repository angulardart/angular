import "dart:async";

import "package:angular2/core.dart"
    show
        Directive,
        Attribute,
        ComponentResolver,
        ComponentFactory,
        ComponentRef,
        ViewContainerRef,
        OnDestroy,
        Output,
        MapInjector;
import "package:angular2/src/facade/async.dart"
    show PromiseWrapper, EventEmitter;
import "package:angular2/src/facade/collection.dart" show StringMapWrapper;
import "package:angular2/src/facade/lang.dart" show isBlank, isPresent;

import "../instruction.dart" show ComponentInstruction, RouteParams, RouteData;
import "../interfaces.dart"
    show OnActivate, CanReuse, OnReuse, OnDeactivate, CanDeactivate;
import "../lifecycle/lifecycle_annotations.dart" as hookMod;
import "../lifecycle/route_lifecycle_reflector.dart" show hasLifecycleHook;
import "../router.dart" as routerMod;

var _resolveToTrue = PromiseWrapper.resolve(true);

/// A router outlet is a placeholder that Angular dynamically fills based on the application's route.
///
/// ## Use
///
/// ```
/// <router-outlet></router-outlet>
/// ```
@Directive(selector: "router-outlet")
class RouterOutlet implements OnDestroy {
  ViewContainerRef _viewContainerRef;
  ComponentResolver _loader;
  routerMod.Router _parentRouter;
  String name = null;
  Future<ComponentRef> _componentRef = null;
  ComponentInstruction _currentInstruction = null;
  @Output("activate")
  var activateEvents = new EventEmitter<dynamic>();
  RouterOutlet(this._viewContainerRef, this._loader, this._parentRouter,
      @Attribute("name") String nameAttr) {
    if (isPresent(nameAttr)) {
      this.name = nameAttr;
      this._parentRouter.registerAuxOutlet(this);
    } else {
      this._parentRouter.registerPrimaryOutlet(this);
    }
  }
  /**
   * Called by the Router to instantiate a new component during the commit phase of a navigation.
   * This method in turn is responsible for calling the `routerOnActivate` hook of its child.
   */
  Future<dynamic> activate(ComponentInstruction nextInstruction) {
    var previousInstruction = this._currentInstruction;
    this._currentInstruction = nextInstruction;
    var componentType = nextInstruction.componentType;
    var childRouter = this._parentRouter.childRouter(componentType);
    var providers = new Map<dynamic, dynamic>();
    providers[RouteData] = nextInstruction.routeData;
    providers[RouteParams] = new RouteParams(nextInstruction.params);
    providers[routerMod.Router] = childRouter;
    var injector =
        new MapInjector(this._viewContainerRef.parentInjector, providers);
    Future<ComponentFactory> componentFactoryPromise;
    if (componentType is ComponentFactory) {
      componentFactoryPromise = PromiseWrapper.resolve(componentType);
    } else {
      componentFactoryPromise = this._loader.resolveComponent(componentType);
    }
    this._componentRef = componentFactoryPromise.then((componentFactory) =>
        this._viewContainerRef.createComponent(componentFactory, 0, injector));
    return this._componentRef.then((componentRef) {
      this.activateEvents.emit(componentRef.instance);
      if (hasLifecycleHook(hookMod.routerOnActivate, componentRef.instance)) {
        return ((componentRef.instance as OnActivate))
            .routerOnActivate(nextInstruction, previousInstruction);
      } else {
        return componentRef;
      }
    });
  }

  /**
   * Called by the [Router] during the commit phase of a navigation when an outlet
   * reuses a component between different routes.
   * This method in turn is responsible for calling the `routerOnReuse` hook of its child.
   */
  Future<dynamic> reuse(ComponentInstruction nextInstruction) {
    var previousInstruction = this._currentInstruction;
    this._currentInstruction = nextInstruction;
    // it's possible the component is removed before it can be reactivated (if nested withing

    // another dynamically loaded component, for instance). In that case, we simply activate

    // a new one.
    if (isBlank(this._componentRef)) {
      return this.activate(nextInstruction);
    } else {
      return this._componentRef.then((ComponentRef ref) =>
          hasLifecycleHook(hookMod.routerOnReuse, ref.instance)
              ? ((ref.instance as OnReuse))
                  .routerOnReuse(nextInstruction, previousInstruction)
              : true);
    }
  }

  /**
   * Called by the [Router] when an outlet disposes of a component's contents.
   * This method in turn is responsible for calling the `routerOnDeactivate` hook of its child.
   */
  Future<dynamic> deactivate(ComponentInstruction nextInstruction) {
    var next = _resolveToTrue;
    if (isPresent(this._componentRef)) {
      next = this._componentRef.then((ComponentRef ref) =>
          hasLifecycleHook(hookMod.routerOnDeactivate, ref.instance)
              ? ((ref.instance as OnDeactivate))
                  .routerOnDeactivate(nextInstruction, this._currentInstruction)
              : true);
    }
    return next.then((_) {
      if (isPresent(this._componentRef)) {
        var onDispose =
            this._componentRef.then((ComponentRef ref) => ref.destroy());
        this._componentRef = null;
        return onDispose;
      }
    });
  }

  /**
   * Called by the [Router] during recognition phase of a navigation.
   *
   * If this resolves to `false`, the given navigation is cancelled.
   *
   * This method delegates to the child component's `routerCanDeactivate` hook if it exists,
   * and otherwise resolves to true.
   */
  Future<bool> routerCanDeactivate(ComponentInstruction nextInstruction) {
    if (isBlank(this._currentInstruction)) {
      return _resolveToTrue;
    }
    return this._componentRef.then((ComponentRef ref) =>
        hasLifecycleHook(hookMod.routerCanDeactivate, ref.instance)
            ? ((ref.instance as CanDeactivate))
                .routerCanDeactivate(nextInstruction, this._currentInstruction)
            : true);
  }

  /**
   * Called by the [Router] during recognition phase of a navigation.
   *
   * If the new child component has a different Type than the existing child component,
   * this will resolve to `false`. You can't reuse an old component when the new component
   * is of a different Type.
   *
   * Otherwise, this method delegates to the child component's `routerCanReuse` hook if it exists,
   * or resolves to true if the hook is not present.
   */
  Future<bool> routerCanReuse(ComponentInstruction nextInstruction) {
    Future<bool> result;
    if (isBlank(this._currentInstruction) ||
        this._currentInstruction.componentType !=
            nextInstruction.componentType) {
      result = PromiseWrapper.resolve(false);
    } else {
      result = this._componentRef.then((ComponentRef ref) {
        if (hasLifecycleHook(hookMod.routerCanReuse, ref.instance)) {
          return ((ref.instance as CanReuse))
              .routerCanReuse(nextInstruction, this._currentInstruction);
        } else {
          return nextInstruction == this._currentInstruction ||
              (isPresent(nextInstruction.params) &&
                  isPresent(this._currentInstruction.params) &&
                  StringMapWrapper.equals(
                      nextInstruction.params, this._currentInstruction.params));
        }
      });
    }
    return result;
  }

  void ngOnDestroy() {
    this._parentRouter.unregisterPrimaryOutlet(this);
  }
}
