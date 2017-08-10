@Tags(const ['codegen'])
@TestOn('browser')

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  group('query for Directive', () {
    test('should contain all direct content children', () async {
      final testBed = new NgTestBed<TestsContentChildrenComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2|3|5');
    });

    test('should contain all content children', () async {
      final testBed = new NgTestBed<TestsContentChildrenDescendantsComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2|3|4|5');
    });

    test('should contain first content child', () async {
      final testBed = new NgTestBed<TestsContentChildComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2');
    });

    test('should contain all view children', () async {
      final testBed = new NgTestBed<TestsViewChildrenComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), 'a|b|c');
    });

    test('should contain first view child', () async {
      final testBed = new NgTestBed<TestsViewChildComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), 'a');
    });

    test('should contain all direct content children in embedded view',
        () async {
      final testBed = new NgTestBed<TestsEmbeddedContentChildrenComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1');
      await testFixture.update((component) => component.showContent = true);
      expect(testFixture.text.trim(), '1|2|4');
    });

    test('should contain all content children in embedded view', () async {
      final testBed =
          new NgTestBed<TestsEmbeddedContentChildrenDescendantsComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1');
      await testFixture.update((component) => component.showContent = true);
      expect(testFixture.text.trim(), '1|2|3|4');
    });

    test('should contain first content child in embedded view', () async {
      final testBed = new NgTestBed<TestsEmbeddedContentChildComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), isEmpty);
      await testFixture.update((component) => component.showContent = true);
      expect(testFixture.text.trim(), '1');
    });

    test('should contain all view children in embedded view', () async {
      final testBed = new NgTestBed<TestsEmbeddedViewChildrenComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), isEmpty);
      await testFixture.update((component) => component.showView = true);
      expect(testFixture.text.trim(), 'a|b|c');
    });

    test('should contain first view child in embedded view', () async {
      final testBed = new NgTestBed<TestsEmbeddedViewChildComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), 'c');
      await testFixture.update((component) => component.showView = true);
      expect(testFixture.text.trim(), 'a');
    });

    test('should handle moved directives', () async {
      final testBed = new NgTestBed<MovesDirectiveComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1|2|3');
      await testFixture.update((component) => component.list = ['3', '2']);
      expect(testFixture.text.trim(), '3|2');
    });

    test('should support transclusion', () async {
      final testBed = new NgTestBed<TestsTranscludedContentChildrenComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2|7');
    });

    test('should not be affected by unrelated changes', () async {
      final testBed = new NgTestBed<UnrelatedChangesComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1');
      await testFixture.update((component) {
        component.showInertDirective = false;
      });
      expect(testFixture.text.trim(), '1');
    });

    test('should handle long ngFor cycles', () async {
      final testBed = new NgTestBed<LongNgForCycleComponent>();
      final testFixture = await testBed.create();
      // No significance to 50, just a reasonably long cycle.
      for (var i = 0; i < 50; i++) {
        await testFixture.update((component) {
          component.list = ['$i', '${i + 1}'];
        });
        expect(testFixture.text.trim(), '$i|${i + 1}');
      }
    });

    test('should support more than three queries', () async {
      final testBed = new NgTestBed<FourQueriesComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1|1|1|1');
    });
  });

  group('query for TemplateRef', () {
    test('should find content and view children', () async {
      final testBed = new NgTestBed<TestsTemplateRefComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.rootElement.querySelectorAll('.embedded-from-content'),
          hasLength(2));
      expect(testFixture.rootElement.querySelectorAll('.embedded-from-view'),
          hasLength(2));
    });

    test('should find named content child and named view child', () async {
      final testBed = new NgTestBed<TestsNamedTemplateRefComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.rootElement.querySelectorAll('.embedded-from-content'),
          hasLength(1));
      expect(testFixture.rootElement.querySelectorAll('.embedded-from-view'),
          hasLength(1));
    });
  });

  group('query for a different token via read', () {
    test('should contain all content children', () async {
      final testBed = new NgTestBed<TestsReadsContentChildrenComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1|3');
    });

    test('should contain the first content child', () async {
      final testBed = new NgTestBed<TestsReadsContentChildComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2');
    });

    test('should contain all view children', () async {
      final testBed = new NgTestBed<ReadsViewChildrenComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2|3');
    });

    test('should contain the first view child', () async {
      final testBed = new NgTestBed<ReadsViewChildComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2');
    });

    test('should support ViewContainer', () async {
      final testBed = new NgTestBed<TestsReadsViewContainerRefComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), 'Embedded in view container!');
    });
  });

  group('changes', () {
    test('should update query results', () async {
      final testBed = new NgTestBed<ChangesViewChildrenComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1|2|3');
      await testFixture.update((component) {
        component.x = '3';
        component.z = '1';
      });
      expect(testFixture.text.trim(), '3|2|1');
    });

    test('should remove destroyed directives from query results', () async {
      final testBed = new NgTestBed<DestroysViewChildrenComponent>();
      var component;
      final testFixture = await testBed.create(
          beforeChangeDetection: (instance) => component = instance);
      expect(component.textDirectives, hasLength(1));
      await testFixture.update((component) => component.showView = false);
      expect(component.textDirectives, hasLength(0));
      await testFixture.update((component) => component.showView = true);
      expect(component.textDirectives, hasLength(1));
    });
  });

  group('query for variable binding', () {
    test('should contain all view children', () async {
      final testBed = new NgTestBed<LabeledViewChildrenComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1|2|4|8');
    });

    test('should support multiple variables', () async {
      final testBed = new NgTestBed<MultipleLabeledViewChildrenComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '0|1');
    });

    test('should support changes', () async {
      final testBed = new NgTestBed<LabeledViewChildrenComponent>();
      final testFixture = await testBed.create();
      await testFixture.update((component) {
        component.list = ['8', '4', '2', '1'];
      });
      expect(testFixture.text.trim(), '8|4|2|1');
    });

    test('should support element binding', () async {
      var component;
      final testBed = new NgTestBed<LabeledElementViewChildrenComponent>();
      await testBed.create(beforeChangeDetection: (comp) => component = comp);
      final divIt = component.elementRefs.iterator;
      final itemIt = component.list.iterator;

      while (divIt.moveNext()) {
        itemIt.moveNext();
        expect(divIt.current.nativeElement.text, itemIt.current);
      }

      expect(itemIt.moveNext(), false);
    });
  });
}

