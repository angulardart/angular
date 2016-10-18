@TestOn('browser && !js')
library angular2.test.core.linker.query_integration_test;

import "package:angular2/common.dart" show NgIf, NgFor;
import "package:angular2/core.dart"
    show
        Component,
        Directive,
        Injectable,
        TemplateRef,
        QueryList,
        ContentChildren,
        ViewChildren,
        ContentChild,
        ViewChild,
        AfterContentInit,
        AfterViewInit,
        AfterContentChecked,
        AfterViewChecked;
import "package:angular2/core.dart" show ViewContainerRef;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void main() {
  group("Query API", () {
    group("querying by directive type", () {
      test(
          "should contain all direct child directives in the light dom (constructor)",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<div text=\"1\"></div>" +
              "<needs-query text=\"2\"><div text=\"3\">" +
              "<div text=\"too-deep\"></div>" +
              "</div></needs-query>" +
              "<div text=\"4\"></div>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            expect(asNativeElements(view.debugElement.children),
                hasTextContent("2|3|"));
            completer.done();
          });
        });
      });
      test("should contain all direct child directives in the content dom",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-content-children #q><div text=\"foo\"></div></needs-content-children>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            var q = view.debugElement.children[0].getLocal("q");
            view.detectChanges();
            expect(q.textDirChildren.length, 1);
            expect(q.numberOfChildrenAfterContentInit, 1);
            completer.done();
          });
        });
      });
      test("should contain the first content child", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-content-child #q><div *ngIf=\"shouldShow\" text=\"foo\"></div></needs-content-child>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.debugElement.componentInstance.shouldShow = true;
            view.detectChanges();
            NeedsContentChild q = view.debugElement.children[0].getLocal("q");
            expect(q.log, [
              ["setter", "foo"],
              ["init", "foo"],
              ["check", "foo"]
            ]);
            view.debugElement.componentInstance.shouldShow = false;
            view.detectChanges();
            expect(q.log, [
              ["setter", "foo"],
              ["init", "foo"],
              ["check", "foo"],
              ["setter", null],
              ["check", null]
            ]);
            completer.done();
          });
        });
      });
      test("should contain the first view child", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-view-child #q></needs-view-child>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            NeedsViewChild q = view.debugElement.children[0].getLocal("q");
            expect(q.log, [
              ["setter", "foo"],
              ["init", "foo"],
              ["check", "foo"]
            ]);
            q.shouldShow = false;
            view.detectChanges();
            expect(q.log, [
              ["setter", "foo"],
              ["init", "foo"],
              ["check", "foo"],
              ["setter", null],
              ["check", null]
            ]);
            completer.done();
          });
        });
      });
      test(
          "should set static view and content children already after the constructor call",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-static-content-view-child #q><div text=\"contentFoo\"></div></needs-static-content-view-child>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            NeedsStaticContentAndViewChild q =
                view.debugElement.children[0].getLocal("q");
            expect(q.contentChild.text, isNull);
            expect(q.viewChild.text, isNull);
            view.detectChanges();
            expect(q.contentChild.text, "contentFoo");
            expect(q.viewChild.text, "viewFoo");
            completer.done();
          });
        });
      });
      test("should contain the first view child accross embedded views",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-view-child #q></needs-view-child>";
          tcb
              .overrideTemplate(MyComp, template)
              .overrideTemplate(NeedsViewChild,
                  "<div *ngIf=\"true\"><div *ngIf=\"shouldShow\" text=\"foo\"></div></div><div *ngIf=\"shouldShow2\" text=\"bar\"></div>")
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            NeedsViewChild q = view.debugElement.children[0].getLocal("q");
            expect(q.log, [
              ["setter", "foo"],
              ["init", "foo"],
              ["check", "foo"]
            ]);
            q.shouldShow = false;
            q.shouldShow2 = true;
            q.log = [];
            view.detectChanges();
            expect(q.log, [
              ["setter", "bar"],
              ["check", "bar"]
            ]);
            q.shouldShow = false;
            q.shouldShow2 = false;
            q.log = [];
            view.detectChanges();
            expect(q.log, [
              ["setter", null],
              ["check", null]
            ]);
            completer.done();
          });
        });
      });
      test(
          "should contain all directives in the light dom when descendants flag is used",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<div text=\"1\"></div>" +
              "<needs-query-desc text=\"2\"><div text=\"3\">" +
              "<div text=\"4\"></div>" +
              "</div></needs-query-desc>" +
              "<div text=\"5\"></div>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            expect(asNativeElements(view.debugElement.children),
                hasTextContent("2|3|4|"));
            completer.done();
          });
        });
      });
      test("should contain all directives in the light dom", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<div text=\"1\"></div>" +
              "<needs-query text=\"2\"><div text=\"3\"></div></needs-query>" +
              "<div text=\"4\"></div>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            expect(asNativeElements(view.debugElement.children),
                hasTextContent("2|3|"));
            completer.done();
          });
        });
      });
      test("should reflect dynamically inserted directives", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<div text=\"1\"></div>" +
              "<needs-query text=\"2\"><div *ngIf=\"shouldShow\" [text]=\"'3'\"></div></needs-query>" +
              "<div text=\"4\"></div>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            expect(asNativeElements(view.debugElement.children),
                hasTextContent("2|"));
            view.debugElement.componentInstance.shouldShow = true;
            view.detectChanges();
            expect(asNativeElements(view.debugElement.children),
                hasTextContent("2|3|"));
            completer.done();
          });
        });
      });
      test("should be cleanly destroyed when a query crosses view boundaries",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<div text=\"1\"></div>" +
              "<needs-query text=\"2\"><div *ngIf=\"shouldShow\" [text]=\"'3'\"></div></needs-query>" +
              "<div text=\"4\"></div>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.shouldShow = true;
            fixture.detectChanges();
            fixture.destroy();
            completer.done();
          });
        });
      });
      test("should reflect moved directives", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<div text=\"1\"></div>" +
              "<needs-query text=\"2\"><div *ngFor=\"let  i of list\" [text]=\"i\"></div></needs-query>" +
              "<div text=\"4\"></div>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            expect(asNativeElements(view.debugElement.children),
                hasTextContent("2|1d|2d|3d|"));
            view.debugElement.componentInstance.list = ["3d", "2d"];
            view.detectChanges();
            expect(asNativeElements(view.debugElement.children),
                hasTextContent("2|3d|2d|"));
            completer.done();
          });
        });
      });
    });
    group("query for TemplateRef", () {
      test("should find TemplateRefs in the light and shadow dom", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-tpl><template let-x=\"light\"></template></needs-tpl>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            NeedsTpl needsTpl = view.debugElement.children[0].inject(NeedsTpl);
            expect(
                needsTpl.vc
                    .createEmbeddedView(needsTpl.query.first)
                    .hasLocal("light"),
                isTrue);
            expect(
                needsTpl.vc
                    .createEmbeddedView(needsTpl.viewQuery.first)
                    .hasLocal("shadow"),
                isTrue);
            completer.done();
          });
        });
      });
      test("should find named TemplateRefs", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-named-tpl><template let-x=\"light\" #tpl></template></needs-named-tpl>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            NeedsNamedTpl needsTpl =
                view.debugElement.children[0].inject(NeedsNamedTpl);
            expect(
                needsTpl.vc
                    .createEmbeddedView(needsTpl.contentTpl)
                    .hasLocal("light"),
                isTrue);
            expect(
                needsTpl.vc
                    .createEmbeddedView(needsTpl.viewTpl)
                    .hasLocal("shadow"),
                isTrue);
            completer.done();
          });
        });
      });
    });
    group("read a different token", () {
      test("should contain all content children", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-content-children-read #q text=\"ca\"><div #q text=\"cb\"></div></needs-content-children-read>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            NeedsContentChildrenWithRead comp = view.debugElement.children[0]
                .inject(NeedsContentChildrenWithRead);
            expect(
                comp.textDirChildren.map((textDirective) => textDirective.text),
                ["ca", "cb"]);
            completer.done();
          });
        });
      });
      test("should contain the first content child", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-content-child-read><div #q text=\"ca\"></div></needs-content-child-read>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            NeedsContentChildWithRead comp =
                view.debugElement.children[0].inject(NeedsContentChildWithRead);
            expect(comp.textDirChild.text, "ca");
            completer.done();
          });
        });
      });
      test("should contain the first view child", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-view-child-read></needs-view-child-read>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            NeedsViewChildWithRead comp =
                view.debugElement.children[0].inject(NeedsViewChildWithRead);
            expect(comp.textDirChild.text, "va");
            completer.done();
          });
        });
      });
      test("should contain all child directives in the view", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-view-children-read></needs-view-children-read>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            NeedsViewChildrenWithRead comp =
                view.debugElement.children[0].inject(NeedsViewChildrenWithRead);
            expect(
                comp.textDirChildren.map((textDirective) => textDirective.text),
                ["va", "vb"]);
            completer.done();
          });
        });
      });
      test("should support reading a ViewContainer", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-viewcontainer-read><template>hello</template></needs-viewcontainer-read>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            NeedsViewContainerWithRead comp = view.debugElement.children[0]
                .inject(NeedsViewContainerWithRead);
            comp.createView();
            expect(view.debugElement.children[0].nativeElement,
                hasTextContent("hello"));
            completer.done();
          });
        });
      });
    });
    group("changes", () {
      test("should notify query on change", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-query #q>" +
              "<div text=\"1\"></div>" +
              "<div *ngIf=\"shouldShow\" text=\"2\"></div>" +
              "</needs-query>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            var q = view.debugElement.children[0].getLocal("q");
            view.detectChanges();
            q.query.changes.listen((_) {
              expect(q.query.first.text, "1");
              expect(q.query.last.text, "2");
              completer.done();
            });
            view.debugElement.componentInstance.shouldShow = true;
            view.detectChanges();
          });
        });
      });
      test("should notify child's query before notifying parent's query",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-query-desc #q1>" +
              "<needs-query-desc #q2>" +
              "<div text=\"1\"></div>" +
              "</needs-query-desc>" +
              "</needs-query-desc>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            var q1 = view.debugElement.children[0].getLocal("q1");
            var q2 = view.debugElement.children[0].getLocal("q2");
            var firedQ2 = false;
            q2.query.changes.listen((_) {
              firedQ2 = true;
            });
            q1.query.changes.listen((_) {
              expect(firedQ2, isTrue);
              completer.done();
            });
            view.detectChanges();
          });
        });
      });
      test(
          "should correctly clean-up when destroyed together with the directives it is querying",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-query #q *ngIf=\"shouldShow\"><div text=\"foo\"></div></needs-query>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.debugElement.componentInstance.shouldShow = true;
            view.detectChanges();
            NeedsQuery q = view.debugElement.children[0].getLocal("q");
            expect(q.query.length, 1);
            view.debugElement.componentInstance.shouldShow = false;
            view.detectChanges();
            view.debugElement.componentInstance.shouldShow = true;
            view.detectChanges();
            NeedsQuery q2 = view.debugElement.children[0].getLocal("q");
            expect(q2.query.length, 1);
            completer.done();
          });
        });
      });
    });
    group("querying by var binding", () {
      test(
          "should contain all the child directives in the light dom with the given var binding",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-query-by-ref-binding #q>" +
              "<div *ngFor=\"let item of list\" [text]=\"item\" #textLabel=\"textDir\"></div>" +
              "</needs-query-by-ref-binding>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            var q = view.debugElement.children[0].getLocal("q");
            view.debugElement.componentInstance.list = ["1d", "2d"];
            view.detectChanges();
            expect(q.query.first.text, "1d");
            expect(q.query.last.text, "2d");
            completer.done();
          });
        });
      });
      test("should support querying by multiple var bindings", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-query-by-ref-bindings #q>" +
              "<div text=\"one\" #textLabel1=\"textDir\"></div>" +
              "<div text=\"two\" #textLabel2=\"textDir\"></div>" +
              "</needs-query-by-ref-bindings>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            var q = view.debugElement.children[0].getLocal("q");
            view.detectChanges();
            expect(q.query.first.text, "one");
            expect(q.query.last.text, "two");
            completer.done();
          });
        });
      });
      test("should support dynamically inserted directives", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-query-by-ref-binding #q>" +
              "<div *ngFor=\"let item of list\" [text]=\"item\" #textLabel=\"textDir\"></div>" +
              "</needs-query-by-ref-binding>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            var q = view.debugElement.children[0].getLocal("q");
            view.debugElement.componentInstance.list = ["1d", "2d"];
            view.detectChanges();
            view.debugElement.componentInstance.list = ["2d", "1d"];
            view.detectChanges();
            expect(q.query.last.text, "1d");
            completer.done();
          });
        });
      });
      test(
          "should contain all the elements in the light dom with the given var binding",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-query-by-ref-binding #q>" +
              "<div template=\"ngFor: let item of list\">" +
              "<div #textLabel>{{item}}</div>" +
              "</div>" +
              "</needs-query-by-ref-binding>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            var q = view.debugElement.children[0].getLocal("q");
            view.debugElement.componentInstance.list = ["1d", "2d"];
            view.detectChanges();
            expect(q.query.first.nativeElement, hasTextContent("1d"));
            expect(q.query.last.nativeElement, hasTextContent("2d"));
            completer.done();
          });
        });
      });
      test(
          "should contain all the elements in the light dom even if they get projected",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-query-and-project #q>" +
              "<div text=\"hello\"></div><div text=\"world\"></div>" +
              "</needs-query-and-project>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            expect(asNativeElements(view.debugElement.children),
                hasTextContent("hello|world|"));
            completer.done();
          });
        });
      });
      test("should support querying the view by using a view query", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-view-query-by-ref-binding #q></needs-view-query-by-ref-binding>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            NeedsViewQueryByLabel q =
                view.debugElement.children[0].getLocal("q");
            view.detectChanges();
            expect(q.query.first.nativeElement, hasTextContent("text"));
            completer.done();
          });
        });
      });
      test("should contain all child directives in the view dom", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-view-children #q></needs-view-children>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            var q = view.debugElement.children[0].getLocal("q");
            view.detectChanges();
            expect(q.textDirChildren.length, 1);
            expect(q.numberOfChildrenAfterViewInit, 1);
            completer.done();
          });
        });
      });
    });
    group("querying in the view", () {
      test(
          "should contain all the elements in the view with that have the given directive",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-view-query #q><div text=\"ignoreme\"></div></needs-view-query>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            NeedsViewQuery q = view.debugElement.children[0].getLocal("q");
            view.detectChanges();
            expect(
                q.query.map((TextDirective d) => d.text), ["1", "2", "3", "4"]);
            completer.done();
          });
        });
      });
      test("should not include directive present on the host element",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-view-query #q text=\"self\"></needs-view-query>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            NeedsViewQuery q = view.debugElement.children[0].getLocal("q");
            view.detectChanges();
            expect(
                q.query.map((TextDirective d) => d.text), ["1", "2", "3", "4"]);
            completer.done();
          });
        });
      });
      test("should reflect changes in the component", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-view-query-if #q></needs-view-query-if>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            NeedsViewQueryIf q = view.debugElement.children[0].getLocal("q");
            view.detectChanges();
            expect(q.query, hasLength(0));
            q.show = true;
            view.detectChanges();
            expect(q.query, hasLength(1));
            expect(q.query.first.text, "1");
            completer.done();
          });
        });
      });
      test("should not be affected by other changes in the component",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-view-query-nested-if #q></needs-view-query-nested-if>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            NeedsViewQueryNestedIf q =
                view.debugElement.children[0].getLocal("q");
            view.detectChanges();
            expect(q.query.length, 1);
            expect(q.query.first.text, "1");
            q.show = false;
            view.detectChanges();
            expect(q.query.length, 1);
            expect(q.query.first.text, "1");
            completer.done();
          });
        });
      });
      test(
          "should maintain directives in pre-order depth-first DOM order after dynamic insertion",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-view-query-order #q></needs-view-query-order>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            NeedsViewQueryOrder q = view.debugElement.children[0].getLocal("q");
            view.detectChanges();
            expect(
                q.query.map((TextDirective d) => d.text), ["1", "2", "3", "4"]);
            q.list = ["-3", "2"];
            view.detectChanges();
            expect(q.query.map((TextDirective d) => d.text),
                ["1", "-3", "2", "4"]);
            completer.done();
          });
        });
      });
      test(
          "should maintain directives in pre-order depth-first DOM order after dynamic insertion",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-view-query-order-with-p #q></needs-view-query-order-with-p>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            NeedsViewQueryOrderWithParent q =
                view.debugElement.children[0].getLocal("q");
            view.detectChanges();
            expect(
                q.query.map((TextDirective d) => d.text), ["1", "2", "3", "4"]);
            q.list = ["-3", "2"];
            view.detectChanges();
            expect(q.query.map((TextDirective d) => d.text),
                ["1", "-3", "2", "4"]);
            completer.done();
          });
        });
      });
      test("should handle long ngFor cycles", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = "<needs-view-query-order #q></needs-view-query-order>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            NeedsViewQueryOrder q = view.debugElement.children[0].getLocal("q");
            // no significance to 50, just a reasonably large cycle.
            for (var i = 0; i < 50; i++) {
              var newString = i.toString();
              q.list = [newString];
              view.detectChanges();
              expect(q.query.map((TextDirective d) => d.text),
                  ["1", newString, "4"]);
            }
            completer.done();
          });
        });
      });
      test("should support more than three queries", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template =
              "<needs-four-queries #q><div text=\"1\"></div></needs-four-queries>";
          tcb
              .overrideTemplate(MyComp, template)
              .createAsync(MyComp)
              .then((view) {
            view.detectChanges();
            var q = view.debugElement.children[0].getLocal("q");
            expect(q.query1, isNotNull);
            expect(q.query2, isNotNull);
            expect(q.query3, isNotNull);
            expect(q.query4, isNotNull);
            completer.done();
          });
        });
      });
    });
  });
}

