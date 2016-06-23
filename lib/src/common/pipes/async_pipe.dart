library angular2.src.common.pipes.async_pipe;

import "dart:async";
import "package:angular2/src/facade/lang.dart"
    show isBlank, isPresent, isPromise;
import "package:angular2/src/facade/async.dart"
    show ObservableWrapper, Stream, EventEmitter;
import "package:angular2/core.dart"
    show
        Pipe,
        Injectable,
        ChangeDetectorRef,
        OnDestroy,
        PipeTransform,
        WrappedValue;
import "invalid_pipe_argument_exception.dart" show InvalidPipeArgumentException;

class ObservableStrategy {
  dynamic createSubscription(dynamic async, dynamic updateLatestValue) {
    return ObservableWrapper.subscribe(async, updateLatestValue, (e) {
      throw e;
    });
  }

  void dispose(dynamic subscription) {
    ObservableWrapper.dispose(subscription);
  }

  void onDestroy(dynamic subscription) {
    ObservableWrapper.dispose(subscription);
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

/**
 * The `async` pipe subscribes to an Observable or Promise and returns the latest value it has
 * emitted.
 * When a new value is emitted, the `async` pipe marks the component to be checked for changes.
 *
 * ### Example
 *
 * This example binds a `Promise` to the view. Clicking the `Resolve` button resolves the
 * promise.
 *
 * {@example core/pipes/ts/async_pipe/async_pipe_example.ts region='AsyncPipe'}
 *
 * It's also possible to use `async` with Observables. The example below binds the `time` Observable
 * to the view. Every 500ms, the `time` Observable updates the view with the current time.
 *
 * ```typescript
 * ```
 */
@Pipe(name: "async", pure: false)
@Injectable()
class AsyncPipe implements PipeTransform, OnDestroy {
  /** @internal */
  Object _latestValue = null;
  /** @internal */
  Object _latestReturnedValue = null;
  /** @internal */
  Object _subscription = null;
  /** @internal */
  dynamic /* Stream< dynamic > | Future< dynamic > | EventEmitter< dynamic > */ _obj =
      null;
  dynamic _strategy = null;
  /** @internal */
  ChangeDetectorRef _ref;
  AsyncPipe(ChangeDetectorRef _ref) {
    this._ref = _ref;
  }
  void ngOnDestroy() {
    if (isPresent(this._subscription)) {
      this._dispose();
    }
  }

  dynamic transform(
      dynamic /* Stream< dynamic > | Future< dynamic > | EventEmitter< dynamic > */ obj,
      [List<dynamic> args]) {
    if (isBlank(this._obj)) {
      if (isPresent(obj)) {
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

  /** @internal */
  void _subscribe(
      dynamic /* Stream< dynamic > | Future< dynamic > | EventEmitter< dynamic > */ obj) {
    this._obj = obj;
    this._strategy = this._selectStrategy(obj);
    this._subscription = this._strategy.createSubscription(
        obj, (Object value) => this._updateLatestValue(obj, value));
  }

  /** @internal */
  dynamic _selectStrategy(
      dynamic /* Stream< dynamic > | Future< dynamic > | EventEmitter< dynamic > */ obj) {
    if (isPromise(obj)) {
      return _promiseStrategy;
    } else if (ObservableWrapper.isObservable(obj)) {
      return _observableStrategy;
    } else {
      throw new InvalidPipeArgumentException(AsyncPipe, obj);
    }
  }

  /** @internal */
  void _dispose() {
    this._strategy.dispose(this._subscription);
    this._latestValue = null;
    this._latestReturnedValue = null;
    this._subscription = null;
    this._obj = null;
  }

  /** @internal */
  _updateLatestValue(dynamic async, Object value) {
    if (identical(async, this._obj)) {
      this._latestValue = value;
      this._ref.markForCheck();
    }
  }
}
