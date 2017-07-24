import 'dart:html';

import 'package:angular/angular.dart' show OpaqueToken;

/// `LocationStrategy` is responsible for representing and reading route state
/// from the browser's URL. Angular provides two strategies:
/// [HashLocationStrategy] and [PathLocationStrategy] (default).
///
/// This is used under the hood of the [Location] service.
///
/// Applications should use the [Router] or [Location] services to
/// interact with application route state.
///
/// For instance, [HashLocationStrategy] produces URLs like
/// `http://example.com#/foo`, and [PathLocationStrategy] produces
/// `http://example.com/foo` as an equivalent URL.
///
/// See these two classes for more.
abstract class LocationStrategy {
  String path();
  String hash();
  String prepareExternalUrl(String internal);
  void pushState(dynamic state, String title, String url, String queryParams);
  void replaceState(
      dynamic state, String title, String url, String queryParams);
  void forward();
  void back();
  void onPopState(EventListener fn);
  String getBaseHref();
}

/// The `APP_BASE_HREF` token represents the base href to be used with the
/// [PathLocationStrategy].
///
/// If you're using [PathLocationStrategy], you must provide a provider to a string
/// representing the URL prefix that should be preserved when generating and recognizing
/// URLs.
///
/// ### Example
///
/// ```
/// import 'package:angular/angular.dart' show Component;
/// import 'package:angular_router/angular_router.dart'
///   show APP_BASE_HREF, ROUTER_DIRECTIVES, ROUTER_PROVIDERS, RouteConfig;
///
/// @Component({directives: [ROUTER_DIRECTIVES]})
/// @RouteConfig([
///  {...},
/// ])
/// class AppCmp {
///   // ...
/// }
///
/// bootstrap(AppCmp, [
///   ROUTER_PROVIDERS,
///   provide(APP_BASE_HREF, {useValue: '/my/app'})
/// ]);
/// ```
const OpaqueToken APP_BASE_HREF = const OpaqueToken('appBaseHref');
