@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.common.directives.for_test;

import 'dart:html';

import 'package:test/test.dart';
import 'package:_tests/matchers.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/debug/debug_node.dart';
import 'package:angular_test/angular_test.dart';

void main() {
  group('ngFor', () {
    tearDown(() => disposeAnyRunningTest());

    test("should reflect initial elements", () async {
      var testBed = new NgTestBed<NgForItemsTest>();
      var testFixture = await testBed.create();
      expect(testFixture.rootElement, hasTextContent('1;2;3;'));
    });

    test("should reflect added elements", () async {
      var testBed = new NgTestBed<NgForItemsTest>();
      NgTestFixture<NgForItemsTest> testFixture = await testBed.create();
      await testFixture.update((NgForItemsTest component) {
        component.items.add(4);
      });
      expect(testFixture.rootElement, hasTextContent('1;2;3;4;'));
    });

    test("should reflect removed elements - first", () async {
      var testBed = new NgTestBed<NgForItemsTest>();
      NgTestFixture<NgForItemsTest> testFixture = await testBed.create();
      await testFixture.update((NgForItemsTest component) {
        component.items.removeAt(0);
      });
      expect(testFixture.rootElement, hasTextContent('2;3;'));
    });

    test("should reflect removed elements - middle", () async {
      var testBed = new NgTestBed<NgForItemsTest>();
      NgTestFixture<NgForItemsTest> testFixture = await testBed.create();
      await testFixture.update((NgForItemsTest component) {
        component.items.removeAt(1);
      });
      expect(testFixture.rootElement, hasTextContent('1;3;'));
    });

    test("should reflect removed elements - last", () async {
      var testBed = new NgTestBed<NgForItemsTest>();
      NgTestFixture<NgForItemsTest> testFixture = await testBed.create();
      await testFixture.update((NgForItemsTest component) {
        component.items.removeAt(2);
      });
      expect(testFixture.rootElement, hasTextContent('1;2;'));
    });

    test("should reflect move to end", () async {
      var testBed = new NgTestBed<NgForItemsTest>();
      NgTestFixture<NgForItemsTest> testFixture = await testBed.create();
      await testFixture.update((NgForItemsTest component) {
        component.items.removeAt(0);
        component.items.add(1);
      });
      expect(testFixture.rootElement, hasTextContent('2;3;1;'));
    });

    test("should reflect move to start", () async {
      var testBed = new NgTestBed<NgForItemsTest>();
      NgTestFixture<NgForItemsTest> testFixture = await testBed.create();
      await testFixture.update((NgForItemsTest component) {
        component.items.removeAt(1);
        component.items.insert(0, 2);
      });
      expect(testFixture.rootElement, hasTextContent('2;1;3;'));
    });

    test("should reflect a mix of all changes (additions/removals/moves)",
        () async {
      var testBed = new NgTestBed<NgForItemsTest>();
      NgTestFixture<NgForItemsTest> testFixture = await testBed.create();
      await testFixture.update((NgForItemsTest component) {
        component.items = <int>[0, 1, 2, 3, 4, 5];
      });
      await testFixture.update((NgForItemsTest component) {
        component.items = <int>[6, 2, 7, 0, 4, 8];
      });
      expect(testFixture.rootElement, hasTextContent('6;2;7;0;4;8;'));
    });

    test("should iterate over an array of objects", () async {
      var testBed = new NgTestBed<NgForOptionsTest>();
      NgTestFixture<NgForOptionsTest> testFixture = await testBed.create();
      await testFixture.update((NgForOptionsTest component) {
        component.items = [
          {"name": "misko"},
          {"name": "shyam"}
        ];
      });
      expect(testFixture.rootElement, hasTextContent('misko;shyam;'));
      // Add new object.
      await testFixture.update((NgForOptionsTest component) {
        component.items.add({"name": "adam"});
      });
      expect(testFixture.rootElement, hasTextContent('misko;shyam;adam;'));
      // Remove.
      await testFixture.update((NgForOptionsTest component) {
        component.items.removeAt(2);
        component.items.removeAt(0);
      });
      expect(testFixture.rootElement, hasTextContent('shyam;'));
    });

    test("should gracefully handle nulls", () async {
      var testBed = new NgTestBed<NgForNullTest>();
      NgTestFixture<NgForNullTest> testFixture = await testBed.create();
      expect(testFixture.rootElement, hasTextContent(''));
    });

    test("should gracefully handle ref changing to null and back", () async {
      var testBed = new NgTestBed<NgForItemsTest>();
      NgTestFixture<NgForItemsTest> testFixture = await testBed.create();
      expect(testFixture.rootElement, hasTextContent('1;2;3;'));

      await testFixture.update((NgForItemsTest component) {
        component.items = null;
      });
      expect(testFixture.rootElement, hasTextContent(''));
      await testFixture.update((NgForItemsTest component) {
        component.items = [5, 6];
      });
      expect(testFixture.rootElement, hasTextContent('5;6;'));
    });

    test("should throw on non-iterable ref and suggest using an array",
        () async {
      var testBed = new NgTestBed<NgForOptionsTest>();
      NgTestFixture<NgForOptionsTest> testFixture = await testBed.create();
      bool didThrowException = false;
      await testFixture.update((NgForOptionsTest component) {
        component.items = "this is not iterable";
      }).catchError((e) {
        expect(
            e.toString(),
            contains(
                'Cannot diff `this is not iterable` of type String. NgFor only '
                'supports binding to something that implements the `Iterable` '
                'interface, such as `List`.'));
        didThrowException = true;
      });
      expect(didThrowException, true);
    });

    test("should work with duplicates", () async {
      var testBed = new NgTestBed<NgForObjectItemInstanceTest>();
      var testFixture = await testBed.create();
      await testFixture.update((NgForObjectItemInstanceTest component) {
        var a = new Foo('titleA');
        component.items = <Foo>[a, a];
      });
      expect(testFixture.rootElement, hasTextContent('titleA;titleA;'));
    });

    test("should repeat over nested arrays", () async {
      var testBed = new NgTestBed<NgForNestedTest>();
      var testFixture = await testBed.create();
      await testFixture.update((NgForNestedTest component) {
        component.items = [
          ["a", "b"],
          ["c"]
        ];
      });
      expect(testFixture.rootElement, hasTextContent('a-2;b-2;|c-1;|'));
      await testFixture.update((NgForNestedTest component) {
        component.items = [
          ["e"],
          ["f", "g"]
        ];
      });
      expect(testFixture.rootElement, hasTextContent('e-1;|f-2;g-2;|'));
    });

    test(
        'should repeat over nested arrays with no intermediate '
        'element', () async {
      var testBed = new NgTestBed<NgForNestedTemplateTest>();
      var testFixture = await testBed.create();
      await testFixture.update((NgForNestedTemplateTest component) {
        component.items = [
          ["a", "b"],
          ["c"]
        ];
      });
      expect(testFixture.rootElement, hasTextContent('a-2;b-2;|c-1;|'));
      await testFixture.update((NgForNestedTemplateTest component) {
        component.items = [
          ["e"],
          ["f", "g"]
        ];
      });
      expect(testFixture.rootElement, hasTextContent('e-1;|f-2;g-2;|'));
    });

    test(
        'should repeat over nested ngIf that are the last node in '
        'the ngFor temlate', () async {
      var testBed = new NgTestBed<NgForNestedLastIfTest>();
      var testFixture = await testBed.create();
      var el = testFixture.rootElement;
      await testFixture.update((NgForNestedLastIfTest component) {
        component.items = [1];
      });
      expect(el, hasTextContent("0|even|"));

      await testFixture.update((NgForNestedLastIfTest component) {
        component.items.add(1);
      });
      expect(el, hasTextContent("0|even|1|"));

      await testFixture.update((NgForNestedLastIfTest component) {
        component.items.add(1);
      });
      expect(el, hasTextContent("0|even|1|2|even|"));
    });

    test("should display indices correctly", () async {
      var testBed = new NgTestBed<NgForIndexTest>();
      var testFixture = await testBed.create();
      await testFixture.update((NgForIndexTest component) {
        component.items = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
      });
      expect(testFixture.rootElement, hasTextContent("0123456789"));
      await testFixture.update((NgForIndexTest component) {
        component.items = [1, 2, 6, 7, 4, 3, 5, 8, 9, 0];
      });
      expect(testFixture.rootElement, hasTextContent("0123456789"));
    });

    test("should display first item correctly", () async {
      var testBed = new NgTestBed<NgForFirstTest>();
      var testFixture = await testBed.create();
      await testFixture.update((NgForFirstTest component) {
        component.items = [0, 1, 2];
      });
      expect(testFixture.rootElement, hasTextContent("truefalsefalse"));
      await testFixture.update((NgForFirstTest component) {
        component.items = [2, 1];
      });
      expect(testFixture.rootElement, hasTextContent("truefalse"));
    });

    test("should display last item correctly", () async {
      var testBed = new NgTestBed<NgForLastTest>();
      var testFixture = await testBed.create();
      await testFixture.update((NgForLastTest component) {
        component.items = [0, 1, 2];
      });
      expect(testFixture.rootElement, hasTextContent("falsefalsetrue"));
      await testFixture.update((NgForLastTest component) {
        component.items = [2, 1];
      });
      expect(testFixture.rootElement, hasTextContent("falsetrue"));
    });

    test("should display even items correctly", () async {
      var testBed = new NgTestBed<NgForEvenTest>();
      var testFixture = await testBed.create();
      await testFixture.update((NgForEvenTest component) {
        component.items = [0, 1, 2];
      });
      expect(testFixture.rootElement, hasTextContent("truefalsetrue"));
      await testFixture.update((NgForEvenTest component) {
        component.items = [2, 1];
      });
      expect(testFixture.rootElement, hasTextContent("truefalse"));
    });

    test("should display odd items correctly", () async {
      var testBed = new NgTestBed<NgForOddTest>();
      var testFixture = await testBed.create();
      await testFixture.update((NgForOddTest component) {
        component.items = [0, 1, 2, 3];
      });
      expect(testFixture.rootElement, hasTextContent("falsetruefalsetrue"));
      await testFixture.update((NgForOddTest component) {
        component.items = [2, 1];
      });
      expect(testFixture.rootElement, hasTextContent("falsetrue"));
    });

    test("should allow using a custom template", () async {
      var testBed = new NgTestBed<NgForCustomTemplateTest>();
      var testFixture = await testBed.create();
      var childComp =
          (getDebugNode(testFixture.rootElement) as DebugElement).children[0];
      await testFixture.update((NgForCustomTemplateTest component) {
        childComp.componentInstance.items = ["a", "b", "c"];
      });
      expect(childComp.nativeElement, hasTextContent("0: a;1: b;2: c;"));
    });

    test("should use a default template if a custom one is null", () async {
      var testBed = new NgTestBed<NgForCustomTemplateNullTest>();
      var testFixture = await testBed.create();
      var childComp =
          (getDebugNode(testFixture.rootElement) as DebugElement).children[0];
      await testFixture.update((NgForCustomTemplateNullTest component) {
        childComp.componentInstance.items = ["a", "b", "c"];
      });
      expect(childComp.nativeElement, hasTextContent("0: a;1: b;2: c;"));
    });

    test(
        'should use a custom template (precedence) when both default and a '
        'custom one are present', () async {
      var testBed = new NgTestBed<NgForCustomTemplatePrecedenceTest>();
      var testFixture = await testBed.create();
      var childComp =
          (getDebugNode(testFixture.rootElement) as DebugElement).children[0];
      await testFixture.update((NgForCustomTemplatePrecedenceTest component) {
        childComp.componentInstance.items = ["a", "b", "c"];
      });
      expect(childComp.nativeElement, hasTextContent("0: a;1: b;2: c;"));
    });

    group("track by", () {
      test("should not replace tracked items", () async {
        var testBed = new NgTestBed<TrackByIdTest>();
        var testFixture = await testBed.create();
        await testFixture.update((TrackByIdTest component) {
          component.items = [
            {"id": "a", "color": "blue"}
          ];
        });
        Element startElement = testFixture.rootElement.querySelector('p');
        // Set items to new list instance (same trackBy identity).
        await testFixture.update((TrackByIdTest component) {
          component.items = [
            {"id": "a", "color": "red"}
          ];
        });
        Element endElement = testFixture.rootElement.querySelector('p');
        // Since ids are identical element should have stayed stable.
        expect(startElement, endElement);
      });

      test("should update implicit local variable on view", () async {
        var testBed = new NgTestBed<TrackByIdTest>();
        var testFixture = await testBed.create();
        await testFixture.update((TrackByIdTest component) {
          component.items = [
            {"id": "a", "color": "blue"}
          ];
        });
        Element startElement = testFixture.rootElement.querySelector('p');
        expect(startElement, hasTextContent("{id: a, color: blue}"));
        // Set items to new list instance (same trackBy identity).
        await testFixture.update((TrackByIdTest component) {
          component.items = [
            {"id": "a", "color": "red"}
          ];
        });
        expect(startElement, hasTextContent("{id: a, color: red}"));
      });

      test("should move items around and updated (reorder)", () async {
        var testBed = new NgTestBed<TrackByIdTest>();
        var testFixture = await testBed.create();
        await testFixture.update((TrackByIdTest component) {
          component.items = [
            {"id": "a", "color": "blue"},
            {"id": "b", "color": "yellow"}
          ];
        });
        var startElements = testFixture.rootElement.querySelectorAll('p');
        await testFixture.update((TrackByIdTest component) {
          component.items = [
            {"id": "b", "color": "red"},
            {"id": "a", "color": "orange"}
          ];
        });
        var endElements = testFixture.rootElement.querySelectorAll('p');
        expect(startElements[0], endElements[1]);
        expect(startElements[1], endElements[0]);
      });

      test(
          'should handle added and removed items properly when tracking '
          'by index', () async {
        var testBed = new NgTestBed<TrackByIndexTest>();
        var testFixture = await testBed.create();
        await testFixture.update((TrackByIndexTest component) {
          component.items = ["a", "b", "c", "d"];
        });
        await testFixture.update((TrackByIndexTest component) {
          component.items = ["e", "f", "g", "h"];
        });
        await testFixture.update((TrackByIndexTest component) {
          component.items = ["e", "f", "h"];
        });
        expect(testFixture.rootElement, hasTextContent("efh"));
      });

      test(
          'should remove by index when list item or '
          'it\'s hash changes', () async {
        var testBed = new NgTestBed<ObjectEditorComponent>();
        var testFixture = await testBed.create();
        await testFixture.update((ObjectEditorComponent component) {
          component.entities = ['a1', 'b1', 'c1', 'd1', 'e1', 'f1', 'g1', 'h1'];
        });
        await testFixture.update((ObjectEditorComponent component) {
          component.entities = ['a1', 'c1', 'e1', 'f1', 'h1'];
        });
        await testFixture.update((ObjectEditorComponent component) {
          component.entities[3] = 'moved-f1';
        });
        await testFixture.update((ObjectEditorComponent component) {
          component.removeEdited(3);
        });
        await testFixture.update((ObjectEditorComponent component) {
          component.entities[2] = 'moved-e1';
          component.removeEdited(2);
        });
      });
    });
  });
}

