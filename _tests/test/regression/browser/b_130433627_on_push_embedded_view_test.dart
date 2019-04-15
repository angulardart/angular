@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'b_130433627_on_push_embedded_view_test.template.dart' as ng;

void main() {
  NgTestFixture<TestComponent> fixture;

  setUp(() async {
    fixture = await NgTestBed.forComponent(ng.TestComponentNgFactory).create();
  });

  tearDown(disposeAnyRunningTest);

  // Embedded views have two kinds of parents. The parent view which defines the
  // embedded view via a `<template>`, and the parent view of the
  // `ViewContainerRef` that hosts the embedded view.
  //
  // When these parents are the same, embedded views are well behaved.
  //
  // However, when an embedded view is hosted in the view container of another
  // OnPush view, it may cease to correctly receive updates from its
  // `<template>` parent.
  //
  // When embedded within an OnPush component, an embedded view is only change
  // detected when that parent is marked to be checked. This poses a problem for
  // embedded views with expressions bound to their `<template>` parent.  When
  // such an embedded view is hosted in the view container of another OnPush
  // component, there's currently no mechanism in the framework that marks that
  // component to be checked when the `<template>` parent receives a change that
  // could invalidate a binding within the `<template>`.
  group(
      'updating the OnPush component which defines a template should update '
      'any embedded views created from that template', () {
    test('when embedded within the OnPush component of origin', () async {
      final component = fixture.assertOnlyInstance;

      expect(component.templateProducer.text, isEmpty);

      await fixture.update((component) {
        component.templateText = 'Hello template!';
      });

      expect(component.templateProducer.text, contains('Hello template!'));

      await fixture.update((component) {
        component.templateText = 'Goodbye template!';
      });

      expect(component.templateProducer.text, contains('Goodbye template!'));
    });

    test('when embedded within a separate OnPush component', () async {
      final component = fixture.assertOnlyInstance;

      expect(component.templateConsumer.text, isEmpty);

      await fixture.update((component) {
        component.templateText = 'Hello template!';
      });

      // The above change only causes the template producer and its child nested
      // views to be updated. Any templates that originated within its view that
      // are embedded in a foreign OnPush view don't receive these changes.
      expect(
        component.templateConsumer.text,
        contains('Hello template!'),
        skip: 'b/130433627',
      );

      await fixture.update((component) {
        component.consumerText = 'Hello consumer!';
      });

      // The above change that was previously expected is now observed in the
      // template embedded in a foreign view container with an OnPush parent.
      expect(
        component.templateConsumer.text,
        contains('Hello template!'),
        reason: 'Unrelated change to view container parent triggers change '
            'detection of nested views which delivers an old change from the '
            'template parent to the embedded view.',
      );
      expect(component.templateConsumer.text, contains('Hello consumer!'));
    });
  });
}

@Component(
  selector: 'test',
  directives: [
    TemplateProducerComponent,
    TemplateConsumerComponent,
  ],
  template: '''
    <template-producer
        #templateProducer="templateProducer"
        [templateText]="templateText">
    </template-producer>
    <template-consumer
        #templateConsumer
        [template]="templateProducer.template"
        [text]="consumerText">
    </template-consumer>
  ''',
)
class TestComponent {
  @ViewChild('templateConsumer', read: Element)
  Element templateConsumer;

  @ViewChild('templateProducer', read: Element)
  Element templateProducer;

  var templateText = '';
  var consumerText = '';
}

@Component(
  selector: 'template-producer',
  template: '''
    <template #template>{{templateText}}</template>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
  exportAs: 'templateProducer',
)
class TemplateProducerComponent implements OnInit {
  @ViewChild('template', read: ViewContainerRef)
  ViewContainerRef container;

  @ViewChild('template')
  TemplateRef template;

  @Input()
  String templateText;

  @override
  void ngOnInit() {
    container.createEmbeddedView(template);
  }
}

@Component(
  selector: 'template-consumer',
  template: '''
    <template #container></template>
    <div>{{text}}</div>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class TemplateConsumerComponent implements OnInit {
  @ViewChild('container', read: ViewContainerRef)
  ViewContainerRef container;

  @Input()
  TemplateRef template;

  @Input()
  String text;

  @override
  void ngOnInit() {
    container.createEmbeddedView(template);
  }
}
