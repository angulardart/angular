import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'memorized_form_test.template.dart' as ng;

void main() {
  ng.initReflector();

  group(MemorizedForm, () {
    tearDown(() => disposeAnyRunningTest());

    group('Controls', () {
      late NgTestFixture<TestControlComponent> fixture;
      late TestControlComponent readonlyCmp;

      void _showControls(TestControlComponent component, bool show) {
        component
          ..showInputOne = show
          ..showInputTwo = show;
      }

      setUp(() async {
        var testBed = NgTestBed(ng.createTestControlComponentFactory());
        fixture = await testBed.create();
        readonlyCmp = fixture.assertOnlyInstance;
      });

      test('Initial should have no controls', () async {
        expect(readonlyCmp.form!.form!.controls.length, 0);
        expect(readonlyCmp.form!.value, {});
      });

      test('Adding controls adds them to the form', () async {
        await fixture.update((component) {
          component.one = 'one';
          _showControls(component, true);
        });
        expect(readonlyCmp.form!.form!.controls.length, 2);
        expect(readonlyCmp.form!.value, {'one': 'one', 'two': null});
      });

      test('Adding then removing controls does not remove control', () async {
        await fixture.update((component) {
          component.one = 'one';
          _showControls(component, true);
        });
        await fixture.update((component) => _showControls(component, false));

        expect(readonlyCmp.form!.form!.controls.length, 2);
        expect(readonlyCmp.form!.value, {'one': 'one', 'two': null});
      });

      test('Readding a control preserves the value', () async {
        await fixture.update((component) => _showControls(component, true));
        await fixture.update((component) =>
            (component.form!.controls!['two'] as Control).updateValue('two'));
        await fixture.update((component) => _showControls(component, false));
        await fixture.update((component) => _showControls(component, true));
        expect(readonlyCmp.form!.form!.controls.length, 2);
        expect(readonlyCmp.form!.value, {'one': null, 'two': 'two'},
            reason: 'Should still have the same values');
      });
    });

    group('ControlGroup', () {
      late NgTestFixture<TestGroupComponent> fixture;
      late TestGroupComponent readonlyCmp;

      void _showGroups(TestGroupComponent component, bool show) {
        component
          ..showGroupOne = show
          ..showGroupTwo = show;
      }

      setUp(() async {
        var testBed = NgTestBed(ng.createTestGroupComponentFactory());
        fixture = await testBed.create();
        readonlyCmp = fixture.assertOnlyInstance;
      });

      test('Initial should have no controls', () {
        expect(readonlyCmp.form!.form!.controls.length, 0);
        expect(readonlyCmp.form!.value, {});
      });

      test('Adding control groups adds them to the form', () async {
        await fixture.update((component) {
          component.one = 'one';
          _showGroups(component, true);
        });
        expect(readonlyCmp.form!.form!.controls.length, 2);
        expect(readonlyCmp.form!.value, {
          'one': {'one': 'one'},
          'two': {'two': null}
        });
      });

      test('Adding then removing control groups does not remove control',
          () async {
        await fixture.update((component) {
          component.one = 'one';
          _showGroups(component, true);
        });
        await fixture.update((component) => _showGroups(component, false));
        expect(readonlyCmp.form!.form!.controls.length, 2);
        expect(readonlyCmp.form!.value, {
          'one': {'one': 'one'},
          'two': {'two': null}
        });
      });

      test('Readding a control group preserves the value', () async {
        await fixture.update((component) => _showGroups(component, true));
        await fixture.update((component) =>
            ((component.form!.controls!['two'] as ControlGroup).controls['two']
                    as Control)
                .updateValue('two'));
        await fixture.update((component) => _showGroups(component, false));
        await fixture.update((component) => _showGroups(component, true));

        expect(readonlyCmp.form!.form!.controls.length, 2);
        expect(
            readonlyCmp.form!.value,
            {
              'one': {'one': null},
              'two': {'two': 'two'}
            },
            reason: 'Should still have the same values');
      });
    });
  });
}

@Component(
  selector: 'test-control-component',
  directives: [MemorizedForm, formDirectives, NgIf],
  template: r'''
<div memorizedForm>
  <div *ngIf="showInputOne">One: <input ngControl="one" [ngModel]="one"></div>
  <div *ngIf="showInputTwo">Two: <input ngControl="two"></div>
</div>
''',
)
class TestControlComponent {
  String? one;
  var showInputOne = false;
  bool showInputTwo = false;

  @ViewChild(NgForm)
  NgForm? form;
}

@Component(
  selector: 'test-group-component',
  directives: [MemorizedForm, formDirectives, NgIf],
  template: r'''
<div memorizedForm>
  <div *ngIf="showGroupOne" ngControlGroup="one">One: <input ngControl="one" [ngModel]="one"></div>
  <div *ngIf="showGroupTwo" ngControlGroup="two">Two: <input ngControl="two"></div>
</div>
''',
)
class TestGroupComponent {
  String? one;
  var showGroupOne = false;
  bool showGroupTwo = false;

  @ViewChild(NgForm)
  NgForm? form;
}