@Directive(selector: "[text]", inputs: const ["text"], exportAs: "textDir")
@Injectable()
class TextDirective {
  String text;
  TextDirective();
}

@Component(selector: "needs-content-children", template: "")
class NeedsContentChildren implements AfterContentInit {
  @ContentChildren(TextDirective)
  QueryList<TextDirective> textDirChildren;
  num numberOfChildrenAfterContentInit;
  ngAfterContentInit() {
    this.numberOfChildrenAfterContentInit = this.textDirChildren.length;
  }
}

@Component(
    selector: "needs-view-children",
    template: "<div text></div>",
    directives: const [TextDirective])
class NeedsViewChildren implements AfterViewInit {
  @ViewChildren(TextDirective)
  QueryList<TextDirective> textDirChildren;
  num numberOfChildrenAfterViewInit;
  ngAfterViewInit() {
    this.numberOfChildrenAfterViewInit = this.textDirChildren.length;
  }
}

@Component(selector: "needs-content-child", template: "")
class NeedsContentChild implements AfterContentInit, AfterContentChecked {
  TextDirective _child;
  @ContentChild(TextDirective)
  set child(value) {
    this._child = value;
    this.log.add(["setter", value != null ? value.text : null]);
  }

  get child {
    return this._child;
  }

  var log = [];
  ngAfterContentInit() {
    this.log.add(["init", child != null ? child.text : null]);
  }

