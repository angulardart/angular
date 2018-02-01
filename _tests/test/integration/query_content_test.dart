@TestOn('browser')

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:_tests/query_tests.dart';
import 'package:test/test.dart';

import 'query_content_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();
  tearDown(disposeAnyRunningTest);

  group('QueryList', () {
    testContentChildren(
      contentChildren: new TestCase(
        new NgTestBed<TestContentChildren>(),
        [1, 2, 3],
      ),
      contentChild: new TestCase(
        new NgTestBed<TestContentChild>(),
        [1],
      ),
    );
  });

  group('List', () {
    testContentChildren(
      contentChildren: new TestCase(
        new NgTestBed<TestContentChildrenList>(),
        [1, 2, 3],
      ),
    );
  });
}

@Component(
  selector: 'content',
  template: '<ng-content></ng-content>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ContentChildrenComponent extends HasChildren<ValueDirective> {
  @override
  @ContentChildren(ValueDirective)
  List actualChildren;
}

@Component(
  selector: 'content',
  template: '<ng-content></ng-content>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ContentChildComponent extends HasChild<ValueDirective> {
  @override
  @ContentChild(ValueDirective)
  ValueDirective child;
}

@Component(
  selector: 'test',
  directives: const [
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestContentChildren extends HasChildren<ValueDirective> {
  @ViewChild('comp')
  HasChildren<ValueDirective> content;

  @override
  List get actualChildren => content.actualChildren;
}

@Component(
  selector: 'test',
  directives: const [
    ContentChildComponent,
    ValueDirective,
  ],
  template: r'''
    <content #comp>
      <value [value]="1"></value>
    </content>
  ''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ContentChildrenComponentList extends HasChildren<ValueDirective> {
  @override
  @ContentChildren(ValueDirective)
  List<ValueDirective> actualChildren;
}

@Component(
  selector: 'test',
  directives: const [
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestContentChildrenList extends HasChildren<ValueDirective> {
  @ViewChild('comp')
  HasChildren<ValueDirective> content;

  @override
  List<ValueDirective> get actualChildren => content.actualChildren;
}
