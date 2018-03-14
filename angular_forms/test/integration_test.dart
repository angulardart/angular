@TestOn('browser')
import 'dart:async';
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'integration_test.template.dart' as ng_generated;

void dispatchEvent(Element element, String eventType) {
  element.dispatchEvent(new Event(eventType, canBubble: true));
}

void main() {
  ng_generated.initReflector();

  group('ngForm', () {
    tearDown(() => disposeAnyRunningTest());

    test('should initialze DOM elements with the given form object', () async {
      var testBed = new NgTestBed<InputFormTest>();
      var fixture = await testBed.create(
          beforeChangeDetection: (InputFormTest component) {
        component.form = new ControlGroup({'login': new Control('loginValue')});
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.value, 'loginValue');
    });
    test('should throw if a form is not passed into ngFormModel', () async {
      var testBed = new NgTestBed<InputFormTest>();
      var fixture = await testBed.create(
          beforeChangeDetection: (InputFormTest component) {
        component.form = new ControlGroup({'login': new Control('loginValue')});
      });
      var update = fixture.update((InputFormTest component) {
        component.form = null;
      });
      expect(
          update,
          throwsInAngular(allOf(
              new isInstanceOf<Error>(),
              predicate((e) => e.message.contains(
                  'ngFormModel expects a form. Please pass one in.')))));
    });
    test('should update the control group values on DOM change', () async {
      var testBed = new NgTestBed<InputFormTest>();
      var form = new ControlGroup({'login': new Control('oldValue')});
      var fixture = await testBed.create(
          beforeChangeDetection: (InputFormTest component) {
        component.form = form;
      });
      await fixture.update((_) {
        var input = fixture.rootElement.querySelector('input') as InputElement;
        input.value = 'updatedValue';
        dispatchEvent(input, 'input');
      });
      expect(form.value, {'login': 'updatedValue'});
    });
    test('should ignore the change event for <input type=text>', () async {
      var testBed = new NgTestBed<InputFormTest>();
      var form = new ControlGroup({'login': new Control('oldValue')});
      var fixture = await testBed.create(
          beforeChangeDetection: (InputFormTest component) {
        component.form = form;
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      form.valueChanges.listen((_) {
        throw new UnsupportedError('should not happen');
      });
      await fixture.update((_) {
        input.value = 'updatedValue';
        dispatchEvent(input, 'change');
      });
    });
    test('should emit ngSubmit event on submit', () async {
      var testBed = new NgTestBed<SubmitFormTest>();
      var fixture = await testBed.create(
          beforeChangeDetection: (SubmitFormTest component) {
        component.form = new ControlGroup({});
        component.name = 'old';
      });
      expect(fixture.text.trim(), 'old');
      var form = fixture.rootElement.querySelector('form');
      await fixture.update((_) {
        dispatchEvent(form, 'submit');
      });
      expect(fixture.text.trim(), 'updated');
    });
    test('should work with single controls', () async {
      var testBed = new NgTestBed<SingleControlTest>();
      var control = new Control('loginValue');
      var fixture = await testBed.create(
          beforeChangeDetection: (SingleControlTest component) {
        component.form = control;
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.value, 'loginValue');
      await fixture.update((_) {
        input.value = 'updatedValue';
        dispatchEvent(input, 'input');
      });
      expect(control.value, 'updatedValue');
    });
    test('should update DOM elements when rebinding the control group',
        () async {
      var testBed = new NgTestBed<InputFormTest>();
      var fixture = await testBed.create(
          beforeChangeDetection: (InputFormTest component) {
        component.form = new ControlGroup({'login': new Control('oldValue')});
      });
      await fixture.update((InputFormTest component) {
        component.form = new ControlGroup({'login': new Control('newValue')});
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.value, 'newValue');
    });
    test('should update DOM elements when updating the value of a control',
        () async {
      var testBed = new NgTestBed<InputFormTest>();
      var login = new Control('oldValue');
      var form = new ControlGroup({'login': login});
      var fixture = await testBed.create(
          beforeChangeDetection: (InputFormTest component) {
        component.form = form;
      });
      await fixture.update((_) {
        login.updateValue('newValue');
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.value, 'newValue');
    });
    test(
        'should mark controls as touched after '
        'interacting with the DOM control', () async {
      var testBed = new NgTestBed<InputFormTest>();
      var login = new Control('oldValue');
      var form = new ControlGroup({'login': login});
      var fixture = await testBed.create(
          beforeChangeDetection: (InputFormTest component) {
        component.form = form;
      });
      expect(login.touched, false);
      await fixture.update((_) {
        var input = fixture.rootElement.querySelector('input');
        dispatchEvent(input, 'blur');
      });
      expect(login.touched, true);
    });
    test('should support <input type=text>', () async {
      var testBed = new NgTestBed<InputFormTest>();
      var form = new ControlGroup({'login': new Control('old')});
      var fixture = await testBed.create(
          beforeChangeDetection: (InputFormTest component) {
        component.form = form;
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.value, 'old');
      await fixture.update((InputFormTest component) {
        input.value = 'new';
        dispatchEvent(input, 'input');
      });
      expect(form.value, equals({'login': 'new'}));
    });
    test('should support <input> without type', () async {
      var testBed = new NgTestBed<InputWithoutTypeTest>();
      var form = new ControlGroup({'text': new Control('old')});
      var fixture = await testBed.create(
          beforeChangeDetection: (InputWithoutTypeTest component) {
        component.form = form;
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.value, 'old');
      await fixture.update((InputWithoutTypeTest component) {
        input.value = 'new';
        dispatchEvent(input, 'input');
      });
      expect(form.value, equals({'text': 'new'}));
    });
    test('should support <textarea>', () async {
      var testBed = new NgTestBed<TextAreaTest>();
      var form = new ControlGroup({'text': new Control('old')});
      var fixture =
          await testBed.create(beforeChangeDetection: (TextAreaTest component) {
        component.form = form;
      });
      var textarea =
          fixture.rootElement.querySelector('textarea') as TextAreaElement;
      expect(textarea.value, 'old');
      await fixture.update((_) {
        textarea.value = 'new';
        dispatchEvent(textarea, 'input');
      });
      expect(form.value, equals({'text': 'new'}));
    });
    test('should support <type=checkbox>', () async {
      var testBed = new NgTestBed<CheckboxTest>();
      var form = new ControlGroup({'checkbox': new Control(true)});
      var fixture =
          await testBed.create(beforeChangeDetection: (CheckboxTest component) {
        component.form = form;
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.checked, true);
      await fixture.update((_) {
        input.checked = false;
        dispatchEvent(input, 'change');
      });
      expect(form.value, equals({'checkbox': false}));
    });
    test('should support <type=number>', () async {
      var testBed = new NgTestBed<NumberTest>();
      var form = new ControlGroup({'num': new Control(10)});
      var fixture =
          await testBed.create(beforeChangeDetection: (NumberTest component) {
        component.form = form;
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.value, '10');
      await fixture.update((_) {
        input.value = '20';
        dispatchEvent(input, 'input');
      });
      expect(form.value, equals({'num': 20}));
    });
    test('should support <type=number> when value is cleared in the UI',
        () async {
      var testBed = new NgTestBed<NumberRequiredTest>();
      var form = new ControlGroup({'num': new Control(10)});
      var fixture = await testBed.create(
          beforeChangeDetection: (NumberRequiredTest component) {
        component.form = form;
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      await fixture.update((_) {
        input.value = '';
        dispatchEvent(input, 'input');
      });
      expect(form.valid, false);
      expect(form.value, equals({'num': null}));
      await fixture.update((_) {
        input.value = '0';
        dispatchEvent(input, 'input');
      });
      expect(form.valid, true);
      expect(form.value, equals({'num': 0}));
    });
    test('should support <type=number> when value is cleared programmatically',
        () async {
      var testBed = new NgTestBed<NumberModelTest>();
      var form = new ControlGroup({'num': new Control(10)});
      var fixture = await testBed.create(
          beforeChangeDetection: (NumberModelTest component) {
        component.form = form;
        component.data = '';
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.value, '');
    });
    test('should support <type=radio>', () async {
      var testBed = new NgTestBed<RadioTest>();
      var form = new ControlGroup({
        'foodChicken': new Control(new RadioButtonState(false, 'chicken')),
        'foodFish': new Control(new RadioButtonState(true, 'fish'))
      });
      var fixture =
          await testBed.create(beforeChangeDetection: (RadioTest component) {
        component.form = form;
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.checked, false);
      await fixture.update((_) {
        dispatchEvent(input, 'change');
      });
      var value = form.value;
      expect(value['foodChicken'].checked, true);
      expect(value['foodFish'].checked, false);
    });

    group('should support select', () {
      test('with basic selection', () async {
        var testBed = new NgTestBed<BasicSelectTest>();
        var fixture = await testBed.create();
        var select =
            fixture.rootElement.querySelector('select') as SelectElement;
        var sfOption =
            fixture.rootElement.querySelector('option') as OptionElement;
        expect(select.value, 'SF');
        expect(sfOption.selected, true);
      });
      test('with basic selection and value bindings', () async {
        var testBed = new NgTestBed<SelectForTest>();
        var fixture = await testBed.create();
        var sfOption =
            fixture.rootElement.querySelector('option') as OptionElement;
        expect(sfOption.value, '0');
        await fixture.update((SelectForTest component) {
          component.cities.first['id'] = '2';
        });
        expect(sfOption.value, '2');
      });
      test('with ngControl', () async {
        var testBed = new NgTestBed<SelectControlTest>();
        var form = new ControlGroup({'city': new Control('SF')});
        var fixture = await testBed.create(
            beforeChangeDetection: (SelectControlTest component) {
          component.form = form;
        });
        var select =
            fixture.rootElement.querySelector('select') as SelectElement;
        var sfOption =
            fixture.rootElement.querySelector('option') as OptionElement;
        expect(select.value, 'SF');
        expect(sfOption.selected, true);
        await fixture.update((_) {
          select.value = 'NYC';
          dispatchEvent(select, 'change');
        });
        expect(form.value, equals({'city': 'NYC'}));
        expect(sfOption.selected, false);
      });
      test('with a dynamic list of options', () async {
        var testBed = new NgTestBed<SelectControlDynamicDataTest>();
        var fixture = await testBed.create();
        var select =
            fixture.rootElement.querySelector('select') as SelectElement;
        expect(select.value, 'NYC');
      });
      test('with option values that are maps', () async {
        var testBed = new NgTestBed<SelectOptionValueMapTest>();
        var fixture = await testBed.create();
        await fixture.update((SelectOptionValueMapTest component) {
          component.selectedCity = component.cities[1];
        });
        var select =
            fixture.rootElement.querySelector('select') as SelectElement;
        var nycOption =
            fixture.rootElement.querySelectorAll('option')[1] as OptionElement;
        expect(select.value, '1: Object');
        expect(nycOption.selected, true);
        await fixture.update((_) {
          select.value = '2: Object';
          dispatchEvent(select, 'change');
        });
        await fixture.update((SelectOptionValueMapTest component) {
          expect(component.selectedCity['name'], 'Buffalo');
        });
      });
      test('when new options are added', () async {
        var testBed = new NgTestBed<SelectOptionValueMapTest>();
        var fixture = await testBed.create(
            beforeChangeDetection: (SelectOptionValueMapTest component) {
          component.cities = [
            {'name': 'SF'},
            {'name': 'NYC'}
          ];
          component.selectedCity = component.cities[1];
        });
        await fixture.update((SelectOptionValueMapTest component) {
          component.cities.add({'name': 'Buffalo'});
          component.selectedCity = component.cities[2];
        });
        var select =
            fixture.rootElement.querySelector('select') as SelectElement;
        var buffalo =
            fixture.rootElement.querySelectorAll('option')[2] as OptionElement;
        expect(select.value, '2: Object');
        expect(buffalo.selected, true);
      });
      test('when options are removed', () async {
        var testBed = new NgTestBed<SelectOptionValueMapTest>();
        var fixture = await testBed.create(
            beforeChangeDetection: (SelectOptionValueMapTest component) {
          component.cities = [
            {'name': 'SF'},
            {'name': 'NYC'}
          ];
          component.selectedCity = component.cities[1];
        });
        var select =
            fixture.rootElement.querySelector('select') as SelectElement;
        expect(select.value, '1: Object');
        await fixture.update((SelectOptionValueMapTest component) {
          component.cities.removeLast();
        });
        expect(select.value, isNot('1: Object'));
      });
      test('when option values change identity while tracking by index',
          () async {
        var testBed = new NgTestBed<SelectTrackByTest>();
        var fixture = await testBed.create(
            beforeChangeDetection: (SelectTrackByTest component) {
          component.selectedCity = component.cities.first;
        });
        await fixture.update((SelectTrackByTest component) {
          component.cities[1] = 'Buffalo';
          component.selectedCity = component.cities[1];
        });
        var select =
            fixture.rootElement.querySelector('select') as SelectElement;
        var buffalo =
            fixture.rootElement.querySelectorAll('option')[1] as OptionElement;
        expect(select.value, '1: Buffalo');
        expect(buffalo.selected, true);
      });
      test('with duplicate option values', () async {
        var testBed = new NgTestBed<SelectOptionValueMapTest>();
        var fixture = await testBed.create(
            beforeChangeDetection: (SelectOptionValueMapTest component) {
          component.cities = [
            {'name': 'NYC'},
            {'name': 'SF'},
            {'name': 'SF'},
          ];
          component.selectedCity = component.cities.first;
        });
        await fixture.update((SelectOptionValueMapTest component) {
          component.selectedCity = component.cities[1];
        });
        var select =
            fixture.rootElement.querySelector('select') as SelectElement;
        var firstSF =
            fixture.rootElement.querySelectorAll('option')[1] as OptionElement;
        expect(select.value, '1: Object');
        expect(firstSF.selected, true);
      });
      test('when option values have same content, but different identities',
          () async {
        var testBed = new NgTestBed<SelectOptionValueMapTest>();
        var fixture = await testBed.create(
            beforeChangeDetection: (SelectOptionValueMapTest component) {
          component.cities = [
            {'name': 'SF'},
            {'name': 'NYC'},
            {'name': 'NYC'},
          ];
          component.selectedCity = component.cities.first;
        });
        await fixture.update((SelectOptionValueMapTest component) {
          component.selectedCity = component.cities[2];
        });
        var select =
            fixture.rootElement.querySelector('select') as SelectElement;
        var secondNYC =
            fixture.rootElement.querySelectorAll('option')[2] as OptionElement;
        expect(select.value, '2: Object');
        expect(secondNYC.selected, true);
      });
    });
    test('should support custom value accessors', () async {
      var testBed = new NgTestBed<CustomAccessorTest>();
      var form = new ControlGroup({'name': new Control('aa')});
      var fixture = await testBed.create(
          beforeChangeDetection: (CustomAccessorTest component) {
        component.form = form;
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.value, '!aa!');
      await fixture.update((_) {
        input.value = '!bb!';
        dispatchEvent(input, 'input');
      });
      expect(form.value, equals({'name': 'bb'}));
    });
    test(
        'should support custom value accessors on non builtin input '
        'elements that fire a change event without a "target" property',
        () async {
      var testBed = new NgTestBed<MyInputTest>();
      var fixture = await testBed.create();
      MyInput myInput;
      await fixture.update((MyInputTest component) {
        myInput = component.myInput;
        expect(myInput.value, '!aa!');
        myInput.value = '!bb!';
        myInput.onInput.stream.listen((value) {
          expect(component.form.value, equals({'name': 'bb'}));
        });
        myInput.dispatchChangeEvent();
      });
    });
    group('validations', () {
      test('should use sync validators defined in html', () async {
        var testBed = new NgTestBed<SyncValidatorsHtmlTest>();
        var form = new ControlGroup({
          'login': new Control(''),
          'min': new Control(''),
          'max': new Control('')
        });
        var fixture = await testBed.create(
            beforeChangeDetection: (SyncValidatorsHtmlTest component) {
          component.form = form;
        });
        var required =
            fixture.rootElement.querySelector('[required]') as InputElement;
        var minLength = fixture.rootElement.querySelector('[ngControl=min]')
            as InputElement;
        var maxLength = fixture.rootElement.querySelector('[ngControl=max]')
            as InputElement;
        await fixture.update((_) {
          required.value = '';
          minLength.value = '1';
          maxLength.value = '1234';
          dispatchEvent(required, 'input');
          dispatchEvent(minLength, 'input');
          dispatchEvent(maxLength, 'input');
        });
        expect(form.hasError('required', ['login']), true);
        expect(form.hasError('minlength', ['min']), true);
        expect(form.hasError('maxlength', ['max']), true);
        expect(form.hasError('loginIsEmpty'), true);
        await fixture.update((_) {
          required.value = '1';
          minLength.value = '123';
          maxLength.value = '123';
          dispatchEvent(required, 'input');
          dispatchEvent(minLength, 'input');
          dispatchEvent(maxLength, 'input');
        });
        expect(form.valid, true);
      });
      test('should use sync validators defined in the model', () async {
        var testBed = new NgTestBed<InputFormTest>();
        var form =
            new ControlGroup({'login': new Control('aa', Validators.required)});
        var fixture = await testBed.create(
            beforeChangeDetection: (InputFormTest component) {
          component.form = form;
        });
        expect(form.valid, true);
        await fixture.update((_) {
          var input =
              fixture.rootElement.querySelector('input') as InputElement;
          input.value = '';
          dispatchEvent(input, 'input');
        });
        expect(form.valid, false);
      });
    });
    group('nested forms', () {
      test('should init DOM with the given form object', () async {
        var testBed = new NgTestBed<NestedFormTest>();
        var fixture = await testBed.create();
        var input = fixture.rootElement.querySelector('input') as InputElement;
        expect(input.value, 'value');
      });
      test('should update the control group values on DOM change', () async {
        var testBed = new NgTestBed<NestedFormTest>();
        var fixture = await testBed.create();
        var input = fixture.rootElement.querySelector('input') as InputElement;
        var form;
        await fixture.update((NestedFormTest component) {
          input.value = 'updatedValue';
          dispatchEvent(input, 'input');
          form = component.form;
        });
        expect(
            form.value,
            equals({
              'nested': {'login': 'updatedValue'}
            }));
      });
    });
    test('should support ngModel for complex forms', () async {
      var testBed = new NgTestBed<ComplexNgModelTest>();
      var fixture = await testBed.create();
      await fixture.update((ComplexNgModelTest component) {
        component.name = 'oldValue';
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.value, 'oldValue');
      ComplexNgModelTest comp;
      await fixture.update((ComplexNgModelTest component) {
        input.value = 'updatedValue';
        dispatchEvent(input, 'input');
        comp = component;
      });
      expect(comp.name, 'updatedValue');
    });
    test('should support ngModel for single fields', () async {
      var testBed = new NgTestBed<SingleFieldNgModelTest>();
      var fixture = await testBed.create();
      await fixture.update((SingleFieldNgModelTest component) {
        component.name = 'oldValue';
      });
      var input = fixture.rootElement.querySelector('input') as InputElement;
      expect(input.value, 'oldValue');

      SingleFieldNgModelTest comp;
      await fixture.update((SingleFieldNgModelTest component) {
        input.value = 'updatedValue';
        dispatchEvent(input, 'input');
        comp = component;
      });
      expect(comp.name, 'updatedValue');
    });
    group('template-driven forms', () {
      test('should add new controls and control groups', () async {
        var testBed = new NgTestBed<TemplateFormTest>();
        var fixture = await testBed.create();
        NgForm form;
        await fixture.update((TemplateFormTest component) {
          form = component.form;
        });
        expect(form.controls, contains('user'));
        expect((form.controls['user'] as ControlGroup).controls,
            contains('login'));
      });
      test('should emit ngSubmit event on submit', () async {
        var testBed = new NgTestBed<TemplateSubmitTest>();
        var fixture = await testBed.create();
        await fixture.update((TemplateSubmitTest component) {
          component.name = 'old';
        });
        TemplateSubmitTest comp;
        await fixture.update((TemplateSubmitTest component) {
          var form = fixture.rootElement.querySelector('form');
          dispatchEvent(form, 'submit');
          comp = component;
        });
        expect(comp.name, 'updated');
      });
      test('should not create a form when ngNoForm is used', () async {
        var testBed = new NgTestBed<NgNoFormTest>();
        var fixture = await testBed.create();
        await fixture.update((form) {
          expect(form.hasForm.ngForm, isNotNull);
          expect(form.noForm.ngForm, isNull);
        });
      });
      test('should remove controls', () async {
        var testBed = new NgTestBed<RemoveControlsTest>();
        var fixture = await testBed.create();
        NgForm form;
        await fixture.update((RemoveControlsTest component) {
          component.name = 'show';
          form = component.myForm;
        });
        expect(form.controls, contains('login'));
        await fixture.update((RemoveControlsTest component) {
          component.name = 'hide';
        });
        expect(form, isNot(contains('login')));
      });
      test('should remove control groups', () async {
        var testBed = new NgTestBed<RemoveControlGroupTest>();
        var fixture = await testBed.create();
        NgForm form;
        await fixture.update((RemoveControlGroupTest component) {
          component.name = 'show';
          form = component.myForm;
        });
        expect(form.controls, contains('user'));
        await fixture.update((RemoveControlGroupTest component) {
          component.name = 'hide';
        });
        expect(form.controls, isNot(contains('user')));
      });
      test('should support ngModel for complex forms', () async {
        var testBed = new NgTestBed<NgModelComplexTest>();
        var fixture = await testBed.create();
        await fixture.update((NgModelComplexTest component) {
          component.name = 'oldValue';
        });
        var input = fixture.rootElement.querySelector('input') as InputElement;
        expect(input.value, 'oldValue');
        NgModelComplexTest comp;
        await fixture.update((NgModelComplexTest component) {
          input.value = 'updatedValue';
          dispatchEvent(input, 'input');
          comp = component;
        });
        expect(comp.name, 'updatedValue');
      });
      test('should support ngModel for single fields', () async {
        var testBed = new NgTestBed<NgModelSingleFieldTest>();
        var fixture = await testBed.create();
        await fixture.update((NgModelSingleFieldTest component) {
          component.name = 'oldValue';
        });
        var input = fixture.rootElement.querySelector('input') as InputElement;
        expect(input.value, 'oldValue');
        NgModelSingleFieldTest comp;
        await fixture.update((NgModelSingleFieldTest component) {
          input.value = 'updatedValue';
          dispatchEvent(input, 'input');
          comp = component;
        });
        expect(comp.name, 'updatedValue');
      });
      test('should support <type=radio>', () async {
        var testBed = new NgTestBed<TemplateRadioTest>();
        var data = <String, RadioButtonState>{
          'chicken1': new RadioButtonState(false, 'chicken'),
          'fish1': new RadioButtonState(true, 'fish'),
          'chicken2': new RadioButtonState(false, 'chicken'),
          'fish2': new RadioButtonState(true, 'fish'),
        };
        var fixture = await testBed.create(
            beforeChangeDetection: (TemplateRadioTest component) {
          component.data = data;
        });
        var input = fixture.rootElement.querySelector('input') as InputElement;
        expect(input.checked, false);
        await fixture.update((_) {
          dispatchEvent(input, 'change');
        });
        expect(data['chicken1'].checked, true);
        expect(data['chicken1'].value, 'chicken');
        expect(data['fish1'].checked, false);
        expect(data['fish1'].value, 'fish');
        expect(data['chicken2'].checked, false);
        expect(data['chicken2'].value, 'chicken');
        expect(data['fish2'].checked, true);
        expect(data['fish2'].value, 'fish');
      });
    });
    group('ngModel corner cases', () {
      test(
          'should not update the view when the value '
          'initially came from the view', () async {
        var testBed = new NgTestBed<NgModelInitialViewTest>();
        var fixture = await testBed.create();
        var input = fixture.rootElement.querySelector('input') as InputElement;
        await fixture.update((_) {
          input.value = 'aa';
          input.selectionStart = 1;
          dispatchEvent(input, 'input');
        });
        expect(input.selectionStart, 1);
      });
      test(
          'should update the view when the model is set '
          'back to what used to be in the view', () async {
        var testBed = new NgTestBed<NgModelRevertViewTest>();
        var fixture = await testBed.create();
        await fixture.update((NgModelRevertViewTest component) {
          component.name = '';
        });
        var input = fixture.rootElement.querySelector('input') as InputElement;
        NgModelRevertViewTest comp;
        await fixture.update((NgModelRevertViewTest component) {
          input.value = 'aa';
          input.selectionStart = 1;
          dispatchEvent(input, 'input');
          comp = component;
        });
        expect(comp.name, 'aa');
        await fixture.update((NgModelRevertViewTest component) {
          component.name = 'bb';
        });
        expect(input.value, 'bb');
        await fixture.update((NgModelRevertViewTest component) {
          component.name = 'aa';
        });
        expect(input.value, 'aa');
      });
      test('should not crash when validity is checked from a binding',
          () async {
        // {{x.valid}} used to crash because valid() tried to read a property
        // from form.control before it was set. This test verifies this bug is
        // fixed.
        var testBed = new NgTestBed<NgModelValidityTest>();
        await testBed.create();
      });
    });
  });
}

@Directive(selector: '[wrapped-value]', host: const {
  '(input)': 'handleOnInput(\$event.target.value)',
  '[value]': 'value'
}, providers: [
  const ExistingProvider.forToken(
    NG_VALUE_ACCESSOR,
    WrappedAccessor,
  )
])
class WrappedAccessor implements ControlValueAccessor {
  var value;
  Function onChange;

  void writeValue(value) {
    this.value = '!$value!';
  }

  void registerOnChange(fn) {
    this.onChange = fn;
  }

  void registerOnTouched(fn) {}

  void handleOnInput(value) {
    this.onChange(value.substring(1, value.length - 1));
  }
}

@Component(selector: 'my-input', template: '', providers: [
  const ExistingProvider.forToken(
    NG_VALUE_ACCESSOR,
    MyInput,
  )
])
class MyInput implements ControlValueAccessor {
  @Output('input')
  StreamController onInput = new StreamController.broadcast();
  String value;

  void writeValue(value) {
    this.value = '!$value!';
  }

  void registerOnChange(fn) {
    this.onInput.stream.listen(fn);
  }

  void registerOnTouched(fn) {}

  void dispatchChangeEvent() {
    this.onInput.add(this.value.substring(1, this.value.length - 1));
  }
}

Map loginIsEmptyGroupValidator(ControlGroup c) {
  return c.controls['login'].value == '' ? {'loginIsEmpty': true} : null;
}

@Directive(selector: '[login-is-empty-validator]', providers: const [
  const Provider(NG_VALIDATORS,
      useValue: loginIsEmptyGroupValidator, multi: true)
])
class LoginIsEmptyValidator {}

@Component(
    selector: 'input-form-test',
    directives: const [formDirectives],
    template: '''
<div [ngFormModel]="form">
  <input type="text" ngControl="login">
</div>''')
class InputFormTest {
  ControlGroup form;
}

@Component(
    selector: 'submit-form-test',
    directives: const [formDirectives],
    template: '''
<div>
  <form [ngFormModel]="form" (ngSubmit)="name = 'updated'"></form>
  <span>{{name}}</span>
</div>''')
class SubmitFormTest {
  ControlGroup form;
  String name;
}

@Component(
  selector: 'single-control-test',
  directives: const [formDirectives],
  template: '<div><input type="text" [ngFormControl]="form"></div>',
)
class SingleControlTest {
  Control form;
}

@Component(
    selector: 'input-without-type-test',
    directives: const [formDirectives],
    template: '''
<div [ngFormModel]="form">
  <input ngControl="text">
</div>''')
class InputWithoutTypeTest {
  ControlGroup form;
}

@Component(
    selector: 'textarea-test', directives: const [formDirectives], template: '''
<div [ngFormModel]="form">
  <textarea ngControl="text"></textarea>
</div>''')
class TextAreaTest {
  ControlGroup form;
}

@Component(
    selector: 'checkbox-test', directives: const [formDirectives], template: '''
<div [ngFormModel]="form">
  <input type="checkbox" ngControl="checkbox">
</div>''')
class CheckboxTest {
  ControlGroup form;
}

@Component(
    selector: 'number-test', directives: const [formDirectives], template: '''
<div [ngFormModel]="form">
  <input type="number" ngControl="num">
</div>''')
class NumberTest {
  ControlGroup form;
}

@Component(
    selector: 'number-required-test',
    directives: const [formDirectives],
    template: '''
<div [ngFormModel]="form">
  <input type="number" ngControl="num" required>
</div>''')
class NumberRequiredTest {
  ControlGroup form;
}

@Component(
    selector: 'number-required-test',
    directives: const [formDirectives],
    template: '''
<div [ngFormModel]="form">
  <input type="number" ngControl="num" [(ngModel)]="data">
</div>''')
class NumberModelTest {
  ControlGroup form;
  String data;
}

@Component(
    selector: 'radio-test',
    directives: const [formDirectives],
    providers: FORM_PROVIDERS,
    template: '''
<form [ngFormModel]="form">
  <input type="radio" ngControl="foodChicken" name="food">
  <input type="radio" ngControl="foodFish" name="food">
</form>''')
class RadioTest {
  ControlGroup form;
}

@Component(
    selector: 'basic-select-test',
    directives: const [formDirectives],
    template: '''
<select>
  <option value="SF"></option>
  <option value="NYC"></option>
</select>''')
class BasicSelectTest {}

@Component(
    selector: 'select-for-test',
    directives: const [formDirectives, NgFor],
    template: '''
<select>
  <option *ngFor="let city of cities" [value]="city['id']">
    {{city['name']}}
  </option>
</select>''')
class SelectForTest {
  List<Map<String, String>> cities = [
    {'id': '0', 'name': 'SF'},
    {'id': '1', 'name': 'NYC'}
  ];
}

@Component(
    selector: 'select-control-test',
    directives: const [formDirectives],
    template: '''
<div [ngFormModel]="form">
  <select ngControl="city">
    <option value="SF"></option>
    <option value="NYC"></option>
  </select>
</div>''')
class SelectControlTest {
  ControlGroup form;
}

@Component(
    selector: 'select-control-dynamic-data-test',
    directives: const [formDirectives, NgFor],
    template: '''
<div [ngFormModel]="form">
  <select ngControl="city">
    <option *ngFor="let c of cities" [value]="c"></option>
  </select>
</div>''')
class SelectControlDynamicDataTest {
  ControlGroup form = new ControlGroup({'city': new Control('NYC')});
  List<String> cities = ['SF', 'NYC'];
}

@Component(
    selector: 'select-option-value-map-test',
    directives: const [formDirectives, NgFor],
    template: '''
<div>
  <select [(ngModel)]="selectedCity">
    <option *ngFor="let c of cities" [ngValue]="c">{{c['name']}}</option>
  </select>
</div>''')
class SelectOptionValueMapTest {
  Map<String, String> selectedCity;

  List<Map<String, String>> cities = [
    {'name': 'SF'},
    {'name': 'NYC'},
    {'name': 'Buffalo'}
  ];
}

@Component(
    selector: 'select-trackby-test',
    directives: const [formDirectives, NgFor],
    template: '''
<div>
  <select [(ngModel)]="selectedCity">
    <option *ngFor="let c of cities; trackBy:customTrackBy" [ngValue]="c">{{c}}</option>
  </select>
</div>''')
class SelectTrackByTest {
  dynamic selectedCity;

  List cities = [
    {'name': 'SF'},
    {'name': 'NYC'},
  ];

  num customTrackBy(num index, dynamic obj) {
    return index;
  }
}

@Component(
    selector: 'custom-accessor-test',
    directives: const [formDirectives, WrappedAccessor],
    template: '''
<div [ngFormModel]="form">
  <input type="text" ngControl="name" wrapped-value>
</div>''')
class CustomAccessorTest {
  ControlGroup form;
}

@Component(
    selector: 'my-input-test',
    directives: const [formDirectives, MyInput],
    template: '''
<div [ngFormModel]="form">
  <my-input #input ngControl="name"></my-input>
</div>''')
class MyInputTest {
  ControlGroup form = new ControlGroup({'name': new Control('aa')});

  @ViewChild('input')
  MyInput myInput;
}

@Component(
    selector: 'sync-validators-html-test',
    directives: const [formDirectives, LoginIsEmptyValidator],
    template: '''
<div [ngFormModel]="form" login-is-empty-validator>
  <input type="text" ngControl="login" required>
  <input type="text" ngControl="min" [minlength]="3">
  <input type="text" ngControl="max" [maxlength]="3">
</div>''')
class SyncValidatorsHtmlTest {
  ControlGroup form;
}

@Component(
    selector: 'nested-form-test',
    directives: const [formDirectives],
    template: '''
<div [ngFormModel]="form">
  <div ngControlGroup="nested">
    <input type="text" ngControl="login">
  </div>
</div>''')
class NestedFormTest {
  ControlGroup form = new ControlGroup({
    'nested': new ControlGroup({'login': new Control('value')})
  });
}

@Component(
    selector: 'complex-ngmodel-test',
    directives: const [formDirectives],
    template: '''
<div [ngFormModel]="form">
  <input type="text" ngControl="name" [(ngModel)]="name">
</div>''')
class ComplexNgModelTest {
  ControlGroup form = new ControlGroup({'name': new Control('')});

  String name;
}

@Component(
    selector: 'single-field-ngmodel-test',
    directives: const [formDirectives],
    template: '''
<div>
  <input type="text" [ngFormControl]="form" [(ngModel)]="name">
</div>''')
class SingleFieldNgModelTest {
  Control form = new Control('');
  String name;
}

@Component(
    selector: 'template-form-test',
    directives: const [formDirectives],
    template: '''
<form #myForm="ngForm">
  <div ngControlGroup="user">
    <input type="text" ngControl="login">
  </div>
</form>''')
class TemplateFormTest {
  @ViewChild('myForm')
  NgForm form;
}

@Component(
  selector: 'template-submit-test',
  directives: const [formDirectives],
  template: '''<div><form (ngSubmit)="name = 'updated'"></form></div>''',
)
class TemplateSubmitTest {
  String name;
}

@Component(
  selector: 'ngnoform-test',
  directives: const [formDirectives, NoNgFormChild],
  template: ''''
  <form>
    <ng-form-child #hasForm></ng-form-child>
  </form>
  <form ngNoForm>
      <ng-form-child #noForm></ng-form-child>
  </form>''',
)
class NgNoFormTest {
  @ViewChild('hasForm')
  NoNgFormChild hasForm;

  @ViewChild('noForm')
  NoNgFormChild noForm;
}

@Component(
  selector: 'ng-form-child',
  template: '',
)
class NoNgFormChild {
  final ControlContainer ngForm;

  NoNgFormChild(@Optional() this.ngForm);
}

@Component(
    selector: 'remove-controls-test',
    directives: const [formDirectives, NgIf],
    template: '''
<form #myForm="ngForm">
  <div *ngIf="name == 'show'">
    <input type="text" ngControl="login">
  </div>
</form>''')
class RemoveControlsTest {
  String name;

  @ViewChild('myForm')
  NgForm myForm;
}

@Component(
    selector: 'remove-control-group-test',
    directives: const [formDirectives, NgIf],
    template: '''
<form #myForm="ngForm">
  <div *ngIf="name == 'show'" ngControlGroup="user">
    <input type="text" ngControl="login">
  </div>
</form>''')
class RemoveControlGroupTest {
  String name;

  @ViewChild('myForm')
  NgForm myForm;
}

@Component(
    selector: 'ngmodel-complex-test',
    directives: const [formDirectives],
    template: '''
<form>
  <input type="text" ngControl="name" [(ngModel)]="name">
</form>''')
class NgModelComplexTest {
  String name;
}

@Component(
  selector: 'ngmodel-single-field-test',
  directives: const [formDirectives],
  template: '<div><input type="text" [(ngModel)]="name"></div>',
)
class NgModelSingleFieldTest {
  String name;
}

@Component(
    selector: 'template-radio-test',
    directives: const [formDirectives],
    providers: FORM_PROVIDERS,
    template: '''
<form>
  <input type="radio" name="food" ngControl="chicken" [(ngModel)]="data['chicken1']">
  <input type="radio" name="food" ngControl="fish" [(ngModel)]="data['fish1']">
</form>
<form>
  <input type="radio" name="food" ngControl="chicken" [(ngModel)]="data['chicken2']">
  <input type="radio" name="food" ngControl="fish" [(ngModel)]="data['fish2']">
</form>''')
class TemplateRadioTest {
  Map<String, RadioButtonState> data;
}

@Component(
  selector: 'ngmodel-initial-view-test',
  directives: const [formDirectives],
  template: '''
<div>
  <input type="text" [ngFormControl]="form" [(ngModel)]="name">
</div>''',
)
class NgModelInitialViewTest {
  Control form = new Control('');
  String name;
}

@Component(
  selector: 'ngmodel-revert-view-test',
  directives: const [formDirectives],
  template: '<input type="text" [(ngModel)]="name">',
)
class NgModelRevertViewTest {
  String name;
}

@Component(
    selector: 'ngmodel-validity-test',
    directives: const [formDirectives],
    template: '''
<form>
  <div ngControlGroup="x" #x="ngForm">
    <input type="text" ngControl="test">
  </div>{{x.valid}}
</form>''')
class NgModelValidityTest {}