@Directive(
  selector: '[text]',
  exportAs: 'textDirective',
)
class TextDirective {
  @Input()
  String text;
}

abstract class TextDirectivesRenderer {
  Iterable<TextDirective> get textDirectives;

  String get text => textDirectives.map((dir) => dir.text).join('|');
}

@Component(
  selector: 'content-children',
  template: '<div>{{text}}</div>',
)
class ContentChildrenComponent extends TextDirectivesRenderer {
  @ContentChildren(TextDirective)
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'tests-content-children',
  template: '''
<div text="1"></div>
<content-children text="2">
  <div text="3">
    <div text="4"></div>
  </div>
  <div text="5"></div>
</content-children>
<div text="6"></div>''',
  directives: const [
    ContentChildrenComponent,
    TextDirective,
  ],
)
class TestsContentChildrenComponent {}

@Component(
  selector: 'content-children-descendants',
  template: '<div>{{text}}</div>',
)
class ContentChildrenDescendantsComponent extends TextDirectivesRenderer {
  @ContentChildren(TextDirective, descendants: true)
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'tests-content-children-descendants',
  template: '''
<div text="1"></div>
<content-children-descendants text="2">
  <div text="3">
    <div text="4"></div>
  </div>
  <div text="5"></div>
</content-children-descendants>
<div text="6"></div>''',
  directives: const [
    ContentChildrenDescendantsComponent,
    TextDirective,
  ],
)
class TestsContentChildrenDescendantsComponent {}

@Component(
  selector: 'content-child',
  template: '<div>{{textDirective?.text}}</div>',
)
class ContentChildComponent {
  @ContentChild(TextDirective)
  TextDirective textDirective;
}

@Component(
  selector: 'tests-content-child',
  template: '''
<div text="1"></div>
<content-child text="2">
  <div text="3">
    <div text="4"></div>
  </div>
  <div text="5"></div>
</content-child>
<div text="6"></div>''',
  directives: const [
    ContentChildComponent,
    TextDirective,
  ],
)
class TestsContentChildComponent {}