  ngAfterContentChecked() {
    this.log.add(["check", child != null ? child.text : null]);
  }
}

@Component(
    selector: "needs-view-child",
    template: '''
    <div *ngIf="shouldShow" text="foo"></div>
  ''',
    directives: const [NgIf, TextDirective])
class NeedsViewChild implements AfterViewInit, AfterViewChecked {
  bool shouldShow = true;
  bool shouldShow2 = false;
  TextDirective _child;
  @ViewChild(TextDirective)
  set child(value) {
    this._child = value;
    this.log.add(["setter", value != null ? value.text : null]);
  }

  get child {
    return this._child;
  }

  var log = [];
  ngAfterViewInit() {
    this.log.add(["init", child != null ? child.text : null]);
  }

  ngAfterViewChecked() {
    this.log.add(["check", child != null ? child.text : null]);
  }
}

@Component(
    selector: "needs-static-content-view-child",
    template: '''
    <div text="viewFoo"></div>
  ''',
    directives: const [TextDirective])
class NeedsStaticContentAndViewChild {
  @ContentChild(TextDirective)
  TextDirective contentChild;
  @ViewChild(TextDirective)
  TextDirective viewChild;
}

@Directive(selector: "[dir]")
@Injectable()
class InertDirective {
  InertDirective();
}

