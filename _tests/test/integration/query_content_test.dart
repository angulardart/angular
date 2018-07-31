@TestOn('browser')

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:_tests/query_tests.dart';
import 'package:test/test.dart';

import 'query_content_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();
  tearDown(disposeAnyRunningTest);

  group('List', () {
    testContentChildren(
      contentChildren: TestCase(
        NgTestBed<TestContentChildrenList>(),
        [1, 2, 3],
      ),
    );
  });
}

@Component(
  selector: 'content',
  template: '<ng-content></ng-content>',
)
class ContentChildrenComponent extends HasChildren<ValueDirective> {
  @override
  @ContentChildren(ValueDirective)
  List actualChildren;
}

@Component(
  selector: 'content',
  template: '<ng-content></ng-content>',
)
class ContentChildComponent extends HasChild<ValueDirective> {
  @override
  @ContentChild(ValueDirective)
  ValueDirective child;
}

@Component(
  selector: 'test',
  directives: [
    ContentChildrenComponent,
    ValueDirective,
  ],
  template: r'''
    <content #comp>
      <value [value]="1"></value>
      <value [value]="2"></value>
      <value [value]="3"></value>
    </content>
  ''',
)
class TestContentChildren extends HasChildren<ValueDirective> {
  @ViewChild('comp')
  HasChildren<ValueDirective> content;

  @override
  List get actualChildren => content.actualChildren;
}

@Component(
  selector: 'test',
  directives: [
    ContentChildComponent,
    ValueDirective,
  ],
  template: r'''
    <content #comp>
      <value [value]="1"></value>
    </content>
  ''',
)
class TestContentChild extends HasChild<ValueDirective> {
  @ViewChild('comp')
  HasChild<ValueDirective> content;

  @override
  ValueDirective get child => content.child;
}

@Component(
  selector: 'content',
  template: '<ng-content></ng-content>',
)
class ContentChildrenComponentList extends HasChildren<ValueDirective> {
  @override
  @ContentChildren(ValueDirective)
  List<ValueDirective> actualChildren;
}

@Component(
  selector: 'test',
  directives: [
    ContentChildrenComponentList,
    ValueDirective,
  ],
  template: r'''
    <content #comp>
      <value [value]="1"></value>
      <value [value]="2"></value>
      <value [value]="3"></value>
    </content>
  ''',
)
class TestContentChildrenList extends HasChildren<ValueDirective> {
  @ViewChild('comp')
  HasChildren<ValueDirective> content;

  @override
  List<ValueDirective> get actualChildren => content.actualChildren;
}
