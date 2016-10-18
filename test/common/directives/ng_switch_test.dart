@TestOn('browser && !js')
library angular2.test.common.directives.ng_switch_test;

import "package:angular2/core.dart" show Component;
import "package:angular2/src/common/directives/ng_switch.dart"
    show NgSwitch, NgSwitchWhen, NgSwitchDefault;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void main() {
  group("switch", () {
    group("switch value changes", () {
      test("should switch amongst when values", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<div>" +
              "<ul [ngSwitch]=\"switchValue\">" +
              "<template ngSwitchWhen=\"a\"><li>when a</li></template>" +
              "<template ngSwitchWhen=\"b\"><li>when b</li></template>" +
              "</ul></div>";
          tcb
              .overrideTemplate(TestComponent, template)
              .createAsync(TestComponent)
              .then((fixture) {
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement, hasTextContent(""));
            fixture.debugElement.componentInstance.switchValue = "a";
            fixture.detectChanges();
            expect(
                fixture.debugElement.nativeElement, hasTextContent("when a"));
            fixture.debugElement.componentInstance.switchValue = "b";
            fixture.detectChanges();
            expect(
                fixture.debugElement.nativeElement, hasTextContent("when b"));
            completer.done();
          });
        });
      });
      test("should switch amongst when values with fallback to default",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<div>" +
              "<ul [ngSwitch]=\"switchValue\">" +
              "<li template=\"ngSwitchWhen 'a'\">when a</li>" +
              "<li template=\"ngSwitchDefault\">when default</li>" +
              "</ul></div>";
          tcb
              .overrideTemplate(TestComponent, template)
              .createAsync(TestComponent)
              .then((fixture) {
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent("when default"));
            fixture.debugElement.componentInstance.switchValue = "a";
            fixture.detectChanges();
            expect(
                fixture.debugElement.nativeElement, hasTextContent("when a"));
            fixture.debugElement.componentInstance.switchValue = "b";
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent("when default"));
            completer.done();
          });
        });
      });
      test("should support multiple whens with the same value", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<div>" +
              "<ul [ngSwitch]=\"switchValue\">" +
              "<template ngSwitchWhen=\"a\"><li>when a1;</li></template>" +
              "<template ngSwitchWhen=\"b\"><li>when b1;</li></template>" +
              "<template ngSwitchWhen=\"a\"><li>when a2;</li></template>" +
              "<template ngSwitchWhen=\"b\"><li>when b2;</li></template>" +
              "<template ngSwitchDefault><li>when default1;</li></template>" +
              "<template ngSwitchDefault><li>when default2;</li></template>" +
              "</ul></div>";
          tcb
              .overrideTemplate(TestComponent, template)
              .createAsync(TestComponent)
              .then((fixture) {
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent("when default1;when default2;"));
            fixture.debugElement.componentInstance.switchValue = "a";
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent("when a1;when a2;"));
            fixture.debugElement.componentInstance.switchValue = "b";
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent("when b1;when b2;"));
            completer.done();
          });
        });
      });
    });
    group("when values changes", () {
      test("should switch amongst when values", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<div>" +
              "<ul [ngSwitch]=\"switchValue\">" +
              "<template [ngSwitchWhen]=\"when1\"><li>when 1;</li></template>" +
              "<template [ngSwitchWhen]=\"when2\"><li>when 2;</li></template>" +
              "<template ngSwitchDefault><li>when default;</li></template>" +
              "</ul></div>";
          tcb
              .overrideTemplate(TestComponent, template)
              .createAsync(TestComponent)
              .then((fixture) {
            fixture.debugElement.componentInstance.when1 = "a";
            fixture.debugElement.componentInstance.when2 = "b";
            fixture.debugElement.componentInstance.switchValue = "a";
            fixture.detectChanges();
            expect(
                fixture.debugElement.nativeElement, hasTextContent("when 1;"));
            fixture.debugElement.componentInstance.switchValue = "b";
            fixture.detectChanges();
            expect(
                fixture.debugElement.nativeElement, hasTextContent("when 2;"));
            fixture.debugElement.componentInstance.switchValue = "c";
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent("when default;"));
            fixture.debugElement.componentInstance.when1 = "c";
            fixture.detectChanges();
            expect(
                fixture.debugElement.nativeElement, hasTextContent("when 1;"));
            fixture.debugElement.componentInstance.when1 = "d";
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent("when default;"));
            completer.done();
          });
        });
      });
    });
  });
}

@Component(
    selector: "test-cmp",
    directives: const [NgSwitch, NgSwitchWhen, NgSwitchDefault],
    template: "")
class TestComponent {
  dynamic switchValue;
  dynamic when1;
  dynamic when2;
  TestComponent() {
    this.switchValue = null;
    this.when1 = null;
    this.when2 = null;
  }
}
