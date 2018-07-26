import 'location.dart';
import 'route_definition.dart';
import 'url.dart';

/// Encapsulates a [RouteDefinition]'s basic properties and creates link URLs.
///
/// A [RoutePath] can be separated as another file and define the basic
/// endpoints of the application. Then, this path can be used to create
/// [RouteDefinition]s and generate URLs. This way, there are no circular
/// dependencies.
/// ```
/// RoutePath contactRoute = new RoutePath(
///   path: 'contact',
///   useAsDefault: true
/// );
///
/// new RouteDefinition(
///   routePath: contactRoute,
///   component: MyComponentNgFactory,
/// );
///
/// router.navigate(contactRoute.toUrl());
/// ```
class RoutePath {
  final String path;
  final RoutePath parent;
  final bool useAsDefault;
  final dynamic additionalData;

  RoutePath({
    String path,
    this.parent,
    this.useAsDefault = false,
    this.additionalData,
  }) : this.path = Url.trimSlashes(path);

  RoutePath.fromRoutes(Iterable<RouteDefinition> routes)
      : path = routes.isNotEmpty ? Url.trimSlashes(routes.last.path) : '',
        useAsDefault = routes.isNotEmpty ? routes.last.useAsDefault : false,
        additionalData = routes.isNotEmpty ? routes.last.additionalData : null,
        parent = routes.length > 1
            ? RoutePath.fromRoutes(routes.take(routes.length - 1))
            : null;

  String toUrl({
    Map<String, String> parameters,
    Map<String, String> queryParameters,
    String fragment,
  }) {
    // Don't pass parameters to parent URL. These are populated only once the
    // complete URL has been constructed.
    final parentUrl = parent != null ? parent.toUrl() : '/';
    var url = Location.joinWithSlash(parentUrl, path);
    if (parameters != null) {
      for (final key in parameters.keys) {
        url = url.replaceFirst(':$key', Uri.encodeComponent(parameters[key]));
      }
    }
    return Url(url, queryParameters: queryParameters, fragment: fragment)
        .toString();
  }
}
