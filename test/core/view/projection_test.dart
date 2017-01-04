@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.core.view.projection_test;

import 'dart:html';
import 'package:angular2/angular2.dart';
import 'package:angular2/testing_experimental.dart';
import 'package:angular2/src/debug/debug_node.dart';
import 'package:angular2/src/testing/matchers.dart';
import 'package:test/test.dart';

void main() {
  group('projection', () {
    tearDown(() => disposeAnyRunningTest());

    test('should support simple html elements', () async {
      var testBed = new NgTestBed<ContainerWithSimpleComponent>();
      var testFixture = await testBed.create();
      Element element = testFixture.element;
      Element childElement = element.querySelector('simple');
      expect(childElement, hasTextContent('SIMPLE(A)'));
    });

    test(
        'should support simple components with text interpolation projected'
        'into child', () async {
      var testBed = new NgTestBed<ContainerWithProjectedInterpolation>();
      var testFixture = await testBed.create();
      Element element = testFixture.element;
      expect(element, hasTextContent('START(SIMPLE(VALUE1))END'));
    });

    test(
        'should support simple components with text interpolation projected'
        'into child where ng-content is nested inside an element', () async {
      var testBed = new NgTestBed<ContainerWithProjectedInterpolationNested>();
      var testFixture = await testBed.create();
      Element element = testFixture.element;
      expect(element, hasTextContent('START(SIMPLE(VALUE2))END'));
    });

    test(
        'should support simple components with text interpolation projected'
        'into child with bindings following ng-content', () async {
      var testBed = new NgTestBed<ContainerWithProjectedInterpolationBound>();
      var testFixture = await testBed.create();
      Element element = testFixture.element;
      expect(element, hasTextContent('START(SIMPLE(VALUE3XY))END'));
    });

    test('should redistribute when the shadow dom changes', () async {
      var testBed = new NgTestBed<ContainerABCWithConditionalComponent>();
      var testFixture = await testBed.create();
      Element element = testFixture.element;
      expect(element, hasTextContent("(, BC)"));

      DebugElement debugElement = getDebugNode(testFixture.element);

      ManualViewportDirective viewportDirective = debugElement
          .queryAllNodes(By.nodeDirective(ManualViewportDirective))[0]
          .inject(ManualViewportDirective);
      await testFixture.update((ContainerABCWithConditionalComponent comp) {
        viewportDirective.show();
      });
      expect(element, hasTextContent('(A, BC)'));
      await testFixture.update((ContainerABCWithConditionalComponent comp) {
        viewportDirective.hide();
      });
      expect(element, hasTextContent('(, BC)'));
    });
  });
}

@Component(
    selector: 'container-for-simple',
    template: '<simple>'
        '<div>A</div>'
        '</simple>',
    directives: const [SimpleComponent])
class ContainerWithSimpleComponent {}

@Component(
    selector: 'container-with-interpolation',
    template: '{{\'START(\'}}<simple>'
        '{{testValue}}'
        '</simple>{{\')END\'}}',
    directives: const [SimpleComponent])
class ContainerWithProjectedInterpolation {
  String testValue = "VALUE1";
}

@Component(selector: 'simple', template: 'SIMPLE(<ng-content></ng-content>)')
class SimpleComponent {}

@Component(
    selector: 'container-with-interpolation2',
    template: '{{\'START(\'}}<simple>'
        '{{testValue}}'
        '</simple>{{\')END\'}}',
    directives: const [SimpleComponent2])
class ContainerWithProjectedInterpolationNested {
  String testValue = "VALUE2";
}

@Component(
    selector: 'simple',
    template: 'SIMPLE(<div><ng-content></ng-content></div>)')
class SimpleComponent2 {}

@Component(
    selector: 'container-with-interpolation3',
    template: '{{\'START(\'}}<simple>'
        '{{testValue}}'
        '</simple>{{\')END\'}}',
    directives: const [SimpleComponentWithBinding])
class ContainerWithProjectedInterpolationBound {
  String testValue = "VALUE3";
}

@Component(
    selector: 'simple',
    template: 'SIMPLE(<div><ng-content></ng-content></div>'
        '<div [tabIndex]=\"0\">XY</div>)')
class SimpleComponentWithBinding {}

@Component(
    selector: 'container-for-conditional',
    template: '<conditional-content>'
        '<div class="left">A</div><div>B</div><div>C</div>'
        '</conditional-content>',
    directives: const [ConditionalContentComponent])
class ContainerABCWithConditionalComponent {}

@Component(
    selector: "conditional-content",
    template:
        '<div>(<div *manual><ng-content select=".left"></ng-content></div>'
        ', <ng-content></ng-content>)</div>',
    directives: const [ManualViewportDirective])
class ConditionalContentComponent {}

@Directive(selector: "[manual]")
class ManualViewportDirective {
  ViewContainerRef vc;
  TemplateRef templateRef;
  ManualViewportDirective(this.vc, this.templateRef);

  void show() {
    vc.insertEmbeddedView(templateRef, 0);
  }

  void hide() {
    vc.clear();
  }
}
