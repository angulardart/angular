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

  void simulatePopState(String url) {
    internalPath = url;
    _subject.add(PopStateEvent('popstate'));
  }

  @override
  String hash() => internalHash;

  @override
  String path() => internalPath;

  @override
  String prepareExternalUrl(String internal) {
    if (internal.startsWith('/') && internalBaseHref.endsWith('/')) {
      return internalBaseHref + internal.substring(1);
    }
    return internalBaseHref + internal;
  }

  @override
  void pushState(Object? ctx, String title, String path, String query) {
    internalTitle = title;
    var url = path + (query.isNotEmpty ? ('?' + query) : '');
    internalPath = url;
    var externalUrl = prepareExternalUrl(url);
    urlChanges.add(externalUrl);
  }

  @override
  void replaceState(Object? ctx, String title, String path, String query) {
    internalTitle = title;
    var url = path + (query.isNotEmpty ? ('?' + query) : '');
    internalPath = url;
    var externalUrl = prepareExternalUrl(url);
    urlChanges.add('replace: ' + externalUrl);
  }

  @override
  void onPopState(EventListener fn) {
    _subject.stream.listen(fn);
  }

  @override
  String getBaseHref() => internalBaseHref;

  @override
  void back() {
    while (urlChanges.isNotEmpty && urlChanges.last.startsWith('replace: ')) {
      urlChanges.removeLast();
    }
    if (urlChanges.isNotEmpty) {
      urlChanges.removeLast();
      var nextUrl = urlChanges.isNotEmpty ? urlChanges.last : '';
      if (nextUrl.startsWith('replace: ')) {
        nextUrl = nextUrl.substring('replace: '.length);
      }
      simulatePopState(nextUrl);
    }
  }

  @override
  void forward() {
    throw UnimplementedError('not implemented');
  }
}
