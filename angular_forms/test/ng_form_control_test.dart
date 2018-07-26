import 'dart:html';

@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_form_control_test.template.dart' as ng;

void main() {
  ng.initReflector();

  group('NgFormControlTest', () {
    NgTestFixture<NgFormControlTest> fixture;

    tearDown(() => disposeAnyRunningTest());

    setUp(() async {
      var testBed = NgTestBed.forComponent(ng.NgFormControlTestNgFactory);
      fixture = await testBed.create();
    });

    var checkProperties = (NgFormControl controlDir, Control control) {
      expect(controlDir.control, control);
      expect(controlDir.value, control.value);
      expect(controlDir.valid, control.valid);
      expect(controlDir.errors, control.errors);
      expect(controlDir.pristine, control.pristine);
      expect(controlDir.dirty, control.dirty);
      expect(controlDir.touched, control.touched);
      expect(controlDir.untouched, control.untouched);
    };

    test('should reexport control properties', () async {
      await fixture.update((cmp) {
        checkProperties(cmp.formControl, cmp.loginControl);
      });
    });

    test('should reexport new control properties', () async {
      var newControl = Control(null);

      await fixture.update((cmp) {
        cmp.loginControl = newControl;
      });
      await fixture.update((cmp) {
        checkProperties(cmp.formControl, newControl);
      });
    });

    test('should set up validator', () async {
      await fixture.update((cmp) {
        expect(cmp.loginControl.valid, false);
      });
    });

    test('should disable element', () async {
      expect(fixture.assertOnlyInstance.inputElement.disabled, false);
      await fixture.update((cmp) => cmp.loginControl.markAsDisabled());
      expect(fixture.assertOnlyInstance.inputElement.disabled, true);
      await fixture.update((cmp) => cmp.loginControl.markAsEnabled());
      expect(fixture.assertOnlyInstance.inputElement.disabled, false);
    });
  });
}

@Component(
  selector: 'ng-form-control-test',
  directives: [
    formDirectives,
  ],
  template: '''
<div ngForm>
  <input [ngFormControl]="loginControl" #login="ngForm" #input required />
</div>
''',
)
class NgFormControlTest {
  @ViewChild('login')
  NgFormControl formControl;

  @ViewChild('input')
  InputElement inputElement;

  Control loginControl = Control(null);
}
