@TestOn('browser')

import 'package:test/test.dart';
import 'package:angular/angular.dart';

void main() {
  group('DatePipe', () {
    DateTime date;
    DatePipe pipe;
    setUp(() {
      date = DateTime(2015, 6, 15, 21, 43, 11);
      pipe = DatePipe();
    });
    group('supports', () {
      test('should support date', () {
        expect(pipe.supports(date), true);
      });
      test('should support int', () {
        expect(pipe.supports(123456789), true);
      });
      test('should not support other objects', () {
        expect(pipe.supports(Object()), false);
        expect(pipe.supports(null), false);
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
      test('should format millis in local timezone', () {
        int millis = date.millisecondsSinceEpoch;
        expect(pipe.transform(millis, 'y'), '2015');
        expect(pipe.transform(millis, 'yy'), '15');
        expect(pipe.transform(millis, 'M'), '6');
        expect(pipe.transform(millis, 'MM'), '06');
        expect(pipe.transform(millis, 'MMM'), 'Jun');
        expect(pipe.transform(millis, 'MMMM'), 'June');
        expect(pipe.transform(millis, 'd'), '15');
        expect(pipe.transform(millis, 'E'), 'Mon');
        expect(pipe.transform(millis, 'EEEE'), 'Monday');
        expect(pipe.transform(millis, 'H'), '21');
        expect(pipe.transform(millis, 'j'), '9 PM');
        expect(pipe.transform(millis, 'm'), '43');
        expect(pipe.transform(millis, 's'), '11');
      });
    });
  });
}
