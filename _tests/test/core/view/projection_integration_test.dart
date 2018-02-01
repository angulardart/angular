@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/core.dart'
    show Component, Directive, Input, ViewChild, ViewChildren, Visibility;
import 'package:angular/src/core/linker.dart'
    show ElementRef, TemplateRef, ViewContainerRef;
import 'package:angular/src/debug/debug_node.dart' show getAllDebugNodes;
import 'package:angular_test/angular_test.dart';

import 'projection_integration_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('projection', () {
    tearDown(disposeAnyRunningTest);

    test(
        'should support projecting text interpolation to a non bound '
        'element with other bound elements after it', () async {
      var testBed = new NgTestBed<NonBoundInterpolationTest>();
      var fixture = await testBed.create();
      await fixture.update((NonBoundInterpolationTest component) {
        component.text = 'A';
      });
      expect(fixture.text, 'SIMPLE(AEL)');
    });
    test('should project content components', () async {
      var testBed = new NgTestBed<ProjectComponentTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'SIMPLE(0|1|2)');
    });
    test('should not show the light dom even if there is no content tag',
        () async {
      var testBed = new NgTestBed<NoLightDomTest>();
      var fixture = await testBed.create();
      expect(fixture.text, isEmpty);
    });
    test('should support multiple content tags', () async {
      var testBed = new NgTestBed<MultipleContentTagsTest>();
      var fixture = await testBed.create();
      expect(fixture.text, '(A, BC)');
    });
    test('should redistribute only direct children', () async {
      var testBed = new NgTestBed<OnlyDirectChildrenTest>();
      var fixture = await testBed.create();
      expect(fixture.text, '(, BAC)');
    });
    test(
        'should redistribute direct child viewcontainers '
        'when the light dom changes', () async {
      var testBed = new NgTestBed<LightDomChangeTest>();
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
      var testBed = new NgTestBed<NestedComponentTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'OUTER(SIMPLE(AB))');
    });
    test(
        'should support nesting with content being '
        'direct child of a nested component', () async {
      var testBed = new NgTestBed<NestedDirectChildTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'OUTER(INNER(INNERINNER(,BC)))');
      await fixture.update((NestedDirectChildTest component) {
        component.viewport.show();
      });
      expect(fixture.text, 'OUTER(INNER(INNERINNER(A,BC)))');
    });
    test('should redistribute when the shadow dom changes', () async {
      var testBed = new NgTestBed<ShadowDomChangeTest>();
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
      var testBed = new NgTestBed<TextNodeAfterContentTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'P,text');
    });
    test('should support text nodes after style tags', () async {
      var testBed = new NgTestBed<TextNodeAfterStyleTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'P,text');
    });
    test('should support moving non projected light dom around', () async {
      var testBed = new NgTestBed<MoveLightDomTest>();
      var fixture = await testBed.create();

      // Have to search for the directive because it's not in the DOM at all.
      ManualViewportDirective sourceDirective;
      getAllDebugNodes().forEach((debug) {
        if (debug.providerTokens.contains(ManualViewportDirective)) {
          sourceDirective = debug.inject(ManualViewportDirective);
        }
      });

      expect(fixture.text, 'START()END');
      await fixture.update((MoveLightDomTest component) {
        component.projectDirective.show(sourceDirective.templateRef);
      });
      expect(fixture.text, 'START(A)END');
    });
    test('should support moving project light dom around', () async {
      var testBed = new NgTestBed<MoveProjectedLightDomTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'SIMPLE()START()END');
      await fixture.update((MoveProjectedLightDomTest component) {
        component.projectDirective.show(component.viewport.templateRef);
      });
      expect(fixture.text, 'SIMPLE()START(A)END');
    });
    test('should support moving ng-content around', () async {
      var testBed = new NgTestBed<MoveNgContentTest>();
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
      var testBed = new NgTestBed<RecursiveTreeTest>();
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
      var testBed = new NgTestBed<RecursiveTreeMultipleComponentTest>();
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
      var testBed = new NgTestBed<NestedConditionalTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'MAIN()');
      await fixture.update((NestedConditionalTest component) {
        component.conditional.viewports.first.show();
      });
      expect(fixture.text, 'MAIN(FIRST())');
      await fixture.update((NestedConditionalTest component) {
        // WARNING: this is assuming that once the first viewport is shown, the
        // new viewport becomes the first viewport in the query list.
        component.conditional.viewports.first.show();
      });
      expect(fixture.text, 'MAIN(FIRST(SECOND(a)))');
    });
    test('should allow to switch the order of nested components via ng-content',
        () async {
      var testBed = new NgTestBed<SwitchOrderTest>();
      var fixture = await testBed.create();
      expect(
          fixture.rootElement.innerHtml,
          '<cmp-a><cmp-b><cmp-d><d>cmp-d</d></cmp-d></cmp-b>'
          '<cmp-c><c>cmp-c</c></cmp-c></cmp-a>');
    });
    test('should create nested components in the right order', () async {
      var testBed = new NgTestBed<CorrectOrderTest>();
      var fixture = await testBed.create();
      expect(
          fixture.rootElement.innerHtml,
          '<cmp-a1>a1<cmp-b11>b11</cmp-b11><cmp-b12>b12</cmp-b12></cmp-a1>'
          '<cmp-a2>a2<cmp-b21>b21</cmp-b21><cmp-b22>b22</cmp-b22></cmp-a2>');
    });
    test('should project filled view containers into a view container',
        () async {
      var testBed = new NgTestBed<NestedProjectionTest>();
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
  });
}

