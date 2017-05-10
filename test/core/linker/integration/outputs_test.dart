@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/src/debug/debug_node.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  test('should support directive outputs on regular elements', () async {
    final testBed = new NgTestBed<ElementWithEventDirectivesComponent>();
    final testFixture = await testBed.create();
    final debugDiv = getDebugNode(testFixture.rootElement.firstChild);
    final emitter = debugDiv.inject(EventEmitterDirective);
    final listener = debugDiv.inject(EventListenerDirective);
    expect(listener.msg, isNull);
    await testFixture.update((_) => emitter.fireEvent('fired!'));
    expect(listener.msg, 'fired!');
  });

  test('should support directive outputs on template elements', () async {
    final testBed = new NgTestBed<TemplateWithEventDirectivesComponent>();
    final testFixture = await testBed.create();
    final debugDiv = getDebugNode(testFixture.rootElement.firstChild);
    final component = debugDiv.inject(TemplateWithEventDirectivesComponent);
    final emitter = debugDiv.inject(EventEmitterDirective);
    final listener = debugDiv.inject(EventListenerDirective);
    expect(component.msg, isNull);
    expect(listener.msg, isNull);
    await testFixture.update((_) => emitter.fireEvent('fired!'));
    expect(component.msg, 'fired!');
    expect(listener.msg, 'fired!');
  });

  test('should support [()] syntax', () async {
    final testBed = new NgTestBed<TwoWayBindingComponent>();
    final testFixture = await testBed.create();
    final debugDiv = getDebugNode(testFixture.rootElement.firstChild);
    final component = debugDiv.inject(TwoWayBindingComponent);
    final directive = debugDiv.inject(DirectiveWithTwoWayBinding);
    expect(directive.control, 'one');
    await testFixture.update((_) => directive.triggerChange('two'));
    expect(component.ctxProp, 'two');
    expect(directive.control, 'two');
  });

  test('should support render events', () async {
    final testBed = new NgTestBed<ElementWithDomEventComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.children.first;
    final listener = getDebugNode(div).inject(DomEventListenerDirective);
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
    expect(clickPrevent.defaultPrevented, isTrue);
    expect(clickNoPrevent.defaultPrevented, isFalse);
    expect(inputPrevent.checked, isFalse);
    expect(inputNoPrevent.checked, isTrue);
  });
}

@Directive(selector: '[emitter]', outputs: const ['event'])
class EventEmitterDirective {
  String msg;
  StreamController _streamController = new StreamController();

  Stream get event => _streamController.stream;

  fireEvent(String msg) {
    _streamController.add(msg);
  }
}

@Directive(selector: '[listener]', host: const {'(event)': 'onEvent(\$event)'})
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
class ElementWithEventDirectivesComponent {}

@Component(
  selector: 'template-event-directives',
  template: '<template emitter listener (event)="msg=\$event"></template>',
  directives: const [EventEmitterDirective, EventListenerDirective],
)
class TemplateWithEventDirectivesComponent {
  String msg;
}

@Directive(
  selector: '[two-way]',
  inputs: const ['control'],
  outputs: const ['controlChange'],
)
class DirectiveWithTwoWayBinding {
  StreamController<String> _streamController = new StreamController<String>();
  var control;

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
class ElementWithDomEventComponent {}

@Directive(
  selector: '[listenerprevent]',
  host: const {'(click)': 'onEvent(\$event)'},
)
class DirectiveListeningDomEventPrevent {
  onEvent(event) {
    return false;
  }
}

@Directive(
  selector: '[listenernoprevent]',
  host: const {'(click)': 'onEvent(\$event)'},
)
class DirectiveListeningDomEventNoPrevent {
  onEvent(event) {
    return true;
  }
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
