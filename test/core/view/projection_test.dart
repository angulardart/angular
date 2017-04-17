@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.core.view.projection_test;

import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/src/debug/debug_node.dart';
import 'package:angular2/src/testing/matchers.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  group('projection', () {
    tearDown(() => disposeAnyRunningTest());

    test('should support simple html elements', () async {
      var testBed = new NgTestBed<ContainerWithSimpleComponent>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
      Element childElement = element.querySelector('simple');
      expect(childElement, hasTextContent('SIMPLE(A)'));
    });

    test(
        'should support simple components with text interpolation projected'
        'into child', () async {
      var testBed = new NgTestBed<ContainerWithProjectedInterpolation>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
      expect(element, hasTextContent('START(SIMPLE(VALUE1))END'));
    });

    test(
        'should support simple components with text interpolation projected'
        'into child where ng-content is nested inside an element', () async {
      var testBed = new NgTestBed<ContainerWithProjectedInterpolationNested>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
      expect(element, hasTextContent('START(SIMPLE(VALUE2))END'));
    });

    test(
        'should support simple components with text interpolation projected'
        'into child with bindings following ng-content', () async {
      var testBed = new NgTestBed<ContainerWithProjectedInterpolationBound>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
      expect(element, hasTextContent('START(SIMPLE(VALUE3XY))END'));
    });

    test('should redistribute when the shadow dom changes', () async {
      var testBed = new NgTestBed<ContainerABCWithConditionalComponent>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
      expect(element, hasTextContent("(, BC)"));

      DebugElement debugElement = getDebugNode(testFixture.rootElement);

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

    test("should support non emulated styles", () async {
      var testBed = new NgTestBed<ContainerWithStyleNotEmulated>();
      var testFixture = await testBed.create();
      Element mainEl = testFixture.rootElement;
      Element div1 = mainEl.childNodes.first;
      Element div2 = document.createElement('div');
      div2.className = 'redStyle';
      mainEl.append(div2);
      expect(div1.getComputedStyle().color, 'rgb(255, 0, 0)');
      expect(div2.getComputedStyle().color, 'rgb(255, 0, 0)');
    });

    test("should support emulated style encapsulation", () async {
      var testBed = new NgTestBed<ContainerWithStyleEmulated>();
      var testFixture = await testBed.create();
      Element mainEl = testFixture.rootElement;
      Element div1 = mainEl.childNodes.first;
      Element div2 = document.createElement('div');
      div2.className = 'blueStyle';
      mainEl.append(div2);
      expect(div1.getComputedStyle().color, 'rgb(0, 0, 255)');
      expect(div2.getComputedStyle().color, 'rgb(0, 0, 0)');
    });

    test('should project ng-content using select query', () async {
      var testBed = new NgTestBed<MyListUserProjectionTest>();
      var testFixture = await testBed.create();
      expect(testFixture.rootElement, hasTextContent('item1item2TheEnd'));
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

@Component(
    selector: 'container-with-style-emu',
    template: '<div class=\"blueStyle\"></div>',
    styles: const [".blueStyle { color: blue}"],
    encapsulation: ViewEncapsulation.Emulated,
    directives: const [SimpleComponent])
class ContainerWithStyleEmulated {}

@Component(
    selector: 'container-with-style-not-emu',
    template: '<div class=\"redStyle\"></div>',
    styles: const [".redStyle { color: red}"],
    encapsulation: ViewEncapsulation.None,
    directives: const [SimpleComponent])
class ContainerWithStyleNotEmulated {}

@Component(
    selector: 'mylist-user',
    template: '<mylist>'
        '<span list-item>item1</span>'
        '<span list-item>item2</span>'
        '</mylist>',
    directives: const [MyListComponent, MyListItemComponent],
    preserveWhitespace: false)
class MyListUserProjectionTest {}

@Component(
    selector: 'mylist',
    template: '<mylist-item>'
        '<ng-content select="[list-item]"></ng-content>'
        '</mylist-item>'
        '<div>TheEnd</div>',
    directives: const [MyListItemComponent],
    preserveWhitespace: false)
class MyListComponent {}

@Component(
    selector: 'mylist-item',
    template: '<ng-content></ng-content>',
    preserveWhitespace: false)
class MyListItemComponent {}
