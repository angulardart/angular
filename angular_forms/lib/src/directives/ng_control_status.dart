import 'package:angular/angular.dart' show Directive, Self;

import 'ng_control.dart' show NgControl;

/// Directive automatically applied to Angular forms that sets CSS classes
/// based on control status (valid/invalid/dirty/etc).
@Directive(selector: '[ngControl],[ngModel],[ngFormControl]', host: const {
  '[class.ng-untouched]': 'ngClassUntouched',
  '[class.ng-touched]': 'ngClassTouched',
  '[class.ng-pristine]': 'ngClassPristine',
  '[class.ng-dirty]': 'ngClassDirty',
  '[class.ng-valid]': 'ngClassValid',
  '[class.ng-invalid]': 'ngClassInvalid'
})
@Deprecated('Use listeners or variable binding on the control itself instead. '
    'This adds overhead for every form control whether the class is '
    'used or not.')
class NgControlStatus {
  final NgControl _cd;
  NgControlStatus(@Self() this._cd);

  bool get ngClassUntouched =>
      _cd.control != null ? _cd.control.untouched : false;

  bool get ngClassTouched => _cd.control != null ? _cd.control.touched : false;

  bool get ngClassPristine =>
      _cd.control != null ? _cd.control.pristine : false;

  bool get ngClassDirty => _cd.control != null ? _cd.control.dirty : false;

  bool get ngClassValid => _cd.control != null ? _cd.control.valid : false;

  bool get ngClassInvalid => _cd.control != null ? !_cd.control.valid : false;
}
