@TestOn('browser')
library angular2.test.core.linker.integration_test;

import "dart:async";

import "package:angular2/common.dart" show NgIf, NgFor;
import "package:angular2/common.dart" show AsyncPipe;
import "package:angular2/compiler.dart" show CompilerConfig;
import "package:angular2/core.dart"
    show
        Injector,
        provide,
        Injectable,
        Provider,
        OpaqueToken,
        Inject,
        Host,
        SkipSelf,
        SkipSelfMetadata,
        OnDestroy,
        ReflectiveInjector;
import "package:angular2/src/core/change_detection/change_detection.dart"
    show PipeTransform, ChangeDetectorRef, ChangeDetectionStrategy;
import "package:angular2/src/core/linker/component_resolver.dart"
    show ComponentResolver;
import "package:angular2/src/core/linker/element_ref.dart" show ElementRef;
import "package:angular2/src/core/linker/query_list.dart" show QueryList;
import "package:angular2/src/core/linker/template_ref.dart"
    show TemplateRef_, TemplateRef;
import "package:angular2/src/core/linker/view_container_ref.dart"
    show ViewContainerRef;
import "package:angular2/src/core/linker/view_ref.dart" show EmbeddedViewRef;
import "package:angular2/src/core/metadata.dart"
    show
        Directive,
        Component,
        ViewMetadata,
        Attribute,
        Query,
        Pipe,
        Input,
        Output,
        HostBinding,
        HostListener;
import "package:angular2/src/core/render.dart" show Renderer;
import "package:angular2/src/facade/async.dart"
    show PromiseWrapper, EventEmitter, ObservableWrapper, PromiseCompleter;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart"
    show isPresent, stringify, isBlank;
import "package:angular2/src/facade/lang.dart" show IS_DART;
import "package:angular2/src/platform/browser/browser_adapter.dart"
    show BrowserDomAdapter;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

