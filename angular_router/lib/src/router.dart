import 'dart:async';

import 'package:angular/angular.dart' show Inject, Injectable;

import 'directives/router_outlet.dart' show RouterOutlet;
import 'instruction.dart' show ComponentInstruction, Instruction;
import 'location.dart' show Location, PathLocationStrategy;
import 'route_config/route_config_decorator.dart' show RouteDefinition;
import 'route_registry.dart' show RouteRegistry, ROUTER_PRIMARY_COMPONENT;

final _resolveToTrue = new Future<bool>.value(true);
final _resolveToFalse = new Future<bool>.value(false);

/// The `Router` is responsible for mapping URLs to components.
///
/// You can see the state of the router by inspecting the read-only field `router.navigating`.
/// This may be useful for showing a spinner, for instance.
///
/// ## Concepts
///
/// Routers and component instances have a 1:1 correspondence.
///
/// The router holds reference to a number of [RouterOutlet].
/// An outlet is a placeholder that the router dynamically fills in depending on the current URL.
///
/// When the router navigates from a URL, it must first recognize it and serialize it into an
/// `Instruction`.
/// The router uses the `RouteRegistry` to get an `Instruction`.
@Injectable()
class Router {
  RouteRegistry registry;
  Router parent;
  dynamic hostComponent;
  Router root;
  bool navigating = false;
  String lastNavigationAttempt;

  /// The current `Instruction` for the router
  Instruction currentInstruction;
  Future<dynamic> _currentNavigation = _resolveToTrue;
  RouterOutlet _outlet;
  final _auxRouters = new Map<String, Router>();
  Router _childRouter;
  final _subject = new StreamController<dynamic>.broadcast();
  final _startNavigationEvent = new StreamController<String>.broadcast();
  Router(this.registry, this.parent, this.hostComponent, [this.root]);

  /// Constructs a child router. You probably don't need to use this unless
  /// you're writing a reusable component.
  Router childRouter(dynamic hostComponent) {
    return this._childRouter = new ChildRouter(this, hostComponent);
  }

  /// Constructs a child router. You probably don't need to use this unless
  /// you're writing a reusable component.
  Router auxRouter(dynamic hostComponent) {
    return new ChildRouter(this, hostComponent);
  }

  /// Register an outlet to be notified of primary route changes.
  ///
  /// You probably don't need to use this unless you're writing a reusable
  /// component.
  Future<dynamic> registerPrimaryOutlet(RouterOutlet outlet) {
    if (outlet.name != null) {
      throw new ArgumentError(
          'registerPrimaryOutlet expects to be called with an unnamed outlet.');
    }
    if (_outlet != null) {
      throw new StateError('Primary outlet is already registered.');
    }
    this._outlet = outlet;
    if (currentInstruction != null) {
      return this.commit(this.currentInstruction, false);
    }
    return _resolveToTrue;
  }

  /// Unregister an outlet (because it was destroyed, etc).
  ///
  /// You probably don't need to use this unless you're writing a custom outlet
  /// implementation.
  void unregisterPrimaryOutlet(RouterOutlet outlet) {
    if (outlet.name != null) {
      throw new ArgumentError(
          'registerPrimaryOutlet expects to be called with an unnamed outlet.');
    }
    this._outlet = null;
  }

  /// Register an outlet to notified of auxiliary route changes.
  ///
  /// You probably don't need to use this unless you're writing a reusable
  /// component.
  Future<dynamic> registerAuxOutlet(RouterOutlet outlet) {
    var outletName = outlet.name;
    if (outletName == null) {
      throw new ArgumentError(
          'registerAuxOutlet expects to be called with an outlet with a name.');
    }
    var router = this.auxRouter(this.hostComponent);
    this._auxRouters[outletName] = router;
    router._outlet = outlet;
    var auxInstruction;
    if (currentInstruction != null &&
        (auxInstruction = this.currentInstruction.auxInstruction[outletName]) !=
            null) {
      return router.commit(auxInstruction);
    }
    return _resolveToTrue;
  }

