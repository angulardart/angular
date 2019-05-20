@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'projection_integration_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('projection', () {
    tearDown(disposeAnyRunningTest);

    test(
        'should support projecting text interpolation to a non bound '
        'element with other bound elements after it', () async {
      var testBed = NgTestBed<NonBoundInterpolationTest>();
      var fixture = await testBed.create();
      await fixture.update((NonBoundInterpolationTest component) {
        component.text = 'A';
      });
      expect(fixture.text, 'SIMPLE(AEL)');
    });
    test('should project content components', () async {
      var testBed = NgTestBed<ProjectComponentTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'SIMPLE(0|1|2)');
    });
    test('should not show the light dom even if there is no content tag',
        () async {
      var testBed = NgTestBed<NoLightDomTest>();
      var fixture = await testBed.create();
      expect(fixture.text, isEmpty);
    });
    test('should support multiple content tags', () async {
      var testBed = NgTestBed<MultipleContentTagsTest>();
      var fixture = await testBed.create();
      expect(fixture.text, '(A, BC)');
    });
    test('should redistribute only direct children', () async {
      var testBed = NgTestBed<OnlyDirectChildrenTest>();
      var fixture = await testBed.create();
      expect(fixture.text, '(, BAC)');
    });
    test(
        'should redistribute direct child viewcontainers '
        'when the light dom changes', () async {
      var testBed = NgTestBed<LightDomChangeTest>();
      var fixture = await testBed.create();
      expect(fixture.text, '(, B)');
      await fixture.update((LightDomChangeTest component) {
        component.viewports.forEach((d) => d.show());
      });
      expect(fixture.text, '(A1, B)');
      await fixture.update((LightDomChangeTest component) {
        component.viewports.forEach((d) => d.hide());
      });
      expect(fixture.text, '(, B)');
    });
    test('should support nested components', () async {
      var testBed = NgTestBed<NestedComponentTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'OUTER(SIMPLE(AB))');
    });
    test(
        'should support nesting with content being '
        'direct child of a nested component', () async {
      var testBed = NgTestBed<NestedDirectChildTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'OUTER(INNER(INNERINNER(,BC)))');
      await fixture.update((NestedDirectChildTest component) {
        component.viewport.show();
      });
      expect(fixture.text, 'OUTER(INNER(INNERINNER(A,BC)))');
    });
    test('should redistribute when the shadow dom changes', () async {
      var testBed = NgTestBed<ShadowDomChangeTest>();
      var fixture = await testBed.create();
      expect(fixture.text, '(, BC)');
      await fixture.update((ShadowDomChangeTest component) {
        component.conditional.viewport.show();
      });
      expect(fixture.text, '(A, BC)');
      await fixture.update((ShadowDomChangeTest component) {
        component.conditional.viewport.hide();
      });
      expect(fixture.text, '(, BC)');
    });
    test('should support text nodes after content tags', () async {
      var testBed = NgTestBed<TextNodeAfterContentTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'P,text');
    });
    test('should support text nodes after style tags', () async {
      var testBed = NgTestBed<TextNodeAfterStyleTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'P,text');
    });
    test('should support moving non projected light dom around', () async {
      var testBed = NgTestBed<MoveLightDomTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'START()END');
      await fixture.update((MoveLightDomTest component) {
        component.projectDirective
            .show(component.manualViewportDirective.templateRef);
      });
      expect(fixture.text, 'START(A)END');
    });
    test('should support moving project light dom around', () async {
      var testBed = NgTestBed<MoveProjectedLightDomTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'SIMPLE()START()END');
      await fixture.update((MoveProjectedLightDomTest component) {
        component.projectDirective.show(component.viewport.templateRef);
      });
      expect(fixture.text, 'SIMPLE()START(A)END');
    });
    test('should support moving ng-content around', () async {
      var testBed = NgTestBed<MoveNgContentTest>();
      var fixture = await testBed.create();
      expect(fixture.text, '(, B)START()END');
      await fixture.update((MoveNgContentTest component) {
        component.projectDirective
            .show(component.conditional.viewport.templateRef);
      });
      expect(fixture.text, '(, B)START(A)END');
      // Stamping ng-content multiple times should not produce the content
      // multiple times.
      await fixture.update((MoveNgContentTest component) {
        component.projectDirective
            .show(component.conditional.viewport.templateRef);
      });
      expect(fixture.text, '(, B)START(A)END');
    });

    // Note: This does not use a ng-content element, but is still important as
    // we are merging proto views independent of the presence of ng-content.
    test('should still allow to implement recursive trees', () async {
      var testBed = NgTestBed<RecursiveTreeTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'TREE(0:)');
      await fixture.update((RecursiveTreeTest component) {
        component.tree.viewport.show();
      });
      expect(fixture.text, 'TREE(0:TREE(1:))');
    });
    test(
        'should still allow to implement a recursive '
        'tree via multiple components', () async {
      var testBed = NgTestBed<RecursiveTreeMultipleComponentTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'TREE(0:)');
      await fixture.update((RecursiveTreeMultipleComponentTest component) {
        component.tree.viewport.show();
      });
      expect(fixture.text, 'TREE(0:TREE2(1:))');
      await fixture.update((RecursiveTreeMultipleComponentTest component) {
        component.tree.tree2.viewport.show();
      });
      expect(fixture.text, 'TREE(0:TREE2(1:TREE(2:)))');
    });
    test('should support nested conditionals that contain ng-contents',
        () async {
      var testBed = NgTestBed<NestedConditionalTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'MAIN()');
      await fixture.update((NestedConditionalTest component) {
        component.conditional.viewports.first.show();
      });
      expect(fixture.text, 'MAIN(FIRST())');
      await fixture.update((NestedConditionalTest component) {
        component.conditional.viewports[1].show();
      });
      expect(fixture.text, 'MAIN(FIRST(SECOND(a)))');
    });
    test('should allow to switch the order of nested components via ng-content',
        () async {
      var testBed = NgTestBed<SwitchOrderTest>();
      var fixture = await testBed.create();
      expect(
          fixture.rootElement.innerHtml,
          '<cmp-a><cmp-b><cmp-d><d>cmp-d</d></cmp-d></cmp-b>'
          '<cmp-c><c>cmp-c</c></cmp-c></cmp-a>');
    });
    test('should create nested components in the right order', () async {
      var testBed = NgTestBed<CorrectOrderTest>();
      var fixture = await testBed.create();
      expect(
          fixture.rootElement.innerHtml,
          '<cmp-a1>a1<cmp-b11>b11</cmp-b11><cmp-b12>b12</cmp-b12></cmp-a1>'
          '<cmp-a2>a2<cmp-b21>b21</cmp-b21><cmp-b22>b22</cmp-b22></cmp-a2>');
    });
    test('should project filled view containers into a view container',
        () async {
      var testBed = NgTestBed<NestedProjectionTest>();
      var fixture = await testBed.create();
      expect(fixture.text, '(, D)');
      await fixture.update((NestedProjectionTest component) {
        component.conditional.viewport.show();
      });
      expect(fixture.text, '(AC, D)');
      await fixture.update((NestedProjectionTest component) {
        component.viewport.show();
      });
      expect(fixture.text, '(ABC, D)');
      await fixture.update((NestedProjectionTest component) {
        component.conditional.viewport.hide();
      });
      expect(fixture.text, '(, D)');
    });
    test('should support <ng-content> as root of an embedded view', () async {
      final testBed =
          NgTestBed.forComponent(ng_generated.TestNgIfNgContentNgFactory);
      final fixture = await testBed.create();
      expect(fixture.text, 'Hello world!');
    });
  });
}

