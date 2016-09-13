import 'dart:async';

import 'package:angular2/src/core/zone/ng_zone.dart';
import 'package:angular2/src/testing/test_bed/ng_dom_stabilizer.dart';
import 'package:test/test.dart';

void main() {
  group('$NgZoneStabilizer', () {
    NgZone ngZone;
    NgDomStabilizer domStabilizer;

    setUp(() {
      ngZone = new NgZone();
      domStabilizer = new NgZoneStabilizer(ngZone);
    });

    test('should elapse microtasks', () async {
      var state = 0;
      domStabilizer.execute(() {
        scheduleMicrotask(() => state = 1);
      });
      expect(state, 0);
      await domStabilizer.stabilize();
      expect(state, 1);
    });

    test('should elapse timers', () async {
      var state = 0;
      domStabilizer.execute(() {
        Timer.run(() => state = 1);
      });
      expect(state, 0);
      await domStabilizer.stabilize();
      expect(state, 1);
    });

    test('should elapse a complex set of tasks', () async {
      var state = 0;
      domStabilizer.execute(() {
        scheduleMicrotask(() {
          state++;
          scheduleMicrotask(() {
            state++;
            Timer.run(() {
              state++;
              scheduleMicrotask(() {
                state++;
                Timer.run(() {
                  state++;
                });
              });
            });
          });
        });
      });
      expect(state, 0);
      await domStabilizer.stabilize();
      expect(state, 5);
    });
  });
}
