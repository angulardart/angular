import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_control_name_test.template.dart' as ng;

void main() {
  ng.initReflector();

  group('NgControlNameTest', () {
    late NgTestFixture<NgControlNameTest> fixture;

    tearDown(() => disposeAnyRunningTest());

    setUp(() async {
      var testBed = NgTestBed(ng.createNgControlNameTestFactory());
      fixture = await testBed.create();
    });

    test('should reexport control properties', () async {
      await fixture.update((cmp) {
        var controlName = cmp.controlName!;
        expect(controlName.control, cmp.controlModel);
        expect(controlName.value, cmp.controlModel.value);
        expect(controlName.valid, cmp.controlModel.valid);
        expect(controlName.errors, cmp.controlModel.errors);
        expect(controlName.pristine, cmp.controlModel.pristine);
        expect(controlName.dirty, cmp.controlModel.dirty);
        expect(controlName.touched, cmp.controlModel.touched);
        expect(controlName.untouched, cmp.controlModel.untouched);
      });
    });

    test('should disabled element', () async {
      expect(fixture.assertOnlyInstance.inputElement!.disabled, false);
      await fixture.update((cmp) => cmp.disabled = true);
      expect(fixture.assertOnlyInstance.inputElement!.disabled, true);
      await fixture.update((cmp) => cmp.disabled = false);
      expect(fixture.assertOnlyInstance.inputElement!.disabled, false);
    });

    test('should reset element', () async {
      await fixture.update((cmp) => cmp.loginValue = 'new value');
      expect(fixture.assertOnlyInstance.inputElement!.value, 'new value');
      await fixture.update((cmp) => cmp.controlName!.reset());
      expect(fixture.assertOnlyInstance.inputElement!.value, '');
    });
  });

  group('NgControl initialization test', () {
    late NgTestFixture<NgControlNameInitTest> fixture;

    tearDown(() => disposeAnyRunningTest());

    setUp(() async {
      var testBed = NgTestBed(ng.createNgControlNameInitTestFactory());
      fixture = await testBed.create();
    });

    test('should initialize with value and not null', () async {
      // Should not throw on initialization with a null value.
      await fixture.update((cmp) {
        expect(cmp.controlName!.value, 'Test');
        expect(cmp.accessor!.value, 'Test');
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
  <input [ngControl]="'login'"
      [(ngModel)]="loginValue"
      #login="ngForm"
      #input
      required
      [ngDisabled]="disabled" />
</div>
''',
)
class NgControlNameTest {
  @ViewChild('login')
  NgControlName? controlName;

  @ViewChild('input')
  InputElement? inputElement;

  String? loginValue;

  ControlGroup formModel = ControlGroup({'login': Control('login')});

  bool disabled = false;

  Control get controlModel => formModel.controls['login'] as Control;
}

@Component(
  selector: 'ng-control-name-accessor-test',
  directives: [
    formDirectives,
    TestAccessor,
  ],
  template: '''
<form>
  <input [ngControl]="'login'" [ngModel]="'Test'" test-accessor />
</form>
''',
)
class NgControlNameInitTest {
  @ViewChild(NgControlName)
  NgControlName? controlName;

  @ViewChild(TestAccessor)
  TestAccessor? accessor;
}

@Directive(
  selector: '[test-accessor]',
  providers: [
    ExistingProvider.forToken(
      ngValueAccessor,
      TestAccessor,
    )
  ],
)
class TestAccessor implements ControlValueAccessor<dynamic> {
  dynamic value;
  @override
  void writeValue(value) {
    if (value == null) {
      fail('Should not initialize value as null. When model has a value.');
    }
    this.value = value;
  }

  @override
  void onDisabledChanged(bool isDisabled) {}

  @override
  void registerOnChange(ChangeFunction<dynamic> f) {}

  @override
  void registerOnTouched(TouchFunction f) {}
}
