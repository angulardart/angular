@TestOn('browser')

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/common/pipes/invalid_pipe_argument_exception.dart';

void main() {
  group('Stream', () {
    StreamController emitter;
    AsyncPipe pipe;
    ChangeDetectorRef ref;
    var message = Object();
    setUp(() {
      emitter = StreamController.broadcast();
      ref = MockChangeDetectorRef();
      pipe = AsyncPipe(ref);
    });
    group('transform', () {
      test('should return null when subscribing to an observable', () {
        expect(pipe.transform(emitter.stream), isNull);
      });
      test('should return the latest available value', () async {
        pipe.transform(emitter.stream);
        emitter.add(message);
        Timer.run(expectAsync0(() {
          final res = pipe.transform(emitter.stream);
          expect(res, message);
        }));
      });
      test(
          'should return same value when nothing has changed '
          'since the last call', () async {
        pipe.transform(emitter.stream);
        emitter.add(message);
        Timer.run(expectAsync0(() {
          pipe.transform(emitter.stream);
          expect(pipe.transform(emitter.stream), message);
        }));
      });
      test(
          'should dispose of the existing subscription when '
          'subscribing to a new observable', () async {
        pipe.transform(emitter.stream);
        var newEmitter = StreamController.broadcast();
        expect(pipe.transform(newEmitter.stream), isNull);
        // this should not affect the pipe
        emitter.add(message);
        Timer.run(expectAsync0(() {
          expect(pipe.transform(newEmitter.stream), isNull);
        }));
      });
      test('should not dispose of existing subscription when Streams are equal',
          () async {
        // See https://github.com/dart-lang/angular2/issues/260
        StreamController _ctrl = StreamController.broadcast();
        expect(pipe.transform(_ctrl.stream), isNull);
        _ctrl.add(message);
        Timer.run(expectAsync0(() {
          expect(pipe.transform(_ctrl.stream), isNotNull);
        }));
      });
      test('should request a change detection check upon receiving a new value',
          () async {
        pipe.transform(emitter.stream);
        emitter.add(message);
        Timer(const Duration(milliseconds: 10), expectAsync0(() {
          verify(ref.markForCheck()).called(1);
        }));
      });
    });
    group('ngOnDestroy', () {
      test('should do nothing when no subscription and not throw exception',
          () {
        pipe.ngOnDestroy();
      });
      test('should dispose of the existing subscription', () async {
        pipe.transform(emitter.stream);
        pipe.ngOnDestroy();
        emitter.add(message);
        Timer.run(expectAsync0(() {
          expect(pipe.transform(emitter.stream), isNull);
        }));
      });
    });
  });
  group('Future', () {
    var message = Object();
    AsyncPipe pipe;
    Completer completer;
    MockChangeDetectorRef ref;
    var timer = 10;
    setUp(() {
      completer = Completer();
      ref = MockChangeDetectorRef();
      pipe = AsyncPipe(ref as dynamic);
    });
    group('transform', () {
      test('should return null when subscribing to a promise', () {
        expect(pipe.transform(completer.future), isNull);
      });
      test('should return the latest available value', () async {
        pipe.transform(completer.future);
        completer.complete(message);
        Timer(Duration(milliseconds: timer), expectAsync0(() {
          final res = pipe.transform(completer.future);
          expect(res, message);
        }));
      });
      test(
          'should return unwrapped value when nothing has '
          'changed since the last call', () async {
        pipe.transform(completer.future);
        completer.complete(message);
        Timer(Duration(milliseconds: timer), expectAsync0(() {
          pipe.transform(completer.future);
          expect(pipe.transform(completer.future), message);
        }));
      });
      test(
          'should dispose of the existing subscription when '
          'subscribing to a new promise', () async {
        pipe.transform(completer.future);
        var newCompleter = Completer();
        expect(pipe.transform(newCompleter.future), isNull);
        // this should not affect the pipe, so it should return WrappedValue
        completer.complete(message);
        Timer(Duration(milliseconds: timer), expectAsync0(() {
          expect(pipe.transform(newCompleter.future), isNull);
        }));
      });
      test('should request a change detection check upon receiving a new value',
          () async {
        pipe.transform(completer.future);
        completer.complete(message);
        Timer(Duration(milliseconds: timer), expectAsync0(() {
          verify(ref.markForCheck()).called(1);
        }));
      });
      group('ngOnDestroy', () {
        test('should do nothing when no source', () {
          () => pipe.ngOnDestroy();
        });
        test('should dispose of the existing source', () async {
          pipe.transform(completer.future);
          expect(pipe.transform(completer.future), isNull);
          completer.complete(message);
          Timer(Duration(milliseconds: timer), expectAsync0(() {
            final res = pipe.transform(completer.future);
            expect(res, message);
            pipe.ngOnDestroy();
            expect(pipe.transform(completer.future), isNull);
          }));
        });
      });
    });
  });
  group('null', () {
    test('should return null when given null', () {
      var pipe = AsyncPipe(null);
      expect(pipe.transform(null), isNull);
    });
  });
  group('other types', () {
    test('should throw when given an invalid object', () {
      var pipe = AsyncPipe(null);
      expect(() => pipe.transform('some bogus object'),
          throwsA(TypeMatcher<InvalidPipeArgumentException>()));
    });
  });
}

class MockChangeDetectorRef extends Mock implements ChangeDetectorRef {}
