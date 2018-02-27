@TestOn('browser')

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:_tests/query_tests.dart';
import 'package:test/test.dart';

import 'query_view_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();
  tearDown(disposeAnyRunningTest);

  group('QueryList', () {
    testViewChildren(
      directViewChildren: new TestCase(
        new NgTestBed<TestDirectViewChildren>(),
        [1, 2, 3],
      ),
      directViewChild: new TestCase(
        new NgTestBed<TestDirectViewChild>(),
        [1],
      ),
      viewChildrenAndEmbedded: new TestCase(
        new NgTestBed<TestViewChildrenAndEmbedded>(),
        [1, 3],
      ),
      viewChildEmbedded: new TestCase(
        new NgTestBed<TestDirectViewChildEmbedded>(),
        [1],
      ),
      viewChildNestedOffOn: new TestCase(
        new NgTestBed<TestViewChildNestedOnOff>(),
        [],
      ),
      viewChildNestedNgIfOffOn: new TestCase(
        new NgTestBed<TestViewChildNestedNgIfOffOn>(),
        [],
      ),
      viewChildNestedNgIfOffOnAsync: new TestCase(
        new NgTestBed<TestViewChildNestedNgIfOffOnAsync>(),
        [],
      ),
    );
  });

  group('List', () {
    testViewChildren(
      directViewChildren: new TestCase(
        new NgTestBed<TestDirectViewChildrenList>(),
        [1, 2, 3],
      ),
      viewChildrenAndEmbedded: new TestCase(
        new NgTestBed<TestViewChildrenAndEmbeddedList>(),
        [1, 3],
      ),
    );

    test('should work even when the property is a setter', () async {
      final testBed = new NgTestBed<TestDirectViewChildrenListSetter>();
      final fixture = await testBed.create();
      expect(fixture, hasChildValues([1, 2, 3]));
    });

    test('should work in a multiple nesting scenario', () async {
      // This is a regression case based on internal code.
      final testBed = new NgTestBed<TestNestedNgForQueriesList>();
      final fixture = await testBed.create();
      expect(
        fixture.assertOnlyInstance.taggedDivs.map((e) => e.nativeElement.text),
        ['1', '2', '3'],
      );
    });

    test('should work in a multiple nesting+static scenario', () async {
      // This is a regression case based on internal code.
      final testBed = new NgTestBed<TestNestedAndStaticNgForQueriesList>();
      final fixture = await testBed.create();
      expect(
        fixture.assertOnlyInstance.taggedDivs.map((e) => e.nativeElement.text),
        ['1', '2', '3', '4', '5', '6', '7'],
      );
    });
  });
}

@Component(
  selector: 'test',
  directives: const [
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
  directives: const [
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
  directives: const [
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
  directives: const [
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
  directives: const [
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
  directives: const [
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
  directives: const [
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
  directives: const [
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
  directives: const [
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
  directives: const [
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
  directives: const [
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

  @ViewChildren('taggedDiv')
  List<ElementRef> taggedDivs;
}

@Component(
  selector: 'test',
  directives: const [
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

  @ViewChildren('taggedDiv')
  List<ElementRef> taggedDivs;
}
