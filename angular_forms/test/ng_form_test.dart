import 'dart:html';

@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_form_test.template.dart' as ng;

void main() {
  ng.initReflector();

  group('NgForm', () {
    NgTestFixture<NgFormTest> fixture;

    tearDown(() => disposeAnyRunningTest());

    setUp(() async {
      var testBed = NgTestBed.forComponent(ng.NgFormTestNgFactory);
      fixture = await testBed.create();
    });

    test('should reexport control properties', () async {
      await fixture.update((cmp) {
        final form = cmp.form;
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
      var formValidator = (c) => {'custom': true};
      var f = NgForm([formValidator]);
      expect(f.form.errors, {'custom': true});
    });

    test('should disable child elements', () async {
      var readonlyComponent = fixture.assertOnlyInstance;
      expect(readonlyComponent.inputElement.disabled, false);
      expect(readonlyComponent.loginControlDir.disabled, false);
      await fixture.update((cmp) => cmp.disabled = true);
      expect(readonlyComponent.inputElement.disabled, true);
      expect(readonlyComponent.loginControlDir.disabled, true);
      await fixture.update((cmp) => cmp.disabled = false);
      expect(readonlyComponent.inputElement.disabled, false);
      expect(readonlyComponent.loginControlDir.disabled, false);
    });
  });
}

@Component(
  selector: 'ng-form-test',
  directives: [
    formDirectives,
    DummyControlValueAccessor,
    NgIf,
  ],
  template: '''
<div ngForm #form="ngForm" [ngDisabled]="disabled">
  <div [ngControlGroup]="'person'" *ngIf="needsLogin">
    <input [ngControl]="'login'" #login="ngForm" required dummy />
    <input [ngControl]="'input'" #input />
  </div>
</div>
''',
)
class NgFormTest {
  @ViewChild('form')
  NgForm form;

  @ViewChild('login')
  NgControlName loginControlDir;

  @ViewChild('input')
  InputElement inputElement;

  bool disabled = false;
  bool needsLogin = true;

  ControlGroup get formModel => form.form;
}

@Directive(selector: '[dummy]', providers: [
  ExistingProvider.forToken(
    ngValueAccessor,
    DummyControlValueAccessor,
  )
])
class DummyControlValueAccessor implements ControlValueAccessor {
  var writtenValue;

  @override
  void writeValue(dynamic obj) {
    this.writtenValue = obj;
  }

  @override
  void registerOnChange(fn) {}
  @override
  void registerOnTouched(fn) {}
  @override
  void onDisabledChanged(bool isDisabled) {}
}
