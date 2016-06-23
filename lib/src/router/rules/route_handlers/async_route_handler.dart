library angular2.src.router.rules.route_handlers.async_route_handler;

import "dart:async";
import "package:angular2/src/facade/lang.dart" show isPresent, Type;
import "route_handler.dart" show RouteHandler;
import "../../instruction.dart" show RouteData, BLANK_ROUTE_DATA;

class AsyncRouteHandler implements RouteHandler {
  dynamic /* () => Promise<Type> */ _loader;
  /** @internal */
  Future<Type> _resolvedComponent = null;
  Type componentType;
  RouteData data;
  AsyncRouteHandler(this._loader, [Map<String, dynamic> data = null]) {
    this.data = isPresent(data) ? new RouteData(data) : BLANK_ROUTE_DATA;
  }
  Future<Type> resolveComponentType() {
    if (isPresent(this._resolvedComponent)) {
      return this._resolvedComponent;
    }
    return this._resolvedComponent = this._loader().then((componentType) {
      this.componentType = componentType;
      return componentType;
    });
  }
}
