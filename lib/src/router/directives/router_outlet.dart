library angular2.src.router.directives.router_outlet;

import "dart:async";
import "package:angular2/src/facade/async.dart"
    show PromiseWrapper, EventEmitter;
import "package:angular2/src/facade/collection.dart" show StringMapWrapper;
import "package:angular2/src/facade/lang.dart" show isBlank, isPresent;
import "package:angular2/core.dart"
    show
        Directive,
        Attribute,
        DynamicComponentLoader,
        ComponentRef,
        ViewContainerRef,
        Injector,
        provide,
        Dependency,
        OnDestroy,
        Output;
import "../router.dart" as routerMod;
import "../instruction.dart" show ComponentInstruction, RouteParams, RouteData;
import "../lifecycle/lifecycle_annotations.dart" as hookMod;
import "../lifecycle/route_lifecycle_reflector.dart" show hasLifecycleHook;
import "../interfaces.dart"
    show OnActivate, CanReuse, OnReuse, OnDeactivate, CanDeactivate;

var _resolveToTrue = PromiseWrapper.resolve(true);

/**
 * A router outlet is a placeholder that Angular dynamically fills based on the application's route.
 *
 * ## Use
 *
 * ```
 * <router-outlet></router-outlet>
 * ```
 */
@Directive(selector: "router-outlet")
class RouterOutlet implements OnDestroy {
  ViewContainerRef _viewContainerRef;
  DynamicComponentLoader _loader;
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
    var providers = Injector.resolve([
      provide(RouteData, useValue: nextInstruction.routeData),
      provide(RouteParams, useValue: new RouteParams(nextInstruction.params)),
      provide(routerMod.Router, useValue: childRouter)
    ]);
    this._componentRef = this
        ._loader
        .loadNextToLocation(componentType, this._viewContainerRef, providers);
    return this._componentRef.then((componentRef) {
      this.activateEvents.emit(componentRef.instance);
      if (hasLifecycleHook(hookMod.routerOnActivate, componentType)) {
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
      return PromiseWrapper.resolve(hasLifecycleHook(
              hookMod.routerOnReuse, this._currentInstruction.componentType)
          ? this._componentRef.then((ComponentRef ref) =>
              ((ref.instance as OnReuse))
                  .routerOnReuse(nextInstruction, previousInstruction))
          : true);
    }
  }

  /**
   * Called by the [Router] when an outlet disposes of a component's contents.
   * This method in turn is responsible for calling the `routerOnDeactivate` hook of its child.
   */
  Future<dynamic> deactivate(ComponentInstruction nextInstruction) {
    var next = _resolveToTrue;
    if (isPresent(this._componentRef) &&
        isPresent(this._currentInstruction) &&
        hasLifecycleHook(hookMod.routerOnDeactivate,
            this._currentInstruction.componentType)) {
      next = this._componentRef.then((ComponentRef ref) =>
          ((ref.instance as OnDeactivate))
              .routerOnDeactivate(nextInstruction, this._currentInstruction));
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
    if (hasLifecycleHook(
        hookMod.routerCanDeactivate, this._currentInstruction.componentType)) {
      return this._componentRef.then((ComponentRef ref) =>
          ((ref.instance as CanDeactivate))
              .routerCanDeactivate(nextInstruction, this._currentInstruction));
    } else {
      return _resolveToTrue;
    }
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
    var result;
    if (isBlank(this._currentInstruction) ||
        this._currentInstruction.componentType !=
            nextInstruction.componentType) {
      result = false;
    } else if (hasLifecycleHook(
        hookMod.routerCanReuse, this._currentInstruction.componentType)) {
      result = this._componentRef.then((ComponentRef ref) =>
          ((ref.instance as CanReuse))
              .routerCanReuse(nextInstruction, this._currentInstruction));
    } else {
      result = nextInstruction == this._currentInstruction ||
          (isPresent(nextInstruction.params) &&
              isPresent(this._currentInstruction.params) &&
              StringMapWrapper.equals(
                  nextInstruction.params, this._currentInstruction.params));
    }
    return (PromiseWrapper.resolve(result) as Future<bool>);
  }

  void ngOnDestroy() {
    this._parentRouter.unregisterPrimaryOutlet(this);
  }
}
