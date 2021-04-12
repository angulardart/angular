import 'package:test/test.dart';
import 'package:_tests/query_tests.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'query_content_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('List', () {
    testContentChildren(
      contentChildren: TestCase(
        NgTestBed(ng.createTestContentChildrenListFactory()),
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
  List<ValueDirective>? children;
}

@Component(
  selector: 'content',
  template: '<ng-content></ng-content>',
)
class ContentChildComponent extends HasChild<ValueDirective> {
  @override
  @ContentChild(ValueDirective)
  ValueDirective? child;
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
  HasChildren<ValueDirective>? content;

  @override
  List<ValueDirective>? get children => content!.children;
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
  HasChild<ValueDirective>? content;

  @override
  ValueDirective? get child => content!.child;
}

@Component(
  selector: 'content',
  template: '<ng-content></ng-content>',
)
class ContentChildrenComponentList extends HasChildren<ValueDirective> {
  @override
  @ContentChildren(ValueDirective)
  List<ValueDirective>? children;
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
  HasChildren<ValueDirective>? content;

  @override
  List<ValueDirective>? get children => content!.children;
}
