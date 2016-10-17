@TestOn('browser')
library angular2.test.core.zone.ng_zone_test;

import "dart:async";

import "package:angular2/src/core/zone/ng_zone.dart" show NgZone, NgZoneError;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

var needsLongerTimers = browserDetection.isSlow || browserDetection.isEdge;
var resultTimer = 1000;
// Schedules a microtask (using a timer)

void macroTask(void fn(), [timer = 1]) {
  // adds longer timers for passing tests in IE and Edge
  new Timer(new Duration(milliseconds: needsLongerTimers ? timer : 1), fn);
}

Log _log;
List _errors;
List _traces;
NgZone _zone;

void logOnError() {
  _zone.onError.listen((NgZoneError ngErr) {
    _errors.add(ngErr.error);
    _traces.add(ngErr.stackTrace);
  });
}

void logOnUnstable() {
  _zone.onUnstable.listen(_log.fn("onUnstable"));
}

void logOnMicrotaskEmpty() {
  _zone.onMicrotaskEmpty.listen(_log.fn("onMicrotaskEmpty"));
}

void logOnStable() {
  _zone.onStable.listen(_log.fn("onStable"));
}

dynamic runNgZoneNoLog(dynamic fn()) {
  var length = _log.logItems.length;
  try {
    return _zone.run(fn);
  } finally {
    // delete anything which may have gotten logged.
    _log.logItems.length = length;
  }
}

NgZone createZone(enableLongStackTrace) {
  return new NgZone(enableLongStackTrace: enableLongStackTrace);
}

void main() {
  group("NgZone", () {
    setUp(() {
      _log = new Log();
      _errors = [];
      _traces = [];
    });
    group("long stack trace", () {
      setUp(() {
        _zone = createZone(true);
        logOnUnstable();
        logOnMicrotaskEmpty();
        logOnStable();
        logOnError();
      });
      commonTests();
      test("should produce long stack traces", () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
          macroTask(() {
            var c = new Completer();
            _zone.run(() {
              Timer.run(() {
                Timer.run(() {
                  c.complete(null);
                  throw new BaseException("ccc");
                });
              });
            });
            c.future.then((_) {
              expect(_traces, hasLength(1));
              expect(_traces[0].length > 1, isTrue);
              completer.done();
            });
          });
        });
      });
      test("should produce long stack traces (when using microtasks)",
          () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
          macroTask(() {
            var c = new Completer();
            _zone.run(() {
              scheduleMicrotask(() {
                scheduleMicrotask(() {
                  c.complete(null);
                  throw new BaseException("ddd");
                });
              });
            });
            c.future.then((_) {
              expect(_traces, hasLength(1));
              expect(_traces[0].length > 1, isTrue);
              completer.done();
            });
          });
        });
      });
    });
    group("short stack trace", () {
      setUp(() {
        _zone = createZone(false);
        logOnUnstable();
        logOnMicrotaskEmpty();
        logOnStable();
        logOnError();
      });
      commonTests();
      test("should disable long stack traces", () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
          macroTask(() {
            var c = new Completer();
            _zone.run(() {
              Timer.run(() {
                Timer.run(() {
                  c.complete(null);
                  throw new BaseException("ccc");
                });
              });
            });
            c.future.then((_) {
              expect(_traces, hasLength(1));
              if (_traces[0] != null) {
                // some browsers don't have stack traces.
                expect(_traces[0].indexOf("---"), -1);
              }
              completer.done();
            });
          });
        });
      });
    });
  });
}

