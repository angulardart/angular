@TestOn('browser')
library angular2.test.common.pipes.date_pipe_test;

import 'package:angular2/common.dart' show DatePipe;
import 'package:angular2/src/compiler/pipe_resolver.dart' show PipeResolver;
import 'package:angular2/src/facade/lang.dart' show DateWrapper;
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

main() {
  group('DatePipe', () {
    var date;
    var pipe;
    setUp(() {
      date = DateWrapper.create(2015, 6, 15, 21, 43, 11);
      pipe = new DatePipe();
    });
    test('should be marked as pure', () async {
      return inject([], () {
        expect(new PipeResolver().resolve(DatePipe).pure, isTrue);
      });
    });
    group('supports', () {
      test('should support date', () {
        expect(pipe.supports(date), isTrue);
      });
      test('should support int', () {
        expect(pipe.supports(123456789), isTrue);
      });
      test('should not support other objects', () {
        expect(pipe.supports(new Object()), isFalse);
        expect(pipe.supports(null), isFalse);
      });
    });
    group('transform', () {
      test('should format each component correctly', () {
        expect(pipe.transform(date, 'y'), '2015');
        expect(pipe.transform(date, 'yy'), '15');
        expect(pipe.transform(date, 'M'), '6');
        expect(pipe.transform(date, 'MM'), '06');
        expect(pipe.transform(date, 'MMM'), 'Jun');
        expect(pipe.transform(date, 'MMMM'), 'June');
        expect(pipe.transform(date, 'd'), '15');
        expect(pipe.transform(date, 'E'), 'Mon');
        expect(pipe.transform(date, 'EEEE'), 'Monday');
        expect(pipe.transform(date, 'H'), '21');
        expect(pipe.transform(date, 'j'), '9 PM');
        expect(pipe.transform(date, 'm'), '43');
        expect(pipe.transform(date, 's'), '11');
      });
      test('should format common multi component patterns', () {
        expect(pipe.transform(date, 'yMEd'), 'Mon, 6/15/2015');
        expect(pipe.transform(date, 'MEd'), 'Mon, 6/15');
        expect(pipe.transform(date, 'MMMd'), 'Jun 15');
        expect(pipe.transform(date, 'yMMMMEEEEd'), 'Monday, June 15, 2015');
        expect(pipe.transform(date, 'jms'), '9:43:11 PM');
        expect(pipe.transform(date, 'ms'), '43:11');
      });
      test('should format with pattern aliases', () {
        expect(pipe.transform(date, 'medium'), 'Jun 15, 2015, 9:43:11 PM');
        expect(pipe.transform(date, 'short'), '6/15/2015, 9:43 PM');
        expect(pipe.transform(date, 'fullDate'), 'Monday, June 15, 2015');
        expect(pipe.transform(date, 'longDate'), 'June 15, 2015');
        expect(pipe.transform(date, 'mediumDate'), 'Jun 15, 2015');
        expect(pipe.transform(date, 'shortDate'), '6/15/2015');
        expect(pipe.transform(date, 'mediumTime'), '9:43:11 PM');
        expect(pipe.transform(date, 'shortTime'), '9:43 PM');
      });
    });
  });
}