  /// Given an instruction, returns `true` if the instruction is currently
  /// active, otherwise `false`.
  bool isRouteActive(Instruction instruction) {
    Router router = this;
    if (currentInstruction == null) {
      return false;
    }
    // `instruction` corresponds to the root router
    while (router.parent != null && instruction.child != null) {
      router = router.parent;
      instruction = instruction.child;
    }
    if (instruction.component == null ||
        currentInstruction.component == null ||
        currentInstruction.component.routeName !=
            instruction.component.routeName) {
      return false;
    }
    var paramEquals = true;
    if (this.currentInstruction.component.params != null) {
      instruction.component.params.forEach((key, value) {
        if (!identical(this.currentInstruction.component.params[key], value)) {
          paramEquals = false;
        }
      });
    }
    return paramEquals;
  }

  /// Dynamically update the routing configuration and trigger a navigation.
  ///
  /// ### Usage
  ///
  /// ```
  /// router.config([
  ///   { 'path': '/', 'component': IndexComp },
  ///   { 'path': '/user/:id', 'component': UserComp },
  /// ]);
  /// ```
  Future<dynamic> config(List<RouteDefinition> definitions) {
    definitions.forEach((routeDefinition) {
      this.registry.config(this.hostComponent, routeDefinition);
    });
    return this.renavigate();
  }

  /// Navigate based on the provided Route Link DSL. It's preferred to navigate with this method
  /// over `navigateByUrl`.
  ///
  /// ### Usage
  ///
  /// This method takes an array representing the Route Link DSL:
  /// ```
  /// ['./MyCmp', {param: 3}]
  /// ```
  /// See the [RouterLink] directive for more.
  Future<dynamic> navigate(List<dynamic> linkParams) {
    var instruction = this.generate(linkParams);
    return this.navigateByInstruction(instruction, false);
  }

  /// Navigate to a URL. Returns a promise that resolves when navigation is complete.
  /// It's preferred to navigate with `navigate` instead of this method, since URLs are more brittle.
  ///
  /// If the given URL begins with a `/`, router will navigate absolutely.
  /// If the given URL does not begin with `/`, the router will navigate relative to this component.
  Future<dynamic> navigateByUrl(String url,
      [bool _skipLocationChange = false, bool _replaceState = false]) {
    return this._currentNavigation = this._currentNavigation.then((_) {
      this.lastNavigationAttempt = url;
      this._startNavigating(url);
      return this._afterPromiseFinishNavigating(
          this.recognize(url).then((instruction) {
        if (instruction == null) {
          return false;
        }
        return this._navigate(instruction, _skipLocationChange, _replaceState);
      }));
    });
  }

  /// Navigate via the provided instruction. Returns a promise that resolves when navigation is
  /// complete.
  Future<dynamic> navigateByInstruction(Instruction instruction,
      [bool _skipLocationChange = false, bool _replaceState = false]) {
    if (instruction == null) {
      return _resolveToFalse;
    }
    return this._currentNavigation = this._currentNavigation.then((_) {
      this._startNavigating(instruction.toLinkUrl());
      return this._afterPromiseFinishNavigating(
          this._navigate(instruction, _skipLocationChange, _replaceState));
    });
  }

  Future<dynamic> _settleInstruction(Instruction instruction) {
    return instruction.resolveComponent().then((_) {
      List<Future<dynamic>> unsettledInstructions = [];
      if (instruction.component != null) {
        instruction.component.reuse = false;
      }
      if (instruction.child != null) {
        unsettledInstructions.add(this._settleInstruction(instruction.child));
      }
      instruction.auxInstruction.forEach((_, Instruction instruction) {
        unsettledInstructions.add(this._settleInstruction(instruction));
      });
      return Future.wait(unsettledInstructions);
    });
  }

