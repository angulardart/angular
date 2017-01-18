@TestOn('browser && !js')
library angular2.test.common.directives.ng_style_test;

import 'dart:html';

import "package:angular2/core.dart" show Component;
import "package:angular2/src/common/directives/ng_style.dart" show NgStyle;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void main() {
  group("binding to CSS styles", () {
    test("should add styles specified in an object literal", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '''<div [ngStyle]="{\'max-width\': \'40px\'}"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          Element elm = fixture.debugElement.children[0].nativeElement;
          expect(elm.style.maxWidth, "40px");
          completer.done();
        });
      });
    });
    test("should add and change styles specified in an object expression",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '''<div [ngStyle]="expr"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((ComponentFixture fixture) {
          Map<String, dynamic> expr;
          fixture.debugElement.componentInstance.expr = {"max-width": "40px"};
          fixture.detectChanges();
          Element elm = fixture.debugElement.children[0].nativeElement;
          expect(elm.style.maxWidth, "40px");
          expr = fixture.debugElement.componentInstance.expr
              as Map<String, dynamic>;
          expr["max-width"] = "30%";
          fixture.detectChanges();
          expect(elm.style.maxWidth, "30%");
          completer.done();
        });
      });
    });
    test("should remove styles when deleting a key in an object expression",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '''<div [ngStyle]="expr"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.expr = {"max-width": "40px"};
          fixture.detectChanges();
          Element elm = fixture.debugElement.children[0].nativeElement;
          expect(elm.style.maxWidth, "40px");
          fixture.debugElement.componentInstance.expr.remove('max-width');
          fixture.detectChanges();
          expect(elm.style.maxWidth, '');
          completer.done();
        });
      });
    });
    test("should co-operate with the style attribute", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            '''<div style="font-size: 12px" [ngStyle]="expr"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.expr = {"max-width": "40px"};
          fixture.detectChanges();
          Element elm = fixture.debugElement.children[0].nativeElement;
          expect(elm.style.maxWidth, "40px");
          expect(elm.style.fontSize, "12px");
          fixture.debugElement.componentInstance.expr.remove('max-width');
          fixture.detectChanges();
          expect(elm.style.maxWidth, "");
          expect(elm.style.fontSize, "12px");
          completer.done();
        });
      });
    });
    test(
        'should co-operate with the style.[styleName]="expr" special-case '
        'in the compiler', () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            '''<div [style.font-size.px]="12" [ngStyle]="expr"></div>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.expr = {"max-width": "40px"};
          fixture.detectChanges();
          Element elm = fixture.debugElement.children[0].nativeElement;
          expect(elm.style.maxWidth, "40px");
          expect(elm.style.fontSize, "12px");
          fixture.debugElement.componentInstance.expr.remove('max-width');
          expect(elm.style.fontSize, "12px");
          fixture.detectChanges();
          expect(elm.style.maxWidth, "");
          completer.done();
        });
      });
    });
  });
}

@Component(selector: "test-cmp", directives: const [NgStyle], template: "")
class TestComponent {
  var expr;
}
