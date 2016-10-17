@TestOn('browser && !js')
library angular2.test.core.linker.projection_integration_test;

import 'package:angular2/core.dart'
    show
        Component,
        Directive,
        ElementRef,
        TemplateRef,
        ViewContainerRef,
        ViewEncapsulation,
        View;
import 'package:angular2/src/debug/debug_node.dart' show getAllDebugNodes;
import 'package:angular2/src/platform/dom/dom_adapter.dart' show DOM;
import 'package:angular2/src/testing/by.dart';
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

void main() {
  group('projection', () {
    test('should support simple components', () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: '<simple>' + '<div>A</div>' + '</simple>',
                    directives: [Simple]))
            .createAsync(MainComp)
            .then((main) {
          expect(main.debugElement.nativeElement, hasTextContent('SIMPLE(A)'));
          completer.done();
        });
      });
    });
    test(
        'should support simple components with text interpolation as '
        'direct children', () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "{{'START('}}<simple>" +
                        "{{text}}" +
                        "</simple>{{')END'}}",
                    directives: [Simple]))
            .createAsync(MainComp)
            .then((main) {
          main.debugElement.componentInstance.text = "A";
          main.detectChanges();
          expect(main.debugElement.nativeElement,
              hasTextContent("START(SIMPLE(A))END"));
          completer.done();
        });
      });
    });
    test("should support projecting text interpolation to a non bound element",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                Simple,
                new View(
                    template: "SIMPLE(<div><ng-content></ng-content></div>)",
                    directives: []))
            .overrideView(
                MainComp,
                new View(
                    template: "<simple>{{text}}</simple>",
                    directives: [Simple]))
            .createAsync(MainComp)
            .then((main) {
          main.debugElement.componentInstance.text = "A";
          main.detectChanges();
          expect(main.debugElement.nativeElement, hasTextContent("SIMPLE(A)"));
          completer.done();
        });
      });
    });
    test(
        "should support projecting text interpolation to a non bound element with other bound elements after it",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                Simple,
                new View(
                    template:
                        "SIMPLE(<div><ng-content></ng-content></div><div [tabIndex]=\"0\">EL</div>)",
                    directives: []))
            .overrideView(
                MainComp,
                new View(
                    template: "<simple>{{text}}</simple>",
                    directives: [Simple]))
            .createAsync(MainComp)
            .then((main) {
          main.debugElement.componentInstance.text = "A";
          main.detectChanges();
          expect(
              main.debugElement.nativeElement, hasTextContent("SIMPLE(AEL)"));
          completer.done();
        });
      });
    });
    test("should project content components", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                Simple,
                new View(
                    template: "SIMPLE({{0}}|<ng-content></ng-content>|{{2}})",
                    directives: []))
            .overrideView(
                OtherComp, new View(template: "{{1}}", directives: []))
            .overrideView(
                MainComp,
                new View(
                    template: "<simple><other></other></simple>",
                    directives: [Simple, OtherComp]))
            .createAsync(MainComp)
            .then((main) {
          main.detectChanges();
          expect(
              main.debugElement.nativeElement, hasTextContent("SIMPLE(0|1|2)"));
          completer.done();
        });
      });
    });
    test("should not show the light dom even if there is no content tag",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(MainComp,
                new View(template: "<empty>A</empty>", directives: [Empty]))
            .createAsync(MainComp)
            .then((main) {
          expect(main.debugElement.nativeElement, hasTextContent(""));
          completer.done();
        });
      });
    });
    test("should support multiple content tags", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<multiple-content-tags>" +
                        "<div>B</div>" +
                        "<div>C</div>" +
                        "<div class=\"left\">A</div>" +
                        "</multiple-content-tags>",
                    directives: [MultipleContentTagsComponent]))
            .createAsync(MainComp)
            .then((main) {
          expect(main.debugElement.nativeElement, hasTextContent("(A, BC)"));
          completer.done();
        });
      });
    });
    test("should redistribute only direct children", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<multiple-content-tags>" +
                        "<div>B<div class=\"left\">A</div></div>" +
                        "<div>C</div>" +
                        "</multiple-content-tags>",
                    directives: [MultipleContentTagsComponent]))
            .createAsync(MainComp)
            .then((main) {
          expect(main.debugElement.nativeElement, hasTextContent("(, BAC)"));
          completer.done();
        });
      });
    });
    test(
        "should redistribute direct child viewcontainers when the light dom changes",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<multiple-content-tags>" +
                        "<template manual class=\"left\"><div>A1</div></template>" +
                        "<div>B</div>" +
                        "</multiple-content-tags>",
                    directives: [
                      MultipleContentTagsComponent,
                      ManualViewportDirective
                    ]))
            .createAsync(MainComp)
            .then((main) {
          var viewportDirectives = main.debugElement.children[0].childNodes
              .where(By.nodeDirective(ManualViewportDirective))
              .toList()
              .map((de) => de.inject(ManualViewportDirective))
              .toList();
          expect(main.debugElement.nativeElement, hasTextContent("(, B)"));
          viewportDirectives.forEach((d) => d.show());
          expect(main.debugElement.nativeElement, hasTextContent("(A1, B)"));
          viewportDirectives.forEach((d) => d.hide());
          expect(main.debugElement.nativeElement, hasTextContent("(, B)"));
          completer.done();
        });
      });
    });
    test("should support nested components", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<outer-with-indirect-nested>" +
                        "<div>A</div>" +
                        "<div>B</div>" +
                        "</outer-with-indirect-nested>",
                    directives: [OuterWithIndirectNestedComponent]))
            .createAsync(MainComp)
            .then((main) {
          expect(main.debugElement.nativeElement,
              hasTextContent("OUTER(SIMPLE(AB))"));
          completer.done();
        });
      });
    });
    test(
        "should support nesting with content being direct child of a nested "
        "component", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<outer>" +
                        "<template manual class=\"left\"><div>A</div></template>" +
                        "<div>B</div>" +
                        "<div>C</div>" +
                        "</outer>",
                    directives: [OuterComponent, ManualViewportDirective]))
            .createAsync(MainComp)
            .then((main) {
          var viewportDirective = main.debugElement
              .queryAllNodes(By.nodeDirective(ManualViewportDirective))[0]
              .inject(ManualViewportDirective);
          expect(main.debugElement.nativeElement,
              hasTextContent("OUTER(INNER(INNERINNER(,BC)))"));
          viewportDirective.show();
          expect(main.debugElement.nativeElement,
              hasTextContent("OUTER(INNER(INNERINNER(A,BC)))"));
          completer.done();
        });
      });
    });
    test("should redistribute when the shadow dom changes", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<conditional-content>" +
                        "<div class=\"left\">A</div>" +
                        "<div>B</div>" +
                        "<div>C</div>" +
                        "</conditional-content>",
                    directives: [ConditionalContentComponent]))
            .createAsync(MainComp)
            .then((main) {
          var viewportDirective = main.debugElement
              .queryAllNodes(By.nodeDirective(ManualViewportDirective))[0]
              .inject(ManualViewportDirective);
          expect(main.debugElement.nativeElement, hasTextContent("(, BC)"));
          viewportDirective.show();
          expect(main.debugElement.nativeElement, hasTextContent("(A, BC)"));
          viewportDirective.hide();
          expect(main.debugElement.nativeElement, hasTextContent("(, BC)"));
          completer.done();
        });
      });
    });
    // GH-2095 - https://github.com/angular/angular/issues/2095
    // important as we are removing the ng-content element during compilation,
    // which could skrew up text node indices.
    test("should support text nodes after content tags", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<simple stringProp=\"text\"></simple>",
                    directives: [Simple]))
            .overrideTemplate(
                Simple, "<ng-content></ng-content><p>P,</p>{{stringProp}}")
            .createAsync(MainComp)
            .then((ComponentFixture main) {
          main.detectChanges();
          expect(main.debugElement.nativeElement, hasTextContent("P,text"));
          completer.done();
        });
      });
    });
    // important as we are moving style tags around during compilation,
    // which could skrew up text node indices.
    test("should support text nodes after style tags", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<simple stringProp=\"text\"></simple>",
                    directives: [Simple]))
            .overrideTemplate(Simple, "<style></style><p>P,</p>{{stringProp}}")
            .createAsync(MainComp)
            .then((ComponentFixture main) {
          main.detectChanges();
          expect(main.debugElement.nativeElement, hasTextContent("P,text"));
          completer.done();
        });
      });
    });
    test("should support moving non projected light dom around", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<empty>" +
                        "  <template manual><div>A</div></template>" +
                        "</empty>" +
                        "START(<div project></div>)END",
                    directives: [
                      Empty,
                      ProjectDirective,
                      ManualViewportDirective
                    ]))
            .createAsync(MainComp)
            .then((main) {
          var sourceDirective;
          // We can't use the child nodes to get a hold of this because it's not in the dom at

          // all.
          getAllDebugNodes().forEach((debug) {
            if (!identical(
                debug.providerTokens.indexOf(ManualViewportDirective), -1)) {
              sourceDirective = debug.inject(ManualViewportDirective);
            }
          });
          ProjectDirective projectDirective = main.debugElement
              .queryAllNodes(By.nodeDirective(ProjectDirective))[0]
              .inject(ProjectDirective);
          expect(main.debugElement.nativeElement, hasTextContent("START()END"));
          projectDirective.show(sourceDirective.templateRef);
          expect(
              main.debugElement.nativeElement, hasTextContent("START(A)END"));
          completer.done();
        });
      });
    });
    test("should support moving projected light dom around", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template:
                        "<simple><template manual><div>A</div></template></simple>" +
                            "START(<div project></div>)END",
                    directives: [
                      Simple,
                      ProjectDirective,
                      ManualViewportDirective
                    ]))
            .createAsync(MainComp)
            .then((main) {
          ManualViewportDirective sourceDirective = main.debugElement
              .queryAllNodes(By.nodeDirective(ManualViewportDirective))[0]
              .inject(ManualViewportDirective);
          ProjectDirective projectDirective = main.debugElement
              .queryAllNodes(By.nodeDirective(ProjectDirective))[0]
              .inject(ProjectDirective);
          expect(main.debugElement.nativeElement,
              hasTextContent("SIMPLE()START()END"));
          projectDirective.show(sourceDirective.templateRef);
          expect(main.debugElement.nativeElement,
              hasTextContent("SIMPLE()START(A)END"));
          completer.done();
        });
      });
    });
    test("should support moving ng-content around", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<conditional-content>" +
                        "<div class=\"left\">A</div>" +
                        "<div>B</div>" +
                        "</conditional-content>" +
                        "START(<div project></div>)END",
                    directives: [
                      ConditionalContentComponent,
                      ProjectDirective,
                      ManualViewportDirective
                    ]))
            .createAsync(MainComp)
            .then((main) {
          ManualViewportDirective sourceDirective = main.debugElement
              .queryAllNodes(By.nodeDirective(ManualViewportDirective))[0]
              .inject(ManualViewportDirective);
          ProjectDirective projectDirective = main.debugElement
              .queryAllNodes(By.nodeDirective(ProjectDirective))[0]
              .inject(ProjectDirective);
          expect(main.debugElement.nativeElement,
              hasTextContent("(, B)START()END"));
          projectDirective.show(sourceDirective.templateRef);
          expect(main.debugElement.nativeElement,
              hasTextContent("(, B)START(A)END"));
          // Stamping ng-content multiple times should not produce the content multiple

          // times...
          projectDirective.show(sourceDirective.templateRef);
          expect(main.debugElement.nativeElement,
              hasTextContent("(, B)START(A)END"));
          completer.done();
        });
      });
    });

    // Note: This does not use a ng-content element, but
    // is still important as we are merging proto views independent of
    // the presence of ng-content elements!
    test("should still allow to implement a recursive trees", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(MainComp,
                new View(template: "<tree></tree>", directives: [Tree]))
            .createAsync(MainComp)
            .then((main) {
          main.detectChanges();
          ManualViewportDirective manualDirective = main.debugElement
              .queryAllNodes(By.nodeDirective(ManualViewportDirective))[0]
              .inject(ManualViewportDirective);
          expect(main.debugElement.nativeElement, hasTextContent("TREE(0:)"));
          manualDirective.show();
          main.detectChanges();
          expect(main.debugElement.nativeElement,
              hasTextContent("TREE(0:TREE(1:))"));
          completer.done();
        });
      });
    });
    // Note: This does not use a ng-content element, but
    // is still important as we are merging proto views independent of
    // the presence of ng-content elements!
    test(
        "should still allow to implement a recursive trees via multiple components",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(MainComp,
                new View(template: "<tree></tree>", directives: [Tree]))
            .overrideView(
                Tree,
                new View(
                    template:
                        "TREE({{depth}}:<tree2 *manual [depth]=\"depth+1\"></tree2>)",
                    directives: [Tree2, ManualViewportDirective]))
            .createAsync(MainComp)
            .then((main) {
          main.detectChanges();
          expect(main.debugElement.nativeElement, hasTextContent("TREE(0:)"));
          var tree = main.debugElement.query(By.directive(Tree));
          ManualViewportDirective manualDirective = tree
              .queryAllNodes(By.nodeDirective(ManualViewportDirective))[0]
              .inject(ManualViewportDirective);
          manualDirective.show();
          main.detectChanges();
          expect(main.debugElement.nativeElement,
              hasTextContent("TREE(0:TREE2(1:))"));
          var tree2 = main.debugElement.query(By.directive(Tree2));
          manualDirective = tree2
              .queryAllNodes(By.nodeDirective(ManualViewportDirective))[0]
              .inject(ManualViewportDirective);
          manualDirective.show();
          main.detectChanges();
          expect(main.debugElement.nativeElement,
              hasTextContent("TREE(0:TREE2(1:TREE(2:)))"));
          completer.done();
        });
      });
    });
    test("should support non emulated styles", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<div class=\"redStyle\"></div>",
                    styles: [".redStyle { color: red}"],
                    encapsulation: ViewEncapsulation.None,
                    directives: [OtherComp]))
            .createAsync(MainComp)
            .then((main) {
          var mainEl = main.debugElement.nativeElement;
          var div1 = DOM.firstChild(mainEl);
          var div2 = DOM.createElement("div");
          DOM.setAttribute(div2, "class", "redStyle");
          DOM.appendChild(mainEl, div2);
          expect(DOM.getComputedStyle(div1).color, "rgb(255, 0, 0)");
          expect(DOM.getComputedStyle(div2).color, "rgb(255, 0, 0)");
          completer.done();
        });
      });
    });
    test("should support emulated style encapsulation", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<div></div>",
                    styles: ["div { color: red}"],
                    encapsulation: ViewEncapsulation.Emulated))
            .createAsync(MainComp)
            .then((main) {
          var mainEl = main.debugElement.nativeElement;
          var div1 = DOM.firstChild(mainEl);
          var div2 = DOM.createElement("div");
          DOM.appendChild(mainEl, div2);
          expect(DOM.getComputedStyle(div1).color, "rgb(255, 0, 0)");
          expect(DOM.getComputedStyle(div2).color, "rgb(0, 0, 0)");
          completer.done();
        });
      });
    });
    test("should support nested conditionals that contain ng-contents",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: '<conditional-text>a</conditional-text>',
                    directives: [ConditionalTextComponent]))
            .createAsync(MainComp)
            .then((main) {
          expect(main.debugElement.nativeElement, hasTextContent("MAIN()"));
          var viewportElement = main.debugElement
              .queryAllNodes(By.nodeDirective(ManualViewportDirective))[0];
          viewportElement.inject(ManualViewportDirective).show();
          expect(
              main.debugElement.nativeElement, hasTextContent("MAIN(FIRST())"));
          viewportElement = main.debugElement
              .queryAllNodes(By.nodeDirective(ManualViewportDirective))[1];
          viewportElement.inject(ManualViewportDirective).show();
          expect(main.debugElement.nativeElement,
              hasTextContent("MAIN(FIRST(SECOND(a)))"));
          completer.done();
        });
      });
    });
    test("should allow to switch the order of nested components via ng-content",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: '''<cmp-a><cmp-b></cmp-b></cmp-a>''',
                    directives: [CmpA, CmpB]))
            .createAsync(MainComp)
            .then((main) {
          main.detectChanges();
          expect(
              DOM.getInnerHTML(main.debugElement.nativeElement),
              "<cmp-a><cmp-b><cmp-d><d>cmp-d</d></cmp-d></cmp-b>" +
                  "<cmp-c><c>cmp-c</c></cmp-c></cmp-a>");
          completer.done();
        });
      });
    });
    test("should create nested components in the right order", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: '''<cmp-a1></cmp-a1><cmp-a2></cmp-a2>''',
                    directives: [CmpA1, CmpA2]))
            .createAsync(MainComp)
            .then((main) {
          main.detectChanges();
          expect(
              DOM.getInnerHTML(main.debugElement.nativeElement),
              "<cmp-a1>a1<cmp-b11>b11</cmp-b11><cmp-b12>b12</cmp-b12></cmp-a1>" +
                  "<cmp-a2>a2<cmp-b21>b21</cmp-b21><cmp-b22>b22</cmp-b22></cmp-a2>");
          completer.done();
        });
      });
    });
    test("should project filled view containers into a view container",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MainComp,
                new View(
                    template: "<conditional-content>" +
                        "<div class=\"left\">A</div>" +
                        "<template manual class=\"left\">B</template>" +
                        "<div class=\"left\">C</div>" +
                        "<div>D</div>" +
                        "</conditional-content>",
                    directives: [
                      ConditionalContentComponent,
                      ManualViewportDirective
                    ]))
            .createAsync(MainComp)
            .then((main) {
          var conditionalComp = main.debugElement
              .query(By.directive(ConditionalContentComponent));
          var viewViewportDir = conditionalComp
              .queryAllNodes(By.nodeDirective(ManualViewportDirective))[0]
              .inject(ManualViewportDirective);
          expect(main.debugElement.nativeElement, hasTextContent("(, D)"));
          expect(main.debugElement.nativeElement, hasTextContent("(, D)"));
          viewViewportDir.show();
          expect(main.debugElement.nativeElement, hasTextContent("(AC, D)"));
          var contentViewportDir = conditionalComp
              .queryAllNodes(By.nodeDirective(ManualViewportDirective))[1]
              .inject(ManualViewportDirective);
          contentViewportDir.show();
          expect(main.debugElement.nativeElement, hasTextContent("(ABC, D)"));
          // hide view viewport, and test that it also hides

          // the content viewport's views
          viewViewportDir.hide();
          expect(main.debugElement.nativeElement, hasTextContent("(, D)"));
          completer.done();
        });
      });
    });
  });
}

