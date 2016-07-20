@TestOn('browser')
library angular2.test.common.directives.ng_plural_test;

import "package:angular2/common.dart"
    show NgPlural, NgPluralCase, NgLocalization;
import "package:angular2/core.dart" show Component, Injectable, provide;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

main() {
  group("switch", () {
    setUp(() {
      beforeEachProviders(
          () => [provide(NgLocalization, useClass: TestLocalizationMap)]);
    });
    test("should display the template according to the exact value", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '<div>'
            '<ul [ngPlural]="switchValue">'
            '<template ngPluralCase="=0"><li>you have no messages.</li>'
            '</template>'
            '<template ngPluralCase="=1"><li>you have one message.</li>'
            '</template>'
            '</ul></div>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.switchValue = 0;
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("you have no messages."));
          fixture.debugElement.componentInstance.switchValue = 1;
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("you have one message."));
          completer.done();
        });
      });
    });
    test("should display the template according to the category", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '<div>'
            '<ul [ngPlural]="switchValue">'
            '<template ngPluralCase="few"><li>you have a few messages.</li>'
            '</template>'
            '<template ngPluralCase="many"><li>you have many messages.</li>'
            '</template>'
            '</ul></div>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.switchValue = 2;
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("you have a few messages."));
          fixture.debugElement.componentInstance.switchValue = 8;
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("you have many messages."));
          completer.done();
        });
      });
    });
    test("should default to other when no matches are found", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '<div>'
            '<ul [ngPlural]="switchValue">'
            '<template ngPluralCase="few"><li>you have a few messages.</li>'
            '</template>'
            '<template ngPluralCase="other"><li>default message.</li>'
            '</template>'
            '</ul></div>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.switchValue = 100;
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("default message."));
          completer.done();
        });
      });
    });
    test("should prioritize value matches over category matches", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '<div>'
            '<ul [ngPlural]=\"switchValue\">'
            '<template ngPluralCase=\"few\"><li>you have a few messages.</li>'
            '</template>'
            '<template ngPluralCase=\"=2\">you have two messages.</template>'
            '</ul></div>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.switchValue = 2;
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("you have two messages."));
          fixture.debugElement.componentInstance.switchValue = 3;
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("you have a few messages."));
          completer.done();
        });
      });
    });
  });
}

@Injectable()
class TestLocalizationMap extends NgLocalization {
  String getPluralCategory(dynamic v) {
    num value = v;
    if (value > 1 && value < 4) {
      return "few";
    } else if (value >= 4 && value < 10) {
      return "many";
    } else {
      return "other";
    }
  }
}

@Component(
    selector: "test-cmp",
    directives: const [NgPlural, NgPluralCase],
    template: "")
class TestComponent {
  num switchValue;
  TestComponent() {
    this.switchValue = null;
  }
}
