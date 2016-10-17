@TestOn('browser')
library angular2.test.common.pipes.async_pipe_test;

import 'dart:async';

import 'package:angular2/common.dart' show AsyncPipe;
import 'package:angular2/core.dart' show WrappedValue;
import 'package:angular2/src/facade/async.dart' show EventEmitter;
import 'package:angular2/src/platform/dom/dom_adapter.dart' show DOM;
import 'package:angular2/testing_internal.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../control_mocks.dart';

void main() {
  group('AsyncPipe AutoObservable', () {
    var emitter;
    var pipe;
    var ref;
    var message = new Object();
    setUp(() {
      emitter = new EventEmitter();
      ref = new MockChangeDetectorRef();
      pipe = new AsyncPipe(ref);
    });
    group('transform', () {
      test('should return null when subscribing to an observable', () {
        expect(pipe.transform(emitter), isNull);
      });
      test('should return the latest available value wrapped', () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
          pipe.transform(emitter);
          emitter.add(message);
          Timer.run(() {
            WrappedValue res = pipe.transform(emitter);
            expect(res.wrapped, message);
            completer.done();
          });
        });
      });
      test(
          'should return same value when nothing has changed since the last call',
          () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
          pipe.transform(emitter);
          emitter.add(message);
          Timer.run(() {
            pipe.transform(emitter);
            expect(pipe.transform(emitter), message);
            completer.done();
          });
        });
      });
      test(
          'should dispose of the existing subscription when subscribing to a new observable',
          () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
          pipe.transform(emitter);
          var newEmitter = new EventEmitter();
          expect(pipe.transform(newEmitter), isNull);
          // this should not affect the pipe
          emitter.add(message);
          Timer.run(() {
            expect(pipe.transform(newEmitter), isNull);
            completer.done();
          });
        });
      });
      test('should request a change detection check upon receiving a new value',
          () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
          pipe.transform(emitter);
          emitter.add(message);
          new Timer(const Duration(milliseconds: 10), () {
            verify(ref.markForCheck()).called(1);
            completer.done();
          });
        });
      });
    });
    group('ngOnDestroy', () {
      test('should do nothing when no subscription and not throw exception',
          () {
        () => pipe.ngOnDestroy();
      });
      test('should dispose of the existing subscription', () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
          pipe.transform(emitter);
          pipe.ngOnDestroy();
          emitter.add(message);
          Timer.run(() {
            expect(pipe.transform(emitter), isNull);
            completer.done();
          });
        });
      });
    });
  });
  group('Promise', () {
    var message = new Object();
    AsyncPipe pipe;
    Completer completer;
    MockChangeDetectorRef ref;
    // adds longer timers for passing tests in IE
    var timer = (DOM != null && browserDetection.isIE) ? 50 : 10;
    setUp(() {
      completer = new Completer();
      ref = new MockChangeDetectorRef();
      pipe = new AsyncPipe((ref as dynamic));
    });
    group('transform', () {
      test('should return null when subscribing to a promise', () {
        expect(pipe.transform(completer.future), isNull);
      });
      test('should return the latest available value', () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter testCompleter) {
          pipe.transform(completer.future);
          completer.complete(message);
          new Timer(new Duration(milliseconds: timer), () {
            WrappedValue res = pipe.transform(completer.future);
            expect(res.wrapped, message);
            testCompleter.done();
          });
        });
      });
      test(
          'should return unwrapped value when nothing has changed since the last call',
          () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter testCompleter) {
          pipe.transform(completer.future);
          completer.complete(message);
          new Timer(new Duration(milliseconds: timer), () {
            pipe.transform(completer.future);
            expect(pipe.transform(completer.future), message);
            testCompleter.done();
          });
        });
      });
      test(
          'should dispose of the existing subscription when '
          'subscribing to a new promise', () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter testCompleter) {
          pipe.transform(completer.future);
          var newCompleter = new Completer();
          expect(pipe.transform(newCompleter.future), isNull);
          // this should not affect the pipe, so it should return WrappedValue
          completer.complete(message);
          new Timer(new Duration(milliseconds: timer), () {
            expect(pipe.transform(newCompleter.future), isNull);
            testCompleter.done();
          });
        });
      });
      test('should request a change detection check upon receiving a new value',
          () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter testCompleter) {
          pipe.transform(completer.future);
          completer.complete(message);
          new Timer(new Duration(milliseconds: timer), () {
            verify(ref.markForCheck()).called(1);
            testCompleter.done();
          });
        });
      });
      group('ngOnDestroy', () {
        test('should do nothing when no source', () {
          () => pipe.ngOnDestroy();
        });
        test('should dispose of the existing source', () async {
          return inject([AsyncTestCompleter],
              (AsyncTestCompleter testCompleter) {
            pipe.transform(completer.future);
            expect(pipe.transform(completer.future), isNull);
            completer.complete(message);
            new Timer(new Duration(milliseconds: timer), () {
              WrappedValue res = pipe.transform(completer.future);
              expect(res.wrapped, message);
              pipe.ngOnDestroy();
              expect(pipe.transform(completer.future), isNull);
              testCompleter.done();
            });
          });
        });
      });
    });
  });
  group('null', () {
    test('should return null when given null', () {
      var pipe = new AsyncPipe(null);
      expect(pipe.transform(null), isNull);
    });
  });
  group('other types', () {
    test('should throw when given an invalid object', () {
      var pipe = new AsyncPipe(null);
      expect(() => pipe.transform(('some bogus object' as dynamic)), throws);
    });
  });
}
