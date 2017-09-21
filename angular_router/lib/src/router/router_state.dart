// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:quiver/core.dart';
import 'package:angular/angular.dart' show ComponentFactory, ComponentRef;

import '../route_definition.dart';
import '../route_path.dart';
import '../url.dart';

/// Represents the state of the router, which is a URL and matching [routes].
class RouterState extends Url {
  /// Matching route definitions at this URL.
  final List<RouteDefinition> routes;

  /// A map of URL parameters.
  ///
  /// If matched RouteDefinition has a path '/customer/:id' and the URL is
  /// '/customer/5', parameters would equal { 'id': '5' }.
  final Map<String, String> parameters;

  RoutePath _routePath;
  RoutePath get routePath {
    return _routePath ??= new RoutePath.fromRoutes(routes);
  }

  RouterState(
    String path,
    List<RouteDefinition> routes, {
    Map<String, String> parameters,
    String fragment: '',
    Map<String, String> queryParameters,
  })
      : this.parameters = new Map.unmodifiable(parameters ?? {}),
        this.routes = new List.unmodifiable(routes ?? []),
        super(path, queryParameters: queryParameters, fragment: fragment);

  @override
  bool operator ==(Object o) {
    if (o is RouterState) {
      return const ListEquality().equals(routes, o.routes) && super == o;
    }
    return false;
  }

  @override
  int get hashCode => hash2(const ListEquality().hash(routes), super.hashCode);

  @override
  String toString() => '#$RouterState {${super.toString()}}';
}

/// **Internal only**: An easily mutable version of [RouterState].
///
/// MutableRouterState enables the Router to set and unset values to build up
/// a RouterState. In addition to the normal RouterState properties, it also
/// maintains a list of outlets and components that will be attached. These
/// are [QueueList]s so that elements can be added in the front or back.
class MutableRouterState {
  String path = '';
  QueueList<RouteDefinition> routes = new QueueList();
  String fragment = '';
  Map<String, String> queryParameters = {};
  Map<String, String> parameters = {};
  QueueList<ComponentRef> components = new QueueList();
  final factories = <ComponentRef, ComponentFactory>{};

  MutableRouterState();

  RouterState build() {
    return new RouterState(path, routes.toList(),
        fragment: fragment,
        queryParameters: queryParameters,
        parameters: parameters);
  }
}