class BaseTestComponent {
  List<int> items;

  BaseTestComponent() {
    items = <int>[1, 2, 3];
  }
  String trackById(int index, dynamic item) {
    return '${item["id"]}';
  }

  int trackByIndex(int index, dynamic item) {
    return index;
  }
}

@Component(
    selector: 'ngfor-items-test',
    template: '<div><copy-me template="ngFor let item of items">'
        '{{item.toString()}};</copy-me></div>',
    directives: const [NgFor])
class NgForItemsTest extends BaseTestComponent {
  @ContentChild(TemplateRef)
  TemplateRef contentTpl;
}

@Component(
    selector: 'ngfor-options-test',
    template: '<ul><li template="ngFor let item of items">{{item["name"]}};'
        '</li></ul>',
    directives: const [NgFor])
class NgForOptionsTest {
  @ContentChild(TemplateRef)
  TemplateRef contentTpl;
  var items;

  NgForOptionsTest() {
    items = [];
  }
  String trackById(int index, dynamic item) {
    return item["id"];
  }

  int trackByIndex(int index, dynamic item) {
    return index;
  }
}

@Component(
    selector: 'ngfor-null-test',
    template: '<ul><li template="ngFor let item of null">{{item}};</li></ul>',
    directives: const [NgFor])
class NgForNullTest extends NgForOptionsTest {}

