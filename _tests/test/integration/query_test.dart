@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:_tests/query_tests.dart';
import 'package:test/test.dart';

import 'query_test.template.dart' as ng_generated;

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
  QueryList actualChildren;
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
  QueryList actualChildren;
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
