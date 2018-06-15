@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular_forms/angular_forms.dart';

Map<String, dynamic> _syncValidator(AbstractControl c) {
  return null;
}

void main() {
  group('Form Builder', () {
    test('should create controls from a value', () {
      var group = FormBuilder.controlGroup({'login': 'some value'});
      expect(group.controls['login'].value, 'some value');
    });
    test('should create controls from an array', () {
      var group = FormBuilder.controlGroup({
        'login': ['some value'],
        'password': ['some value', _syncValidator]
      });
      expect(group.controls['login'].value, 'some value');
      expect(group.controls['password'].value, 'some value');
      expect(group.controls['password'].validator == _syncValidator, true);
    });
    test('should use controls', () {
      var group = FormBuilder.controlGroup(
          {'login': Control('some value', _syncValidator)});
      expect(group.controls['login'].value, 'some value');
      expect(group.controls['login'].validator == _syncValidator, true);
    });
    test('should create groups with a custom validator', () {
      var group = FormBuilder.controlGroup({'login': 'some value'},
          validator: _syncValidator);
      expect(group.validator == _syncValidator, true);
    });
    test('should create control arrays', () {
      var control = Control('three');
      var array = FormBuilder.controlArray([
        'one',
        ['two', _syncValidator],
        control,
        FormBuilder.controlArray(['four'])
      ], _syncValidator);
      expect(array.value, [
        'one',
        'two',
        'three',
        ['four']
      ]);
      expect(array.validator == _syncValidator, true);
    });
  });
}
