import "dart:async";

import "package:angular2/src/facade/lang.dart" show isPresent;

import "../../instruction.dart" show RouteData, BLANK_ROUTE_DATA;
import "route_handler.dart" show RouteHandler;

class AsyncRouteHandler implements RouteHandler {
  dynamic /* () => Promise<any /*Type | ComponentFactory*/> */ _loader;
  /** @internal */
  Future<dynamic> _resolvedComponent = null;
  dynamic componentType;
  RouteData data;
  AsyncRouteHandler(this._loader, [Map<String, dynamic> data = null]) {
    this.data = isPresent(data) ? new RouteData(data) : BLANK_ROUTE_DATA;
  }
  Future<dynamic> resolveComponentType() {
    if (isPresent(this._resolvedComponent)) {
      return this._resolvedComponent;
    }
    return this._resolvedComponent = this._loader().then((componentType) {
      this.componentType = componentType;
      return componentType;
    });
  }
}