@Component(
    selector: 'ngfor-object-test',
    template: '<div><copy-me template="ngFor let item of items">'
        '{{item.toString()}};</copy-me></div>',
    directives: const [NgFor])
class NgForObjectItemInstanceTest {
  List items;

  NgForObjectItemInstanceTest() {
    items = <dynamic>[1, 2, 3];
  }

  @ContentChild(TemplateRef)
  TemplateRef contentTpl;
}

@Component(
    selector: 'ng-for-nested',
    template: '<div>'
        '<div template="ngFor let item of items">'
        '<div template="ngFor let subitem of item">'
        '{{subitem}}-{{item.length}};'
        '</div>|'
        '</div>'
        '</div>',
    directives: const [NgFor],
    preserveWhitespace: false)
class NgForNestedTest {
  List items;
}

@Component(
    selector: 'ng-for-nested-template',
    template: '<div>'
        '<template ngFor let-item [ngForOf]="items">'
        '<div template="ngFor let subitem of item">'
        '{{subitem}}-{{item.length}};'
        '</div>|</template></div>',
    directives: const [NgFor],
    preserveWhitespace: false)
class NgForNestedTemplateTest {
  List items;
}

@Component(
    selector: 'ng-for-nested-lastif',
    template: '<div><template ngFor let-item [ngForOf]="items" '
        'let-i="index"><div>{{i}}|</div>'
        '<div *ngIf="i % 2 == 0">even|</div></template></div>',
    directives: const [NgIf, NgFor],
    preserveWhitespace: false)
