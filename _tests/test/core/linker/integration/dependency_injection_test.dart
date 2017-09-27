@Tags(const ['codegen'])
@TestOn('browser')

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/debug/debug_node.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  test('should support bindings', () async {
    final testBed = new NgTestBed<ProvideConsumeInjectableComponent>();
    final testFixture = await testBed.create();
    final debugNode = getDebugNode(testFixture.rootElement.children.first);
    final consumer = debugNode.getLocal('consumer');
    expect(consumer.injectable, new isInstanceOf<InjectableService>());
  });

  test('should support viewProviders', () async {
    final testBed = new NgTestBed<ProvidesInjectableInViewComponent>();
    final testFixture = await testBed.create();
    final debugNode = getDebugNode(testFixture.rootElement.children.first);
    final consumer = debugNode.getLocal('consumer');
    expect(consumer.injectable, new isInstanceOf<InjectableService>());
  });

  test('should support unbounded lookup', () async {
    final testBed = new NgTestBed<ProvidesInjectableUnboundedComponent>();
    final testFixture = await testBed.create();
    final debugNode = getDebugNode(testFixture.rootElement.children.first);
    final dir = debugNode.getLocal('dir');
    expect(dir.directive.injectable, new isInstanceOf<InjectableService>());
  });

  test('should support the event-bus scenario', () async {
    final testBed = new NgTestBed<EventBusComponent>();
    final testFixture = await testBed.create();
    final grandParentElement = getDebugNode(testFixture.rootElement
        .querySelector('grand-parent-providing-event-bus'));
    final parentElement = getDebugNode(
        testFixture.rootElement.querySelector('parent-providing-event-bus'));
    final childElement = getDebugNode(
        testFixture.rootElement.querySelector('child-consuming-event-bus'));
    final grandParent = grandParentElement.inject(GrandParentProvidingEventBus);
    final parent = parentElement.inject(ParentProvidingEventBus);
    final child = childElement.inject(ChildConsumingEventBus);
    expect(grandParent.bus.name, 'grandparent');
    expect(parent.bus.name, 'parent');
    expect(parent.grandParentBus, grandParent.bus);
    expect(child.bus, parent.bus);
  });

  test('should instantiate bindings lazily', () async {
    final testBed = new NgTestBed<LazyBindingsComponent>();
    final testFixture = await testBed.create();
    final debugNode = getDebugNode(testFixture.rootElement.children.first);
    final providing = debugNode.getLocal('providing');
    expect(providing.created, false);
    await testFixture.update((component) => component.visible = true);
    expect(providing.created, true);
  });

  test('should inject @Host', () async {
    final testBed = new NgTestBed<InjectsHostComponent>();
    final testFixture = await testBed.create();
    final someDirective = testFixture.rootElement.children.first;
    final cmp = getDebugNode(someDirective).getLocal('cmp');
    expect(cmp.myHost, new isInstanceOf<SomeDirective>());
  });

  test('should create a component that injects @Host through ViewContainer',
      () async {
    final testBed = new NgTestBed<InjectsHostThroughViewContainer>();
    final testFixture = await testBed.create();
    final cmpWithHost = testFixture.rootElement.querySelector('cmp-with-host');
    final cmp = getDebugNode(cmpWithHost).getLocal('cmp');
    expect(cmp.myHost, new isInstanceOf<SomeDirective>());
  });
}

@Injectable()
class InjectableService {}

