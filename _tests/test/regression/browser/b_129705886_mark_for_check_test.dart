@TestOn('browser')

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'b_129705886_mark_for_check_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should detect changes via @Input', () async {
    final testBed = NgTestBed.forComponent<UsesOnPushComponent>(
      ng.UsesOnPushComponentNgFactory,
    );

    final fixture = await testBed.create(beforeChangeDetection: (comp) {
      comp.ticks = 1;
    });
    expect(fixture.text, 'Ticks: 1');

    await fixture.update((comp) => comp.ticks++);
    expect(fixture.text, 'Ticks: 2');
  });

  // b/129705886:
  //
  // It's possible to get into callbacks (ngAfter{View|Content}{Init|Checked})
  // or potentially other asynchronous contexts not observed by Dart's zones
  // (i.e. JS-interop) where changing your state and calling "markForCheck"
  // effectively does nothing until you click/scroll/do something that triggers
  // a zone turn.
  test('ignores changes when markForCheck is invoked imperatively', () async {
    final testBed = NgTestBed.forComponent<UsesOnPushComponent>(
      ng.UsesOnPushComponentNgFactory,
    );

    final fixture = await testBed.create();
    expect(fixture.text, 'Ticks: 0');

    // Roughly emulates:
    // 1. A function call that escaped the zone.
    // 2. Waiting for an amount of time that should stabilize.
    // 3. The DOM not reflecting the model until a zone turn occurs.
    fixture.assertOnlyInstance.child.onExternalEvent();

    // Intentional: We do not want to force Angular to update, we want to
    // simulate time passing and natural stabilization (which is what an
    // end-user app would do).
    await Future.delayed(Duration.zero);

    expect(fixture.text, 'Ticks: 0', reason: 'No change detection run');
    expect(fixture.assertOnlyInstance.child.ticks, 1);

    // In practice this is often ".detectChanges()" to "fix" this bug.
    await fixture.update();
    expect(fixture.text, 'Ticks: 1');
  });
}

@Component(
  selector: 'uses-on-push',
  template: '<on-push [ticks]="ticks"></on-push>',
  directives: [OnPushComponent],
)
class UsesOnPushComponent {
  var ticks = 0;

  @ViewChild(OnPushComponent)
  OnPushComponent child;
}

@Component(
  selector: 'on-push',
  template: r'''
    <button>Ticks: {{ticks}}</button>
  ''',
  directives: [
    NgIf,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class OnPushComponent {
  final ChangeDetectorRef _changeDetector;

  OnPushComponent(this._changeDetector);

  @Input()
  var ticks = 0;

  // JS-interop, some function that escapes NgZone, certain lifecycle events.
  void onExternalEvent() {
    ticks++;
    _changeDetector.markForCheck();
  }
}