const ANCHOR_ELEMENT = const OpaqueToken("AnchorElement");
main() {
  bool isJit = false;
  BrowserDomAdapter.makeCurrent();
  group("integration tests", () {
    setUp(() {
      beforeEachProviders(
          () => [provide(ANCHOR_ELEMENT, useValue: el("<div></div>"))]);
    });
    group("react to record changes", () {
      test("should consume text node changes", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp, new ViewMetadata(template: "<div>{{ctxProp}}</div>"))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.ctxProp = "Hello World!";
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent("Hello World!"));
            completer.done();
          });
        });
      });
      test(
          'should update text node with a blank string when '
          'interpolation evaluates to null', () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(MyComp,
                  new ViewMetadata(template: "<div>{{null}}{{ctxProp}}</div>"))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.ctxProp = null;
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement, hasTextContent(''));
            completer.done();
          });
        });
      });
      test("should consume element binding changes", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(MyComp,
                  new ViewMetadata(template: "<div [id]=\"ctxProp\"></div>"))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.ctxProp = "Hello World!";
            fixture.detectChanges();
            expect(fixture.debugElement.children[0].nativeElement.id,
                "Hello World!");
            completer.done();
          });
        });
      });
      test("should consume binding to aria-* attributes", () async {
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<div [attr.aria-label]=\"ctxProp\"></div>"))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.ctxProp =
                "Initial aria label";
            fixture.detectChanges();
            expect(
                DOM.getAttribute(fixture.debugElement.children[0].nativeElement,
                    "aria-label"),
                "Initial aria label");
            fixture.debugElement.componentInstance.ctxProp =
                "Changed aria label";
            fixture.detectChanges();
            expect(
                DOM.getAttribute(fixture.debugElement.children[0].nativeElement,
                    "aria-label"),
                "Changed aria label");
            completer.done();
          });
        });
      });
      test(
          "should remove an attribute when attribute expression evaluates to null",
          () async {
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<div [attr.foo]=\"ctxProp\"></div>"))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.ctxProp = "bar";
            fixture.detectChanges();
            expect(
                DOM.getAttribute(
                    fixture.debugElement.children[0].nativeElement, "foo"),
                "bar");
            fixture.debugElement.componentInstance.ctxProp = null;
            fixture.detectChanges();
            expect(
                DOM.hasAttribute(
                    fixture.debugElement.children[0].nativeElement, "foo"),
                isFalse);
            completer.done();
          });
        });
      });
      test("should remove style when when style expression evaluates to null",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<div [style.height.px]=\"ctxProp\"></div>"))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.ctxProp = "10";
            fixture.detectChanges();
            expect(
                DOM.getStyle(
                    fixture.debugElement.children[0].nativeElement, "height"),
                "10px");
            fixture.debugElement.componentInstance.ctxProp = null;
            fixture.detectChanges();
            expect(
                DOM.getStyle(
                    fixture.debugElement.children[0].nativeElement, "height"),
                '');
            completer.done();
          });
        });
      });
      test(
          "should consume binding to property names where attr name and property name do not match",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<div [tabindex]=\"ctxNumProp\"></div>"))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.detectChanges();
            expect(fixture.debugElement.children[0].nativeElement.tabIndex, 0);
            fixture.debugElement.componentInstance.ctxNumProp = 5;
            fixture.detectChanges();
            expect(fixture.debugElement.children[0].nativeElement.tabIndex, 5);
            completer.done();
          });
        });
      });
      test("should consume binding to camel-cased properties", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<input [readOnly]=\"ctxBoolProp\">"))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.detectChanges();
            expect(fixture.debugElement.children[0].nativeElement.readOnly,
                isFalse);
            fixture.debugElement.componentInstance.ctxBoolProp = true;
            fixture.detectChanges();
            expect(fixture.debugElement.children[0].nativeElement.readOnly,
                isTrue);
            completer.done();
          });
        });
      });
      test("should consume binding to innerHtml", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<div innerHtml=\"{{ctxProp}}\"></div>"))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.ctxProp =
                "Some <span>HTML</span>";
            fixture.detectChanges();
            expect(
                DOM.getInnerHTML(
                    fixture.debugElement.children[0].nativeElement),
                "Some <span>HTML</span>");
            fixture.debugElement.componentInstance.ctxProp =
                "Some other <div>HTML</div>";
            fixture.detectChanges();
            expect(
                DOM.getInnerHTML(
                    fixture.debugElement.children[0].nativeElement),
                "Some other <div>HTML</div>");
            completer.done();
          });
        });
      });
      test("should consume binding to className using class alias", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template:
                          "<div class=\"initial\" [class]=\"ctxProp\"></div>"))
              .createAsync(MyComp)
              .then((fixture) {
            var nativeEl = fixture.debugElement.children[0].nativeElement;
            fixture.debugElement.componentInstance.ctxProp = "foo bar";
            fixture.detectChanges();
            expect(DOM.hasClass(nativeEl, "foo"), isTrue);
            expect(DOM.hasClass(nativeEl, "bar"), isTrue);
            expect(DOM.hasClass(nativeEl, "initial"), isFalse);
            completer.done();
          });
        });
      });
      test("should consume directive watch expression change.", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var tpl = "<span>" +
              "<div my-dir [elprop]=\"ctxProp\"></div>" +
              "<div my-dir elprop=\"Hi there!\"></div>" +
              "<div my-dir elprop=\"Hi {{'there!'}}\"></div>" +
              "<div my-dir elprop=\"One more {{ctxProp}}\"></div>" +
              "</span>";
          tcb
              .overrideView(
                  MyComp, new ViewMetadata(template: tpl, directives: [MyDir]))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.ctxProp = "Hello World!";
            fixture.detectChanges();
            var containerSpan = fixture.debugElement.children[0];
            expect(containerSpan.children[0].inject(MyDir).dirProp,
                "Hello World!");
            expect(
                containerSpan.children[1].inject(MyDir).dirProp, "Hi there!");
            expect(
                containerSpan.children[2].inject(MyDir).dirProp, "Hi there!");
            expect(containerSpan.children[3].inject(MyDir).dirProp,
                "One more Hello World!");
            completer.done();
          });
        });
      });
      group("pipes", () {
        test("should support pipes in bindings", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<div my-dir #dir=\"mydir\" [elprop]=\"ctxProp | double\"></div>",
                        directives: [MyDir],
                        pipes: [DoublePipe]))
                .createAsync(MyComp)
                .then((fixture) {
              fixture.debugElement.componentInstance.ctxProp = "a";
              fixture.detectChanges();
              var dir = fixture.debugElement.children[0].getLocal("dir");
              expect(dir.dirProp, "aa");
              completer.done();
            });
          });
        });
      });
      test("should support nested components.", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<child-cmp></child-cmp>",
                      directives: [ChildComp]))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement, hasTextContent("hello"));
            completer.done();
          });
        });
      });
      test("should support different directive types on a single node",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template:
                          "<child-cmp my-dir [elprop]=\"ctxProp\"></child-cmp>",
                      directives: [MyDir, ChildComp]))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.ctxProp = "Hello World!";
            fixture.detectChanges();
            var tc = fixture.debugElement.children[0];
            expect(tc.inject(MyDir).dirProp, "Hello World!");
            expect(tc.inject(ChildComp).dirProp, null);
            completer.done();
          });
        });
      });
      test("should support directives where a binding attribute is not given",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<p my-dir></p>", directives: [MyDir]))
              .createAsync(MyComp)
              .then((fixture) {
            completer.done();
          });
        });
      });
      test(
          "should execute a given directive once, even if specified multiple times",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<p no-duplicate></p>",
                      directives: [
                        DuplicateDir,
                        DuplicateDir,
                        [
                          DuplicateDir,
                          [DuplicateDir]
                        ]
                      ]))
              .createAsync(MyComp)
              .then((fixture) {
            expect(fixture.debugElement.nativeElement,
                hasTextContent("noduplicate"));
            completer.done();
          });
        });
      });
      test(
          "should support directives where a selector matches property binding",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<p [id]=\"ctxProp\"></p>",
                      directives: [IdDir]))
              .createAsync(MyComp)
              .then((fixture) {
            var tc = fixture.debugElement.children[0];
            var idDir = tc.inject(IdDir);
            fixture.debugElement.componentInstance.ctxProp = "some_id";
            fixture.detectChanges();
            expect(idDir.id, "some_id");
            fixture.debugElement.componentInstance.ctxProp = "other_id";
            fixture.detectChanges();
            expect(idDir.id, "other_id");
            completer.done();
          });
        });
      });
      test("should support directives where a selector matches event binding",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<p (customEvent)=\"doNothing()\"></p>",
                      directives: [EventDir]))
              .createAsync(MyComp)
              .then((fixture) {
            var tc = fixture.debugElement.children[0];
            expect(tc.inject(EventDir), isNotNull);
            completer.done();
          });
        });
      });
      test("should read directives metadata from their binding token",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template:
                          "<div public-api><div needs-public-api></div></div>",
                      directives: [PrivateImpl, NeedsPublicApi]))
              .createAsync(MyComp)
              .then((fixture) {
            completer.done();
          });
        });
      });
      test("should support template directives via `<template>` elements.",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template:
                          "<template some-viewport let-greeting=\"some-tmpl\"><copy-me>{{greeting}}</copy-me></template>",
                      directives: [SomeViewport]))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.detectChanges();
            var childNodesOfWrapper =
                DOM.childNodes(fixture.debugElement.nativeElement);
            // 1 template + 2 copies.
            expect(childNodesOfWrapper, hasLength(3));
            expect(childNodesOfWrapper[1], hasTextContent("hello"));
            expect(childNodesOfWrapper[2], hasTextContent("again"));
            completer.done();
          });
        });
      });
      test(
          "should not detach views in ViewContainers when the parent view is destroyed.",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template:
                          "<div *ngIf=\"ctxBoolProp\"><template some-viewport let-greeting=\"someTmpl\"><span>{{greeting}}</span></template></div>",
                      directives: [SomeViewport, NgIf]))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.ctxBoolProp = true;
            fixture.detectChanges();
            var ngIfEl = fixture.debugElement.children[0];
            SomeViewport someViewport =
                ngIfEl.childNodes[0].inject(SomeViewport);
            expect(someViewport.container, hasLength(2));
            expect(ngIfEl.children, hasLength(2));
            fixture.debugElement.componentInstance.ctxBoolProp = false;
            fixture.detectChanges();
            expect(someViewport.container, hasLength(2));
            expect(fixture.debugElement.children, hasLength(0));
            completer.done();
          });
        });
      });
      test("should use a comment while stamping out `<template>` elements.",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp, new ViewMetadata(template: "<template></template>"))
              .createAsync(MyComp)
              .then((fixture) {
            var childNodesOfWrapper =
                DOM.childNodes(fixture.debugElement.nativeElement);
            expect(childNodesOfWrapper, hasLength(1));
            expect(DOM.isCommentNode(childNodesOfWrapper[0]), isTrue);
            completer.done();
          });
        });
      });
      test("should support template directives via `template` attribute.",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template:
                          "<copy-me template=\"some-viewport: let greeting=some-tmpl\">{{greeting}}</copy-me>",
                      directives: [SomeViewport]))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.detectChanges();
            var childNodesOfWrapper =
                DOM.childNodes(fixture.debugElement.nativeElement);
            // 1 template + 2 copies.
            expect(childNodesOfWrapper, hasLength(3));
            expect(childNodesOfWrapper[1], hasTextContent("hello"));
            expect(childNodesOfWrapper[2], hasTextContent("again"));
            completer.done();
          });
        });
      });
      test("should allow to transplant TemplateRefs into other ViewContainers",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template:
                          "<some-directive><toolbar><template toolbarpart let-toolbarProp=\"toolbarProp\">{{ctxProp}},{{toolbarProp}},<cmp-with-host></cmp-with-host></template></toolbar></some-directive>",
                      directives: [
                        SomeDirective,
                        CompWithHost,
                        ToolbarComponent,
                        ToolbarPart
                      ]))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.debugElement.componentInstance.ctxProp = "From myComp";
            fixture.detectChanges();
            expect(
                fixture.debugElement.nativeElement,
                hasTextContent(
                    "TOOLBAR(From myComp,From toolbar,Component with an injected host)"));
            completer.done();
          });
        });
      });
      group("reference bindings", () {
        test("should assign a component to a ref-", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<p><child-cmp ref-alice></child-cmp></p>",
                        directives: [ChildComp]))
                .createAsync(MyComp)
                .then((fixture) {
              expect(
                  fixture.debugElement.children[0].children[0]
                      .getLocal("alice"),
                  new isInstanceOf<ChildComp>());
              completer.done();
            });
          });
        });
        test("should assign a directive to a ref-", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<div><div export-dir #localdir=\"dir\"></div></div>",
                        directives: [ExportDir]))
                .createAsync(MyComp)
                .then((fixture) {
              expect(
                  fixture.debugElement.children[0].children[0]
                      .getLocal("localdir"),
                  new isInstanceOf<ExportDir>());
              completer.done();
            });
          });
        });
        test(
            'should make the assigned component accessible '
            'in property bindings, even if they were declared before the component',
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<template [ngIf]=\"true\">{{alice.ctxProp}}</template>|{{alice.ctxProp}}|<child-cmp ref-alice></child-cmp>",
                        directives: [ChildComp, NgIf]))
                .createAsync(MyComp)
                .then((fixture) {
              fixture.detectChanges();
              expect(fixture.debugElement.nativeElement,
                  hasTextContent("hello|hello|hello"));
              completer.done();
            });
          });
        });
        test("should assign two component instances each with a ref-",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<p><child-cmp ref-alice></child-cmp><child-cmp ref-bob></child-cmp></p>",
                        directives: [ChildComp]))
                .createAsync(MyComp)
                .then((fixture) {
              var childCmp = fixture.debugElement.children[0].children[0];
              expect(childCmp.getLocal("alice"), new isInstanceOf<ChildComp>());
              expect(childCmp.getLocal("bob"), new isInstanceOf<ChildComp>());
              expect(childCmp.getLocal("alice") != childCmp.getLocal("bob"),
                  isTrue);
              completer.done();
            });
          });
        });
        test(
            "should assign the component instance to a ref- with shorthand syntax",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<child-cmp #alice></child-cmp>",
                        directives: [ChildComp]))
                .createAsync(MyComp)
                .then((fixture) {
              expect(fixture.debugElement.children[0].getLocal("alice"),
                  new isInstanceOf<ChildComp>());
              completer.done();
            });
          });
        });
        test("should assign the element instance to a user-defined variable",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<div><div ref-alice><i>Hello</i></div></div>"))
                .createAsync(MyComp)
                .then((fixture) {
              var value = fixture.debugElement.children[0].children[0]
                  .getLocal("alice");
              expect(value, isNotNull);
              expect(value.tagName.toLowerCase(), "div");
              completer.done();
            });
          });
        });
        test("should assign the TemplateRef to a user-defined variable",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<template ref-alice></template>"))
                .createAsync(MyComp)
                .then((fixture) {
              var value = fixture.debugElement.childNodes[0].getLocal("alice");
              expect(value, new isInstanceOf<TemplateRef_>());
              completer.done();
            });
          });
        });
        test("should preserve case", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<p><child-cmp ref-superAlice></child-cmp></p>",
                        directives: [ChildComp]))
                .createAsync(MyComp)
                .then((fixture) {
              expect(
                  fixture.debugElement.children[0].children[0]
                      .getLocal("superAlice"),
                  new isInstanceOf<ChildComp>());
              completer.done();
            });
          });
        });
      });
      group("variables", () {
        test("should allow to use variables in a for loop", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<template ngFor [ngForOf]=\"[1]\" let-i><child-cmp-no-template #cmp></child-cmp-no-template>{{i}}-{{cmp.ctxProp}}</template>",
                        directives: [ChildCompNoTemplate, NgFor]))
                .createAsync(MyComp)
                .then((fixture) {
              fixture.detectChanges();
              // Get the element at index 2, since index 0 is the <template>.
              expect(DOM.childNodes(fixture.debugElement.nativeElement)[2],
                  hasTextContent("1-hello"));
              completer.done();
            });
          });
        });
      });
      group("OnPush components", () {
        test("should use ChangeDetectorRef to manually request a check",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<push-cmp-with-ref #cmp></push-cmp-with-ref>",
                        directives: [
                          [
                            [PushCmpWithRef]
                          ]
                        ]))
                .createAsync(MyComp)
                .then((fixture) {
              var cmp = fixture.debugElement.children[0].getLocal("cmp");
              fixture.detectChanges();
              expect(cmp.numberOfChecks, 1);
              fixture.detectChanges();
              expect(cmp.numberOfChecks, 1);
              cmp.propagate();
              fixture.detectChanges();
              expect(cmp.numberOfChecks, 2);
              completer.done();
            });
          });
        });
        test("should be checked when its bindings got updated", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<push-cmp [prop]=\"ctxProp\" #cmp></push-cmp>",
                        directives: [
                          [
                            [PushCmp]
                          ]
                        ]))
                .createAsync(MyComp)
                .then((fixture) {
              var cmp = fixture.debugElement.children[0].getLocal("cmp");
              fixture.debugElement.componentInstance.ctxProp = "one";
              fixture.detectChanges();
              expect(cmp.numberOfChecks, 1);
              fixture.debugElement.componentInstance.ctxProp = "two";
              fixture.detectChanges();
              expect(cmp.numberOfChecks, 2);
              completer.done();
            });
          });
        });
        test(
            "should allow to destroy a component from within a host event handler",
            fakeAsync(() {
          inject([TestComponentBuilder], (TestComponentBuilder tcb) {
            ComponentFixture fixture;
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<push-cmp-with-host-event></push-cmp-with-host-event>",
                        directives: [
                          [
                            [PushCmpWithHostEvent]
                          ]
                        ]))
                .createAsync(MyComp)
                .then((root) {
              fixture = root;
            });
            tick();
            fixture.detectChanges();
            var cmpEl = fixture.debugElement.children[0];
            PushCmpWithHostEvent cmp = cmpEl.inject(PushCmpWithHostEvent);
            cmp.ctxCallback = (_) => fixture.destroy();
            // Should not throw.
            cmpEl.triggerEventHandler("click", {});
          });
        }));

        test("should be checked when an event is fired", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<push-cmp [prop]=\"ctxProp\" #cmp></push-cmp>",
                        directives: [
                          [
                            [PushCmp]
                          ]
                        ]))
                .createAsync(MyComp)
                .then((fixture) {
              var cmpEl = fixture.debugElement.children[0];
              var cmp = cmpEl.componentInstance;
              fixture.detectChanges();
              fixture.detectChanges();
              expect(cmp.numberOfChecks, 1);
              cmpEl.children[0].triggerEventHandler("click", {});
              // regular element
              fixture.detectChanges();
              fixture.detectChanges();
              expect(cmp.numberOfChecks, 2);
              // element inside of an *ngIf
              cmpEl.children[1].triggerEventHandler("click", {});
              fixture.detectChanges();
              fixture.detectChanges();
              expect(cmp.numberOfChecks, 3);
              // element inside a nested component
              cmpEl.children[2].children[0].triggerEventHandler("click", {});
              fixture.detectChanges();
              fixture.detectChanges();
              expect(cmp.numberOfChecks, 4);
              completer.done();
            });
          });
        });
        test("should not affect updating properties on the component",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<push-cmp-with-ref [prop]=\"ctxProp\" #cmp></push-cmp-with-ref>",
                        directives: [
                          [
                            [PushCmpWithRef]
                          ]
                        ]))
                .createAsync(MyComp)
                .then((fixture) {
              var cmp = fixture.debugElement.children[0].getLocal("cmp");
              fixture.debugElement.componentInstance.ctxProp = "one";
              fixture.detectChanges();
              expect(cmp.prop, "one");
              fixture.debugElement.componentInstance.ctxProp = "two";
              fixture.detectChanges();
              expect(cmp.prop, "two");
              completer.done();
            });
          });
        });
        test("should be checked when an async pipe requests a check",
            fakeAsync(() {
          inject([TestComponentBuilder], (TestComponentBuilder tcb) {
            tcb = tcb.overrideView(
                MyComp,
                new ViewMetadata(
                    template:
                        "<push-cmp-with-async #cmp></push-cmp-with-async>",
                    directives: [
                      [
                        [PushCmpWithAsyncPipe]
                      ]
                    ]));
            ComponentFixture fixture;
            tcb.createAsync(MyComp).then((root) {
              fixture = root;
            });
            tick();
            PushCmpWithAsyncPipe cmp =
                fixture.debugElement.children[0].getLocal("cmp");
            fixture.detectChanges();
            expect(cmp.numberOfChecks, 1);
            fixture.detectChanges();
            fixture.detectChanges();
            expect(cmp.numberOfChecks, 1);
            cmp.resolve(2);
            tick();
            fixture.detectChanges();
            expect(cmp.numberOfChecks, 2);
          });
        }));

        test("should create a component that injects an @Host", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: '''
            <some-directive>
              <p>
                <cmp-with-host #child></cmp-with-host>
              </p>
            </some-directive>''',
                        directives: [SomeDirective, CompWithHost]))
                .createAsync(MyComp)
                .then((fixture) {
              var childComponent =
                  fixture.debugElement.children[0].getLocal("child");
              expect(childComponent.myHost, new isInstanceOf<SomeDirective>());
              completer.done();
            });
          });
        });
        test(
            'should create a component that injects an @Host '
            'through viewcontainer directive', () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: '''
            <some-directive>
              <p *ngIf="true">
                <cmp-with-host #child></cmp-with-host>
              </p>
            </some-directive>''',
                        directives: [SomeDirective, CompWithHost, NgIf]))
                .createAsync(MyComp)
                .then((fixture) {
              fixture.detectChanges();
              var tc = fixture.debugElement.children[0].children[0].children[0];
              var childComponent = tc.getLocal("child");
              expect(childComponent.myHost, new isInstanceOf<SomeDirective>());
              completer.done();
            });
          });
        });
        test("should support events via EventEmitter on regular elements",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div emitter listener></div>",
                        directives: [
                          DirectiveEmittingEvent,
                          DirectiveListeningEvent
                        ]))
                .createAsync(MyComp)
                .then((fixture) {
              var tc = fixture.debugElement.children[0];
              var emitter = tc.inject(DirectiveEmittingEvent);
              var listener = tc.inject(DirectiveListeningEvent);
              expect(listener.msg, "");
              var eventCount = 0;
              ObservableWrapper.subscribe(emitter.event, (_) {
                eventCount++;
                if (identical(eventCount, 1)) {
                  expect(listener.msg, "fired !");
                  fixture.destroy();
                  emitter.fireEvent("fired again !");
                } else {
                  expect(listener.msg, "fired !");
                  completer.done();
                }
              });
              emitter.fireEvent("fired !");
            });
          });
        });
        test("should support events via EventEmitter on template elements",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<template emitter listener (event)=\"ctxProp=\$event\"></template>",
                        directives: [
                          DirectiveEmittingEvent,
                          DirectiveListeningEvent
                        ]))
                .createAsync(MyComp)
                .then((fixture) {
              var tc = fixture.debugElement.childNodes[0];
              var emitter = tc.inject(DirectiveEmittingEvent);
              var myComp = fixture.debugElement.inject(MyComp);
              var listener = tc.inject(DirectiveListeningEvent);
              myComp.ctxProp = "";
              expect(listener.msg, "");
              ObservableWrapper.subscribe(emitter.event, (_) {
                expect(listener.msg, "fired !");
                expect(myComp.ctxProp, "fired !");
                completer.done();
              });
              emitter.fireEvent("fired !");
            });
          });
        });
        test("should support [()] syntax", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div [(control)]=\"ctxProp\" two-way></div>",
                        directives: [DirectiveWithTwoWayBinding]))
                .createAsync(MyComp)
                .then((fixture) {
              var tc = fixture.debugElement.children[0];
              var dir = tc.inject(DirectiveWithTwoWayBinding);
              fixture.debugElement.componentInstance.ctxProp = "one";
              fixture.detectChanges();
              expect(dir.control, "one");
              ObservableWrapper.subscribe(dir.controlChange, (_) {
                expect(fixture.debugElement.componentInstance.ctxProp, "two");
                completer.done();
              });
              dir.triggerChange("two");
            });
          });
        });
        test("should support render events", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div listener></div>",
                        directives: [DirectiveListeningDomEvent]))
                .createAsync(MyComp)
                .then((fixture) {
              var tc = fixture.debugElement.children[0];
              var listener = tc.inject(DirectiveListeningDomEvent);
              dispatchEvent(tc.nativeElement, "domEvent");
              expect(listener.eventTypes, [
                "domEvent",
                "body_domEvent",
                "document_domEvent",
                "window_domEvent"
              ]);
              fixture.destroy();
              listener.eventTypes = [];
              dispatchEvent(tc.nativeElement, "domEvent");
              expect(listener.eventTypes, []);
              completer.done();
            });
          });
        });
        test("should support render global events", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div listener></div>",
                        directives: [DirectiveListeningDomEvent]))
                .createAsync(MyComp)
                .then((fixture) {
              var tc = fixture.debugElement.children[0];
              var listener = tc.inject(DirectiveListeningDomEvent);
              dispatchEvent(DOM.getGlobalEventTarget("window"), "domEvent");
              expect(listener.eventTypes, ["window_domEvent"]);
              listener.eventTypes = [];
              dispatchEvent(DOM.getGlobalEventTarget("document"), "domEvent");
              expect(listener.eventTypes,
                  ["document_domEvent", "window_domEvent"]);
              fixture.destroy();
              listener.eventTypes = [];
              dispatchEvent(DOM.getGlobalEventTarget("body"), "domEvent");
              expect(listener.eventTypes, []);
              completer.done();
            });
          });
        });
        test("should support updating host element via hostAttributes",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div update-host-attributes></div>",
                        directives: [DirectiveUpdatingHostAttributes]))
                .createAsync(MyComp)
                .then((fixture) {
              fixture.detectChanges();
              expect(
                  DOM.getAttribute(
                      fixture.debugElement.children[0].nativeElement, "role"),
                  "button");
              completer.done();
            });
          });
        });
        test("should support updating host element via hostProperties",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div update-host-properties></div>",
                        directives: [DirectiveUpdatingHostProperties]))
                .createAsync(MyComp)
                .then((fixture) {
              var tc = fixture.debugElement.children[0];
              var updateHost = tc.inject(DirectiveUpdatingHostProperties);
              updateHost.id = "newId";
              fixture.detectChanges();
              expect(tc.nativeElement.id, "newId");
              completer.done();
            });
          });
        });

        test("should support preventing default on render events", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<input type=\"checkbox\" listenerprevent><input type=\"checkbox\" listenernoprevent>",
                        directives: [
                          DirectiveListeningDomEventPrevent,
                          DirectiveListeningDomEventNoPrevent
                        ]))
                .createAsync(MyComp)
                .then((fixture) {
              var dispatchedEvent = DOM.createMouseEvent("click");
              var dispatchedEvent2 = DOM.createMouseEvent("click");
              DOM.dispatchEvent(fixture.debugElement.children[0].nativeElement,
                  dispatchedEvent);
              DOM.dispatchEvent(fixture.debugElement.children[1].nativeElement,
                  dispatchedEvent2);
              expect(DOM.isPrevented(dispatchedEvent), isTrue);
              expect(DOM.isPrevented(dispatchedEvent2), isFalse);
              expect(
                  DOM.getChecked(
                      fixture.debugElement.children[0].nativeElement),
                  isFalse);
              expect(
                  DOM.getChecked(
                      fixture.debugElement.children[1].nativeElement),
                  isTrue);
              completer.done();
            });
          });
        });
        test("should support render global events from multiple directives",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<div *ngIf=\"ctxBoolProp\" listener listenerother></div>",
                        directives: [
                          NgIf,
                          DirectiveListeningDomEvent,
                          DirectiveListeningDomEventOther
                        ]))
                .createAsync(MyComp)
                .then((fixture) {
              globalCounter = 0;
              fixture.debugElement.componentInstance.ctxBoolProp = true;
              fixture.detectChanges();
              var tc = fixture.debugElement.children[0];
              var listener = tc.inject(DirectiveListeningDomEvent);
              var otherListener = tc.inject(DirectiveListeningDomEventOther);
              dispatchEvent(DOM.getGlobalEventTarget("window"), "domEvent");
              expect(listener.eventTypes, ["window_domEvent"]);
              expect(otherListener.eventType, "other_domEvent");
              expect(globalCounter, 1);
              fixture.debugElement.componentInstance.ctxBoolProp = false;
              fixture.detectChanges();
              dispatchEvent(DOM.getGlobalEventTarget("window"), "domEvent");
              expect(globalCounter, 1);
              fixture.debugElement.componentInstance.ctxBoolProp = true;
              fixture.detectChanges();
              dispatchEvent(DOM.getGlobalEventTarget("window"), "domEvent");
              expect(globalCounter, 2);
              // need to destroy to release all remaining global event listeners
              fixture.destroy();
              completer.done();
            });
          });
        });
        group("dynamic ViewContainers", () {
          test(
              "should allow to create a ViewContainerRef at any bound location",
              () async {
            return inject(
                [TestComponentBuilder, AsyncTestCompleter, ComponentResolver],
                (TestComponentBuilder tcb, AsyncTestCompleter completer,
                    compiler) {
              tcb
                  .overrideView(
                      MyComp,
                      new ViewMetadata(
                          template:
                              "<div><dynamic-vp #dynamic></dynamic-vp></div>",
                          directives: [DynamicViewport]))
                  .createAsync(MyComp)
                  .then((fixture) {
                var tc = fixture.debugElement.children[0].children[0];
                DynamicViewport dynamicVp = tc.inject(DynamicViewport);
                dynamicVp.done.then((_) {
                  fixture.detectChanges();
                  expect(
                      fixture
                          .debugElement.children[0].children[1].nativeElement,
                      hasTextContent("dynamic greet"));
                  completer.done();
                });
              });
            });
          });
        });
        test("should support static attributes", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<input static type=\"text\" title>",
                        directives: [NeedsAttribute]))
                .createAsync(MyComp)
                .then((fixture) {
              var tc = fixture.debugElement.children[0];
              var needsAttribute = tc.inject(NeedsAttribute);
              expect(needsAttribute.typeAttribute, "text");
              expect(needsAttribute.staticAttribute, "");
              expect(needsAttribute.fooAttribute, null);
              completer.done();
            });
          });
        });
      });
      group("dependency injection", () {
        test("should support bindings", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: '''
            <directive-providing-injectable >
              <directive-consuming-injectable #consuming>
              </directive-consuming-injectable>
            </directive-providing-injectable>
          ''',
                        directives: [
                          DirectiveProvidingInjectable,
                          DirectiveConsumingInjectable
                        ]))
                .createAsync(MyComp)
                .then((fixture) {
              var comp = fixture.debugElement.children[0].getLocal("consuming");
              expect(comp.injectable, new isInstanceOf<InjectableService>());
              completer.done();
            });
          });
        });
        test("should support viewProviders", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    DirectiveProvidingInjectableInView,
                    new ViewMetadata(
                        template: '''
              <directive-consuming-injectable #consuming>
              </directive-consuming-injectable>
          ''',
                        directives: [DirectiveConsumingInjectable]))
                .createAsync(DirectiveProvidingInjectableInView)
                .then((fixture) {
              var comp = fixture.debugElement.children[0].getLocal("consuming");
              expect(comp.injectable, new isInstanceOf<InjectableService>());
              completer.done();
            });
          });
        });
        test("should support unbounded lookup", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: '''
            <directive-providing-injectable>
              <directive-containing-directive-consuming-an-injectable #dir>
              </directive-containing-directive-consuming-an-injectable>
            </directive-providing-injectable>
          ''',
                        directives: [
                          DirectiveProvidingInjectable,
                          DirectiveContainingDirectiveConsumingAnInjectable
                        ]))
                .overrideView(
                    DirectiveContainingDirectiveConsumingAnInjectable,
                    new ViewMetadata(
                        template: '''
            <directive-consuming-injectable-unbounded></directive-consuming-injectable-unbounded>
          ''',
                        directives: [DirectiveConsumingInjectableUnbounded]))
                .createAsync(MyComp)
                .then((fixture) {
              var comp = fixture.debugElement.children[0].getLocal("dir");
              expect(comp.directive.injectable,
                  new isInstanceOf<InjectableService>());
              completer.done();
            });
          });
        });
        test("should support the event-bus scenario", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: '''
            <grand-parent-providing-event-bus>
              <parent-providing-event-bus>
                <child-consuming-event-bus>
                </child-consuming-event-bus>
              </parent-providing-event-bus>
            </grand-parent-providing-event-bus>
          ''',
                        directives: [
                          GrandParentProvidingEventBus,
                          ParentProvidingEventBus,
                          ChildConsumingEventBus
                        ]))
                .createAsync(MyComp)
                .then((fixture) {
              var gpComp = fixture.debugElement.children[0];
              var parentComp = gpComp.children[0];
              var childComp = parentComp.children[0];
              var grandParent = gpComp.inject(GrandParentProvidingEventBus);
              var parent = parentComp.inject(ParentProvidingEventBus);
              var child = childComp.inject(ChildConsumingEventBus);
              expect(grandParent.bus.name, "grandparent");
              expect(parent.bus.name, "parent");
              expect(parent.grandParentBus, grandParent.bus);
              expect(child.bus, parent.bus);
              completer.done();
            });
          });
        });
        test("should instantiate bindings lazily", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: '''
              <component-providing-logging-injectable #providing>
                <directive-consuming-injectable *ngIf="ctxBoolProp">
                </directive-consuming-injectable>
              </component-providing-logging-injectable>
          ''',
                        directives: [
                          DirectiveConsumingInjectable,
                          ComponentProvidingLoggingInjectable,
                          NgIf
                        ]))
                .createAsync(MyComp)
                .then((fixture) {
              var providing =
                  fixture.debugElement.children[0].getLocal("providing");
              expect(providing.created, isFalse);
              fixture.debugElement.componentInstance.ctxBoolProp = true;
              fixture.detectChanges();
              expect(providing.created, isTrue);
              completer.done();
            });
          });
        });
      });
      group("corner cases", () {
        test("should remove script tags from templates", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(MyComp, new ViewMetadata(template: '''
            <script>alert("Ooops");</script>
            <div>before<script>alert("Ooops");</script><span>inside</span>after</div>'''))
                .createAsync(MyComp)
                .then((fixture) {
              expect(
                  DOM.querySelectorAll(
                      fixture.debugElement.nativeElement, "script"),
                  hasLength(0));
              completer.done();
            });
          });
        });
      });
      group("error handling", () {
        test(
            "should report a meaningful error when a directive is missing annotation",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb = tcb.overrideView(
                MyComp,
                new ViewMetadata(
                    template: "",
                    directives: [SomeDirectiveMissingAnnotation]));
            PromiseWrapper.catchError(tcb.createAsync(MyComp), (e) {
              expect(
                  e.message,
                  '''No Directive annotation found on ${ stringify(
                      SomeDirectiveMissingAnnotation)}''');
              completer.done();
              return null;
            });
          });
        });
        test(
            "should report a meaningful error when a component is missing view annotation",
            () async {
          return inject([TestComponentBuilder], (TestComponentBuilder tcb) {
            try {
              tcb.createAsync(ComponentWithoutView);
            } catch (e) {
              expect(
                  e.message,
                  contains(
                      'must have either \'template\' or \'templateUrl\' set.'));
              return null;
            }
          });
        });
        test("should report a meaningful error when a directive is null",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb = tcb.overrideView(
                MyComp,
                new ViewMetadata(directives: [
                  [null]
                ], template: ""));
            PromiseWrapper.catchError(tcb.createAsync(MyComp), (e) {
              expect(
                  e.message,
                  '''Unexpected directive value \'null\' on the View of component \'${ stringify(
                      MyComp)}\'''');
              completer.done();
              return null;
            });
          });
        });
        test("should provide an error context when an error happens in DI",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb = tcb.overrideView(
                MyComp,
                new ViewMetadata(
                    directives: [DirectiveThrowingAnError],
                    template:
                        '''<directive-throwing-error></directive-throwing-error>'''));
            PromiseWrapper.catchError(tcb.createAsync(MyComp), (e) {
              var c = e.context;
              expect(
                  DOM.nodeName(c.componentRenderElement).toUpperCase(), "DIV");
              expect((c.injector as Injector).get, isNotNull);
              completer.done();
              return null;
            });
          });
        });
        test(
            "should provide an error context when an error happens in change detection",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb = tcb.overrideView(
                MyComp,
                new ViewMetadata(
                    template: '''<input [value]="one.two.three" #local>'''));
            tcb.createAsync(MyComp).then((fixture) {
              try {
                fixture.detectChanges();
                throw "Should throw";
              } catch (e) {
                var c = e.context;
                expect(DOM.nodeName(c.renderNode).toUpperCase(), "INPUT");
                expect(DOM.nodeName(c.componentRenderElement).toUpperCase(),
                    "DIV");
                expect((c.injector as Injector).get, isNotNull);
                expect(c.source, contains(":0:7"));
                expect(c.context, fixture.debugElement.componentInstance);
                expect(c.locals["local"], isNotNull);
                completer.done();
              }
            });
          });
        });
        test(
            "should provide an error context when an error happens in change detection (text node)",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb = tcb.overrideView(MyComp,
                new ViewMetadata(template: '''<div>{{one.two.three}}</div>'''));
            tcb.createAsync(MyComp).then((fixture) {
              try {
                fixture.detectChanges();
                throw "Should throw";
              } catch (e) {
                var c = e.context;
                expect(c.renderNode, isNotNull);
                expect(c.source, contains(":0:5"));
                completer.done();
              }
            });
          });
        });
        test(
            "should provide an error context when an error happens in an event handler",
            fakeAsync(() {
          inject([TestComponentBuilder], (TestComponentBuilder tcb) {
            tcb = tcb.overrideView(
                MyComp,
                new ViewMetadata(
                    template:
                        '''<span emitter listener (event)="throwError()" #local></span>''',
                    directives: [
                      DirectiveEmittingEvent,
                      DirectiveListeningEvent
                    ]));
            ComponentFixture fixture;
            tcb.createAsync(MyComp).then((root) {
              fixture = root;
            });
            tick();
            var tc = fixture.debugElement.children[0];
            tc.inject(DirectiveEmittingEvent).fireEvent("boom");
            try {
              tick();
              throw "Should throw";
            } catch (e) {
              clearPendingTimers();
              var c = e.context;
              expect(DOM.nodeName(c.renderNode).toUpperCase(), "SPAN");
              expect(
                  DOM.nodeName(c.componentRenderElement).toUpperCase(), "DIV");
              expect(((c.injector as Injector)).get, isNotNull);
              expect(c.context, fixture.debugElement.componentInstance);
              expect(c.locals["local"], isNotNull);
            }
          });
        }));
        test("should report a meaningful error when a directive is undefined",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            var undefinedValue;
            tcb = tcb.overrideView(MyComp,
                new ViewMetadata(directives: [undefinedValue], template: ""));
            PromiseWrapper.catchError(tcb.createAsync(MyComp), (e) {
              expect(
                  e.message,
                  '''Unexpected directive value \'null\' on the View of component \'${ stringify(
                      MyComp)}\'''');
              completer.done();
              return null;
            });
          });
        });
        test(
            "should specify a location of an error that happened during change detection (text)",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp, new ViewMetadata(template: "<div>{{a.b}}</div>"))
                .createAsync(MyComp)
                .then((fixture) {
              expect(() => fixture.detectChanges(), throwsWith(':0:5'));
              completer.done();
            });
          });
        });
        test(
            "should specify a location of an error that happened during change detection (element property)",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(MyComp,
                    new ViewMetadata(template: "<div [title]=\"a.b\"></div>"))
                .createAsync(MyComp)
                .then((fixture) {
              expect(() => fixture.detectChanges(), throwsWith(':0:5' ''));
              completer.done();
            });
          });
        });
        test(
            "should specify a location of an error that happened during change detection (directive property)",
            () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<child-cmp [title]=\"a.b\"></child-cmp>",
                        directives: [ChildComp]))
                .createAsync(MyComp)
                .then((fixture) {
              expect(() => fixture.detectChanges(), throwsWith(':0:11' ''));
              completer.done();
            });
          });
        });
        test("should support imperative views", () async {
          return inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<simple-imp-cmp></simple-imp-cmp>",
                        directives: [SimpleImperativeViewComponent]))
                .createAsync(MyComp)
                .then((fixture) {
              expect(fixture.debugElement.nativeElement,
                  hasTextContent("hello imp view"));
              completer.done();
            });
          });
        });

        test("should support moving embedded views around", () async {
          return inject(
              [TestComponentBuilder, AsyncTestCompleter, ANCHOR_ELEMENT],
              (TestComponentBuilder tcb, AsyncTestCompleter completer,
                  anchorElement) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<div><div *someImpvp=\"ctxBoolProp\">hello</div></div>",
                        directives: [SomeImperativeViewport]))
                .createAsync(MyComp)
                .then((ComponentFixture fixture) {
              fixture.detectChanges();
              expect(anchorElement, hasTextContent(""));
              fixture.debugElement.componentInstance.ctxBoolProp = true;
              fixture.detectChanges();
              expect(anchorElement, hasTextContent("hello"));
              fixture.debugElement.componentInstance.ctxBoolProp = false;
              fixture.detectChanges();
              expect(fixture.debugElement.nativeElement, hasTextContent(""));
              completer.done();
            });
          });
        });
        group("Property bindings", () {
          test("should throw on bindings to unknown properties", () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              tcb = tcb.overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "<div unknown=\"{{ctxProp}}\"></div>"));
              PromiseWrapper.catchError(tcb.createAsync(MyComp), (e) {
                expect(
                    e.message,
                    '''Template parse errors:
Can\'t bind to \'unknown\' since it isn\'t a known native property ("<div [ERROR ->]unknown="{{ctxProp}}"></div>"): MyComp@0:5''');
                completer.done();
                return null;
              });
            });
          });
          test(
              "should not throw for property binding to a non-existing property when there is a matching directive property",
              () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              tcb
                  .overrideView(
                      MyComp,
                      new ViewMetadata(
                          template: "<div my-dir [elprop]=\"ctxProp\"></div>",
                          directives: [MyDir]))
                  .createAsync(MyComp)
                  .then((val) {
                completer.done();
              });
            });
          });

          test(
              "should not be created when there is a directive with the same property",
              () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              tcb
                  .overrideView(
                      MyComp,
                      new ViewMetadata(
                          template: "<span [title]=\"ctxProp\"></span>",
                          directives: [DirectiveWithTitle]))
                  .createAsync(MyComp)
                  .then((fixture) {
                fixture.debugElement.componentInstance.ctxProp = "TITLE";
                fixture.detectChanges();
                var el = DOM.querySelector(
                    fixture.debugElement.nativeElement, "span");
                expect(isBlank(el.title) || el.title == "", isTrue);
                completer.done();
              });
            });
          });
          test(
              "should work when a directive uses hostProperty to update the DOM element",
              () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              tcb
                  .overrideView(
                      MyComp,
                      new ViewMetadata(
                          template: "<span [title]=\"ctxProp\"></span>",
                          directives: [DirectiveWithTitleAndHostProperty]))
                  .createAsync(MyComp)
                  .then((fixture) {
                fixture.debugElement.componentInstance.ctxProp = "TITLE";
                fixture.detectChanges();
                var el = DOM.querySelector(
                    fixture.debugElement.nativeElement, "span");
                expect(el.title, "TITLE");
                completer.done();
              });
            });
          });
        });
        group("logging property updates", () {
          test("should reflect property values as attributes", () async {
            beforeEachProviders(() => [
                  // Switch to debug mode.
                  provide(CompilerConfig,
                      useValue: new CompilerConfig(true, true, isJit))
                ]);
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              var tpl = "<div>" +
                  "<div my-dir [elprop]=\"ctxProp\"></div>" +
                  "</div>";
              tcb
                  .overrideView(MyComp,
                      new ViewMetadata(template: tpl, directives: [MyDir]))
                  .createAsync(MyComp)
                  .then((fixture) {
                fixture.debugElement.componentInstance.ctxProp = "hello";
                fixture.detectChanges();
                expect(DOM.getInnerHTML(fixture.debugElement.nativeElement),
                    contains('ng-reflect-dir-prop="hello"'));
                completer.done();
              });
            });
          });
          test("should reflect property values on template comments", () async {
            beforeEachProviders(() => [
                  // Switch to debug mode.
                  provide(CompilerConfig,
                      useValue: new CompilerConfig(true, true, isJit))
                ]);
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              var tpl = "<template [ngIf]=\"ctxBoolProp\"></template>";
              tcb
                  .overrideView(MyComp,
                      new ViewMetadata(template: tpl, directives: [NgIf]))
                  .createAsync(MyComp)
                  .then((fixture) {
                fixture.debugElement.componentInstance.ctxBoolProp = true;
                fixture.detectChanges();
                expect(DOM.getInnerHTML(fixture.debugElement.nativeElement),
                    contains('"ng-reflect-ng-if": "true"'));
                completer.done();
              });
            });
          });
        });
        group("Missing directive checks", () {
          expectCompileError(tcb, inlineTpl, errMessage, done) {
            tcb =
                tcb.overrideView(MyComp, new ViewMetadata(template: inlineTpl));
            PromiseWrapper.then(tcb.createAsync(MyComp), (value) {
              throw new BaseException(
                  "Test failure: should not have come here as an exception was expected");
            }, (err) {
              expect(err.message, contains(errMessage));
              done();
            });
          }
// TODO: future errors to surface.
          test(
              'should raise an error if no directive is registered for '
              'a template with template bindings', () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              expectCompileError(
                  tcb,
                  "<div><div template=\"if: foo\"></div></div>",
                  'Template parse errors:\n'
                  'Can\'t bind to \'if\' since it isn\'t a known native '
                  'property ("<div><div [ERROR ->]template="if: foo">'
                  '</div></div>"): MyComp@0:10\n'
                  'Property binding if not used by any directive on an '
                  'embedded template ("<div>[ERROR ->]<div template="if: '
                  'foo"></div></div>"): MyComp@0:5',
                  () => completer.done());
            });
          });
