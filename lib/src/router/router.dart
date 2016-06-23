library angular2.src.router.router;

import "dart:async";
import "package:angular2/src/facade/async.dart"
    show PromiseWrapper, EventEmitter, ObservableWrapper;
import "package:angular2/src/facade/collection.dart"
    show Map, StringMapWrapper, MapWrapper, ListWrapper;
import "package:angular2/src/facade/lang.dart"
    show isBlank, isString, isPresent, Type, isArray;
import "package:angular2/src/facade/exceptions.dart"
    show BaseException, WrappedException;
import "package:angular2/platform/common.dart" show Location;
import "package:angular2/core.dart" show Inject, Injectable;
import "route_registry.dart" show RouteRegistry, ROUTER_PRIMARY_COMPONENT;
import "instruction.dart" show ComponentInstruction, Instruction;
import "directives/router_outlet.dart" show RouterOutlet;
import "lifecycle/route_lifecycle_reflector.dart" show getCanActivateHook;
import "route_config/route_config_impl.dart" show RouteDefinition;

var _resolveToTrue = PromiseWrapper.resolve(true);
var _resolveToFalse = PromiseWrapper.resolve(false);

/**
 * The `Router` is responsible for mapping URLs to components.
 *
 * You can see the state of the router by inspecting the read-only field `router.navigating`.
 * This may be useful for showing a spinner, for instance.
 *
 * ## Concepts
 *
 * Routers and component instances have a 1:1 correspondence.
 *
 * The router holds reference to a number of [RouterOutlet].
 * An outlet is a placeholder that the router dynamically fills in depending on the current URL.
 *
 * When the router navigates from a URL, it must first recognize it and serialize it into an
 * `Instruction`.
 * The router uses the `RouteRegistry` to get an `Instruction`.
 */
@Injectable()
class Router {
  RouteRegistry registry;
  Router parent;
  dynamic hostComponent;
  Router root;
  bool navigating = false;
  String lastNavigationAttempt;
  /**
   * The current `Instruction` for the router
   */
  Instruction currentInstruction = null;
  Future<dynamic> _currentNavigation = _resolveToTrue;
  RouterOutlet _outlet = null;
  var _auxRouters = new Map<String, Router>();
  Router _childRouter;
  EventEmitter<dynamic> _subject = new EventEmitter();
  Router(this.registry, this.parent, this.hostComponent, [this.root]) {}
  /**
   * Constructs a child router. You probably don't need to use this unless you're writing a reusable
   * component.
   */
  Router childRouter(dynamic hostComponent) {
    return this._childRouter = new ChildRouter(this, hostComponent);
  }

  /**
   * Constructs a child router. You probably don't need to use this unless you're writing a reusable
   * component.
   */
  Router auxRouter(dynamic hostComponent) {
    return new ChildRouter(this, hostComponent);
  }

  /**
   * Register an outlet to be notified of primary route changes.
   *
   * You probably don't need to use this unless you're writing a reusable component.
   */
  Future<dynamic> registerPrimaryOutlet(RouterOutlet outlet) {
    if (isPresent(outlet.name)) {
      throw new BaseException(
          '''registerPrimaryOutlet expects to be called with an unnamed outlet.''');
    }
    if (isPresent(this._outlet)) {
      throw new BaseException('''Primary outlet is already registered.''');
    }
    this._outlet = outlet;
    if (isPresent(this.currentInstruction)) {
      return this.commit(this.currentInstruction, false);
    }
    return _resolveToTrue;
  }

  /**
   * Unregister an outlet (because it was destroyed, etc).
   *
   * You probably don't need to use this unless you're writing a custom outlet implementation.
   */
  void unregisterPrimaryOutlet(RouterOutlet outlet) {
    if (isPresent(outlet.name)) {
      throw new BaseException(
          '''registerPrimaryOutlet expects to be called with an unnamed outlet.''');
    }
    this._outlet = null;
  }

  /**
   * Register an outlet to notified of auxiliary route changes.
   *
   * You probably don't need to use this unless you're writing a reusable component.
   */
  Future<dynamic> registerAuxOutlet(RouterOutlet outlet) {
    var outletName = outlet.name;
    if (isBlank(outletName)) {
      throw new BaseException(
          '''registerAuxOutlet expects to be called with an outlet with a name.''');
    }
    var router = this.auxRouter(this.hostComponent);
    this._auxRouters[outletName] = router;
    router._outlet = outlet;
    var auxInstruction;
    if (isPresent(this.currentInstruction) &&
        isPresent(auxInstruction =
            this.currentInstruction.auxInstruction[outletName])) {
      return router.commit(auxInstruction);
    }
    return _resolveToTrue;
  }

