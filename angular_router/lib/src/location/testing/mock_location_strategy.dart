import 'dart:async';
import 'dart:html' show EventListener, PopStateEvent;

import 'package:angular/angular.dart' show Injectable;
import 'package:angular_router/src/location/location_strategy.dart'
    show LocationStrategy;

/// A mock implementation of [LocationStrategy] that allows tests to fire
/// simulated location events.
@Injectable()
class MockLocationStrategy extends LocationStrategy {
  String internalBaseHref = '/';
  String internalPath = '/';
  String internalTitle = '';
  String internalHash = '';
  List<String> urlChanges = [];

  final _subject = StreamController<PopStateEvent>();
  MockLocationStrategy();
  void simulatePopState(String url) {
    internalPath = url;
    _subject.add(PopStateEvent('popstate'));
  }

  String hash() => internalHash;

  String path() => internalPath;

  String prepareExternalUrl(String internal) {
    if (internal.startsWith('/') && internalBaseHref.endsWith('/')) {
      return internalBaseHref + internal.substring(1);
    }
    return internalBaseHref + internal;
  }

  void pushState(dynamic ctx, String title, String path, String query) {
    internalTitle = title;
    var url = path + (query.isNotEmpty ? ('?' + query) : '');
    internalPath = url;
    var externalUrl = prepareExternalUrl(url);
    urlChanges.add(externalUrl);
  }

  void replaceState(dynamic ctx, String title, String path, String query) {
    internalTitle = title;
    var url = path + (query.isNotEmpty ? ('?' + query) : '');
    internalPath = url;
    var externalUrl = prepareExternalUrl(url);
    urlChanges.add('replace: ' + externalUrl);
  }

  void onPopState(EventListener fn) {
    _subject.stream.listen(fn);
  }

  String getBaseHref() => internalBaseHref;

  void back() {
    if (urlChanges.isNotEmpty) {
      urlChanges.removeLast();
      var nextUrl =
          urlChanges.isNotEmpty ? urlChanges[urlChanges.length - 1] : '';
      simulatePopState(nextUrl);
    }
  }

  void forward() {
    throw UnimplementedError('not implemented');
  }
}
