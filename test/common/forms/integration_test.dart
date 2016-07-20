@TestOn('browser')
library angular2.test.common.forms.integration_test;

import "package:angular2/common.dart";
import "package:angular2/core.dart"
    show Component, Directive, Output, EventEmitter;
import "package:angular2/core.dart" show Provider, Input;
import "package:angular2/platform/browser.dart" show By;
import "package:angular2/src/facade/async.dart"
    show ObservableWrapper, TimerWrapper;
import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "package:angular2/src/facade/promise.dart" show PromiseWrapper;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

main() {
  group("integration tests", () {
    test("should initialize DOM elements with the given form object", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var t = '''<div [ngFormModel]="form">
                <input type="text" ngControl="login">
               </div>''';
        tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
          fixture.debugElement.componentInstance.form =
              new ControlGroup({"login": new Control("loginValue")});
          fixture.detectChanges();
          var input = fixture.debugElement.query(By.css("input"));
          expect(input.nativeElement.value, "loginValue");
          completer.done();
        });
      });
    });
    test("should throw if a form isn't passed into ngFormModel", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var t = '''<div [ngFormModel]="form">
                <input type="text" ngControl="login">
               </div>''';
        tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
          expect(
              () => fixture.detectChanges(),
              throwsA(allOf(
                  new isInstanceOf<Error>(),
                  predicate((e) => e.message.contains(
                      "ngFormModel expects a form. Please pass one in.")))));
          completer.done();
        });
      });
    });
    test("should update the control group values on DOM change", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var form = new ControlGroup({"login": new Control("oldValue")});
        var t = '''<div [ngFormModel]="form">
                <input type="text" ngControl="login">
              </div>''';
        tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
          fixture.debugElement.componentInstance.form = form;
          fixture.detectChanges();
          var input = fixture.debugElement.query(By.css("input"));
          input.nativeElement.value = "updatedValue";
          dispatchEvent(input.nativeElement, "input");
          expect(form.value, {"login": "updatedValue"});
          completer.done();
        });
      });
    });
    test("should ignore the change event for <input type=text>", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var form = new ControlGroup({"login": new Control("oldValue")});
        var t = '''<div [ngFormModel]="form">
                <input type="text" ngControl="login">
              </div>''';
        tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
          fixture.debugElement.componentInstance.form = form;
          fixture.detectChanges();
          var input = fixture.debugElement.query(By.css("input"));
          input.nativeElement.value = "updatedValue";
          ObservableWrapper.subscribe(form.valueChanges, (value) {
            throw "Should not happen";
          });
          dispatchEvent(input.nativeElement, "change");
          completer.done();
        });
      });
    });
    test("should emit ngSubmit event on submit", fakeAsync(() {
      inject([TestComponentBuilder], (TestComponentBuilder tcb) {
        var t = '''<div>
                      <form [ngFormModel]="form" (ngSubmit)="name=\'updated\'"></form>
                      <span>{{name}}</span>
                    </div>''';
        ComponentFixture fixture;
        tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
          fixture = root;
        });
        tick();
        fixture.debugElement.componentInstance.form = new ControlGroup({});
        fixture.debugElement.componentInstance.name = "old";
        tick();
        var form = fixture.debugElement.query(By.css("form"));
        dispatchEvent(form.nativeElement, "submit");
        tick();
        expect(fixture.debugElement.componentInstance.name, "updated");
      });
    }));
    test("should work with single controls", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var control = new Control("loginValue");
        var t = '''<div><input type="text" [ngFormControl]="form"></div>''';
        tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
          fixture.debugElement.componentInstance.form = control;
          fixture.detectChanges();
          var input = fixture.debugElement.query(By.css("input"));
          expect(input.nativeElement.value, "loginValue");
          input.nativeElement.value = "updatedValue";
          dispatchEvent(input.nativeElement, "input");
          expect(control.value, "updatedValue");
          completer.done();
        });
      });
    });
    test("should update DOM elements when rebinding the control group",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var t = '''<div [ngFormModel]="form">
                <input type="text" ngControl="login">
               </div>''';
        tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
          fixture.debugElement.componentInstance.form =
              new ControlGroup({"login": new Control("oldValue")});
          fixture.detectChanges();
          fixture.debugElement.componentInstance.form =
              new ControlGroup({"login": new Control("newValue")});
          fixture.detectChanges();
          var input = fixture.debugElement.query(By.css("input"));
          expect(input.nativeElement.value, "newValue");
          completer.done();
        });
      });
    });
    test("should update DOM elements when updating the value of a control",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var login = new Control("oldValue");
        var form = new ControlGroup({"login": login});
        var t = '''<div [ngFormModel]="form">
                <input type="text" ngControl="login">
               </div>''';
        tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
          fixture.debugElement.componentInstance.form = form;
          fixture.detectChanges();
          login.updateValue("newValue");
          fixture.detectChanges();
          var input = fixture.debugElement.query(By.css("input"));
          expect(input.nativeElement.value, "newValue");
          completer.done();
        });
      });
    });
    test(
        "should mark controls as touched after interacting with the DOM control",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var login = new Control("oldValue");
        var form = new ControlGroup({"login": login});
        var t = '''<div [ngFormModel]="form">
                <input type="text" ngControl="login">
               </div>''';
        tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
          fixture.debugElement.componentInstance.form = form;
          fixture.detectChanges();
          var loginEl = fixture.debugElement.query(By.css("input"));
          expect(login.touched, isFalse);
          dispatchEvent(loginEl.nativeElement, "blur");
          expect(login.touched, isTrue);
          completer.done();
        });
      });
    });
    group("different control types", () {
      test("should support <input type=text>", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var t = '''<div [ngFormModel]="form">
                  <input type="text" ngControl="text">
                </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form =
                new ControlGroup({"text": new Control("old")});
            fixture.detectChanges();
            var input = fixture.debugElement.query(By.css("input"));
            expect(input.nativeElement.value, "old");
            input.nativeElement.value = "new";
            dispatchEvent(input.nativeElement, "input");
            expect(fixture.debugElement.componentInstance.form.value,
                {"text": "new"});
            completer.done();
          });
        });
      });
      test("should support <input> without type", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var t = '''<div [ngFormModel]="form">
                    <input ngControl="text">
                  </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form =
                new ControlGroup({"text": new Control("old")});
            fixture.detectChanges();
            var input = fixture.debugElement.query(By.css("input"));
            expect(input.nativeElement.value, "old");
            input.nativeElement.value = "new";
            dispatchEvent(input.nativeElement, "input");
            expect(fixture.debugElement.componentInstance.form.value,
                {"text": "new"});
            completer.done();
          });
        });
      });
      test("should support <textarea>", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var t = '''<div [ngFormModel]="form">
                    <textarea ngControl="text"></textarea>
                  </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form =
                new ControlGroup({"text": new Control("old")});
            fixture.detectChanges();
            var textarea = fixture.debugElement.query(By.css("textarea"));
            expect(textarea.nativeElement.value, "old");
            textarea.nativeElement.value = "new";
            dispatchEvent(textarea.nativeElement, "input");
            expect(fixture.debugElement.componentInstance.form.value,
                {"text": "new"});
            completer.done();
          });
        });
      });
      test("should support <type=checkbox>", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var t = '''<div [ngFormModel]="form">
                    <input type="checkbox" ngControl="checkbox">
                  </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form =
                new ControlGroup({"checkbox": new Control(true)});
            fixture.detectChanges();
            var input = fixture.debugElement.query(By.css("input"));
            expect(input.nativeElement.checked, isTrue);
            input.nativeElement.checked = false;
            dispatchEvent(input.nativeElement, "change");
            expect(fixture.debugElement.componentInstance.form.value,
                {"checkbox": false});
            completer.done();
          });
        });
      });
      test("should support <type=number>", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var t = '''<div [ngFormModel]="form">
                    <input type="number" ngControl="num">
                  </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form =
                new ControlGroup({"num": new Control(10)});
            fixture.detectChanges();
            var input = fixture.debugElement.query(By.css("input"));
            expect(input.nativeElement.value, "10");
            input.nativeElement.value = "20";
            dispatchEvent(input.nativeElement, "input");
            expect(
                fixture.debugElement.componentInstance.form.value, {"num": 20});
            completer.done();
          });
        });
      });
      test("should support <type=number> when value is cleared in the UI",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var t = '''<div [ngFormModel]="form">
                    <input type="number" ngControl="num" required>
                  </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form =
                new ControlGroup({"num": new Control(10)});
            fixture.detectChanges();
            var input = fixture.debugElement.query(By.css("input"));
            input.nativeElement.value = "";
            dispatchEvent(input.nativeElement, "input");
            expect(fixture.debugElement.componentInstance.form.valid, isFalse);
            expect(fixture.debugElement.componentInstance.form.value,
                {"num": null});
            input.nativeElement.value = "0";
            dispatchEvent(input.nativeElement, "input");
            expect(fixture.debugElement.componentInstance.form.valid, isTrue);
            expect(
                fixture.debugElement.componentInstance.form.value, {"num": 0});
            completer.done();
          });
        });
      });
      test(
          "should support <type=number> when value is cleared programmatically",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var form = new ControlGroup({"num": new Control(10)});
          var t = '''<div [ngFormModel]="form">
                    <input type="number" ngControl="num" [(ngModel)]="data">
                  </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form = form;
            fixture.debugElement.componentInstance.data = null;
            fixture.detectChanges();
            var input = fixture.debugElement.query(By.css("input"));
            expect(input.nativeElement.value, "");
            completer.done();
          });
        });
      });
      test("should support <type=radio>", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var t = '''<form [ngFormModel]="form">
                    <input type="radio" ngControl="foodChicken" name="food">
                    <input type="radio" ngControl="foodFish" name="food">
                  </form>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form = new ControlGroup({
              "foodChicken":
                  new Control(new RadioButtonState(false, "chicken")),
              "foodFish": new Control(new RadioButtonState(true, "fish"))
            });
            fixture.detectChanges();
            var input = fixture.debugElement.query(By.css("input"));
            expect(input.nativeElement.checked, isFalse);
            dispatchEvent(input.nativeElement, "change");
            fixture.detectChanges();
            var value = fixture.debugElement.componentInstance.form.value;
            expect(value["foodChicken"].checked, isTrue);
            expect(value["foodFish"].checked, isFalse);
            completer.done();
          });
        });
      });
      group("should support <select>", () {
        test("with basic selection", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            var t = '''<select>
                        <option value="SF"></option>
                        <option value="NYC"></option>
                      </select>''';
            tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
              fixture.detectChanges();
              var select = fixture.debugElement.query(By.css("select"));
              var sfOption = fixture.debugElement.query(By.css("option"));
              expect(select.nativeElement.value, "SF");
              expect(sfOption.nativeElement.selected, isTrue);
              completer.done();
            });
          });
        });
        test("with basic selection and value bindings", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            var t = '''<select>
                        <option *ngFor="let city of list" [value]="city[\'id\']">
                          {{ city[\'name\'] }}
                        </option>
                      </select>''';
            tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
              var testComp = fixture.debugElement.componentInstance;
              testComp.list = [
                {"id": "0", "name": "SF"},
                {"id": "1", "name": "NYC"}
              ];
              fixture.detectChanges();
              var sfOption = fixture.debugElement.query(By.css("option"));
              expect(sfOption.nativeElement.value, "0");
              testComp.list[0]["id"] = "2";
              fixture.detectChanges();
              expect(sfOption.nativeElement.value, "2");
              completer.done();
            });
          });
        });
        test("with ngControl", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            var t = '''<div [ngFormModel]="form">
                      <select ngControl="city">
                        <option value="SF"></option>
                        <option value="NYC"></option>
                      </select>
                    </div>''';
            tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
              fixture.debugElement.componentInstance.form =
                  new ControlGroup({"city": new Control("SF")});
              fixture.detectChanges();
              var select = fixture.debugElement.query(By.css("select"));
              var sfOption = fixture.debugElement.query(By.css("option"));
              expect(select.nativeElement.value, "SF");
              expect(sfOption.nativeElement.selected, isTrue);
              select.nativeElement.value = "NYC";
              dispatchEvent(select.nativeElement, "change");
              expect(fixture.debugElement.componentInstance.form.value,
                  {"city": "NYC"});
              expect(sfOption.nativeElement.selected, isFalse);
              completer.done();
            });
          });
        });
        test("with a dynamic list of options", fakeAsync(() {
          inject([TestComponentBuilder], (TestComponentBuilder tcb) {
            var t = '''<div [ngFormModel]="form">
                        <select ngControl="city">
                          <option *ngFor="let c of data" [value]="c"></option>
                        </select>
                    </div>''';
            var fixture;
            tcb
                .overrideTemplate(MyComp, t)
                .createAsync(MyComp)
                .then((compFixture) => fixture = compFixture);
            tick();
            fixture.debugElement.componentInstance.form =
                new ControlGroup({"city": new Control("NYC")});
            fixture.debugElement.componentInstance.data = ["SF", "NYC"];
            fixture.detectChanges();
            tick();
            var select = fixture.debugElement.query(By.css("select"));
            expect(select.nativeElement.value, "NYC");
          });
        }));
        test("with option values that are objects", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            var t = '''<div>
                        <select [(ngModel)]="selectedCity">
                          <option *ngFor="let c of list" [ngValue]="c">{{c[\'name\']}}</option>
                        </select>
                    </div>''';
            tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
              var testComp = fixture.debugElement.componentInstance;
              testComp.list = [
                {"name": "SF"},
                {"name": "NYC"},
                {"name": "Buffalo"}
              ];
              testComp.selectedCity = testComp.list[1];
              fixture.detectChanges();
              var select = fixture.debugElement.query(By.css("select"));
              var nycOption =
                  fixture.debugElement.queryAll(By.css("option"))[1];
              expect(select.nativeElement.value, "1: Object");
              expect(nycOption.nativeElement.selected, isTrue);
              select.nativeElement.value = "2: Object";
              dispatchEvent(select.nativeElement, "change");
              fixture.detectChanges();
              TimerWrapper.setTimeout(() {
                expect(testComp.selectedCity["name"], "Buffalo");
                completer.done();
              }, 0);
            });
          });
        });
        test("when new options are added", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            var t = '''<div>
                        <select [(ngModel)]="selectedCity">
                          <option *ngFor="let c of list" [ngValue]="c">{{c[\'name\']}}</option>
                        </select>
                    </div>''';
            tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
              MyComp testComp = fixture.debugElement.componentInstance;
              testComp.list = [
                {"name": "SF"},
                {"name": "NYC"}
              ];
              testComp.selectedCity = testComp.list[1];
              fixture.detectChanges();
              testComp.list.add({"name": "Buffalo"});
              testComp.selectedCity = testComp.list[2];
              fixture.detectChanges();
              var select = fixture.debugElement.query(By.css("select"));
              var buffalo = fixture.debugElement.queryAll(By.css("option"))[2];
              expect(select.nativeElement.value, "2: Object");
              expect(buffalo.nativeElement.selected, isTrue);
              completer.done();
            });
          });
        });
        test("when options are removed", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            var t = '''<div>
                        <select [(ngModel)]="selectedCity">
                          <option *ngFor="let c of list" [ngValue]="c">{{c}}</option>
                        </select>
                    </div>''';
            tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
              MyComp testComp = fixture.debugElement.componentInstance;
              testComp.list = [
                {"name": "SF"},
                {"name": "NYC"}
              ];
              testComp.selectedCity = testComp.list[1];
              fixture.detectChanges();
              var select = fixture.debugElement.query(By.css("select"));
              expect(select.nativeElement.value, "1: Object");
              testComp.list.removeLast();
              fixture.detectChanges();
              expect(select.nativeElement.value != "1: Object", isTrue);
              completer.done();
            });
          });
        });
        test("when option values change identity while tracking by index",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            var t = '''<div>
                        <select [(ngModel)]="selectedCity">
                          <option *ngFor="let c of list; trackBy:customTrackBy" [ngValue]="c">{{c}}</option>
                        </select>
                    </div>''';
            tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
              var testComp = fixture.debugElement.componentInstance;
              testComp.list = [
                {"name": "SF"},
                {"name": "NYC"}
              ];
              testComp.selectedCity = testComp.list[0];
              fixture.detectChanges();
              testComp.list[1] = "Buffalo";
              testComp.selectedCity = testComp.list[1];
              fixture.detectChanges();
              var select = fixture.debugElement.query(By.css("select"));
              var buffalo = fixture.debugElement.queryAll(By.css("option"))[1];
              expect(select.nativeElement.value, "1: Buffalo");
              expect(buffalo.nativeElement.selected, isTrue);
              completer.done();
            });
          });
        });
        test("with duplicate option values", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            var t = '''<div>
                        <select [(ngModel)]="selectedCity">
                          <option *ngFor="let c of list" [ngValue]="c">{{c}}</option>
                        </select>
                    </div>''';
            tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
              var testComp = fixture.debugElement.componentInstance;
              testComp.list = [
                {"name": "NYC"},
                {"name": "SF"},
                {"name": "SF"}
              ];
              testComp.selectedCity = testComp.list[0];
              fixture.detectChanges();
              testComp.selectedCity = testComp.list[1];
              fixture.detectChanges();
              var select = fixture.debugElement.query(By.css("select"));
              var firstSF = fixture.debugElement.queryAll(By.css("option"))[1];
              expect(select.nativeElement.value, "1: Object");
              expect(firstSF.nativeElement.selected, isTrue);
              completer.done();
            });
          });
        });
        test("when option values have same content, but different identities",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            var t = '''<div>
                        <select [(ngModel)]="selectedCity">
                          <option *ngFor="let c of list" [ngValue]="c">{{c[\'name\']}}</option>
                        </select>
                    </div>''';
            tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
              var testComp = fixture.debugElement.componentInstance;
              testComp.list = [
                {"name": "SF"},
                {"name": "NYC"},
                {"name": "NYC"}
              ];
              testComp.selectedCity = testComp.list[0];
              fixture.detectChanges();
              testComp.selectedCity = testComp.list[2];
              fixture.detectChanges();
              var select = fixture.debugElement.query(By.css("select"));
              var secondNYC =
                  fixture.debugElement.queryAll(By.css("option"))[2];
              expect(select.nativeElement.value, "2: Object");
              expect(secondNYC.nativeElement.selected, isTrue);
              completer.done();
            });
          });
        });
      });
      test("should support custom value accessors", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var t = '''<div [ngFormModel]="form">
                    <input type="text" ngControl="name" wrapped-value>
                  </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form =
                new ControlGroup({"name": new Control("aa")});
            fixture.detectChanges();
            var input = fixture.debugElement.query(By.css("input"));
            expect(input.nativeElement.value, "!aa!");
            input.nativeElement.value = "!bb!";
            dispatchEvent(input.nativeElement, "input");
            expect(fixture.debugElement.componentInstance.form.value,
                {"name": "bb"});
            completer.done();
          });
        });
      });
      test(
          'should support custom value accessors on non builtin input '
          'elements that fire a change event without a \'target\' property',
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var t = '''<div [ngFormModel]="form">
                    <my-input ngControl="name"></my-input>
                  </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form =
                new ControlGroup({"name": new Control("aa")});
            fixture.detectChanges();
            var input = fixture.debugElement.query(By.css("my-input"));
            expect(input.componentInstance.value, "!aa!");
            input.componentInstance.value = "!bb!";
            ObservableWrapper.subscribe(input.componentInstance.onInput,
                (value) {
              expect(fixture.debugElement.componentInstance.form.value,
                  {"name": "bb"});
              completer.done();
            });
            input.componentInstance.dispatchChangeEvent();
          });
        });
      });
    });
    group("validations", () {
      test("should use sync validators defined in html", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var form = new ControlGroup({
            "login": new Control(""),
            "min": new Control(""),
            "max": new Control("")
          });
          var t = '''<div [ngFormModel]="form" login-is-empty-validator>
                      <input type="text" ngControl="login" required>
                      <input type="text" ngControl="min" minlength="3">
                      <input type="text" ngControl="max" maxlength="3">
                   </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form = form;
            fixture.detectChanges();
            var required = fixture.debugElement.query(By.css("[required]"));
            var minLength = fixture.debugElement.query(By.css("[minlength]"));
            var maxLength = fixture.debugElement.query(By.css("[maxlength]"));
            required.nativeElement.value = "";
            minLength.nativeElement.value = "1";
            maxLength.nativeElement.value = "1234";
            dispatchEvent(required.nativeElement, "input");
            dispatchEvent(minLength.nativeElement, "input");
            dispatchEvent(maxLength.nativeElement, "input");
            expect(form.hasError("required", ["login"]), isTrue);
            expect(form.hasError("minlength", ["min"]), isTrue);
            expect(form.hasError("maxlength", ["max"]), isTrue);
            expect(form.hasError("loginIsEmpty"), isTrue);
            required.nativeElement.value = "1";
            minLength.nativeElement.value = "123";
            maxLength.nativeElement.value = "123";
            dispatchEvent(required.nativeElement, "input");
            dispatchEvent(minLength.nativeElement, "input");
            dispatchEvent(maxLength.nativeElement, "input");
            expect(form.valid, isTrue);
            completer.done();
          });
        });
      });
      test("should use async validators defined in the html", fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          var form = new ControlGroup({"login": new Control("")});
          var t = '''<div [ngFormModel]="form">
                      <input type="text" ngControl="login" uniq-login-validator="expected">
                   </div>''';
          var rootTC;
          tcb
              .overrideTemplate(MyComp, t)
              .createAsync(MyComp)
              .then((root) => rootTC = root);
          tick();
          rootTC.debugElement.componentInstance.form = form;
          rootTC.detectChanges();
          expect(form.pending, isTrue);
          tick(100);
          expect(form.hasError("uniqLogin", ["login"]), isTrue);
          var input = rootTC.debugElement.query(By.css("input"));
          input.nativeElement.value = "expected";
          dispatchEvent(input.nativeElement, "input");
          tick(100);
          expect(form.valid, isTrue);
        });
      }));
      test("should use sync validators defined in the model", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var form = new ControlGroup(
              {"login": new Control("aa", Validators.required)});
          var t = '''<div [ngFormModel]="form">
                    <input type="text" ngControl="login">
                   </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form = form;
            fixture.detectChanges();
            expect(form.valid, isTrue);
            var input = fixture.debugElement.query(By.css("input"));
            input.nativeElement.value = "";
            dispatchEvent(input.nativeElement, "input");
            expect(form.valid, isFalse);
            completer.done();
          });
        });
      });
      test("should use async validators defined in the model", fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          var control = new Control(
              "", Validators.required, uniqLoginAsyncValidator("expected"));
          var form = new ControlGroup({"login": control});
          var t = '''<div [ngFormModel]="form">
                    <input type="text" ngControl="login">
                   </div>''';
          var fixture;
          tcb
              .overrideTemplate(MyComp, t)
              .createAsync(MyComp)
              .then((root) => fixture = root);
          tick();
          fixture.debugElement.componentInstance.form = form;
          fixture.detectChanges();
          expect(form.hasError("required", ["login"]), isTrue);
          var input = fixture.debugElement.query(By.css("input"));
          input.nativeElement.value = "wrong value";
          dispatchEvent(input.nativeElement, "input");
          expect(form.pending, isTrue);
          tick();
          expect(form.hasError("uniqLogin", ["login"]), isTrue);
          input.nativeElement.value = "expected";
          dispatchEvent(input.nativeElement, "input");
          tick();
          expect(form.valid, isTrue);
        });
      }));
    });
    group("nested forms", () {
      test("should init DOM with the given form object", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var form = new ControlGroup({
            "nested": new ControlGroup({"login": new Control("value")})
          });
          var t = '''<div [ngFormModel]="form">
                    <div ngControlGroup="nested">
                      <input type="text" ngControl="login">
                    </div>
                </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form = form;
            fixture.detectChanges();
            var input = fixture.debugElement.query(By.css("input"));
            expect(input.nativeElement.value, "value");
            completer.done();
          });
        });
      });
      test("should update the control group values on DOM change", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var form = new ControlGroup({
            "nested": new ControlGroup({"login": new Control("value")})
          });
          var t = '''<div [ngFormModel]="form">
                        <div ngControlGroup="nested">
                          <input type="text" ngControl="login">
                        </div>
                    </div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form = form;
            fixture.detectChanges();
            var input = fixture.debugElement.query(By.css("input"));
            input.nativeElement.value = "updatedValue";
            dispatchEvent(input.nativeElement, "input");
            expect(form.value, {
              "nested": {"login": "updatedValue"}
            });
            completer.done();
          });
        });
      });
    });
    test("should support ngModel for complex forms", fakeAsync(() {
      inject([TestComponentBuilder], (TestComponentBuilder tcb) {
        var form = new ControlGroup({"name": new Control("")});
        var t =
            '''<div [ngFormModel]="form"><input type="text" ngControl="name" [(ngModel)]="name"></div>''';
        ComponentFixture fixture;
        tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
          fixture = root;
        });
        tick();
        fixture.debugElement.componentInstance.name = "oldValue";
        fixture.debugElement.componentInstance.form = form;
        fixture.detectChanges();
        var input = fixture.debugElement.query(By.css("input")).nativeElement;
        expect(input.value, "oldValue");
        input.value = "updatedValue";
        dispatchEvent(input, "input");
        tick();
        expect(fixture.debugElement.componentInstance.name, "updatedValue");
      });
    }));
    test("should support ngModel for single fields", fakeAsync(() {
      inject([TestComponentBuilder], (TestComponentBuilder tcb) {
        var form = new Control("");
        var t =
            '''<div><input type="text" [ngFormControl]="form" [(ngModel)]="name"></div>''';
        ComponentFixture fixture;
        tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
          fixture = root;
        });
        tick();
        fixture.debugElement.componentInstance.form = form;
        fixture.debugElement.componentInstance.name = "oldValue";
        fixture.detectChanges();
        var input = fixture.debugElement.query(By.css("input")).nativeElement;
        expect(input.value, "oldValue");
        input.value = "updatedValue";
        dispatchEvent(input, "input");
        tick();
        expect(fixture.debugElement.componentInstance.name, "updatedValue");
      });
    }));
    group("template-driven forms", () {
      test("should add new controls and control groups", fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          var t = '''<form>
                         <div ngControlGroup="user">
                          <input type="text" ngControl="login">
                         </div>
                   </form>''';
          ComponentFixture fixture;
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
            fixture = root;
          });
          tick();
          fixture.debugElement.componentInstance.name = null;
          fixture.detectChanges();
          var form = fixture.debugElement.children[0].inject(NgForm);
          expect(form.controls["user"], isNull);
          tick();
          expect(form.controls["user"], isNotNull);
          expect(form.controls["user"].controls["login"], isNotNull);
        });
      }));
      test("should emit ngSubmit event on submit", fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          var t = '''<div><form (ngSubmit)="name=\'updated\'"></form></div>''';
          ComponentFixture fixture;
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
            fixture = root;
          });
          tick();
          fixture.debugElement.componentInstance.name = "old";
          var form = fixture.debugElement.query(By.css("form"));
          dispatchEvent(form.nativeElement, "submit");
          tick();
          expect(fixture.debugElement.componentInstance.name, "updated");
        });
      }));
      test("should not create a template-driven form when ngNoForm is used",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var t = '''<form ngNoForm>
                   </form>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.name = null;
            fixture.detectChanges();
            expect(
                fixture.debugElement.children[0].providerTokens, hasLength(0));
            completer.done();
          });
        });
      });
      test("should remove controls", fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          var t = '''<form>
                        <div *ngIf="name == \'show\'">
                          <input type="text" ngControl="login">
                        </div>
                      </form>''';
          ComponentFixture fixture;
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
            fixture = root;
          });
          tick();
          fixture.debugElement.componentInstance.name = "show";
          fixture.detectChanges();
          tick();
          var form = fixture.debugElement.children[0].inject(NgForm);
          expect(form.controls["login"], isNotNull);
          fixture.debugElement.componentInstance.name = "hide";
          fixture.detectChanges();
          tick();
          expect(form.controls["login"], isNull);
        });
      }));
      test("should remove control groups", fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          var t = '''<form>
                         <div *ngIf="name==\'show\'" ngControlGroup="user">
                          <input type="text" ngControl="login">
                         </div>
                   </form>''';
          ComponentFixture fixture;
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
            fixture = root;
          });
          tick();
          fixture.debugElement.componentInstance.name = "show";
          fixture.detectChanges();
          tick();
          var form = fixture.debugElement.children[0].inject(NgForm);
          expect(form.controls["user"], isNotNull);
          fixture.debugElement.componentInstance.name = "hide";
          fixture.detectChanges();
          tick();
          expect(form.controls["user"], isNull);
        });
      }));
      test("should support ngModel for complex forms", fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          var t = '''<form>
                          <input type="text" ngControl="name" [(ngModel)]="name">
                   </form>''';
          ComponentFixture fixture;
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
            fixture = root;
          });
          tick();
          fixture.debugElement.componentInstance.name = "oldValue";
          fixture.detectChanges();
          tick();
          var input = fixture.debugElement.query(By.css("input")).nativeElement;
          expect(input.value, "oldValue");
          input.value = "updatedValue";
          dispatchEvent(input, "input");
          tick();
          expect(fixture.debugElement.componentInstance.name, "updatedValue");
        });
      }));
      test("should support ngModel for single fields", fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          var t = '''<div><input type="text" [(ngModel)]="name"></div>''';
          ComponentFixture fixture;
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
            fixture = root;
          });
          tick();
          fixture.debugElement.componentInstance.name = "oldValue";
          fixture.detectChanges();
          var input = fixture.debugElement.query(By.css("input")).nativeElement;
          expect(input.value, "oldValue");
          input.value = "updatedValue";
          dispatchEvent(input, "input");
          tick();
          expect(fixture.debugElement.componentInstance.name, "updatedValue");
        });
      }));
      test("should support <type=radio>", fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          var t = '''<form>
                      <input type="radio" name="food" ngControl="chicken" [(ngModel)]="data[\'chicken1\']">
                      <input type="radio" name="food" ngControl="fish" [(ngModel)]="data[\'fish1\']">
                    </form>
                    <form>
                      <input type="radio" name="food" ngControl="chicken" [(ngModel)]="data[\'chicken2\']">
                      <input type="radio" name="food" ngControl="fish" [(ngModel)]="data[\'fish2\']">
                    </form>''';
          ComponentFixture fixture;
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((f) {
            fixture = f;
          });
          tick();
          fixture.debugElement.componentInstance.data = {
            "chicken1": new RadioButtonState(false, "chicken"),
            "fish1": new RadioButtonState(true, "fish"),
            "chicken2": new RadioButtonState(false, "chicken"),
            "fish2": new RadioButtonState(true, "fish")
          };
          fixture.detectChanges();
          tick();
          var input = fixture.debugElement.query(By.css("input"));
          expect(input.nativeElement.checked, isFalse);
          dispatchEvent(input.nativeElement, "change");
          tick();
          var data = fixture.debugElement.componentInstance.data;
          expect(data["chicken1"].checked, isTrue);
          expect(data["chicken1"].value, "chicken");
          expect(data["fish1"].checked, isFalse);
          expect(data["fish1"].value, "fish");
          expect(data["chicken2"].checked, isFalse);
          expect(data["chicken2"].value, "chicken");
          expect(data["fish2"].checked, isTrue);
          expect(data["fish2"].value, "fish");
        });
      }));
    });
    group("setting status classes", () {
      test("should work with single fields", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var form = new Control("", Validators.required);
          var t = '''<div><input type="text" [ngFormControl]="form"></div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form = form;
            fixture.detectChanges();
            var input =
                fixture.debugElement.query(By.css("input")).nativeElement;
            expect(sortedClassList(input),
                ["ng-invalid", "ng-pristine", "ng-untouched"]);
            dispatchEvent(input, "blur");
            fixture.detectChanges();
            expect(sortedClassList(input),
                ["ng-invalid", "ng-pristine", "ng-touched"]);
            input.value = "updatedValue";
            dispatchEvent(input, "input");
            fixture.detectChanges();
            expect(
                sortedClassList(input), ["ng-dirty", "ng-touched", "ng-valid"]);
            completer.done();
          });
        });
      });
      test("should work with complex model-driven forms", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var form =
              new ControlGroup({"name": new Control("", Validators.required)});
          var t =
              '''<form [ngFormModel]="form"><input type="text" ngControl="name"></form>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.form = form;
            fixture.detectChanges();
            var input =
                fixture.debugElement.query(By.css("input")).nativeElement;
            expect(sortedClassList(input),
                ["ng-invalid", "ng-pristine", "ng-untouched"]);
            dispatchEvent(input, "blur");
            fixture.detectChanges();
            expect(sortedClassList(input),
                ["ng-invalid", "ng-pristine", "ng-touched"]);
            input.value = "updatedValue";
            dispatchEvent(input, "input");
            fixture.detectChanges();
            expect(
                sortedClassList(input), ["ng-dirty", "ng-touched", "ng-valid"]);
            completer.done();
          });
        });
      });
      test("should work with ngModel", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var t = '''<div><input [(ngModel)]="name" required></div>''';
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((fixture) {
            fixture.debugElement.componentInstance.name = "";
            fixture.detectChanges();
            var input =
                fixture.debugElement.query(By.css("input")).nativeElement;
            expect(sortedClassList(input),
                ["ng-invalid", "ng-pristine", "ng-untouched"]);
            dispatchEvent(input, "blur");
            fixture.detectChanges();
            expect(sortedClassList(input),
                ["ng-invalid", "ng-pristine", "ng-touched"]);
            input.value = "updatedValue";
            dispatchEvent(input, "input");
            fixture.detectChanges();
            expect(
                sortedClassList(input), ["ng-dirty", "ng-touched", "ng-valid"]);
            completer.done();
          });
        });
      });
    });
    group("ngModel corner cases", () {
      test(
          "should not update the view when the value initially came from the view",
          fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          var form = new Control("");
          var t =
              '''<div><input type="text" [ngFormControl]="form" [(ngModel)]="name"></div>''';
          ComponentFixture fixture;
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
            fixture = root;
          });
          tick();
          fixture.debugElement.componentInstance.form = form;
          fixture.detectChanges();
          // In Firefox, effective text selection in the real DOM requires an actual focus

          // of the field. This is not an issue in a new HTML document.
          if (browserDetection.isFirefox) {
            var fakeDoc = DOM.createHtmlDocument();
            DOM.appendChild(fakeDoc.body, fixture.debugElement.nativeElement);
          }
          var input = fixture.debugElement.query(By.css("input")).nativeElement;
          input.value = "aa";
          input.selectionStart = 1;
          dispatchEvent(input, "input");
          tick();
          fixture.detectChanges();
          // selection start has not changed because we did not reset the value
          expect(input.selectionStart, 1);
        });
      }));
      test(
          "should update the view when the model is set back to what used to be in the view",
          fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          var t = '''<input type="text" [(ngModel)]="name">''';
          ComponentFixture fixture;
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
            fixture = root;
          });
          tick();
          fixture.debugElement.componentInstance.name = "";
          fixture.detectChanges();
          // Type "aa" into the input.
          var input = fixture.debugElement.query(By.css("input")).nativeElement;
          input.value = "aa";
          input.selectionStart = 1;
          dispatchEvent(input, "input");
          tick();
          fixture.detectChanges();
          expect(fixture.debugElement.componentInstance.name, "aa");
          // Programatically update the input value to be "bb".
          fixture.debugElement.componentInstance.name = "bb";
          tick();
          fixture.detectChanges();
          expect(input.value, "bb");
          // Programatically set it back to "aa".
          fixture.debugElement.componentInstance.name = "aa";
          tick();
          fixture.detectChanges();
          expect(input.value, "aa");
        });
      }));
      test("should not crash when validity is checked from a binding",
          fakeAsync(() {
        inject([TestComponentBuilder], (TestComponentBuilder tcb) {
          // {{x.valid}} used to crash because valid() tried to read a property

          // from form.control before it was set. This test verifies this bug is

          // fixed.
          var t = '''<form><div ngControlGroup="x" #x="ngForm">
                      <input type="text" ngControl="test"></div>{{x.valid}}</form>''';
          ComponentFixture fixture;
          tcb.overrideTemplate(MyComp, t).createAsync(MyComp).then((root) {
            fixture = root;
          });
          tick();
          fixture.detectChanges();
        });
      }));
    });
  });
}

@Directive(selector: "[wrapped-value]", host: const {
  "(input)": "handleOnInput(\$event.target.value)",
  "[value]": "value"
})
class WrappedValue implements ControlValueAccessor {
  var value;
  Function onChange;
  WrappedValue(NgControl cd) {
    cd.valueAccessor = this;
  }
  writeValue(value) {
    this.value = '''!${ value}!''';
  }

  registerOnChange(fn) {
    this.onChange = fn;
  }

  registerOnTouched(fn) {}
  handleOnInput(value) {
    this.onChange(value.substring(1, value.length - 1));
  }
}

@Component(selector: "my-input", template: "")
class MyInput implements ControlValueAccessor {
  @Output("input")
  EventEmitter<dynamic> onInput = new EventEmitter();
  String value;
  MyInput(NgControl cd) {
    cd.valueAccessor = this;
  }
  writeValue(value) {
    this.value = '''!${ value}!''';
  }

  registerOnChange(fn) {
    ObservableWrapper.subscribe(this.onInput, fn);
  }

  registerOnTouched(fn) {}
  dispatchChangeEvent() {
    ObservableWrapper.callEmit(
        this.onInput, this.value.substring(1, this.value.length - 1));
  }
}

uniqLoginAsyncValidator(String expectedValue) {
  return (c) {
    var completer = PromiseWrapper.completer();
    var res = (c.value == expectedValue) ? null : {"uniqLogin": true};
    completer.resolve(res);
    return completer.promise;
  };
}

loginIsEmptyGroupValidator(ControlGroup c) {
  return c.controls["login"].value == "" ? {"loginIsEmpty": true} : null;
}

@Directive(selector: "[login-is-empty-validator]", providers: const [
  const Provider(NG_VALIDATORS,
      useValue: loginIsEmptyGroupValidator, multi: true)
])
class LoginIsEmptyValidator {}

@Directive(selector: "[uniq-login-validator]", providers: const [
  const Provider(NG_ASYNC_VALIDATORS,
      useExisting: UniqLoginValidator, multi: true)
])
class UniqLoginValidator implements Validator {
  @Input("uniq-login-validator")
  var expected;
  validate(c) {
    return uniqLoginAsyncValidator(this.expected)(c);
  }
}

@Component(selector: "my-comp", template: "", directives: const [
  FORM_DIRECTIVES,
  WrappedValue,
  MyInput,
  NgIf,
  NgFor,
  LoginIsEmptyValidator,
  UniqLoginValidator
])
class MyComp {
  dynamic form;
  String name;
  dynamic data;
  List<dynamic> list;
  dynamic selectedCity;
  num customTrackBy(num index, dynamic obj) {
    return index;
  }
}

sortedClassList(el) {
  var l = DOM.classList(el);
  ListWrapper.sort(l);
  return l;
}
