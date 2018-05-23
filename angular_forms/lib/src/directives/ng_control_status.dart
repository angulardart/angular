import 'package:angular/angular.dart';

import 'ng_control.dart' show NgControl;

/// Directive automatically applied to Angular forms that sets CSS classes
/// based on control status (valid/invalid/dirty/etc).
@Directive(
  selector: '[ngControl],[ngModel],[ngFormControl]',
)
@Deprecated('Use listeners or variable binding on the control itself instead. '
    'This adds overhead for every form control whether the class is '
    'used or not.')
class NgControlStatus {
  final NgControl _cd;
  NgControlStatus(@Self() this._cd);

  @HostBinding('class.ng-untouched')
  bool get ngClassUntouched =>
      _cd.control != null ? _cd.control.untouched : false;

  @HostBinding('class.ng-touched')
  bool get ngClassTouched => _cd.control != null ? _cd.control.touched : false;

  @HostBinding('class.ng-pristine')
  bool get ngClassPristine =>
      _cd.control != null ? _cd.control.pristine : false;

  @HostBinding('class.ng-dirty')
  bool get ngClassDirty => _cd.control != null ? _cd.control.dirty : false;

  @HostBinding('class.ng-valid')
  bool get ngClassValid => _cd.control != null ? _cd.control.valid : false;

  @HostBinding('class.ng-invalid')
  bool get ngClassInvalid => _cd.control != null ? !_cd.control.valid : false;
}
