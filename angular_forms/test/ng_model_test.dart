import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/runtime/check_binding.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_model_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('NgModelTest', () {
    late NgTestFixture<NgModelTest> fixture;

    setUp(() async {
      final testBed = NgTestBed(ng.createNgModelTestFactory());
      fixture = await testBed.create();
    });

    test('should reexport control properties', () async {
      await fixture.update((cmp) {
        var model = cmp.ngModel!;
        var control = model.control;
        expect(model.value, control.value);
        expect(model.valid, control.valid);
        expect(model.errors, control.errors);
        expect(model.pristine, control.pristine);
        expect(model.dirty, control.dirty);
        expect(model.touched, control.touched);
        expect(model.untouched, control.untouched);
      });
    });

    test('should set up validator', () async {
      await fixture.update((cmp) {
        expect(cmp.ngModel!.errors, {'required': true});
        cmp.loginValue = 'someValue';
      });
      await fixture.update((cmp) {
        expect(cmp.ngModel!.errors, isNull);
      });
    });
  });

  test('throws when violating the checkBinding contract', () async {
    final testBed = NgTestBed(
      ng.createNgModelWithCheckBindingTestFactory(),
    );

    final fixture = await testBed.create();
    expect(fixture.assertOnlyInstance.value, isNull);

    expect(
      fixture.update((comp) => comp.value = 'Hello'),
      throwsA(TypeMatcher<UnstableExpressionError>()),
      reason: 'Should throw due to checkBinding',
    );
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
  NgModel? ngModel;

  String? loginValue;
}

@Component(
  selector: 'test',
  directives: [
    CustomEditorWithNgModelSupport,
    NgModel,
  ],
  template: '''
    <custom-editor-with-ng-model [(ngModel)]="value">
    </custom-editor-with-ng-model>
  ''',
)
class NgModelWithCheckBindingTest {
  String? value;
}

@Component(
  selector: 'custom-editor-with-ng-model',
  template: '',
)
class CustomEditorWithNgModelSupport implements ControlValueAccessor<String> {
  final NgControl _ngControl;
  late ChangeFunction<String> _onChange;

  CustomEditorWithNgModelSupport(this._ngControl) {
    _ngControl.valueAccessor = this;
  }

  @override
  void writeValue(String? value) {
    // Example of bad behavior. We are, synchronously, receiving a write coming
    // from ngModel.model=, and synchronously, responding back to ngModel, which
    // in turn, synchronously, talks back via StreamController(sync: true).
    if (value == 'Hello') {
      value = 'Goodbye';
      _onChange(value);
    }
  }

  @override
  void onDisabledChanged(_) {}

  @override
  void registerOnChange(ChangeFunction<String> function) {
    _onChange = function;
  }

  @override
  void registerOnTouched(_) {}
}