@Component(
  selector: 'view-children',
  template: '''
<div text="a">
  <div text="b"></div>
</div>
<div>{{text}}</div>
<div text="c"></div>''',
  directives: const [
    TextDirective,
  ],
)
class ViewChildrenComponent extends TextDirectivesRenderer {
  @ViewChildren(TextDirective)
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'tests-view-children',
  template: '''
<div text="1"></div>
<view-children text="2">
  <div text="3"></div>
</view-children>
<div text="4"></div>''',
  directives: const [
    TextDirective,
    ViewChildrenComponent,
  ],
)
class TestsViewChildrenComponent {}

@Component(
  selector: 'view-child',
  template: '''
<div text="a">
  <div text="b"></div>
</div>
<div>{{textDirective.text}}</div>
<div text="c"></div>''',
  directives: const [
    TextDirective,
  ],
)
class ViewChildComponent {
  @ViewChild(TextDirective)
  TextDirective textDirective;
}

@Component(
  selector: 'tests-view-children',
  template: '''
<div text="1"></div>
<view-child text="2">
  <div text="3"></div>
</view-child>
<div text="4"></div>''',
  directives: const [
    TextDirective,
    ViewChildComponent,
  ],
)
class TestsViewChildComponent {}

@Component(
  selector: 'tests-embedded-content-children',
  template: '''
<content-children text="1">
  <template [ngIf]="showContent">
    <div text="2">
      <div text="3"></div>
    </div>
    <div text="4"></div>
  </template>
</content-children>''',
  directives: const [
    ContentChildrenComponent,
    NgIf,
    TextDirective,
  ],
)
class TestsEmbeddedContentChildrenComponent {
  bool showContent = false;
}

@Component(
  selector: 'tests-embedded-content-children',
  template: '''
<content-children-descendants text="1">
  <template [ngIf]="showContent">
    <div text="2">
      <div text="3"></div>
    </div>
    <div text="4"></div>
  </template>
</content-children-descendants>''',
  directives: const [
    ContentChildrenDescendantsComponent,
    NgIf,
    TextDirective,
  ],
)
class TestsEmbeddedContentChildrenDescendantsComponent {
  bool showContent = false;
}

@Component(
  selector: 'tests-embedded-content-children',
  template: '''
<content-child>
  <div *ngIf="showContent" text="1">
    <div text="2"></div>
  </div>
</content-child>''',
  directives: const [
    ContentChildComponent,
    NgIf,
    TextDirective,
  ],
)
class TestsEmbeddedContentChildComponent {
  bool showContent = false;
}

@Component(
  selector: 'embedded-view-children',
  template: '''
<template [ngIf]="showView">
  <div text="a">
    <div text="b"></div>
  </div>
  <div text="c"></div>
</template>
<div>{{text}}</div>''',
  directives: const [
    NgIf,
    TextDirective,
  ],
)
class TestsEmbeddedViewChildrenComponent extends TextDirectivesRenderer {
  bool showView = false;

  @ViewChildren(TextDirective)
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'embedded-view-child',
  template: '''
<div *ngIf="showView" text="a">
  <div text="b"></div>
</div>
<div text="c"></div>
<div>{{textDirective?.text}}</div>''',
  directives: const [
    NgIf,
    TextDirective,
  ],
)
class TestsEmbeddedViewChildComponent {
  bool showView = false;

  @ViewChild(TextDirective)
  TextDirective textDirective;
}

@Component(
  selector: 'moves-directive',
  template: '''
<content-children>
  <div *ngFor="let item of list" text="{{item}}"></div>
</content-children>''',
  directives: const [
    ContentChildrenComponent,
    NgFor,
    TextDirective,
  ],
)
class MovesDirectiveComponent {
  List<String> list = <String>['1', '2', '3'];
}

@Component(
  selector: 'transcluded-content-children',
  template: '<ng-content></ng-content><div>{{text}}</div>',
)
class TranscludedContentChildrenComponent extends TextDirectivesRenderer {
  @ContentChildren(TextDirective)
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'tests-transcluded-content-children',
  template: '''
<transcluded-content-children>
  <div text="2"></div>
  <div text="7"></div>
</transcluded-content-children>''',
  directives: const [
    TextDirective,
    TranscludedContentChildrenComponent,
  ],
)
class TestsTranscludedContentChildrenComponent {}

