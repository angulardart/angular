library angular2.src.router.rules.route_handlers.route_handler;

import "dart:async";
import "package:angular2/src/facade/lang.dart" show Type;
import "../../instruction.dart" show RouteData;

abstract class RouteHandler {
  Type componentType;
  Future<dynamic> resolveComponentType();
  RouteData data;
}