@Component(selector: "main", template: "", directives: const [])
class MainComp {
  String text = "";
}

@Component(selector: "other", template: "", directives: const [])
class OtherComp {
  String text = "";
}

@Component(
    selector: "simple",
    inputs: const ["stringProp"],
    template: "SIMPLE(<ng-content></ng-content>)",
    directives: const [])
class Simple {
  String stringProp = "";
}

@Component(
    selector: "simple-native1",
    template: "SIMPLE1(<content></content>)",
    directives: const [],
    encapsulation: ViewEncapsulation.Native,
    styles: const ["div {color: red}"])
class SimpleNative1 {}

@Component(
    selector: "simple-native2",
    template: "SIMPLE2(<content></content>)",
    directives: const [],
    encapsulation: ViewEncapsulation.Native,
    styles: const ["div {color: blue}"])
class SimpleNative2 {}

@Component(selector: "empty", template: "", directives: const [])
class Empty {}

@Component(
    selector: "multiple-content-tags",
    template:
        "(<ng-content SELECT=\".left\"></ng-content>, <ng-content></ng-content>)",
    directives: const [])
class MultipleContentTagsComponent {}

@Directive(selector: "[manual]")
class ManualViewportDirective {
  ViewContainerRef vc;
  TemplateRef templateRef;
  ManualViewportDirective(this.vc, this.templateRef);
  void show() {
    this.vc.insertEmbeddedView(this.templateRef, 0);
  }

