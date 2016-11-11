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
        var template = '<template [ngTemplateOutlet]="null"></template>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent(''));
          completer.done();
        });
      });
    });

    test("should insert content specified by TemplateRef", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '<tpl-refs #refs="tplRefs">'
            '<template>foo</template>'
            '</tpl-refs>'
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
        var template = '<tpl-refs #refs="tplRefs">'
            '<template>foo</template>'
            '<template>bar</template>'
            '</tpl-refs>'
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
          fixture.componentInstance.currentTplRef = refs.tplRefs.last;
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent("bar"));
          completer.done();
        });
      });
    });

    test(
        'should display template if context is null',
        () async => inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              var template = '<tpl-refs #refs="tplRefs">'
                  '<template>foo</template>'
                  '</tpl-refs>'
                  '<template [ngTemplateOutlet]="currentTplRef" [ngOutletContext]="null"></template>';
              tcb
                  .overrideTemplate(TestComponent, template)
                  .createAsync(TestComponent)
                  .then((fixture) {
                fixture.detectChanges();
                expect(fixture.nativeElement, hasTextContent(''));

                var refs = fixture.debugElement.children[0].getLocal('refs');

                fixture.componentInstance.currentTplRef = refs.tplRefs.first;
                fixture.detectChanges();
                expect(fixture.nativeElement, hasTextContent('foo'));

                completer.done();
              });
            }));

    test(
        'should reflect initial context and changes',
        () async => inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              var template = '<tpl-refs #refs="tplRefs">'
                  '<template let-foo="foo"><span>{{foo}}</span></template>'
                  '</tpl-refs>'
                  '<template [ngTemplateOutlet]="currentTplRef" [ngOutletContext]="context"></template>';
              tcb
                  .overrideTemplate(TestComponent, template)
                  .createAsync(TestComponent)
                  .then((fixture) {
                fixture.detectChanges();

                var refs = fixture.debugElement.children[0].getLocal('refs');
                fixture.componentInstance.currentTplRef = refs.tplRefs.first;

                fixture.detectChanges();
                expect(
                    fixture.debugElement.nativeElement, hasTextContent('bar'));

                fixture.componentInstance.context.foo = 'alter-bar';

                fixture.detectChanges();
                expect(fixture.debugElement.nativeElement,
                    hasTextContent('alter-bar'));

                completer.done();
              });
            }));

    test(
        'should reflect user defined \$implicit property in the context',
        () async => inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              var template = '<tpl-refs #refs="tplRefs">'
                  '<template let-ctx><span>{{ctx.foo}}</span></template>'
                  '</tpl-refs>'
                  '<template [ngTemplateOutlet]="currentTplRef" [ngOutletContext]="context"></template>';
              tcb
                  .overrideTemplate(TestComponent, template)
                  .createAsync(TestComponent)
                  .then((fixture) {
                fixture.detectChanges();

                var refs = fixture.debugElement.children[0].getLocal('refs');
                fixture.componentInstance.currentTplRef = refs.tplRefs.first;

                fixture.componentInstance.context = {
                  '\$implicit': fixture.componentInstance.context
                };
                fixture.detectChanges();
                expect(
                    fixture.debugElement.nativeElement, hasTextContent('bar'));

                completer.done();
              });
            }));

    test(
        'should reflect context re-binding',
        () async => inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              var template = '<tpl-refs #refs="tplRefs">'
                  '<template let-shawshank="shawshank">'
                  '<span>{{shawshank}}</span>'
                  '</template>'
                  '</tpl-refs>'
                  '<template [ngTemplateOutlet]="currentTplRef" [ngOutletContext]="context"></template>';
              tcb
                  .overrideTemplate(TestComponent, template)
                  .createAsync(TestComponent)
                  .then((fixture) {
                fixture.detectChanges();

                var refs = fixture.debugElement.children[0].getLocal('refs');
                fixture.componentInstance.currentTplRef = refs.tplRefs.first;
                fixture.componentInstance.context = {'shawshank': 'brooks'};

                fixture.detectChanges();
                expect(fixture.debugElement.nativeElement,
                    hasTextContent('brooks'));

                fixture.componentInstance.context = {'shawshank': 'was here'};

                fixture.detectChanges();
                expect(fixture.debugElement.nativeElement,
                    hasTextContent('was here'));

                completer.done();
              });
            }));
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
  Map context = {'foo': 'bar'};
}
