@TestOn('browser')
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'ng_zone_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('$NgZone', () {
    NgZone zone;
    List<String> log;
    List errors;
    List traces;

    List<StreamSubscription> subs;

    void createNgZone({@required bool enableLongStackTrace}) {
      ExceptionHandler.debugAsyncStackTraces(enableLongStackTrace);
      zone = NgZone();
      subs = <StreamSubscription>[
        zone.onError.listen((e) {
          errors.add(e.error);
          traces.add(e.stackTrace);
        }),
        zone.onEventDone.listen((_) => log.add('onEventDone')),
        zone.onMicrotaskEmpty.listen((_) => log.add('onMicrotaskEmpty')),
        zone.onTurnDone.listen((_) => log.add('onTurnDone')),
        zone.onTurnStart.listen((_) => log.add('onTurnStart')),
      ];
    }

    setUp(() {
      log = <String>[];
      errors = [];
      traces = [];
    });

    tearDown(() {
      if (subs != null) {
        for (final sub in subs) {
          sub.cancel();
        }
      }
    });

    group('hasPendingMicrotasks', () {
      setUp(() => createNgZone(enableLongStackTrace: false));

      test('should initially be false', () {
        expect(zone.hasPendingMicrotasks, false);
      });

      test('should be true when a microtask is queued', () async {
        final onCompleter = Completer<Null>();
        zone.run(() {
          log.add('--- entered zone ---');
          scheduleMicrotask(() {
            log.add('--- ran microtask ---');
            onCompleter.complete();
          });
        });
        expect(zone.hasPendingMicrotasks, true);
        await onCompleter.future;
        expect(zone.hasPendingMicrotasks, false);
        expect(log, [
          'onTurnStart',
          '--- entered zone ---',
          '--- ran microtask ---',
          'onEventDone',
          'onMicrotaskEmpty',
          'onTurnDone',
        ]);
      });
    });

    group('hasPendingMacrotasks', () {
      setUp(() => createNgZone(enableLongStackTrace: false));

      test('should initially be false', () {
        expect(zone.hasPendingMacrotasks, false);
      });

      test('should be true when a timer is queued', () async {
        final onCompleter = Completer<Null>();
        zone.run(() {
          log.add('--- entered zone ---');
          Timer.run(() {
            log.add('--- ran timer ---');
            onCompleter.complete();
          });
        });
        expect(zone.hasPendingMacrotasks, true);
        await onCompleter.future;
        expect(zone.hasPendingMacrotasks, false);
        expect(log, [
          'onTurnStart',
          '--- entered zone ---',
          'onEventDone',
          'onMicrotaskEmpty',
          'onTurnDone',
          'onTurnStart',
          '--- ran timer ---',
          'onEventDone',
          'onMicrotaskEmpty',
          'onTurnDone',
        ]);
      });
    });

    group('isInAngularZone', () {
      setUp(() => createNgZone(enableLongStackTrace: false));

      test('should be false outside of the zone', () {
        zone.runOutsideAngular(() {
          expect(NgZone.isInAngularZone(), false);
        });
      });

      test('should be true inside of the zone', () {
        zone.run(() {
          expect(NgZone.isInAngularZone(), true);
        });
      });
    });

    group('nested zone', () {
      NgZone nestedZone;

      setUp(() {
        createNgZone(enableLongStackTrace: false);
        zone.run(() {
          nestedZone = NgZone();
        });
        log = <String>[];
        subs.addAll([
          nestedZone.onEventDone.listen((_) => log.add('nested onEventDone')),
          nestedZone.onMicrotaskEmpty
              .listen((_) => log.add('nested onMicrotaskEmpty')),
          nestedZone.onTurnDone.listen((_) => log.add('nested onTurnDone')),
          nestedZone.onTurnStart.listen((_) => log.add('nested onTurnStart')),
        ]);
      });

      test('should have all events contained within parent zone', () async {
        final onCompleter = Completer<Null>();
        nestedZone.run(() {
          log.add('--- entered zone ---');
          scheduleMicrotask(() {
            log.add('--- ran microtask ---');
            onCompleter.complete();
          });
        });
        expect(zone.hasPendingMicrotasks, true);
        await onCompleter.future;
        expect(zone.hasPendingMicrotasks, false);
        expect(log, [
          'onTurnStart',
          'nested onTurnStart',
          '--- entered zone ---',
          '--- ran microtask ---',
          'nested onEventDone',
          'nested onMicrotaskEmpty',
          'nested onTurnDone',
          'onEventDone',
          'onMicrotaskEmpty',
          'onTurnDone'
        ]);
      });
    });

    group('run', () {
      setUp(() => createNgZone(enableLongStackTrace: false));

      test('should return the body return value', () async {
        final result = zone.run(() => 'Hello World');
        expect(result, 'Hello World');
      });

      test('should run subscriber listeners inside the zone', () async {
        final someEvents = Stream.fromIterable([1, 2, 3]);
        zone.run(() {
          someEvents.listen((_) {
            log.add('--- subscription event: ${NgZone.isInAngularZone()} ---');
          });
        });
        await Future.delayed(Duration.zero);
        expect(log, [
          'onTurnStart',
          '--- subscription event: true ---',
          '--- subscription event: true ---',
          '--- subscription event: true ---',
          'onEventDone',
          'onMicrotaskEmpty',
          'onTurnDone',
        ]);
      });
    });

    group('without longStackTrace', () {
      setUp(() => createNgZone(enableLongStackTrace: false));

      test('should capture an error and stack trace', () async {
        zone.runGuarded(() {
          void bar() {
            throw StateError('How did I end up here?');
          }

          void foo() {
            scheduleMicrotask(bar);
          }

          scheduleMicrotask(foo);
        });
        await Future.delayed(Duration.zero);
        expect(errors.map((e) => e.toString()), [
          'Bad state: How did I end up here?',
        ]);
        final fullStackTrace = traces.map((t) => t.toString()).join('');
        expect(fullStackTrace, contains('bar'));
        expect(fullStackTrace, isNot(contains('foo')));
      }, onPlatform: {
        'firefox': Skip('Strack trace appears differently'),
      });
    });

    group('with longStackTrace', () {
      setUp(() => createNgZone(enableLongStackTrace: true));

      test('should capture an error and a long stack trace', () async {
        zone.runGuarded(() {
          void bar() {
            throw StateError('How did I end up here?');
          }

          void foo() {
            scheduleMicrotask(bar);
          }

          scheduleMicrotask(foo);
        });
        await Future.delayed(Duration.zero);
        expect(errors.map((e) => e.toString()), [
          'Bad state: How did I end up here?',
        ]);
        final fullStackTrace = traces.map((t) => t.toString()).join('');
        expect(fullStackTrace, contains('bar'));
        expect(fullStackTrace, contains('foo'));
      }, onPlatform: {
        'firefox': Skip('Strack trace appears differently'),
      });
    });

    test('should support "runAfterChangesObserved"', () async {
      createNgZone(enableLongStackTrace: true);
      var counter = 0;
      return zone.run(() {
        counter++;
        scheduleMicrotask(() {
          counter++;
        });
        zone.runAfterChangesObserved(expectAsync0(() {
          expect(counter, 2);
        }));
      });
    });

    test('should support "runAfterChangesObserved" in onTurnDone', () async {
      createNgZone(enableLongStackTrace: true);
      var onTurnDoneTriggered = 0;
      var sub = zone.onTurnDone.listen((_) {
        onTurnDoneTriggered++;
        if (onTurnDoneTriggered == 0) {
          zone.runAfterChangesObserved(() {
            zone.run(() {});
          });
        }
      });
      zone.run(() {});
      await Future(() {});
      expect(onTurnDoneTriggered, 1);
      await sub.cancel();
    });

    test('should execute "runAfterChangesObserved" callback in this zone',
        () async {
      createNgZone(enableLongStackTrace: true);
      var onMicrotaskEmptyTriggered = 0;
      var counter = 0;
      var sub = zone.onMicrotaskEmpty.listen((_) {
        onMicrotaskEmptyTriggered++;
      });
      final completer = Completer<void>();
      zone.run(() {
        zone.runAfterChangesObserved(() {
          expect(onMicrotaskEmptyTriggered, 1);
          counter++;
          completer.complete();
        });
      });
      await completer.future;
      expect(counter, 1);
      expect(onMicrotaskEmptyTriggered, 2); // onMicrotaskEmpty ran again.
      await sub.cancel();
    });
  });
}
