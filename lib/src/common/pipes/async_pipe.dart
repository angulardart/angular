import "dart:async";

import "package:angular2/core.dart"
    show Pipe, Injectable, ChangeDetectorRef, OnDestroy, WrappedValue;

import "invalid_pipe_argument_exception.dart" show InvalidPipeArgumentException;

class ObservableStrategy {
  StreamSubscription createSubscription(
      Stream stream, void updateLatestValue(value)) {
    return stream.listen(updateLatestValue, onError: (e) => throw e);
  }

  void dispose(StreamSubscription subscription) {
    subscription.cancel();
  }

  void onDestroy(StreamSubscription subscription) {
    dispose(subscription);
  }
}

class PromiseStrategy {
  dynamic createSubscription(
      Future<dynamic> async, dynamic updateLatestValue(dynamic v)) {
    return async.then(updateLatestValue);
  }

  void dispose(dynamic subscription) {}
  void onDestroy(dynamic subscription) {}
}

var _promiseStrategy = new PromiseStrategy();
var _observableStrategy = new ObservableStrategy();
Future<dynamic> ___unused;

/// An `async` pipe awaits for a value from a [Future] or [Stream]. When a value
/// is received, the `async` pipe marks the component to be checked for changes.
///
/// ### Example
///
/// {@example common/pipes/lib/async_pipe.dart region='AsyncPipe'}
///
@Pipe(name: "async", pure: false)
@Injectable()
class AsyncPipe implements OnDestroy {
  Object _latestValue;
  Object _latestReturnedValue;
  Object _subscription;
  dynamic /* Stream< dynamic > | Future< dynamic > | EventEmitter< dynamic > */ _obj;
  dynamic _strategy;
  ChangeDetectorRef _ref;
  AsyncPipe(ChangeDetectorRef _ref) {
    this._ref = _ref;
  }
  @override
  void ngOnDestroy() {
    if (this._subscription != null) {
      this._dispose();
    }
  }

  dynamic transform(
      dynamic /* Stream< dynamic > | Future< dynamic > | EventEmitter< dynamic > */ obj) {
    if (_obj == null) {
      if (obj != null) {
        this._subscribe(obj);
      }
      this._latestReturnedValue = this._latestValue;
      return this._latestValue;
    }
    if (!identical(obj, this._obj)) {
      this._dispose();
      return this.transform(obj);
    }
    if (identical(this._latestValue, this._latestReturnedValue)) {
      return this._latestReturnedValue;
    } else {
      this._latestReturnedValue = this._latestValue;
      return WrappedValue.wrap(this._latestValue);
    }
  }

  void _subscribe(
      dynamic /* Stream< dynamic > | Future< dynamic > | EventEmitter< dynamic > */ obj) {
    this._obj = obj;
    this._strategy = this._selectStrategy(obj);
    this._subscription = this._strategy.createSubscription(
        obj, (Object value) => this._updateLatestValue(obj, value));
  }

  dynamic _selectStrategy(
      dynamic /* Stream< dynamic > | Future< dynamic > | EventEmitter< dynamic > */ obj) {
    if (obj is Future) {
      return _promiseStrategy;
    } else if (obj is Stream) {
      return _observableStrategy;
    } else {
      throw new InvalidPipeArgumentException(AsyncPipe, obj);
    }
  }

  void _dispose() {
    this._strategy.dispose(this._subscription);
    this._latestValue = null;
    this._latestReturnedValue = null;
    this._subscription = null;
    this._obj = null;
  }

  void _updateLatestValue(dynamic async, Object value) {
    if (identical(async, this._obj)) {
      this._latestValue = value;
      this._ref.markForCheck();
    }
  }
}
