@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_model_test.template.dart' as ng;

void main() {
  ng.initReflector();

  group('NgModelTest', () {
    NgTestFixture<NgModelTest> fixture;

    tearDown(() => disposeAnyRunningTest());

    setUp(() async {
      var testBed = NgTestBed.forComponent(ng.NgModelTestNgFactory);
      fixture = await testBed.create();
    });

    test('should reexport control properties', () async {
      await fixture.update((cmp) {
        var control = cmp.ngModel.control;
        expect(cmp.ngModel.value, control.value);
        expect(cmp.ngModel.valid, control.valid);
        expect(cmp.ngModel.errors, control.errors);
        expect(cmp.ngModel.pristine, control.pristine);
        expect(cmp.ngModel.dirty, control.dirty);
        expect(cmp.ngModel.touched, control.touched);
        expect(cmp.ngModel.untouched, control.untouched);
      });
    });
    test('should set up validator', () async {
      await fixture.update((cmp) {
        expect(cmp.ngModel.errors, {'required': true});
        cmp.loginValue = 'someValue';
      });
      await fixture.update((cmp) {
        expect(cmp.ngModel.errors, isNull);
      });
    });
  });
}

@Component(
  selector: 'ng-model-test',
  directives: [
    formDirectives,
  ],
  template: '''
<div ngForm>
  <input [(ngModel)]="loginValue" #login="ngForm" required />
</div>
''',
)
class NgModelTest {
  @ViewChild('login')
  NgModel ngModel;

  String loginValue;
}
