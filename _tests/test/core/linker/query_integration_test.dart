@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'query_integration_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('query for Directive', () {
    test('should contain first content child', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestsContentChildComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2');
    });

    test('should contain all view children', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestsViewChildrenComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), 'a|b|c');
    });

    test('should contain first view child', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestsViewChildComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), 'a');
    });

    test('should contain first content child in embedded view', () async {
      final testBed = NgTestBed.forComponent(
          ng.TestsEmbeddedContentChildComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), isEmpty);
      await testFixture.update((component) => component.showContent = true);
      expect(testFixture.text.trim(), '1');
    });

    test('should contain all view children in embedded view', () async {
      final testBed = NgTestBed.forComponent(
          ng.TestsEmbeddedViewChildrenComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), isEmpty);
      await testFixture.update((component) => component.showView = true);
      expect(testFixture.text.trim(), 'a|b|c');
    });

    test('should contain first view child in embedded view', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestsEmbeddedViewChildComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), 'c');
      await testFixture.update((component) => component.showView = true);
      expect(testFixture.text.trim(), 'a');
    });

    test('should handle moved directives', () async {
      final testBed =
          NgTestBed.forComponent(ng.MovesDirectiveComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1|2|3');
      await testFixture.update((component) => component.list = ['3', '2']);
      expect(testFixture.text.trim(), '3|2');
    });

    test('should support transclusion', () async {
      final testBed = NgTestBed.forComponent(
          ng.TestsTranscludedContentChildrenComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2|7');
    });

    test('should not be affected by unrelated changes', () async {
      final testBed =
          NgTestBed.forComponent(ng.UnrelatedChangesComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1');
      await testFixture.update((component) {
        component.showInertDirective = false;
      });
      expect(testFixture.text.trim(), '1');
    });

    test('should handle long ngFor cycles', () async {
      final testBed =
          NgTestBed.forComponent(ng.LongNgForCycleComponentNgFactory);
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
      final testBed = NgTestBed.forComponent(ng.FourQueriesComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1|1|1|1');
    });
  });

  group('query for TemplateRef', () {
    test('should find content and view children', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestsTemplateRefComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.rootElement.querySelectorAll('.embedded-from-content'),
          hasLength(2));
      expect(testFixture.rootElement.querySelectorAll('.embedded-from-view'),
          hasLength(2));
    });

    test('should find named content child and named view child', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestsNamedTemplateRefComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.rootElement.querySelectorAll('.embedded-from-content'),
          hasLength(1));
      expect(testFixture.rootElement.querySelectorAll('.embedded-from-view'),
          hasLength(1));
    });
  });

  group('query for a different token via read', () {
    test('should contain all content children', () async {
      final testBed = NgTestBed.forComponent(
          ng.TestsReadsContentChildrenComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1|3');
    });

    test('should contain the first content child', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestsReadsContentChildComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2');
    });

    test('should contain all view children', () async {
      final testBed =
          NgTestBed.forComponent(ng.ReadsViewChildrenComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2|3');
    });

    test('should contain the first view child', () async {
      final testBed =
          NgTestBed.forComponent(ng.ReadsViewChildComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '2');
    });

    test('should support ViewContainer', () async {
      final testBed = NgTestBed.forComponent(
          ng.TestsReadsViewContainerRefComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), 'Embedded in view container!');
    });
  });

  group('changes', () {
    test('should update query results', () async {
      final testBed =
          NgTestBed.forComponent(ng.ChangesViewChildrenComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1|2|3');
      await testFixture.update((component) {
        component.x = '3';
        component.z = '1';
      });
      expect(testFixture.text.trim(), '3|2|1');
    });

    test('should remove destroyed directives from query results', () async {
      final testBed =
          NgTestBed.forComponent(ng.DestroysViewChildrenComponentNgFactory);
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
      final testBed =
          NgTestBed.forComponent(ng.LabeledViewChildrenComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '1|2|4|8');
    });

    test('should support multiple variables', () async {
      final testBed = NgTestBed.forComponent(
          ng.MultipleLabeledViewChildrenComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text.trim(), '0|1');
    });

    test('should support changes', () async {
      final testBed =
          NgTestBed.forComponent(ng.LabeledViewChildrenComponentNgFactory);
      final testFixture = await testBed.create();
      await testFixture.update((component) {
        component.list = ['8', '4', '2', '1'];
      });
      expect(testFixture.text.trim(), '8|4|2|1');
    });

    test('should support element binding', () async {
      final testBed = NgTestBed.forComponent(
          ng.LabeledElementViewChildrenComponentNgFactory);
      var fixture = await testBed.create();
      var component = fixture.assertOnlyInstance;
      final divIt = component.elementRefs.iterator;
      final itemIt = component.list.iterator;

      while (divIt.moveNext()) {
        itemIt.moveNext();
        expect(divIt.current.text, itemIt.current);
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
  List<TextDirective> textDirectives;
}

@Component(
  selector: 'content-child',
  template: '<div>{{textDirective?.text}}</div><ng-content></ng-content>',
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
  directives: [
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
<div text="c"></div>
<ng-content></ng-content>''',
  directives: [
    TextDirective,
  ],
)
class ViewChildrenComponent extends TextDirectivesRenderer {
  @ViewChildren(TextDirective)
  List<TextDirective> textDirectives;
}

@Component(
  selector: 'tests-view-children',
  template: '''
<div text="1"></div>
<view-children text="2">
  <div text="3"></div>
</view-children>
<div text="4"></div>''',
  directives: [
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
<div text="c"></div>
<ng-content></ng-content>''',
  directives: [
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
  directives: [
    TextDirective,
    ViewChildComponent,
  ],
)
class TestsViewChildComponent {}

@Component(
  selector: 'tests-embedded-content-children',
  template: '''
<content-child>
  <div *ngIf="showContent" text="1">
    <div text="2"></div>
  </div>
</content-child>''',
  directives: [
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
  directives: [
    NgIf,
    TextDirective,
  ],
)
class TestsEmbeddedViewChildrenComponent extends TextDirectivesRenderer {
  bool showView = false;

  @ViewChildren(TextDirective)
  List<TextDirective> textDirectives;
}

@Component(
  selector: 'embedded-view-child',
  template: '''
<div *ngIf="showView" text="a">
  <div text="b"></div>
</div>
<div text="c"></div>
<div>{{textDirective?.text}}</div>''',
  directives: [
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
  directives: [
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
  List<TextDirective> textDirectives;
}

@Component(
  selector: 'tests-transcluded-content-children',
  template: '''
<transcluded-content-children>
  <div text="2"></div>
  <div text="7"></div>
</transcluded-content-children>''',
  directives: [
    TextDirective,
    TranscludedContentChildrenComponent,
  ],
)
class TestsTranscludedContentChildrenComponent {}

@Directive(
  selector: '[inert]',
)
class InertDirective {}

@Component(
  selector: 'unrelated-changes',
  template: '''
<div text="1"></div>
<div *ngIf="showInertDirective" inert></div>
<div>{{text}}</div>
  ''',
  directives: [
    InertDirective,
    NgIf,
    TextDirective,
  ],
)
class UnrelatedChangesComponent extends TextDirectivesRenderer {
  bool showInertDirective = true;

  @ViewChildren(TextDirective)
  List<TextDirective> textDirectives;
}

@Component(
  selector: 'long-ng-for-cycle',
  template: '''
<div *ngFor="let item of list" [text]="item"></div>
<div>{{text}}</div>
''',
  directives: [
    NgFor,
    TextDirective,
  ],
)
class LongNgForCycleComponent extends TextDirectivesRenderer {
  List<String> list = <String>[];

  @ViewChildren(TextDirective)
  List<TextDirective> textDirectives;
}

@Component(
  selector: 'four-queries',
  template: '''
<div text="1"></div>
<div>{{q1.text}}|{{q2.text}}|{{q3.text}}|{{q4.text}}</div>''',
  directives: [
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
  List<TemplateRef> contentTemplateRefs;

  @ViewChildren(TemplateRef)
  List<TemplateRef> viewTemplateRefs;

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
  directives: [
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
  directives: [
    NamedTemplateRefComponent,
  ],
)
class TestsNamedTemplateRefComponent {}

@Component(
  selector: 'reads-content-children',
  template: '<div>{{text}}</div><ng-content></ng-content>',
)
class ReadsContentChildrenComponent extends TextDirectivesRenderer {
  @ContentChildren('hasText', read: TextDirective)
  List<TextDirective> textDirectives;
}

@Component(
  selector: 'tests-reads-content-children',
  template: '''
<reads-content-children text="1" #hasText>
  <div text="2"></div>
  <div text="3" #hasText></div>
</reads-content-children>''',
  directives: [
    ReadsContentChildrenComponent,
    TextDirective,
  ],
)
class TestsReadsContentChildrenComponent {}

@Component(
  selector: 'reads-content-child',
  template: '<div>{{textDirective.text}}</div><ng-content></ng-content>',
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
  directives: [
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
  directives: [
    TextDirective,
  ],
)
class ReadsViewChildrenComponent extends TextDirectivesRenderer {
  @ViewChildren('hasText', read: TextDirective)
  List<TextDirective> textDirectives;
}

@Component(
  selector: 'reads-view-child',
  template: '''
<div text="1"></div>
<div text="2" #hasText></div>
<div>{{textDirective.text}}</div>
<div text="3" #hasText></div>''',
  directives: [
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
  directives: [
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
  directives: [
    TextDirective,
  ],
)
class ChangesViewChildrenComponent extends TextDirectivesRenderer {
  String x = '1';
  String y = '2';
  String z = '3';

  @ViewChildren(TextDirective)
  List<TextDirective> textDirectives;
}

@Component(
  selector: 'destroys-view-children',
  template: '''
<template [ngIf]="showView">
  <div text="1"></div>
</template>''',
  directives: [
    NgIf,
    TextDirective,
  ],
)
class DestroysViewChildrenComponent {
  bool showView = true;

  @ViewChildren(TextDirective)
  List<TextDirective> textDirectives;
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
  directives: [
    NgFor,
    TextDirective,
  ],
)
class LabeledViewChildrenComponent extends TextDirectivesRenderer {
  List<String> list = <String>['1', '2', '4', '8'];

  @ViewChildren('textLabel')
  List<TextDirective> textDirectives;
}

@Component(
  selector: 'multiple-labeled-view-children',
  template: '''
<div text="0" #textLabel1="textDirective"></div>
<div text="1" #textLabel2="textDirective"></div>
<div>{{text}}</div>''',
  directives: [
    NgFor,
    TextDirective,
  ],
)
class MultipleLabeledViewChildrenComponent extends TextDirectivesRenderer {
  @ViewChildren('textLabel1,textLabel2')
  List<TextDirective> textDirectives;
}

@Component(
  selector: 'labeled-element-view-children',
  template: '''
<div *ngFor="let item of list">
  <div #divLabel>{{item}}</div>
</div>''',
  directives: [
    NgFor,
  ],
)
class LabeledElementViewChildrenComponent {
  List<String> list = <String>['3', '1', '4'];

  @ViewChildren('divLabel')
  List<HtmlElement> elementRefs;
}