@Directive(selector: '[inert]')
class InertDirective {}

@Component(selector: 'unrelated-changes', template: '''
<div text="1"></div>
<div *ngIf="showInertDirective" inert></div>
<div>{{text}}</div>
  ''', directives: const [
  InertDirective,
  NgIf,
  TextDirective,
])
class UnrelatedChangesComponent extends TextDirectivesRenderer {
  bool showInertDirective = true;

  @ViewChildren(TextDirective)
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'long-ng-for-cycle',
  template: '''
<div *ngFor="let item of list" [text]="item"></div>
<div>{{text}}</div>
''',
  directives: const [
    NgFor,
    TextDirective,
  ],
)
class LongNgForCycleComponent extends TextDirectivesRenderer {
  List<String> list = <String>[];

  @ViewChildren(TextDirective)
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'four-queries',
  template: '''
<div text="1"></div>
<div>{{q1.text}}|{{q2.text}}|{{q3.text}}|{{q4.text}}</div>''',
  directives: const [
    TextDirective,
  ],
)
class FourQueriesComponent {
  @ViewChild(TextDirective)
  TextDirective q1;

  @ViewChild(TextDirective)
  TextDirective q2;

  @ViewChild(TextDirective)
  TextDirective q3;

  @ViewChild(TextDirective)
  TextDirective q4;
}

@Component(
  selector: 'template-ref',
  template: '''
<template>
  <div class="embedded-from-view"></div>
</template>
<template>
  <div class="embedded-from-view"></div>
</template>
''',
)
class TemplateRefComponent implements AfterViewInit {
  final ViewContainerRef viewContainerRef;

  @ContentChildren(TemplateRef)
  QueryList<TemplateRef> contentTemplateRefs;

  @ViewChildren(TemplateRef)
  QueryList<TemplateRef> viewTemplateRefs;

  TemplateRefComponent(this.viewContainerRef);

  @override
  ngAfterViewInit() {
    createEmbeddedViewsFrom(contentTemplateRefs);
    createEmbeddedViewsFrom(viewTemplateRefs);
  }

  void createEmbeddedViewsFrom(Iterable<TemplateRef> templateRefs) {
    for (var templateRef in templateRefs) {
      viewContainerRef.createEmbeddedView(templateRef);
    }
  }
}

@Component(
  selector: 'tests-template-ref',
  template: '''
<template-ref>
  <template>
    <div class="embedded-from-content"></div>
  </template>
  <template>
    <div class="embedded-from-content"></div>
  </template>
</template-ref>''',
  directives: const [
    TemplateRefComponent,
  ],
)
class TestsTemplateRefComponent {}

@Component(
  selector: 'named-template-ref',
  template: '''
<template #templateName>
  <div class="embedded-from-view"></div>
</template>
''',
)
class NamedTemplateRefComponent implements AfterViewInit {
  final ViewContainerRef viewContainerRef;

  @ContentChild('templateName')
  TemplateRef contentTemplateRef;

  @ViewChild('templateName')
  TemplateRef viewTemplateRef;

  NamedTemplateRefComponent(this.viewContainerRef);

  @override
  ngAfterViewInit() {
    viewContainerRef.createEmbeddedView(contentTemplateRef);
    viewContainerRef.createEmbeddedView(viewTemplateRef);
  }
}

@Component(
  selector: 'tests-named-template-ref',
  template: '''
<named-template-ref>
  <template #templateName>
    <div class="embedded-from-content"></div>
  </template>
</named-template-ref>''',
  directives: const [
    NamedTemplateRefComponent,
  ],
)
class TestsNamedTemplateRefComponent {}

@Component(
  selector: 'reads-content-children',
  template: '<div>{{text}}</div>',
)
class ReadsContentChildrenComponent extends TextDirectivesRenderer {
  @ContentChildren('hasText', read: TextDirective)
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'tests-reads-content-children',
  template: '''
<reads-content-children text="1" #hasText>
  <div text="2"></div>
  <div text="3" #hasText></div>
</reads-content-children>''',
  directives: const [
    ReadsContentChildrenComponent,
    TextDirective,
  ],
)
class TestsReadsContentChildrenComponent {}

