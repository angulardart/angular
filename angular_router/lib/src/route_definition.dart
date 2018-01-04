// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:angular/angular.dart';

import 'route_path.dart';
import 'url.dart';

/// A user defined route [path] for a router.
///
/// Route definitions are how you configure routing. Several types supported:
///
/// - Load a component for a given path: [RouteDefinition]
/// - Defer/lazy load a component: [RouteDefinition.defer]
/// - Redirect and resolve a new route: [RouteDefinition.redirect]
abstract class RouteDefinition {
  static final RegExp _findParameters = new RegExp(r':([\w-]+)');

  /// Logical name used for determining a route.
  final String path;

  /// Uses this Route as default if the [RouterOutlet] has no component.
  final bool useAsDefault;

  /// Additional information to attached to the [RouteDefinition].
  ///
  /// Useful for using a generic component for multiple [RouteDefinition]s.
  final dynamic additionalData;

  RouteDefinition._(
      {String path,
      bool useAsDefault,
      dynamic additionalData,
      RoutePath routePath})
      : this.path = Url.trimSlashes(path ?? routePath?.path),
        this.useAsDefault = useAsDefault ?? routePath?.useAsDefault ?? false,
        this.additionalData = additionalData ?? routePath?.additionalData;

  /// Runs a dev-mode assertion that the definition is valid.
  ///
  /// When assertions are enabled, throws [StateError]. Otherwise does nothing.
  @mustCallSuper
  @visibleForTesting
  void assertValid() {
    assert(() {
      if (path == null) {
        throw new StateError('Must have a non-null `path` string');
      }
      return true;
    });
  }

  /// Define a route from [path] that loads [component] into an outlet.
  ///
  /// ```
  /// import 'contact_view.template.dart';
  ///
  /// new RouteDefinition(
  ///   path: 'contact',
  ///   component: ContactViewComponentNgFactory,
  /// );
  /// ```
  ///
  /// At most one route may be set to [useAsDefault], which means it will be
  /// automatically inferred to be in use if there are no matching routes for a
  /// given outlet.
  ///
  /// Another way to create a RouteDefinition is by using a [RoutePath]. The
  /// routePath can also be used for other applications, such as creating URLs.
  /// ```
  /// RoutePath contactRoute = new RoutePath(
  ///   path: 'contact',
  /// );
  ///
  /// new RouteDefinition(
  ///   routePath: contactRoute,
  ///   component: ContactViewComponentNgFactory,
  /// );
  /// ```
  factory RouteDefinition({
    String path,
    ComponentFactory component,
    bool useAsDefault,
    additionalData,
    RoutePath routePath,
  }) = ComponentRouteDefinition._;

  /// Define a route from [path] that uses [loader] to resolve a component.
  ///
  /// Can be used to prefetch/initialize, such as loading a deferred library:
  /// ```
  /// import 'contact_view.template.dart' deferred as contact_view;
  ///
  /// Type loadContentView() async {
  ///   await contact_view.loadLibrary();
  ///   return contact_view.ContactViewComponentNgFactory;
  /// }
  /// ```
  ///
  /// Then create a [RouteDefinition] that uses `loadContentView`:
  ///
  /// ```
  /// new RouteDefinition.defer('contact', loadContactView);
  /// ```
  ///
  /// At most one route may be set to [useAsDefault], which means it will be
  /// automatically inferred to be in use if there are no matching routes for a
  /// given outlet.
  factory RouteDefinition.defer({
    String path,
    LoadComponentAsync loader,
    bool useAsDefault,
    additionalData,
    RoutePath routePath,
  }) = DeferredRouteDefinition._;

  /// Configures a redirect from a [path] --> [to] another one.
  ///
  /// ```
  /// new RouteDefinition.redirect('contact', 'about/contact');
  /// ```
  ///
  /// At most one route may be set to [useAsDefault], which means it will be
  /// automatically inferred to be in use if there are no matching routes for a
  /// given outlet.
  factory RouteDefinition.redirect({
    String path,
    String redirectTo,
    bool useAsDefault,
    additionalData,
    RoutePath routePath,
  }) = RedirectRouteDefinition._;

  /// Collection of parameters that are supplied in [path].
  Iterable<String> get parameters {
    return _findParameters.allMatches(path).map((m) => m[1]);
  }

  /// Returns as a regular expression that matches this route.
  RegExp toRegExp() => new RegExp('/?' +
      path.replaceAll(_findParameters,
          r"((?:[\w'\.\-~!\$&\(\)\*\+,;=:@]|%[0-9a-fA-F]{2})+)"));

  /// Returns as a valid URL with [paramValues] filled into [parameters].
  String toUrl([Map<String, String> paramValues = const {}]) {
    assert(() {
      if (paramValues == null) {
        throw new ArgumentError.notNull('paramValues');
      }
      return true;
    });
    var url = '/' + path;
    for (final parameter in parameters) {
      url = url.replaceFirst(
          ':$parameter', Uri.encodeComponent(paramValues[parameter]));
    }
    return url;
  }
}

/// Returns a future that completes with a component type or factory.
typedef Future<ComponentFactory> LoadComponentAsync();

@visibleForTesting
class ComponentRouteDefinition extends RouteDefinition {
  /// Allows creating a component imperatively.
  final ComponentFactory component;

  ComponentRouteDefinition._({
    String path,
    this.component,
    bool useAsDefault,
    additionalData,
    RoutePath routePath,
  })
      : super._(
          path: path,
          useAsDefault: useAsDefault,
          additionalData: additionalData,
          routePath: routePath,
        );

  @override
  void assertValid() {
    assert(() {
      if (component is! Type && component is! ComponentFactory) {
        throw new StateError(
          'Must have a valid (non-null) `component` type (got $Component).',
        );
      }
      return true;
    });
    super.assertValid();
  }
}

@visibleForTesting
class DeferredRouteDefinition extends RouteDefinition {
  /// Returns a future that completes with a component type to be resolved.
  final LoadComponentAsync loader;

  DeferredRouteDefinition._({
    String path,
    this.loader,
    bool useAsDefault,
    additionalData,
    RoutePath routePath,
  })
      : super._(
            path: path,
            useAsDefault: useAsDefault,
            additionalData: additionalData,
            routePath: routePath);

  @override
  void assertValid() {
    assert(() {
      if (loader == null) {
        throw new StateError('Must have a non-null `loader` function');
      }
      return true;
    });
    super.assertValid();
  }
}

@visibleForTesting
class RedirectRouteDefinition extends RouteDefinition {
  /// What [path] to redirect to when resolved.
  final String redirectTo;

  RedirectRouteDefinition._({
    String path,
    this.redirectTo,
    bool useAsDefault,
    additionalData,
    RoutePath routePath,
  })
      : super._(
            path: path,
            useAsDefault: useAsDefault,
            additionalData: additionalData,
            routePath: routePath);

  @override
  void assertValid() {
    assert(() {
      if (redirectTo == null) {
        throw new StateError('Must have a non-null `redirectTo` string');
      }
      if (redirectTo == path) {
        throw new StateError('Cannot redirect from `redirectTo` to `path');
      }
      return true;
    });
    super.assertValid();
  }
}
