import "package:angular2/platform/common.dart";
import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/facade/async.dart"
    show EventEmitter, ObservableWrapper;

/**
 * A spy for [Location] that allows tests to fire simulated location events.
 */
@Injectable()
class SpyLocation implements Location {
  List<String> urlChanges = [];
  /** @internal */
  String _path = "";
  /** @internal */
  String _query = "";
  /** @internal */
  EventEmitter<dynamic> _subject = new EventEmitter();
  /** @internal */
  String _baseHref = "";
  /** @internal */
  String _hash = "";
  setInitialPath(String url) {
    this._path = url;
  }

  setBaseHref(String url) {
    this._baseHref = url;
  }

  setHash(String hash) {
    this._hash = hash;
  }

  String path() {
    return this._path;
  }

  String hash() {
    return this._hash;
  }

  simulateUrlPop(String pathname) {
    ObservableWrapper.callEmit(this._subject, {"url": pathname, "pop": true});
  }

  simulateHashChange(String pathname) {
    // Because we don't prevent the native event, the browser will independently update the path
    this.setInitialPath(pathname);
    this.urlChanges.add("hash: " + pathname);
    ObservableWrapper.callEmit(
        this._subject, {"url": pathname, "pop": true, "type": "hashchange"});
  }

  String prepareExternalUrl(String url) {
    if (url.length > 0 && !url.startsWith("/")) {
      url = "/" + url;
    }
    return this._baseHref + url;
  }

  go(String path, [String query = ""]) {
    path = this.prepareExternalUrl(path);
    if (this._path == path && this._query == query) {
      return;
    }
    this._path = path;
    this._query = query;
    var url = path + (query.length > 0 ? ("?" + query) : "");
    this.urlChanges.add(url);
  }

  replaceState(String path, [String query = ""]) {
    path = this.prepareExternalUrl(path);
    this._path = path;
    this._query = query;
    var url = path + (query.length > 0 ? ("?" + query) : "");
    this.urlChanges.add("replace: " + url);
  }

  forward() {}
  back() {}
  Object subscribe(void onNext(dynamic value),
      [void onThrow(dynamic error) = null, void onReturn() = null]) {
    return ObservableWrapper.subscribe(
        this._subject, onNext, onThrow, onReturn);
  }

  // TODO: remove these once Location is an interface, and can be implemented cleanly
  LocationStrategy platformStrategy = null;
  String normalize(String url) {
    return null;
  }
}
