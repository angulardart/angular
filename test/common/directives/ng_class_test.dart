@TestOn('browser && !js')
library angular2.test.common.directives.ng_class_test;

import "package:angular2/common.dart" show NgFor;
import "package:angular2/core.dart" show Component;
import "package:angular2/src/common/directives/ng_class.dart";
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void detectChangesAndCheckClasses(ComponentFixture fixture, String classes) {
  fixture.detectChanges();
  expect(fixture.debugElement.children[0].nativeElement.className, classes);
}

void main() {
  group("binding to CSS class list", () {
    test("should clean up when the directive is destroyed", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            "<div *ngFor=\"let item of items\" [ngClass]=\"item\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          assert(fixture.debugElement != null);
          fixture.debugElement.componentInstance.items = [
            ["0"]
          ];
          fixture.detectChanges();
          fixture.debugElement.componentInstance.items = [
            ["1"]
          ];
          detectChangesAndCheckClasses(fixture, "1");
          completer.done();
        });
      });
    });
  });
  group("expressions evaluating to objects", () {
    test("should add classes specified in an object literal", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"{foo: true, bar: false}\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo");
          completer.done();
        });
      });
    });
    test(
        'should add classes specified in an object literal '
        ' without change in class names', () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            '''<div [ngClass]="{\'foo-bar\': true, \'fooBar\': true}"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo-bar fooBar");
          completer.done();
        });
      });
    });
    test(
        "should add and remove classes based on changes in object literal values",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            "<div [ngClass]=\"{foo: condition, bar: !condition}\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo");
          fixture.debugElement.componentInstance.condition = false;
          detectChangesAndCheckClasses(fixture, "bar");
          completer.done();
        });
      });
    });
    test(
        "should add and remove classes based on changes to the expression object",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"objExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo");
          fixture.debugElement.componentInstance.objExpr['bar'] = true;
          detectChangesAndCheckClasses(fixture, "foo bar");
          fixture.debugElement.componentInstance.objExpr['baz'] = true;
          detectChangesAndCheckClasses(fixture, "foo bar baz");
          fixture.debugElement.componentInstance.objExpr.remove('bar');
          detectChangesAndCheckClasses(fixture, "foo baz");
          completer.done();
        });
      });
    });
    test(
        "should add and remove classes based on reference changes to the expression object",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"objExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo");
          fixture.debugElement.componentInstance.objExpr = {
            "foo": true,
            "bar": true
          };
          detectChangesAndCheckClasses(fixture, "foo bar");
          fixture.debugElement.componentInstance.objExpr = {"baz": true};
          detectChangesAndCheckClasses(fixture, "baz");
          completer.done();
        });
      });
    });
    test("should remove active classes when expression evaluates to null",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"objExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo");
          fixture.debugElement.componentInstance.objExpr = null;
          detectChangesAndCheckClasses(fixture, "");
          fixture.debugElement.componentInstance.objExpr = {
            "foo": false,
            "bar": true
          };
          detectChangesAndCheckClasses(fixture, "bar");
          completer.done();
        });
      });
    });
    test("should allow multiple classes per expression", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"objExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.objExpr = {
            "bar baz": true,
            "bar1 baz1": true
          };
          detectChangesAndCheckClasses(fixture, "bar baz bar1 baz1");
          fixture.debugElement.componentInstance.objExpr = {
            "bar baz": false,
            "bar1 baz1": true
          };
          detectChangesAndCheckClasses(fixture, "bar1 baz1");
          completer.done();
        });
      });
    });
    test("should split by one or more spaces between classes", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"objExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.objExpr = {
            "foo bar     baz": true
          };
          detectChangesAndCheckClasses(fixture, "foo bar baz");
          completer.done();
        });
      });
    });
  });
  group("expressions evaluating to lists", () {
    test("should add classes specified in a list literal", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            '''<div [ngClass]="[\'foo\', \'bar\', \'foo-bar\', \'fooBar\']"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo bar foo-bar fooBar");
          completer.done();
        });
      });
    });
    test("should add and remove classes based on changes to the expression",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"arrExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          List<String> arrExpr =
              fixture.debugElement.componentInstance.arrExpr as List<String>;
          detectChangesAndCheckClasses(fixture, "foo");
          arrExpr.add("bar");
          detectChangesAndCheckClasses(fixture, "foo bar");
          arrExpr[1] = "baz";
          detectChangesAndCheckClasses(fixture, "foo baz");
          fixture.debugElement.componentInstance.arrExpr.remove('baz');
          detectChangesAndCheckClasses(fixture, "foo");
          completer.done();
        });
      });
    });
    test("should add and remove classes when a reference changes", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"arrExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo");
          fixture.debugElement.componentInstance.arrExpr = ["bar"];
          detectChangesAndCheckClasses(fixture, "bar");
          completer.done();
        });
      });
    });
    test("should take initial classes into account when a reference changes",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div class=\"foo\" [ngClass]=\"arrExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo");
          fixture.debugElement.componentInstance.arrExpr = ["bar"];
          detectChangesAndCheckClasses(fixture, "foo bar");
          completer.done();
        });
      });
    });
    test("should ignore empty or blank class names", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div class=\"foo\" [ngClass]=\"arrExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.arrExpr = ["", "  "];
          detectChangesAndCheckClasses(fixture, "foo");
          completer.done();
        });
      });
    });
    test("should trim blanks from class names", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div class=\"foo\" [ngClass]=\"arrExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.arrExpr = [" bar  "];
          detectChangesAndCheckClasses(fixture, "foo bar");
          completer.done();
        });
      });
    });
    test("should allow multiple classes per item in arrays", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"arrExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.arrExpr = [
            "foo bar baz",
            "foo1 bar1   baz1"
          ];
          detectChangesAndCheckClasses(fixture, "foo bar baz foo1 bar1 baz1");
          fixture.debugElement.componentInstance.arrExpr = [
            "foo bar   baz foobar"
          ];
          detectChangesAndCheckClasses(fixture, "foo bar baz foobar");
          completer.done();
        });
      });
    });
  });
  group("expressions evaluating to sets", () {
    test("should add and remove classes if the set instance changed", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"setExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          var setExpr = new Set<String>();
          setExpr.add("bar");
          fixture.debugElement.componentInstance.setExpr = setExpr;
          detectChangesAndCheckClasses(fixture, "bar");
          setExpr = new Set<String>();
          setExpr.add("baz");
          fixture.debugElement.componentInstance.setExpr = setExpr;
          detectChangesAndCheckClasses(fixture, "baz");
          completer.done();
        });
      });
    });
  });
  group("expressions evaluating to string", () {
    test("should add classes specified in a string literal", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '''<div [ngClass]="\'foo bar foo-bar fooBar\'"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo bar foo-bar fooBar");
          completer.done();
        });
      });
    });
    test("should add and remove classes based on changes to the expression",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"strExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo");
          fixture.debugElement.componentInstance.strExpr = "foo bar";
          detectChangesAndCheckClasses(fixture, "foo bar");
          fixture.debugElement.componentInstance.strExpr = "baz";
          detectChangesAndCheckClasses(fixture, "baz");
          completer.done();
        });
      });
    });
    test("should remove active classes when switching from string to null",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '''<div [ngClass]="strExpr"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo");
          fixture.debugElement.componentInstance.strExpr = null;
          detectChangesAndCheckClasses(fixture, "");
          completer.done();
        });
      });
    });
    test(
        "should take initial classes into account when switching from string to null",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '''<div class="foo" [ngClass]="strExpr"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "foo");
          fixture.debugElement.componentInstance.strExpr = null;
          detectChangesAndCheckClasses(fixture, "foo");
          completer.done();
        });
      });
    });
    test("should ignore empty and blank strings", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '''<div class="foo" [ngClass]="strExpr"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.strExpr = "";
          detectChangesAndCheckClasses(fixture, "foo");
          completer.done();
        });
      });
    });
  });
  group("cooperation with other class-changing constructs", () {
    test("should co-operate with the class attribute", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div [ngClass]=\"objExpr\" class=\"init foo\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.objExpr['bar'] = true;
          detectChangesAndCheckClasses(fixture, "init foo bar");
          fixture.debugElement.componentInstance.objExpr['foo'] = false;
          detectChangesAndCheckClasses(fixture, "init bar");
          fixture.debugElement.componentInstance.objExpr = null;
          detectChangesAndCheckClasses(fixture, "init foo");
          completer.done();
        });
      });
    });
    test("should co-operate with the interpolated class attribute", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            '''<div [ngClass]="objExpr" class="{{\'init foo\'}}"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.objExpr['bar'] = true;
          detectChangesAndCheckClasses(fixture, '''init foo bar''');
          fixture.debugElement.componentInstance.objExpr['foo'] = false;
          detectChangesAndCheckClasses(fixture, '''init bar''');
          fixture.debugElement.componentInstance.objExpr = null;
          detectChangesAndCheckClasses(fixture, '''init foo''');
          completer.done();
        });
      });
    });
    test("should co-operate with the class attribute and binding to it",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            '''<div [ngClass]="objExpr" class="init" [class]="\'foo\'"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.objExpr['bar'] = true;
          detectChangesAndCheckClasses(fixture, '''init foo bar''');
          fixture.debugElement.componentInstance.objExpr['foo'] = false;
          detectChangesAndCheckClasses(fixture, '''init bar''');
          fixture.debugElement.componentInstance.objExpr = null;
          detectChangesAndCheckClasses(fixture, '''init foo''');
          completer.done();
        });
      });
    });
    test("should co-operate with the class attribute and class.name binding",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            "<div class=\"init foo\" [ngClass]=\"objExpr\" [class.baz]=\"condition\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "init foo baz");
          fixture.debugElement.componentInstance.objExpr['bar'] = true;
          detectChangesAndCheckClasses(fixture, "init foo baz bar");
          fixture.debugElement.componentInstance.objExpr['foo'] = false;
          detectChangesAndCheckClasses(fixture, "init baz bar");
          fixture.debugElement.componentInstance.condition = false;
          detectChangesAndCheckClasses(fixture, "init bar");
          completer.done();
        });
      });
    });
    test(
        "should co-operate with initial class and class attribute binding when binding changes",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            "<div class=\"init\" [ngClass]=\"objExpr\" [class]=\"strExpr\"></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          detectChangesAndCheckClasses(fixture, "init foo");
          fixture.debugElement.componentInstance.objExpr['bar'] = true;
          detectChangesAndCheckClasses(fixture, "init foo bar");
          fixture.debugElement.componentInstance.strExpr = "baz";
          detectChangesAndCheckClasses(fixture, "init bar baz foo");
          fixture.debugElement.componentInstance.objExpr = null;
          detectChangesAndCheckClasses(fixture, "init baz");
          completer.done();
        });
      });
    });
  });
}

@Component(
    selector: "test-cmp", directives: const [NgClass, NgFor], template: "")
class TestComponent {
  bool condition = true;
  List<dynamic> items;
  List<String> arrExpr = ["foo"];
  Set<String> setExpr = new Set<String>();
  var objExpr = {"foo": true, "bar": false};
  var strExpr = "foo";
  TestComponent() {
    this.setExpr.add("foo");
  }
}