//          test(
//              "should raise an error for missing template directive (2)", () async {
//            return inject([TestComponentBuilder, AsyncTestCompleter],
//                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
//              expectCompileError(
//                  tcb,
//                  "<div><template *ngIf=\"condition\"></template></div>",
//                  "Missing directive to handle: <template *ngIf=\"condition\">",
//                  () => completer.done());
//            });
//          });
//
//
//        test(
//            "should raise an error for missing template directive (3)", () async {
//          return inject([TestComponentBuilder, AsyncTestCompleter],
//              (TestComponentBuilder tcb, AsyncTestCompleter completer) {
//            expectCompileError(
//                tcb,
//                "<div *ngIf=\"condition\"></div>",
//                "Missing directive to handle 'if' in MyComp: <div *ngIf=\"condition\">",
//                () => completer.done());
//          });
//        });
//      }
        });
        group("property decorators", () {
          test("should support property decorators", () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              tcb
                  .overrideView(
                      MyComp,
                      new ViewMetadata(
                          template:
                              "<with-prop-decorators elProp=\"aaa\"></with-prop-decorators>",
                          directives: [DirectiveWithPropDecorators]))
                  .createAsync(MyComp)
                  .then((fixture) {
                fixture.detectChanges();
                var dir = fixture.debugElement.children[0]
                    .inject(DirectiveWithPropDecorators);
                expect(dir.dirProp, "aaa");
                completer.done();
              });
            });
          });
          test("should support host binding decorators", () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              tcb
                  .overrideView(
                      MyComp,
                      new ViewMetadata(
                          template:
                              "<with-prop-decorators></with-prop-decorators>",
                          directives: [DirectiveWithPropDecorators]))
                  .createAsync(MyComp)
                  .then((fixture) {
                fixture.detectChanges();
                var dir = fixture.debugElement.children[0]
                    .inject(DirectiveWithPropDecorators);
                dir.myAttr = "aaa";
                fixture.detectChanges();
                expect(
                    DOM.getOuterHTML(
                        fixture.debugElement.children[0].nativeElement),
                    contains("my-attr=\"aaa\""));
                completer.done();
              });
            });
          });
          test("should support event decorators", fakeAsync(() {
            inject([TestComponentBuilder], (TestComponentBuilder tcb) {
              tcb = tcb.overrideView(
                  MyComp,
                  new ViewMetadata(
                      template:
                          '''<with-prop-decorators (elEvent)="ctxProp=\'called\'">''',
                      directives: [DirectiveWithPropDecorators]));
              ComponentFixture fixture;
              tcb.createAsync(MyComp).then((root) {
                fixture = root;
              });
              tick();
              var emitter = fixture.debugElement.children[0]
                  .inject(DirectiveWithPropDecorators);
              emitter.fireEvent("fired !");
              tick();
              expect(fixture.debugElement.componentInstance.ctxProp, "called");
            });
          }));
          test("should support host listener decorators", () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              tcb
                  .overrideView(
                      MyComp,
                      new ViewMetadata(
                          template:
                              "<with-prop-decorators></with-prop-decorators>",
                          directives: [DirectiveWithPropDecorators]))
                  .createAsync(MyComp)
                  .then((fixture) {
                fixture.detectChanges();
                var dir = fixture.debugElement.children[0]
                    .inject(DirectiveWithPropDecorators);
                var native = fixture.debugElement.children[0].nativeElement;
                DOM.dispatchEvent(native, DOM.createMouseEvent("click"));
                expect(dir.target, native);
                completer.done();
              });
            });
          });
          test("should support defining views in the component decorator",
              () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              tcb
                  .overrideView(
                      MyComp,
                      new ViewMetadata(
                          template:
                              "<component-with-template></component-with-template>",
                          directives: [ComponentWithTemplate]))
                  .createAsync(MyComp)
                  .then((fixture) {
                fixture.detectChanges();
                var native = fixture.debugElement.children[0].nativeElement;
                expect(native, hasTextContent("No View Decorator: 123"));
                completer.done();
              });
            });
          });
        });

        group("svg", () {
          test("should support svg elements", () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              tcb
                  .overrideView(
                      MyComp,
                      new ViewMetadata(
                          template: "<svg><use xlink:href=\"Port\" /></svg>"))
                  .createAsync(MyComp)
                  .then((fixture) {
                var el = fixture.debugElement.nativeElement;
                var svg = DOM.childNodes(el)[0];
                var use = DOM.childNodes(svg)[0];
                expect(DOM.getProperty((svg as dynamic), "namespaceURI"),
                    "http://www.w3.org/2000/svg");
                expect(DOM.getProperty((use as dynamic), "namespaceURI"),
                    "http://www.w3.org/2000/svg");
                if (!IS_DART) {
                  var firstAttribute =
                      DOM.getProperty((use as dynamic), "attributes")[0];
                  expect(firstAttribute.name, "xlink:href");
                  expect(firstAttribute.namespaceURI,
                      "http://www.w3.org/1999/xlink");
                } else {
                  // For Dart where '_Attr' has no instance getter 'namespaceURI'
                  expect(DOM.getOuterHTML(use), contains("xmlns:xlink"));
                }
                completer.done();
              });
            });
          });
        });
        group("attributes", () {
          test("should support attributes with namespace", () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              tcb
                  .overrideView(
                      SomeCmp,
                      new ViewMetadata(
                          template: "<svg:use xlink:href=\"#id\" />"))
                  .createAsync(SomeCmp)
                  .then((fixture) {
                var useEl = DOM.firstChild(fixture.debugElement.nativeElement);
                expect(
                    DOM.getAttributeNS(
                        useEl, "http://www.w3.org/1999/xlink", "href"),
                    "#id");
                completer.done();
              });
            });
          });
          test("should support binding to attributes with namespace", () async {
            return inject([TestComponentBuilder, AsyncTestCompleter],
                (TestComponentBuilder tcb, AsyncTestCompleter completer) {
              tcb
                  .overrideView(
                      SomeCmp,
                      new ViewMetadata(
                          template: "<svg:use [attr.xlink:href]=\"value\" />"))
                  .createAsync(SomeCmp)
                  .then((fixture) {
                var cmp = fixture.debugElement.componentInstance;
                var useEl = DOM.firstChild(fixture.debugElement.nativeElement);
                cmp.value = "#id";
                fixture.detectChanges();
                expect(
                    DOM.getAttributeNS(
                        useEl, "http://www.w3.org/1999/xlink", "href"),
                    "#id");
                cmp.value = null;
                fixture.detectChanges();
                expect(
                    DOM.hasAttributeNS(
                        useEl, "http://www.w3.org/1999/xlink", "href"),
                    isFalse);
                completer.done();
              });
            });
          });
        });
      });
    });
  });
}