  void hide() {
    this.vc.clear();
  }
}

@Directive(selector: "[project]")
class ProjectDirective {
  ViewContainerRef vc;
  ProjectDirective(this.vc);
  void show(TemplateRef templateRef) {
    this.vc.insertEmbeddedView(templateRef, 0);
  }

  void hide() {
    this.vc.clear();
  }
}

@Component(
    selector: "outer-with-indirect-nested",
    template: "OUTER(<simple><div><ng-content></ng-content></div></simple>)",
    directives: const [Simple])
class OuterWithIndirectNestedComponent {}

@Component(
    selector: "outer",
    template:
        "OUTER(<inner><ng-content select=\".left\" class=\"left\"></ng-content><ng-content></ng-content></inner>)",
    directives: const [InnerComponent])
class OuterComponent {}

@Component(
    selector: "inner",
    template:
        "INNER(<innerinner><ng-content select=\".left\" class=\"left\"></ng-content><ng-content></ng-content></innerinner>)",
    directives: const [InnerInnerComponent])
class InnerComponent {}

@Component(
    selector: "innerinner",
    template:
        "INNERINNER(<ng-content select=\".left\"></ng-content>,<ng-content></ng-content>)",
    directives: const [])
class InnerInnerComponent {}

@Component(
    selector: "conditional-content",
    template:
        "<div>(<div *manual><ng-content select=\".left\"></ng-content></div>, <ng-content></ng-content>)</div>",
    directives: const [ManualViewportDirective])
