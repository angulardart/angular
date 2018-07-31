@TestOn('browser')

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:_tests/query_tests.dart';
import 'package:test/test.dart';

import 'query_view_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();
  tearDown(disposeAnyRunningTest);

  group('List', () {
    testViewChildren(
      directViewChildren: TestCase(
        NgTestBed<TestDirectViewChildrenList>(),
        [1, 2, 3],
      ),
      viewChildrenAndEmbedded: TestCase(
        NgTestBed<TestViewChildrenAndEmbeddedList>(),
        [1, 3],
      ),
    );

    test('should work even when the property is a setter', () async {
      final testBed = NgTestBed<TestDirectViewChildrenListSetter>();
      final fixture = await testBed.create();
      expect(fixture, hasChildValues([1, 2, 3]));
    });

    test('should work in a multiple nesting scenario', () async {
      // This is a regression case based on internal code.
      final testBed = NgTestBed<TestNestedNgForQueriesList>();
      final fixture = await testBed.create();
      expect(
        fixture.assertOnlyInstance.taggedDivs.map((e) => e.text),
        ['1', '2', '3'],
      );
    });

    test('should work in a multiple nesting+static scenario', () async {
      // This is a regression case based on internal code.
      final testBed = NgTestBed<TestNestedAndStaticNgForQueriesList>();
      final fixture = await testBed.create();
      expect(
        fixture.assertOnlyInstance.taggedDivs.map((e) => e.text),
        ['1', '2', '3', '4', '5', '6', '7'],
      );
    });

    test('should work on type selectors that are not directives', () async {
      final testBed = NgTestBed<TestNonDirectiveChildSelector>();
      final fixture = await testBed.create();
      expect(fixture.assertOnlyInstance.children, hasLength(3));
      expect(fixture.assertOnlyInstance.services, hasLength(3));
    });
  });
}

@Component(
  selector: 'test',
  directives: [
    ValueDirective,
  ],
  template: r'''
    <value [value]="1"></value>
    <value [value]="2"></value>
    <value [value]="3"></value>
  ''',
)
class TestDirectViewChildren extends HasChildren<ValueDirective> {
  @override
  @ViewChildren(ValueDirective)
  List actualChildren;
}

@Component(
  selector: 'test',
  directives: [
    ValueDirective,
  ],
  template: r'''
    <value [value]="1"></value>
  ''',
)
class TestDirectViewChild extends HasChild<ValueDirective> {
  @override
  @ViewChild(ValueDirective)
  ValueDirective child;
}

@Component(
  selector: 'test',
  directives: [
    AlwaysShowDirective,
    ValueDirective,
  ],
  template: r'''
    <value [value]="1"></value>
    <template neverShow>
      <value [value]="2"></value>
    </template>
    <template alwaysShow>
      <value [value]="3"></value>
    </template>
  ''',
)
class TestViewChildrenAndEmbedded extends HasChildren<ValueDirective> {
  @override
  @ViewChildren(ValueDirective)
  List actualChildren;
}

@Component(
  selector: 'test',
  directives: [
    AlwaysShowDirective,
    ValueDirective,
  ],
  template: r'''
    <template alwaysShow>
      <value [value]="1"></value>
    </template>
  ''',
)
class TestDirectViewChildEmbedded extends HasChild<ValueDirective> {
  @override
  @ViewChild(ValueDirective)
  ValueDirective child;
}

@Component(
  selector: 'test',
  directives: [
    AlwaysShowDirective,
    NeverShowDirective,
    ValueDirective,
  ],
  template: r'''
    <template alwaysShow>
      <template neverShow>
        <value [value]="1"></value>
      </template>
    </template>
  ''',
)
class TestViewChildNestedOnOff extends HasChild<ValueDirective> {
  @override
  @ViewChild(ValueDirective)
  ValueDirective child;
}

@Component(
  selector: 'test',
  directives: [
    NgIf,
    ValueDirective,
  ],
  template: r'''
    <div *ngIf="outerDiv">
      <div *ngIf="innerDiv">
        <value [value]="1"></value>
      </div>
    </div>
  ''',
)
class TestViewChildNestedNgIfOffOn extends HasChild<ValueDirective> {
  var outerDiv = false;
  var innerDiv = true;