@Component(
  selector: 'non-bound-interpolation-test',
  template: '<simple>{{text}}</simple>',
  directives: [NonBoundInterpolationChild],
)
class NonBoundInterpolationTest {
  String text = '';
}

@Component(
  selector: 'simple',
  template: 'SIMPLE('
      '<div><ng-content></ng-content></div>'
      '<div [tabIndex]="0">EL</div>)',
)
class NonBoundInterpolationChild {
  String text = '';
}

@Component(
  selector: 'project-component-test',
  template: '<simple><other></other></simple>',
  directives: [ProjectComponentSimple, ProjectComponentOther],
)
class ProjectComponentTest {}

@Component(
  selector: 'simple',
  template: 'SIMPLE({{0}}|<ng-content></ng-content>|{{2}})',
)
class ProjectComponentSimple {}

@Component(
  selector: 'other',
  template: '{{1}}',
)
class ProjectComponentOther {}

@Component(
  selector: 'no-light-dom-test',
  template: '<empty>A</empty>',
  directives: [Empty],
)
class NoLightDomTest {}

@Component(
  selector: 'multiple-content-tags-test',
  template: '<multiple-content-tags>'
      '<div>B</div>'
      '<div>C</div>'
      '<div class="left">A</div>'
      '</multiple-content-tags>',
  directives: [MultipleContentTagsComponent],
)
class MultipleContentTagsTest {}

