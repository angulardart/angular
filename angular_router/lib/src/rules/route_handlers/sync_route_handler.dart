import 'dart:async';

import '../../instruction.dart' show RouteData, BLANK_ROUTE_DATA;
import 'route_handler.dart' show RouteHandler;

class SyncRouteHandler implements RouteHandler {
  dynamic componentType;
  RouteData data;
  Future<dynamic> _resolvedComponent;
  SyncRouteHandler(this.componentType, [Map<String, dynamic> data]) {
    this._resolvedComponent = new Future.value(componentType);
    this.data = data != null ? new RouteData(data) : BLANK_ROUTE_DATA;
  }
  Future<dynamic> resolveComponentType() {
    return this._resolvedComponent;
  }
}