@Injectable()
class MyService {
  String greeting;
  MyService() {
    this.greeting = "hello";
  }
}

@Component(selector: "simple-imp-cmp", template: "")
@Injectable()
class SimpleImperativeViewComponent {
  var done;
  SimpleImperativeViewComponent(ElementRef self, Renderer renderer) {
    var hostElement = self.nativeElement;
    DOM.appendChild(hostElement, el("hello imp view"));
  }
}

@Directive(selector: "dynamic-vp")
@Injectable()
class DynamicViewport {
  Future<dynamic> done;
  DynamicViewport(ViewContainerRef vc, ComponentResolver compiler) {
    var myService = new MyService();
    myService.greeting = "dynamic greet";
    var injector = ReflectiveInjector.resolveAndCreate(
        [provide(MyService, useValue: myService)], vc.injector);
    this.done = compiler.resolveComponent(ChildCompUsingService).then(
        (componentFactory) =>
            vc.createComponent(componentFactory, 0, injector));
  }
}

@Directive(
    selector: "[my-dir]", inputs: const ["dirProp: elprop"], exportAs: "mydir")
@Injectable()
class MyDir {
  String dirProp;
  MyDir() {
    this.dirProp = "";
  }
}

@Directive(selector: "[title]", inputs: const ["title"])
class DirectiveWithTitle {
  String title;
}

