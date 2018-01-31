@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.core.linker.deferred_component_test;

import 'dart:async';
import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/core/linker/view_ref.dart';
import 'package:angular/src/debug/debug_app_view.dart';

import 'deferred_component_test.template.dart' as ng_generated;
import 'deferred_view.dart';

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should load a @deferred component', () async {
    final fixture = await new NgTestBed<SimpleContainerTest>().create();

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
    final fixture = await new NgTestBed<NestedContainerTest>().create();
    Element view = fixture.rootElement.querySelector('my-deferred-view');
    expect(view, isNull);

    await fixture.update((c) => c.show = true);
    view = fixture.rootElement.querySelector('my-deferred-view');
    expect(view, isNotNull);
  });

  test('should pass property values to an @deferred component', () async {
    final fixture = await new NgTestBed<PropertyContainerTest>().create();
    expect(fixture.text, contains('Title: Hello World'));
  });

  test('should listen to events from an @deferred component', () async {
    final fixture = await new NgTestBed<EventContainerTest>().create();
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
  directives: const [DeferredChildComponent],
  template: r'''
    <section>
      <my-deferred-view @deferred></my-deferred-view>
    </section>
  ''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class SimpleContainerTest {
  final ChangeDetectorRef cdRef;

  SimpleContainerTest(this.cdRef);

  Future waitForDeferred() async {
    // TODO(het): remove this once angular_test supports waiting for deferred
    // components
    var view = (cdRef as ViewRefImpl).appView as DebugAppView;
    return Future.wait(view.deferredLoads);
  }
}

@Component(
  selector: 'nested-container',
  directives: const [DeferredChildComponent, NgIf],
  template: r'''
    <section *ngIf="show">
      <my-deferred-view @deferred></my-deferred-view>
    </section>
  ''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NestedContainerTest {
  bool show = false;
}

@Component(
  selector: 'property-container',
  directives: const [DeferredChildComponent],
  template: r'''
    <section>
      <my-deferred-view @deferred [title]="'Hello World'"></my-deferred-view>
    </section>
  ''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class PropertyContainerTest {}

@Component(
  selector: 'event-container',
  directives: const [DeferredChildComponent],
  template: r'''
    <section>
      Events:&ngsp;{{count}}
      <my-deferred-view @deferred (selected)="onSelected()"></my-deferred-view>
    </section>
  ''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class EventContainerTest {
  int count = 0;

  void onSelected() {
    count++;
  }
}
