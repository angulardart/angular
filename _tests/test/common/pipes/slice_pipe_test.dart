@TestOn('browser')
import 'package:test/test.dart';
import 'package:_tests/matchers.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'slice_pipe_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('SlicePipe', () {
    List<num> list;
    var str;
    var pipe;
    setUp(() {
      list = [1, 2, 3, 4, 5];
      str = 'tuvwxyz';
      pipe = SlicePipe();
    });
    group('supports', () {
      test('should support strings', () {
        expect(pipe.supports(str), true);
      });
      test('should support lists', () {
        expect(pipe.supports(list), true);
      });
      test('should not support other objects', () {
        expect(pipe.supports(Object()), false);
        expect(pipe.supports(null), false);
      });
    });
    group('transform', () {
      test(
          'should return all items after START index when START'
          ' is positive and END is omitted', () {
        expect(pipe.transform(list, 3), [4, 5]);
        expect(pipe.transform(str, 3), 'wxyz');
      });
      test(
          'should return last START items when START '
          'is negative and END is omitted', () {
        expect(pipe.transform(list, -3), [3, 4, 5]);
        expect(pipe.transform(str, -3), 'xyz');
      });
      test(
          'should return all items between START and '
          'END index when START and END are positive', () {
        expect(pipe.transform(list, 1, 3), [2, 3]);
        expect(pipe.transform(str, 1, 3), 'uv');
      });
      test(
          'should return all items between START and '
          'END from the end when START and END are negative', () {
        expect(pipe.transform(list, -4, -2), [2, 3]);
        expect(pipe.transform(str, -4, -2), 'wx');
      });
      test('should return an empty value if START is greater than END', () {
        expect(pipe.transform(list, 4, 2), []);
        expect(pipe.transform(str, 4, 2), '');
      });
      test('should return an empty value if START greater than input length',
          () {
        expect(pipe.transform(list, 99), []);
        expect(pipe.transform(str, 99), '');
      });

      test(
          'should return entire input if START is negative '
          'and greater than input length', () {
        expect(pipe.transform(list, -99), [1, 2, 3, 4, 5]);
        expect(pipe.transform(str, -99), 'tuvwxyz');
      });
      test('should not modify the input list', () {
        expect(pipe.transform(list, 2), [3, 4, 5]);
        expect(list, [1, 2, 3, 4, 5]);
      });
    });
    group('integration', () {
      test('should work with mutable arrays', () async {
        var testBed = NgTestBed<TestComp>();
        var testFixture = await testBed.create();
        var el = testFixture.rootElement;
        List<num> mutable = [1, 2];
        await testFixture.update((TestComp comp) {
          comp.data = mutable;
        });
        expect(el, hasTextContent('2'));
        await testFixture.update((TestComp comp) {
          mutable.add(3);
        });
        expect(el, hasTextContent('2,3'));
      });
    });
  });
}

@Component(
  selector: 'test-comp',
  template: '{{(data | slice:1).join(\',\') }}',
  pipes: [SlicePipe],
)
class TestComp {
  dynamic data = [];
}
