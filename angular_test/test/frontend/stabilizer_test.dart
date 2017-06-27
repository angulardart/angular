// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/di.dart';
import 'package:angular_test/src/errors.dart';
import 'package:angular_test/src/frontend/stabilizer.dart';

void main() {
  group('$NgZoneStabilizer', () {
    NgZone ngZone;
    NgZoneStabilizer ngZoneStabilizer;

    setUp(() {
      ngZone = new NgZone();
      ngZoneStabilizer = new NgZoneStabilizer(ngZone);
    });

    test('should forward a synchronous error during update', () async {
      expect(ngZoneStabilizer.update(() {
        throw new StateError('Test');
      }), throwsStateError);
    });

    test('should forward a synchronous error while stabilizng', () async {
      expect(ngZoneStabilizer.stabilize(run: () {
        throw new StateError('Test');
      }), throwsStateError);
    });

    test('should forward an asynchronous error during update', () async {
      expect(ngZoneStabilizer.update(() {
        scheduleMicrotask(() {
          throw new StateError('Test');
        });
      }), throwsStateError);
    });

    test('should forward an asynchronous error while stabilizing', () async {
      expect(ngZoneStabilizer.stabilize(run: () {
        scheduleMicrotask(() {
          throw new StateError('Test');
        });
      }), throwsStateError);
    });

    test('should forward an asynchronous error via timer', () async {
      expect(ngZoneStabilizer.update(() {
        Timer.run(() {
          throw new StateError('Test');
        });
      }), throwsStateError);
    });

    test('should forward an asynchronus error via timer stabilizing', () async {
      expect(ngZoneStabilizer.stabilize(run: () {
        Timer.run(() {
          throw new StateError('Test');
        });
      }), throwsStateError);
    });

    test('should forward an asynchronous error via late stabilizing', () async {
      expect(ngZoneStabilizer.stabilize(run: () {
        Timer.run(() {
          scheduleMicrotask(() {
            Timer.run(() {
              scheduleMicrotask(() {
                throw new StateError('Test');
              });
            });
          });
        });
      }), throwsStateError);
    });

    test('should forward an asynchrnous error in the far future', () async {
      expect(ngZoneStabilizer.stabilize(run: () async {
        for (var i = 0; i < 20; i++) {
          await new Future(() {});
          await new Future.value();
        }
        throw new StateError('Test');
      }), throwsStateError);
    });

    test('should stabilize existing events', () async {
      var asyncEventsCompleted = false;
      ngZone.run(() async {
        for (var i = 0; i < 20; i++) {
          await new Future(() {});
          await new Future.value();
        }
        asyncEventsCompleted = true;
      });
      expect(asyncEventsCompleted, isFalse);
      await ngZoneStabilizer.stabilize();
      expect(asyncEventsCompleted, isTrue);
    });

    test('should throw if stabilization never occurs', () async {
      expect(
          ngZoneStabilizer.stabilize(
              run: () {
                // Just enough asynchronous events to exceed the threshold; not 1:1.
                Timer.run(() {
                  Timer.run(() {
                    Timer.run(() {});
                  });
                });
              },
              threshold: 5),
          throwsA(const isInstanceOf<WillNeverStabilizeError>()));
    });
  });
}
