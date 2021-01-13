import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_form_test.template.dart' as ng;

void main() {
  group('NgForm', () {
    late NgTestFixture<NgFormTest> fixture;

    tearDown(() => disposeAnyRunningTest());

    setUp(() async {
      var testBed = NgTestBed(ng.createNgFormTestFactory());
      fixture = await testBed.create();
    });

    test('should reexport control properties', () async {
      await fixture.update((cmp) {
        final form = cmp.form!;
        final formModel = cmp.formModel;
        expect(form.control, formModel);
        expect(form.value, formModel.value);
        expect(form.valid, formModel.valid);
        expect(form.errors, formModel.errors);
        expect(form.pristine, formModel.pristine);
        expect(form.dirty, formModel.dirty);
        expect(form.touched, formModel.touched);
        expect(form.untouched, formModel.untouched);
      });
    });

    group('addControl & addControlGroup', () {
      test('should create a control with the given name', () async {
        await fixture.update((cmp) {
          expect(cmp.formModel.findPath(['person', 'login']), isNotNull);
        });
      });
    });

    group('removeControl & removeControlGroup', () {
      test('should remove control', () async {
        await fixture.update((cmp) {
          cmp.needsLogin = false;
        });
        await fixture.update((cmp) {
          expect(cmp.formModel.findPath(['person']), isNull);
          expect(cmp.formModel.findPath(['person', 'login']), isNull);
        });
      });
    });

    test('should set up sync validator', () {
      Map<String, dynamic> formValidator(_) => {'custom': true};
      var f = NgForm(
        [formValidator],
        fixture.assertOnlyInstance.changeDetectorRef,
      );
      expect(f.form!.errors, {'custom': true});
    });

    test('should disable child elements', () async {
      var readonlyComponent = fixture.assertOnlyInstance;
      expect(readonlyComponent.inputElement!.disabled, false);
      expect(readonlyComponent.loginControlDir!.disabled, false);
      await fixture.update((cmp) => cmp.disabled = true);
      expect(readonlyComponent.inputElement!.disabled, true);
      expect(readonlyComponent.loginControlDir!.disabled, true);
      await fixture.update((cmp) => cmp.disabled = false);
      expect(readonlyComponent.inputElement!.disabled, false);
      expect(readonlyComponent.loginControlDir!.disabled, false);
    });
  });

  group('OnPush observed form status', () {
    group('with Control', () {
      late NgTestFixture<OnPushControlTest> fixture;

      tearDown(() => disposeAnyRunningTest());

      setUp(() async {
        var testBed = NgTestBed(ng.createOnPushControlTestFactory());
        fixture = await testBed.create();
      });

      test('should be valid before adding required control', () {
        expect(fixture.assertOnlyInstance.submitButton!.disabled, isFalse);
      });

      test('should be invalid after adding required control', () async {
        await fixture.update((component) {
          component.requiresName = true;
        });
        expect(fixture.assertOnlyInstance.submitButton!.disabled, isTrue);
      });

      test('should be valid after removing required control', () async {
        await fixture.update((component) {
          component.requiresName = true;
        });
        await fixture.update((component) {
          component.requiresName = false;
        });
        expect(fixture.assertOnlyInstance.submitButton!.disabled, isFalse);
      });
    });

    group('with ControlGroup', () {
      late NgTestFixture<OnPushControlGroupTest> fixture;

      tearDown(() => disposeAnyRunningTest());

      setUp(() async {
        var testBed = NgTestBed(ng.createOnPushControlGroupTestFactory());
        fixture = await testBed.create();
      });

      test('should be valid before adding required control group', () {
        expect(fixture.assertOnlyInstance.submitButton!.disabled, isFalse);
      });

      test('should be invalid after adding required control group', () async {
        await fixture.update((component) {
          component.requiresGroup = true;
        });
        expect(fixture.assertOnlyInstance.submitButton!.disabled, isTrue);
      });

      test('should be valid after removing required control group', () async {
        await fixture.update((component) {
          component.requiresGroup = true;
        });
        await fixture.update((component) {
          component.requiresGroup = false;
        });
        expect(fixture.assertOnlyInstance.submitButton!.disabled, isFalse);
      });
    });
  });
}

@Component(
  selector: 'ng-form-test',
  directives: [
    formDirectives,
    NgIf,
  ],
  template: '''
<div ngForm #form="ngForm" [ngDisabled]="disabled">
  <div [ngControlGroup]="'person'" *ngIf="needsLogin">
    <input [ngControl]="'login'" #login="ngForm" required />
    <input [ngControl]="'input'" #input />
  </div>
</div>
''',
)
class NgFormTest {
  NgFormTest(this.changeDetectorRef);

  final ChangeDetectorRef changeDetectorRef;

  @ViewChild('form')
  NgForm? form;

  @ViewChild('login')
  NgControlName? loginControlDir;

  @ViewChild('input')
  InputElement? inputElement;

  bool disabled = false;
  bool needsLogin = true;

  ControlGroup get formModel => form!.form!;
}

@Component(
  selector: 'test',
  directives: [
    formDirectives,
    NgIf,
  ],
  template: '''
    <form #form="ngForm">
      <input *ngIf="requiresName" ngControl="name" required />
      <button #submit [disabled]="!form.valid!">
        Submit
      </button>
    </form>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class OnPushControlTest {
  var requiresName = false;

  @ViewChild('submit')
  ButtonElement? submitButton;
}

@Component(
  selector: 'test',
  directives: [
    formDirectives,
    NgIf,
  ],
  template: '''
    <form #form="ngForm">
      <div *ngIf="requiresGroup" ngControlGroup="info">
        <input ngControl="name" required />
      </div>
      <button #submit [disabled]="!form.valid!">
        Submit
      </button>
    </form>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class OnPushControlGroupTest {
  var requiresGroup = false;

  @ViewChild('submit')
  ButtonElement? submitButton;
}
