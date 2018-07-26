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
      ngZone = NgZone();
      ngZoneStabilizer = NgZoneStabilizer(ngZone);
    });

    test('should forward a synchronous error during update', () async {
      expect(ngZoneStabilizer.update(() {
        throw StateError('Test');
      }), throwsStateError);
    });

    test('should forward a synchronous error while stabilizng', () async {
      expect(ngZoneStabilizer.stabilize(runAndTrackSideEffects: () {
        throw StateError('Test');
      }), throwsStateError);
    });

    test('should forward an asynchronous error during update', () async {
      expect(ngZoneStabilizer.update(() {
        scheduleMicrotask(() {
          throw StateError('Test');
        });
      }), throwsStateError);
    });

    test('should forward an asynchronous error while stabilizing', () async {
      expect(ngZoneStabilizer.stabilize(runAndTrackSideEffects: () {
        scheduleMicrotask(() {
          throw StateError('Test');
        });
      }), throwsStateError);
    });

    test('should forward an asynchronous error via timer', () async {
      expect(ngZoneStabilizer.update(() {
        Timer.run(() {
          throw StateError('Test');
        });
      }), throwsStateError);
    });

    test('should forward an asynchronus error via timer stabilizing', () async {
      expect(ngZoneStabilizer.stabilize(runAndTrackSideEffects: () {
        Timer.run(() {
          throw StateError('Test');
        });
      }), throwsStateError);
    });

    test('should forward an asynchronus error via delayed future stabilizing',
        () async {
      expect(ngZoneStabilizer.stabilize(runAndTrackSideEffects: () {
        Future.delayed(Duration(milliseconds: 100), () {
          throw StateError('Test');
        });
      }), throwsStateError);
    });

    test('should forward an asynchronous error via late stabilizing', () async {
      expect(ngZoneStabilizer.stabilize(runAndTrackSideEffects: () {
        Timer.run(() {
          scheduleMicrotask(() {
            Timer.run(() {
              scheduleMicrotask(() {
                throw StateError('Test');
              });
            });
          });
        });
      }), throwsStateError);
    });

    test('should forward an asynchrnous error in the far future', () async {
      expect(ngZoneStabilizer.stabilize(runAndTrackSideEffects: () async {
        for (var i = 0; i < 20; i++) {
          await Future(() {});
          await Future.value();
        }
        throw StateError('Test');
      }), throwsStateError);
    });

    test('should stabilize existing events', () async {
      var asyncEventsCompleted = false;
      ngZone.run(() async {
        for (var i = 0; i < 20; i++) {
          await Future(() {});
          await Future.value();
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
          runAndTrackSideEffects: () {
            // Just enough asynchronous events to exceed the threshold; not 1:1.
            var timersRemaining = 10;

            void runTimer() {
              if (--timersRemaining > 0) {
                scheduleMicrotask(() => Timer.run(runTimer));
              }
            }

            runTimer();
          },
          threshold: 5,
        ),
        throwsA(const isInstanceOf<WillNeverStabilizeError>()),
      );
    });

    test('should stabilize if animation timers are used', () async {
      expect(
        ngZoneStabilizer.stabilize(
            runAndTrackSideEffects: () async {
              Timer(const Duration(milliseconds: 100), () {});
            },
            threshold: 1),
        completion(isNull),
      );
    });
  });

  group('$DelegatingNgTestStabilizer', () {
    NgZoneStabilizerForTesting ngZoneStabilizer;
    FakeNgTestStabilizer fakeNgTestStabilizer;
    AlwaysStableNgTestStabilizer alwaysStableNgTestStabilizer;
    DelegatingNgTestStabilizer delegatingNgTestStabilizer;

    setUp(() {
      final ngZone = NgZone();
      ngZoneStabilizer = NgZoneStabilizerForTesting(ngZone);
      fakeNgTestStabilizer = FakeNgTestStabilizer(ngZone);
      alwaysStableNgTestStabilizer = AlwaysStableNgTestStabilizer();
      delegatingNgTestStabilizer = DelegatingNgTestStabilizer([
        ngZoneStabilizer,
        fakeNgTestStabilizer,
        alwaysStableNgTestStabilizer
      ]);
    });

    test('should stabilize if there is no function to run', () async {
      await delegatingNgTestStabilizer.stabilize();
      expect(ngZoneStabilizer.updateCount, 1);
      expect(fakeNgTestStabilizer.updateCount, 1);
      expect(alwaysStableNgTestStabilizer.updateCount, 1);
    });

    test('should stabilize if there is a function to run', () async {
      await delegatingNgTestStabilizer.stabilize(runAndTrackSideEffects: () {
        scheduleMicrotask(() {});
      });
      expect(ngZoneStabilizer.updateCount, 2);
      expect(fakeNgTestStabilizer.updateCount, 2);
      expect(alwaysStableNgTestStabilizer.updateCount, 1);
    });

    test('should only run update at least once and when needed', () async {
      fakeNgTestStabilizer.minUpdateCountToStabilize = 5;

      await delegatingNgTestStabilizer.stabilize();
      expect(ngZoneStabilizer.updateCount, 1);
      expect(fakeNgTestStabilizer.updateCount, 5);
      expect(alwaysStableNgTestStabilizer.updateCount, 1);
    });
  });
}

abstract class _HasUpdateCount {
  int updateCount = 0;
}

/// [NgZoneStabilizerForTesting] increments [updateCount] when a `update` is
/// called.
class NgZoneStabilizerForTesting extends NgZoneStabilizer with _HasUpdateCount {
  NgZoneStabilizerForTesting(NgZone ngZone) : super(ngZone);

  @override
  Future<bool> update([void Function() fn]) async {
    final result = await super.update(fn);
    updateCount++;
    return result;
  }
}

class AlwaysStableNgTestStabilizer extends NgTestStabilizer
    with _HasUpdateCount {
  @override
  bool get isStable => true;

  @override
  Future<bool> update([void Function() fn]) async {
    // [fn] is not supported.
    if (fn != null) return false;

    updateCount++;
    return isStable;
  }
}

/// [FakeNgTestStabilizer] adds every [NgZone] onEventDone to its task list.
class FakeNgTestStabilizer extends NgTestStabilizer with _HasUpdateCount {
  final _tasks = <int>[];
  int _nextTaskId = 0;

  int minUpdateCountToStabilize = 0;

  FakeNgTestStabilizer(NgZone ngZone) {
    ngZone.onEventDone.listen((_) {
      _tasks.add(_nextTaskId++);
    });
  }

  @override
  bool get isStable =>
      _tasks.isEmpty && updateCount >= minUpdateCountToStabilize;

  @override
  Future<bool> update([void Function() fn]) async {
    // [fn] is not supported.
    if (fn != null) return false;

    if (_tasks.isNotEmpty) {
      _tasks.removeAt(0);
    }
    updateCount++;
    return isStable;
  }
}
