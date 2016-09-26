import 'dart:html' as html;

import "package:angular2/di.dart" show Injectable, Inject, Optional;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "location.dart" show Location;
import "location_strategy.dart" show LocationStrategy, APP_BASE_HREF;
import "platform_location.dart" show PlatformLocation;

/// `PathLocationStrategy` is a [LocationStrategy] used to configure the
/// [Location] service to represent its state in the
/// [path](https://en.wikipedia.org/wiki/Uniform_Resource_Locator#Syntax) of the
/// browser's URL.
///
/// `PathLocationStrategy` is the default binding for [LocationStrategy]
/// provided in [ROUTER_PROVIDERS].
///
/// If you're using `PathLocationStrategy`, you must provide a provider for
/// [APP_BASE_HREF] to a string representing the URL prefix that should
/// be preserved when generating and recognizing URLs.
///
/// For instance, if you provide an `APP_BASE_HREF` of `'/my/app'` and call
/// `location.go('/foo')`, the browser's URL will become
/// `example.com/my/app/foo`.
///
/// ### Example
///
/// ```
/// import {Component, provide} from 'angular2/core';
/// import {bootstrap} from 'angular2/platform/browser';
/// import {
///   Location,
///   APP_BASE_HREF
/// } from 'angular2/platform/common';
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
/// bootstrap(AppCmp, [
///   ROUTER_PROVIDERS, // includes binding to PathLocationStrategy
///   provide(APP_BASE_HREF, {useValue: '/my/app'})
/// ]);
/// ```
@Injectable()
class PathLocationStrategy extends LocationStrategy {
  PlatformLocation _platformLocation;
  String _baseHref;
  PathLocationStrategy(this._platformLocation,
      [@Optional() @Inject(APP_BASE_HREF) String href]) {
    href ??= this._platformLocation.getBaseHrefFromDOM();
    if (href == null) {
      throw new BaseException(
          '''No base href set. Please provide a value for the APP_BASE_HREF token or add a base element to the document.''');
    }
    this._baseHref = href;
  }

  @override
  void onPopState(html.EventListener fn) {
    this._platformLocation.onPopState(fn);
    this._platformLocation.onHashChange(fn);
  }

  String getBaseHref() {
    return this._baseHref;
  }

  String prepareExternalUrl(String internal) {
    return Location.joinWithSlash(this._baseHref, internal);
  }

  String hash() {
    return this._platformLocation.hash;
  }

  String path() {
    return this._platformLocation.pathname +
        Location.normalizeQueryParams(this._platformLocation.search);
  }

  void pushState(dynamic state, String title, String url, String queryParams) {
    var externalUrl = this
        .prepareExternalUrl(url + Location.normalizeQueryParams(queryParams));
    this._platformLocation.pushState(state, title, externalUrl);
  }

  void replaceState(
      dynamic state, String title, String url, String queryParams) {
    var externalUrl = this
        .prepareExternalUrl(url + Location.normalizeQueryParams(queryParams));
    this._platformLocation.replaceState(state, title, externalUrl);
  }

  void forward() {
    this._platformLocation.forward();
  }

  void back() {
    this._platformLocation.back();
  }
}
