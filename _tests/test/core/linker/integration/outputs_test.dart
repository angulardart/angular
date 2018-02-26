@TestOn('browser')

import 'dart:async';
import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'outputs_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should support directive outputs on regular elements', () async {
    final testBed = new NgTestBed<ElementWithEventDirectivesComponent>();
    final testFixture = await testBed.create();
    final emitter = testFixture.assertOnlyInstance.emitter;
    final listener = testFixture.assertOnlyInstance.listener;
    expect(listener.msg, isNull);
    await testFixture.update((_) => emitter.fireEvent('fired!'));
    expect(listener.msg, 'fired!');
  });

  test('should support directive outputs on template elements', () async {
    final testBed = new NgTestBed<TemplateWithEventDirectivesComponent>();
    final testFixture = await testBed.create();
    final component = testFixture.assertOnlyInstance;
    expect(component.msg, isNull);
    expect(component.listener.msg, isNull);
    await testFixture.update((_) => component.emitter.fireEvent('fired!'));
    expect(component.msg, 'fired!');
    expect(component.listener.msg, 'fired!');
  });

  test('should support [()] syntax', () async {
    final testBed = new NgTestBed<TwoWayBindingComponent>();
    final testFixture = await testBed.create();
    final component = testFixture.assertOnlyInstance;
    expect(component.directive.control, 'one');
    await testFixture.update((_) => component.directive.triggerChange('two'));
    expect(component.ctxProp, 'two');
    expect(component.directive.control, 'two');
  });

  test('should support render events', () async {
    final testBed = new NgTestBed<ElementWithDomEventComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.children.first;
    final listener = testFixture.assertOnlyInstance.listener;
    await testFixture.update((_) => div.dispatchEvent(new Event('domEvent')));
    expect(listener.eventTypes, ['domEvent']);
  });

  test('should support preventing default on render events', () async {
    final testBed = new NgTestBed<TestPreventDefaultComponent>();
    final testFixture = await testBed.create();
    final inputPrevent = testFixture.rootElement.children[0] as InputElement;
    final inputNoPrevent = testFixture.rootElement.children[1] as InputElement;
    final clickPrevent = new MouseEvent('click');
    final clickNoPrevent = new MouseEvent('click');
    inputPrevent.dispatchEvent(clickPrevent);
    inputNoPrevent.dispatchEvent(clickNoPrevent);
    await testFixture.update();
    expect(clickPrevent.defaultPrevented, true);
    expect(clickNoPrevent.defaultPrevented, false);
    expect(inputPrevent.checked, false);
    expect(inputNoPrevent.checked, true);
  });
}

@Directive(
  selector: '[emitter]',
)
class EventEmitterDirective {
  String msg;
  final _streamController = new StreamController<String>();

  @Output()
  Stream get event => _streamController.stream;

  fireEvent(String msg) {
    _streamController.add(msg);
  }
}

@Directive(
  selector: '[listener]',
  host: const {'(event)': 'onEvent(\$event)'},
)
class EventListenerDirective {
  String msg;

  onEvent(String msg) {
    this.msg = msg;
  }
}

@Component(
  selector: 'event-directives',
  template: '<div emitter listener></div>',
  directives: const [EventEmitterDirective, EventListenerDirective],
)
class ElementWithEventDirectivesComponent {
  @ViewChild(EventEmitterDirective)
  EventEmitterDirective emitter;

  @ViewChild(EventListenerDirective)
  EventListenerDirective listener;
}

@Component(
  selector: 'template-event-directives',
  template: '<template emitter listener (event)="msg=\$event"></template>',
  directives: const [EventEmitterDirective, EventListenerDirective],
)
class TemplateWithEventDirectivesComponent {
  String msg;

  @ViewChild(EventEmitterDirective)
  EventEmitterDirective emitter;

  @ViewChild(EventListenerDirective)
  EventListenerDirective listener;
}

@Directive(
  selector: '[two-way]',
)
class DirectiveWithTwoWayBinding {
  final _streamController = new StreamController<String>();

  @Input()
  var control;

  @Output()
  get controlChange => _streamController.stream;

  triggerChange(String value) {
    _streamController.add(value);
  }
}

@Component(
  selector: 'two-way-binding',
  template: '<div [(control)]="ctxProp" two-way></div>',
  directives: const [DirectiveWithTwoWayBinding],
)
class TwoWayBindingComponent {
  String ctxProp = 'one';

  @ViewChild(DirectiveWithTwoWayBinding)
  DirectiveWithTwoWayBinding directive;
}

@Directive(
  selector: '[listener]',
  host: const {
    '(domEvent)': 'onEvent(\$event.type)',
  },
)
class DomEventListenerDirective {
  List<String> eventTypes = [];

  onEvent(String eventType) {
    eventTypes.add(eventType);
  }
}

@Component(
  selector: 'element-with-dom-event',
  template: '<div listener></div>',
  directives: const [DomEventListenerDirective],
)
class ElementWithDomEventComponent {
  @ViewChild(DomEventListenerDirective)
  DomEventListenerDirective listener;
}

@Directive(
  selector: '[listenerprevent]',
  host: const {'(click)': 'onEvent(\$event)'},
)
class DirectiveListeningDomEventPrevent {
  onEvent(Event event) {
    event.preventDefault();
  }
}

@Directive(
  selector: '[listenernoprevent]',
  host: const {'(click)': 'onEvent(\$event)'},
)
class DirectiveListeningDomEventNoPrevent {
  onEvent(Event event) {}
}

@Component(
  selector: 'test-prevent-default',
  template: '<input type="checkbox" listenerprevent>'
      '<input type="checkbox" listenernoprevent>',
  directives: const [
    DirectiveListeningDomEventNoPrevent,
    DirectiveListeningDomEventPrevent,
  ],
)
class TestPreventDefaultComponent {}