  Future<dynamic> _navigate(
      Instruction instruction, bool _skipLocationChange, bool _replaceState) {
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
          return this
              .commit(instruction, _skipLocationChange, _replaceState)
              .then((_) {
            this._emitNavigationFinish(instruction.rootUrl);
            return true;
          });
        }
      });
    });
  }

  void _emitNavigationFinish(url) {
    _subject.add(url);
  }

  void _emitNavigationFail(url) {
    _subject.addError(url);
  }

  Future<dynamic> _afterPromiseFinishNavigating(Future<dynamic> promise) {
    return promise.then((_) => _finishNavigating()).catchError((err) {
      _finishNavigating();
      throw err;
    });
  }
  /*
   * Recursively set reuse flags
   */

  Future<dynamic> _routerCanReuse(Instruction instruction) {
    if (_outlet == null) {
      return _resolveToFalse;
    }
    if (instruction.component == null) {
      return _resolveToTrue;
    }
    return this._outlet.routerCanReuse(instruction.component).then((result) {
      instruction.component.reuse = result;
      if (result && _childRouter != null && instruction.child != null) {
        return this._childRouter._routerCanReuse(instruction.child);
      }
    });
  }

  Future<bool> _canActivate(Instruction nextInstruction) {
    return canActivateOne(nextInstruction, this.currentInstruction);
  }

  Future<bool> _routerCanDeactivate(Instruction instruction) {
    if (_outlet == null) {
      return new Future.value(true);
    }
    Future<bool> next;
    Instruction childInstruction;
    bool reuse = false;
    ComponentInstruction componentInstruction;
    if (instruction != null) {
      childInstruction = instruction.child;
      componentInstruction = instruction.component;
      reuse = instruction.component?.reuse != false;
    }
    if (reuse) {
      next = new Future.value(true);
    } else {
      next = this._outlet.routerCanDeactivate(componentInstruction);
    }
    // TODO: aux route lifecycle hooks
    return next.then(/* dynamic /* bool | Future< bool > */ */ (result) async {
      if (result == false) {
        return false;
      }
      if (_childRouter != null) {
        return await this._childRouter._routerCanDeactivate(childInstruction);
      }
      return true;
    });
  }

  /// Updates this router and all descendant routers according to the given instruction
  Future<dynamic> commit(Instruction instruction,
      [bool _skipLocationChange = false, bool _replaceState = false]) {
    this.currentInstruction = instruction;
    Future<dynamic> next = _resolveToTrue;
    if (_outlet != null && instruction.component != null) {
      var componentInstruction = instruction.component;
      if (componentInstruction.reuse) {
        next = this._outlet.reuse(componentInstruction);
      } else {
        var outlet = this._outlet;
        next = this
            .deactivate(instruction)
            .then((_) => outlet.activate(componentInstruction));
      }
      if (instruction.child != null) {
        next = next.then((_) {
          if (_childRouter != null) {
            return this._childRouter.commit(instruction.child);
          }
        });
      }
    }
    List<Future<dynamic>> promises = [];
    this._auxRouters.forEach((name, router) {
      if (instruction.auxInstruction[name] != null) {
        promises.add(router.commit(instruction.auxInstruction[name]));
      }
    });
    return next.then((_) => Future.wait(promises));
  }

  void _startNavigating(String url) {
    this.navigating = true;
    _startNavigationEvent.add(url);
  }

  void _finishNavigating() {
    this.navigating = false;
  }

  /// Stream on router publishes URL it has starting navigating to.
  /// Use subscribe method below to be informed if navigation was successful.
  Stream<String> get onStartNavigation => _startNavigationEvent.stream;

  /// Subscribe to URL updates from the router
  Object subscribe(void onNext(dynamic value), [void onError(dynamic value)]) {
    return _subject.stream.listen(onNext, onError: onError);
  }

  /// Removes the contents of this router's outlet and all descendant outlets
  Future<dynamic> deactivate(Instruction instruction) {
    Instruction childInstruction;
    ComponentInstruction componentInstruction;
    if (instruction != null) {
      childInstruction = instruction.child;
      componentInstruction = instruction.component;
    }
    Future<dynamic> next = _resolveToTrue;
    if (_childRouter != null) {
      next = this._childRouter.deactivate(childInstruction);
    }
    if (_outlet != null) {
      var outlet = this._outlet;
      next = next.then((_) => outlet.deactivate(componentInstruction));
    }
    // TODO: handle aux routes
    return next;
  }

  /// Given a URL, returns an instruction representing the component graph
  Future<Instruction> recognize(String url) {
    var ancestorComponents = this._getAncestorInstructions();
    return this.registry.recognize(url, ancestorComponents);
  }

  List<Instruction> _getAncestorInstructions() {
    List<Instruction> ancestorInstructions = [this.currentInstruction];
    Router ancestorRouter = this;
    while ((ancestorRouter = ancestorRouter.parent) != null) {
      (ancestorInstructions..insert(0, ancestorRouter.currentInstruction))
          .length;
    }
    return ancestorInstructions;
  }

  /// Navigates to either the last URL successfully navigated to, or the last URL requested if the
  /// router has yet to successfully navigate.
  Future<dynamic> renavigate() {
    if (lastNavigationAttempt == null) {
      return _currentNavigation;
    }
    return navigateByUrl(lastNavigationAttempt);
  }

  /// Generate an `Instruction` based on the provided Route Link DSL.
  Instruction generate(List<dynamic> linkParams) {
    var ancestorInstructions = this._getAncestorInstructions();
    return this.registry.generate(linkParams, ancestorInstructions);
  }
}

