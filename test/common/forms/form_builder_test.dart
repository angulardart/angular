@TestOn('browser')
library angular2.test.common.forms.form_builder_test;

import 'dart:async';

import "package:angular2/common.dart" show FormBuilder, AbstractControl;
import 'package:test/test.dart';

Map<String, dynamic> _syncValidator(AbstractControl c) {
  return null;
}

dynamic _asyncValidator(AbstractControl c) => new Future.value(null);

void main() {
  var syncValidator = _syncValidator;
  var asyncValidator = _asyncValidator;

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
        "password": ["some value", syncValidator, asyncValidator]
      });
      expect(g.controls["login"].value, "some value");
      expect(g.controls["password"].value, "some value");
      expect(g.controls["password"].validator == syncValidator, isTrue);
      expect(g.controls["password"].asyncValidator == asyncValidator, isTrue);
    });
    test("should use controls", () {
      var g = b.group(
          {"login": b.control("some value", syncValidator, asyncValidator)});
      expect(g.controls["login"].value, "some value");
      expect(g.controls["login"].validator == syncValidator, isTrue);
      expect(g.controls["login"].asyncValidator == asyncValidator, isTrue);
    });
    test("should create groups with optional controls", () {
      var g = b.group({
        "login": "some value"
      }, {
        "optionals": {"login": false}
      });
      expect(g.contains("login"), isFalse);
    });
    test("should create groups with a custom validator", () {
      var g = b.group({"login": "some value"},
          {"validator": syncValidator, "asyncValidator": asyncValidator});
      expect(g.validator == syncValidator, isTrue);
      expect(g.asyncValidator == asyncValidator, isTrue);
    });
    test("should create control arrays", () {
      var c = b.control("three");
      var a = b.array([
        "one",
        ["two", syncValidator],
        c,
        b.array(["four"])
      ], syncValidator, asyncValidator);
      expect(a.value, [
        "one",
        "two",
        "three",
        ["four"]
      ]);
      expect(a.validator == syncValidator, isTrue);
      expect(a.asyncValidator == asyncValidator, isTrue);
    });
  });
}
