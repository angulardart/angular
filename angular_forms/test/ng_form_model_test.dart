@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_form_model_test.template.dart' as ng;

Matcher throwsWith(String s) =>
    throwsA(predicate((e) => e.toString().contains(s)));

void main() {
  ng.initReflector();

  group('NgFormModel', () {
    final defaultAccessor = DefaultValueAccessor(document.createElement('div'));
    NgTestFixture<NgFormModelTest> fixture;

    tearDown(() => disposeAnyRunningTest());

    setUp(() async {
      var testBed = NgTestBed.forComponent(ng.NgFormModelTestNgFactory);
      fixture = await testBed.create();
    });

    test('should reexport control properties', () {
      fixture.update((cmp) {
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

    group('addControl', () {
      test('should throw when no control found', () async {
        await fixture.update((cmp) {
          var dir = NgControlName(cmp.form, null, [defaultAccessor]);
          dir.name = 'invalidName';
          expect(() => cmp.form.addControl(dir),
              throwsWith('Cannot find control (invalidName)'));
        });
      });

      test('should throw when no value accessor', () async {
        await fixture.update((cmp) {
          var dir = NgControlName(cmp.form, null, null);
          dir.name = 'login';
          expect(() => cmp.form.addControl(dir),
              throwsWith('No value accessor for (login)'));
        });
      });

      test('should set up validators', () async {
        await fixture.update((cmp) {
          // sync validators are set
          expect(cmp.formModel.hasError('required', ['login']), true);
          (cmp.formModel.findPath(['login']) as Control)
              .updateValue('invalid value');
        });
      });

      test('should write value to the DOM', () async {
        await fixture.update((cmp) {
          (cmp.formModel.findPath(['login']) as Control)
              .updateValue('initValue');
          expect(
              (cmp.loginControlDir.valueAccessor as DummyControlValueAccessor)
                  .writtenValue,
              'initValue');
        });
      });

      test(
          'should add the directive to the list of directives '
          'included in the form', () async {
        await fixture.update((cmp) {
          expect(cmp.form.directives, [cmp.loginControlDir]);
        });
      });
    });

    group('addControlGroup', () {
      test('should set up validator', () async {
        await fixture.update((cmp) {
          (cmp.formModel.findPath(['passwords', 'password']) as Control)
              .updateValue('somePassword');
          (cmp.formModel.findPath(['passwords', 'passwordConfirm']) as Control)
              .updateValue('someOtherPassword');
        });

        await fixture.update((cmp) {
          // sync validators are set
          expect(cmp.formModel.hasError('differentPasswords', ['passwords']),
              true);

          (cmp.formModel.findPath(['passwords', 'passwordConfirm']) as Control)
              .updateValue('somePassword');

          expect(cmp.formModel.hasError('differentPasswords', ['passwords']),
              false);
        });
      });
    });

    group('removeControl', () {
      test(
          'should remove the directive to the list of directives included in '
          'the form', () async {
        await fixture.update((cmp) {
          cmp.needsLogin = false;
        });

        await fixture.update((cmp) {
          expect(cmp.form.directives, []);
        });
      });
    });

    group('ngAfterChanges', () {
      test('should update dom values of all the directives', () async {
        await fixture.update((cmp) {
          (cmp.formModel.findPath(['login']) as Control)
              .updateValue('new value');
        });
        await fixture.update((cmp) {
          expect(
              (cmp.loginControlDir.valueAccessor as DummyControlValueAccessor)
                  .writtenValue,
              'new value');
        });
      });

      test('should validate form is not null', () async {
        expect(
            () async => await fixture.update((cmp) {
                  cmp.formModel = null;
                }),
            throwsA(TypeMatcher<StateError>()));
      });
    });
  });
}

@Component(
  selector: 'ng-form-model-test',
  directives: [
    formDirectives,
    DummyControlValueAccessor,
    MatchingPasswordsValidator,
    NgIf,
  ],
  template: '''
<div [ngFormModel]="formModel" #form="ngForm">
  <div *ngIf="needsLogin">
    <input [ngControl]="'login'" #login="ngForm" required dummy />
  </div>
  <div [ngControlGroup]="'passwords'" #passwords="ngForm" matchingPasswords>
  </div>
</div>
''',
)
class NgFormModelTest {
  @ViewChild('form')
  NgFormModel form;

  @ViewChild('login')
  NgControlName loginControlDir;

  @ViewChild('passwords')
  NgControlGroup passwords;

  bool needsLogin = true;

  var formModel = ControlGroup({
    'login': Control(),
    'passwords':
        ControlGroup({'password': Control(), 'passwordConfirm': Control()})
  });
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

@Directive(selector: '[matchingPasswords]', providers: [
  ValueProvider.forToken(
      NG_VALIDATORS, MatchingPasswordsValidator.matchingPasswordsValidator),
])
class MatchingPasswordsValidator {
  static Map<String, dynamic> matchingPasswordsValidator(
      AbstractControl control) {
    if (control is! ControlGroup) throw StateError('Must be ControlGroup');
    var group = control as ControlGroup;
    if (group.controls['password'].value !=
        group.controls['passwordConfirm'].value) {
      return {'differentPasswords': true};
    } else {
      return null;
    }
  }
}
