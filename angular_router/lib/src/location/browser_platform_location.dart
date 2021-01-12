import 'dart:html';

import 'package:angular/angular.dart' show Injectable;

import 'base_href.dart';
import 'platform_location.dart';

/// `PlatformLocation` encapsulates all of the direct calls to platform APIs.
/// This class should not be used directly by an application developer. Instead, use
/// [Location].
@Injectable()
class BrowserPlatformLocation extends PlatformLocation {
  final Location location;
  final History _history;

  BrowserPlatformLocation()
      : location = window.location,
        _history = window.history;

  @override
  String? getBaseHrefFromDOM() => baseHrefFromDOM();

  @override
  void onPopState(EventListener fn) {
    window.addEventListener('popstate', fn, false);
  }

  @override
  void onHashChange(EventListener fn) {
    window.addEventListener('hashchange', fn, false);
  }

  @override
  String get pathname {
    return location.pathname!;
  }

  @override
  String get search {
    return location.search!;
  }

  @override
  String get hash {
    return location.hash;
  }

  set pathname(String newPath) {
    location.pathname = newPath;
  }

  @override
  void pushState(Object? state, String title, String? url) {
    _history.pushState(state, title, url);
  }

  @override
  void replaceState(Object? state, String title, String? url) {
    _history.replaceState(state, title, url);
  }

  @override
  void forward() {
    _history.forward();
  }

  @override
  void back() {
    _history.back();
  }
}
