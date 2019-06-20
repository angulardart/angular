@TestOn('browser')
import 'dart:async';

import 'package:angular/angular.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:angular/src/core/zone/ng_zone.dart';

// Schedules a microtasks (using a resolved promise .then())
void microTask(void fn()) {
  scheduleMicrotask(() {
    // We do double dispatch so that we  can wait for scheduleMicrotasks in
    // the Testability when NgZone becomes stable.
    scheduleMicrotask(fn);
  });
}

abstract class TestabilityCallback {
  dynamic execute(value);
}

class MockCallback extends Mock implements TestabilityCallback {}

@Injectable()
class TestZone implements NgZone {
  final _delegate = NgZone();

  StreamController<Null> _onUnstableStream;

  @override
  Stream<Null> get onTurnStart {
    return _onUnstableStream.stream;
  }

  StreamController<Null> _onStableStream;

  @override
  Stream<Null> get onTurnDone {
    return _onStableStream.stream;
  }

  TestZone() {
    _onUnstableStream = StreamController.broadcast(sync: true);
    _onStableStream = StreamController.broadcast(sync: true);
  }

  void unstable() {
    this._onUnstableStream.add(null);
  }

  void stable() {
    this._onStableStream.add(null);
  }

  @override
  void dispose() => _delegate.dispose();

  @override
  bool get hasPendingMacrotasks => _delegate.hasPendingMacrotasks;

  @override
  bool get hasPendingMicrotasks => _delegate.hasPendingMicrotasks;

  @override
  bool get inInnerZone => _delegate.inInnerZone;

  @override
  bool get inOuterZone => _delegate.inOuterZone;

  @override
  bool get isRunning => _delegate.isRunning;

  @override
  Stream<NgZoneError> get onError => _delegate.onError;

  @override
  Stream<void> get onEventDone => _delegate.onEventDone;

  @override
  Stream<void> get onMicrotaskEmpty => _delegate.onMicrotaskEmpty;

  @override
  R run<R>(callback) => _delegate.run(callback);

  @override
  void runAfterChangesObserved(callback) {
    _delegate.runAfterChangesObserved(callback);
  }

  @override
  void runGuarded(callback) {
    _delegate.runGuarded(callback);
  }

  @override
  R runOutsideAngular<R>(callback) => _delegate.runOutsideAngular(callback);
}

