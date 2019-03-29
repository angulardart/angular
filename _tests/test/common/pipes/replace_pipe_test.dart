import 'package:test/test.dart';
import 'package:angular/src/common/pipes/invalid_pipe_argument_exception.dart';
import 'package:angular/src/common/pipes/replace_pipe.dart';

final someNumber = 42;
final str = "Douglas Adams";

final Matcher throwsAnInvalidPipeArgumentException =
    throwsA(TypeMatcher<InvalidPipeArgumentException>());

void main() {
  group("ReplacePipe", () {
    var pipe = const ReplacePipe();
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
        var result2 = pipe.transform(str, RegExp("a"), "_");
        var result3 =
            pipe.transform(str, RegExp("a", caseSensitive: false), "_");
        var f = (x) {
          return "Adams!";
        };
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
