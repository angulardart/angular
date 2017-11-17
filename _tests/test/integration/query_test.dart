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
      directViewChildren: new NgTestBed<TestDirectViewChildren>(),
    );
  });
}

@Component(
  selector: 'test-view-children',
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