@Component(
    selector: "needs-query",
    directives: const [NgFor, TextDirective],
    template:
        "<div text=\"ignoreme\"></div><b *ngFor=\"let  dir of query\">{{dir.text}}|</b>")
@Injectable()
class NeedsQuery {
  QueryList<TextDirective> query;
  NeedsQuery(@ContentChildren(TextDirective) QueryList<TextDirective> query) {
    this.query = query;
  }
}

@Component(selector: "needs-four-queries", template: "")
class NeedsFourQueries {
  @ContentChild(TextDirective)
  TextDirective query1;
  @ContentChild(TextDirective)
  TextDirective query2;
  @ContentChild(TextDirective)
  TextDirective query3;
  @ContentChild(TextDirective)
  TextDirective query4;
}

@Component(
    selector: "needs-query-desc",
    directives: const [NgFor],
    template: "<div *ngFor=\"let  dir of query\">{{dir.text}}|</div>")
@Injectable()
class NeedsQueryDesc {
  QueryList<TextDirective> query;
  NeedsQueryDesc(
      @ContentChildren(TextDirective, descendants: true)
          QueryList<TextDirective> query) {
    this.query = query;
  }
}

@Component(
    selector: "needs-query-by-ref-binding",
    directives: const [],
    template: "<ng-content>")