@Directive(
    selector: "[title]",
    inputs: const ["title"],
    host: const {"[title]": "title"})
class DirectiveWithTitleAndHostProperty {
  String title;
}

@Component(selector: "event-cmp", template: "<div (click)=\"noop()\"></div>")
class EventCmp {
  noop() {}
}

@Component(
    selector: "push-cmp",
    inputs: const ["prop"],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template:
        "{{field}}<div (click)=\"noop()\"></div><div *ngIf=\"true\" (click)=\"noop()\"></div><event-cmp></event-cmp>",
    directives: const [EventCmp, NgIf])
@Injectable()
class PushCmp {
  num numberOfChecks;
  var prop;
  PushCmp() {
    this.numberOfChecks = 0;
  }
  noop() {}
  get field {
    this.numberOfChecks++;
    return "fixed";
  }
}

@Component(
    selector: "push-cmp-with-ref",
    inputs: const ["prop"],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: "{{field}}")
@Injectable()
class PushCmpWithRef {
  num numberOfChecks;
  ChangeDetectorRef ref;
  var prop;
  PushCmpWithRef(ChangeDetectorRef ref) {
    this.numberOfChecks = 0;
    this.ref = ref;
  }
  get field {
    this.numberOfChecks++;
    return "fixed";
  }

  propagate() {
    this.ref.markForCheck();
  }
}

