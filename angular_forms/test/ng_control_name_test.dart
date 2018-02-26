@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_control_name_test.template.dart' as ng;

void main() {
  ng.initReflector();

  group('NgControlNameTest', () {
    NgTestFixture<NgControlNameTest> fixture;

    tearDown(() => disposeAnyRunningTest());

    setUp(() async {
      var testBed = NgTestBed.forComponent(ng.NgControlNameTestNgFactory);
      fixture = await testBed.create();
    });

    test('should reexport control properties', () async {
      await fixture.update((cmp) {
        expect(cmp.controlName.control, cmp.controlModel);
        expect(cmp.controlName.value, cmp.controlModel.value);
        expect(cmp.controlName.valid, cmp.controlModel.valid);
        expect(cmp.controlName.errors, cmp.controlModel.errors);
        expect(cmp.controlName.pristine, cmp.controlModel.pristine);
        expect(cmp.controlName.dirty, cmp.controlModel.dirty);
        expect(cmp.controlName.touched, cmp.controlModel.touched);
        expect(cmp.controlName.untouched, cmp.controlModel.untouched);
      });
    });
  });
}

@Component(
  selector: 'ng-control-name-test',
  directives: [
    formDirectives,
  ],
  template: '''
<div [ngFormModel]="formModel">
  <input [ngControl]="'login'" [(ngModel)]="loginValue" #login="ngForm" required />
</div>
''',
)
class NgControlNameTest {
  @ViewChild('login')
  NgControlName controlName;

  String loginValue;

  ControlGroup formModel = new ControlGroup({'login': new Control('login')});

  Control get controlModel => formModel.controls['login'];
}
