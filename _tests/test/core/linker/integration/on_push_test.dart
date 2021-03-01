import 'dart:async';
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'on_push_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('should use ChangeDetectorRef to manually request a check', () {
    test('from a component declared in the template', () async {
      final testBed = NgTestBed(ng.createManualCheckComponentFactory());
      final testFixture = await testBed.create();
      final cmp = testFixture.assertOnlyInstance.child!;
      expect(cmp.numberOfChecks, 1);
      await testFixture.update();
      expect(cmp.numberOfChecks, 1);
      await testFixture.update((_) => cmp.propagate());
      expect(cmp.numberOfChecks, 2);
    });

    test('from an imperatively loaded component', () async {
      final testBed = NgTestBed(ng.createManualCheckLoadedComponentFactory());
      late final PushCmpWithRef cmp;
      final testFixture = await testBed.create(
        beforeChangeDetection: (component) {
          cmp = component.loadComponent();
        },
      );
      expect(cmp.numberOfChecks, 1);
      await testFixture.update();
      expect(cmp.numberOfChecks, 1);
      await testFixture.update((_) => cmp.propagate());
      expect(cmp.numberOfChecks, 2);
    });
  });

  test('should check component when bindings update', () async {
    final testBed = NgTestBed(ng.createPushCmpHostComponentFactory());
    final testFixture = await testBed.create();
    final cmp = testFixture.assertOnlyInstance.child!;
    expect(cmp.numberOfChecks, 1);
    await testFixture.update((component) => component.ctxProp = 'two');
    expect(cmp.numberOfChecks, 2);
  });

  test('should check when an event is fired', () async {
    final testBed = NgTestBed(ng.createPushCmpHostComponentFactory());
    final testFixture = await testBed.create();
    final cmp = testFixture.assertOnlyInstance.child!;
    final cmpElement = testFixture.rootElement.children.first;
    expect(cmp.numberOfChecks, 1);
    // Regular element.
    await testFixture.update((_) {
      cmpElement.children[0].dispatchEvent(MouseEvent('click'));
    });
    expect(cmp.numberOfChecks, 2);
    // Element inside an *ngIf.
    await testFixture.update((_) {
      cmpElement.children[1].dispatchEvent(MouseEvent('click'));
    });
    expect(cmp.numberOfChecks, 3);
    // Element inside a child component.
    await testFixture.update((_) {
      cmpElement.children[2].children[0].dispatchEvent(MouseEvent('click'));
    });
    expect(cmp.numberOfChecks, 4);
  });

  test('should not affect updating bindings', () async {
    final testBed = NgTestBed(ng.createPushCmpWithRefHostComponentFactory());
    final testFixture = await testBed.create();
    final cmp = testFixture.assertOnlyInstance.child!;
    expect(cmp.prop, 'one');
    await testFixture.update((component) => component.ctxProp = 'two');
    expect(cmp.prop, 'two');
  });

  test('should check when async pipe requests check', () async {
    final testBed = NgTestBed(ng.createPushCmpWithAsyncPipeHostCmpFactory());
    final testFixture = await testBed.create();
    final cmp = testFixture.assertOnlyInstance.child!;
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
)
class PushCmpWithRef {
  var numberOfChecks = 0;

  final ChangeDetectorRef ref;

  @Input()
  String? prop;

  PushCmpWithRef(this.ref);

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
  directives: [PushCmpWithRef],
)
class ManualCheckComponent {
  @ViewChild('cmp')
  PushCmpWithRef? child;
}

@Component(
  selector: 'test',
  template: '<template #container></template>',
)
class ManualCheckLoadedComponent {
  @ViewChild('container', read: ViewContainerRef)
  ViewContainerRef? componentLoader;

  PushCmpWithRef loadComponent() {
    return componentLoader!
        .createComponent(ng.createPushCmpWithRefFactory())
        .instance;
  }
}

@Component(
  selector: 'event-cmp',
  template: '<div (click)="noop()"></div>',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class EventCmp {
  void noop() {}
}

@Component(
  selector: 'push-cmp',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: '{{field}}<div (click)="noop()"></div><div *ngIf="true" '
      '(click)="noop()"></div><event-cmp></event-cmp>',
  directives: [EventCmp, NgIf],
)
class PushCmp {
  int numberOfChecks = 0;

  @Input()
  String? prop;

  void noop() {}

  String get field {
    numberOfChecks++;
    return 'fixed';
  }
}

@Component(
  selector: 'push-cmp-host',
  template: '<push-cmp [prop]="ctxProp" #cmp></push-cmp>',
  directives: [PushCmp],
)
class PushCmpHostComponent {
  String ctxProp = 'one';

  @ViewChild('cmp')
  PushCmp? child;
}

@Component(
  selector: 'push-cmp-with-ref-host',
  template: '<push-cmp-with-ref [prop]="ctxProp" #cmp></push-cmp-with-ref>',
  directives: [PushCmpWithRef],
)
class PushCmpWithRefHostComponent {
  String ctxProp = 'one';

  @ViewChild('cmp')
  PushCmpWithRef? child;
}

@Component(
  selector: 'push-cmp-with-async',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: r'{{$pipe.async(field)}}',
  pipes: [AsyncPipe],
)
class PushCmpWithAsyncPipe {
  int numberOfChecks = 0;
  late final Future<int> future;
  late final Completer<int> completer;

  PushCmpWithAsyncPipe() {
    completer = Completer();
    future = completer.future;
  }

  Future<int> get field {
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
  directives: [PushCmpWithAsyncPipe],
)
class PushCmpWithAsyncPipeHostCmp {
  @ViewChild('cmp')
  PushCmpWithAsyncPipe? child;
}