@Injectable()
class RootRouter extends Router {
  final Location _location;
  var _locationSub;
  RootRouter(RouteRegistry registry, this._location,
      @Inject(ROUTER_PRIMARY_COMPONENT) dynamic primaryComponent)
      : super(registry, null, primaryComponent) {
    this.root = this;
    this._locationSub = this._location.subscribe((change) {
      // we call recognize ourselves
      this.recognize(change['url']).then((instruction) {
        if (instruction != null) {
          this
              .navigateByInstruction(instruction, change['pop'] != null)
              .then((_) {
            // this is a popstate event; no need to change the URL
            if (change['pop'] != null && change['type'] != 'hashchange') {
              return;
            }
            var emitPath = instruction.path;
            var emitQuery = instruction.toUrlQuery();
            if (emitPath.length == 0 || emitPath[0] != '/') {
              emitPath = '/' + emitPath;
            }
            // We've opted to use pushstate and popState APIs regardless of whether you

            // an app uses HashLocationStrategy or PathLocationStrategy.

            // However, apps that are migrating might have hash links that operate outside

            // angular to which routing must respond.

            // Therefore we know that all hashchange events occur outside Angular.

            // To support these cases where we respond to hashchanges and redirect as a

            // result, we need to replace the top item on the stack.
            if (change['type'] == 'hashchange') {
              if (instruction.rootUrl != this._location.path()) {
                this._location.replaceState(emitPath, emitQuery);
              }
            } else {
              this._location.go(emitPath, emitQuery);
            }
          });
        } else {
          this._emitNavigationFail(change['url']);
        }
      });
    });
    this.registry.configFromComponent(primaryComponent);
    this.navigateByUrl(_location.path());
  }
  Future<dynamic> commit(Instruction instruction,
      [bool _skipLocationChange = false, bool _replaceState = false]) {
    var emitPath = instruction.path;
    var emitQuery = instruction.toUrlQuery();
    if (emitPath.length == 0 || emitPath[0] != '/') {
      emitPath = '/' + emitPath;
    }
    if (_location.platformStrategy is PathLocationStrategy) {
      var hash = this._location.hash();
      if (hash.isNotEmpty) {
        var normalizedHash = hash.startsWith('#') ? hash : '#' + hash;
        emitQuery = (emitQuery ?? '') + normalizedHash;
      }
    }
    var promise = super.commit(instruction);
    if (!_skipLocationChange) {
      promise = promise.then((_) {
        if (_replaceState) {
          this._location.replaceState(emitPath, emitQuery);
        } else {
          this._location.go(emitPath, emitQuery);
        }
      });
    }
    return promise;
  }

  void dispose() {
    _locationSub?.cancel();
    _locationSub = null;
  }
}

class ChildRouter extends Router {
  ChildRouter(Router parent, hostComponent)
      : super(parent.registry, parent, hostComponent, parent.root) {
    this.parent = parent;
  }
  Future<dynamic> navigateByUrl(String url,
      [bool _skipLocationChange = false, bool _replaceState = false]) {
    // Delegate navigation to the root router
    return this.parent.navigateByUrl(url, _skipLocationChange, _replaceState);
  }

  Future<dynamic> navigateByInstruction(Instruction instruction,
      [bool _skipLocationChange = false, bool _replaceState = false]) {
    // Delegate navigation to the root router
    return this
        .parent
        .navigateByInstruction(instruction, _skipLocationChange, _replaceState);
  }
}

// TODO(matanl): Remove, CanActivate is no longer supported.
@deprecated
Future<bool> canActivateOne(_, __) => new Future.value(true);