@Component(
    selector: "push-cmp-with-host-event",
    host: const {"(click)": "ctxCallback(\$event)"},
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: "")
class PushCmpWithHostEvent {
  Function ctxCallback = (_) {};
}

@Component(
    selector: "push-cmp-with-async",
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: "{{field | async}}",
    pipes: const [AsyncPipe])
@Injectable()
class PushCmpWithAsyncPipe {
  num numberOfChecks = 0;
  Future<dynamic> promise;
  PromiseCompleter<dynamic> completer;
  PushCmpWithAsyncPipe() {
    this.completer = PromiseWrapper.completer();
    this.promise = this.completer.promise;
  }
  get field {
    this.numberOfChecks++;
    return this.promise;
  }

  resolve(value) {
    this.completer.resolve(value);
  }
}

@Component(selector: "my-comp", directives: const [])
@Injectable()
class MyComp {
  String ctxProp;
  num ctxNumProp;
  bool ctxBoolProp;
  MyComp() {
    this.ctxProp = "initial value";
    this.ctxNumProp = 0;
    this.ctxBoolProp = false;
  }
  throwError() {
    throw "boom";
  }
}

@Component(
    selector: "child-cmp",
    inputs: const ["dirProp"],
    viewProviders: const [MyService],
    directives: const [MyDir],
    template: "{{ctxProp}}")
