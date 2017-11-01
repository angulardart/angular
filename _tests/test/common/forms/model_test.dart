@Tags(const ['codegen'])
@TestOn('browser')

import 'package:test/test.dart';
import 'package:angular_forms/angular_forms.dart';

import 'model_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('Form Model', () {
    group('Control', () {
      test('should default the value to null', () {
        var c = new Control();
        expect(c.value, isNull);
      });
      group('validator', () {
        test('should run validator with the initial value', () {
          var c = new Control('value', Validators.required);
          expect(c.valid, true);
        });
        test('should rerun the validator when the value changes', () {
          var c = new Control('value', Validators.required);
          c.updateValue(null);
          expect(c.valid, false);
        });
        test('should return errors', () {
          var c = new Control(null, Validators.required);
          expect(c.errors, {'required': true});
        });
      });
      group('dirty', () {
        test('should be false after creating a control', () {
          var c = new Control('value');
          expect(c.dirty, false);
        });
        test('should be true after changing the value of the control', () {
          var c = new Control('value');
          c.markAsDirty();
          expect(c.dirty, true);
        });
      });
      group('updateValue', () {
        Control c;
        ControlGroup g;
        setUp(() {
          c = new Control('oldValue');
          g = new ControlGroup({'one': c});
        });
        test('should update the value of the control', () {
          c.updateValue('newValue');
          expect(c.value, 'newValue');
        });
        test('should invoke ngOnChanges if it is present', () {
          var ngOnChanges;
          c.registerOnChange((v) => ngOnChanges = ['invoked', v]);
          c.updateValue('newValue');
          expect(ngOnChanges, ['invoked', 'newValue']);
        });
        test('should not invoke on change when explicitly specified', () {
          var onChange;
          c.registerOnChange((v) => onChange = ['invoked', v]);
          c.updateValue('newValue', emitModelToViewChange: false);
          expect(onChange, isNull);
        });
        test('should update the parent', () {
          c.updateValue('newValue');
          expect(g.value, {'one': 'newValue'});
        });
        test('should not update the parent when explicitly specified', () {
          c.updateValue('newValue', onlySelf: true);
          expect(g.value, {'one': 'oldValue'});
        });
        test('should fire an event', () {
          c.valueChanges.listen(expectAsync1((value) {
            expect(value, 'newValue');
          }));
          c.updateValue('newValue');
        });
        test('should not fire an event when explicitly specified', () {
          c.valueChanges.listen(expectAsync1((value) {}, count: 0));
          c.updateValue('newValue', emitEvent: false);
        });
        test('should update raw value', () {
          c.updateValue('newValue', rawValue: 'rawValue');
          expect(c.rawValue, 'rawValue');
          expect(g.value, {'one': 'newValue'});
        });
      });
      group('valueChanges & statusChanges', () {
        var c;
        setUp(() {
          c = new Control('old', Validators.required);
        });
        test('should fire an event after the value has been updated', () async {
          c.valueChanges.listen(expectAsync1((value) {
            expect(c.value, 'new');
            expect(value, 'new');
          }));
          c.updateValue('new');
        });
        test(
            'should fire an event after the status has been updated to invalid',
            () {
          c.statusChanges.listen(expectAsync1((status) {
            expect(c.status, 'INVALID');
            expect(status, 'INVALID');
          }));
          c.updateValue('');
        });
        test('should return a cold observable', () async {
          c.updateValue('will be ignored');
          c.valueChanges.listen(expectAsync1((value) {
            expect(value, 'new');
          }));
          c.updateValue('new');
        });
      });
      group('setErrors', () {
        test('should set errors on a control', () {
          var c = new Control('someValue');
          c.setErrors({'someError': true});
          expect(c.valid, false);
          expect(c.errors, {'someError': true});
        });
        test('should reset the errors and validity when the value changes', () {
          var c = new Control('someValue', Validators.required);
          c.setErrors({'someError': true});
          c.updateValue('');
          expect(c.errors, {'required': true});
        });
        test("should update the parent group's validity", () {
          var c = new Control('someValue');
          var g = new ControlGroup({'one': c});
          expect(g.valid, true);
          c.setErrors({'someError': true});
          expect(g.valid, false);
        });
        test("should not reset parent's errors", () {
          var c = new Control('someValue');
          var g = new ControlGroup({'one': c});
          g.setErrors({'someGroupError': true});
          c.setErrors({'someError': true});
          expect(g.errors, {'someGroupError': true});
        });
        test('should reset errors when updating a value', () {
          var c = new Control('oldValue');
          var g = new ControlGroup({'one': c});
          g.setErrors({'someGroupError': true});
          c.setErrors({'someError': true});
          c.updateValue('newValue');
          expect(c.errors, isNull);
          expect(g.errors, isNull);
        });
      });
    });
    group('ControlGroup', () {
      group('value', () {
        test('should be the reduced value of the child controls', () {
          var g = new ControlGroup(
              {'one': new Control('111'), 'two': new Control('222')});
          expect(g.value, {'one': '111', 'two': '222'});
        });
        test('should be empty when there are no child controls', () {
          var g = new ControlGroup({});
          expect(g.value, {});
        });
        test('should support nested groups', () {
          var g = new ControlGroup({
            'one': new Control('111'),
            'nested': new ControlGroup({'two': new Control('222')})
          });
          expect(g.value, {
            'one': '111',
            'nested': {'two': '222'}
          });
          (((g.controls['nested'].find('two')) as Control)).updateValue('333');
          expect(g.value, {
            'one': '111',
            'nested': {'two': '333'}
          });
        });
      });
      group('errors', () {
        test('should run the validator when the value changes', () {
          Map<String, bool> simpleValidator(c) =>
              c.controls['one'].value != 'correct' ? {'broken': true} : null;
          var c = new Control(null);
          var g = new ControlGroup({'one': c}, null, simpleValidator);
          c.updateValue('correct');
          expect(g.valid, true);
          expect(g.errors, null);
          c.updateValue('incorrect');
          expect(g.valid, false);
          expect(g.errors, {'broken': true});
        });
      });
      group('dirty', () {
        Control c;
        ControlGroup g;
        setUp(() {
          c = new Control('value');
          g = new ControlGroup({'one': c});
        });
        test('should be false after creating a control', () {
          expect(g.dirty, false);
        });
        test('should be false after changing the value of the control', () {
          c.markAsDirty();
          expect(g.dirty, true);
        });
      });
      group('optional components', () {
        group('contains', () {
          var group;
          setUp(() {
            group = new ControlGroup({
              'required': new Control('requiredValue'),
              'optional': new Control('optionalValue')
            }, {
              'optional': false
            });
          });
          // rename contains into has
          test('should return false when the component is not included', () {
            expect(group.contains('optional'), false);
          });
          test(
              'should return false when there is no component '
              'with the given name', () {
            expect(group.contains('something else'), false);
          });
          test('should return true when the component is included', () {
            expect(group.contains('required'), true);
            group.include('optional');
            expect(group.contains('optional'), true);
          });
        });
        test('should not include an inactive component into the group value',
            () {
          var group = new ControlGroup({
            'required': new Control('requiredValue'),
            'optional': new Control('optionalValue')
          }, {
            'optional': false
          });
          expect(group.value, {'required': 'requiredValue'});
          group.include('optional');
          expect(group.value,
              {'required': 'requiredValue', 'optional': 'optionalValue'});
        });
        test('should not run Validators on an inactive component', () {
          var group = new ControlGroup({
            'required': new Control('requiredValue', Validators.required),
            'optional': new Control('', Validators.required)
          }, {
            'optional': false
          });
          expect(group.valid, true);
          group.include('optional');
          expect(group.valid, false);
        });
      });
      group('valueChanges', () {
        Control c1, c2;
        ControlGroup g;
        setUp(() {
          c1 = new Control('old1');
          c2 = new Control('old2');
          g = new ControlGroup({'one': c1, 'two': c2}, {'two': true});
        });
        test('should fire an event after the value has been updated', () async {
          g.valueChanges.listen(expectAsync1((value) {
            expect(g.value, {'one': 'new1', 'two': 'old2'});
            expect(value, {'one': 'new1', 'two': 'old2'});
          }));
          c1.updateValue('new1');
        });
        test(
            "should fire an event after the control's observable "
            "fired an event", () async {
          var controlCallbackIsCalled = false;
          c1.valueChanges.listen(expectAsync1((value) {
            controlCallbackIsCalled = true;
          }));
          g.valueChanges.listen(expectAsync1((value) {
            expect(controlCallbackIsCalled, true);
          }));
          c1.updateValue('new1');
        });
        test('should fire an event when a control is excluded', () async {
          g.valueChanges.listen(expectAsync1((value) {
            expect(value, {'one': 'old1'});
          }));
          g.exclude('two');
        });
        test('should fire an event when a control is included', () async {
          g.exclude('two');
          g.valueChanges.listen(expectAsync1((value) {
            expect(value, {'one': 'old1', 'two': 'old2'});
          }));
          g.include('two');
        });
        test('should fire an event every time a control is updated', () async {
          var loggedValues = [];
          g.valueChanges.listen(expectAsync1((value) {
            loggedValues.add(value);
            if (loggedValues.length == 2) {
              expect(loggedValues, [
                {'one': 'new1', 'two': 'old2'},
                {'one': 'new1', 'two': 'new2'}
              ]);
            }
          }, count: 2));
          c1.updateValue('new1');
          c2.updateValue('new2');
        });
      });
      group('getError', () {
        test('should return the error when it is present', () {
          var c = new Control('', Validators.required);
          var g = new ControlGroup({'one': c});
          expect(c.getError('required'), true);
          expect(g.getError('required', ['one']), true);
        });
        test('should return null otherwise', () {
          var c = new Control('not empty', Validators.required);
          var g = new ControlGroup({'one': c});
          expect(c.getError('invalid'), null);
          expect(g.getError('required', ['one']), null);
          expect(g.getError('required', ['invalid']), null);
        });
      });
    });
    group('ControlArray', () {
      group('adding/removing', () {
        ControlArray a;
        var c1, c2, c3;
        setUp(() {
          a = new ControlArray([]);
          c1 = new Control(1);
          c2 = new Control(2);
          c3 = new Control(3);
        });
        test('should support pushing', () {
          a.push(c1);
          expect(a.length, 1);
          expect(a.controls, [c1]);
        });
        test('should support removing', () {
          a.push(c1);
          a.push(c2);
          a.push(c3);
          a.removeAt(1);
          expect(a.controls, [c1, c3]);
        });
        test('should support inserting', () {
          a.push(c1);
          a.push(c3);
          a.insert(1, c2);
          expect(a.controls, [c1, c2, c3]);
        });
      });
      group('value', () {
        test('should be the reduced value of the child controls', () {
          var a = new ControlArray([new Control(1), new Control(2)]);
          expect(a.value, [1, 2]);
        });
        test('should be an empty array when there are no child controls', () {
          var a = new ControlArray([]);
          expect(a.value, []);
        });
      });
      group('errors', () {
        test('should run the validator when the value changes', () {
          Map<String, dynamic> simpleValidator(c) =>
              c.controls[0].value != 'correct' ? {'broken': true} : null;
          var c = new Control(null);
          var g = new ControlArray([c], simpleValidator);
          c.updateValue('correct');
          expect(g.valid, true);
          expect(g.errors, isNull);
          c.updateValue('incorrect');
          expect(g.valid, false);
          expect(g.errors, {'broken': true});
        });
      });
      group('dirty', () {
        Control c;
        ControlArray a;
        setUp(() {
          c = new Control('value');
          a = new ControlArray([c]);
        });
        test('should be false after creating a control', () {
          expect(a.dirty, false);
        });
        test('should be false after changing the value of the control', () {
          c.markAsDirty();
          expect(a.dirty, true);
        });
      });
      group('pending', () {
        Control c;
        ControlArray a;
        setUp(() {
          c = new Control('value');
          a = new ControlArray([c]);
        });
        test('should be false after creating a control', () {
          expect(c.pending, false);
          expect(a.pending, false);
        });
        test('should be true after changing the value of the control', () {
          c.markAsPending();
          expect(c.pending, true);
          expect(a.pending, true);
        });
        test('should not update the parent when onlySelf = true', () {
          c.markAsPending(onlySelf: true);
          expect(c.pending, true);
          expect(a.pending, false);
        });
      });
      group('valueChanges', () {
        ControlArray a;
        Control c1, c2;
        setUp(() {
          c1 = new Control('old1');
          c2 = new Control('old2');
          a = new ControlArray([c1, c2]);
        });
        test('should fire an event after the value has been updated', () async {
          a.valueChanges.listen(expectAsync1((value) {
            expect(a.value, ['new1', 'old2']);
            expect(value, ['new1', 'old2']);
          }));
          c1.updateValue('new1');
        });
        test(
            "should fire an event after the control's observable "
            "fired an event", () async {
          var controlCallbackIsCalled = false;
          c1.valueChanges.listen(expectAsync1((value) {
            controlCallbackIsCalled = true;
          }));
          a.valueChanges.listen(expectAsync1((value) {
            expect(controlCallbackIsCalled, true);
          }));
          c1.updateValue('new1');
        });
        test('should fire an event when a control is removed', () async {
          a.valueChanges.listen(expectAsync1((value) {
            expect(value, ['old1']);
          }));
          a.removeAt(1);
        });
        test('should fire an event when a control is added', () async {
          a.removeAt(1);
          a.valueChanges.listen(expectAsync1((value) {
            expect(value, ['old1', 'old2']);
          }));
          a.push(c2);
        });
      });
      group('find', () {
        test('should return null when path is null', () {
          var g = new ControlGroup({});
          expect(g.find(null), null);
        });
        test('should return null when path is empty', () {
          var g = new ControlGroup({});
          expect(g.find([]), null);
        });
        test('should return null when path is invalid', () {
          var g = new ControlGroup({});
          expect(g.find(['one', 'two']), null);
        });
        test('should return a child of a control group', () {
          var g = new ControlGroup({
            'one': new Control('111'),
            'nested': new ControlGroup({'two': new Control('222')})
          });
          expect(g.find(['nested', 'two']).value, '222');
          expect(g.find(['one']).value, '111');
          expect(g.find('nested/two').value, '222');
          expect(g.find('one').value, '111');
        });
        test('should return an element of an array', () {
          var g = new ControlGroup({
            'array': new ControlArray([new Control('111')])
          });
          expect(g.find(['array', 0]).value, '111');
        });
      });
    });
  });
}
