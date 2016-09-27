import "dart:async";

import "package:angular2/src/compiler/xhr.dart" show XHR;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

/// A mock implementation of [XHR] that allows outgoing requests to be mocked
/// and responded to within a single test, without going to the network.
class MockXHR extends XHR {
  List<_Expectation> _expectations = [];
  var _definitions = new Map<String, String>();
  List<_PendingRequest> _requests = [];
  Future<String> get(String url) {
    var request = new _PendingRequest(url);
    this._requests.add(request);
    return request.getPromise();
  }

  /// Add an expectation for the given URL. Incoming requests will be checked against
  /// the next expectation (in FIFO order). The `verifyNoOutstandingExpectations` method
  /// can be used to check if any expectations have not yet been met.
  ///
  /// The response given will be returned if the expectation matches.
  void expect(String url, String response) {
    var expectation = new _Expectation(url, response);
    this._expectations.add(expectation);
  }

  /// Add a definition for the given URL to return the given response. Unlike expectations,
  /// definitions have no order and will satisfy any matching request at any time. Also
  /// unlike expectations, unused definitions do not cause `verifyNoOutstandingExpectations`
  /// to return an error.
  void when(String url, String response) {
    this._definitions[url] = response;
  }

  /// Process pending requests and verify there are no outstanding expectations. Also fails
  /// if no requests are pending.
  void flush() {
    if (identical(this._requests.length, 0)) {
      throw new BaseException("No pending requests to flush");
    }
    do {
      this._processRequest(this._requests.removeAt(0));
    } while (this._requests.length > 0);
    this.verifyNoOutstandingExpectations();
  }

  /// Throw an exception if any expectations have not been satisfied.
  void verifyNoOutstandingExpectations() {
    if (identical(this._expectations.length, 0)) return;
    var urls = [];
    for (var i = 0; i < this._expectations.length; i++) {
      var expectation = this._expectations[i];
      urls.add(expectation.url);
    }
    throw new BaseException(
        '''Unsatisfied requests: ${ urls . join ( ", " )}''');
  }

  void _processRequest(_PendingRequest request) {
    var url = request.url;
    if (this._expectations.length > 0) {
      var expectation = this._expectations[0];
      if (expectation.url == url) {
        this._expectations.remove(expectation);
        request.complete(expectation.response);
        return;
      }
    }
    if (this._definitions.containsKey(url)) {
      var response = this._definitions[url];
      request.complete(response);
      return;
    }
    throw new BaseException('''Unexpected request ${ url}''');
  }
}

class _PendingRequest {
  String url;
  Completer<String> completer;
  _PendingRequest(url) {
    this.url = url;
    this.completer = new Completer<String>();
  }
  void complete(String response) {
    if (response == null) {
      this.completer.completeError('''Failed to load ${ this . url}''');
    } else {
      this.completer.complete(response);
    }
  }

  Future<String> getPromise() {
    return this.completer.future;
  }
}

class _Expectation {
  String url;
  String response;
  _Expectation(String url, String response) {
    this.url = url;
    this.response = response;
  }
}