@Component(
  selector: 'non-bound-interpolation-test',
  template: '<simple>{{text}}</simple>',
  directives: const [NonBoundInterpolationChild],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NonBoundInterpolationTest {
  String text = '';
}

@Component(
  selector: 'simple',
  template: 'SIMPLE('
      '<div><ng-content></ng-content></div>'
      '<div [tabIndex]="0">EL</div>)',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NonBoundInterpolationChild {
  String text = '';
}

@Component(
  selector: 'project-component-test',
  template: '<simple><other></other></simple>',
  directives: const [ProjectComponentSimple, ProjectComponentOther],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ProjectComponentTest {}

@Component(
  selector: 'simple',
  template: 'SIMPLE({{0}}|<ng-content></ng-content>|{{2}})',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ProjectComponentSimple {}

@Component(
  selector: 'other',
  template: '{{1}}',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ProjectComponentOther {}

@Component(
  selector: 'no-light-dom-test',
  template: '<empty>A</empty>',
  directives: const [Empty],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NoLightDomTest {}

@Component(
  selector: 'multiple-content-tags-test',
  template: '<multiple-content-tags>'
      '<div>B</div>'
      '<div>C</div>'
      '<div class="left">A</div>'
      '</multiple-content-tags>',
  directives: const [MultipleContentTagsComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MultipleContentTagsTest {}

@Component(
  selector: 'only-direct-children-test',
  template: '<multiple-content-tags>'
      '<div>B<div class="left">A</div></div>'
      '<div>C</div>'
      '</multiple-content-tags>',
  directives: const [MultipleContentTagsComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class OnlyDirectChildrenTest {}

@Component(
  selector: 'light-dom-change-test',
  template: '<multiple-content-tags>'
      '<template manual class="left"><div>A1</div></template>'
      '<div>B</div>'
      '</multiple-content-tags>',
  directives: const [ManualViewportDirective, MultipleContentTagsComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [OuterWithIndirectNestedComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NestedComponentTest {}

@Component(
  selector: 'nested-direct-child-test',
  template: '<outer>'
      '<template manual class="left"><div>A</div></template>'
      '<div>B</div>'
      '<div>C</div>'
      '</outer>',
  directives: const [OuterComponent, ManualViewportDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ConditionalContentComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ShadowDomChangeTest {
  @ViewChild(ConditionalContentComponent)
  ConditionalContentComponent conditional;
}

@Component(
  selector: 'text-node-after-content-test',
  template: '<simple stringProp="text"></simple>',
  directives: const [TextNodeAfterContentComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TextNodeAfterContentTest {}

@Component(
  selector: 'simple',
  template: '<ng-content></ng-content><p>P,</p>{{stringProp}}',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TextNodeAfterContentComponent {
  @Input()
  String stringProp = '';
}

@Component(
  selector: 'text-node-after-style-test',
  template: '<simple stringProp="text"></simple>',
  directives: const [TextNodeAfterStyleComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TextNodeAfterStyleTest {}

@Component(
  selector: 'simple',
  template: '<style></style><p>P,</p>{{stringProp}}',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [Empty, ProjectDirective, ManualViewportDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MoveLightDomTest {
  @ViewChild(ProjectDirective)
  ProjectDirective projectDirective;
}

@Component(
  selector: 'move-projected-light-dom-test',
  template: '<simple><template manual><div>A</div></template></simple>'
      'START(<div project></div>)END',
  directives: const [Simple, ManualViewportDirective, ProjectDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ConditionalContentComponent, ProjectDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [Tree],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class RecursiveTreeTest {
  @ViewChild(Tree)
  Tree tree;
}

@Component(
  selector: 'recursive-tree-multiple-component-test',
  template: '<tree></tree>',
  directives: const [RecursiveTree],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class RecursiveTreeMultipleComponentTest {
  @ViewChild(RecursiveTree)
  RecursiveTree tree;
}

@Component(
  selector: 'nested-conditional-test',
  template: '<conditional-text>a</conditional-text>',
  directives: const [ConditionalTextComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NestedConditionalTest {
  @ViewChild(ConditionalTextComponent)
  ConditionalTextComponent conditional;
}

@Component(
  selector: 'switch-order-test',
  template: '<cmp-a><cmp-b></cmp-b></cmp-a>',
  directives: const [CmpA, CmpB],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class SwitchOrderTest {}

@Component(
  selector: 'correct-order-test',
  template: '<cmp-a1></cmp-a1><cmp-a2></cmp-a2>',
  directives: const [CmpA1, CmpA2],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ConditionalContentComponent, ManualViewportDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class Simple {
  @Input()
  String stringProp = '';
}

@Component(
  selector: 'empty',
  template: '',
  directives: const [],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class Empty {}

@Component(
  selector: 'multiple-content-tags',
  template:
      '(<ng-content select=".left"></ng-content>,&ngsp;<ng-content></ng-content>)',
  directives: const [],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MultipleContentTagsComponent {}

@Directive(
  selector: '[manual]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [Simple],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class OuterWithIndirectNestedComponent {}

@Component(
  selector: 'outer',
  template: 'OUTER(<inner>'
      '<ng-content select=".left" ngProjectAs=".left"></ng-content>'
      '<ng-content></ng-content>'
      '</inner>)',
  directives: const [InnerComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class OuterComponent {}

@Component(
  selector: 'inner',
  template: 'INNER(<innerinner>'
      '<ng-content select=".left" ngProjectAs=".left"></ng-content>'
      '<ng-content></ng-content></innerinner>)',
  directives: const [InnerInnerComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class InnerComponent {}

@Component(
  selector: 'innerinner',
  template: 'INNERINNER('
      '<ng-content select=".left"></ng-content>,'
      '<ng-content></ng-content>)',
  directives: const [],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class InnerInnerComponent {}

@Component(
  selector: 'conditional-content',
  template: '<div>(<div *manual>'
      '<ng-content select=".left"></ng-content></div>,&ngsp;'
      '<ng-content></ng-content>)</div>',
  directives: const [ManualViewportDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ManualViewportDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ConditionalTextComponent {
  @ViewChildren(ManualViewportDirective)
  List<ManualViewportDirective> viewports;
}

@Component(
  selector: 'tree2',
  template: 'TREE2({{depth}}:<tree *manual [depth]="depth+1"></tree>)',
  directives: const [ManualViewportDirective, RecursiveTree],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ManualViewportDirective, Tree],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ManualViewportDirective, Tree2],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CmpD {
  String tagName;
  CmpD(ElementRef elementRef) {
    this.tagName = (elementRef.nativeElement as Element).tagName.toLowerCase();
  }
}

@Component(
  selector: 'cmp-c',
  template: '<c>{{tagName}}</c>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CmpC {
  String tagName;
  CmpC(ElementRef elementRef) {
    this.tagName = (elementRef.nativeElement as Element).tagName.toLowerCase();
  }
}

@Component(
  selector: 'cmp-b',
  template: '<ng-content></ng-content><cmp-d></cmp-d>',
  directives: const [CmpD],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CmpB {}

@Component(
  selector: 'cmp-a',
  template: '<ng-content></ng-content><cmp-c></cmp-c>',
  directives: const [CmpC],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CmpA {}

@Component(
  selector: 'cmp-b11',
  template: '{{\'b11\'}}',
  directives: const [],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CmpB11 {}

@Component(
  selector: 'cmp-b12',
  template: '{{\'b12\'}}',
  directives: const [],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CmpB12 {}

@Component(
  selector: 'cmp-b21',
  template: '{{\'b21\'}}',
  directives: const [],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CmpB21 {}

@Component(
  selector: 'cmp-b22',
  template: '{{\'b22\'}}',
  directives: const [],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CmpB22 {}

@Component(
  selector: 'cmp-a1',
  template: '{{\'a1\'}}<cmp-b11></cmp-b11><cmp-b12></cmp-b12>',
  directives: const [CmpB11, CmpB12],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CmpA1 {}

@Component(
  selector: 'cmp-a2',
  template: '{{\'a2\'}}<cmp-b21></cmp-b21><cmp-b22></cmp-b22>',
  directives: const [CmpB21, CmpB22],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CmpA2 {}
