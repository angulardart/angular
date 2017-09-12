import 'route_definition.dart';
import 'url.dart';

/// Encapsulates a [RouteDefinition]'s basic properties and creates link URLs.
///
/// A [RouteLibrary] can be separated as another file and define the basic
/// endpoints of the application. Then, this library can be used to create
/// [RouteDefinition]s and generate URLs. This way, there are no circular
/// dependencies.
/// ```
/// RouteLibrary contactRoute = new RouteLibrary(
///   path: 'contact',
///   useAsDefault: true
/// );
///
/// new RouteDefinition(library: contactRoute, component: MyComponentNgFactory)
///
/// router.navigate(contactRoute.toUrl());
/// ```
class RouteLibrary {
  final String path;
  final RouteLibrary parent;
  final bool useAsDefault;
  final dynamic additionalData;

  RouteLibrary({
    String path,
    this.parent,
    this.useAsDefault: false,
    this.additionalData,
  })
      : this.path = Url.trimSlashes(path);

  RouteLibrary.fromRoutes(Iterable<RouteDefinition> routes)
      : path = routes.isNotEmpty ? Url.trimSlashes(routes.last.path) : '',
        useAsDefault = routes.isNotEmpty ? routes.last.useAsDefault : false,
        additionalData = routes.isNotEmpty ? routes.last.additionalData : null,
        parent = routes.length > 1
            ? new RouteLibrary.fromRoutes(routes.take(routes.length - 1))
            : null;

  String toUrl(
      {Map<String, String> parameters = const {},
      Map<String, String> queryParameters,
      String fragment}) {
    var url = parent?.toUrl(parameters: parameters) ?? '';
    url += '/$path';
    parameters.forEach((key, val) {
      url = url.replaceFirst(':$key', Uri.encodeComponent(val));
    });
    return new Url(url, queryParameters: queryParameters, fragment: fragment)
        .toString();
  }
}
