import "package:angular2/platform/common.dart";
import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/facade/async.dart" show EventEmitter;

/// A spy for [Location] that allows tests to fire simulated location events.
@Injectable()
class SpyLocation implements Location {
  List<String> urlChanges = [];
  String _path = "";
  String _query = "";
  EventEmitter<dynamic> _subject = new EventEmitter();
  String _baseHref = "";
  String _hash = "";

  setInitialPath(String url) {
    this._path = url;
  }

  void setBaseHref(String url) {
    this._baseHref = url;
  }

  void setHash(String hash) {
    this._hash = hash;
  }

  String path() {
    return this._path;
  }

  String hash() {
    return this._hash;
  }

  void simulateUrlPop(String pathname) {
    this._subject.add({"url": pathname, "pop": true});
  }

  void simulateHashChange(String pathname) {
    // Because we don't prevent the native event, the browser will independently update the path
    this.setInitialPath(pathname);
    this.urlChanges.add("hash: " + pathname);
    this._subject.add({"url": pathname, "pop": true, "type": "hashchange"});
  }

  String prepareExternalUrl(String url) {
    if (url.length > 0 && !url.startsWith("/")) {
      url = "/" + url;
    }
    return this._baseHref + url;
  }

  void go(String path, [String query = ""]) {
    path = this.prepareExternalUrl(path);
    if (this._path == path && this._query == query) {
      return;
    }
    this._path = path;
    this._query = query;
    var url = path + (query.length > 0 ? ("?" + query) : "");
    this.urlChanges.add(url);
  }

  void replaceState(String path, [String query = ""]) {
    path = this.prepareExternalUrl(path);
    this._path = path;
    this._query = query;
    var url = path + (query.length > 0 ? ("?" + query) : "");
    this.urlChanges.add("replace: " + url);
  }

  void forward() {}
  void back() {}
  Object subscribe(void onNext(dynamic value),
      [void onThrow(dynamic error) = null, void onReturn() = null]) {
    return this._subject.listen(onNext, onError: onThrow, onDone: onReturn);
  }

  // TODO: remove these once Location is an interface, and can be implemented cleanly
  LocationStrategy platformStrategy;
  String normalize(String url) {
    return null;
  }
}