@Injectable()
class NeedsQueryByLabel {
  QueryList<dynamic> query;
  NeedsQueryByLabel(
      @ContentChildren("textLabel", descendants: true)
          QueryList<dynamic> query) {
    this.query = query;
  }
}

@Component(
    selector: "needs-view-query-by-ref-binding",
    directives: const [],
    template: "<div #textLabel>text</div>")
@Injectable()
class NeedsViewQueryByLabel {
  QueryList<dynamic> query;
  NeedsViewQueryByLabel(@ViewChildren("textLabel") QueryList<dynamic> query) {
    this.query = query;
  }
}

@Component(
    selector: "needs-query-by-ref-bindings",
    directives: const [],
    template: "<ng-content>")
@Injectable()
class NeedsQueryByTwoLabels {
  QueryList<dynamic> query;
  NeedsQueryByTwoLabels(
      @ContentChildren("textLabel1,textLabel2", descendants: true)
          QueryList<dynamic> query) {
    this.query = query;
  }
}

@Component(
    selector: "needs-query-and-project",
    directives: const [NgFor],
    template:
        "<div *ngFor=\"let  dir of query\">{{dir.text}}|</div><ng-content></ng-content>")
@Injectable()
class NeedsQueryAndProject {
  QueryList<TextDirective> query;
  NeedsQueryAndProject(
      @ContentChildren(TextDirective) QueryList<TextDirective> query) {
    this.query = query;
  }
}

