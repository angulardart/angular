import 'dart:html' as html;

import 'package:angular/angular.dart' show Injectable, Inject, Optional;

import 'location.dart' show Location;
import 'location_strategy.dart' show LocationStrategy, appBaseHref;
import 'platform_location.dart' show PlatformLocation;

/// `PathLocationStrategy` is a [LocationStrategy] used to configure the
/// [Location] service to represent its state in the
/// [path](https://en.wikipedia.org/wiki/Uniform_Resource_Locator#Syntax) of the
/// browser's URL.
///
/// `PathLocationStrategy` is the default binding for [LocationStrategy]
/// provided in [routerProviders].
///
/// If you're using `PathLocationStrategy`, you must provide a provider for
/// [appBaseHref] to a string representing the URL prefix that should
/// be preserved when generating and recognizing URLs.
///
/// For instance, if you provide an `appBaseHref` of `'/my/app'` and call
/// `location.go('/foo')`, the browser's URL will become
/// `example.com/my/app/foo`.
@Injectable()
class PathLocationStrategy extends LocationStrategy {
  final PlatformLocation _platformLocation;
  late final String _baseHref;

  PathLocationStrategy(
    this._platformLocation, [
    @Optional() @Inject(appBaseHref) String? href,
  ]) {
    href ??= _platformLocation.getBaseHrefFromDOM();
    if (href == null) {
      throw ArgumentError('No base href set. Please provide a value for the '
          'appBaseHref token or add a base element to the document.');
    }
    _baseHref = href;
  }

  @override
  void onPopState(html.EventListener fn) {
    _platformLocation.onPopState(fn);
  }

  @override
  String getBaseHref() => _baseHref;

  @override
  String prepareExternalUrl(String internal) {
    return Location.joinWithSlash(_baseHref, internal);
  }

  @override
  String hash() => _platformLocation.hash;

  @override
  String path() =>
      _platformLocation.pathname +
      Location.normalizeQueryParams(_platformLocation.search);

  @override
  void pushState(Object? state, String title, String url, String queryParams) {
    var externalUrl =
        prepareExternalUrl(url + Location.normalizeQueryParams(queryParams));
    _platformLocation.pushState(state, title, externalUrl);
  }

  @override
  void replaceState(
      Object? state, String title, String url, String queryParams) {
    var externalUrl =
        prepareExternalUrl(url + Location.normalizeQueryParams(queryParams));
    _platformLocation.replaceState(state, title, externalUrl);
  }

  @override
  void forward() {
    _platformLocation.forward();
  }

  @override
  void back() {
    _platformLocation.back();
  }
}
