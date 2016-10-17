@TestOn('browser && !js')
library angular2.test.common.directives.ng_template_outlet_test;

import "package:angular2/core.dart"
    show Component, Directive, TemplateRef, ContentChildren, QueryList;
import "package:angular2/src/common/directives/ng_template_outlet.dart"
    show NgTemplateOutlet;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void main() {
  group("insert", () {
    test("should do nothing if templateRef is null", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '''<template [ngTemplateOutlet]="null"></template>''';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent(""));
          completer.done();
        });
      });
    });
    test("should insert content specified by TemplateRef", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            '<tpl-refs #refs="tplRefs"><template>foo</template></tpl-refs>'
            '<template [ngTemplateOutlet]="currentTplRef"></template>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent(""));
          var refs = fixture.debugElement.children[0].getLocal("refs");
          fixture.componentInstance.currentTplRef = refs.tplRefs.first;
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent("foo"));
          completer.done();
        });
      });
    });
    test("should clear content if TemplateRef becomes null", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            '<tpl-refs #refs="tplRefs"><template>foo</template></tpl-refs>'
            '<template [ngTemplateOutlet]="currentTplRef"></template>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          var refs = fixture.debugElement.children[0].getLocal("refs");
          fixture.componentInstance.currentTplRef = refs.tplRefs.first;
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent("foo"));
          fixture.componentInstance.currentTplRef = null;
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent(""));
          completer.done();
        });
      });
    });
    test("should swap content if TemplateRef changes", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            '<tpl-refs #refs="tplRefs"><template>foo</template><template>'
            'bar</template></tpl-refs><template '
            '[ngTemplateOutlet]="currentTplRef"></template>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          var refs = fixture.debugElement.children[0].getLocal("refs");
          fixture.componentInstance.currentTplRef = refs.tplRefs.first;
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent("foo"));
          fixture.componentInstance.currentTplRef = refs.tplRefs.last;
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent("bar"));
          completer.done();
        });
      });
    });
  });
}

@Directive(selector: "tpl-refs", exportAs: "tplRefs")
class CaptureTplRefs {
  @ContentChildren(TemplateRef)
  QueryList<TemplateRef> tplRefs;
}

@Component(
    selector: "test-cmp",
    directives: const [NgTemplateOutlet, CaptureTplRefs],
    template: "")
class TestComponent {
  TemplateRef currentTplRef;
}