  /**
   * Given an instruction, returns `true` if the instruction is currently active,
   * otherwise `false`.
   */
  bool isRouteActive(Instruction instruction) {
    Router router = this;
    if (isBlank(this.currentInstruction)) {
      return false;
    }
    // `instruction` corresponds to the root router
    while (isPresent(router.parent) && isPresent(instruction.child)) {
      router = router.parent;
      instruction = instruction.child;
    }
    if (isBlank(instruction.component) ||
        isBlank(this.currentInstruction.component) ||
        this.currentInstruction.component.routeName !=
            instruction.component.routeName) {
      return false;
    }
    var paramEquals = true;
    if (isPresent(this.currentInstruction.component.params)) {
      StringMapWrapper.forEach(instruction.component.params, (value, key) {
        if (!identical(this.currentInstruction.component.params[key], value)) {
          paramEquals = false;
        }
      });
    }
    return paramEquals;
  }

  /**
   * Dynamically update the routing configuration and trigger a navigation.
   *
   * ### Usage
   *
   * ```
   * router.config([
   *   { 'path': '/', 'component': IndexComp },
   *   { 'path': '/user/:id', 'component': UserComp },
   * ]);
   * ```
   */
  Future<dynamic> config(List<RouteDefinition> definitions) {
    definitions.forEach((routeDefinition) {
      this.registry.config(this.hostComponent, routeDefinition);
    });
    return this.renavigate();
  }

  /**
   * Navigate based on the provided Route Link DSL. It's preferred to navigate with this method
   * over `navigateByUrl`.
   *
   * ### Usage
   *
   * This method takes an array representing the Route Link DSL:
   * ```
   * ['./MyCmp', {param: 3}]
   * ```
   * See the [RouterLink] directive for more.
   */
  Future<dynamic> navigate(List<dynamic> linkParams) {
    var instruction = this.generate(linkParams);
    return this.navigateByInstruction(instruction, false);
  }

  /**
   * Navigate to a URL. Returns a promise that resolves when navigation is complete.
   * It's preferred to navigate with `navigate` instead of this method, since URLs are more brittle.
   *
   * If the given URL begins with a `/`, router will navigate absolutely.
   * If the given URL does not begin with `/`, the router will navigate relative to this component.
   */
  Future<dynamic> navigateByUrl(String url,
      [bool _skipLocationChange = false]) {
    return this._currentNavigation = this._currentNavigation.then((_) {
      this.lastNavigationAttempt = url;
      this._startNavigating();
      return this._afterPromiseFinishNavigating(
          this.recognize(url).then((instruction) {
        if (isBlank(instruction)) {
          return false;
        }
        return this._navigate(instruction, _skipLocationChange);
      }));
    });
  }

  /**
   * Navigate via the provided instruction. Returns a promise that resolves when navigation is
   * complete.
   */
  Future<dynamic> navigateByInstruction(Instruction instruction,
      [bool _skipLocationChange = false]) {
    if (isBlank(instruction)) {
      return _resolveToFalse;
    }
    return this._currentNavigation = this._currentNavigation.then((_) {
      this._startNavigating();
      return this._afterPromiseFinishNavigating(
          this._navigate(instruction, _skipLocationChange));
    });
  }

  /** @internal */
  Future<dynamic> _settleInstruction(Instruction instruction) {
    return instruction.resolveComponent().then((_) {
      List<Future<dynamic>> unsettledInstructions = [];
      if (isPresent(instruction.component)) {
        instruction.component.reuse = false;
      }
      if (isPresent(instruction.child)) {
        unsettledInstructions.add(this._settleInstruction(instruction.child));
      }
      StringMapWrapper.forEach(instruction.auxInstruction,
          (Instruction instruction, _) {
        unsettledInstructions.add(this._settleInstruction(instruction));
      });
      return PromiseWrapper.all(unsettledInstructions);
    });
  }

  /** @internal */
  Future<dynamic> _navigate(Instruction instruction, bool _skipLocationChange) {
    return this
        ._settleInstruction(instruction)
        .then((_) => this._routerCanReuse(instruction))
        .then((_) => this._canActivate(instruction))
        .then((bool result) {
      if (!result) {
        return false;
      }
      return this._routerCanDeactivate(instruction).then((bool result) {
        if (result) {
          return this.commit(instruction, _skipLocationChange).then((_) {
            this._emitNavigationFinish(instruction.toRootUrl());
            return true;
          });
        }
      });
    });
  }

  void _emitNavigationFinish(url) {
    ObservableWrapper.callEmit(this._subject, url);
  }

  /** @internal */
  void _emitNavigationFail(url) {
    ObservableWrapper.callError(this._subject, url);
  }