@Component(
  selector: 'only-direct-children-test',
  template: '<multiple-content-tags>'
      '<div>B<div class="left">A</div></div>'
      '<div>C</div>'
      '</multiple-content-tags>',
  directives: [MultipleContentTagsComponent],
)
class OnlyDirectChildrenTest {}

@Component(
  selector: 'light-dom-change-test',
  template: '<multiple-content-tags>'
      '<template manual class="left"><div>A1</div></template>'
      '<div>B</div>'
      '</multiple-content-tags>',
  directives: [ManualViewportDirective, MultipleContentTagsComponent],
)
class LightDomChangeTest {
  @ViewChildren(ManualViewportDirective)
  List<ManualViewportDirective> viewports;
}

@Component(
  selector: 'nested-component-test',
  template: '<outer-with-indirect-nested>'
      '<div>A</div>'
      '<div>B</div>'
      '</outer-with-indirect-nested>',
  directives: [OuterWithIndirectNestedComponent],
)
class NestedComponentTest {}

@Component(
  selector: 'nested-direct-child-test',
  template: '<outer>'
      '<template manual class="left"><div>A</div></template>'
      '<div>B</div>'
      '<div>C</div>'
      '</outer>',
  directives: [OuterComponent, ManualViewportDirective],
)
class NestedDirectChildTest {
  @ViewChild(ManualViewportDirective)
  ManualViewportDirective viewport;
}

@Component(
  selector: 'shadow-dom-change-test',
  template: '<conditional-content>'
      '<div class="left">A</div>'
      '<div>B</div>'
      '<div>C</div>'
      '</conditional-content>',
  directives: [ConditionalContentComponent],
)
class ShadowDomChangeTest {
  @ViewChild(ConditionalContentComponent)
  ConditionalContentComponent conditional;
}

@Component(
  selector: 'text-node-after-content-test',
  template: '<simple stringProp="text"></simple>',
  directives: [TextNodeAfterContentComponent],
)
class TextNodeAfterContentTest {}

@Component(
  selector: 'simple',
  template: '<ng-content></ng-content><p>P,</p>{{stringProp}}',
)
class TextNodeAfterContentComponent {
  @Input()
  String stringProp = '';
}

@Component(
  selector: 'text-node-after-style-test',
  template: '<simple stringProp="text"></simple>',
  directives: [TextNodeAfterStyleComponent],
)
class TextNodeAfterStyleTest {}

@Component(
  selector: 'simple',
  template: '<style></style><p>P,</p>{{stringProp}}',
)
class TextNodeAfterStyleComponent {
  @Input()
  String stringProp = '';
}

@Component(
  selector: 'move-light-dom-test',
  template: '<empty>'
      '  <template manual><div>A</div></template>'
      '</empty>'
      'START(<div project></div>)END',
  directives: [Empty, ProjectDirective, ManualViewportDirective],
)
class MoveLightDomTest {
  @ViewChild(ManualViewportDirective)
  ManualViewportDirective manualViewportDirective;

  @ViewChild(ProjectDirective)
  ProjectDirective projectDirective;
}

@Component(
  selector: 'move-projected-light-dom-test',
  template: '<simple><template manual><div>A</div></template></simple>'
      'START(<div project></div>)END',
  directives: [Simple, ManualViewportDirective, ProjectDirective],
)
class MoveProjectedLightDomTest {
  @ViewChild(ManualViewportDirective)
  ManualViewportDirective viewport;

  @ViewChild(ProjectDirective)
  ProjectDirective projectDirective;
}

