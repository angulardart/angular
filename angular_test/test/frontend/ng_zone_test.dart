import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_test/src/frontend/ng_zone/fake_time_stabilizer.dart';
import 'package:angular_test/src/frontend/ng_zone/real_time_stabilizer.dart';
import 'package:angular_test/src/frontend/ng_zone/timer_hook_zone.dart';
import 'package:test/test.dart';

void main() {
  group('FakeTimeNgZoneStabilizer', () {
    NgZone ngZone;
    TimerHookZone timerZone;
    FakeTimeNgZoneStabilizer stabilizer;

    setUp(() {
      timerZone = TimerHookZone();
      ngZone = timerZone.run(() => NgZone());
      stabilizer = FakeTimeNgZoneStabilizer(timerZone, ngZone);
    });

    test('should elapse a series of simple timers', () async {
      var lastTimersRun = <int>[];
      ngZone.run(() {
        Timer(Duration(seconds: 1), () {
          lastTimersRun.add(1);
        });
        Timer(Duration(seconds: 2), () {
          lastTimersRun.add(2);
        });
        Timer(Duration(seconds: 3), () {
          lastTimersRun.add(3);
        });
      });
      expect(lastTimersRun, isEmpty);

      await stabilizer.elapse(Duration(seconds: 0));
      expect(lastTimersRun, isEmpty);

      await stabilizer.elapse(Duration(seconds: 1));
      expect(lastTimersRun, [1]);

      await stabilizer.elapse(Duration(seconds: 2));
      expect(lastTimersRun, [1, 2, 3]);
    });

    test('should elapse a series of nested timers', () async {
      var lastTimersRun = <int>[];
      ngZone.run(() {
        Timer(Duration(seconds: 1), () {
          lastTimersRun.add(1);
          Timer(Duration(seconds: 2), () {
            lastTimersRun.add(2);
            Timer(Duration(seconds: 3), () {
              lastTimersRun.add(3);
            });
          });
        });
      });
      expect(lastTimersRun, isEmpty);

      // Elapsed: 0
      await stabilizer.elapse(Duration(seconds: 0));
      expect(lastTimersRun, isEmpty);

      // Elapsed: 1
      // Only the first timer should complete. and the second timer should
      // be added as pending timers with elapsedTime = 1s.
      await stabilizer.elapse(Duration(seconds: 1));
      expect(lastTimersRun, [1]);

      // Elapsed: 2
      // The second timer should not complete.
      await stabilizer.elapse(Duration(seconds: 1));
      expect(lastTimersRun, [1]);

      // Elapsed: 3
      // The second timer should complete and the third one should be added in
      // pending timers.
      await stabilizer.elapse(Duration(seconds: 1));
      expect(lastTimersRun, [1, 2]);

      // Elapsed: 6
      // All timers complete.
      await stabilizer.elapse(Duration(seconds: 3));
      expect(lastTimersRun, [1, 2, 3]);
    });

    test('should elapse timers manually, microtasks automatically', () async {
      var tasks = <String>[];
      ngZone.run(() {
        scheduleMicrotask(() {
          tasks.add('#1: scheduleMicrotask');
        });
        Timer.run(() {
          tasks.add('#2: Timer.run');
          scheduleMicrotask(() {
            tasks.add('#3: scheduleMicrotask');
            Timer.run(() {
              tasks.add('#4: Timer.run');
            });
          });
          Timer(Duration(seconds: 5), () {
            tasks.add('#5: Timer(Duration(seconds: 5))');
          });
        });
      });

      await stabilizer.update();
      expect(tasks, ['#1: scheduleMicrotask']);
      tasks.clear();

      await stabilizer.elapse(Duration.zero);
      expect(tasks, [
        '#2: Timer.run',
        '#3: scheduleMicrotask',
        '#4: Timer.run',
      ]);
      tasks.clear();

      await stabilizer.elapse(Duration(seconds: 5));
      expect(tasks, ['#5: Timer(Duration(seconds: 5))']);
    });

    test('should execute periodic timers', () async {
      Timer timer;
      var counter = 0;

      ngZone.run(() {
        timer = Timer.periodic(Duration(seconds: 1), (_) => counter++);
      });

      expect(counter, 0);

      await stabilizer.elapse(Duration(seconds: 1));
      expect(counter, 1);

      await stabilizer.elapse(Duration(seconds: 1));
      expect(counter, 2);

      timer.cancel();
      await stabilizer.elapse(Duration(seconds: 1));
      expect(counter, 2);
    });

    test('should propogate synchronous errors', () {
      expect(
        stabilizer.update(() => throw _IntentionalError()),
        _throwsIntentionalError,
      );
    });

    test('should propogate asynchronous errors from microtasks', () {
      expect(() {
        return stabilizer.update(() {
          scheduleMicrotask(() {
            throw _IntentionalError();
          });
        });
      }, _throwsIntentionalError);
    });

    test('should propogate asynchronous errors from an async body', () {
      expect(() {
        return stabilizer.update(() async {
          throw _IntentionalError();
        });
      }, _throwsIntentionalError);
    });

    test('should propogate asynchronous errors from timers', () async {
      // Schedules a timer.
      await expectLater(stabilizer.update(() {
        Timer.run(() {
          throw _IntentionalError();
        });
      }), completes);

      // Executes a timer.
      expect(stabilizer.elapse(Duration.zero), _throwsIntentionalError);
    });

    test('should propogate deeply nested asynchronous errors', () async {
      // Schedules a timer.
      await expectLater(stabilizer.update(() {
        Timer.run(() async {
          scheduleMicrotask(() async {
            Future.delayed(Duration(seconds: 3), () {
              throw _IntentionalError();
            });
          });
        });
      }), completes);

      // Executes a timer.
      expect(stabilizer.elapse(Duration(seconds: 3)), _throwsIntentionalError);
    });

    test('should throw TimersWillNotCompleteError', () {
      var iterations = FakeTimeNgZoneStabilizer.defaultMaxIterations;
      ngZone.run(() {
        void scheduleTimer() {
          if (iterations >= 0) {
            iterations--;
            Timer.run(scheduleTimer);
          }
        }

        scheduleTimer();
      });
      expect(
        stabilizer.elapse(Duration.zero),
        throwsA(isA<TimersWillNotCompleteError>()),
      );
    });

    test('should have a configurable maxIterations', () {
      // Use a different maxIterations:
      stabilizer = FakeTimeNgZoneStabilizer(
        timerZone,
        ngZone,
        maxIterations: FakeTimeNgZoneStabilizer.defaultMaxIterations + 1,
      );

      var iterations = FakeTimeNgZoneStabilizer.defaultMaxIterations;
      ngZone.run(() {
        void scheduleTimer() {
          if (iterations >= 0) {
            iterations--;
            Timer.run(scheduleTimer);
          }
        }

        scheduleTimer();
      });
      expect(
        stabilizer.elapse(Duration.zero),
        completes,
      );
    });
  });

  group('RealTimeNgZoneStabilizer', () {
    NgZone ngZone;
    RealTimeNgZoneStabilizer stabilizer;

    setUp(() {
      final timerZone = TimerHookZone();
      ngZone = timerZone.run(() => NgZone());
      stabilizer = RealTimeNgZoneStabilizer(timerZone, ngZone);
    });

    test('should not elapse timers outside of Angular zone', () async {
      var lastTimersRun = <int>[];
      var completer = Completer<void>();
      ngZone.runOutsideAngular(() {
        Timer(Duration(seconds: 1), () {
          lastTimersRun.add(1);
          completer.complete();
        });
      });
      expect(lastTimersRun, isEmpty);

      await stabilizer.update();
      expect(lastTimersRun, isEmpty);

      await completer.future;
      expect(lastTimersRun, [1]);
    });

    test('should elapse a series of simple timers', () async {
      var lastTimersRun = <int>[];
      ngZone.run(() {
        Timer(Duration(seconds: 1), () {
          lastTimersRun.add(1);
        });
        Timer(Duration(seconds: 2), () {
          lastTimersRun.add(2);
        });
        Timer(Duration(seconds: 3), () {
          lastTimersRun.add(3);
        });
      });
      expect(lastTimersRun, isEmpty);

      await stabilizer.update();
      expect(lastTimersRun, [1, 2, 3]);
    });

    test('should elapse timers manually, microtasks automatically', () async {
      var tasks = <String>[];
      ngZone.run(() {
        scheduleMicrotask(() {
          tasks.add('#1: scheduleMicrotask');
        });
        Timer.run(() {
          tasks.add('#2: Timer.run');
          scheduleMicrotask(() {
            tasks.add('#3: scheduleMicrotask');
            Timer.run(() {
              tasks.add('#4: Timer.run');
            });
          });
          Timer(Duration(seconds: 5), () {
            tasks.add('#5: Timer(Duration(seconds: 5))');
          });
        });
      });

      expect(await stabilizer.update(), isFalse);
      expect(tasks, [
        '#1: scheduleMicrotask',
        '#2: Timer.run',
        '#3: scheduleMicrotask',
        '#4: Timer.run',
      ]);
      tasks.clear();

      expect(await stabilizer.update(), isTrue);
      expect(tasks, [
        '#5: Timer(Duration(seconds: 5))',
      ]);
    });

    test('should consider a cancelled timer completed', () {
      final pendingTimer = ngZone.run(() {
        return Timer(
          Duration(seconds: 30),
          expectAsync0(() {}, count: 0),
        );
      });
      expect(stabilizer.isStable, isFalse);
      pendingTimer.cancel();
      expect(stabilizer.isStable, isTrue);
    });

    test('should propogate synchronous errors', () {
      expect(
        stabilizer.update(() => throw _IntentionalError()),
        _throwsIntentionalError,
      );
    });

    test('should propogate asynchronous errors from microtasks', () {
      expect(() {
        return stabilizer.update(() {
          scheduleMicrotask(() {
            throw _IntentionalError();
          });
        });
      }, _throwsIntentionalError);
    });

    test('should propogate asynchronous errors from an async body', () {
      expect(() {
        return stabilizer.update(() async {
          throw _IntentionalError();
        });
      }, _throwsIntentionalError);
    });

    test('should propogate asynchronous errors from timers', () async {
      // Schedules and executes a timer.
      expect(stabilizer.update(() {
        Timer.run(() {
          throw _IntentionalError();
        });
      }), _throwsIntentionalError);
    });

    test('should propogate deeply nested asynchronous errors', () async {
      // Schedules and executes a timer.
      expect(stabilizer.update(() {
        Timer.run(() async {
          scheduleMicrotask(() async {
            throw _IntentionalError();
          });
        });
      }), _throwsIntentionalError);
    });
  });
}

class _IntentionalError extends Error {}

final _throwsIntentionalError = throwsA(TypeMatcher<_IntentionalError>());
