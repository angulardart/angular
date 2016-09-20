@TestOn('browser')
library angular2.test.common.pipes.lowercase_pipe_test;

import "package:angular2/common.dart" show LowerCasePipe;
import 'package:test/test.dart';

void main() {
  group("LowerCasePipe", () {
    var upper;
    var lower;
    var pipe;
    setUp(() {
      lower = "something";
      upper = "SOMETHING";
      pipe = new LowerCasePipe();
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
        expect(() => pipe.transform(new Object()), throws);
      });
    });
  });
}
