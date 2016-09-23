library angular2.test.core.change_detection.differs.default_keyvalue_differ_test;

import "package:angular2/src/core/change_detection/differs/default_keyvalue_differ.dart"
    show DefaultKeyValueDiffer;
import 'package:test/test.dart';

// todo(vicb): Update the code & tests for object equality
void main() {
  group("keyvalue differ", () {
    group("DefaultKeyValueDiffer", () {
      var differ;
      Map<dynamic, dynamic> m;
      setUp(() {
        differ = new DefaultKeyValueDiffer();
        m = new Map();
      });
      tearDown(() {
        differ = null;
      });
      test("should detect additions", () {
        differ.check(m);
        m["a"] = 1;
        differ.check(m);
        expect(differ.toString(),
            kvChangesAsString(map: ["a[null->1]"], additions: ["a[null->1]"]));
        m["b"] = 2;
        differ.check(m);
        expect(
            differ.toString(),
            kvChangesAsString(
                map: ["a", "b[null->2]"],
                previous: ["a"],
                additions: ["b[null->2]"]));
      });
      test("should handle changing key/values correctly", () {
        m[1] = 10;
        m[2] = 20;
        differ.check(m);
        m[2] = 10;
        m[1] = 20;
        differ.check(m);
        expect(
            differ.toString(),
            kvChangesAsString(
                map: ["1[10->20]", "2[20->10]"],
                previous: ["1[10->20]", "2[20->10]"],
                changes: ["1[10->20]", "2[20->10]"]));
      });
      test("should expose previous and current value", () {
        var previous, current;
        m[1] = 10;
        differ.check(m);
        m[1] = 20;
        differ.check(m);
        differ.forEachChangedItem((record) {
          previous = record.previousValue;
          current = record.currentValue;
        });
        expect(previous, 10);
        expect(current, 20);
      });
      test("should do basic map watching", () {
        differ.check(m);
        m["a"] = "A";
        differ.check(m);
        expect(differ.toString(),
            kvChangesAsString(map: ["a[null->A]"], additions: ["a[null->A]"]));
        m["b"] = "B";
        differ.check(m);
        expect(
            differ.toString(),
            kvChangesAsString(
                map: ["a", "b[null->B]"],
                previous: ["a"],
                additions: ["b[null->B]"]));
        m["b"] = "BB";
        m["d"] = "D";
        differ.check(m);
        expect(
            differ.toString(),
            kvChangesAsString(
                map: ["a", "b[B->BB]", "d[null->D]"],
                previous: ["a", "b[B->BB]"],
                additions: ["d[null->D]"],
                changes: ["b[B->BB]"]));
        (m.containsKey("b") && (m.remove("b") != null || true));
        differ.check(m);
        expect(
            differ.toString(),
            kvChangesAsString(
                map: ["a", "d"],
                previous: ["a", "b[BB->null]", "d"],
                removals: ["b[BB->null]"]));
        m.clear();
        differ.check(m);
        expect(
            differ.toString(),
            kvChangesAsString(
                previous: ["a[A->null]", "d[D->null]"],
                removals: ["a[A->null]", "d[D->null]"]));
      });
      test("should test string by value rather than by reference (DART)", () {
        m["foo"] = "bar";
        differ.check(m);
        var f = "f";
        var oo = "oo";
        var b = "b";
        var ar = "ar";
        m[f + oo] = b + ar;
        differ.check(m);
        expect(differ.toString(),
            kvChangesAsString(map: ["foo"], previous: ["foo"]));
      });
      test("should not see a NaN value as a change (JS)", () {
        m["foo"] = double.NAN;
        differ.check(m);
        differ.check(m);
        expect(differ.toString(),
            kvChangesAsString(map: ["foo"], previous: ["foo"]));
      }, tags: ['known_ff_failure']);
    });
  });
}

String kvChangesAsString(
    {List<dynamic> map,
    List<dynamic> previous,
    List<dynamic> additions,
    List<dynamic> changes,
    List<dynamic> removals}) {
  map ??= [];
  previous ??= [];
  additions ??= [];
  changes ??= [];
  removals ??= [];
  return "map: " +
      map.join(", ") +
      "\n" +
      "previous: " +
      previous.join(", ") +
      "\n" +
      "additions: " +
      additions.join(", ") +
      "\n" +
      "changes: " +
      changes.join(", ") +
      "\n" +
      "removals: " +
      removals.join(", ") +
      "\n";
}
