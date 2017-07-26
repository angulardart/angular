import 'dart:async';

import 'package:angular/angular.dart' show Injectable;
import 'package:angular_router/src/location/location.dart';
import 'package:angular_router/src/location/location_strategy.dart';

/// A spy for [Location] that allows tests to fire simulated location events.
@Injectable()
class SpyLocation implements Location {
  List<String> urlChanges = [];
  String _path = '';
  String _query = '';
  final _subject = new StreamController<dynamic>();
  String _baseHref = '';
  String _hash = '';

  setInitialPath(String url) {
    _path = url;
  }

  void setBaseHref(String url) {
    _baseHref = url;
  }

  void setHash(String hash) {
    _hash = hash;
  }

  String path() {
    return _path;
  }

  String hash() {
    return _hash;
  }

  void simulateUrlPop(String pathname) {
    _subject.add({'url': pathname, 'pop': true});
  }

  void simulateHashChange(String pathname) {
    // Because we don't prevent the native event, the browser will independently update the path
    setInitialPath(pathname);
    urlChanges.add('hash: ' + pathname);
    _subject.add({'url': pathname, 'pop': true, 'type': 'hashchange'});
  }

  String prepareExternalUrl(String url) {
    if (url.length > 0 && !url.startsWith('/')) {
      url = '/' + url;
    }
    return _baseHref + url;
  }

  void go(String path, [String query = '']) {
    path = prepareExternalUrl(path);
    if (_path == path && _query == query) {
      return;
    }
    _path = path;
    _query = query;
    var url = path + (query.length > 0 ? ('?' + query) : '');
    urlChanges.add(url);
  }

  void replaceState(String path, [String query = '']) {
    path = prepareExternalUrl(path);
    _path = path;
    _query = query;
    var url = path + (query.length > 0 ? ('?' + query) : '');
    urlChanges.add('replace: ' + url);
  }

  void forward() {}
  void back() {}
  Object subscribe(void onNext(dynamic value),
      [void onThrow(dynamic error) = null, void onReturn() = null]) {
    return _subject.stream.listen(onNext, onError: onThrow, onDone: onReturn);
  }

  // TODO: remove these once Location is an interface, and can be implemented cleanly
  LocationStrategy platformStrategy;
  String normalize(String url) {
    return null;
  }
}
