library angular2.test.core.change_detection.change_detector_util_test;

import "package:angular2/src/core/change_detection/change_detection_util.dart"
    show devModeEqual;
import 'package:test/test.dart';

void main() {
  group("ChangeDetectionUtil", () {
    group("devModeEqual", () {
      test("should do the deep comparison of iterables", () {
        expect(
            devModeEqual([
              ["one"]
            ], [
              ["one"]
            ]),
            isTrue);
        expect(devModeEqual(["one"], ["one", "two"]), isFalse);
        expect(devModeEqual(["one", "two"], ["one"]), isFalse);
        expect(devModeEqual(["one"], "one"), isFalse);
        expect(devModeEqual(["one"], new Object()), isFalse);
        expect(devModeEqual("one", ["one"]), isFalse);
        expect(devModeEqual(new Object(), ["one"]), isFalse);
      });
      test("should compare primitive numbers", () {
        expect(devModeEqual(1, 1), isTrue);
        expect(devModeEqual(1, 2), isFalse);
        expect(devModeEqual(new Object(), 2), isFalse);
        expect(devModeEqual(1, new Object()), isFalse);
      });
      test("should compare primitive strings", () {
        expect(devModeEqual("one", "one"), isTrue);
        expect(devModeEqual("one", "two"), isFalse);
        expect(devModeEqual(new Object(), "one"), isFalse);
        expect(devModeEqual("one", new Object()), isFalse);
      });
      test("should compare primitive booleans", () {
        expect(devModeEqual(true, true), isTrue);
        expect(devModeEqual(true, false), isFalse);
        expect(devModeEqual(new Object(), true), isFalse);
        expect(devModeEqual(true, new Object()), isFalse);
      });
      test("should compare null", () {
        expect(devModeEqual(null, null), isTrue);
        expect(devModeEqual(null, 1), isFalse);
        expect(devModeEqual(new Object(), null), isFalse);
        expect(devModeEqual(null, new Object()), isFalse);
      });
      test("should return true for other objects", () {
        expect(devModeEqual(new Object(), new Object()), isTrue);
      });
    });
  });
}
