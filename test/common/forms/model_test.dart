@TestOn('browser')
library angular2.test.common.forms.model_spec;

import "package:angular2/common.dart"
    show ControlGroup, Control, ControlArray, Validators;
import "package:angular2/src/facade/async.dart"
    show TimerWrapper, ObservableWrapper, EventEmitter;
import "package:angular2/src/facade/lang.dart" show IS_DART, isPresent;
import "package:angular2/src/facade/promise.dart" show PromiseWrapper;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

main() {
  var asyncValidator = (expected, [timeouts = const {}]) {
    return (c) {
      var completer = PromiseWrapper.completer();
      var t = isPresent(timeouts[c.value]) ? timeouts[c.value] : 0;
      var res = c.value != expected ? {"async": true} : null;
      if (t == 0) {
        completer.resolve(res);
      } else {
        TimerWrapper.setTimeout(() {
          completer.resolve(res);
        }, t);
      }
      return completer.promise;
    };
  };

  var asyncValidatorReturningObservable = (c) {
    var e = new EventEmitter();
    PromiseWrapper.scheduleMicrotask(
        () => ObservableWrapper.callEmit(e, {"async": true}));
    return e;
  };

  group("Form Model", () {
    group("Control", () {
      test("should default the value to null", () {
        var c = new Control();
        expect(c.value, isNull);
      });
      group("validator", () {
        test("should run validator with the initial value", () {
          var c = new Control("value", Validators.required);
          expect(c.valid, isTrue);
        });
        test("should rerun the validator when the value changes", () {
          var c = new Control("value", Validators.required);
          c.updateValue(null);
          expect(c.valid, isFalse);
        });
        test("should return errors", () {
          var c = new Control(null, Validators.required);
          expect(c.errors, {"required": true});
        });
      });
      group("asyncValidator", () {
        test("should run validator with the initial value", fakeAsync(() {
          var c = new Control("value", null, asyncValidator("expected"));
          tick();
          expect(c.valid, isFalse);
          expect(c.errors, {"async": true});
        }));
        test("should support validators returning observables", fakeAsync(() {
          var c = new Control("value", null, asyncValidatorReturningObservable);
          tick();
          expect(c.valid, isFalse);
          expect(c.errors, {"async": true});
        }));
        test("should rerun the validator when the value changes", fakeAsync(() {
          var c = new Control("value", null, asyncValidator("expected"));
          c.updateValue("expected");
          tick();
          expect(c.valid, isTrue);
        }));
        test(
            "should run the async validator only when the sync validator passes",
            fakeAsync(() {
          var c =
              new Control("", Validators.required, asyncValidator("expected"));
          tick();
          expect(c.errors, {"required": true});
          c.updateValue("some value");
          tick();
          expect(c.errors, {"async": true});
        }));
        test(
            "should mark the control as pending while running the async validation",
            fakeAsync(() {
          var c = new Control("", null, asyncValidator("expected"));
          expect(c.pending, isTrue);
          tick();
          expect(c.pending, isFalse);
        }));
        test("should only use the latest async validation run", fakeAsync(() {
          var c = new Control("", null,
              asyncValidator("expected", {"long": 200, "expected": 100}));
          c.updateValue("long");
          c.updateValue("expected");
          tick(300);
          expect(c.valid, isTrue);
        }));
      });
      group("dirty", () {
        test("should be false after creating a control", () {
          var c = new Control("value");
          expect(c.dirty, isFalse);
        });
        test("should be true after changing the value of the control", () {
          var c = new Control("value");
          c.markAsDirty();
          expect(c.dirty, isTrue);
        });
      });
      group("updateValue", () {
        var g, c;
        setUp(() {
          c = new Control("oldValue");
          g = new ControlGroup({"one": c});
        });
        test("should update the value of the control", () {
          c.updateValue("newValue");
          expect(c.value, "newValue");
        });
        test("should invoke ngOnChanges if it is present", () {
          var ngOnChanges;
          c.registerOnChange((v) => ngOnChanges = ["invoked", v]);
          c.updateValue("newValue");
          expect(ngOnChanges, ["invoked", "newValue"]);
        });
        test("should not invoke on change when explicitly specified", () {
          var onChange = null;
          c.registerOnChange((v) => onChange = ["invoked", v]);
          c.updateValue("newValue", emitModelToViewChange: false);
          expect(onChange, isNull);
        });
        test("should update the parent", () {
          c.updateValue("newValue");
          expect(g.value, {"one": "newValue"});
        });
        test("should not update the parent when explicitly specified", () {
          c.updateValue("newValue", onlySelf: true);
          expect(g.value, {"one": "oldValue"});
        });
        test("should fire an event", fakeAsync(() {
          ObservableWrapper.subscribe(c.valueChanges, (value) {
            expect(value, "newValue");
          });
          c.updateValue("newValue");
          tick();
        }));
        test("should not fire an event when explicitly specified",
            fakeAsync(() {
          ObservableWrapper.subscribe(c.valueChanges, (value) {
            throw "Should not happen";
          });
          c.updateValue("newValue", emitEvent: false);
          tick();
        }));
      });
      group("valueChanges & statusChanges", () {
        var c;
        setUp(() {
          c = new Control("old", Validators.required);
        });
        test("should fire an event after the value has been updated", () async {
          return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
            ObservableWrapper.subscribe(c.valueChanges, (value) {
              expect(c.value, "new");
              expect(value, "new");
              completer.done();
            });
            c.updateValue("new");
          });
        });
        test(
            "should fire an event after the status has been updated to invalid",
            fakeAsync(() {
          ObservableWrapper.subscribe(c.statusChanges, (status) {
            expect(c.status, "INVALID");
            expect(status, "INVALID");
          });
          c.updateValue("");
          tick();
        }));
        test(
            "should fire an event after the status has been updated to pending",
            fakeAsync(() {
          var c = new Control(
              "old", Validators.required, asyncValidator("expected"));
          var log = [];
          ObservableWrapper.subscribe(
              c.valueChanges, (value) => log.add('''value: \'${ value}\''''));
          ObservableWrapper.subscribe(c.statusChanges,
              (status) => log.add('''status: \'${ status}\''''));
          c.updateValue("");
          tick();
          c.updateValue("nonEmpty");
          tick();
          c.updateValue("expected");
          tick();
          expect(log, [
            "" + "value: ''",
            "status: 'INVALID'",
            "value: 'nonEmpty'",
            "status: 'PENDING'",
            "status: 'INVALID'",
            "value: 'expected'",
            "status: 'PENDING'",
            "status: 'VALID'"
          ]);
        }));
        // TODO: remove the if statement after making observable delivery sync
        if (!IS_DART) {
          test("should update set errors and status before emitting an event",
              () async {
            return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
              c.valueChanges.subscribe((value) {
                expect(c.valid, isFalse);
                expect(c.errors, {"required": true});
                completer.done();
              });
              c.updateValue("");
            });
          });
        }
        test("should return a cold observable", () async {
          return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
            c.updateValue("will be ignored");
            ObservableWrapper.subscribe(c.valueChanges, (value) {
              expect(value, "new");
              completer.done();
            });
            c.updateValue("new");
          });
        });
      });
      group("setErrors", () {
        test("should set errors on a control", () {
          var c = new Control("someValue");
          c.setErrors({"someError": true});
          expect(c.valid, isFalse);
          expect(c.errors, {"someError": true});
        });
        test("should reset the errors and validity when the value changes", () {
          var c = new Control("someValue", Validators.required);
          c.setErrors({"someError": true});
          c.updateValue("");
          expect(c.errors, {"required": true});
        });
        test("should update the parent group's validity", () {
          var c = new Control("someValue");
          var g = new ControlGroup({"one": c});
          expect(g.valid, isTrue);
          c.setErrors({"someError": true});
          expect(g.valid, isFalse);
        });
        test("should not reset parent's errors", () {
          var c = new Control("someValue");
          var g = new ControlGroup({"one": c});
          g.setErrors({"someGroupError": true});
          c.setErrors({"someError": true});
          expect(g.errors, {"someGroupError": true});
        });
        test("should reset errors when updating a value", () {
          var c = new Control("oldValue");
          var g = new ControlGroup({"one": c});
          g.setErrors({"someGroupError": true});
          c.setErrors({"someError": true});
          c.updateValue("newValue");
          expect(c.errors, isNull);
          expect(g.errors, isNull);
        });
      });
    });
    group("ControlGroup", () {
      group("value", () {
        test("should be the reduced value of the child controls", () {
          var g = new ControlGroup(
              {"one": new Control("111"), "two": new Control("222")});
          expect(g.value, {"one": "111", "two": "222"});
        });
        test("should be empty when there are no child controls", () {
          var g = new ControlGroup({});
          expect(g.value, {});
        });
        test("should support nested groups", () {
          var g = new ControlGroup({
            "one": new Control("111"),
            "nested": new ControlGroup({"two": new Control("222")})
          });
          expect(g.value, {
            "one": "111",
            "nested": {"two": "222"}
          });
          (((g.controls["nested"].find("two")) as Control)).updateValue("333");
          expect(g.value, {
            "one": "111",
            "nested": {"two": "333"}
          });
        });
      });
      group("errors", () {
        test("should run the validator when the value changes", () {
          var simpleValidator = (c) =>
              c.controls["one"].value != "correct" ? {"broken": true} : null;
          var c = new Control(null);
          var g = new ControlGroup({"one": c}, null, simpleValidator);
          c.updateValue("correct");
          expect(g.valid, isTrue);
          expect(g.errors, null);
          c.updateValue("incorrect");
          expect(g.valid, isFalse);
          expect(g.errors, {"broken": true});
        });
      });
      group("dirty", () {
        var c, g;
        setUp(() {
          c = new Control("value");
          g = new ControlGroup({"one": c});
        });
        test("should be false after creating a control", () {
          expect(g.dirty, isFalse);
        });
        test("should be false after changing the value of the control", () {
          c.markAsDirty();
          expect(g.dirty, isTrue);
        });
      });
      group("optional components", () {
        group("contains", () {
          var group;
          setUp(() {
            group = new ControlGroup({
              "required": new Control("requiredValue"),
              "optional": new Control("optionalValue")
            }, {
              "optional": false
            });
          });
          // rename contains into has
          test("should return false when the component is not included", () {
            expect(group.contains("optional"), isFalse);
          });
          test(
              "should return false when there is no component with the given name",
              () {
            expect(group.contains("something else"), isFalse);
          });
          test("should return true when the component is included", () {
            expect(group.contains("required"), isTrue);
            group.include("optional");
            expect(group.contains("optional"), isTrue);
          });
        });
        test("should not include an inactive component into the group value",
            () {
          var group = new ControlGroup({
            "required": new Control("requiredValue"),
            "optional": new Control("optionalValue")
          }, {
            "optional": false
          });
          expect(group.value, {"required": "requiredValue"});
          group.include("optional");
          expect(group.value,
              {"required": "requiredValue", "optional": "optionalValue"});
        });
        test("should not run Validators on an inactive component", () {
          var group = new ControlGroup({
            "required": new Control("requiredValue", Validators.required),
            "optional": new Control("", Validators.required)
          }, {
            "optional": false
          });
          expect(group.valid, isTrue);
          group.include("optional");
          expect(group.valid, isFalse);
        });
      });
      group("valueChanges", () {
        var g, c1, c2;
        setUp(() {
          c1 = new Control("old1");
          c2 = new Control("old2");
          g = new ControlGroup({"one": c1, "two": c2}, {"two": true});
        });
        test("should fire an event after the value has been updated", () async {
          return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
            ObservableWrapper.subscribe(g.valueChanges, (value) {
              expect(g.value, {"one": "new1", "two": "old2"});
              expect(value, {"one": "new1", "two": "old2"});
              completer.done();
            });
            c1.updateValue("new1");
          });
        });
        test(
            "should fire an event after the control's observable fired an event",
            () async {
          return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
            var controlCallbackIsCalled = false;
            ObservableWrapper.subscribe(c1.valueChanges, (value) {
              controlCallbackIsCalled = true;
            });
            ObservableWrapper.subscribe(g.valueChanges, (value) {
              expect(controlCallbackIsCalled, isTrue);
              completer.done();
            });
            c1.updateValue("new1");
          });
        });
        test("should fire an event when a control is excluded", () async {
          return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
            ObservableWrapper.subscribe(g.valueChanges, (value) {
              expect(value, {"one": "old1"});
              completer.done();
            });
            g.exclude("two");
          });
        });
        test("should fire an event when a control is included", () async {
          return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
            g.exclude("two");
            ObservableWrapper.subscribe(g.valueChanges, (value) {
              expect(value, {"one": "old1", "two": "old2"});
              completer.done();
            });
            g.include("two");
          });
        });
        test("should fire an event every time a control is updated", () async {
          return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
            var loggedValues = [];
            ObservableWrapper.subscribe(g.valueChanges, (value) {
              loggedValues.add(value);
              if (loggedValues.length == 2) {
                expect(loggedValues, [
                  {"one": "new1", "two": "old2"},
                  {"one": "new1", "two": "new2"}
                ]);
                completer.done();
              }
            });
            c1.updateValue("new1");
            c2.updateValue("new2");
          });
        });
      });
      group("getError", () {
        test("should return the error when it is present", () {
          var c = new Control("", Validators.required);
          var g = new ControlGroup({"one": c});
          expect(c.getError("required"), isTrue);
          expect(g.getError("required", ["one"]), isTrue);
        });
        test("should return null otherwise", () {
          var c = new Control("not empty", Validators.required);
          var g = new ControlGroup({"one": c});
          expect(c.getError("invalid"), null);
          expect(g.getError("required", ["one"]), null);
          expect(g.getError("required", ["invalid"]), null);
        });
      });
      group("asyncValidator", () {
        test("should run the async validator", fakeAsync(() {
          var c = new Control("value");
          var g = new ControlGroup(
              {"one": c}, null, null, asyncValidator("expected"));
          expect(g.pending, isTrue);
          tick(1);
          expect(g.errors, {"async": true});
          expect(g.pending, isFalse);
        }));
        test("should set the parent group's status to pending", fakeAsync(() {
          var c = new Control("value", null, asyncValidator("expected"));
          var g = new ControlGroup({"one": c});
          expect(g.pending, isTrue);
          tick(1);
          expect(g.pending, isFalse);
        }));
        test(
            "should run the parent group's async validator when children are pending",
            fakeAsync(() {
          var c = new Control("value", null, asyncValidator("expected"));
          var g = new ControlGroup(
              {"one": c}, null, null, asyncValidator("expected"));
          tick(1);
          expect(g.errors, {"async": true});
          expect(g.find(["one"]).errors, {"async": true});
        }));
      });
    });
    group("ControlArray", () {
      group("adding/removing", () {
        ControlArray a;
        var c1, c2, c3;
        setUp(() {
          a = new ControlArray([]);
          c1 = new Control(1);
          c2 = new Control(2);
          c3 = new Control(3);
        });
        test("should support pushing", () {
          a.push(c1);
          expect(a.length, 1);
          expect(a.controls, [c1]);
        });
        test("should support removing", () {
          a.push(c1);
          a.push(c2);
          a.push(c3);
          a.removeAt(1);
          expect(a.controls, [c1, c3]);
        });
        test("should support inserting", () {
          a.push(c1);
          a.push(c3);
          a.insert(1, c2);
          expect(a.controls, [c1, c2, c3]);
        });
      });
      group("value", () {
        test("should be the reduced value of the child controls", () {
          var a = new ControlArray([new Control(1), new Control(2)]);
          expect(a.value, [1, 2]);
        });
        test("should be an empty array when there are no child controls", () {
          var a = new ControlArray([]);
          expect(a.value, []);
        });
      });
      group("errors", () {
        test("should run the validator when the value changes", () {
          var simpleValidator =
              (c) => c.controls[0].value != "correct" ? {"broken": true} : null;
          var c = new Control(null);
          var g = new ControlArray([c], simpleValidator);
          c.updateValue("correct");
          expect(g.valid, isTrue);
          expect(g.errors, isNull);
          c.updateValue("incorrect");
          expect(g.valid, isFalse);
          expect(g.errors, {"broken": true});
        });
      });
      group("dirty", () {
        Control c;
        ControlArray a;
        setUp(() {
          c = new Control("value");
          a = new ControlArray([c]);
        });
        test("should be false after creating a control", () {
          expect(a.dirty, isFalse);
        });
        test("should be false after changing the value of the control", () {
          c.markAsDirty();
          expect(a.dirty, isTrue);
        });
      });
      group("pending", () {
        Control c;
        ControlArray a;
        setUp(() {
          c = new Control("value");
          a = new ControlArray([c]);
        });
        test("should be false after creating a control", () {
          expect(c.pending, isFalse);
          expect(a.pending, isFalse);
        });
        test("should be true after changing the value of the control", () {
          c.markAsPending();
          expect(c.pending, isTrue);
          expect(a.pending, isTrue);
        });
        test("should not update the parent when onlySelf = true", () {
          c.markAsPending(onlySelf: true);
          expect(c.pending, isTrue);
          expect(a.pending, isFalse);
        });
      });
      group("valueChanges", () {
        ControlArray a;
        var c1, c2;
        setUp(() {
          c1 = new Control("old1");
          c2 = new Control("old2");
          a = new ControlArray([c1, c2]);
        });
        test("should fire an event after the value has been updated", () async {
          return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
            ObservableWrapper.subscribe(a.valueChanges, (value) {
              expect(a.value, ["new1", "old2"]);
              expect(value, ["new1", "old2"]);
              completer.done();
            });
            c1.updateValue("new1");
          });
        });
        test(
            "should fire an event after the control's observable fired an event",
            () async {
          return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
            var controlCallbackIsCalled = false;
            ObservableWrapper.subscribe(c1.valueChanges, (value) {
              controlCallbackIsCalled = true;
            });
            ObservableWrapper.subscribe(a.valueChanges, (value) {
              expect(controlCallbackIsCalled, isTrue);
              completer.done();
            });
            c1.updateValue("new1");
          });
        });
        test("should fire an event when a control is removed", () async {
          return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
            ObservableWrapper.subscribe(a.valueChanges, (value) {
              expect(value, ["old1"]);
              completer.done();
            });
            a.removeAt(1);
          });
        });
        test("should fire an event when a control is added", () async {
          return inject([AsyncTestCompleter], (AsyncTestCompleter completer) {
            a.removeAt(1);
            ObservableWrapper.subscribe(a.valueChanges, (value) {
              expect(value, ["old1", "old2"]);
              completer.done();
            });
            a.push(c2);
          });
        });
      });
      group("find", () {
        test("should return null when path is null", () {
          var g = new ControlGroup({});
          expect(g.find(null), null);
        });
        test("should return null when path is empty", () {
          var g = new ControlGroup({});
          expect(g.find([]), null);
        });
        test("should return null when path is invalid", () {
          var g = new ControlGroup({});
          expect(g.find(["one", "two"]), null);
        });
        test("should return a child of a control group", () {
          var g = new ControlGroup({
            "one": new Control("111"),
            "nested": new ControlGroup({"two": new Control("222")})
          });
          expect(g.find(["nested", "two"]).value, "222");
          expect(g.find(["one"]).value, "111");
          expect(g.find("nested/two").value, "222");
          expect(g.find("one").value, "111");
        });
        test("should return an element of an array", () {
          var g = new ControlGroup({
            "array": new ControlArray([new Control("111")])
          });
          expect(g.find(["array", 0]).value, "111");
        });
      });
      group("asyncValidator", () {
        test("should run the async validator", fakeAsync(() {
          var c = new Control("value");
          var g = new ControlArray([c], null, asyncValidator("expected"));
          expect(g.pending, isTrue);
          tick(1);
          expect(g.errors, {"async": true});
          expect(g.pending, isFalse);
        }));
      });
    });
  });
}
