@TestOn('browser')
library angular2.test.common.pipes.async_pipe_test;

import 'dart:async';

import 'package:angular2/common.dart' show AsyncPipe;
import 'package:angular2/core.dart' show WrappedValue;
import 'package:angular2/src/facade/async.dart'
    show EventEmitter, ObservableWrapper, TimerWrapper;
import 'package:angular2/src/facade/lang.dart' show isBlank;
import 'package:angular2/src/platform/dom/dom_adapter.dart' show DOM;
import 'package:angular2/testing_internal.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../control_mocks.dart';

main() {
  group('AsyncPipe Observable', () {
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
          ObservableWrapper.callEmit(emitter, message);
          TimerWrapper.setTimeout(() {
            WrappedValue res = pipe.transform(emitter);
            expect(res.wrapped, message);
            completer.done();
          }, 0);
        });
      });
      test(
          'should return same value when nothing has changed since the last call',
          () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
          pipe.transform(emitter);
          ObservableWrapper.callEmit(emitter, message);
          TimerWrapper.setTimeout(() {
            pipe.transform(emitter);
            expect(pipe.transform(emitter), message);
            completer.done();
          }, 0);
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
          ObservableWrapper.callEmit(emitter, message);
          TimerWrapper.setTimeout(() {
            expect(pipe.transform(newEmitter), isNull);
            completer.done();
          }, 0);
        });
      });
      test('should request a change detection check upon receiving a new value',
          () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
          pipe.transform(emitter);
          ObservableWrapper.callEmit(emitter, message);
          TimerWrapper.setTimeout(() {
            verify(ref.markForCheck()).called(1);
            completer.done();
          }, 10);
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
          ObservableWrapper.callEmit(emitter, message);
          TimerWrapper.setTimeout(() {
            expect(pipe.transform(emitter), isNull);
            completer.done();
          }, 0);
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
    var timer = (!isBlank(DOM) && browserDetection.isIE) ? 50 : 10;
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
          TimerWrapper.setTimeout(() {
            WrappedValue res = pipe.transform(completer.future);
            expect(res.wrapped, message);
            testCompleter.done();
          }, timer);
        });
      });
      test(
          'should return unwrapped value when nothing has changed since the last call',
          () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter testCompleter) {
          pipe.transform(completer.future);
          completer.complete(message);
          TimerWrapper.setTimeout(() {
            pipe.transform(completer.future);
            expect(pipe.transform(completer.future), message);
            testCompleter.done();
          }, timer);
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
          TimerWrapper.setTimeout(() {
            expect(pipe.transform(newCompleter.future), isNull);
            testCompleter.done();
          }, timer);
        });
      });
      test('should request a change detection check upon receiving a new value',
          () async {
        return inject([AsyncTestCompleter], (AsyncTestCompleter testCompleter) {
          pipe.transform(completer.future);
          completer.complete(message);
          TimerWrapper.setTimeout(() {
            verify(ref.markForCheck()).called(1);
            testCompleter.done();
          }, timer);
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
            TimerWrapper.setTimeout(() {
              WrappedValue res = pipe.transform(completer.future);
              expect(res.wrapped, message);
              pipe.ngOnDestroy();
              expect(pipe.transform(completer.future), isNull);
              testCompleter.done();
            }, timer);
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
