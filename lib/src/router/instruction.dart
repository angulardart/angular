library angular2.src.router.instruction;

import "dart:async";
import "package:angular2/src/facade/collection.dart"
    show Map, MapWrapper, StringMapWrapper, ListWrapper;
import "package:angular2/src/facade/lang.dart" show isPresent, isBlank, Type;
import "package:angular2/src/facade/async.dart" show PromiseWrapper;

/**
 * `RouteParams` is an immutable map of parameters for the given route
 * based on the url matcher and optional parameters for that route.
 *
 * You can inject `RouteParams` into the constructor of a component to use it.
 *
 * ### Example
 *
 * ```
 * import {Component} from 'angular2/core';
 * import {bootstrap} from 'angular2/platform/browser';
 * import {Router, ROUTER_DIRECTIVES, ROUTER_PROVIDERS, RouteConfig, RouteParams} from
 * 'angular2/router';
 *
 * @Component({directives: [ROUTER_DIRECTIVES]})
 * @RouteConfig([
 *  {path: '/user/:id', component: UserCmp, name: 'UserCmp'},
 * ])
 * class AppCmp {}
 *
 * @Component({ template: 'user: {{id}}' })
 * class UserCmp {
 *   id: string;
 *   constructor(params: RouteParams) {
 *     this.id = params.get('id');
 *   }
 * }
 *
 * bootstrap(AppCmp, ROUTER_PROVIDERS);
 * ```
 */
class RouteParams {
  Map<String, String> params;
  RouteParams(this.params) {}
  String get(String param) {
    return StringMapWrapper.get(this.params, param);
  }
}

/**
 * `RouteData` is an immutable map of additional data you can configure in your [Route].
 *
 * You can inject `RouteData` into the constructor of a component to use it.
 *
 * ### Example
 *
 * ```
 * import {Component} from 'angular2/core';
 * import {bootstrap} from 'angular2/platform/browser';
 * import {Router, ROUTER_DIRECTIVES, ROUTER_PROVIDERS, RouteConfig, RouteData} from
 * 'angular2/router';
 *
 * @Component({directives: [ROUTER_DIRECTIVES]})
 * @RouteConfig([
 *  {path: '/user/:id', component: UserCmp, name: 'UserCmp', data: {isAdmin: true}},
 * ])
 * class AppCmp {}
 *
 * @Component({
 *   ...,
 *   template: 'user: {{isAdmin}}'
 * })
 * class UserCmp {
 *   string: isAdmin;
 *   constructor(data: RouteData) {
 *     this.isAdmin = data.get('isAdmin');
 *   }
 * }
 *
 * bootstrap(AppCmp, ROUTER_PROVIDERS);
 * ```
 */
class RouteData {
  Map<String, dynamic> data;
  RouteData([this.data = const {}]) {}
  dynamic get(String key) {
    return StringMapWrapper.get(this.data, key);
  }
}

var BLANK_ROUTE_DATA = new RouteData();

/**
 * `Instruction` is a tree of [ComponentInstruction]s with all the information needed
 * to transition each component in the app to a given route, including all auxiliary routes.
 *
 * `Instruction`s can be created using [Router#generate], and can be used to
 * perform route changes with [Router#navigateByInstruction].
 *
 * ### Example
 *
 * ```
 * import {Component} from 'angular2/core';
 * import {bootstrap} from 'angular2/platform/browser';
 * import {Router, ROUTER_DIRECTIVES, ROUTER_PROVIDERS, RouteConfig} from 'angular2/router';
 *
 * @Component({directives: [ROUTER_DIRECTIVES]})
 * @RouteConfig([
 *  {...},
 * ])
 * class AppCmp {
 *   constructor(router: Router) {
 *     var instruction = router.generate(['/MyRoute']);
 *     router.navigateByInstruction(instruction);
 *   }
 * }
 *
 * bootstrap(AppCmp, ROUTER_PROVIDERS);
 * ```
 */
abstract class Instruction {
  ComponentInstruction component;
  Instruction child;
  Map<String, Instruction> auxInstruction;
  Instruction(this.component, this.child, this.auxInstruction) {}
  String get urlPath {
    return isPresent(this.component) ? this.component.urlPath : "";
  }

  List<String> get urlParams {
    return isPresent(this.component) ? this.component.urlParams : [];
  }

  String get specificity {
    var total = "";
    if (isPresent(this.component)) {
      total += this.component.specificity;
    }
    if (isPresent(this.child)) {
      total += this.child.specificity;
    }
    return total;
  }

  Future<ComponentInstruction> resolveComponent();
  /**
   * converts the instruction into a URL string
   */
  String toRootUrl() {
    return this.toUrlPath() + this.toUrlQuery();
  }

  /** @internal */
  String _toNonRootUrl() {
    return this._stringifyPathMatrixAuxPrefixed() +
        (isPresent(this.child) ? this.child._toNonRootUrl() : "");
  }

  String toUrlQuery() {
    return this.urlParams.length > 0 ? ("?" + this.urlParams.join("&")) : "";
  }

  /**
   * Returns a new instruction that shares the state of the existing instruction, but with
   * the given child [Instruction] replacing the existing child.
   */
  Instruction replaceChild(Instruction child) {
    return new ResolvedInstruction(this.component, child, this.auxInstruction);
  }