class ConditionalContentComponent {}

@Component(
    selector: "conditional-text",
    template:
        "MAIN(<template manual>FIRST(<template manual>SECOND(<ng-content></ng-content>)</template>)</template>)",
    directives: const [ManualViewportDirective])
class ConditionalTextComponent {}

@Component(
    selector: "tab",
    template: "<div><div *manual>TAB(<ng-content></ng-content>)</div></div>",
    directives: const [ManualViewportDirective])
class Tab {}

@Component(
    selector: "tree2",
    inputs: const ["depth"],
    template: "TREE2({{depth}}:<tree *manual [depth]=\"depth+1\"></tree>)",
    directives: const [ManualViewportDirective, Tree])
class Tree2 {
  var depth = 0;
}

@Component(
    selector: "tree",
    inputs: const ["depth"],
    template: "TREE({{depth}}:<tree *manual [depth]=\"depth+1\"></tree>)",
    directives: const [ManualViewportDirective, Tree, Tree])
class Tree {
  var depth = 0;
}

@Component(selector: "cmp-d", template: '''<d>{{tagName}}</d>''')
class CmpD {
  String tagName;
  CmpD(ElementRef elementRef) {
    this.tagName = DOM.tagName(elementRef.nativeElement).toLowerCase();
  }
}

@Component(selector: "cmp-c", template: '''<c>{{tagName}}</c>''')
class CmpC {
  String tagName;
  CmpC(ElementRef elementRef) {
    this.tagName = DOM.tagName(elementRef.nativeElement).toLowerCase();
  }
}

