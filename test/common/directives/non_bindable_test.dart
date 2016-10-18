@TestOn('browser && !js')
library angular2.test.common.directives.non_bindable_test;

import "package:angular2/core.dart" show Component, Directive;
import "package:angular2/src/core/linker/element_ref.dart" show ElementRef;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void main() {
  group("non-bindable", () {
    test("should not interpolate children", () async {
      inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div>{{text}}<span ngNonBindable>{{text}}</span></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("foo{{text}}"));
          completer.done();
        });
      });
    });
    test("should ignore directives on child nodes", () async {
      inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            "<div ngNonBindable><span id=child test-dec>{{text}}</span></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          // We must use DOM.querySelector instead of fixture.query here

          // since the elements inside are not compiled.
          var span =
              DOM.querySelector(fixture.debugElement.nativeElement, "#child");
          expect(DOM.hasClass(span, "compiled"), isFalse);
          completer.done();
        });
      });
    });
    test("should trigger directives on the same node", () async {
      inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            "<div><span id=child ngNonBindable test-dec>{{text}}</span></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          var span =
              DOM.querySelector(fixture.debugElement.nativeElement, "#child");
          expect(DOM.hasClass(span, "compiled"), isTrue);
          completer.done();
        });
      });
    });
  });
}

@Directive(selector: "[test-dec]")
class TestDirective {
  TestDirective(ElementRef el) {
    DOM.addClass(el.nativeElement, "compiled");
  }
}

@Component(
    selector: "test-cmp", directives: const [TestDirective], template: "")
class TestComponent {
  String text;
  TestComponent() {
    this.text = "foo";
  }
}
