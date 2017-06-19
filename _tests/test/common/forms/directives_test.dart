@TestOn('browser')
import 'dart:html';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/common/forms/directives/shared.dart'
    show selectValueAccessor, composeValidators;
import 'package:angular/src/testing/internal.dart';

import '../../test_util.dart';
import '../control_mocks.dart';

class DummyControlValueAccessor implements ControlValueAccessor {
  var writtenValue;
  void registerOnChange(fn) {}
  void registerOnTouched(fn) {}
  void writeValue(dynamic obj) {
    this.writtenValue = obj;
  }
}

class CustomValidatorDirective implements Validator {
  Map<String, dynamic> validate(AbstractControl c) {
    return {"custom": true};
  }
}

class MockNgControl extends Mock implements NgControl {}

void main() {
  group("Shared selectValueAccessor", () {
    DefaultValueAccessor defaultAccessor;
    NgControl dir;
    setUp(() {
      defaultAccessor = new DefaultValueAccessor(null);
      dir = new MockNgControl();
    });
    test("should throw when given an empty array", () {
      expect(() => selectValueAccessor(dir, []),
          throwsABaseException("No valid value accessor for"));
    });
    test("should return the default value accessor when no other provided", () {
      expect(selectValueAccessor(dir, [defaultAccessor]), defaultAccessor);
    });
    test("should return checkbox accessor when provided", () {
      var checkboxAccessor = new CheckboxControlValueAccessor(null);
      expect(selectValueAccessor(dir, [defaultAccessor, checkboxAccessor]),
          checkboxAccessor);
    });
    test("should return select accessor when provided", () {
      var selectAccessor = new SelectControlValueAccessor(null);
      expect(selectValueAccessor(dir, [defaultAccessor, selectAccessor]),
          selectAccessor);
    });
    test("should throw when more than one build-in accessor is provided", () {
      var checkboxAccessor = new CheckboxControlValueAccessor(null);
      var selectAccessor = new SelectControlValueAccessor(null);
      expect(
          () => selectValueAccessor(dir, [checkboxAccessor, selectAccessor]),
          throwsABaseException(
              "More than one built-in value accessor matches"));
    });
    test("should return custom accessor when provided", () {
      var customAccessor = new MockValueAccessor();
      var checkboxAccessor = new CheckboxControlValueAccessor(null);
      expect(
          selectValueAccessor(
              dir, [defaultAccessor, customAccessor, checkboxAccessor]),
          customAccessor);
    });
    test("should throw when more than one custom accessor is provided", () {
      ControlValueAccessor customAccessor = new MockValueAccessor();
      expect(() => selectValueAccessor(dir, [customAccessor, customAccessor]),
          throwsABaseException("More than one custom value accessor matches"));
    });
  });
  group("Shared composeValidators", () {
    setUp(() {
      new DefaultValueAccessor(null);
    });
    test("should compose functions", () {
      var dummy1 = (_) => ({"dummy1": true});
      var dummy2 = (_) => ({"dummy2": true});
      var v = composeValidators([dummy1, dummy2]);
      expect(v(new Control("")), {"dummy1": true, "dummy2": true});
    });
    test("should compose validator directives", () {
      var dummy1 = (_) => ({"dummy1": true});
      var v = composeValidators([dummy1, new CustomValidatorDirective()]);
      expect(v(new Control("")), {"dummy1": true, "custom": true});
    });
  });
  group("NgFormModel", () {
    DefaultValueAccessor defaultAccessor;
    NgFormModel form;
    ControlGroup formModel;
    var loginControlDir;
    setUp(() {
      defaultAccessor = new DefaultValueAccessor(
          new ElementRef(document.createElement('div')));
      form = new NgFormModel([]);
      formModel = new ControlGroup({
        "login": new Control(),
        "passwords": new ControlGroup(
            {"password": new Control(), "passwordConfirm": new Control()})
      });
      form.form = formModel;
      loginControlDir =
          new NgControlName(form, [Validators.required], [defaultAccessor]);
      loginControlDir.name = "login";
      loginControlDir.valueAccessor = new DummyControlValueAccessor();
    });
    test("should reexport control properties", () {
      expect(form.control, formModel);
      expect(form.value, formModel.value);
      expect(form.valid, formModel.valid);
      expect(form.errors, formModel.errors);
      expect(form.pristine, formModel.pristine);
      expect(form.dirty, formModel.dirty);
      expect(form.touched, formModel.touched);
      expect(form.untouched, formModel.untouched);
    });
    group("addControl", () {
      test("should throw when no control found", () {
        var dir = new NgControlName(form, null, [defaultAccessor]);
        dir.name = "invalidName";
        expect(() => form.addControl(dir),
            throwsWith("Cannot find control (invalidName)"));
      });
      test("should throw when no value accessor", () {
        var dir = new NgControlName(form, null, null);
        dir.name = "login";
        expect(() => form.addControl(dir),
            throwsWith("No value accessor for (login)"));
      });
      test("should set up validators", fakeAsync(() {
        form.addControl(loginControlDir);
        // sync validators are set
        expect(formModel.hasError("required", ["login"]), true);
        ((formModel.find(["login"]) as Control)).updateValue("invalid value");
      }));
      test("should write value to the DOM", () {
        ((formModel.find(["login"]) as Control)).updateValue("initValue");
        form.addControl(loginControlDir);
        expect(((loginControlDir.valueAccessor as dynamic)).writtenValue,
            "initValue");
      });
      test(
          'should add the directive to the list of directives '
          'included in the form', () {
        form.addControl(loginControlDir);
        expect(form.directives, [loginControlDir]);
      });
    });
    group("addControlGroup", () {
      var matchingPasswordsValidator = (g) {
        if (g.controls["password"].value !=
            g.controls["passwordConfirm"].value) {
          return {"differentPasswords": true};
        } else {
          return null;
        }
      };
      test("should set up validator", fakeAsync(() {
        var group = new NgControlGroup(form, [matchingPasswordsValidator]);
        group.name = "passwords";
        form.addControlGroup(group);
        ((formModel.find(["passwords", "password"]) as Control))
            .updateValue("somePassword");
        ((formModel.find(["passwords", "passwordConfirm"]) as Control))
            .updateValue("someOtherPassword");
        // sync validators are set
        expect(formModel.hasError("differentPasswords", ["passwords"]), true);

        ((formModel.find(["passwords", "passwordConfirm"]) as Control))
            .updateValue("somePassword");
      }));
    });
    group("removeControl", () {
      test(
          "should remove the directive to the list of directives included in the form",
          () {
        form.addControl(loginControlDir);
        form.removeControl(loginControlDir);
        expect(form.directives, []);
      });
    });
    group("ngOnChanges", () {
      test("should update dom values of all the directives", () {
        form.addControl(loginControlDir);
        ((formModel.find(["login"]) as Control)).updateValue("new value");
        form.ngOnChanges({});
        expect(((loginControlDir.valueAccessor as dynamic)).writtenValue,
            "new value");
      });
      test("should set up a sync validator", () {
        var formValidator = (c) => ({"custom": true});
        var f = new NgFormModel([formValidator]);
        f.form = formModel;
        f.ngOnChanges({"form": new SimpleChange(null, null)});
        expect(formModel.errors, {"custom": true});
      });
    });
    group("NgForm", () {
      DefaultValueAccessor defaultAccessor;
      NgForm form;
      ControlGroup formModel;
      var loginControlDir;
      NgControlGroup personControlGroupDir;
      setUp(() {
        defaultAccessor = new DefaultValueAccessor(null);
        form = new NgForm([]);
        formModel = form.form;
        personControlGroupDir = new NgControlGroup(form, []);
        personControlGroupDir.name = "person";
        loginControlDir =
            new NgControlName(personControlGroupDir, null, [defaultAccessor]);
        loginControlDir.name = "login";
        loginControlDir.valueAccessor = new DummyControlValueAccessor();
      });
      test("should reexport control properties", () {
        expect(form.control, formModel);
        expect(form.value, formModel.value);
        expect(form.valid, formModel.valid);
        expect(form.errors, formModel.errors);
        expect(form.pristine, formModel.pristine);
        expect(form.dirty, formModel.dirty);
        expect(form.touched, formModel.touched);
        expect(form.untouched, formModel.untouched);
      });
      group("addControl & addControlGroup", () {
        test("should create a control with the given name", fakeAsync(() {
          form.addControlGroup(personControlGroupDir);
          form.addControl(loginControlDir);
          flushMicrotasks();
          expect(formModel.find(["person", "login"]), isNotNull);
        }));
      });
      group("removeControl & removeControlGroup", () {
        test("should remove control", fakeAsync(() {
          form.addControlGroup(personControlGroupDir);
          form.addControl(loginControlDir);
          form.removeControlGroup(personControlGroupDir);
          form.removeControl(loginControlDir);
          flushMicrotasks();
          expect(formModel.find(["person"]), isNull);
          expect(formModel.find(["person", "login"]), isNull);
        }));
      });
      test("should set up sync validator", fakeAsync(() {
        var formValidator = (c) => ({"custom": true});
        var f = new NgForm([formValidator]);
        tick();
        expect(f.form.errors, {"custom": true});
      }));
    });
    group("NgControlGroup", () {
      ControlGroup formModel;
      var controlGroupDir;
      setUp(() {
        formModel = new ControlGroup({"login": new Control(null)});
        var parent = new NgFormModel([]);
        parent.form = new ControlGroup({"group": formModel});
        controlGroupDir = new NgControlGroup(parent, []);
        controlGroupDir.name = "group";
      });
      test("should reexport control properties", () {
        expect(controlGroupDir.control, formModel);
        expect(controlGroupDir.value, formModel.value);
        expect(controlGroupDir.valid, formModel.valid);
        expect(controlGroupDir.errors, formModel.errors);
        expect(controlGroupDir.pristine, formModel.pristine);
        expect(controlGroupDir.dirty, formModel.dirty);
        expect(controlGroupDir.touched, formModel.touched);
        expect(controlGroupDir.untouched, formModel.untouched);
      });
    });
    group("NgFormControl", () {
      var controlDir;
      var control;
      var checkProperties = (control) {
        expect(controlDir.control, control);
        expect(controlDir.value, control.value);
        expect(controlDir.valid, control.valid);
        expect(controlDir.errors, control.errors);
        expect(controlDir.pristine, control.pristine);
        expect(controlDir.dirty, control.dirty);
        expect(controlDir.touched, control.touched);
        expect(controlDir.untouched, control.untouched);
      };
      setUp(() {
        controlDir =
            new NgFormControl([Validators.required], [defaultAccessor]);
        controlDir.valueAccessor = new DummyControlValueAccessor();
        control = new Control(null);
        controlDir.form = control;
      });
      test("should reexport control properties", () {
        checkProperties(control);
      });
      test("should reexport new control properties", () {
        var newControl = new Control(null);
        controlDir.form = newControl;
        controlDir.ngOnChanges({"form": new SimpleChange(control, newControl)});
        checkProperties(newControl);
      });
      test("should set up validator", () {
        expect(control.valid, true);
        // this will add the required validator and recalculate the validity
        controlDir.ngOnChanges({"form": new SimpleChange(null, control)});
        expect(control.valid, false);
      });
    });
    group("NgModel", () {
      var ngModel;
      setUp(() {
        ngModel = new NgModel([Validators.required], [defaultAccessor]);
        ngModel.valueAccessor = new DummyControlValueAccessor();
      });
      test("should reexport control properties", () {
        var control = ngModel.control;
        expect(ngModel.control, control);
        expect(ngModel.value, control.value);
        expect(ngModel.valid, control.valid);
        expect(ngModel.errors, control.errors);
        expect(ngModel.pristine, control.pristine);
        expect(ngModel.dirty, control.dirty);
        expect(ngModel.touched, control.touched);
        expect(ngModel.untouched, control.untouched);
      });
      test("should set up validator", fakeAsync(() {
        // this will add the required validator and recalculate the validity
        ngModel.ngOnInit();
        ngModel.ngOnChanges({});
        tick();
        expect(ngModel.control.errors, {"required": true});
        ngModel.control.updateValue("someValue");
      }));
    });
    group("NgControlName", () {
      Control formModel;
      var controlNameDir;
      setUp(() {
        formModel = new Control("name");
        var parent = new NgFormModel([]);
        parent.form = new ControlGroup({"name": formModel});
        controlNameDir = new NgControlName(parent, [], [defaultAccessor]);
        controlNameDir.name = "name";
      });
      test("should reexport control properties", () {
        expect(controlNameDir.control, formModel);
        expect(controlNameDir.value, formModel.value);
        expect(controlNameDir.valid, formModel.valid);
        expect(controlNameDir.errors, formModel.errors);
        expect(controlNameDir.pristine, formModel.pristine);
        expect(controlNameDir.dirty, formModel.dirty);
        expect(controlNameDir.touched, formModel.touched);
        expect(controlNameDir.untouched, formModel.untouched);
      });
    });
  });
}
