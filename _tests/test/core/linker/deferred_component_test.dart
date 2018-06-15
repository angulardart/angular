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
    final fixture = await NgTestBed.forComponent<SimpleContainerTest>(
      ng.SimpleContainerTestNgFactory,
    ).create();

    SimpleContainerTest comp;
    await fixture.update((SimpleContainerTest component) {
      comp = component;
    });
    await comp.waitForDeferred();
    final view = fixture.rootElement.querySelector('my-deferred-view');
    expect(view, isNotNull);
    expect(fixture.text, contains('Title:'));
  });

  test('should load a @deferred component nested in an *ngIf', () async {
    final fixture = await NgTestBed.forComponent<NestedContainerTest>(
      ng.NestedContainerTestNgFactory,
    ).create();
    Element view = fixture.rootElement.querySelector('my-deferred-view');
    expect(view, isNull);

    await fixture.update((c) => c.show = true);
    view = fixture.rootElement.querySelector('my-deferred-view');
    expect(view, isNotNull);
  });

  test('should pass property values to an @deferred component', () async {
    final fixture = await NgTestBed.forComponent<PropertyContainerTest>(
      ng.PropertyContainerTestNgFactory,
    ).create();
    expect(fixture.text, contains('Title: Hello World'));
  });

  test('should listen to events from an @deferred component', () async {
    final fixture = await NgTestBed.forComponent<EventContainerTest>(
      ng.EventContainerTestNgFactory,
    ).create();
    final div = fixture.rootElement.querySelector('my-deferred-view > button');
    expect(fixture.text, contains('Events: 0'));
    await fixture.update((_) {
      div.click();
    });
    expect(fixture.text, contains('Events: 1'));
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

  Future waitForDeferred() async {
    // TODO(matanl): Add proper support to this instead of using a timer.
    await Future.delayed(Duration.zero);
    // TODO(het): remove this once angular_test supports waiting for deferred
    // components
    // var view = (cdRef as ViewRefImpl).appView as AppView;
    // return Future.wait(view.deferredLoads);
  }
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