  @override
  @ViewChild(ValueDirective)
  ValueDirective child;
}

@Component(
  selector: 'test-regression-embedded-ngif-false-true-async',
  directives: [
    NgIf,
    ValueDirective,
  ],
  template: r'''
    <div *ngIf="outerDiv">
      <div *ngIf="innerDiv">
        <value [value]="1"></value>
      </div>
    </div>
  ''',
)
class TestViewChildNestedNgIfOffOnAsync extends HasChild<ValueDirective>
    implements AfterViewInit {
  var outerDiv = true;
  var innerDiv = true;

  @override
  void ngAfterViewInit() {
    scheduleMicrotask(() {
      outerDiv = false;
    });
  }

  @override
  @ViewChild(ValueDirective)
  ValueDirective child;
}

@Component(
  selector: 'test',
  directives: [
    ValueDirective,
  ],
  template: r'''
    <value [value]="1"></value>
    <value [value]="2"></value>
    <value [value]="3"></value>
  ''',
)
class TestDirectViewChildrenList extends HasChildren<ValueDirective> {
  @override
  @ViewChildren(ValueDirective)
  List<ValueDirective> actualChildren;
}

@Component(
  selector: 'test',
  directives: [
    ValueDirective,
  ],
  template: r'''
    <value [value]="1"></value>
    <value [value]="2"></value>
    <value [value]="3"></value>
  ''',
)
class TestDirectViewChildrenListSetter extends HasChildren<ValueDirective> {
  @ViewChildren(ValueDirective)
  set actualChildrenSetter(List<ValueDirective> actualChildren) {
    this.actualChildren = actualChildren;
  }

  @override
  Iterable actualChildren;
}

@Component(
  selector: 'test',
  directives: [
    AlwaysShowDirective,
    ValueDirective,
  ],
  template: r'''
    <value [value]="1"></value>
    <template neverShow>
      <value [value]="2"></value>
    </template>
    <template alwaysShow>
      <value [value]="3"></value>
    </template>
  ''',
)
class TestViewChildrenAndEmbeddedList extends HasChildren<ValueDirective> {
  @override
  @ViewChildren(ValueDirective)
  List<ValueDirective> actualChildren;
}

@Component(
  selector: 'test',
  directives: [
    AlwaysShowDirective,
    NgFor,
  ],
  template: r'''
    <div *alwaysShow>
      <div *alwaysShow>
        <div *ngFor="let item of items" #taggedDiv>{{item}}</div>
      </div>
    </div>
  ''',
)
class TestNestedNgForQueriesList {
  final items = [1, 2, 3];

  @ViewChildren('taggedDiv', read: Element)
  List<Element> taggedDivs;
}

@Component(
  selector: 'test',
  directives: [
    AlwaysShowDirective,
    NgFor,
  ],
  template: r'''
    <div #taggedDiv>1</div>
    <div *alwaysShow>
      <div #taggedDiv>2</div>
      <div *alwaysShow>
        <div #taggedDiv>3</div>
        <div *ngFor="let item of items" #taggedDiv>{{item}}</div>
      </div>
    </div>
    <div #taggedDiv>7</div>
  ''',
)
class TestNestedAndStaticNgForQueriesList {
  final items = [4, 5, 6];

  @ViewChildren('taggedDiv', read: Element)
  List<Element> taggedDivs;
}

abstract class Queryable {}

@Directive(
  selector: 'queryable-directive',
  providers: [
    ExistingProvider(Queryable, QueryableDirective),
    ClassProvider(InjectableService),
  ],
)
class QueryableDirective implements Queryable {}

class InjectableService {}

@Component(
  selector: 'test-non-directive-child-selector',
  directives: [
    NgIf,
    QueryableDirective,
  ],
  template: r'''
    <queryable-directive></queryable-directive>
    <queryable-directive></queryable-directive>
    <queryable-directive *ngIf="showLastDirective"></queryable-directive>
  ''',
)
class TestNonDirectiveChildSelector {
  @ViewChildren(Queryable)
  List<Queryable> children;

  @ViewChildren(InjectableService)
  List<InjectableService> services;

  bool showLastDirective = true;
}
