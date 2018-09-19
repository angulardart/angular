import 'dart:async';

import 'package:angular/angular.dart' show Injectable;

import 'location_strategy.dart' show LocationStrategy;

/// `Location` is a service that applications can use to interact with a
/// browser's URL.
///
/// Depending on which [LocationStrategy] is used, `Location` will either
/// persist to the URL's path or the URL's hash segment.
///
/// Note: it's better to use [Router#navigate] service to trigger route changes.
/// Use `Location` only if you need to interact with or create normalized URLs
/// outside of routing.
///
/// `Location` is responsible for normalizing the URL against the application's
/// base href. A normalized URL is absolute from the URL host, includes the
/// application's base href, and has no trailing slash:
/// - `/my/app/user/123` is normalized
/// - `my/app/user/123` **is not** normalized
/// - `/my/app/user/123/` **is not** normalized
///
/// ### Example
///
/// ```
/// import 'package:angular/angular.dart' show Component;
/// import 'package:angular_router/angular_router.dart'
///   show
///     Location,
///     RouteConfig,
///     ROUTER_DIRECTIVES,
///     ROUTER_PROVIDERS;
///
/// @Component(
///   ...
///   directives: [ROUTER_DIRECTIVES],
/// )
/// @RouteConfig(const [
///   ...
/// ])
/// class AppComponent {
///   AppComponent(Location location) {
///     location.go('/foo');
///   }
/// }
///
/// bootstrap(AppComponent, [ROUTER_PROVIDERS]);
/// ```
@Injectable()
class Location {
  final LocationStrategy locationStrategy;
  final _subject = StreamController<dynamic>();
  final String _baseHref;

  Location(this.locationStrategy)
      : _baseHref = _sanitizeBaseHref(locationStrategy) {
    locationStrategy.onPopState((ev) {
      _subject.add({'url': path(), 'pop': true, 'type': ev.type});
    });
  }

  static String _sanitizeBaseHref(LocationStrategy platformStrategy) {
    var browserBaseHref = platformStrategy.getBaseHref();
    return Location.stripTrailingSlash(_stripIndexHtml(browserBaseHref));
  }

  /// Returns the normalized URL path.
  String path() => normalize(locationStrategy.path());

  String hash() => normalize(locationStrategy.hash());

  /// Given a string representing a URL, returns the normalized URL path without
  /// leading or trailing slashes
  String normalize(String url) => Location.stripTrailingSlash(
      _stripBaseHref(_baseHref, _stripIndexHtml(url)));

  /// Normalizes [path] for navigation.
  ///
  /// This determines the representation of [path] used to manipulate browser
  /// history and exposed through router states.
  String normalizePath(String path) {
    if (path == null) return null;

    if (!path.startsWith('/')) {
      path = '/$path';
    }

    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    return path;
  }

  /// Given a string representing a URL, returns the platform-specific external
  /// URL path. If the given URL doesn't begin with a leading slash (`'/'`),
  /// this method adds one before normalizing. This method will also add a hash
  /// if `HashLocationStrategy` is used, or the `appBaseHref` if the
  /// `PathLocationStrategy` is in use.
  String prepareExternalUrl(String url) {
    if (url.isNotEmpty && !url.startsWith('/')) {
      url = '/$url';
    }
    return locationStrategy.prepareExternalUrl(url);
  }

  // TODO: rename this method to pushState
  /// Changes the browsers URL to the normalized version of the given URL, and
  /// pushes a new item onto the platform's history.
  void go(String path, [String query = '']) {
    locationStrategy.pushState(null, '', path, query);
  }

  /// Changes the browsers URL to the normalized version of the given URL, and
  /// replaces the top item on the platform's history stack.
  void replaceState(String path, [String query = '']) {
    locationStrategy.replaceState(null, '', path, query);
  }

  /// Navigates forward in the platform's history.
  void forward() {
    locationStrategy.forward();
  }

  /// Navigates back in the platform's history.
  void back() {
    locationStrategy.back();
  }

  /// Subscribe to the platform's `popState` events.
  Object subscribe(
    void onNext(dynamic value), [
    void onThrow(dynamic exception),
    void onReturn(),
  ]) {
    return _subject.stream.listen(onNext, onError: onThrow, onDone: onReturn);
  }

  /// Given a string of url parameters, prepend with '?' if needed, otherwise
  /// return parameters as is.
  static String normalizeQueryParams(String params) {
    return params.isEmpty || params.startsWith('?') ? params : '?$params';
  }

  /// Given 2 parts of a url, join them with a slash if needed.
  static String joinWithSlash(String start, String end) {
    if (start.isEmpty) {
      return end;
    }
    if (end.isEmpty) {
      return start;
    }
    var slashes = 0;
    if (start.endsWith('/')) {
      slashes++;
    }
    if (end.startsWith('/')) {
      slashes++;
    }
    if (slashes == 2) {
      return start + end.substring(1);
    }
    if (slashes == 1) {
      return start + end;
    }
    return '$start/$end';
  }

  /// If url has a trailing slash, remove it, otherwise return url as is.
  static String stripTrailingSlash(String url) {
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}

String _stripBaseHref(String baseHref, String url) {
  if (baseHref.isNotEmpty && url.startsWith(baseHref)) {
    return url.substring(baseHref.length);
  }
  return url;
}

String _stripIndexHtml(String url) {
  if (url.endsWith('/index.html')) {
    // '/index.html'.length == 11
    return url.substring(0, url.length - 11);
  }
  return url;
}