@Injectable()
class ChildComp {
  String ctxProp;
  String dirProp;
  ChildComp(MyService service) {
    this.ctxProp = service.greeting;
    this.dirProp = null;
  }
}

@Component(
    selector: "child-cmp-no-template", directives: const [], template: "")
@Injectable()
class ChildCompNoTemplate {
  String ctxProp = "hello";
}

@Component(selector: "child-cmp-svc", template: "{{ctxProp}}")
@Injectable()
class ChildCompUsingService {
  String ctxProp;
  ChildCompUsingService(MyService service) {
    this.ctxProp = service.greeting;
  }
}

@Directive(selector: "some-directive")
@Injectable()
class SomeDirective {}

class SomeDirectiveMissingAnnotation {}

@Component(
    selector: "cmp-with-host",
    template: "<p>Component with an injected host</p>",
    directives: const [SomeDirective])
@Injectable()
class CompWithHost {
  SomeDirective myHost;
  CompWithHost(@Host() SomeDirective someComp) {
    this.myHost = someComp;
  }
}

@Component(selector: "[child-cmp2]", viewProviders: const [MyService])
@Injectable()
class ChildComp2 {
  String ctxProp;
  String dirProp;
  ChildComp2(MyService service) {
    this.ctxProp = service.greeting;
    this.dirProp = null;
  }
}

@Directive(selector: "[some-viewport]")
@Injectable()
class SomeViewport {
  ViewContainerRef container;
  SomeViewport(this.container, TemplateRef templateRef) {
    container.createEmbeddedView(templateRef).setLocal("some-tmpl", "hello");
    container.createEmbeddedView(templateRef).setLocal("some-tmpl", "again");
  }
}

@Pipe(name: "double")
class DoublePipe implements PipeTransform, OnDestroy {
  ngOnDestroy() {}
  transform(value) {
    return '''${ value}${ value}''';
  }
}

@Directive(selector: "[emitter]", outputs: const ["event"])
@Injectable()
class DirectiveEmittingEvent {
  String msg;
  EventEmitter<dynamic> event;
  DirectiveEmittingEvent() {
    this.msg = "";
    this.event = new EventEmitter();
  }
  fireEvent(String msg) {
    ObservableWrapper.callEmit(this.event, msg);
  }
}

@Directive(selector: "[update-host-attributes]", host: const {"role": "button"})
@Injectable()
class DirectiveUpdatingHostAttributes {}

@Directive(selector: "[update-host-properties]", host: const {"[id]": "id"})
@Injectable()
class DirectiveUpdatingHostProperties {
  String id;
  DirectiveUpdatingHostProperties() {
    this.id = "one";
  }
}

@Directive(selector: "[listener]", host: const {"(event)": "onEvent(\$event)"})
@Injectable()
class DirectiveListeningEvent {
  String msg;
  DirectiveListeningEvent() {
    this.msg = "";
  }
  onEvent(String msg) {
    this.msg = msg;
  }
}

@Directive(selector: "[listener]", host: const {
  "(domEvent)": "onEvent(\$event.type)",
  "(window:domEvent)": "onWindowEvent(\$event.type)",
  "(document:domEvent)": "onDocumentEvent(\$event.type)",
  "(body:domEvent)": "onBodyEvent(\$event.type)"
})
@Injectable()
class DirectiveListeningDomEvent {
  List<String> eventTypes = [];
  onEvent(String eventType) {
    this.eventTypes.add(eventType);
  }

  onWindowEvent(String eventType) {
    this.eventTypes.add("window_" + eventType);
  }

  onDocumentEvent(String eventType) {
    this.eventTypes.add("document_" + eventType);
  }

  onBodyEvent(String eventType) {
    this.eventTypes.add("body_" + eventType);
  }
}

var globalCounter = 0;

@Directive(
    selector: "[listenerother]",
    host: const {"(window:domEvent)": "onEvent(\$event.type)"})