@Component(
  selector: 'directive-consuming-injectable',
  template: '',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class DirectiveConsumingInjectable {
  InjectableService injectable;

  DirectiveConsumingInjectable(
      @Host() @Inject(InjectableService) this.injectable);
}

@Directive(
  selector: 'directive-providing-injectable',
  providers: const [InjectableService],
)
class DirectiveProvidingInjectable {}

@Component(
  selector: 'provide-consume-injectable',
  template: '''
<directive-providing-injectable>
  <directive-consuming-injectable #consumer></directive-consuming-injectable>
</directive-providing-injectable>''',
  directives: const [
    DirectiveConsumingInjectable,
    DirectiveProvidingInjectable,
  ],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class ProvideConsumeInjectableComponent {}

@Component(
  selector: 'provides-injectable-in-view',
  template: '''
<directive-consuming-injectable #consumer>
</directive-consuming-injectable>''',
  directives: const [DirectiveConsumingInjectable],
  viewProviders: const [InjectableService],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class ProvidesInjectableInViewComponent {}

@Component(
  selector: 'directive-containing-directive-consuming-an-injectable',
  template: '''
<directive-consuming-injectable-unbounded>
</directive-consuming-injectable-unbounded>''',
  directives: const [DirectiveConsumingInjectableUnbounded],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class DirectiveContainingDirectiveConsumingAnInjectable {
  var directive;
}

@Component(
  selector: 'directive-consuming-injectable-unbounded', template: '',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class DirectiveConsumingInjectableUnbounded {
  InjectableService injectable;

  DirectiveConsumingInjectableUnbounded(this.injectable,
      @SkipSelf() DirectiveContainingDirectiveConsumingAnInjectable parent) {
    parent.directive = this;
  }
}

@Component(
  selector: 'provides-injectable-unbounded',
  template: '''
<directive-providing-injectable>
  <directive-containing-directive-consuming-an-injectable #dir>
  </directive-containing-directive-consuming-an-injectable>
</directive-providing-injectable>''',
  directives: const [
    DirectiveProvidingInjectable,
    DirectiveContainingDirectiveConsumingAnInjectable,
  ],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class ProvidesInjectableUnboundedComponent {}

class EventBus {
  final EventBus parentEventBus;
  final String name;

  const EventBus(this.parentEventBus, this.name);
}

const grandParentBus = const EventBus(null, 'grandparent');

@Directive(
  selector: 'grand-parent-providing-event-bus',
  providers: const [
    const Provider(EventBus, useValue: grandParentBus),
  ],
)
class GrandParentProvidingEventBus {
  EventBus bus;

  GrandParentProvidingEventBus(this.bus);
}

EventBus createParentBus(EventBus parentEventBus) {
  return new EventBus(parentEventBus, 'parent');
}

@Component(
  selector: 'parent-providing-event-bus',
  providers: const [
    const Provider(EventBus, useFactory: createParentBus, deps: const [
      const [EventBus, const SkipSelf()]
    ])
  ],
  directives: const [ChildConsumingEventBus],
  template: '<child-consuming-event-bus></child-consuming-event-bus>',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class ParentProvidingEventBus {
  EventBus bus;
  EventBus grandParentBus;

  ParentProvidingEventBus(this.bus, @SkipSelf() this.grandParentBus);
}

@Directive(selector: 'child-consuming-event-bus')
class ChildConsumingEventBus {
  EventBus bus;

  ChildConsumingEventBus(@SkipSelf() this.bus);
}

@Component(
  selector: 'event-bus',
  template: '''
<grand-parent-providing-event-bus>
  <parent-providing-event-bus></parent-providing-event-bus>
</grand-parent-providing-event-bus>''',
  directives: const [
    GrandParentProvidingEventBus,
    ParentProvidingEventBus,
  ],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class EventBusComponent {}

InjectableService createInjectableWithLogging(Injector injector) {
  injector.get(ComponentProvidingLoggingInjectable).created = true;
  return new InjectableService();
}

@Component(
  selector: 'component-providing-logging-injectable',
  providers: const [
    const Provider(InjectableService,
        useFactory: createInjectableWithLogging, deps: const [Injector])
  ],
  template: '',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class ComponentProvidingLoggingInjectable {
  bool created = false;
}

@Component(
  selector: 'lazy-bindings',
  template: '''
<component-providing-logging-injectable #providing>
  <directive-consuming-injectable *ngIf="visible">
  </directive-consuming-injectable>
</component-providing-logging-injectable>''',
  directives: const [
    ComponentProvidingLoggingInjectable,
    DirectiveConsumingInjectable,
    NgIf,
  ],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class LazyBindingsComponent {
  bool visible = false;
}

@Directive(selector: 'some-directive')
class SomeDirective {}

@Component(
  selector: 'cmp-with-host',
  template: '<p>Component with an injected host</p>',
  directives: const [SomeDirective],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class CompWithHost {
  SomeDirective myHost;

  CompWithHost(@Host() SomeDirective someComp) {
    this.myHost = someComp;
  }
}

@Component(
  selector: 'injects-host',
  template:
      '<some-directive><cmp-with-host #cmp></cmp-with-host></some-directive>',
  directives: const [CompWithHost, SomeDirective],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class InjectsHostComponent {}

@Component(
  selector: 'injects-host-through-view-container',
  template: '''
<some-directive>
  <p *ngIf="true">
    <cmp-with-host #cmp></cmp-with-host>
  </p>
</some-directive>''',
  directives: const [CompWithHost, NgIf, SomeDirective],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class InjectsHostThroughViewContainer {}
