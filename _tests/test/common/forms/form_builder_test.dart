@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular_forms/angular_forms.dart';

Map<String, dynamic> _syncValidator(AbstractControl c) {
  return null;
}

void main() {
  var syncValidator = _syncValidator;

  group("Form Builder", () {
    var b;
    setUp(() {
      b = new FormBuilder();
    });
    test("should create controls from a value", () {
      var g = b.group({"login": "some value"});
      expect(g.controls["login"].value, "some value");
    });
    test("should create controls from an array", () {
      var g = b.group({
        "login": ["some value"],
        "password": ["some value", syncValidator]
      });
      expect(g.controls["login"].value, "some value");
      expect(g.controls["password"].value, "some value");
      expect(g.controls["password"].validator == syncValidator, true);
    });
    test("should use controls", () {
      var g = b.group({"login": b.control("some value", syncValidator)});
      expect(g.controls["login"].value, "some value");
      expect(g.controls["login"].validator == syncValidator, true);
    });
    test("should create groups with optional controls", () {
      var g = b.group({
        "login": "some value"
      }, {
        "optionals": {"login": false}
      });
      expect(g.contains("login"), false);
    });
    test("should create groups with a custom validator", () {
      var g = b.group({"login": "some value"}, {"validator": syncValidator});
      expect(g.validator == syncValidator, true);
    });
    test("should create control arrays", () {
      var c = b.control("three");
      var a = b.array([
        "one",
        ["two", syncValidator],
        c,
        b.array(["four"])
      ], syncValidator);
      expect(a.value, [
        "one",
        "two",
        "three",
        ["four"]
      ]);
      expect(a.validator == syncValidator, true);
    });
  });
}
