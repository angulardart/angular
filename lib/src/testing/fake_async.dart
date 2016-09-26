import 'dart:async' show runZoned, ZoneSpecification;

import 'package:angular2/src/facade/exceptions.dart' show BaseException;
import 'package:quiver/testing/async.dart' as quiver;

import 'test_injector.dart' show getTestInjector, FunctionWithParamTokens;

const _u = const Object();

quiver.FakeAsync _fakeAsync;

/// Wraps the [fn] to be executed in the fakeAsync zone:
/// - microtasks are manually executed by calling [flushMicrotasks],
/// - timers are synchronous, [tick] simulates the asynchronous passage of time.
///
/// If there are any pending timers at the end of the function, an exception
/// will be thrown.
///
/// Can be used to wrap inject() calls.
///
/// Returns a `Function` that wraps [fn].
Function fakeAsync(dynamic /* Function | FunctionWithParamTokens */ fn) {
  if (_fakeAsync != null) {
    throw 'fakeAsync() calls can not be nested';
  }

  Function innerFn;
  if (fn is FunctionWithParamTokens) {
    if (fn.isAsync) {
      throw 'Cannot wrap async test with fakeAsync';
    }
    innerFn = () {
      getTestInjector().execute(fn);
    };
  } else if (fn is Function) {
    innerFn = fn;
  } else {
    throw 'fakeAsync can wrap only test functions but got object of type ' +
        fn.runtimeType.toString();
  }

  return (
      [a0 = _u,
      a1 = _u,
      a2 = _u,
      a3 = _u,
      a4 = _u,
      a5 = _u,
      a6 = _u,
      a7 = _u,
      a8 = _u,
      a9 = _u]) {
    // runZoned() to install a custom exception handler that re-throws
    return runZoned(() {
      return new quiver.FakeAsync().run((quiver.FakeAsync async) {
        try {
          _fakeAsync = async;
          List args = [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9]
              .takeWhile((a) => a != _u)
              .toList();
          var res = Function.apply(innerFn, args);
          _fakeAsync.flushMicrotasks();

          if (async.periodicTimerCount > 0) {
            throw new BaseException('${async.periodicTimerCount} periodic '
                'timer(s) still in the queue.');
          }

          if (async.nonPeriodicTimerCount > 0) {
            throw new BaseException('${async.nonPeriodicTimerCount} timer(s) '
                'still in the queue.');
          }

          return res;
        } finally {
          _fakeAsync = null;
        }
      });
    },
        zoneSpecification: new ZoneSpecification(
            handleUncaughtError: (self, parent, zone, error, stackTrace) =>
                throw error));
  };
}

/// Simulates the asynchronous passage of [millis] milliseconds for the timers
/// in the fakeAsync zone.
///
/// The microtasks queue is drained at the very start of this function and after
/// any timer callback has been executed.
void tick([int millis = 0]) {
  _assertInFakeAsyncZone();
  var duration = new Duration(milliseconds: millis);
  _fakeAsync.elapse(duration);
}

/// This is not needed in Dart. Because quiver correctly removes a timer when
/// it throws an exception.
void clearPendingTimers() {}

/// Flush any pending microtasks.
void flushMicrotasks() {
  _assertInFakeAsyncZone();
  _fakeAsync.flushMicrotasks();
}

void _assertInFakeAsyncZone() {
  if (_fakeAsync == null) {
    throw new BaseException('The code should be running in the fakeAsync zone '
        'to call this function');
  }
}