void main() {
  group('Testability', () {
    Testability testability;
    MockCallback callback;
    MockCallback callback2;
    TestZone ngZone;
    setUp(() {
      ngZone = TestZone();
      testability = Testability(ngZone);
      callback = MockCallback();
      callback2 = MockCallback();
    });
    group('Pending count logic', () {
      test('should start with a pending count of 0', () {
        expect(testability.getPendingRequestCount(), 0);
      });
      test('should fire whenstable callbacks if pending count is 0', () async {
        testability.whenStable((value) => callback.execute(value));
        microTask(() {
          verify(callback.execute(any)).called(1);
        });
      });
      test('should not fire callbacks synchronously if pending count is 0', () {
        testability.whenStable((value) => callback.execute(value));
        verifyZeroInteractions(callback);
      });
      test('should not call whenstable callbacks when there are pending counts',
          () async {
        testability.increasePendingRequestCount();
        testability.increasePendingRequestCount();
        testability.whenStable((value) => callback.execute(value));
        microTask(() {
          verifyZeroInteractions(callback);
          testability.decreasePendingRequestCount();
          microTask(() {
            verifyZeroInteractions(callback);
          });
        });
      });
      test('should fire callbacks when pending drops to 0', () async {
        testability.increasePendingRequestCount();
        testability.whenStable((value) => callback.execute(value));
        microTask(() {
          verifyZeroInteractions(callback);
          testability.decreasePendingRequestCount();
          microTask(() {
            verify(callback.execute(any)).called(1);
          });
        });
      });
      test('should not fire callbacks synchronously when pending drops to 0',
          () {
        testability.increasePendingRequestCount();
        testability.whenStable((value) => callback.execute(value));
        testability.decreasePendingRequestCount();
        verifyZeroInteractions(callback);
      });
      test(
          'should fire whenstable callbacks with didWork if pending count is 0',
          () async {
        testability.whenStable((value) => callback.execute(value));
        microTask(() {
          verify(callback.execute(false)).called(1);
        });
      });
      test('should fire callbacks with didWork when pending drops to 0',
          () async {
        testability.increasePendingRequestCount();
        testability.whenStable((value) => callback.execute(value));
        microTask(() {
          testability.decreasePendingRequestCount();
          microTask(() {
            verify(callback.execute(true)).called(1);
            testability.whenStable((value) => callback2.execute(value));
            microTask(() {
              verify(callback2.execute(false)).called(1);
            });
          });
        });
      });
    });
    group('NgZone callback logic', () {
      test('should fire whenstable callback if event is already finished',
          () async {
        ngZone.unstable();
        ngZone.stable();
        testability.whenStable((value) => callback.execute(value));
        microTask(() {
          verify(callback.execute(any)).called(1);
        });
      });
      test(
          'should not fire whenstable callbacks synchronously '
          'if event is already finished', () {
        ngZone.unstable();
        ngZone.stable();
        testability.whenStable((value) => callback.execute(value));
        verifyZeroInteractions(callback);
      });
      test('should fire whenstable callback when event finishes', () async {
        ngZone.unstable();
        testability.whenStable((value) => callback.execute(value));
        microTask(() {
          verifyZeroInteractions(callback);
          ngZone.stable();
          microTask(() {
            verify(callback.execute(any)).called(1);
          });
        });
      });
      test(
          'should not fire whenstable callbacks '
          'synchronously when event finishes', () {
        ngZone.unstable();
        testability.whenStable((value) => callback.execute(value));
        ngZone.stable();
        verifyZeroInteractions(callback);
      });
      test('should not fire whenstable callback when event did not finish',
          () async {
        ngZone.unstable();
        testability.increasePendingRequestCount();
        testability.whenStable((value) => callback.execute(value));
        microTask(() {
          verifyZeroInteractions(callback);
          testability.decreasePendingRequestCount();
          microTask(() {
            verifyZeroInteractions(callback);
            ngZone.stable();
            microTask(() {
              verify(callback.execute(any)).called(1);
            });
          });
        });
      });
      test('should not fire whenstable callback when there are pending counts',
          () async {
        ngZone.unstable();
        testability.increasePendingRequestCount();
        testability.increasePendingRequestCount();
        testability.whenStable((value) => callback.execute(value));
        microTask(() {
          verifyZeroInteractions(callback);
          ngZone.stable();
          microTask(() {
            verifyZeroInteractions(callback);
            testability.decreasePendingRequestCount();
            microTask(() {
              verifyZeroInteractions(callback);
              testability.decreasePendingRequestCount();
              microTask(() {
                verify(callback.execute(any)).called(1);
              });
            });
          });
        });
      });
      test(
          'should fire whenstable callback with didWork '
          'if event is already finished', () async {
        ngZone.unstable();
        ngZone.stable();
        testability.whenStable((value) => callback.execute(value));
        microTask(() {
          verify(callback.execute(true)).called(1);
          testability.whenStable((value) => callback2.execute(value));
          microTask(() {
            verify(callback2.execute(false)).called(1);
          });
        });
      });
      test('should fire whenstable callback with didwork when event finishes',
          () async {
        ngZone.unstable();
        testability.whenStable((value) => callback.execute(value));
        microTask(() {
          ngZone.stable();
          microTask(() {
            verify(callback.execute(true)).called(1);
            testability.whenStable((value) => callback2.execute(value));
            microTask(() {
              verify(callback2.execute(false)).called(1);
            });
          });
        });
      });
    });
  });
}
