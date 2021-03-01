import 'package:test/test.dart';
import 'package:angular/src/common/pipes/lowercase_pipe.dart';

void main() {
  group('LowerCasePipe', () {
    late String upper;
    late String lower;
    late LowerCasePipe pipe;
    setUp(() {
      lower = 'something';
      upper = 'SOMETHING';
      pipe = LowerCasePipe();
    });
    group('transform', () {
      test('should return lowercase', () {
        var val = pipe.transform(upper);
        expect(val, lower);
      });
      test('should lowercase when there is a new value', () {
        var val = pipe.transform(upper);
        expect(val, lower);
        var val2 = pipe.transform('WAT');
        expect(val2, 'wat');
      });
    });
  });
}
