@TestOn('browser')
library angular2.test.common.pipes.uppercase_pipe_test;

import "package:angular2/common.dart" show UpperCasePipe;
import 'package:test/test.dart';

void main() {
  group("UpperCasePipe", () {
    var upper;
    var lower;
    var pipe;
    setUp(() {
      lower = "something";
      upper = "SOMETHING";
      pipe = new UpperCasePipe();
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
        expect(() => pipe.transform(new Object()), throws);
      });
    });
  });
}