@Component(
  selector: 'reads-content-child',
  template: '<div>{{textDirective.text}}</div>',
)
class ReadsContentChildComponent {
  @ContentChild('hasText', read: TextDirective)
  TextDirective textDirective;
}

@Component(
  selector: 'tests-reads-content-child',
  template: '''
<reads-content-child>
  <div text="1"></div>
  <div text="2" #hasText></div>
</reads-content-child>
''',
  directives: const [
    ReadsContentChildComponent,
    TextDirective,
  ],
)
class TestsReadsContentChildComponent {}

@Component(
  selector: 'reads-view-children',
  template: '''
<div text="1"></div>
<div text="2" #hasText></div>
<div>{{text}}</div>
<div text="3" #hasText></div>''',
  directives: const [
    TextDirective,
  ],
)
class ReadsViewChildrenComponent extends TextDirectivesRenderer {
  @ViewChildren('hasText', read: TextDirective)
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'reads-view-child',
  template: '''
<div text="1"></div>
<div text="2" #hasText></div>
<div>{{textDirective.text}}</div>
<div text="3" #hasText></div>''',
  directives: const [
    TextDirective,
  ],
)
class ReadsViewChildComponent {
  @ViewChild('hasText', read: TextDirective)
  TextDirective textDirective;
}

@Component(
  selector: 'reads-view-container-ref',
  template: '<div #hasViewContainerRef></div>',
)
class ReadsViewContainerRefComponent implements AfterViewInit {
  @ContentChild(TemplateRef)
  TemplateRef templateRef;

  @ViewChild('hasViewContainerRef', read: ViewContainerRef)
  ViewContainerRef viewContainerRef;

  @override
  ngAfterViewInit() {
    viewContainerRef.createEmbeddedView(templateRef);
  }
}

@Component(
  selector: 'tests-reads-view-container-ref',
  template: '''
<reads-view-container-ref>
  <template>Embedded in view container!</template>
</reads-view-container-ref>''',
  directives: const [
    ReadsViewContainerRefComponent,
  ],
)
class TestsReadsViewContainerRefComponent {}

@Component(
  selector: 'changes-view-children',
  template: '''
<div [text]="x"></div>
<div [text]="y">
  <div [text]="z"></div>
</div>
<div>{{text}}</div>
''',
  directives: const [
    TextDirective,
  ],
)
class ChangesViewChildrenComponent extends TextDirectivesRenderer {
  String x = '1';
  String y = '2';
  String z = '3';

  @ViewChildren(TextDirective)
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'destroys-view-children',
  template: '''
<template [ngIf]="showView">
  <div text="1"></div>
</template>''',
  directives: const [
    NgIf,
    TextDirective,
  ],
)
class DestroysViewChildrenComponent {
  bool showView = true;

  @ViewChildren(TextDirective)
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'labeled-view-children',
  template: '''
<div
    *ngFor="let item of list"
    [text]="item"
    #textLabel="textDirective">
</div>
<div>{{text}}</div>''',
  directives: const [
    NgFor,
    TextDirective,
  ],
)
class LabeledViewChildrenComponent extends TextDirectivesRenderer {
  List<String> list = <String>['1', '2', '4', '8'];

  @ViewChildren('textLabel')
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'multiple-labeled-view-children',
  template: '''
<div text="0" #textLabel1="textDirective"></div>
<div text="1" #textLabel2="textDirective"></div>
<div>{{text}}</div>''',
  directives: const [
    NgFor,
    TextDirective,
  ],
)
class MultipleLabeledViewChildrenComponent extends TextDirectivesRenderer {
  @ViewChildren('textLabel1,textLabel2')
  QueryList<TextDirective> textDirectives;
}

@Component(
  selector: 'labeled-element-view-children',
  template: '''
<div template="ngFor: let item of list">
  <div #divLabel>{{item}}</div>
</div>''',
  directives: const [
    NgFor,
  ],
)
class LabeledElementViewChildrenComponent {
  List<String> list = <String>['3', '1', '4'];

  @ViewChildren('divLabel')
  QueryList<dynamic> elementRefs;
}
