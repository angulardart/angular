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

  group('NgModelWithNgDisabledTest', () {
    late NgTestFixture<NgModelWithNgDisabledTestComponent> fixture;
    late NgModelWithNgDisabledTestComponent component;

    setUp(() async {
      final testBed =
          NgTestBed(ng.createNgModelWithNgDisabledTestComponentFactory());
      fixture = await testBed.create();
      component = fixture.assertOnlyInstance;
    });

    test('disables component when ngDisabled initially true', () async {
      expect(component.editor!.isDisabled, isTrue);
    });

    test('enables component when ngDisabled changes to false', () async {
      await fixture.update((cmp) {
        cmp.isDisabled = false;
      });
      expect(component.editor!.isDisabled, isFalse);
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
  selector: 'test',
  directives: [
    CustomEditorWithNgModelSupport,
    NgModel,
  ],
  template: '''
    <custom-editor-with-ng-model
        #editor
        [(ngModel)]="value" [ngDisabled]="isDisabled">
    </custom-editor-with-ng-model>
  ''',
)
class NgModelWithNgDisabledTestComponent {
  String? value;
  bool isDisabled = true;

  @ViewChild('editor')
  CustomEditorWithNgModelSupport? editor;
}

@Component(
  selector: 'custom-editor-with-ng-model',
  template: '',
)
class CustomEditorWithNgModelSupport implements ControlValueAccessor<String> {
  final NgControl _ngControl;
  late ChangeFunction<String> _onChange;

  /// Whether or not the component is disabled.
  ///
  /// Typically, the disabled state would render differently, but for testing
  /// purposes we just set a boolean.
  bool isDisabled = false;

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
  void onDisabledChanged(isDisabled) {
    this.isDisabled = isDisabled;
  }

  @override
  void registerOnChange(ChangeFunction<String> function) {
    _onChange = function;
  }

  @override
  void registerOnTouched(_) {}
}