  /**
   * If the final URL for the instruction is ``
   */
  String toUrlPath() {
    return this.urlPath +
        this._stringifyAux() +
        (isPresent(this.child) ? this.child._toNonRootUrl() : "");
  }

  // default instructions override these
  String toLinkUrl() {
    return this.urlPath +
        this._stringifyAux() +
        (isPresent(this.child) ? this.child._toLinkUrl() : "") +
        this.toUrlQuery();
  }
  // this is the non-root version (called recursively)

  /** @internal */
  String _toLinkUrl() {
    return this._stringifyPathMatrixAuxPrefixed() +
        (isPresent(this.child) ? this.child._toLinkUrl() : "");
  }

  /** @internal */
  String _stringifyPathMatrixAuxPrefixed() {
    var primary = this._stringifyPathMatrixAux();
    if (primary.length > 0) {
      primary = "/" + primary;
    }
    return primary;
  }

  /** @internal */
  String _stringifyMatrixParams() {
    return this.urlParams.length > 0 ? (";" + this.urlParams.join(";")) : "";
  }

  /** @internal */
  String _stringifyPathMatrixAux() {
    if (isBlank(this.component)) {
      return "";
    }
    return this.urlPath + this._stringifyMatrixParams() + this._stringifyAux();
  }

  /** @internal */
  String _stringifyAux() {
    var routes = [];
    StringMapWrapper.forEach(this.auxInstruction,
        (Instruction auxInstruction, String _) {
      routes.add(auxInstruction._stringifyPathMatrixAux());
    });
    if (routes.length > 0) {
      return "(" + routes.join("//") + ")";
    }
    return "";
  }
}

/**
 * a resolved instruction has an outlet instruction for itself, but maybe not for...
 */
class ResolvedInstruction extends Instruction {
  ResolvedInstruction(ComponentInstruction component, Instruction child,
      Map<String, Instruction> auxInstruction)
      : super(component, child, auxInstruction) {
    /* super call moved to initializer */;
  }
  Future<ComponentInstruction> resolveComponent() {
    return PromiseWrapper.resolve(this.component);
  }
}

/**
 * Represents a resolved default route
 */
class DefaultInstruction extends ResolvedInstruction {
  DefaultInstruction(ComponentInstruction component, DefaultInstruction child)
      : super(component, child, {}) {
    /* super call moved to initializer */;
  }
  String toLinkUrl() {
    return "";
  }

  /** @internal */
  String _toLinkUrl() {
    return "";
  }
}

/**
 * Represents a component that may need to do some redirection or lazy loading at a later time.
 */
class UnresolvedInstruction extends Instruction {
  dynamic /* () => Promise<Instruction> */ _resolver;
  String _urlPath;
  List<String> _urlParams;
  UnresolvedInstruction(this._resolver,
      [this._urlPath = "", this._urlParams = const []])
      : super(null, null, {}) {
    /* super call moved to initializer */;
  }
  String get urlPath {
    if (isPresent(this.component)) {
      return this.component.urlPath;
    }
    if (isPresent(this._urlPath)) {
      return this._urlPath;
    }
    return "";
  }

  List<String> get urlParams {
    if (isPresent(this.component)) {
      return this.component.urlParams;
    }
    if (isPresent(this._urlParams)) {
      return this._urlParams;
    }
    return [];
  }

  Future<ComponentInstruction> resolveComponent() {
    if (isPresent(this.component)) {
      return PromiseWrapper.resolve(this.component);
    }
    return this._resolver().then((Instruction instruction) {
      this.child = isPresent(instruction) ? instruction.child : null;
      return this.component =
          isPresent(instruction) ? instruction.component : null;
    });
  }
}

class RedirectInstruction extends ResolvedInstruction {
  String _specificity;
  RedirectInstruction(ComponentInstruction component, Instruction child,
      Map<String, Instruction> auxInstruction, this._specificity)
      : super(component, child, auxInstruction) {
    /* super call moved to initializer */;
  }
  String get specificity {
    return this._specificity;
  }
}

/**
 * A `ComponentInstruction` represents the route state for a single component.
 *
 * `ComponentInstructions` is a public API. Instances of `ComponentInstruction` are passed
 * to route lifecycle hooks, like [CanActivate].
 *
 * `ComponentInstruction`s are [hash consed](https://en.wikipedia.org/wiki/Hash_consing). You should
 * never construct one yourself with "new." Instead, rely on router's internal recognizer to
 * construct `ComponentInstruction`s.
 *
 * You should not modify this object. It should be treated as immutable.
 */
class ComponentInstruction {
  String urlPath;
  List<String> urlParams;
  var componentType;
  bool terminal;
  String specificity;
  Map<String, String> params;
  String routeName;
  bool reuse = false;
  RouteData routeData;
  /**
   * @internal
   */
  ComponentInstruction(this.urlPath, this.urlParams, RouteData data,
      this.componentType, this.terminal, this.specificity,
      [this.params = null, this.routeName]) {
    this.routeData = isPresent(data) ? data : BLANK_ROUTE_DATA;
  }
}
