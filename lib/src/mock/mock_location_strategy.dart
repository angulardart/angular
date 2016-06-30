library angular2.src.mock.mock_location_strategy;

import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/facade/async.dart"
    show EventEmitter, ObservableWrapper;
import "package:angular2/platform/common.dart" show LocationStrategy;

/**
 * A mock implementation of [LocationStrategy] that allows tests to fire simulated
 * location events.
 */
@Injectable()
class MockLocationStrategy extends LocationStrategy {
  String internalBaseHref = "/";
  String internalPath = "/";
  String internalTitle = "";
  String internalHash = "";
  List<String> urlChanges = [];
  /** @internal */
  EventEmitter<dynamic> _subject = new EventEmitter();
  MockLocationStrategy() : super() {
    /* super call moved to initializer */;
  }
  void simulatePopState(String url) {
    this.internalPath = url;
    ObservableWrapper.callEmit(
        this._subject, new _MockPopStateEvent(this.path()));
  }

  String hash() {
    return this.internalHash;
  }

  String path() {
    return this.internalPath;
  }

  String prepareExternalUrl(String internal) {
    if (internal.startsWith("/") && this.internalBaseHref.endsWith("/")) {
      return this.internalBaseHref + internal.substring(1);
    }
    return this.internalBaseHref + internal;
  }

  void pushState(dynamic ctx, String title, String path, String query) {
    this.internalTitle = title;
    var url = path + (query.length > 0 ? ("?" + query) : "");
    this.internalPath = url;
    var externalUrl = this.prepareExternalUrl(url);
    this.urlChanges.add(externalUrl);
  }

  void replaceState(dynamic ctx, String title, String path, String query) {
    this.internalTitle = title;
    var url = path + (query.length > 0 ? ("?" + query) : "");
    this.internalPath = url;
    var externalUrl = this.prepareExternalUrl(url);
    this.urlChanges.add("replace: " + externalUrl);
  }

  void onPopState(void fn(dynamic value)) {
    ObservableWrapper.subscribe(this._subject, fn);
  }

  String getBaseHref() {
    return this.internalBaseHref;
  }

  void back() {
    if (this.urlChanges.length > 0) {
      this.urlChanges.removeLast();
      var nextUrl = this.urlChanges.length > 0
          ? this.urlChanges[this.urlChanges.length - 1]
          : "";
      this.simulatePopState(nextUrl);
    }
  }

  void forward() {
    throw "not implemented";
  }
}

class _MockPopStateEvent {
  String newUrl;
  bool pop = true;
  String type = "popstate";
  _MockPopStateEvent(this.newUrl) {}
}
