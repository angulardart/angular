import 'dart:async';

import '../../instruction.dart' show RouteData;

abstract class RouteHandler {
  dynamic componentType;
  Future<dynamic> resolveComponentType();
  RouteData data;
}
