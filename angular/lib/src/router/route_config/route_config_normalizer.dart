import 'dart:async';

import "package:angular/src/facade/exceptions.dart" show BaseException;

import "../route_definition.dart";
import "../route_registry.dart";
import "route_config_decorator.dart";

RouteDefinition normalizeRouteConfig(
    RouteDefinition config, RouteRegistry registry) {
  if (config is AsyncRoute) {
    Future loader() async {
      var value = await config.loader();
      registry.configFromComponent(value);
      return value;
    }

    return new AsyncRoute(
        path: config.path,
        loader: loader,
        name: config.name,
        data: config.data,
        useAsDefault: config.useAsDefault);
  }
  return config;
}

void assertComponentExists(dynamic component, String path) {
  if (component == null) {
    throw new BaseException(
        'Component for route "$path" is not defined, or is not a class.');
  }
}
