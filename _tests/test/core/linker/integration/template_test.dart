@TestOn('browser')

import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'template_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should support template directives via <template> elements', () async {
    final testBed = new NgTestBed<TemplateDirectiveComponent>();
    final testFixture = await testBed.create();
    // 1 template + 2 copies.
    expect(testFixture.rootElement.childNodes, hasLength(3));
    expect(testFixture.rootElement.childNodes[1].text, 'hello');
    expect(testFixture.rootElement.childNodes[2].text, 'again');
  });

  test('should not detach views when parent is destroyed', () async {
    final testBed = new NgTestBed<DestroyParentViewComponent>();
    final testFixture = await testBed.create();
    final ngIfElement = testFixture.rootElement.children.first;
    final someViewport = testFixture.assertOnlyInstance.viewport;
    expect(ngIfElement.children, hasLength(2));
    expect(someViewport.container, hasLength(2));
    await testFixture.update((component) => component.visible = false);
    expect(testFixture.rootElement.children, hasLength(0));
    expect(someViewport.container, hasLength(2));
  });

  test('should use a comment while stamping out <template> elements', () async {
    final testBed = new NgTestBed<EmptyTemplateComponent>();
    final testFixture = await testBed.create();
    final childNodes = testFixture.rootElement.childNodes;
    expect(childNodes, hasLength(1));
    expect(childNodes.first, new isInstanceOf<Comment>());
  });

  test('should support template directives via template property', () async {
    final testBed = new NgTestBed<TemplatePropertyComponent>();
    final testFixture = await testBed.create();
    // 1 template + 2 copies.
    expect(testFixture.rootElement.childNodes, hasLength(3));
    expect(testFixture.rootElement.childNodes[1].text, 'hello');
    expect(testFixture.rootElement.childNodes[2].text, 'again');
  });

  test('should transplant TemplateRef into another ViewContainer', () async {
    final testBed = new NgTestBed<TemplateRefTransplantComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text,
        'From component,From toolbar,Component with an injected host');
  });
}

@Directive(
  selector: '[some-viewport]',
)
class SomeViewport {
  final ViewContainerRef container;

  SomeViewport(this.container, TemplateRef templateRef) {
    container.createEmbeddedView(templateRef).setLocal('some-tmpl', 'hello');
    container.createEmbeddedView(templateRef).setLocal('some-tmpl', 'again');
  }
}

@Component(
  selector: 'template-directive',
  template:
      '<template some-viewport let-x="some-tmpl"><div>{{x}}</div></template>',
  directives: const [
    SomeViewport,
  ],
)
class TemplateDirectiveComponent {}

@Component(
  selector: 'destroy-parent-view',
  template: '<div *ngIf="visible">'
      '<template some-viewport let-x="someTmpl"><span>{{x}}</span></template>'
      '</div>',
  directives: const [
    NgIf,
    SomeViewport,
  ],
)
class DestroyParentViewComponent {
  bool visible = true;

  @ViewChild(SomeViewport)
  SomeViewport viewport;
}

@Component(
  selector: 'empty-template',
  template: '<template></template>',
)
class EmptyTemplateComponent {}

@Component(
  selector: 'template-property',
  template: '<div template="some-viewport: let x=some-tmpl">{{x}}</div>',
  directives: const [
    SomeViewport,
  ],
)
class TemplatePropertyComponent {}

@Directive(
  selector: '[toolbarpart]',
)
class ToolbarPart {
  final TemplateRef templateRef;

  ToolbarPart(this.templateRef);
}

@Directive(
  selector: '[toolbarVc]',
)
class ToolbarViewContainer {
  final ViewContainerRef vc;

  ToolbarViewContainer(this.vc);

  @Input()
  set toolbarVc(ToolbarPart part) {
    final view = vc.insertEmbeddedView(part.templateRef, 0);
    view.setLocal('toolbarProp', 'From toolbar');
  }
}

@Component(
  selector: 'toolbar',
  template: '<div *ngFor="let part of query" [toolbarVc]="part"></div>',
  directives: const [
    NgFor,
    ToolbarViewContainer,
  ],
)
class ToolbarComponent {
  @ContentChildren(ToolbarPart)
  List<ToolbarPart> query;

  String prop = 'hello world';
}

@Directive(
  selector: 'some-directive',
  visibility: Visibility.all,
)
class SomeDirective {}

@Component(
  selector: 'cmp-with-host',
  template: '<p>Component with an injected host</p>',
  directives: const [SomeDirective],
)
class CompWithHost {
  SomeDirective myHost;

  CompWithHost(@Host() SomeDirective someComp) {
    this.myHost = someComp;
  }
}

@Component(
  selector: 'template-ref-transplant',
  template: '<some-directive><toolbar>'
      '<template toolbarpart let-toolbarProp="toolbarProp">'
      '{{prop}},{{toolbarProp}},<cmp-with-host></cmp-with-host>'
      '</template>'
      '</toolbar></some-directive>',
  directives: const [
    CompWithHost,
    SomeDirective,
    ToolbarComponent,
    ToolbarPart,
  ],
)
class TemplateRefTransplantComponent {
  String prop = 'From component';
}
