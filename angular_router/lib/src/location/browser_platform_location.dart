import 'dart:html';

import 'package:angular/angular.dart' show Injectable;

import 'base_href.dart' as base_href;
import 'platform_location.dart';

/// `PlatformLocation` encapsulates all of the direct calls to platform APIs.
/// This class should not be used directly by an application developer. Instead, use
/// [Location].
@Injectable()
class BrowserPlatformLocation extends PlatformLocation {
  Location _location;
  History _history;

  BrowserPlatformLocation() {
    baseHRefFromDOM = base_href.baseHrefFromDOM;
    _init();
  }
  // This is moved to its own method so that `MockPlatformLocationStrategy` can overwrite it

  void _init() {
    _location = window.location;
    _history = window.history;
  }

  Location get location => _location;

  String getBaseHrefFromDOM() => baseHRefFromDOM();

  @override
  void onPopState(EventListener fn) {
    window.addEventListener('popstate', fn, false);
  }

  @override
  void onHashChange(EventListener fn) {
    window.addEventListener('hashchange', fn, false);
  }

  String get pathname {
    return _location.pathname;
  }

  String get search {
    return _location.search;
  }

  String get hash {
    return _location.hash;
  }

  set pathname(String newPath) {
    _location.pathname = newPath;
  }

  void pushState(dynamic state, String title, String url) {
    _history.pushState(state, title, url);
  }

  void replaceState(dynamic state, String title, String url) {
    _history.replaceState(state, title, url);
  }

  void forward() {
    _history.forward();
  }

  void back() {
    _history.back();
  }
}