class NgForNestedLastIfTest {
  List items;
}

@Component(
    selector: 'ng-for-index-test',
    template: '<div><copy-me template="ngFor: let item of items; let i=index">'
        '{{i.toString()}}</copy-me></div>',
    directives: const [NgFor])
class NgForIndexTest {
  List items;
}

@Component(
    selector: 'ng-for-first-test',
    template: '<div><copy-me template="ngFor: let item of items; '
        'let isFirst=first">{{isFirst.toString()}}</copy-me></div>',
    directives: const [NgFor])
class NgForFirstTest {
  List items;
}

@Component(
    selector: 'ng-for-last-test',
    template: '<div><copy-me template="ngFor: let item of items; '
        'let isLast=last\">{{isLast.toString()}}</copy-me></div>',
    directives: const [NgFor])
class NgForLastTest {
  List items;
}

@Component(
    selector: 'ng-for-even-test',
    template: '<div><copy-me template="ngFor: let item of items; '
        'let isEven=even\">{{isEven.toString()}}</copy-me></div>',
    directives: const [NgFor])
class NgForEvenTest {
  List items;
}

@Component(
    selector: 'ng-for-odd-test',
    template: '<div><copy-me template=\"ngFor: let item of items; '
        'let isOdd=odd\">{{isOdd.toString()}}</copy-me></div>',
    directives: const [NgFor])