  Future<dynamic> _afterPromiseFinishNavigating(Future<dynamic> promise) {
    return PromiseWrapper
        .catchError(promise.then((_) => this._finishNavigating()), (err) {
      this._finishNavigating();
      throw err;
    });
  }
  /*
   * Recursively set reuse flags
   */

  /** @internal */
  Future<dynamic> _routerCanReuse(Instruction instruction) {
    if (isBlank(this._outlet)) {
      return _resolveToFalse;
    }
    if (isBlank(instruction.component)) {
      return _resolveToTrue;
    }
    return this._outlet.routerCanReuse(instruction.component).then((result) {
      instruction.component.reuse = result;
      if (result &&
          isPresent(this._childRouter) &&
          isPresent(instruction.child)) {
        return this._childRouter._routerCanReuse(instruction.child);
      }
    });
  }

  Future<bool> _canActivate(Instruction nextInstruction) {
    return canActivateOne(nextInstruction, this.currentInstruction);
  }

  Future<bool> _routerCanDeactivate(Instruction instruction) {
    if (isBlank(this._outlet)) {
      return _resolveToTrue;
    }
    Future<bool> next;
    Instruction childInstruction = null;
    bool reuse = false;
    ComponentInstruction componentInstruction = null;
    if (isPresent(instruction)) {
      childInstruction = instruction.child;
      componentInstruction = instruction.component;
      reuse = isBlank(instruction.component) || instruction.component.reuse;
    }
    if (reuse) {
      next = _resolveToTrue;
    } else {
      next = this._outlet.routerCanDeactivate(componentInstruction);
    }
    // TODO: aux route lifecycle hooks
    return next.then(/* dynamic /* bool | Future< bool > */ */ (result) {
      if (result == false) {
        return false;
      }
      if (isPresent(this._childRouter)) {
        // TODO: ideally, this closure would map to async-await in Dart.

        // For now, casting to any to suppress an error.
        return (this._childRouter._routerCanDeactivate(childInstruction)
            as dynamic);
      }
      return true;
    });
  }

  /**
   * Updates this router and all descendant routers according to the given instruction
   */
  Future<dynamic> commit(Instruction instruction,
      [bool _skipLocationChange = false]) {
    this.currentInstruction = instruction;
    Future<dynamic> next = _resolveToTrue;
    if (isPresent(this._outlet) && isPresent(instruction.component)) {
      var componentInstruction = instruction.component;
      if (componentInstruction.reuse) {
        next = this._outlet.reuse(componentInstruction);
      } else {
        var outlet = this._outlet;
        next = this
            .deactivate(instruction)
            .then((_) => outlet.activate(componentInstruction));
      }
      if (isPresent(instruction.child)) {
        next = next.then((_) {
          if (isPresent(this._childRouter)) {
            return this._childRouter.commit(instruction.child);
          }
        });
      }
    }
    List<Future<dynamic>> promises = [];
    this._auxRouters.forEach((name, router) {
      if (isPresent(instruction.auxInstruction[name])) {
        promises.add(router.commit(instruction.auxInstruction[name]));
      }
    });
    return next.then((_) => PromiseWrapper.all(promises));
  }

  /** @internal */
  void _startNavigating() {
    this.navigating = true;
  }

  /** @internal */
  void _finishNavigating() {
    this.navigating = false;
  }

  /**
   * Subscribe to URL updates from the router
   */
  Object subscribe(void onNext(dynamic value), [void onError(dynamic value)]) {
    return ObservableWrapper.subscribe(this._subject, onNext, onError);
  }

  /**
   * Removes the contents of this router's outlet and all descendant outlets
   */
  Future<dynamic> deactivate(Instruction instruction) {
    Instruction childInstruction = null;
    ComponentInstruction componentInstruction = null;
    if (isPresent(instruction)) {
      childInstruction = instruction.child;
      componentInstruction = instruction.component;
    }
    Future<dynamic> next = _resolveToTrue;
    if (isPresent(this._childRouter)) {
      next = this._childRouter.deactivate(childInstruction);
    }
    if (isPresent(this._outlet)) {
      var outlet = this._outlet;
      next = next.then((_) => outlet.deactivate(componentInstruction));
    }
    // TODO: handle aux routes
    return next;
  }

  /**
   * Given a URL, returns an instruction representing the component graph
   */
  Future<Instruction> recognize(String url) {
    var ancestorComponents = this._getAncestorInstructions();
    return this.registry.recognize(url, ancestorComponents);
  }

  List<Instruction> _getAncestorInstructions() {
    List<Instruction> ancestorInstructions = [this.currentInstruction];
    Router ancestorRouter = this;
    while (isPresent(ancestorRouter = ancestorRouter.parent)) {
      (ancestorInstructions..insert(0, ancestorRouter.currentInstruction))
          .length;
    }
    return ancestorInstructions;
  }

