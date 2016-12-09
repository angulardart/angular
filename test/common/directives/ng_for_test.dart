@TestOn('browser && !js')
library angular2.test.common.directives.ng_for_test;

import "package:angular2/core.dart" show Component, TemplateRef, ContentChild;
import "package:angular2/src/common/directives/ng_for.dart" show NgFor;
import "package:angular2/src/common/directives/ng_if.dart" show NgIf;
import 'package:angular2/src/facade/exceptions.dart' show BaseException;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void main() {
  group("ngFor", () {
    var TEMPLATE = '<div><copy-me template=\"ngFor let item of items\">'
        '{{item.toString()}};</copy-me></div>';
    test("should reflect initial elements", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(TestComponent, TEMPLATE)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement, hasTextContent('1;2;'));
          completer.done();
        });
      });
    });
    test("should reflect added elements", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(TestComponent, TEMPLATE)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          ((fixture.debugElement.componentInstance.items as List<num>)).add(3);
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement, hasTextContent('1;2;3;'));
          completer.done();
        });
      });
    });
    test("should reflect removed elements", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(TestComponent, TEMPLATE)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          fixture.debugElement.componentInstance.items.removeAt(1);
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement, hasTextContent("1;"));
          completer.done();
        });
      });
    });
    test("should reflect moved elements", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(TestComponent, TEMPLATE)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          fixture.debugElement.componentInstance.items.removeAt(0);
          ((fixture.debugElement.componentInstance.items as List<num>)).add(1);
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement, hasTextContent("2;1;"));
          completer.done();
        });
      });
    });
    test("should reflect a mix of all changes (additions/removals/moves)",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(TestComponent, TEMPLATE)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.items = [0, 1, 2, 3, 4, 5];
          fixture.detectChanges();
          fixture.debugElement.componentInstance.items = [6, 2, 7, 0, 4, 8];
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("6;2;7;0;4;8;"));
          completer.done();
        });
      });
    });
    test("should iterate over an array of objects", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            '<ul><li template="ngFor let item of items">{{item["name"]}};'
            '</li></ul>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          // INIT
          fixture.debugElement.componentInstance.items = [
            {"name": "misko"},
            {"name": "shyam"}
          ];
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("misko;shyam;"));
          // GROW
          ((fixture.debugElement.componentInstance.items as List<dynamic>))
              .add({"name": "adam"});
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("misko;shyam;adam;"));
          // SHRINK
          fixture.debugElement.componentInstance.items
            ..removeAt(2)
            ..removeAt(0);
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement, hasTextContent("shyam;"));
          completer.done();
        });
      });
    });
    test("should gracefully handle nulls", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            "<ul><li template=\"ngFor let item of null\">{{item}};</li></ul>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement, hasTextContent(""));
          completer.done();
        });
      });
    });
    test("should gracefully handle ref changing to null and back", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(TestComponent, TEMPLATE)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement, hasTextContent("1;2;"));
          fixture.debugElement.componentInstance.items = null;
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement, hasTextContent(""));
          fixture.debugElement.componentInstance.items = [1, 2, 3];
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement, hasTextContent("1;2;3;"));
          completer.done();
        });
      });
    });
    test("should throw on non-iterable ref and suggest using an array",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(TestComponent, TEMPLATE)
            .createAsync(TestComponent)
            .then((fixture) {
          String msg = '';
          try {
            fixture.debugElement.componentInstance.items = 'whaaa';
            fixture.detectChanges();
          } catch (e) {
            msg = e is BaseException
                ? e.toString()
                : e.originalException.toString();
          }
          expect(
              msg,
              'Cannot find a differ supporting object \'whaaa\' of'
              ' type \'String\'. NgFor only supports binding to '
              'Iterables such as Arrays.');
          completer.done();
        });
      });
    });
    test("should throw on ref changing to string", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(TestComponent, TEMPLATE)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement, hasTextContent("1;2;"));
          fixture.debugElement.componentInstance.items = "whaaa";
          expect(() => fixture.detectChanges(),
              throwsA(new isInstanceOf<Error>()));
          completer.done();
        });
      });
    });
    test("should works with duplicates", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(TestComponent, TEMPLATE)
            .createAsync(TestComponent)
            .then((fixture) {
          var a = new Foo();
          fixture.debugElement.componentInstance.items = [a, a];
          fixture.detectChanges();
          expect(
              fixture.debugElement.nativeElement, hasTextContent('foo;foo;'));
          completer.done();
        });
      });
    });
    test("should repeat over nested arrays", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '<div>' +
            '<div template="ngFor let item of items">'
            '<div template="ngFor let subitem of item">'
            '{{subitem}}-{{item.length}};'
            '</div>|'
            '</div>'
            '</div>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.items = [
            ["a", "b"],
            ["c"]
          ];
          fixture.detectChanges();
          fixture.detectChanges();
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent('a-2;b-2;|c-1;|'));
          fixture.debugElement.componentInstance.items = [
            ["e"],
            ["f", "g"]
          ];
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent('e-1;|f-2;g-2;|'));
          completer.done();
        });
      });
    });
    test("should repeat over nested arrays with no intermediate element",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = "<div><template ngFor let-item [ngForOf]=\"items\">" +
            "<div template=\"ngFor let subitem of item\">" +
            "{{subitem}}-{{item.length}};" +
            "</div></template></div>";
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.items = [
            ["a", "b"],
            ["c"]
          ];
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("a-2;b-2;c-1;"));
          fixture.debugElement.componentInstance.items = [
            ["e"],
            ["f", "g"]
          ];
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("e-1;f-2;g-2;"));
          completer.done();
        });
      });
    });
    test(
        'should repeat over nested ngIf that are the last node in '
        'the ngFor temlate', () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '<div><template ngFor let-item [ngForOf]="items" '
            'let-i="index"><div>{{i}}|</div>'
            '<div *ngIf="i % 2 == 0">even|</div></template></div>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          var el = fixture.debugElement.nativeElement;
          var items = [1];
          fixture.debugElement.componentInstance.items = items;
          fixture.detectChanges();
          expect(el, hasTextContent("0|even|"));
          items.add(1);
          fixture.detectChanges();
          expect(el, hasTextContent("0|even|1|"));
          items.add(1);
          fixture.detectChanges();
          expect(el, hasTextContent("0|even|1|2|even|"));
          completer.done();
        });
      });
    });
    test("should display indices correctly", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template =
            '<div><copy-me template="ngFor: let item of items; let i=index">'
            '{{i.toString()}}</copy-me></div>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.items = [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
          ];
          fixture.detectChanges();
          expect(
              fixture.debugElement.nativeElement, hasTextContent("0123456789"));
          fixture.debugElement.componentInstance.items = [
            1,
            2,
            6,
            7,
            4,
            3,
            5,
            8,
            9,
            0
          ];
          fixture.detectChanges();
          expect(
              fixture.debugElement.nativeElement, hasTextContent("0123456789"));
          completer.done();
        });
      });
    });
    test("should display first item correctly", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '<div><copy-me template="ngFor: let item of items; '
            'let isFirst=first">{{isFirst.toString()}}</copy-me></div>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.items = [0, 1, 2];
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("truefalsefalse"));
          fixture.debugElement.componentInstance.items = [2, 1];
          fixture.detectChanges();
          expect(
              fixture.debugElement.nativeElement, hasTextContent("truefalse"));
          completer.done();
        });
      });
    });
    test("should display last item correctly", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '<div><copy-me template="ngFor: let item of items; '
            'let isLast=last\">{{isLast.toString()}}</copy-me></div>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.items = [0, 1, 2];
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("falsefalsetrue"));
          fixture.debugElement.componentInstance.items = [2, 1];
          fixture.detectChanges();
          expect(
              fixture.debugElement.nativeElement, hasTextContent("falsetrue"));
          completer.done();
        });
      });
    });
    test("should display even items correctly", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '<div><copy-me template="ngFor: let item of items; '
            'let isEven=even\">{{isEven.toString()}}</copy-me></div>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.items = [0, 1, 2];
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("truefalsetrue"));
          fixture.debugElement.componentInstance.items = [2, 1];
          fixture.detectChanges();
          expect(
              fixture.debugElement.nativeElement, hasTextContent("truefalse"));
          completer.done();
        });
      });
    });
    test("should display odd items correctly", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        var template = '<div><copy-me template=\"ngFor: let item of items; '
            'let isOdd=odd\">{{isOdd.toString()}}</copy-me></div>';
        tcb
            .overrideTemplate(TestComponent, template)
            .createAsync(TestComponent)
            .then((fixture) {
          fixture.debugElement.componentInstance.items = [0, 1, 2, 3];
          fixture.detectChanges();
          expect(fixture.debugElement.nativeElement,
              hasTextContent("falsetruefalsetrue"));
          fixture.debugElement.componentInstance.items = [2, 1];
          fixture.detectChanges();
          expect(
              fixture.debugElement.nativeElement, hasTextContent("falsetrue"));
          completer.done();
        });
      });
    });
    test("should allow to use a custom template", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(
                TestComponent,
                '<ul><template ngFor [ngForOf]="items" '
                '[ngForTemplate]="contentTpl"></template></ul>')
            .overrideTemplate(
                ComponentUsingTestComponent,
                '<test-cmp><li template="let item; let i=index">'
                '{{i}}: {{item}};</li></test-cmp>')
            .createAsync(ComponentUsingTestComponent)
            .then((fixture) {
          var testComponent = fixture.debugElement.children[0];
          testComponent.componentInstance.items = ["a", "b", "c"];
          fixture.detectChanges();
          expect(
              testComponent.nativeElement, hasTextContent("0: a;1: b;2: c;"));
          completer.done();
        });
      });
    });
    test("should use a default template if a custom one is null", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(
                TestComponent,
                '<ul><template ngFor let-item [ngForOf]="items"'
                '[ngForTemplate]="contentTpl" let-i="index">'
                '{{i}}: {{item}};</template></ul>')
            .overrideTemplate(
                ComponentUsingTestComponent, "<test-cmp></test-cmp>")
            .createAsync(ComponentUsingTestComponent)
            .then((fixture) {
          var testComponent = fixture.debugElement.children[0];
          testComponent.componentInstance.items = ["a", "b", "c"];
          fixture.detectChanges();
          expect(
              testComponent.nativeElement, hasTextContent("0: a;1: b;2: c;"));
          completer.done();
        });
      });
    });
    test(
        'should use a custom template when both default and a '
        'custom one are present', () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(
                TestComponent,
                '<ul><template ngFor let-item [ngForOf]="items"'
                '[ngForTemplate]="contentTpl" let-i="index">'
                '{{i}}=> {{item}};</template></ul>')
            .overrideTemplate(
                ComponentUsingTestComponent,
                '<test-cmp><li template="let item; let i=index">'
                '{{i}}: {{item}};</li></test-cmp>')
            .createAsync(ComponentUsingTestComponent)
            .then((fixture) {
          var testComponent = fixture.debugElement.children[0];
          testComponent.componentInstance.items = ["a", "b", "c"];
          fixture.detectChanges();
          expect(
              testComponent.nativeElement, hasTextContent("0: a;1: b;2: c;"));
          completer.done();
        });
      });
    });
    group("track by", () {
      test("should not replace tracked items", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = '<template ngFor let-item [ngForOf]="items" '
              '[ngForTrackBy]="trackById" let-i="index">'
              '<p>{{items[i]}}</p>'
              '</template>';
          tcb
              .overrideTemplate(TestComponent, template)
              .createAsync(TestComponent)
              .then((fixture) {
            var buildItemList = () {
              fixture.debugElement.componentInstance.items = [
                {"id": "a"}
              ];
              fixture.detectChanges();
              return fixture.debugElement.queryAll(By.css("p"))[0];
            };
            var firstP = buildItemList();
            var finalP = buildItemList();
            expect(finalP.nativeElement, firstP.nativeElement);
            completer.done();
          });
        });
      });
      test("should update implicit local variable on view", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = '<div><template ngFor let-item [ngForOf]="items" '
              '[ngForTrackBy]="trackById">{{item[\'color\']}}</template></div>';
          tcb
              .overrideTemplate(TestComponent, template)
              .createAsync(TestComponent)
              .then((fixture) {
            fixture.debugElement.componentInstance.items = [
              {"id": "a", "color": "blue"}
            ];
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement, hasTextContent("blue"));
            fixture.debugElement.componentInstance.items = [
              {"id": "a", "color": "red"}
            ];
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement, hasTextContent("red"));
            completer.done();
          });
        });
      });
      test("should move items around and keep them updated ", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = '<div><template ngFor let-item [ngForOf]="items" '
              '[ngForTrackBy]="trackById">{{item[\'color\']}}</template></div>';
          tcb
              .overrideTemplate(TestComponent, template)
              .createAsync(TestComponent)
              .then((fixture) {
            fixture.debugElement.componentInstance.items = [
              {"id": "a", "color": "blue"},
              {"id": "b", "color": "yellow"}
            ];
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent("blueyellow"));
            fixture.debugElement.componentInstance.items = [
              {"id": "b", "color": "orange"},
              {"id": "a", "color": "red"}
            ];
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent("orangered"));
            completer.done();
          });
        });
      });
      test(
          'should handle added and removed items properly when tracking '
          'by index', () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var template = '<div><template ngFor let-item [ngForOf]="items" '
              '[ngForTrackBy]="trackByIndex">{{item}}</template></div>';
          tcb
              .overrideTemplate(TestComponent, template)
              .createAsync(TestComponent)
              .then((fixture) {
            fixture.debugElement.componentInstance.items = ["a", "b", "c", "d"];
            fixture.detectChanges();
            fixture.debugElement.componentInstance.items = ["e", "f", "g", "h"];
            fixture.detectChanges();
            fixture.debugElement.componentInstance.items = ["e", "f", "h"];
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement, hasTextContent("efh"));
            completer.done();
          });
        });
      });
    });
  });
}

class Foo {
  String toString() {
    return "foo";
  }
}

@Component(selector: "test-cmp", directives: const [NgFor, NgIf], template: "")
class TestComponent {
  @ContentChild(TemplateRef)
  TemplateRef contentTpl;
  dynamic items;
  TestComponent() {
    this.items = [1, 2];
  }
  String trackById(num index, dynamic item) {
    return item["id"];
  }

  num trackByIndex(num index, dynamic item) {
    return index;
  }
}

@Component(
    selector: "outer-cmp", directives: const [TestComponent], template: "")
class ComponentUsingTestComponent {
  dynamic items;
  ComponentUsingTestComponent() {
    this.items = [1, 2];
  }
}