@Component(
  selector: 'move-ng-content-test',
  template: '<conditional-content>'
      '<div class="left">A</div>'
      '<div>B</div>'
      '</conditional-content>'
      'START(<div project></div>)END',
  directives: [ConditionalContentComponent, ProjectDirective],
)
class MoveNgContentTest {
  @ViewChild(ProjectDirective)
  ProjectDirective projectDirective;

  @ViewChild(ConditionalContentComponent)
  ConditionalContentComponent conditional;
}

@Component(
  selector: 'recursive-tree-test',
  template: '<tree></tree>',
  directives: [Tree],
)
class RecursiveTreeTest {
  @ViewChild(Tree)
  Tree tree;
}

@Component(
  selector: 'recursive-tree-multiple-component-test',
  template: '<tree></tree>',
  directives: [RecursiveTree],
)
class RecursiveTreeMultipleComponentTest {
  @ViewChild(RecursiveTree)
  RecursiveTree tree;
}

@Component(
  selector: 'nested-conditional-test',
  template: '<conditional-text>a</conditional-text>',
  directives: [ConditionalTextComponent],
)
class NestedConditionalTest {
  @ViewChild(ConditionalTextComponent)
  ConditionalTextComponent conditional;
}

@Component(
  selector: 'switch-order-test',
  template: '<cmp-a><cmp-b></cmp-b></cmp-a>',
  directives: [CmpA, CmpB],
)
class SwitchOrderTest {}

@Component(
  selector: 'correct-order-test',
  template: '<cmp-a1></cmp-a1><cmp-a2></cmp-a2>',
  directives: [CmpA1, CmpA2],
)
class CorrectOrderTest {}

@Component(
  selector: 'nested-projection-test',
  template: '<conditional-content>'
      '<div class="left">A</div>'
      '<template manual class="left">B</template>'
      '<div class="left">C</div>'
      '<div>D</div>'
      '</conditional-content>',
  directives: [ConditionalContentComponent, ManualViewportDirective],
)
class NestedProjectionTest {
  @ViewChild(ConditionalContentComponent)
  ConditionalContentComponent conditional;

  @ViewChild(ManualViewportDirective)
  ManualViewportDirective viewport;
}

@Component(
  selector: 'simple',
  template: 'SIMPLE(<ng-content></ng-content>)',
  directives: [],
)
class Simple {
  @Input()
  String stringProp = '';
}

@Component(
  selector: 'empty',
  template: '',
  directives: [],
)
class Empty {}

@Component(
  selector: 'multiple-content-tags',
  template:
      '(<ng-content select=".left"></ng-content>,&ngsp;<ng-content></ng-content>)',
  directives: [],
)
class MultipleContentTagsComponent {}

@Directive(
  selector: '[manual]',
)
class ManualViewportDirective {
  ViewContainerRef vc;
  TemplateRef templateRef;

  ManualViewportDirective(this.vc, this.templateRef);

  void show() {
    this.vc.insertEmbeddedView(this.templateRef, 0);
  }

  void hide() {
    this.vc.clear();
  }
}

@Directive(
  selector: '[project]',
)
class ProjectDirective {
  ViewContainerRef vc;
  ProjectDirective(this.vc);
  void show(TemplateRef templateRef) {
    this.vc.insertEmbeddedView(templateRef, 0);
  }

  void hide() {
    this.vc.clear();
  }
}

@Component(
  selector: 'outer-with-indirect-nested',
  template: 'OUTER(<simple><div><ng-content></ng-content></div></simple>)',
  directives: [Simple],
)
class OuterWithIndirectNestedComponent {}

@Component(
  selector: 'outer',
  template: 'OUTER(<inner>'
      '<ng-content select=".left" ngProjectAs=".left"></ng-content>'
      '<ng-content></ng-content>'
      '</inner>)',
  directives: [InnerComponent],
)
class OuterComponent {}

@Component(
  selector: 'inner',
  template: 'INNER(<innerinner>'
      '<ng-content select=".left" ngProjectAs=".left"></ng-content>'
      '<ng-content></ng-content></innerinner>)',
  directives: [InnerInnerComponent],
)
class InnerComponent {}

@Component(
  selector: 'innerinner',
  template: 'INNERINNER('
      '<ng-content select=".left"></ng-content>,'
      '<ng-content></ng-content>)',
  directives: [],
)
class InnerInnerComponent {}

