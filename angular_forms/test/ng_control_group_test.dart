import 'dart:html';

@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_control_group_test.template.dart' as ng;

void main() {
  ng.initReflector();

  group('NgControlGroup', () {
    NgTestFixture<NgControlGroupTest> fixture;

    tearDown(() => disposeAnyRunningTest());

    setUp(() async {
      var testBed = NgTestBed.forComponent(ng.NgControlGroupTestNgFactory);
      fixture = await testBed.create();
    });

    test('should reexport control properties', () async {
      await fixture.update((cmp) {
        expect(cmp.controlGroup.control, cmp.groupModel);
        expect(cmp.controlGroup.value, cmp.groupModel.value);
        expect(cmp.controlGroup.valid, cmp.groupModel.valid);
        expect(cmp.controlGroup.errors, cmp.groupModel.errors);
        expect(cmp.controlGroup.pristine, cmp.groupModel.pristine);
        expect(cmp.controlGroup.dirty, cmp.groupModel.dirty);
        expect(cmp.controlGroup.touched, cmp.groupModel.touched);
        expect(cmp.controlGroup.untouched, cmp.groupModel.untouched);
      });
    });

    test('should disable child controls', () async {
      await fixture.update((cmp) {
        cmp.disabled = true;
      });
      expect(fixture.assertOnlyInstance.inputElement.disabled, true);
      await fixture.update((cmp) {
        cmp.disabled = false;
      });
      expect(fixture.assertOnlyInstance.inputElement.disabled, false);
    });
  });
}

@Component(
  selector: 'ng-control-group-test',
  directives: [
    formDirectives,
    NgIf,
  ],
  template: '''
<div [ngFormModel]="formModel">
  <div [ngControlGroup]="'group'" #controlGroup="ngForm" [ngDisabled]="disabled">
    <input [ngControl]="'login'" #input />
  </div>
</div>
''',
)
class NgControlGroupTest {
  @ViewChild('controlGroup')
  NgControlGroup controlGroup;

  @ViewChild('input')
  InputElement inputElement;

  bool disabled = false;

  ControlGroup formModel = FormBuilder.controlGroup({
    'group': FormBuilder.controlGroup({'login': Control(null)})
  });

  ControlGroup get groupModel => formModel.controls['group'];
}
