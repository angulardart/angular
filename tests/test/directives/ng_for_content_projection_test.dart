import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_for_content_projection_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('should re-order queries when ngFor performs a re-order', () {
    late NgTestFixture<TestNgForBase> fixture;

    Future<void> forceReorder132() {
      return fixture.update((c) {
        c.items = [1, 3, 2];
      });
    }

    test('@ContentChildren', () async {
      fixture = await NgTestBed(
        ng.createTestNgForReorderContentChildrenFactory(),
      ).create(
        beforeChangeDetection: (c) => c.items = [1, 2, 3],
      );

      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        ['1', '2', '3'],
      );
      await forceReorder132();
      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        ['1', '3', '2'],
      );
    });

    test('@ContentChildren, when nested', () async {
      fixture = await NgTestBed(
        ng.createTestNestedNgForReorderContentChildrenFactory(),
      ).create(
        beforeChangeDetection: (c) => c.items = [1, 2, 3],
      );

      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        ['1', '2', '3'],
      );
      await forceReorder132();
      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        ['1', '3', '2'],
      );
    });

    test('@ContentChildren, when nested with a #referenced child', () async {
      fixture = await NgTestBed(
        ng.createTestReferencedNgForReorderContentChildrenFactory(),
      ).create(
        beforeChangeDetection: (c) => c.items = [1, 2, 3],
      );

      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        ['1', '2', '3'],
      );
      await forceReorder132();
      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        // TODO(b/129297484): Should be "['1', '3', '2']".
        ['1', '2', '3'],
      );
    });

    test('@ViewChildren', () async {
      fixture = await NgTestBed(
        ng.createTestNgForReorderViewChildrenFactory(),
      ).create(
        beforeChangeDetection: (c) => c.items = [1, 2, 3],
      );

      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        ['1', '2', '3'],
      );
      await forceReorder132();
      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        ['1', '3', '2'],
      );
    });

    test('@ViewChildren, when nested', () async {
      fixture = await NgTestBed(
        ng.createTestNestedNgForReorderViewChildrenFactory(),
      ).create(
        beforeChangeDetection: (c) => c.items = [1, 2, 3],
      );

      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        ['1', '2', '3'],
      );
      await forceReorder132();
      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        ['1', '3', '2'],
      );
    });

    test('@ViewChildren, when nested with a #referenced child', () async {
      fixture = await NgTestBed(
        ng.createTestReferencedNgForReorderViewChildrenFactory(),
      ).create(
        beforeChangeDetection: (c) => c.items = [1, 2, 3],
      );

      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        ['1', '2', '3'],
      );
      await forceReorder132();
      expect(
        fixture.assertOnlyInstance.children!.map((h) => h.text),
        // TODO(b/129297484): Should be "['1', '3', '2']".
        ['1', '2', '3'],
      );
    });
  });
}

abstract class TestNgForBase {
  @Input()
  List<int>? items;

  List<HtmlElement>? get children;
}

@Component(
  selector: 'test-ng-for-reorder-content',
  directives: [
    ContentProjectedChild,
    NgFor,
  ],
  template: '''
    <content-projected-child>
      <ul>
        <li #listItem *ngFor="let i of items">{{i}}</li>
      </ul>
    </content-projected-child>
  ''',
)
class TestNgForReorderContentChildren extends TestNgForBase {
  @ViewChild(ContentProjectedChild)
  ContentProjectedChild? child;

  @override
  List<HtmlElement>? get children => child!.children;
}

@Component(
  selector: 'test-ng-for-reorder-content',
  directives: [
    ContentProjectedChild,
    NgFor,
    NgIf,
  ],
  template: '''
    <content-projected-child>
      <ul>
        <li #listItem *ngFor="let i of items">
          <ng-container *ngIf="true">{{i}}</ng-container>
        </li>
      </ul>
    </content-projected-child>
  ''',
)
class TestNestedNgForReorderContentChildren extends TestNgForBase {
  @ViewChild(ContentProjectedChild)
  ContentProjectedChild? child;

  @override
  List<HtmlElement>? get children => child!.children;
}

@Component(
  selector: 'test-ng-for-reorder-content',
  directives: [
    ContentProjectedChild,
    NgFor,
    NgIf,
  ],
  template: '''
    <content-projected-child>
      <ul>
        <li *ngFor="let i of items">
          <!-- Note that the #listItem reference moves below -->
          <span #listItem *ngIf="true">{{i}}</span>
        </li>
      </ul>
    </content-projected-child>
  ''',
)
class TestReferencedNgForReorderContentChildren extends TestNgForBase {
  @ViewChild(ContentProjectedChild)
  ContentProjectedChild? child;

  @override
  List<HtmlElement>? get children => child!.children;
}

@Component(
  selector: 'content-projected-child',
  template: '<ng-content></ng-content>',
)
class ContentProjectedChild {
  @ContentChildren('listItem')
  List<HtmlElement>? children;
}

@Component(
  selector: 'test-ng-for-reorder-view',
  directives: [
    NgFor,
  ],
  template: '''
    <ul>
      <li #listItem *ngFor="let i of items">{{i}}</li>
    </ul>
  ''',
)
class TestNgForReorderViewChildren extends TestNgForBase {
  @ViewChildren('listItem')
  @override
  List<HtmlElement>? children;
}

@Component(
  selector: 'test-ng-for-reorder-view',
  directives: [
    NgFor,
    NgIf,
  ],
  template: '''
    <ul>
      <li #listItem *ngFor="let i of items">
        <span *ngIf="true">{{i}}</span>
      </li>
    </ul>
  ''',
)
class TestNestedNgForReorderViewChildren extends TestNgForBase {
  @ViewChildren('listItem')
  @override
  List<HtmlElement>? children;
}

@Component(
  selector: 'test-ng-for-reorder-view',
  directives: [
    NgFor,
    NgIf,
  ],
  template: '''
    <ul>
      <li *ngFor="let i of items">
        <span #listItem *ngIf="true">{{i}}</span>
      </li>
    </ul>
  ''',
)
class TestReferencedNgForReorderViewChildren extends TestNgForBase {
  @ViewChildren('listItem')
  @override
  List<HtmlElement>? children;
}
