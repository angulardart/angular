import 'dart:async';
import 'package:angular_test/src/frontend/ng_zone/timer.dart';
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
}