@Component(
  selector: 'conditional-content',
  template: '<div>(<div *manual>'
      '<ng-content select=".left"></ng-content></div>,&ngsp;'
      '<ng-content></ng-content>)</div>',
  directives: [ManualViewportDirective],
)
class ConditionalContentComponent {
  @ViewChild(ManualViewportDirective)
  ManualViewportDirective viewport;
}

@Component(
  selector: 'conditional-text',
  template: 'MAIN(<template manual>'
      'FIRST(<template manual>SECOND(<ng-content></ng-content>)</template>)'
      '</template>)',
  directives: [ManualViewportDirective],
)
class ConditionalTextComponent {
  @ViewChildren(ManualViewportDirective)
  List<ManualViewportDirective> viewports;
}

@Component(
  selector: 'tree2',
  template: 'TREE2({{depth}}:<tree *manual [depth]="depth+1"></tree>)',
  directives: [ManualViewportDirective, RecursiveTree],
)
class Tree2 {
  @Input()
  var depth = 0;

  @ViewChild(ManualViewportDirective)
  ManualViewportDirective viewport;
}

@Component(
  selector: 'tree',
  template: 'TREE({{depth}}:<tree *manual [depth]="depth+1"></tree>)',
  directives: [ManualViewportDirective, Tree],
)
class Tree {
  @Input()
  var depth = 0;

  @ViewChild(ManualViewportDirective)
  ManualViewportDirective viewport;
}

@Component(
  selector: 'tree',
  template: 'TREE({{depth}}:<tree2 *manual [depth]="depth+1"></tree2>)',
  directives: [ManualViewportDirective, Tree2],
)
class RecursiveTree {
  @Input()
  var depth = 0;

  @ViewChild(ManualViewportDirective)
  ManualViewportDirective viewport;

  @ViewChild(Tree2)
  Tree2 tree2;
}

@Component(
  selector: 'cmp-d',
  template: '<d>{{tagName}}</d>',
)
class CmpD {
  final String tagName;
  CmpD(Element element) : tagName = element.tagName.toLowerCase();
}

@Component(
  selector: 'cmp-c',
  template: '<c>{{tagName}}</c>',
)
class CmpC {
  final String tagName;
  CmpC(Element element) : tagName = element.tagName.toLowerCase();
}

@Component(
  selector: 'cmp-b',
  template: '<ng-content></ng-content><cmp-d></cmp-d>',
  directives: [CmpD],
)
class CmpB {}

@Component(
  selector: 'cmp-a',
  template: '<ng-content></ng-content><cmp-c></cmp-c>',
  directives: [CmpC],
)
class CmpA {}

@Component(
  selector: 'cmp-b11',
  template: '{{\'b11\'}}',
  directives: [],
)
class CmpB11 {}

@Component(
  selector: 'cmp-b12',
  template: '{{\'b12\'}}',
  directives: [],
)
class CmpB12 {}

@Component(
  selector: 'cmp-b21',
  template: '{{\'b21\'}}',
  directives: [],
)
class CmpB21 {}

@Component(
  selector: 'cmp-b22',
  template: '{{\'b22\'}}',
  directives: [],
)
class CmpB22 {}

@Component(
  selector: 'cmp-a1',
  template: '{{\'a1\'}}<cmp-b11></cmp-b11><cmp-b12></cmp-b12>',
  directives: [CmpB11, CmpB12],
)
class CmpA1 {}

@Component(
  selector: 'cmp-a2',
  template: '{{\'a2\'}}<cmp-b21></cmp-b21><cmp-b22></cmp-b22>',
  directives: [CmpB21, CmpB22],
)
class CmpA2 {}

@Component(
  selector: 'ng-if-ng-content',
  directives: [NgIf],
  template: '''
    <ng-container *ngIf="isContentVisible">
      <ng-content></ng-content>
    </ng-container>
  ''',
)
class NgIfNgContent {
  var isContentVisible = true;
}

@Component(
  selector: 'test',
  directives: [NgIfNgContent],
  template: '''
    <ng-if-ng-content>
      <div>Hello world!</div>
    </ng-if-ng-content>
  ''',
)
class TestNgIfNgContent {}
