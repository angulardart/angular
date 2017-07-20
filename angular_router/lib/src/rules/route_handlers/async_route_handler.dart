import 'dart:async';

import '../../instruction.dart' show RouteData, BLANK_ROUTE_DATA;
import 'route_handler.dart' show RouteHandler;

class AsyncRouteHandler implements RouteHandler {
  dynamic /* () => Promise<any /*Type | ComponentFactory*/> */ _loader;
  Future<dynamic> _resolvedComponent;
  dynamic componentType;
  RouteData data;
  AsyncRouteHandler(this._loader, [Map<String, dynamic> data = null]) {
    this.data = data != null ? new RouteData(data) : BLANK_ROUTE_DATA;
  }
  Future<dynamic> resolveComponentType() {
    if (this._resolvedComponent != null) {
      return this._resolvedComponent;
    }
    return this._resolvedComponent = this._loader().then((componentType) {
      this.componentType = componentType;
      return componentType;
    });
  }
}
