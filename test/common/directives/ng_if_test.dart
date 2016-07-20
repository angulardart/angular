@TestOn('browser')
library angular2.test.common.directives.ng_if_spec;

import "package:angular2/common.dart" show NgIf;
import "package:angular2/core.dart" show Component;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

main() {
  group("ngIf directive", () {
    test("should work in a template attribute", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var html = '<div><copy-me template="ngIf booleanCondition">'
            'hello</copy-me></div>';
        tcb
            .overrideTemplate(TestComponent, html)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          expect(
              DOM
                  .querySelectorAll(
                      fixture.debugElement.nativeElement, "copy-me")
                  .length,
              1);
          expect(fixture.debugElement.nativeElement, hasTextContent('hello'));
          completer.done();
        });
      });
    });
    test("should work in a template element", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var html = '<div><template [ngIf]="booleanCondition">'
            '<copy-me>hello2</copy-me></template></div>';
        tcb
            .overrideTemplate(TestComponent, html)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          expect(
              DOM
                  .querySelectorAll(
                      fixture.debugElement.nativeElement, "copy-me")
                  .length,
              1);
          expect(fixture.debugElement.nativeElement, hasTextContent("hello2"));
          completer.done();
        });
      });
    });
    test("should toggle node when condition changes", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var html =
            "<div><copy-me template=\"ngIf booleanCondition\">hello</copy-me></div>";
        tcb
            .overrideTemplate(TestComponent, html)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.booleanCondition = false;
          fixture.detectChanges();
          expect(
              DOM.querySelectorAll(
                  fixture.debugElement.nativeElement, "copy-me"),
              hasLength(0));

          expect(fixture.debugElement.nativeElement, hasTextContent(""));
          fixture.debugElement.componentInstance.booleanCondition = true;
          fixture.detectChanges();
          expect(
              DOM
                  .querySelectorAll(
                      fixture.debugElement.nativeElement, "copy-me")
                  .length,
              1);
          expect(fixture.debugElement.nativeElement, hasTextContent("hello"));
          fixture.debugElement.componentInstance.booleanCondition = false;
          fixture.detectChanges();
          expect(
              DOM
                  .querySelectorAll(
                      fixture.debugElement.nativeElement, "copy-me")
                  .length,
              0);
          expect(fixture.debugElement.nativeElement, hasTextContent(""));
          completer.done();
        });
      });
    });
    test("should handle nested if correctly", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var html =
            "<div><template [ngIf]=\"booleanCondition\"><copy-me *ngIf=\"nestedBooleanCondition\">hello</copy-me></template></div>";
        tcb
            .overrideTemplate(TestComponent, html)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.booleanCondition = false;
          fixture.detectChanges();
          expect(
              DOM.querySelectorAll(
                  fixture.debugElement.nativeElement, "copy-me"),
              hasLength(0));

          expect(fixture.debugElement.nativeElement, hasTextContent(""));
          fixture.debugElement.componentInstance.booleanCondition = true;
          fixture.detectChanges();
          expect(
              DOM.querySelectorAll(
                  fixture.debugElement.nativeElement, "copy-me"),
              hasLength(1));
          expect(fixture.debugElement.nativeElement, hasTextContent("hello"));
          fixture.debugElement.componentInstance.nestedBooleanCondition = false;
          fixture.detectChanges();
          expect(
              DOM.querySelectorAll(
                  fixture.debugElement.nativeElement, "copy-me"),
              hasLength(0));
          expect(fixture.debugElement.nativeElement, hasTextContent(""));
          fixture.debugElement.componentInstance.nestedBooleanCondition = true;
          fixture.detectChanges();
          expect(
              DOM.querySelectorAll(
                  fixture.debugElement.nativeElement, "copy-me"),
              hasLength(1));
          expect(fixture.debugElement.nativeElement, hasTextContent("hello"));
          fixture.debugElement.componentInstance.booleanCondition = false;
          fixture.detectChanges();
          expect(
              DOM.querySelectorAll(
                  fixture.debugElement.nativeElement, "copy-me"),
              hasLength(0));
          expect(fixture.debugElement.nativeElement, hasTextContent(""));
          completer.done();
        });
      });
    });
    test("should update several nodes with if", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var html = "<div>" +
            "<copy-me template=\"ngIf numberCondition + 1 >= 2\">helloNumber</copy-me>" +
            "<copy-me template=\"ngIf stringCondition == 'foo'\">helloString</copy-me>" +
            "<copy-me template=\"ngIf functionCondition(stringCondition, numberCondition)\">helloFunction</copy-me>" +
            "</div>";
        tcb
            .overrideTemplate(TestComponent, html)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          expect(
              DOM.querySelectorAll(
                  fixture.debugElement.nativeElement, "copy-me"),
              hasLength(3));
          expect(DOM.getText(fixture.debugElement.nativeElement),
              "helloNumberhelloStringhelloFunction");
          fixture.debugElement.componentInstance.numberCondition = 0;
          fixture.detectChanges();
          expect(
              DOM.querySelectorAll(
                  fixture.debugElement.nativeElement, "copy-me"),
              hasLength(1));
          expect(fixture.debugElement.nativeElement,
              hasTextContent("helloString"));
          fixture.debugElement.componentInstance.numberCondition = 1;
          fixture.debugElement.componentInstance.stringCondition = "bar";
          fixture.detectChanges();
          expect(
              DOM.querySelectorAll(
                  fixture.debugElement.nativeElement, "copy-me"),
              hasLength(1));
          expect(fixture.debugElement.nativeElement,
              hasTextContent("helloNumber"));
          completer.done();
        });
      });
    });
  });
}

@Component(selector: "test-cmp", directives: const [NgIf], template: "")
class TestComponent {
  bool booleanCondition;
  bool nestedBooleanCondition;
  num numberCondition;
  String stringCondition;
  Function functionCondition;
  TestComponent() {
    this.booleanCondition = true;
    this.nestedBooleanCondition = true;
    this.numberCondition = 1;
    this.stringCondition = "foo";
    this.functionCondition = (s, n) {
      return s == "foo" && n == 1;
    };
  }
}