void commonTests() {
  group("hasPendingMicrotasks", () {
    test("should be false", () {
      expect(_zone.hasPendingMicrotasks, isFalse);
    });
    test("should be true", () {
      runNgZoneNoLog(() {
        scheduleMicrotask(() {});
      });
      expect(_zone.hasPendingMicrotasks, isTrue);
    });
  });
  group("hasPendingTimers", () {
    test("should be false", () {
      expect(_zone.hasPendingMacrotasks, isFalse);
    });
    test("should be true", () {
      runNgZoneNoLog(() {
        Timer.run(() {});
      });
      expect(_zone.hasPendingMacrotasks, isTrue);
    });
  });
  group("hasPendingAsyncTasks", () {
    test("should be false", () {
      expect(_zone.hasPendingMicrotasks, isFalse);
    });
    test("should be true when microtask is scheduled", () {
      runNgZoneNoLog(() {
        scheduleMicrotask(() {});
      });
      expect(_zone.hasPendingMicrotasks, isTrue);
    });
    test("should be true when timer is scheduled", () {
      runNgZoneNoLog(() {
        Timer.run(() {});
      });
      expect(_zone.hasPendingMacrotasks, isTrue);
    });
  });
  group("isInInnerZone", () {
    test("should return whether the code executes in the inner zone", () {
      expect(NgZone.isInAngularZone(), false);
      runNgZoneNoLog(() {
        expect(NgZone.isInAngularZone(), true);
      });
    });
  });
  group("run", () {
    test("should return the body return value from run", () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        macroTask(() {
          expect(_zone.run(() {
            return 6;
          }), 6);
        });
        macroTask(() {
          completer.done();
        });
      });
    });
    test("should call onUnstable and onMicrotaskEmpty", () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() => macroTask(_log.fn("run")));
        macroTask(() {
          expect(_log.result(), "onUnstable; run; onMicrotaskEmpty; onStable");
          completer.done();
        });
      });
    });
    test("should call onStable once at the end of event", () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        // The test is set up in a way that causes the zone loop to run onMicrotaskEmpty twice

        // then verified that onStable is only called once at the end
        runNgZoneNoLog(() => macroTask(_log.fn("run")));
        var times = 0;
        _zone.onMicrotaskEmpty.listen((_) {
          times++;
          _log.add('''onMicrotaskEmpty ${ times}''');
          if (times < 2) {
            // Scheduling a microtask causes a second digest
            runNgZoneNoLog(() {
              scheduleMicrotask(() {});
            });
          }
        });
        macroTask(() {
          expect(
              _log.result(),
              "onUnstable; run; onMicrotaskEmpty; onMicrotaskEmpty 1; " +
                  "onMicrotaskEmpty; onMicrotaskEmpty 2; onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test("should call standalone onStable", () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() => macroTask(_log.fn("run")));
        macroTask(() {
          expect(_log.result(), "onUnstable; run; onMicrotaskEmpty; onStable");
          completer.done();
        }, resultTimer);
      });
    });
