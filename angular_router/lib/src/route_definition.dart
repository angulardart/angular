import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular/src/utilities.dart';

import 'route_path.dart';
import 'router/router_state.dart';
import 'url.dart';

/// A user defined route [path] for a router.
///
/// Route definitions are how you configure routing. Several types supported:
///
/// - Load a component for a given path: [RouteDefinition]
/// - Defer/lazy load a component: [RouteDefinition.defer]
/// - Redirect and resolve a new route: [RouteDefinition.redirect]
abstract class RouteDefinition {
  static final RegExp _findParameters = RegExp(r':([\w-]+)');

  /// Logical name used for determining a route.
  final String path;

  /// Uses this Route as default if the [RouterOutlet] has no component.
  final bool useAsDefault;

  /// Additional information to attached to the [RouteDefinition].
  ///
  /// Useful for using a generic component for multiple [RouteDefinition]s.
  final dynamic additionalData;

  RouteDefinition._({
    String? path,
    bool? useAsDefault,
    dynamic additionalData,
    RoutePath? routePath,
  })  : assert(path != null || routePath != null),
        path = Url.trimSlashes(path ?? routePath!.path),
        useAsDefault = useAsDefault ?? routePath?.useAsDefault ?? false,
        additionalData = additionalData ?? routePath?.additionalData;

  /// Runs a dev-mode assertion that the definition is valid.
  ///
  /// When assertions are enabled, throws [StateError]. Otherwise does nothing.
  void assertValid() {}

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
    String? path,
    ComponentFactory<Object>? component,
    bool? useAsDefault,
    dynamic additionalData,
    RoutePath? routePath,
  }) = ComponentRouteDefinition._;

  /// Define a route from [path] that uses [loader] to resolve a component.
  ///
  /// Can be used to prefetch/initialize, such as loading a deferred library:
  /// ```
  /// import 'contact_view.template.dart' deferred as contact_view;
  ///
  /// Future<ComponentFactory> loadContentView() async {
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
  /// An optional [prefetcher] can be specified to prefetch additional
  /// resources. The [prefetcher] is passed a partial [RouterState] that
  /// represents the match *so far* from the root matching route. It's possible
  /// that the [prefetcher] will be invoked during route resolution, even if its
  /// route doesn't fully match, or is prevented from activating. The
  /// [prefetcher] is run concurrently with [loader]. If the [prefetcher]
  /// returns a [Future], its result is awaited before the route is initialized.
  /// If the result of the [prefetcher] doesn't need to be awaited before
  /// activating the route, it should return void.
  ///
  /// At most one route may be set to [useAsDefault], which means it will be
  /// automatically inferred to be in use if there are no matching routes for a
  /// given outlet.
  factory RouteDefinition.defer({
    String? path,
    required LoadComponentAsync loader,
    FutureOr<void> Function(RouterState)? prefetcher,
    bool? useAsDefault,
    dynamic additionalData,
    RoutePath? routePath,
  }) = DeferredRouteDefinition._;

  /// Configures a redirect from a [path] --> [to] another one.
  ///
  /// ```
  /// new RouteDefinition.redirect(
  ///   path: 'contact',
  ///   redirectTo: 'about/contact',
  /// );
  /// ```
  ///
  /// At most one route may be set to [useAsDefault], which means it will be
  /// automatically inferred to be in use if there are no matching routes for a
  /// given outlet.
  ///
  /// If you want to redirect all unmatched routes using a regex path '.*', be
  /// aware this will override your default route. Instead, if you wish to have
  /// both a default route, and redirect all unmatched routes, be sure to use
  /// '.+' as your path.
  ///
  /// ```
  /// [
  ///   new RouteDefinition(path: 'home', useAsDefault: true, ...),
  ///   new RouteDefinition.redirect(path: '.+', redirectTo: 'home'),
  /// ]
  /// ```
  factory RouteDefinition.redirect({
    String? path,
    required String redirectTo,
    bool? useAsDefault,
    dynamic additionalData,
    RoutePath? routePath,
  }) = RedirectRouteDefinition._;

  /// Collection of parameters that are supplied in [path].
  Iterable<String> get parameters {
    return _findParameters.allMatches(path).map((m) => m[1]!);
  }

  /// Returns as a regular expression that matches this route.
  RegExp toRegExp() => RegExp('/?' +
      path.replaceAll(_findParameters,
          r"((?:[\w'\.\-~!\$&\(\)\*\+,;=:@]|%[0-9a-fA-F]{2})+)"));

  /// Returns as a valid URL with [paramValues] filled into [parameters].
  String toUrl([Map<String, String> paramValues = const {}]) {
    var url = '/' + path;
    for (final parameter in parameters) {
      url = url.replaceFirst(
          ':$parameter', Uri.encodeComponent(paramValues[parameter]!));
    }
    return url;
  }
}

/// Returns a future that completes with a component type or factory.
typedef LoadComponentAsync = Future<ComponentFactory<Object>> Function();

class ComponentRouteDefinition extends RouteDefinition {
  /// Allows creating a component imperatively.
  final ComponentFactory<Object>? component;

  ComponentRouteDefinition._({
    String? path,
    this.component,
    bool? useAsDefault,
    dynamic additionalData,
    RoutePath? routePath,
  }) : super._(
          path: path,
          useAsDefault: useAsDefault,
          additionalData: additionalData,
          routePath: routePath,
        );

  @override
  void assertValid() {
    if (!isDevMode) {
      return;
    }
    if (component == null) {
      throw StateError('Must have a non-null `component` factory');
    }
  }
}

class DeferredRouteDefinition extends RouteDefinition {
  /// Returns a future that completes with a component type to be resolved.
  final LoadComponentAsync loader;

  /// An optional function for prefetching resources before loading this route.
  ///
  /// See [RouteDefinition.defer] for details.
  final FutureOr<void> Function(RouterState)? prefetcher;

  DeferredRouteDefinition._({
    String? path,
    required this.loader,
    this.prefetcher,
    bool? useAsDefault,
    dynamic additionalData,
    RoutePath? routePath,
  }) : super._(
            path: path,
            useAsDefault: useAsDefault,
            additionalData: additionalData,
            routePath: routePath);
}

class RedirectRouteDefinition extends RouteDefinition {
  /// What [path] to redirect to when resolved.
  final String redirectTo;

  RedirectRouteDefinition._({
    String? path,
    required this.redirectTo,
    bool? useAsDefault,
    dynamic additionalData,
    RoutePath? routePath,
  }) : super._(
            path: path,
            useAsDefault: useAsDefault,
            additionalData: additionalData,
            routePath: routePath);

  @override
  void assertValid() {
    if (!isDevMode) {
      return;
    }
    if (redirectTo == path) {
      throw StateError('Cannot redirect from `redirectTo` to `path');
    }
    var pathParameters = parameters;
    var unknownRedirectToParameters = _redirectToParameters.where(
        (redirectToParameter) => !pathParameters.contains(redirectToParameter));
    if (unknownRedirectToParameters.isNotEmpty) {
      throw StateError('Parameters in `redirectTo` are not in `path`: '
          '$unknownRedirectToParameters');
    }
  }

  /// Returns the redirectTo URL with [_redirectToParameters] filled in.
  String redirectToUrl([Map<String, String> paramValues = const {}]) {
    var url = redirectTo;
    for (final parameter in _redirectToParameters) {
      url = url.replaceFirst(
          ':$parameter', Uri.encodeComponent(paramValues[parameter]!));
    }
    return url;
  }

  Iterable<String> get _redirectToParameters =>
      RouteDefinition._findParameters.allMatches(redirectTo).map((m) => m[1]!);
}
