@TestOn('browser')

import 'package:test/test.dart';
import 'package:angular_forms/angular_forms.dart';

import 'model_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('Form Model', () {
    group('Control', () {
      test('should default the value to null', () {
        var c = Control();
        expect(c.value, isNull);
      });
      group('validator', () {
        test('should run validator with the initial value', () {
          var c = Control('value', Validators.required);
          expect(c.valid, true);
        });
        test('should rerun the validator when the value changes', () {
          var c = Control('value', Validators.required);
          c.updateValue(null);
          expect(c.valid, false);
        });
        test('should return errors', () {
          var c = Control(null, Validators.required);
          expect(c.errors, {'required': true});
        });
      });
      group('dirty', () {
        test('should be false after creating a control', () {
          var control = Control('value');
          expect(control.dirty, false);
        });

        test('should be true after changing the value of the control', () {
          var control = Control('value');
          control.markAsDirty();
          expect(control.dirty, true);
        });

        test('should reset to pristine', () {
          var control = Control('value');
          control.markAsDirty();
          expect(control.dirty, true);
          control.markAsPristine();
          expect(control.dirty, false);
        });

        test('should update parent', () {
          var control = Control('value');
          var group = ControlGroup({'control': control});
          control.markAsDirty(onlySelf: false);
          expect(group.dirty, true);
          control.markAsPristine(updateParent: true);
          expect(group.dirty, false);
        });
      });
      group('touched', () {
        test('should be false after creating a control', () {
          var c = Control('value');
          expect(c.touched, false);
        });

        test('should be true after touching the control', () {
          var c = Control('value');
          c.markAsTouched();
          expect(c.touched, true);
        });

        test('should be false after marking the control as untouched', () {
          var c = Control('value');
          c.markAsTouched();
          c.markAsUntouched();
          expect(c.touched, false);
        });

        test('should update parent', () {
          var control = Control('value');
          var group = ControlGroup({'control': control});
          control.markAsTouched();
          expect(group.touched, true);
          control.markAsUntouched();
          expect(group.touched, false);
        });
      });

      group('updateValue', () {
        Control c;
        ControlGroup g;
        setUp(() {
          c = Control('oldValue');
          g = ControlGroup({'one': c});
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
          c = Control('old', Validators.required);
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
          var c = Control('someValue');
          c.setErrors({'someError': true});
          expect(c.valid, false);
          expect(c.errors, {'someError': true});
        });
        test('should reset the errors and validity when the value changes', () {
          var c = Control('someValue', Validators.required);
          c.setErrors({'someError': true});
          c.updateValue('');
          expect(c.errors, {'required': true});
        });
        test('should update the parent group\'s validity', () {
          var c = Control('someValue');
          var g = ControlGroup({'one': c});
          expect(g.valid, true);
          c.setErrors({'someError': true});
          expect(g.valid, false);
        });
        test('should not reset parent\'s errors', () {
          var c = Control('someValue');
          var g = ControlGroup({'one': c});
          g.setErrors({'someGroupError': true});
          c.setErrors({'someError': true});
          expect(g.errors, {'someGroupError': true});
        });
        test('should reset errors when updating a value', () {
          var c = Control('oldValue');
          var g = ControlGroup({'one': c});
          g.setErrors({'someGroupError': true});
          c.setErrors({'someError': true});
          c.updateValue('newValue');
          expect(c.errors, isNull);
          expect(g.errors, isNull);
        });
      });
      group('disabled', () {
        Control control;
        ControlGroup group;

        setUp(() {
          control = Control('some value');
          group = ControlGroup({'one': control});
        });

        test('should update status', () {
          expect(control.disabled, false);
          control.markAsDisabled();
          expect(control.disabled, true);
          control.markAsEnabled();
          expect(control.disabled, false);
        });

        test('should programatically change value, but not status', () {
          expect(control.value, 'some value');
          control.markAsDisabled();
          expect(control.value, 'some value');
          control.updateValue('new value');
          expect(control.value, 'new value',
              reason: 'Value changes are propagated when disabled.');
          expect(control.disabled, true);
        });

        test('should update parent', () {
          expect(group.disabled, false);
          control.markAsDisabled();
          expect(group.disabled, true);
          control.markAsEnabled();
          expect(group.disabled, false);
        });
      });

      group('reset', () {
        Control control;

        setUp(() {
          control = Control();
        });

        test('should reset value', () {
          control.updateValue('some value');
          expect(control.value, 'some value');
          control.reset();
          expect(control.value, null);
        });

        test('should reset pristine', () {
          control.markAsDirty();
          expect(control.dirty, true);
          control.reset();
          expect(control.dirty, false);
        });

        test('should reset touched', () {
          control.markAsTouched();
          expect(control.touched, true);
          control.reset();
          expect(control.touched, false);
        });

        test('should not reset disabled state', () {
          control.markAsDisabled();
          expect(control.disabled, true);
          control.reset();
          expect(control.disabled, true);
        });

        test('should not reset enabled state', () {
          control.markAsEnabled();
          expect(control.enabled, true);
          control.reset();
          expect(control.enabled, true);
        });

        test('should allow setting value', () {
          control.reset(value: 'some value');
          expect(control.value, 'some value');
        });

        test('should allow setting disabled state', () {
          control.reset(isDisabled: true);
          expect(control.disabled, true);
        });

        test('should allow setting disabled state when disabled', () {
          control.markAsDisabled();
          control.reset(isDisabled: true);
          expect(control.disabled, true);
        });

        test('should allow setting enabled state when disabled', () {
          control.markAsDisabled();
          control.reset(isDisabled: false);
          expect(control.disabled, false);
        });
      });
    });

    group('ControlGroup', () {
      group('value', () {
        test('should be the reduced value of the child controls', () {
          var g = ControlGroup({'one': Control('111'), 'two': Control('222')});
          expect(g.value, {'one': '111', 'two': '222'});
        });

        test('should be empty when there are no child controls', () {
          var g = ControlGroup({});
          expect(g.value, {});
        });

        test('should support nested groups', () {
          var g = ControlGroup({
            'one': Control('111'),
            'nested': ControlGroup({'two': Control('222')})
          });
          expect(g.value, {
            'one': '111',
            'nested': {'two': '222'}
          });
          (g.controls['nested'].find('two') as Control).updateValue('333');
          expect(g.value, {
            'one': '111',
            'nested': {'two': '333'}
          });
        });
      });

      group('updateValue', () {
        Control control;
        ControlGroup group;

        setUp(() {
          control = Control('oldValue');
          group = ControlGroup({'one': control});
        });

        test('should update the value of the group', () {
          group.updateValue({'one': 'newValue'});
          expect(group.value, {'one': 'newValue'});
        });

        test('should update the value of the child control', () {
          group.updateValue({'one': 'newValue'});
          expect(control.value, 'newValue');
        });

        test('should "reset" the values with an empty map', () {
          group.updateValue({});
          expect(group.value, {'one': null});
          expect(control.value, null);
        });

        test('should "reset" the values with a null map', () {
          group.updateValue(null);
          expect(group.value, {'one': null});
          expect(control.value, null);
        });

        test('should throw if keys don\'t match', () {
          expect(() => group.updateValue({'two': 'newValue'}),
              throwsArgumentError);
        });

        test('should throw if missing control', () {
          group.addControl('two', Control());
          expect(() => group.updateValue({'one': 'newValue'}),
              throwsArgumentError);
        });
      });

      group('errors', () {
        test('should run the validator when the value changes', () {
          Map<String, bool> simpleValidator(c) =>
              c.controls['one'].value != 'correct' ? {'broken': true} : null;
          var c = Control<String>(null);
          var g = ControlGroup({'one': c}, simpleValidator);
          c.updateValue('correct');
          expect(g.valid, true);
          expect(g.errors, null);
          c.updateValue('incorrect');
          expect(g.valid, false);
          expect(g.errors, {'broken': true});
        });
      });

      group('dirty', () {
        Control control;
        ControlGroup group;

        setUp(() {
          control = Control('value');
          group = ControlGroup({'one': control});
        });

        test('should be false after creating a control', () {
          expect(group.dirty, false);
        });

        test('should be false after changing the value of the control', () {
          control.markAsDirty();
          expect(group.dirty, true);
        });

        test('setting pristine should update control', () {
          control.markAsDirty();
          group.markAsPristine();
          expect(control.dirty, false);
        });

        test('should derive value from children', () {
          var otherControl = Control('new value');
          group.addControl('two', otherControl);

          //Make only one control dirty.
          control.markAsDirty();
          expect(group.dirty, true);

          // Make *both* controls dirty, then pristine only one.
          otherControl.markAsDirty();
          otherControl.markAsPristine();
          expect(group.dirty, true);

          // Now, make *both* controls pristine.
          control.markAsPristine();
          expect(group.dirty, false);
        });
      });

      group('touched', () {
        Control control;
        ControlGroup group;

        setUp(() {
          control = Control('value');

          group = ControlGroup({'one': control});
        });

        test('should be false after creating a control', () {
          expect(group.touched, false);
        });

        test('should be true after changing the value of the control', () {
          control.markAsTouched();
          expect(group.touched, true);
        });

        test('setting untouched should update control', () {
          control.markAsTouched();
          group.markAsUntouched();
          expect(control.touched, false);
        });

        test('should derive value from children', () {
          var otherControl = Control('new value');
          group.addControl('two', otherControl);

          // Make only one control touched.
          control.markAsTouched();
          expect(group.touched, true);

          // Make *both* controls touched, then untouch only one.
          otherControl.markAsTouched();
          otherControl.markAsUntouched();
          expect(group.touched, true);

          // Now, untouch the second one.
          control.markAsUntouched();
          expect(group.touched, false);
        });
      });

      group('valueChanges', () {
        Control c1, c2;
        ControlGroup g;

        setUp(() {
          c1 = Control('old1');
          c2 = Control('old2');
          g = ControlGroup({'one': c1, 'two': c2});
        });

        test('should fire an event after the value has been updated', () async {
          g.valueChanges.listen(expectAsync1((value) {
            expect(g.value, {'one': 'new1', 'two': 'old2'});
            expect(value, {'one': 'new1', 'two': 'old2'});
          }));
          c1.updateValue('new1');
        });

        test(
            'should fire an event after the control\'s observable fired an '
            'event', () async {
          var controlCallbackIsCalled = false;
          c1.valueChanges.listen(expectAsync1((value) {
            controlCallbackIsCalled = true;
          }));
          g.valueChanges.listen(expectAsync1((value) {
            expect(controlCallbackIsCalled, true);
          }));
          c1.updateValue('new1');
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
          var c = Control('', Validators.required);
          var g = ControlGroup({'one': c});
          expect(c.getError('required'), true);
          expect(g.getError('required', ['one']), true);
        });

        test('should return null otherwise', () {
          var c = Control('not empty', Validators.required);
          var g = ControlGroup({'one': c});
          expect(c.getError('invalid'), null);
          expect(g.getError('required', ['one']), null);
          expect(g.getError('required', ['invalid']), null);
        });
      });

      group('disabled', () {
        Control control;
        ControlGroup group;

        setUp(() {
          control = Control('some value');
          group = ControlGroup({'one': control, 'two': Control('other value')});
        });

        test('should update status', () {
          expect(group.disabled, false);
          group.markAsDisabled();
          expect(group.disabled, true);
          group.markAsEnabled();
          expect(group.disabled, false);
        });

        test('should ignore values from disabled children', () {
          expect(group.value, {'one': 'some value', 'two': 'other value'});
          control.markAsDisabled();
          expect(group.value, {'two': 'other value'});
        });

        test('should ignore changes in child values', () {
          expect(group.value, {'one': 'some value', 'two': 'other value'});
          group.markAsDisabled();
          expect(group.value, {'one': 'some value', 'two': 'other value'});
          control.updateValue('new value');
          expect(group.disabled, true);
          expect(group.value, {'one': 'new value', 'two': 'other value'},
              reason: 'Value changes are propagated when disabled.');
          group.markAsEnabled();
          expect(group.value, {'one': 'new value', 'two': 'other value'});
        });

        test('should update children', () {
          expect(control.disabled, false);
          group.markAsDisabled();
          expect(control.disabled, true);
          group.markAsEnabled();
          expect(control.disabled, false);
        });

        test('should update nested children', () {
          var childControl = Control();
          group.addControl('nested', ControlGroup({'child': childControl}));
          group.markAsDisabled();
          expect(childControl.disabled, true);
          group.markAsEnabled();
          expect(childControl.disabled, false);
        });

        test('should handle empty ControlGroup', () {
          var emptyGroup = ControlGroup({});
          expect(emptyGroup.disabled, false);
          emptyGroup.markAsDisabled();
          expect(emptyGroup.disabled, true);
          emptyGroup.markAsEnabled();
          expect(emptyGroup.disabled, false);
        });
      });

      group('reset', () {
        Control control;

        setUp(() {
          control = Control();
        });

        test('should reset value', () {
          control.updateValue('some value');
          expect(control.value, 'some value');
          control.reset();
          expect(control.value, null);
        });

        test('should reset pristine', () {
          control.markAsDirty();
          expect(control.dirty, true);
          control.reset();
          expect(control.dirty, false);
        });

        test('should reset touched', () {
          control.markAsTouched();
          expect(control.touched, true);
          control.reset();
          expect(control.touched, false);
        });

        test('should not reset disabled state', () {
          control.markAsDisabled();
          expect(control.disabled, true);
          control.reset();
          expect(control.disabled, true);
        });

        test('should not reset enabled state', () {
          control.markAsEnabled();
          expect(control.enabled, true);
          control.reset();
          expect(control.enabled, true);
        });

        test('should allow setting value', () {
          control.reset(value: 'some value');
          expect(control.value, 'some value');
        });

        test('should allow setting disabled state', () {
          control.reset(isDisabled: true);
          expect(control.disabled, true);
        });

        test('should allow setting disabled state when disabled', () {
          control.markAsDisabled();
          control.reset(isDisabled: true);
          expect(control.disabled, true);
        });

        test('should allow setting enabled state when disabled', () {
          control.markAsDisabled();
          control.reset(isDisabled: false);
          expect(control.disabled, false);
        });
      });
    });

    group('ControlArray', () {
      group('adding/removing', () {
        ControlArray a;
        var c1, c2, c3;
        setUp(() {
          a = ControlArray([]);
          c1 = Control(1);
          c2 = Control(2);
          c3 = Control(3);
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
          var a = ControlArray([Control(1), Control(2)]);
          expect(a.value, [1, 2]);
        });
        test('should be an empty array when there are no child controls', () {
          var a = ControlArray([]);
          expect(a.value, []);
        });
      });

      group('updateValue', () {
        Control control;
        ControlArray array;

        setUp(() {
          control = Control('oldValue');
          array = ControlArray([control]);
        });

        test('should update the value of the group', () {
          array.updateValue(['newValue']);
          expect(array.value, ['newValue']);
        });

        test('should update the value of the child control', () {
          array.updateValue(['newValue']);
          expect(control.value, 'newValue');
        });

        test('should "reset" the values with an empty list', () {
          array.updateValue([]);
          expect(array.value, [null]);
          expect(control.value, null);
        });

        test('should "reset" the values with a null list', () {
          array.updateValue(null);
          expect(array.value, [null]);
          expect(control.value, null);
        });

        test('should throw if wrong length', () {
          expect(() => array.updateValue(['one', 'two']), throwsArgumentError);
          array.push(Control('two'));
          expect(() => array.updateValue(['one']), throwsArgumentError);
        });
      });

      group('errors', () {
        test('should run the validator when the value changes', () {
          Map<String, dynamic> simpleValidator(c) =>
              c.controls[0].value != 'correct' ? {'broken': true} : null;
          var c = Control<String>(null);
          var g = ControlArray([c], simpleValidator);
          c.updateValue('correct');
          expect(g.valid, true);
          expect(g.errors, isNull);
          c.updateValue('incorrect');
          expect(g.valid, false);
          expect(g.errors, {'broken': true});
        });
      });
      group('dirty', () {
        Control control;
        ControlArray array;
        setUp(() {
          control = Control('value');
          array = ControlArray([control]);
        });
        test('should be false after creating a control', () {
          expect(array.dirty, false);
        });
        test('should be false after changing the value of the control', () {
          control.markAsDirty();
          expect(array.dirty, true);
        });

        test('setting pristine should update control', () {
          control.markAsDirty();
          array.markAsPristine();
          expect(control.dirty, false);
        });

        test('should derive value from children', () {
          var otherControl = Control('new value');
          array.push(otherControl);

          //Make only one control dirty.
          control.markAsDirty();
          expect(array.dirty, true);

          // Make *both* controls dirty, then pristine only one.
          otherControl.markAsDirty();
          otherControl.markAsPristine();
          expect(array.dirty, true);

          // Now, make *both* controls pristine.
          control.markAsPristine();
          expect(array.dirty, false);
        });
      });

      group('touched', () {
        Control control;
        ControlArray array;

        setUp(() {
          control = Control('value');
          array = ControlArray([control]);
        });

        test('should be false after creating a control', () {
          expect(array.touched, false);
        });

        test('should be true after changing the value of the control', () {
          control.markAsTouched();
          expect(array.touched, true);
        });

        test('setting untouced should update control', () {
          control.markAsTouched();
          array.markAsUntouched();
          expect(control.touched, false);
        });

        test('should derive value from children', () {
          var otherControl = Control('new value');
          array.push(otherControl);

          // Make only one control touched.
          control.markAsTouched();
          expect(array.touched, true);

          // Make *both* controls touched, then untouch only one.
          otherControl.markAsTouched();
          otherControl.markAsUntouched();
          expect(array.touched, true);

          // Now, untouch the second one.
          control.markAsUntouched();
          expect(array.touched, false);
        });
      });

      group('pending', () {
        Control c;
        ControlArray a;
        setUp(() {
          c = Control('value');
          a = ControlArray([c]);
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
          c1 = Control('old1');
          c2 = Control('old2');
          a = ControlArray([c1, c2]);
        });
        test('should fire an event after the value has been updated', () async {
          a.valueChanges.listen(expectAsync1((value) {
            expect(a.value, ['new1', 'old2']);
            expect(value, ['new1', 'old2']);
          }));
          c1.updateValue('new1');
        });
        test(
            'should fire an event after the control\'s observable '
            'fired an event', () async {
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
      group('findPath', () {
        test('should return null when path is null', () {
          var g = ControlGroup({});
          expect(g.findPath(null), null);
        });
        test('should return null when path is empty', () {
          var g = ControlGroup({});
          expect(g.findPath([]), null);
        });
        test('should return null when path is invalid', () {
          var g = ControlGroup({});
          expect(g.findPath(['one', 'two']), null);
        });
        test('should return a child of a control group', () {
          var g = ControlGroup({
            'one': Control('111'),
            'nested': ControlGroup({'two': Control('222')})
          });
          expect(g.findPath(['nested', 'two']).value, '222');
          expect(g.findPath(['one']).value, '111');
          expect(g.find('nested/two').value, '222');
          expect(g.find('one').value, '111');
        });
        test('should return an element of an array', () {
          var g = ControlGroup({
            'array': ControlArray([Control('111')])
          });
          expect(g.findPath(['array', '0']).value, '111');
        });
      });

      group('disabled', () {
        Control control;
        ControlArray array;

        setUp(() {
          control = Control('some value');
          array = ControlArray([control, Control('other value')]);
        });

        test('should update status', () {
          expect(array.disabled, false);
          array.markAsDisabled();
          expect(array.disabled, true);
          array.markAsEnabled();
          expect(array.disabled, false);
        });

        test('should ignore values from disabled children', () {
          expect(array.value, ['some value', 'other value']);
          control.markAsDisabled();
          expect(array.value, ['other value']);
        });

        test('should ignore changes in child values', () {
          expect(array.value, ['some value', 'other value']);
          array.markAsDisabled();
          expect(array.value, ['some value', 'other value']);
          control.updateValue('new value');
          expect(array.disabled, true);
          expect(array.value, ['new value', 'other value'],
              reason: 'Value changes are propagated when disabled.');
          array.markAsEnabled();
          expect(array.value, ['new value', 'other value']);
        });

        test('should update children', () {
          expect(control.disabled, false);
          array.markAsDisabled();
          expect(control.disabled, true);
          array.markAsEnabled();
          expect(control.disabled, false);
        });

        test('should handle empty array', () {
          var emptyArray = ControlArray([]);
          expect(emptyArray.disabled, false);
          emptyArray.markAsDisabled();
          expect(emptyArray.disabled, true);
          emptyArray.markAsEnabled();
          expect(emptyArray.disabled, false);
        });
      });

      group('reset', () {
        Control control;

        setUp(() {
          control = Control();
        });

        test('should reset value', () {
          control.updateValue('some value');
          expect(control.value, 'some value');
          control.reset();
          expect(control.value, null);
        });

        test('should reset pristine', () {
          control.markAsDirty();
          expect(control.dirty, true);
          control.reset();
          expect(control.dirty, false);
        });

        test('should reset touched', () {
          control.markAsTouched();
          expect(control.touched, true);
          control.reset();
          expect(control.touched, false);
        });

        test('should not reset disabled state', () {
          control.markAsDisabled();
          expect(control.disabled, true);
          control.reset();
          expect(control.disabled, true);
        });

        test('should not reset enabled state', () {
          control.markAsEnabled();
          expect(control.enabled, true);
          control.reset();
          expect(control.enabled, true);
        });

        test('should allow setting value', () {
          control.reset(value: 'some value');
          expect(control.value, 'some value');
        });

        test('should allow setting disabled state', () {
          control.reset(isDisabled: true);
          expect(control.disabled, true);
        });

        test('should allow setting disabled state when disabled', () {
          control.markAsDisabled();
          control.reset(isDisabled: true);
          expect(control.disabled, true);
        });

        test('should allow setting enabled state when disabled', () {
          control.markAsDisabled();
          control.reset(isDisabled: false);
          expect(control.disabled, false);
        });
      });
    });
  });
}
