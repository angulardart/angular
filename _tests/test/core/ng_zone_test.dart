import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';

void main() {
  group('$NgZone', () {
    late NgZone zone;
    late List<String> log;
    late List<Object> errors;
    late List<StackTrace> traces;

    late List<StreamSubscription<void>> subs;

    void createNgZone() {
      zone = NgZone();
      subs = [
        zone.onUncaughtError.listen((e) {
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
      for (final sub in subs) {
        sub.cancel();
      }
    });

    group('hasPendingMicrotasks', () {
      setUp(() => createNgZone());

      test('should initially be false', () {
        expect(zone.hasPendingMicrotasks, false);
      });

      test('should be true when a microtask is queued', () async {
        final onCompleter = Completer<void>();
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
      setUp(() => createNgZone());

      test('should initially be false', () {
        expect(zone.hasPendingMacrotasks, false);
      });

      test('should be true when a timer is queued', () async {
        final onCompleter = Completer<void>();
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
      setUp(() => createNgZone());

      test('should be false outside of the zone', () {
        zone.runOutsideAngular(() {
          expect(zone.inInnerZone, isFalse);
        });
      });

      test('should be true inside of the zone', () {
        zone.run(() {
          expect(zone.inInnerZone, isTrue);
        });
      });
    });

    group('nested zone', () {
      late NgZone nestedZone;

      setUp(() {
        createNgZone();
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
        final onCompleter = Completer<void>();
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
      setUp(() => createNgZone());

      test('should return the body return value', () async {
        final result = zone.run(() => 'Hello World');
        expect(result, 'Hello World');
      });

      test('should run subscriber listeners inside the zone', () async {
        final someEvents = Stream.fromIterable([1, 2, 3]);
        zone.run(() {
          someEvents.listen((_) {
            log.add('--- subscription event: ${zone.inInnerZone} ---');
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
  });
}