  /**
   * Navigates to either the last URL successfully navigated to, or the last URL requested if the
   * router has yet to successfully navigate.
   */
  Future<dynamic> renavigate() {
    if (isBlank(this.lastNavigationAttempt)) {
      return this._currentNavigation;
    }
    return this.navigateByUrl(this.lastNavigationAttempt);
  }

  /**
   * Generate an `Instruction` based on the provided Route Link DSL.
   */
  Instruction generate(List<dynamic> linkParams) {
    var ancestorInstructions = this._getAncestorInstructions();
    return this.registry.generate(linkParams, ancestorInstructions);
  }
}

@Injectable()
class RootRouter extends Router {
  /** @internal */
  Location _location;
  /** @internal */
  Object _locationSub;
  RootRouter(RouteRegistry registry, Location location,
      @Inject(ROUTER_PRIMARY_COMPONENT) Type primaryComponent)
      : super(registry, null, primaryComponent) {
    /* super call moved to initializer */;
    this.root = this;
    this._location = location;
    this._locationSub = this._location.subscribe((change) {
      // we call recognize ourselves
      this.recognize(change["url"]).then((instruction) {
        if (isPresent(instruction)) {
          this
              .navigateByInstruction(instruction, isPresent(change["pop"]))
              .then((_) {
            // this is a popstate event; no need to change the URL
            if (isPresent(change["pop"]) && change["type"] != "hashchange") {
              return;
            }
            var emitPath = instruction.toUrlPath();
            var emitQuery = instruction.toUrlQuery();
            if (emitPath.length > 0 && emitPath[0] != "/") {
              emitPath = "/" + emitPath;
            }
            // We've opted to use pushstate and popState APIs regardless of whether you

            // an app uses HashLocationStrategy or PathLocationStrategy.

            // However, apps that are migrating might have hash links that operate outside

            // angular to which routing must respond.

            // Therefore we know that all hashchange events occur outside Angular.

            // To support these cases where we respond to hashchanges and redirect as a

            // result, we need to replace the top item on the stack.
            if (change["type"] == "hashchange") {
              if (instruction.toRootUrl() != this._location.path()) {
                this._location.replaceState(emitPath, emitQuery);
              }
            } else {
              this._location.go(emitPath, emitQuery);
            }
          });
        } else {
          this._emitNavigationFail(change["url"]);
        }
      });
    });
    this.registry.configFromComponent(primaryComponent);
    this.navigateByUrl(location.path());
  }
  Future<dynamic> commit(Instruction instruction,
      [bool _skipLocationChange = false]) {
    var emitPath = instruction.toUrlPath();
    var emitQuery = instruction.toUrlQuery();
    if (emitPath.length > 0 && emitPath[0] != "/") {
      emitPath = "/" + emitPath;
    }
    var promise = super.commit(instruction);
    if (!_skipLocationChange) {
      promise = promise.then((_) {
        this._location.go(emitPath, emitQuery);
      });
    }
    return promise;
  }

  void dispose() {
    if (isPresent(this._locationSub)) {
      ObservableWrapper.dispose(this._locationSub);
      this._locationSub = null;
    }
  }
}

class ChildRouter extends Router {
  ChildRouter(Router parent, hostComponent)
      : super(parent.registry, parent, hostComponent, parent.root) {
    /* super call moved to initializer */;
    this.parent = parent;
  }
  Future<dynamic> navigateByUrl(String url,
      [bool _skipLocationChange = false]) {
    // Delegate navigation to the root router
    return this.parent.navigateByUrl(url, _skipLocationChange);
  }

  Future<dynamic> navigateByInstruction(Instruction instruction,
      [bool _skipLocationChange = false]) {
    // Delegate navigation to the root router
    return this.parent.navigateByInstruction(instruction, _skipLocationChange);
  }
}

Future<bool> canActivateOne(
    Instruction nextInstruction, Instruction prevInstruction) {
  var next = _resolveToTrue;
  if (isBlank(nextInstruction.component)) {
    return next;
  }
  if (isPresent(nextInstruction.child)) {
    next = canActivateOne(nextInstruction.child,
        isPresent(prevInstruction) ? prevInstruction.child : null);
  }
  return next.then(/* bool */ (bool result) {
    if (result == false) {
      return false;
    }
    if (nextInstruction.component.reuse) {
      return true;
    }
    var hook = getCanActivateHook(nextInstruction.component.componentType);
    if (isPresent(hook)) {
      return hook(nextInstruction.component,
          isPresent(prevInstruction) ? prevInstruction.component : null);
    }
    return true;
  });
}
