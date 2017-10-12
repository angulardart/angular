import 'dart:async';

import 'package:angular/core.dart' show Pipe, ChangeDetectorRef, OnDestroy;

import 'invalid_pipe_argument_exception.dart' show InvalidPipeArgumentException;

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

final _promiseStrategy = new PromiseStrategy();
final _observableStrategy = new ObservableStrategy();

/// An `async` pipe awaits for a value from a [Future] or [Stream]. When a value
/// is received, the `async` pipe marks the component to be checked for changes.
///
/// ### Example
///
/// <?code-excerpt "common/pipes/lib/async_pipe.dart (AsyncPipe)"?>
/// ```dart
/// @Component(
///     selector: 'async-greeter',
///     template: '''
///       <div>
///         <p>Wait for it ... {{ greeting | async }}</p>
///         <button [disabled]="!done" (click)="tryAgain()">Try Again!</button>
///       </div>''')
/// class AsyncGreeterPipe {
///   static const _delay = const Duration(seconds: 2);
///
///   Future<String> greeting;
///   bool done;
///
///   AsyncGreeterPipe() {
///     tryAgain();
///   }
///
///   String greet() {
///     done = true;
///     return "Hi!";
///   }
///
///   void tryAgain() {
///     done = false;
///     greeting = new Future<String>.delayed(_delay, greet);
///   }
/// }
///
/// @Component(
///     selector: 'async-time',
///     template: "<p>Time: {{ time | async | date:'mediumTime'}}</p>") //
/// class AsyncTimePipe {
///   static const _delay = const Duration(seconds: 1);
///   final Stream<DateTime> time =
///       new Stream.periodic(_delay, (_) => new DateTime.now());
/// }
/// ```
///
@Pipe('async', pure: false)
class AsyncPipe implements OnDestroy {
  Object _latestValue;
  Object _subscription;
  dynamic /* Stream | Future | EventEmitter */ _obj;
  dynamic _strategy;
  ChangeDetectorRef _ref;

  AsyncPipe(this._ref);

  @override
  void ngOnDestroy() {
    if (_subscription != null) {
      _dispose();
    }
  }

  dynamic transform(dynamic /* Stream | Future | EventEmitter */ obj) {
    if (_obj == null) {
      if (obj != null) {
        _subscribe(obj);
      }
    } else if (!_maybeStreamIdentical(obj, _obj)) {
      _dispose();
      return transform(obj);
    }
    return _latestValue;
  }

  void _subscribe(dynamic /* Stream | Future | EventEmitter */ obj) {
    _obj = obj;
    _strategy = _selectStrategy(obj);
    _subscription = _strategy.createSubscription(
        obj, (Object value) => _updateLatestValue(obj, value));
  }

  dynamic _selectStrategy(dynamic /* Stream | Future | EventEmitter */ obj) {
    if (obj is Future) {
      return _promiseStrategy;
    } else if (obj is Stream) {
      return _observableStrategy;
    } else {
      throw new InvalidPipeArgumentException(AsyncPipe, obj);
    }
  }

  void _dispose() {
    _strategy.dispose(_subscription);
    _latestValue = null;
    _subscription = null;
    _obj = null;
  }

  void _updateLatestValue(dynamic async, Object value) {
    if (identical(async, _obj)) {
      _latestValue = value;
      _ref.markForCheck();
    }
  }

  // StreamController.stream getter always returns new Stream instance,
  // operator== check is also needed. See
  // https://github.com/dart-lang/angular2/issues/260
  static bool _maybeStreamIdentical(a, b) {
    if (!identical(a, b)) {
      return a is Stream && b is Stream && a == b;
    }
    return true;
  }
}
