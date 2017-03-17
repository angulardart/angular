@TestOn('browser')
library angular2.test.common.pipes.replace_pipe_test;

import "package:angular2/angular2.dart" show ReplacePipe;
import 'package:test/test.dart';

import '../../test_util.dart';

void main() {
  group("ReplacePipe", () {
    num someNumber;
    var str;
    var pipe;
    setUp(() {
      someNumber = 42;
      str = "Douglas Adams";
      pipe = new ReplacePipe();
    });
    group("transform", () {
      test("should not support input other than strings and numbers", () {
        expect(() => pipe.transform({}, "Douglas", "Hugh"),
            throwsAnInvalidPipeArgumentException);
        expect(() => pipe.transform([1, 2, 3], "Douglas", "Hugh"),
            throwsAnInvalidPipeArgumentException);
      });
      test(
          "should not support patterns other than strings and regular expressions",
          () {
        expect(() => pipe.transform(str, {}, "Hugh"),
            throwsAnInvalidPipeArgumentException);
        expect(() => pipe.transform(str, null, "Hugh"),
            throwsAnInvalidPipeArgumentException);
        expect(() => pipe.transform(str, 123, "Hugh"),
            throwsAnInvalidPipeArgumentException);
      });
      test("should not support replacements other than strings and functions",
          () {
        expect(() => pipe.transform(str, "Douglas", {}),
            throwsAnInvalidPipeArgumentException);
        expect(() => pipe.transform(str, "Douglas", null),
            throwsAnInvalidPipeArgumentException);
        expect(() => pipe.transform(str, "Douglas", 123),
            throwsAnInvalidPipeArgumentException);
      });
      test("should return a new string with the pattern replaced", () {
        var result1 = pipe.transform(str, "Douglas", "Hugh");
        var result2 = pipe.transform(str, new RegExp("a"), "_");
        var result3 =
            pipe.transform(str, new RegExp("a", caseSensitive: false), "_");
        var f = ((x) {
          return "Adams!";
        });
        var result4 = pipe.transform(str, "Adams", f);
        var result5 = pipe.transform(someNumber, "2", "4");
        expect(result1, "Hugh Adams");
        expect(result2, "Dougl_s Ad_ms");
        expect(result3, "Dougl_s _d_ms");
        expect(result4, "Douglas Adams!");
        expect(result5, "44");
      });
    });
  });
}