//    xtest(
//        "should run subscriber listeners in the subscription zone (outside)",
//        inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
//          // Each subscriber fires a microtask outside the Angular zone. The test
//
//          // then verifies that those microtasks do not cause additional digests.
//          var turnStart = false;
//          _zone.onUnstable.listen((_) {
//            if (turnStart) throw "Should not call this more than once";
//            _log.add("onUnstable");
//            scheduleMicrotask(() {});
//            turnStart = true;
//          });
//          var turnDone = false;
//          _zone.onMicrotaskEmpty.listen((_) {
//            if (turnDone) throw "Should not call this more than once";
//            _log.add("onMicrotaskEmpty");
//            scheduleMicrotask(() {});
//            turnDone = true;
//          });
//          var eventDone = false;
//          _zone.onStable.listen((_) {
//            if (eventDone) throw "Should not call this more than once";
//            _log.add("onStable");
//            scheduleMicrotask(() {});
//            eventDone = true;
//          });
//          macroTask(() {
//            _zone.run(_log.fn("run"));
//          });
//          macroTask(() {
//            expect(_log.result())
//                .toEqual("onUnstable; run; onMicrotaskEmpty; onStable");
//            completer.done();
//          }, resultTimer);
//        }),
//        testTimeout);
    test("should run subscriber listeners in the subscription zone (inside)",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() => macroTask(_log.fn("run")));
        // the only practical use-case to run a callback inside the zone is

        // change detection after "onMicrotaskEmpty". That's the only case tested.
        var turnDone = false;
        _zone.onMicrotaskEmpty.listen((_) {
          _log.add("onMyMicrotaskEmpty");
          if (turnDone) return;
          _zone.run(() {
            scheduleMicrotask(() {});
          });
          turnDone = true;
        });
        macroTask(() {
          expect(
              _log.result(),
              "onUnstable; run; onMicrotaskEmpty; onMyMicrotaskEmpty; " +
                  "onMicrotaskEmpty; onMyMicrotaskEmpty; onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test(
        "should run async tasks scheduled inside onStable outside Angular zone",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() => macroTask(_log.fn("run")));
        _zone.onStable.listen((_) {
          NgZone.assertNotInAngularZone();
          _log.add("onMyTaskDone");
        });
        macroTask(() {
          expect(_log.result(),
              "onUnstable; run; onMicrotaskEmpty; onStable; onMyTaskDone");
          completer.done();
        });
      });
    });
    test(
        "should call onUnstable once before a turn and onMicrotaskEmpty once after the turn",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() {
          macroTask(() {
            _log.add("run start");
            scheduleMicrotask(_log.fn("async"));
            _log.add("run end");
          });
        });
        macroTask(() {
          // The microtask (AsyncTestCompleter completer) is executed after the macrotask (run)
          expect(_log.result(),
              "onUnstable; run start; run end; async; onMicrotaskEmpty; onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test("should not run onUnstable and onMicrotaskEmpty for nested Zone.run",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() {
          macroTask(() {
            _log.add("start run");
            _zone.run(() {
              _log.add("nested run");
              scheduleMicrotask(_log.fn("nested run microtask"));
            });
            _log.add("end run");
          });
        });
        macroTask(() {
          expect(_log.result(),
              "onUnstable; start run; nested run; end run; nested run microtask; onMicrotaskEmpty; onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test(
        "should not run onUnstable and onMicrotaskEmpty for nested Zone.run invoked from onMicrotaskEmpty",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() => macroTask(_log.fn("start run")));
        _zone.onMicrotaskEmpty.listen((_) {
          _log.add("onMicrotaskEmpty:started");
          _zone.run(() => _log.add("nested run"));
          _log.add("onMicrotaskEmpty:finished");
        });
        macroTask(() {
          expect(_log.result(),
              "onUnstable; start run; onMicrotaskEmpty; onMicrotaskEmpty:started; nested run; onMicrotaskEmpty:finished; onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test(
        "should call onUnstable and onMicrotaskEmpty before and after each top-level run",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() => macroTask(_log.fn("run1")));
        runNgZoneNoLog(() => macroTask(_log.fn("run2")));
        macroTask(() {
          expect(_log.result(),
              "onUnstable; run1; onMicrotaskEmpty; onStable; onUnstable; run2; onMicrotaskEmpty; onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test(
        "should call onUnstable and onMicrotaskEmpty before and after each turn",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        Completer<String> a;
        Completer<String> b;
        runNgZoneNoLog(() {
          macroTask(() {
            a = new Completer();
            b = new Completer();
            _log.add("run start");
            a.future.then(_log.fn("a then"));
            b.future.then(_log.fn("b then"));
          });
        });
        runNgZoneNoLog(() {
          macroTask(() {
            a.complete("a");
            b.complete("b");
          });
        });
        macroTask(() {
          expect(_log.result(),
              "onUnstable; run start; onMicrotaskEmpty; onStable; onUnstable; a then; b then; onMicrotaskEmpty; onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test("should run a function outside of the angular zone", () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        macroTask(() {
          _zone.runOutsideAngular(_log.fn("run"));
        });
        macroTask(() {
          expect(_log.result(), "run");
          completer.done();
        });
      });
    });
    test(
        "should call onUnstable and onMicrotaskEmpty when an inner microtask is scheduled from outside angular",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter testCompleter) {
        Completer<dynamic> completer;
        macroTask(() {
          NgZone.assertNotInAngularZone();
          completer = new Completer();
        });
        runNgZoneNoLog(() {
          macroTask(() {
            NgZone.assertInAngularZone();
            completer.future.then(_log.fn("executedMicrotask"));
          });
        });
        macroTask(() {
          NgZone.assertNotInAngularZone();
          _log.add("scheduling a microtask");
          completer.complete(null);
        });
        macroTask(() {
          expect(
              _log.result(),
              // First VM turn => setup Promise then
              "onUnstable; onMicrotaskEmpty; onStable; " +
                  // Second VM turn (outside of angular)
                  "scheduling a microtask; onUnstable; " +
                  // Third VM Turn => execute the microtask (inside angular)

                  // No onUnstable;  because we don't own the task which started the turn.
                  "executedMicrotask; onMicrotaskEmpty; onStable");
          testCompleter.done();
        }, resultTimer);
      });
    });
    test(
        "should call onUnstable only before executing a microtask scheduled in onMicrotaskEmpty " +
            "and not onMicrotaskEmpty after executing the task", () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() => macroTask(_log.fn("run")));
        var ran = false;
        _zone.onMicrotaskEmpty.listen((_) {
          _log.add("onMicrotaskEmpty(begin)");
          if (!ran) {
            _zone.run(() {
              scheduleMicrotask(() {
                ran = true;
                _log.add("executedMicrotask");
              });
            });
          }
          _log.add("onMicrotaskEmpty(end)");
        });
        macroTask(() {
          expect(
              _log.result(),
              // First VM turn => 'run' macrotask
              "onUnstable; run; onMicrotaskEmpty; onMicrotaskEmpty(begin); onMicrotaskEmpty(end); " +
                  // Second microtaskDrain Turn => microtask enqueued from onMicrotaskEmpty
                  "executedMicrotask; onMicrotaskEmpty; onMicrotaskEmpty(begin); onMicrotaskEmpty(end); onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test(
        "should call onUnstable and onMicrotaskEmpty for a scheduleMicrotask in onMicrotaskEmpty triggered by " +
            "a scheduleMicrotask in run", () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() {
          macroTask(() {
            _log.add("scheduleMicrotask");
            scheduleMicrotask(_log.fn("run(executeMicrotask)"));
          });
        });
        var ran = false;
        _zone.onMicrotaskEmpty.listen((_) {
          _log.add("onMicrotaskEmpty(begin)");
          if (!ran) {
            _log.add("onMicrotaskEmpty(scheduleMicrotask)");
            _zone.run(() {
              scheduleMicrotask(() {
                ran = true;
                _log.add("onMicrotaskEmpty(executeMicrotask)");
              });
            });
          }
          _log.add("onMicrotaskEmpty(end)");
        });
        macroTask(() {
          expect(
              _log.result(),
              // First VM Turn => a macrotask + the microtask it enqueues
              "onUnstable; scheduleMicrotask; run(executeMicrotask); onMicrotaskEmpty; onMicrotaskEmpty(begin); onMicrotaskEmpty(scheduleMicrotask); onMicrotaskEmpty(end); " +
                  // Second VM Turn => the microtask enqueued from onMicrotaskEmpty
                  "onMicrotaskEmpty(executeMicrotask); onMicrotaskEmpty; onMicrotaskEmpty(begin); onMicrotaskEmpty(end); onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test(
        "should execute promises scheduled in onUnstable before promises scheduled in run",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() {
          macroTask(() {
            _log.add("run start");
            new Future.value(null).then((_) {
              _log.add("promise then");
              new Future.value(null).then(_log.fn("promise foo"));
              return new Future.value(null);
            }).then(_log.fn("promise bar"));
            _log.add("run end");
          });
        });
        var donePromiseRan = false;
        var startPromiseRan = false;
        _zone.onUnstable.listen((_) {
          _log.add("onUnstable(begin)");
          if (!startPromiseRan) {
            _log.add("onUnstable(schedulePromise)");
            _zone.run(() {
              scheduleMicrotask(_log.fn("onUnstable(executePromise)"));
            });
            startPromiseRan = true;
          }
          _log.add("onUnstable(end)");
        });
        _zone.onMicrotaskEmpty.listen((_) {
          _log.add("onMicrotaskEmpty(begin)");
          if (!donePromiseRan) {
            _log.add("onMicrotaskEmpty(schedulePromise)");
            _zone.run(() {
              scheduleMicrotask(_log.fn("onMicrotaskEmpty(executePromise)"));
            });
            donePromiseRan = true;
          }
          _log.add("onMicrotaskEmpty(end)");
        });
        macroTask(() {
          expect(
              _log.result(),
              // First VM turn: enqueue a microtask in onUnstable
              "onUnstable; onUnstable(begin); onUnstable(schedulePromise); onUnstable(end); " +
                  // First VM turn: execute the macrotask which enqueues microtasks
                  "run start; run end; " +
                  // First VM turn: execute enqueued microtasks
                  "onUnstable(executePromise); promise then; promise foo; promise bar; onMicrotaskEmpty; " +
                  // First VM turn: onTurnEnd, enqueue a microtask
                  "onMicrotaskEmpty(begin); onMicrotaskEmpty(schedulePromise); onMicrotaskEmpty(end); " +
                  // Second VM turn: execute the microtask from onTurnEnd
                  "onMicrotaskEmpty(executePromise); onMicrotaskEmpty; onMicrotaskEmpty(begin); onMicrotaskEmpty(end); onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test(
        "should call onUnstable and onMicrotaskEmpty before and after each turn, respectively",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        Completer<dynamic> completerA;
        Completer<dynamic> completerB;
        runNgZoneNoLog(() {
          macroTask(() {
            completerA = new Completer();
            completerB = new Completer();
            completerA.future.then(_log.fn("a then"));
            completerB.future.then(_log.fn("b then"));
            _log.add("run start");
          });
        });
        runNgZoneNoLog(() {
          macroTask(() {
            completerA.complete(null);
          }, 10);
        });
        runNgZoneNoLog(() {
          macroTask(() {
            completerB.complete(null);
          }, 20);
        });
        macroTask(() {
          expect(
              _log.result(),
              // First VM turn
              "onUnstable; run start; onMicrotaskEmpty; onStable; " +
                  // Second VM turn
                  "onUnstable; a then; onMicrotaskEmpty; onStable; " +
                  // Third VM turn
                  "onUnstable; b then; onMicrotaskEmpty; onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test(
        "should call onUnstable and onMicrotaskEmpty before and after (respectively) all turns in a chain",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        runNgZoneNoLog(() {
          macroTask(() {
            _log.add("run start");
            scheduleMicrotask(() {
              _log.add("async1");
              scheduleMicrotask(_log.fn("async2"));
            });
            _log.add("run end");
          });
        });
        macroTask(() {
          expect(_log.result(),
              "onUnstable; run start; run end; async1; async2; onMicrotaskEmpty; onStable");
          completer.done();
        }, resultTimer);
      });
    });
    test(
        "should call onUnstable and onMicrotaskEmpty for promises created outside of run body",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        Future<dynamic> promise;
        runNgZoneNoLog(() {
          macroTask(() {
            _zone.runOutsideAngular(() {
              promise = new Future.value(4).then((x) => new Future.value(x));
            });
            promise.then(_log.fn("promise then"));
            _log.add("zone run");
          });
        });
        macroTask(() {
          expect(
              _log.result(),
              "onUnstable; zone run; onMicrotaskEmpty; onStable; " +
                  "onUnstable; promise then; onMicrotaskEmpty; onStable");
          completer.done();
        }, resultTimer);
      });
    });
  });

  group("exceptions", () {
    test(
        "should call the on error callback when it is invoked via zone.runGuarded",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        macroTask(() {
          var exception = new BaseException("sync");
          _zone.runGuarded(() {
            throw exception;
          });
          expect(_errors, hasLength(1));
          expect(_errors[0], exception);
          completer.done();
        });
      });
    });
    test(
        "should not call the on error callback but rethrow when it is invoked via zone.run",
        () async {
      return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
        macroTask(() {
          var exception = new BaseException("sync");
          expect(
              () => _zone.run(() {
                    throw exception;
                  }),
              throwsWith("sync"));
          expect(_errors, hasLength(0));
          completer.done();
        });
      });
    });
  });
  test("should call onError for errors from microtasks", () async {
    return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
      var exception = new BaseException("async");
      macroTask(() {
        _zone.run(() {
          scheduleMicrotask(() {
            throw exception;
          });
        });
      });
      macroTask(() {
        expect(_errors, hasLength(1));
        expect(_errors[0], exception);
        completer.done();
      }, resultTimer);
    });
  });
}
