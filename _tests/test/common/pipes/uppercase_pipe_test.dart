import 'package:test/test.dart';
import 'package:_tests/test_util.dart';
import 'package:angular/src/common/pipes/uppercase_pipe.dart';

void main() {
  group("UpperCasePipe", () {
    var upper;
    var lower;
    var pipe;
    setUp(() {
      lower = "something";
      upper = "SOMETHING";
      pipe = UpperCasePipe();
    });
    group("transform", () {
      test("should return uppercase", () {
        var val = pipe.transform(lower);
        expect(val, upper);
      });
      test("should uppercase when there is a new value", () {
        var val = pipe.transform(lower);
        expect(val, upper);
        var val2 = pipe.transform("wat");
        expect(val2, "WAT");
      });
      test("should not support other objects", () {
        expect(() => pipe.transform(Object()), throwsATypeError);
      });
    });
  });
}