class NgForOddTest {
  List items;
}

@Component(
    selector: 'ng-for-custom-template-container',
    template: '<test-cmp><li template="let item; let i=index">'
        '{{i}}: {{item}};</li></test-cmp>',
    directives: const [NgFor, NgForCustomTemplateComponent])
class NgForCustomTemplateTest {
  List items;
}

@Component(
    selector: 'test-cmp',
    template: '<ul><template ngFor [ngForOf]="items" '
        '[ngForTemplate]="contentTpl"></template></ul>',
    directives: const [NgFor])
class NgForCustomTemplateComponent {
  @ContentChild(TemplateRef)
  TemplateRef contentTpl;
  List items;
}

@Component(
    selector: 'ng-for-custom-template-container2',
    template: '<test-cmp></test-cmp>',
    directives: const [NgFor, NgForCustomTemplateNullComponent])
class NgForCustomTemplateNullTest {
  List items;
}

@Component(
    selector: 'test-cmp',
    template: '<ul><template ngFor let-item [ngForOf]="items"'
        '[ngForTemplate]="contentTpl" let-i="index">'
        '{{i}}: {{item}};</template></ul>',
    directives: const [NgFor])
class NgForCustomTemplateNullComponent {
  @ContentChild(TemplateRef)
  TemplateRef contentTpl;
  List items;
}

