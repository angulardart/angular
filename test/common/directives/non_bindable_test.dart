@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  group('ngNonBindable', () {
    tearDown(() => disposeAnyRunningTest());

    test('should not interpolate children', () async {
      var testBed = new NgTestBed<NoInterpolationTest>();
      var testFixture = await testBed.create();
      expect(testFixture.text, 'foo{{text}}');
    });
    test('should ignore directives on child nodes', () async {
      var testBed = new NgTestBed<IgnoreDirectivesTest>();
      var testFixture = await testBed.create();
      var span = testFixture.rootElement.querySelector('#child');
      expect(span.classes, isNot(contains('compiled')));
    });
    test('should trigger directives on the same node', () async {
      var testBed = new NgTestBed<DirectiveSameNodeTest>();
      var testFixture = await testBed.create();
      var span = testFixture.rootElement.querySelector('#child');
      expect(span.classes, contains('compiled'));
    });
  });
}

@Directive(selector: '[test-dec]')
class TestDirective {
  TestDirective(ElementRef el) {
    (el.nativeElement as Element).classes.add('compiled');
  }
}

@Component(
  selector: 'no-interpolation-test',
  template: '<div>{{text}}<span ngNonBindable>{{text}}</span></div>',
)
class NoInterpolationTest {
  String text = 'foo';
}

@Component(
  selector: 'ignore-directives-test',
  directives: const [TestDirective],
  template: '<div ngNonBindable><span id=child test-dec>{{text}}</span></div>',
)
class IgnoreDirectivesTest {
  String text = 'foo';
}

@Component(
  selector: 'directive-same-node-test',
  directives: const [TestDirective],
  template: '<div><span id=child ngNonBindable test-dec>{{text}}</span></div>',
)
class DirectiveSameNodeTest {
  String text = 'foo';
}
