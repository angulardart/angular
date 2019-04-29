@TestOn('browser')

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'b_129780288_detached_lifecycle_test.template.dart' as ng;

void main() {
  List<String> logs;

  tearDown(disposeAnyRunningTest);

  setUp(() => logs = []);

  test('ChangeDetectionStrategy.Detached should behave strangely', () async {
    final testBed = NgTestBed.forComponent<TestDetachedViaStrategy>(
      ng.TestDetachedViaStrategyNgFactory,
    );

    final fixture = await testBed.create(beforeChangeDetection: (comp) {
      comp.logs = logs;
    });

    expect(
      logs,
      [
        'ngAfterChanges',
        'ngOnInit',
        'ngAfterContentInit',
        'ngAfterViewInit',
      ],
      reason: 'Despite starting detached, all events are invoked',
    );

    expect(
      fixture.text,
      contains('Hello World'),
      reason: 'Despite starting detached, initial bindings were used',
    );

    await fixture.update((comp) {
      comp.logs = logs = [];
      comp.text = 'Hello Galaxy';
    });

    expect(
      logs,
      ['ngAfterChanges'],
      reason: 'Change detection events are still being executed',
    );

    expect(
      fixture.text,
      isNot(contains('Hello Galaxy')),
      reason: 'Change detection bindings were not updated, though',
    );

    await fixture.update((comp) {
      comp.logs = logs = [];
      // ignore: deprecated_member_use
      comp.child.reattach();
    });

    expect(
      logs,
      ['ngAfterChanges'],
      reason: 'Change detection events are executed after attach',
    );

    expect(
      fixture.text,
      contains('Hello Galaxy'),
      reason: 'Change detection bindings are updated after attach',
    );
  });

  test('ChangeDetectorRef.detach() shoud behave mostly sane', () async {
    final testBed = NgTestBed.forComponent<TestDetachedViaRef>(
      ng.TestDetachedViaRefNgFactory,
    );

    final fixture = await testBed.create(beforeChangeDetection: (comp) {
      comp.logs = logs;
    });

    expect(
      logs,
      [
        'ngAfterChanges',
        'ngOnInit',
        'ngAfterContentInit',
        'ngAfterViewInit',
      ],
      reason: 'Despite starting detached, all events are invoked',
    );

    expect(
      fixture.text,
      isNot(contains('Hello World')),
      reason: 'Initial bindings were never read',
    );

    await fixture.update((comp) {
      comp.logs = logs = [];
      comp.text = 'Hello Galaxy';
    });

    expect(
      logs,
      ['ngAfterChanges'],
      reason: 'Change detection events are still being executed',
    );

    expect(
      fixture.text,
      isNot(contains('Hello Galaxy')),
      reason: 'Updated bindings were not read',
    );

    await fixture.update((comp) {
      comp.logs = logs = [];
      // ignore: deprecated_member_use
      comp.child.reattach();
    });

    expect(
      logs,
      ['ngAfterChanges'],
      reason: 'Change detection events are executed after attach',
    );

    expect(
      fixture.text,
      contains('Hello Galaxy'),
      reason: 'Change detection bindings are updated after attach',
    );
  });
}

@Component(
  selector: 'test-1',
  directives: [
    DetachedViaStrategy,
  ],
  template: r'''
    <detached-via-strategy [logs]="logs" [text]="text">
      <button></button>
    </detached-via-strategy>
  ''',
)
class TestDetachedViaStrategy {
  List<String> logs;

  var text = 'Hello World';

  @ViewChild(DetachedViaStrategy, read: ChangeDetectorRef)
  ChangeDetectorRef child;
}

@Component(
  selector: 'test-2',
  directives: [
    DetachedViaRef,
  ],
  template: r'''
    <detached-via-ref [logs]="logs" [text]="text">
      <button></button>
    </detached-via-ref>
  ''',
)
class TestDetachedViaRef {
  List<String> logs;

  var text = 'Hello World';

  @ViewChild(DetachedViaRef, read: ChangeDetectorRef)
  ChangeDetectorRef child;
}

class Logger implements OnInit, AfterChanges, AfterViewInit, AfterContentInit {
  @Input()
  List<String> logs = [];

  @Input()
  String text;

  @override
  void ngAfterChanges() {
    logs.add('ngAfterChanges');
  }

  @override
  void ngAfterContentInit() {
    logs.add('ngAfterContentInit');
  }

  @override
  void ngAfterViewInit() {
    logs.add('ngAfterViewInit');
  }

  @override
  void ngOnInit() {
    logs.add('ngOnInit');
  }
}

@Component(
  selector: 'detached-via-strategy',
  template: r'''
    <span>{{text}}</span>
    <span>
      <ng-content></ng-content>
    </span>
  ''',
  // ignore: deprecated_member_use
  changeDetection: ChangeDetectionStrategy.Detached,
)
class DetachedViaStrategy extends Logger {}

@Component(
  selector: 'detached-via-ref',
  template: r'''
    <span>{{text}}</span>
    <span>
      <ng-content></ng-content>
    </span>
  ''',
)
class DetachedViaRef extends Logger {
  DetachedViaRef(ChangeDetectorRef changeDetectorRef) {
    // ignore: deprecated_member_use
    changeDetectorRef.detach();
  }
}
