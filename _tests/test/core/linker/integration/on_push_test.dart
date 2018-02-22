@TestOn('browser')

import 'dart:async';
import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/debug/debug_node.dart';

import 'on_push_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should use ChangeDetectorRef to manually request a check', () async {
    final testBed = new NgTestBed<ManualCheckComponent>();
    final testFixture = await testBed.create();
    final childCmpNoTemplate = testFixture.rootElement.firstChild;
    final cmp = getDebugNode(childCmpNoTemplate).getLocal('cmp');
    expect(cmp.numberOfChecks, 1);
    await testFixture.update();
    expect(cmp.numberOfChecks, 1);
    await testFixture.update((_) => cmp.propagate());
    expect(cmp.numberOfChecks, 2);
  });

  test('should check component when bindings update', () async {
    final testBed = new NgTestBed<PushCmpHostComponent>();
    final testFixture = await testBed.create();
    final pushCmp = testFixture.rootElement.firstChild;
    final cmp = getDebugNode(pushCmp).getLocal('cmp');
    expect(cmp.numberOfChecks, 1);
    await testFixture.update((component) => component.ctxProp = 'two');
    expect(cmp.numberOfChecks, 2);
  });

  test('should check when an event is fired', () async {
    final testBed = new NgTestBed<PushCmpHostComponent>();
    final testFixture = await testBed.create();
    final pushCmp = testFixture.rootElement.children.first;
    final cmp = getDebugNode(pushCmp).getLocal('cmp');
    expect(cmp.numberOfChecks, 1);
    // Regular element.
    await testFixture.update((_) {
      pushCmp.children[0].dispatchEvent(new MouseEvent('click'));
    });
    expect(cmp.numberOfChecks, 2);
    // Element inside an *ngIf.
    await testFixture.update((_) {
      pushCmp.children[1].dispatchEvent(new MouseEvent('click'));
    });
    expect(cmp.numberOfChecks, 3);
    // Element inside a child component.
    await testFixture.update((_) {
      pushCmp.children[2].children.first.dispatchEvent(new MouseEvent('click'));
    });
    expect(cmp.numberOfChecks, 4);
  });

  test('should not affect updating bindings', () async {
    final testBed = new NgTestBed<PushCmpWithRefHostComponent>();
    final testFixture = await testBed.create();
    final pushCmpWithRef = testFixture.rootElement.children.first;
    final cmp = getDebugNode(pushCmpWithRef).getLocal('cmp');
    expect(cmp.prop, 'one');
    await testFixture.update((component) => component.ctxProp = 'two');
    expect(cmp.prop, 'two');
  });

  test('should check when async pipe requests check', () async {
    final testBed = new NgTestBed<PushCmpWithAsyncPipeHostCmp>();
    final testFixture = await testBed.create();
    final pushCmpWithAsyncPipe = testFixture.rootElement.children.first;
    final cmp = getDebugNode(pushCmpWithAsyncPipe).getLocal('cmp');
    expect(cmp.numberOfChecks, 1);
    await testFixture.update();
    expect(cmp.numberOfChecks, 1);
    await testFixture.update((_) => cmp.resolve(12));
    expect(cmp.numberOfChecks, 2);
  });
}

@Component(
  selector: 'push-cmp-with-ref',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: '{{field}}',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class PushCmpWithRef {
  int numberOfChecks;
  ChangeDetectorRef ref;
  @Input()
  var prop;

  PushCmpWithRef(this.ref) {
    numberOfChecks = 0;
  }

  String get field {
    numberOfChecks++;
    return 'fixed';
  }

  void propagate() {
    ref.markForCheck();
  }
}

@Component(
  selector: 'manual-check',
  template: '<push-cmp-with-ref #cmp></push-cmp-with-ref>',
  directives: const [PushCmpWithRef],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ManualCheckComponent {}

@Component(
  selector: 'event-cmp',
  template: '<div (click)="noop()"></div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class EventCmp {
  void noop() {}
}

@Component(
  selector: 'push-cmp',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: '{{field}}<div (click)="noop()"></div><div *ngIf="true" '
      '(click)="noop()"></div><event-cmp></event-cmp>',
  directives: const [EventCmp, NgIf],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class PushCmp {
  int numberOfChecks;
  @Input()
  var prop;

  PushCmp() {
    numberOfChecks = 0;
  }

  void noop() {}

  String get field {
    numberOfChecks++;
    return 'fixed';
  }
}

@Component(
  selector: 'push-cmp-host',
  template: '<push-cmp [prop]="ctxProp" #cmp></push-cmp>',
  directives: const [PushCmp],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class PushCmpHostComponent {
  String ctxProp = 'one';
}

@Component(
  selector: 'push-cmp-with-ref-host',
  template: '<push-cmp-with-ref [prop]="ctxProp" #cmp></push-cmp-with-ref>',
  directives: const [PushCmpWithRef],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class PushCmpWithRefHostComponent {
  String ctxProp = 'one';
}

@Component(
  selector: 'push-cmp-with-async',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: '{{field | async}}',
  pipes: const [AsyncPipe],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class PushCmpWithAsyncPipe {
  int numberOfChecks = 0;
  Future<int> future;
  Completer<int> completer;

  PushCmpWithAsyncPipe() {
    completer = new Completer();
    future = completer.future;
  }

  get field {
    numberOfChecks++;
    return future;
  }

  void resolve(int value) {
    completer.complete(value);
  }
}

@Component(
  selector: 'push-cmp-with-async-host',
  template: '<push-cmp-with-async #cmp></push-cmp-with-async>',
  directives: const [PushCmpWithAsyncPipe],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class PushCmpWithAsyncPipeHostCmp {}
