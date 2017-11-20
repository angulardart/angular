@Tags(const ['codegen'])
@TestOn('browser')

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
    );
  });
}

@Component(
  selector: 'test-direct-view-children',
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
  selector: 'test-direct-view-child',
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
  selector: 'test-view-children-and-embedded',
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
  selector: 'test-direct-view-child',
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