@Component(
    selector: 'ng-for-custom-template-precedence',
    template: '<test-cmp><li template="let item; let i=index">'
        '{{i}}: {{item}};</li></test-cmp>',
    directives: const [NgFor, NgForCustomTemplatePrecedenceComponent])
class NgForCustomTemplatePrecedenceTest {
  List items;
}

@Component(
    selector: 'test-cmp',
    template: '<ul><template ngFor let-item [ngForOf]="items"'
        '[ngForTemplate]="contentTpl" let-i="index">'
        '{{i}}=> {{item}};</template></ul>',
    directives: const [NgFor])
class NgForCustomTemplatePrecedenceComponent {
  @ContentChild(TemplateRef)
  TemplateRef contentTpl;
  List items;
}

class Foo {
  final String title;
  Foo(this.title);
  @override
  toString() => title;
}

@Component(
    selector: 'track-by-id-test',
    template: '<template ngFor let-item [ngForOf]="items" '
        '[ngForTrackBy]="trackById" let-i="index">'
        '<p>{{items[i]}}</p><div>{{colorOfItem(items[i])}}</div>'
        '</template>',
    directives: const [NgFor])
class TrackByIdTest {
  List items;
  String trackById(num index, dynamic item) {
    return item["id"];
  }

  String colorOfItem(Map item) => item['color'];
}

@Component(
    selector: 'track-by-index-test',
    template: '<div><template ngFor let-item [ngForOf]="items" '
        '[ngForTrackBy]="trackByIndex">{{item}}</template></div>',
    directives: const [NgFor])
class TrackByIndexTest {
  List items;
  int trackByIndex(int index, dynamic item) {
    return index;
  }

  String colorOfItem(Map item) => item['color'];
}

@Component(
    selector: 'object-editor',
    template: '<div *ngFor="let entity of entities; let i=index">'
        '<object-to-edit [objectId]="entity"></object-to-edit>'
        '<button (click)="removeEdited(i)">remove</button>'
        '<button (click)="mutateItem(i)">mutate</button>'
        '</div>',
    directives: const [ObjectToEdit, NgFor])
class ObjectEditorComponent {
  List<String> entities;

  void removeEdited(int index) {
    entities.removeAt(index);
  }

  void mutateItem(int index) {
    entities[index] = 'z' + entities[index];
  }
}

@Component(selector: 'object-to-edit', template: '<p>{{objectId}}</p>')
class ObjectToEdit {
  dynamic _value;
  String get objectId => '$_value';

  @Input()
  set objectId(dynamic value) {
    _value = value;
  }
}
