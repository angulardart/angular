import 'package:test/test.dart';
import 'package:_tests/test_util.dart';
import 'package:angular/src/common/pipes/lowercase_pipe.dart';

void main() {
  group("LowerCasePipe", () {
    var upper;
    var lower;
    var pipe;
    setUp(() {
      lower = "something";
      upper = "SOMETHING";
      pipe = LowerCasePipe();
    });
    group("transform", () {
      test("should return lowercase", () {
        var val = pipe.transform(upper);
        expect(val, lower);
      });
      test("should lowercase when there is a new value", () {
        var val = pipe.transform(upper);
        expect(val, lower);
        var val2 = pipe.transform("WAT");
        expect(val2, "wat");
      });
      test("should not support other objects", () {
        expect(() => pipe.transform(Object()), throwsATypeError);
      });
    });
  });
}