@Component(
    selector: "needs-view-query",
    directives: const [TextDirective],
    template: "<div text=\"1\"><div text=\"2\"></div></div>" +
        "<div text=\"3\"></div><div text=\"4\"></div>")
@Injectable()
class NeedsViewQuery {
  QueryList<TextDirective> query;
  NeedsViewQuery(@ViewChildren(TextDirective) QueryList<TextDirective> query) {
    this.query = query;
  }
}

@Component(
    selector: "needs-view-query-if",
    directives: const [NgIf, TextDirective],
    template: "<div *ngIf=\"show\" text=\"1\"></div>")
@Injectable()
class NeedsViewQueryIf {
  bool show;
  QueryList<TextDirective> query;
  NeedsViewQueryIf(
      @ViewChildren(TextDirective) QueryList<TextDirective> query) {
    this.query = query;
    this.show = false;
  }
}

@Component(
    selector: "needs-view-query-nested-if",
    directives: const [NgIf, InertDirective, TextDirective],
    template: "<div text=\"1\"><div *ngIf=\"show\"><div dir></div></div></div>")
@Injectable()
class NeedsViewQueryNestedIf {
  bool show;
  QueryList<TextDirective> query;
  NeedsViewQueryNestedIf(
      @ViewChildren(TextDirective) QueryList<TextDirective> query) {
    this.query = query;
    this.show = true;
  }
}

@Component(
    selector: "needs-view-query-order",
    directives: const [NgFor, TextDirective, InertDirective],
    template: "<div text=\"1\"></div>" +
        "<div *ngFor=\"let  i of list\" [text]=\"i\"></div>" +
        "<div text=\"4\"></div>")
@Injectable()
class NeedsViewQueryOrder {
  QueryList<TextDirective> query;
  List<String> list;
  NeedsViewQueryOrder(
      @ViewChildren(TextDirective) QueryList<TextDirective> query) {
    this.query = query;
    this.list = ["2", "3"];
  }
}

@Component(
    selector: "needs-view-query-order-with-p",
    directives: const [NgFor, TextDirective, InertDirective],
    template: "<div dir><div text=\"1\"></div>" +
        "<div *ngFor=\"let  i of list\" [text]=\"i\"></div>" +
        "<div text=\"4\"></div></div>")
