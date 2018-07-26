@TestOn('browser')
library angular2.test.core.linker.deferred_component_test;

import 'dart:async';
import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:angular/angular.dart';
import 'package:test/test.dart';

import 'deferred_component_test.template.dart' as ng;
import 'deferred_view.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  test('should load a @deferred component', () async {
    final fixture = await NgTestBed.forComponent(
      ng.SimpleContainerTestNgFactory,
    ).create();

    // We only test this in DDC so a new macro-task is sufficient.
    await Future.delayed(Duration.zero);
    final view = fixture.rootElement.querySelector('my-deferred-view');
    expect(view, isNotNull);
    expect(fixture.text, contains('Title:'));
  });

  test('should load a @deferred component nested in an *ngIf', () async {
    final fixture = await NgTestBed.forComponent(
      ng.NestedContainerTestNgFactory,
    ).create();
    Element view = fixture.rootElement.querySelector('my-deferred-view');
    expect(view, isNull);

    await fixture.update((c) => c.show = true);
    view = fixture.rootElement.querySelector('my-deferred-view');
    expect(view, isNotNull);
  });

  test('should pass property values to an @deferred component', () async {
    final fixture = await NgTestBed.forComponent(
      ng.PropertyContainerTestNgFactory,
    ).create();
    expect(fixture.text, contains('Title: Hello World'));
  });

  test('should listen to events from an @deferred component', () async {
    final fixture = await NgTestBed.forComponent(
      ng.EventContainerTestNgFactory,
    ).create();
    final div = fixture.rootElement.querySelector('my-deferred-view > button');
    expect(fixture.text, contains('Events: 0'));
    await fixture.update((_) {
      div.click();
    });
    expect(fixture.text, contains('Events: 1'));
  });

  test('should be notified when a deferred component is loaded', () async {
    final fixture = await NgTestBed.forComponent(
      ng.LoadNotifierTestNgFactory,
    ).create(beforeChangeDetection: expectAsync1((comp) {
      expect(comp.child1, isNull);
      expect(comp.child2, isNull);
      expect(comp.children, isNull);
    }));
    // We only test this in DDC so a new macro-task is sufficient.
    await Future.delayed(Duration.zero);
    expect(fixture.assertOnlyInstance.child1, isNotNull);
    expect(fixture.assertOnlyInstance.child2, isNotNull);
    expect(fixture.assertOnlyInstance.children, [
      fixture.assertOnlyInstance.child1,
      fixture.assertOnlyInstance.child2,
    ]);
  });
}

@Component(
  selector: 'simple-container',
  directives: [DeferredChildComponent],
  template: r'''
    <section>
      <my-deferred-view @deferred></my-deferred-view>
    </section>
  ''',
)
class SimpleContainerTest {
  final ChangeDetectorRef cdRef;

  SimpleContainerTest(this.cdRef);
}

@Component(
  selector: 'nested-container',
  directives: [DeferredChildComponent, NgIf],
  template: r'''
    <section *ngIf="show">
      <my-deferred-view @deferred></my-deferred-view>
    </section>
  ''',
)
class NestedContainerTest {
  bool show = false;
}

@Component(
  selector: 'property-container',
  directives: [DeferredChildComponent],
  template: r'''
    <section>
      <my-deferred-view @deferred [title]="'Hello World'"></my-deferred-view>
    </section>
  ''',
)
class PropertyContainerTest {}

@Component(
  selector: 'event-container',
  directives: [DeferredChildComponent],
  template: r'''
    <section>
      Events:&ngsp;{{count}}
      <my-deferred-view @deferred (selected)="onSelected()"></my-deferred-view>
    </section>
  ''',
)
class EventContainerTest {
  int count = 0;

  void onSelected() {
    count++;
  }
}

@Component(
  selector: 'load-notifier',
  directives: [DeferredChildComponent],
  template: r'''
    <my-deferred-view @deferred #ref1></my-deferred-view>
    <my-deferred-view @deferred #ref2></my-deferred-view>
  ''',
)
class LoadNotifierTest {
  @ViewChild('ref1')
  DeferredChildComponent child1;

  @ViewChild('ref2')
  DeferredChildComponent child2;

  @ViewChildren(DeferredChildComponent)
  List<DeferredChildComponent> children;
}
