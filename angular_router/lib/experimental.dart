import 'dart:async';
import 'dart:math';

import 'package:angular/angular.dart';

import 'angular_router.dart';
import 'src/route_definition.dart' show LoadComponentAsync;

/// Overwrites [current] route in [outlet] with [componentFactoryOrLoader].
///
/// The [componentFactoryOrLoader] may either be a [ComponentFactory] or
/// [LoadComponentAsync] for a deferred route.
///
/// This function is reserved for compatibility purposes. Only use this if you
/// need to asynchronously load your route definitions.
///
/// To use this function, your router outlet host must define a placeholder
/// route definition that matches anything.
///
/// ```dart
/// routes = [
///   new RouteDefinition(
///     path: '/.*',
///     component: placeholder.PlaceholderComponentNgFactory,
///   ),
/// ];
/// ```
///
/// Upon activation, asynchronously load your route definitions, then invoke
/// this function to replace the placeholder route.
///
/// ```dart
/// @ViewChild
/// RouterOutlet routerOutlet;
///
/// @override
/// void onActivate(RouterState previous, RouterState current) {
///   _loadRoutes(current).then((_) {
///     final componentFactory = _componentFactoryForRouterState(current);
///     overwriteActiveRoute(routerOutlet, current, componentFactory);
///   });
/// }
/// ```
@Deprecated("Use 'reload' and 'replace' navigation parameters instead.")
Future<Null> overwriteActiveRoute<T>(
  RouterOutlet outlet,
  RouterState current,
  dynamic componentFactoryOrLoader,
) {
  return _getComponentFactory(componentFactoryOrLoader)
      .then((componentFactory) {
    final numParentRoutes = max(current.routes.length - 1, 0);
    final leafRoute = current.routes.last;
    // Replace component factory in leaf route definition.
    final updatedLeafRoute = RouteDefinition(
        path: leafRoute.path,
        component: componentFactory,
        additionalData: leafRoute.additionalData);
    // Replace leaf route with updated definition.
    final updatedRoutes = current.routes.sublist(0, numParentRoutes)
      ..add(updatedLeafRoute);
    final newState = RouterState(current.path, updatedRoutes,
        parameters: current.parameters,
        fragment: current.fragment,
        queryParameters: current.queryParameters);
    // Activate updated route.
    return outlet.activate(componentFactory, current, newState);
  });
}

/// Loads, if necessary, and returns a [ComponentFactory].
Future<ComponentFactory> _getComponentFactory(
    dynamic componentFactoryOrLoader) {
  if (componentFactoryOrLoader is ComponentFactory) {
    return Future.value(componentFactoryOrLoader);
  } else if (componentFactoryOrLoader is LoadComponentAsync) {
    return componentFactoryOrLoader();
  }
  throw ArgumentError.value(
    componentFactoryOrLoader,
    'componentFactoryOrLoader',
    'Expected $ComponentFactory or $LoadComponentAsync',
  );
}
