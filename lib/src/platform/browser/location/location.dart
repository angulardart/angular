import "package:angular2/di.dart" show Injectable;
import "package:angular2/src/facade/async.dart" show EventEmitter;

import "location_strategy.dart" show LocationStrategy;

/// `Location` is a service that applications can use to interact with a browser's URL.
/// Depending on which [LocationStrategy] is used, `Location` will either persist
/// to the URL's path or the URL's hash segment.
///
/// Note: it's better to use [Router#navigate] service to trigger route changes. Use
/// `Location` only if you need to interact with or create normalized URLs outside of
/// routing.
///
/// `Location` is responsible for normalizing the URL against the application's base href.
/// A normalized URL is absolute from the URL host, includes the application's base href, and has no
/// trailing slash:
/// - `/my/app/user/123` is normalized
/// - `my/app/user/123` **is not** normalized
/// - `/my/app/user/123/` **is not** normalized
///
/// ### Example
///
/// ```
/// import {Component} from 'angular2/core';
/// import {Location} from 'angular2/platform/common';
/// import {
///   ROUTER_DIRECTIVES,
///   ROUTER_PROVIDERS,
///   RouteConfig
/// } from 'angular2/router';
///
/// @Component({directives: [ROUTER_DIRECTIVES]})
/// @RouteConfig([
///  {...},
/// ])
/// class AppCmp {
///   constructor(location: Location) {
///     location.go('/foo');
///   }
/// }
///
/// bootstrap(AppCmp, [ROUTER_PROVIDERS]);
/// ```
@Injectable()
class Location {
  LocationStrategy platformStrategy;
  /** @internal */
  EventEmitter<dynamic> _subject = new EventEmitter();
  /** @internal */
  String _baseHref;
  Location(this.platformStrategy) {
    var browserBaseHref = this.platformStrategy.getBaseHref();
    this._baseHref =
        Location.stripTrailingSlash(_stripIndexHtml(browserBaseHref));
    this.platformStrategy.onPopState((ev) {
      this._subject.add({"url": this.path(), "pop": true, "type": ev.type});
    });
  }

  /// Returns the normalized URL path.
  String path() {
    return this.normalize(this.platformStrategy.path());
  }

  String hash() {
    return this.normalize(this.platformStrategy.hash());
  }

  /// Given a string representing a URL, returns the normalized URL path without leading or
  /// trailing slashes
  String normalize(String url) {
    return Location.stripTrailingSlash(
        _stripBaseHref(this._baseHref, _stripIndexHtml(url)));
  }

  /// Given a string representing a URL, returns the platform-specific external URL path.
  /// If the given URL doesn't begin with a leading slash (`'/'`), this method adds one
  /// before normalizing. This method will also add a hash if `HashLocationStrategy` is
  /// used, or the `APP_BASE_HREF` if the `PathLocationStrategy` is in use.
  String prepareExternalUrl(String url) {
    if (url.length > 0 && !url.startsWith("/")) {
      url = "/" + url;
    }
    return this.platformStrategy.prepareExternalUrl(url);
  }
  // TODO: rename this method to pushState

  /// Changes the browsers URL to the normalized version of the given URL, and pushes a
  /// new item onto the platform's history.
  void go(String path, [String query = ""]) {
    this.platformStrategy.pushState(null, "", path, query);
  }

  /// Changes the browsers URL to the normalized version of the given URL, and replaces
  /// the top item on the platform's history stack.
  void replaceState(String path, [String query = ""]) {
    this.platformStrategy.replaceState(null, "", path, query);
  }

  /// Navigates forward in the platform's history.
  void forward() {
    this.platformStrategy.forward();
  }

  /// Navigates back in the platform's history.
  void back() {
    this.platformStrategy.back();
  }

  /// Subscribe to the platform's `popState` events.
  Object subscribe(void onNext(dynamic value),
      [void onThrow(dynamic exception) = null, void onReturn() = null]) {
    return this._subject.listen(onNext, onError: onThrow, onDone: onReturn);
  }

  /// Given a string of url parameters, prepend with '?' if needed, otherwise return parameters as
  /// is.
  static String normalizeQueryParams(String params) {
    return (params.length > 0 && params.substring(0, 1) != "?")
        ? ("?" + params)
        : params;
  }

  /// Given 2 parts of a url, join them with a slash if needed.
  static String joinWithSlash(String start, String end) {
    if (start.length == 0) {
      return end;
    }
    if (end.length == 0) {
      return start;
    }
    var slashes = 0;
    if (start.endsWith("/")) {
      slashes++;
    }
    if (end.startsWith("/")) {
      slashes++;
    }
    if (slashes == 2) {
      return start + end.substring(1);
    }
    if (slashes == 1) {
      return start + end;
    }
    return start + "/" + end;
  }

  /// If url has a trailing slash, remove it, otherwise return url as is.
  static String stripTrailingSlash(String url) {
    if (new RegExp(r'\/$').hasMatch(url)) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}

String _stripBaseHref(String baseHref, String url) {
  if (baseHref.length > 0 && url.startsWith(baseHref)) {
    return url.substring(baseHref.length);
  }
  return url;
}

String _stripIndexHtml(String url) {
  if (new RegExp(r'\/index.html$').hasMatch(url)) {
    // '/index.html'.length == 11
    return url.substring(0, url.length - 11);
  }
  return url;
}
