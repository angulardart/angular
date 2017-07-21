import 'dart:async';

import '../route_definition.dart' show RouteDefinition;
import '../rules/route_paths/regex_route_path.dart' show RegexSerializer;

export '../route_definition.dart' show RouteDefinition;

/// The [RouteConfig] decorator defines routes for a given component.
///
/// ### Example
///
/// Here is an example from the [tutorial on routing][routing]:
///
/// <?code-excerpt "docs/toh-5/lib/app_component.dart (routes)"?>
/// ```dart
/// @RouteConfig(const [
///   const Route(
///       path: '/dashboard',
///       name: 'Dashboard',
///       component: DashboardComponent,
///       useAsDefault: true),
///   const Route(
///       path: '/detail/:id', name: 'HeroDetail', component: HeroDetailComponent),
///   const Route(path: '/heroes', name: 'Heroes', component: HeroesComponent)
/// ])
/// ```
///
/// [routing]: https://webdev.dartlang.org/angular/tutorial/toh-pt5.html#configure-routes
class RouteConfig {
  final List<RouteDefinition> configs;
  const RouteConfig(this.configs);
}

abstract class AbstractRoute implements RouteDefinition {
  final String name;
  final bool useAsDefault;
  final String path;
  final String regex;
  final RegexSerializer serializer;
  final data;
  const AbstractRoute(
      {String name,
      bool useAsDefault,
      String path,
      String regex,
      RegexSerializer serializer,
      dynamic data})
      : name = name,
        useAsDefault = useAsDefault,
        path = path,
        regex = regex,
        serializer = serializer,
        data = data;
}

/// `Route` is a type of [RouteDefinition] used to route a path to a component.
///
/// It has the following properties:
/// - `path` is a string that uses the route matcher DSL.
/// - `component` a component type.
/// - `name` is an optional `CamelCase` string representing the name of the
///   route.
/// - `data` is an optional property of any type representing arbitrary route
///   metadata for the given route. It is injectable via [RouteData].
/// - `useAsDefault` is a boolean value. If `true`, the child route will be
///   navigated to if no child route is specified during the navigation.
///
/// ### Example
/// ```
/// import 'package:angular/router.dart';
///
/// @RouteConfig(const [
///   const Route(path: '/home', component: HomeCmp, name: 'HomeCmp'),
/// ])
/// class MyApp {}
/// ```
class Route extends AbstractRoute {
  final dynamic component;
  final String aux = null;
  const Route(
      {String name,
      bool useAsDefault,
      String path,
      String regex,
      RegexSerializer serializer,
      dynamic data,
      dynamic /* Type | ComponentFactory | ComponentDefinition */ component})
      : component = component,
        super(
            name: name,
            useAsDefault: useAsDefault,
            path: path,
            regex: regex,
            serializer: serializer,
            data: data);
}

/// `AuxRoute` is a type of [RouteDefinition] used to define an auxiliary route.
///
/// It takes an object with the following properties:
/// - `path` is a string that uses the route matcher DSL.
/// - `component` a component type.
/// - `name` is an optional `CamelCase` string representing the name of the route.
/// - `data` is an optional property of any type representing arbitrary route
///   metadata for the given route. It is injectable via [RouteData].
///
/// ### Example
/// ```
/// import 'package:angular/router.dart';
///
/// @RouteConfig(const [
///   const AuxRoute(path: '/home', component: HomeCmp),
/// ])
/// class MyApp {}
/// ```
class AuxRoute extends AbstractRoute {
  final dynamic component;
  const AuxRoute(
      {String name,
      bool useAsDefault,
      String path,
      String regex,
      RegexSerializer serializer,
      dynamic data,
      dynamic /* Type | ComponentFactory | ComponentDefinition */ component})
      : component = component,
        super(
            name: name,
            useAsDefault: useAsDefault,
            path: path,
            regex: regex,
            serializer: serializer,
            data: data);
}

/// `AsyncRoute` is a type of [RouteDefinition] used to route a path to an asynchronously
/// loaded component.
///
/// It has the following properties:
/// - `path` is a string that uses the route matcher DSL.
/// - `loader` is a function that returns a promise that resolves to a component.
/// - `name` is an optional `CamelCase` string representing the name of the route.
/// - `data` is an optional property of any type representing arbitrary route
///   metadata for the given route. It is injectable via [RouteData].
/// - `useAsDefault` is a boolean value. If `true`, the child route will be
///   navigated to if no child route is specified during the navigation.
///
/// ### Example
/// ```
/// import 'package:angular/router.dart';
/// import 'package:my_package/my_component.dart' deferred as my_component;
///
/// @RouteConfig(const [
///   const AsyncRoute(path: '/home', loader: l, name: 'MyLoadedCmp'),
/// ])
/// class MyApp {}
///
/// l() => my_component.loadLibrary().then((_) => my_component.MyLoadedCmp);
/// ```
class AsyncRoute extends AbstractRoute {
  final Function /* () => Promise<Type> */ loader;
  final String aux = null;
  const AsyncRoute(
      {String name,
      bool useAsDefault,
      String path,
      String regex,
      RegexSerializer serializer,
      dynamic data,
      Future loader()})
      : loader = loader,
        super(
            name: name,
            useAsDefault: useAsDefault,
            path: path,
            regex: regex,
            serializer: serializer,
            data: data);
}

/// `Redirect` is a type of [RouteDefinition] used to route a path to a canonical route.
///
/// It has the following properties:
/// - `path` is a string that uses the route matcher DSL.
/// - `redirectTo` is an array representing the link DSL.
///
/// Note that redirects **do not** affect how links are generated. For that, see the `useAsDefault`
/// option.
///
/// ### Example
/// ```
/// import 'package:angular/router.dart';
///
/// @RouteConfig(const [
///   const Redirect(path: '/', redirectTo: const ['/Home']),
///   const Route(path: '/home', component: HomeCmp, name: 'Home'),
/// ])
/// class MyApp {}
/// ```
class Redirect extends AbstractRoute {
  final List<dynamic> redirectTo;
  const Redirect(
      {String name,
      bool useAsDefault,
      String path,
      String regex,
      RegexSerializer serializer,
      dynamic data,
      List<dynamic> redirectTo})
      : redirectTo = redirectTo,
        super(
            name: name,
            useAsDefault: useAsDefault,
            path: path,
            regex: regex,
            serializer: serializer,
            data: data);
}
