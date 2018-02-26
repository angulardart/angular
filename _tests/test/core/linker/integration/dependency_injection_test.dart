@TestOn('browser')

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'dependency_injection_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should support bindings', () async {
    final testBed = new NgTestBed<ProvideConsumeInjectableComponent>();
    final testFixture = await testBed.create();
    final consumer = testFixture.assertOnlyInstance.consumer;
    expect(consumer.injectable, new isInstanceOf<InjectableService>());
  });

  test('should support viewProviders', () async {
    final testBed = new NgTestBed<ProvidesInjectableInViewComponent>();
    final testFixture = await testBed.create();
    final consumer = testFixture.assertOnlyInstance.consumer;
    expect(consumer.injectable, new isInstanceOf<InjectableService>());
  });

  test('should support unbounded lookup', () async {
    final testBed = new NgTestBed<ProvidesInjectableUnboundedComponent>();
    final testFixture = await testBed.create();
    final dir = testFixture.assertOnlyInstance.container;
    expect(dir.directive.injectable, new isInstanceOf<InjectableService>());
  });

  test('should support the event-bus scenario', () async {
    final testBed = new NgTestBed<EventBusComponent>();
    final testFixture = await testBed.create();
    final grandParent = testFixture.assertOnlyInstance.grandParent;
    final parent = testFixture.assertOnlyInstance.parent;
    final child = parent.child;
    expect(grandParent.bus.name, 'grandparent');
    expect(parent.bus.name, 'parent');
    expect(parent.grandParentBus, grandParent.bus);
    expect(child.bus, parent.bus);
  });

  test('should instantiate bindings lazily', () async {
    final testBed = new NgTestBed<LazyBindingsComponent>();
    final testFixture = await testBed.create();
    final providing = testFixture.assertOnlyInstance.providing;
    expect(providing.created, false);
    await testFixture.update((component) => component.visible = true);
    expect(providing.created, true);
  });

  test('should inject @Host', () async {
    final testBed = new NgTestBed<InjectsHostComponent>();
    final testFixture = await testBed.create();
    final cmp = testFixture.assertOnlyInstance.compWithHost;
    expect(cmp.myHost, new isInstanceOf<SomeDirective>());
  });

  test('should create a component that injects @Host through ViewContainer',
      () async {
    final testBed = new NgTestBed<InjectsHostThroughViewContainer>();
    final testFixture = await testBed.create();
    final cmp = testFixture.assertOnlyInstance.compWithHost;
    expect(cmp.myHost, new isInstanceOf<SomeDirective>());
  });
}

@Injectable()
class InjectableService {}

@Component(
  selector: 'directive-consuming-injectable',
  template: '',
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
)
class ProvideConsumeInjectableComponent {
  @ViewChild('consumer')
  DirectiveConsumingInjectable consumer;
}

@Component(
  selector: 'provides-injectable-in-view',
  template: '''
<directive-consuming-injectable #consumer>
</directive-consuming-injectable>''',
  directives: const [DirectiveConsumingInjectable],
  viewProviders: const [InjectableService],
)
class ProvidesInjectableInViewComponent {
  @ViewChild('consumer')
  DirectiveConsumingInjectable consumer;
}

@Component(
  selector: 'directive-containing-directive-consuming-an-injectable',
  template: '''
<directive-consuming-injectable-unbounded>
</directive-consuming-injectable-unbounded>''',
  directives: const [DirectiveConsumingInjectableUnbounded],
  visibility: Visibility.all,
)
class DirectiveContainingDirectiveConsumingAnInjectable {
  var directive;
}

@Component(
  selector: 'directive-consuming-injectable-unbounded',
  template: '',
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
)
class ProvidesInjectableUnboundedComponent {
  @ViewChild('dir')
  DirectiveContainingDirectiveConsumingAnInjectable container;
}

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
)
class ParentProvidingEventBus {
  EventBus bus;
  EventBus grandParentBus;

  @ViewChild(ChildConsumingEventBus)
  ChildConsumingEventBus child;

  ParentProvidingEventBus(this.bus, @SkipSelf() this.grandParentBus);
}

@Directive(
  selector: 'child-consuming-event-bus',
)
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
)
class EventBusComponent {
  @ViewChild(GrandParentProvidingEventBus)
  GrandParentProvidingEventBus grandParent;

  @ViewChild(ParentProvidingEventBus)
  ParentProvidingEventBus parent;
}

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
  visibility: Visibility.all,
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
)
class LazyBindingsComponent {
  bool visible = false;

  @ViewChild('providing')
  ComponentProvidingLoggingInjectable providing;
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
  selector: 'injects-host',
  template:
      '<some-directive><cmp-with-host #cmp></cmp-with-host></some-directive>',
  directives: const [CompWithHost, SomeDirective],
)
class InjectsHostComponent {
  @ViewChild('cmp')
  CompWithHost compWithHost;
}

@Component(
  selector: 'injects-host-through-view-container',
  template: '''
<some-directive>
  <p *ngIf="true">
    <cmp-with-host #cmp></cmp-with-host>
  </p>
</some-directive>''',
  directives: const [CompWithHost, NgIf, SomeDirective],
)
class InjectsHostThroughViewContainer {
  @ViewChild('cmp')
  CompWithHost compWithHost;
}