@Component(
    selector: "cmp-b",
    template: '''<ng-content></ng-content><cmp-d></cmp-d>''',
    directives: const [CmpD])
class CmpB {}

@Component(
    selector: "cmp-a",
    template: '''<ng-content></ng-content><cmp-c></cmp-c>''',
    directives: const [CmpC])
class CmpA {}

@Component(
    selector: "cmp-b11", template: '''{{\'b11\'}}''', directives: const [])
class CmpB11 {}

@Component(
    selector: "cmp-b12", template: '''{{\'b12\'}}''', directives: const [])
class CmpB12 {}

@Component(
    selector: "cmp-b21", template: '''{{\'b21\'}}''', directives: const [])
class CmpB21 {}

@Component(
    selector: "cmp-b22", template: '''{{\'b22\'}}''', directives: const [])
class CmpB22 {}

@Component(
    selector: "cmp-a1",
    template: '''{{\'a1\'}}<cmp-b11></cmp-b11><cmp-b12></cmp-b12>''',
    directives: const [CmpB11, CmpB12])
class CmpA1 {}

@Component(
    selector: "cmp-a2",
    template: '''{{\'a2\'}}<cmp-b21></cmp-b21><cmp-b22></cmp-b22>''',
    directives: const [CmpB21, CmpB22])
class CmpA2 {}
