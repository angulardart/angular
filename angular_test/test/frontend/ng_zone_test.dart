import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_test/src/frontend/ng_zone/fake_time_stabilizer.dart';
import 'package:angular_test/src/frontend/ng_zone/intercepted_timer.dart';
import 'package:test/test.dart';

void main() {
  group('InterceptedTimer', () {
    Zone childZone;

    setUp(() {
      childZone = Zone.current.fork(
        specification: ZoneSpecification(
          createTimer: InterceptedTimer.createTimer,
        ),
      );
    });

    test('should be created and run in the correct Zone', () {
      childZone.run(() {
        Timer.run(expectAsync0(() {
          expect(Zone.current, childZone);
        }));
      });
    });

    test('should be able to be manually completed', () async {
      InterceptedTimer upcast;
      childZone.run(() {
        final timer = Timer(Duration(seconds: 1), expectAsync0(() {}));
        upcast = timer as InterceptedTimer;
      });

      // Manually complete the timer.
      upcast.complete();

      // Ensure it does not fire a second time (i.e. it was cancelled).
      await Future.delayed(Duration(seconds: 2));
    });
  });

  group('FakeTimeNgZoneStabilizer', () {
    NgZone ngZone;
    FakeTimeNgZoneStabilizer stabilizer;

    setUp(() {
      stabilizer = FakeTimeNgZoneStabilizer(() {
        return ngZone = NgZone(enableLongStackTrace: true);
      });
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
  });
}

class _IntentionalError extends Error {}

final _throwsIntentionalError = throwsA(isInstanceOf<_IntentionalError>());