@Injectable()
class NeedsViewQueryOrderWithParent {
  QueryList<TextDirective> query;
  List<String> list;
  NeedsViewQueryOrderWithParent(
      @ViewChildren(TextDirective) QueryList<TextDirective> query) {
    this.query = query;
    this.list = ["2", "3"];
  }
}

@Component(
    selector: "needs-tpl", template: "<template let-x=\"shadow\"></template>")
class NeedsTpl {
  ViewContainerRef vc;
  QueryList<TemplateRef> viewQuery;
  QueryList<TemplateRef> query;
  NeedsTpl(@ViewChildren(TemplateRef) QueryList<TemplateRef> viewQuery,
      @ContentChildren(TemplateRef) QueryList<TemplateRef> query, this.vc) {
    this.viewQuery = viewQuery;
    this.query = query;
  }
}

@Component(
    selector: "needs-named-tpl",
    template: "<template #tpl let-x=\"shadow\"></template>")
class NeedsNamedTpl {
  ViewContainerRef vc;
  @ViewChild("tpl")
  TemplateRef viewTpl;
  @ContentChild("tpl")
  TemplateRef contentTpl;
  NeedsNamedTpl(this.vc);
}

@Component(selector: "needs-content-children-read", template: "")
class NeedsContentChildrenWithRead {
  @ContentChildren("q", read: TextDirective)
  QueryList<TextDirective> textDirChildren;
  @ContentChildren("nonExisting", read: TextDirective)
  QueryList<TextDirective> nonExistingVar;
}

@Component(selector: "needs-content-child-read", template: "")
class NeedsContentChildWithRead {
  @ContentChild("q", read: TextDirective)
  TextDirective textDirChild;
  @ContentChild("nonExisting", read: TextDirective)
  TextDirective nonExistingVar;
}

@Component(
    selector: "needs-view-children-read",
    template: "<div #q text=\"va\"></div><div #q text=\"vb\"></div>",
    directives: const [TextDirective])
class NeedsViewChildrenWithRead {
  @ViewChildren("q", read: TextDirective)
  QueryList<TextDirective> textDirChildren;
  @ViewChildren("nonExisting", read: TextDirective)
  QueryList<TextDirective> nonExistingVar;
}

@Component(
    selector: "needs-view-child-read",
    template: "<div #q text=\"va\"></div>",
    directives: const [TextDirective])
class NeedsViewChildWithRead {
  @ViewChild("q", read: TextDirective)
  TextDirective textDirChild;
  @ViewChild("nonExisting", read: TextDirective)
  TextDirective nonExistingVar;
}

@Component(selector: "needs-viewcontainer-read", template: "<div #q></div>")
class NeedsViewContainerWithRead {
  @ViewChild("q", read: ViewContainerRef)
  ViewContainerRef vc;
  @ViewChild("nonExisting", read: ViewContainerRef)
  ViewContainerRef nonExistingVar;
  @ContentChild(TemplateRef)
  TemplateRef template;
  createView() {
    this.vc.createEmbeddedView(this.template);
  }
}

@Component(
    selector: "my-comp",
    directives: const [
      NeedsQuery,
      NeedsQueryDesc,
      NeedsQueryByLabel,
      NeedsQueryByTwoLabels,
      NeedsQueryAndProject,
      NeedsViewQuery,
      NeedsViewQueryIf,
      NeedsViewQueryNestedIf,
      NeedsViewQueryOrder,
      NeedsViewQueryByLabel,
      NeedsViewQueryOrderWithParent,
      NeedsContentChildren,
      NeedsViewChildren,
      NeedsViewChild,
      NeedsStaticContentAndViewChild,
      NeedsContentChild,
      NeedsTpl,
      NeedsNamedTpl,
      TextDirective,
      InertDirective,
      NgIf,
      NgFor,
      NeedsFourQueries,
      NeedsContentChildrenWithRead,
      NeedsContentChildWithRead,
      NeedsViewChildrenWithRead,
      NeedsViewChildWithRead,
      NeedsViewContainerWithRead
    ],
    template: "")
@Injectable()
class MyComp {
  bool shouldShow;
  var list;
  MyComp() {
    this.shouldShow = false;
    this.list = ["1d", "2d", "3d"];
  }
}
