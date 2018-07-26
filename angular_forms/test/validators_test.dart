@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular_forms/angular_forms.dart';

void main() {
  var validator = (String key, dynamic error) {
    return (AbstractControl c) {
      var r = <String, dynamic>{};
      r[key] = error;
      return r;
    };
  };

  group('Validators', () {
    group('required', () {
      test('should error on an empty string', () {
        expect(Validators.required(Control('')), {'required': true});
      });
      test('should error on null', () {
        expect(Validators.required(Control(null)), {'required': true});
      });
      test('should not error on a non-empty string', () {
        expect(Validators.required(Control('not empty')), isNull);
      });
      test('should accept zero as valid', () {
        expect(Validators.required(Control(0)), isNull);
      });
    });
    group('minLength', () {
      test('should not error on an empty string', () {
        expect(Validators.minLength(2)(Control('')), isNull);
      });
      test('should not error on null', () {
        expect(Validators.minLength(2)(Control(null)), isNull);
      });
      test('should not error on valid strings', () {
        expect(Validators.minLength(2)(Control('aa')), isNull);
      });
      test('should error on short strings', () {
        expect(Validators.minLength(2)(Control('a')), {
          'minlength': {'requiredLength': 2, 'actualLength': 1}
        });
      });
    });
    group('maxLength', () {
      test('should not error on an empty string', () {
        expect(Validators.maxLength(2)(Control('')), isNull);
      });
      test('should not error on null', () {
        expect(Validators.maxLength(2)(Control(null)), isNull);
      });
      test('should not error on valid strings', () {
        expect(Validators.maxLength(2)(Control('aa')), isNull);
      });
      test('should error on long strings', () {
        expect(Validators.maxLength(2)(Control('aaa')), {
          'maxlength': {'requiredLength': 2, 'actualLength': 3}
        });
      });
    });
    group('pattern', () {
      test('should not error on an empty string', () {
        expect(Validators.pattern('[a-zA-Z ]*')(Control('')), isNull);
      });
      test('should not error on null', () {
        expect(Validators.pattern('[a-zA-Z ]*')(Control(null)), isNull);
      });
      test('should not error on valid strings', () {
        expect(Validators.pattern('[a-zA-Z ]*')(Control('aaAA')), isNull);
      });
      test('should error on failure to match string', () {
        expect(Validators.pattern('[a-zA-Z ]*')(Control('aaa0')), {
          'pattern': {'requiredPattern': '^[a-zA-Z ]*\$', 'actualValue': 'aaa0'}
        });
      });
    });
    group('compose', () {
      test('should return null when given null', () {
        expect(Validators.compose(null), isNull);
      });
      test('should collect errors from all the validators', () {
        var c =
            Validators.compose([validator('a', true), validator('b', true)]);
        expect(c(Control('')), {'a': true, 'b': true});
      });
      test('should run validators left to right', () {
        var c = Validators.compose([validator('a', 1), validator('a', 2)]);
        expect(c(Control('')), {'a': 2});
      });
      test('should return null when no errors', () {
        var c = Validators.compose(
            [Validators.nullValidator, Validators.nullValidator]);
        expect(c(Control('')), null);
      });
      test('should ignore nulls', () {
        var c = Validators.compose([null, Validators.required]);
        expect(c(Control('')), {'required': true});
      });
    });
  });
}