@Injectable()
class DirectiveListeningDomEventOther {
  String eventType;
  DirectiveListeningDomEventOther() {
    this.eventType = "";
  }
  onEvent(String eventType) {
    globalCounter++;
    this.eventType = "other_" + eventType;
  }
}

@Directive(
    selector: "[listenerprevent]", host: const {"(click)": "onEvent(\$event)"})
@Injectable()
class DirectiveListeningDomEventPrevent {
  onEvent(event) {
    return false;
  }
}

@Directive(
    selector: "[listenernoprevent]",
    host: const {"(click)": "onEvent(\$event)"})
@Injectable()
class DirectiveListeningDomEventNoPrevent {
  onEvent(event) {
    return true;
  }
}

@Directive(selector: "[id]", inputs: const ["id"])
@Injectable()
class IdDir {
  String id;
}

@Directive(selector: "[customEvent]")
@Injectable()
class EventDir {
  @Output()
  var customEvent = new EventEmitter();
  doSomething() {}
}

@Directive(selector: "[static]")
@Injectable()
class NeedsAttribute {
  var typeAttribute;
  var staticAttribute;
  var fooAttribute;
  NeedsAttribute(
      @Attribute("type") String typeAttribute,
      @Attribute("static") String staticAttribute,
      @Attribute("foo") String fooAttribute) {
    this.typeAttribute = typeAttribute;
    this.staticAttribute = staticAttribute;
    this.fooAttribute = fooAttribute;
  }
}

@Injectable()
class PublicApi {}

@Directive(selector: "[public-api]", providers: const [
  const Provider(PublicApi, useExisting: PrivateImpl, deps: const [])
])
@Injectable()
class PrivateImpl extends PublicApi {}

@Directive(selector: "[needs-public-api]")
@Injectable()
class NeedsPublicApi {
  NeedsPublicApi(@Host() PublicApi api) {
    expect(api is PrivateImpl, isTrue);
  }
}

@Directive(selector: "[toolbarpart]")
@Injectable()
class ToolbarPart {
  TemplateRef templateRef;
  ToolbarPart(TemplateRef templateRef) {
    this.templateRef = templateRef;
  }
}

@Directive(selector: "[toolbarVc]", inputs: const ["toolbarVc"])
@Injectable()
class ToolbarViewContainer {
  ViewContainerRef vc;
  ToolbarViewContainer(ViewContainerRef vc) {
    this.vc = vc;
  }
  set toolbarVc(ToolbarPart part) {
    var view = this.vc.createEmbeddedView(part.templateRef, 0);
    view.setLocal("toolbarProp", "From toolbar");
  }
}

@Component(
    selector: "toolbar",
    template:
        "TOOLBAR(<div *ngFor=\"let  part of query\" [toolbarVc]=\"part\"></div>)",
    directives: const [ToolbarViewContainer, NgFor])
@Injectable()
class ToolbarComponent {
  QueryList<ToolbarPart> query;
  String ctxProp;
  ToolbarComponent(@Query(ToolbarPart) QueryList<ToolbarPart> query) {
    this.ctxProp = "hello world";
    this.query = query;
  }
}

@Directive(
    selector: "[two-way]",
    inputs: const ["control"],
    outputs: const ["controlChange"])
@Injectable()
class DirectiveWithTwoWayBinding {
  var controlChange = new EventEmitter();
  var control = null;
  triggerChange(value) {
    ObservableWrapper.callEmit(this.controlChange, value);
  }
}

@Injectable()
class InjectableService {}

createInjectableWithLogging(Injector inj) {
  inj.get(ComponentProvidingLoggingInjectable).created = true;
  return new InjectableService();
}

@Component(
    selector: "component-providing-logging-injectable",
    providers: const [
      const Provider(InjectableService,
          useFactory: createInjectableWithLogging, deps: const [Injector])
    ],
    template: "")
@Injectable()
class ComponentProvidingLoggingInjectable {
  bool created = false;
}

@Directive(selector: "directive-providing-injectable", providers: const [
  const [InjectableService]
])
@Injectable()
class DirectiveProvidingInjectable {}

@Component(
    selector: "directive-providing-injectable",
    viewProviders: const [
      const [InjectableService]
    ],
    template: "")
@Injectable()
class DirectiveProvidingInjectableInView {}

@Component(
    selector: "directive-providing-injectable",
    providers: const [const Provider(InjectableService, useValue: "host")],
    viewProviders: const [const Provider(InjectableService, useValue: "view")],
    template: "")
@Injectable()
class DirectiveProvidingInjectableInHostAndView {}

@Component(selector: "directive-consuming-injectable", template: "")
@Injectable()
class DirectiveConsumingInjectable {
  var injectable;
  DirectiveConsumingInjectable(@Host() @Inject(InjectableService) injectable) {
    this.injectable = injectable;
  }
}

@Component(selector: "directive-containing-directive-consuming-an-injectable")
@Injectable()
class DirectiveContainingDirectiveConsumingAnInjectable {
  var directive;
}

@Component(selector: "directive-consuming-injectable-unbounded", template: "")
@Injectable()
class DirectiveConsumingInjectableUnbounded {
  var injectable;
  DirectiveConsumingInjectableUnbounded(InjectableService injectable,
      @SkipSelf() DirectiveContainingDirectiveConsumingAnInjectable parent) {
    this.injectable = injectable;
    parent.directive = this;
  }
}

class EventBus {
  final EventBus parentEventBus;
  final String name;
  const EventBus(EventBus parentEventBus, String name)
      : parentEventBus = parentEventBus,
        name = name;
}

@Directive(selector: "grand-parent-providing-event-bus", providers: const [
  const Provider(EventBus, useValue: const EventBus(null, "grandparent"))
])
class GrandParentProvidingEventBus {
  EventBus bus;
  GrandParentProvidingEventBus(EventBus bus) {
    this.bus = bus;
  }
}

createParentBus(peb) {
  return new EventBus(peb, "parent");
}

@Component(
    selector: "parent-providing-event-bus",
    providers: const [
      const Provider(EventBus, useFactory: createParentBus, deps: const [
        const [EventBus, const SkipSelfMetadata()]
      ])
    ],
    directives: const [ChildConsumingEventBus],
    template: '''
    <child-consuming-event-bus></child-consuming-event-bus>
  ''')
class ParentProvidingEventBus {
  EventBus bus;
  EventBus grandParentBus;
  ParentProvidingEventBus(EventBus bus, @SkipSelf() EventBus grandParentBus) {
    this.bus = bus;
    this.grandParentBus = grandParentBus;
  }
}

@Directive(selector: "child-consuming-event-bus")
class ChildConsumingEventBus {
  EventBus bus;
  ChildConsumingEventBus(@SkipSelf() EventBus bus) {
    this.bus = bus;
  }
}

@Directive(selector: "[someImpvp]", inputs: const ["someImpvp"])
@Injectable()
class SomeImperativeViewport {
  ViewContainerRef vc;
  TemplateRef templateRef;
  EmbeddedViewRef view;
  var anchor;
  SomeImperativeViewport(
      this.vc, this.templateRef, @Inject(ANCHOR_ELEMENT) anchor) {
    this.view = null;
    this.anchor = anchor;
  }
  set someImpvp(bool value) {
    if (isPresent(this.view)) {
      this.vc.clear();
      this.view = null;
    }
    if (value) {
      this.view = this.vc.createEmbeddedView(this.templateRef);
      var nodes = this.view.rootNodes;
      for (var i = 0; i < nodes.length; i++) {
        DOM.appendChild(this.anchor, nodes[i]);
      }
    }
  }
}

@Directive(selector: "[export-dir]", exportAs: "dir")
class ExportDir {}

@Component(selector: "comp")
class ComponentWithoutView {}

@Directive(selector: "[no-duplicate]")
class DuplicateDir {
  DuplicateDir(ElementRef elRef) {
    DOM.setText(
        elRef.nativeElement, DOM.getText(elRef.nativeElement) + "noduplicate");
  }
}

@Directive(selector: "[no-duplicate]")
class OtherDuplicateDir {
  OtherDuplicateDir(ElementRef elRef) {
    DOM.setText(elRef.nativeElement,
        DOM.getText(elRef.nativeElement) + "othernoduplicate");
  }
}

@Directive(selector: "directive-throwing-error")
class DirectiveThrowingAnError {
  DirectiveThrowingAnError() {
    throw new BaseException("BOOM");
  }
}

@Component(
    selector: "component-with-template",
    directives: const [NgFor],
    template:
        '''No View Decorator: <div *ngFor="let item of items">{{item}}</div>''')
class ComponentWithTemplate {
  var items = [1, 2, 3];
}

@Directive(selector: "with-prop-decorators")
class DirectiveWithPropDecorators {
  var target;
  @Input("elProp")
  String dirProp;
  @Output("elEvent")
  var event = new EventEmitter();
  @HostBinding("attr.my-attr")
  String myAttr;
  @HostListener("click", const ["\$event.target"])
  onClick(target) {
    this.target = target;
  }

  fireEvent(msg) {
    ObservableWrapper.callEmit(this.event, msg);
  }
}

@Component(selector: "some-cmp")
class SomeCmp {
  dynamic value;
}
