library angular2.src.common.forms.directives.ng_control;

import "control_value_accessor.dart" show ControlValueAccessor;
import "abstract_control_directive.dart" show AbstractControlDirective;
import "package:angular2/src/facade/exceptions.dart" show unimplemented;
import "validators.dart" show AsyncValidatorFn, ValidatorFn;

/**
 * A base class that all control directive extend.
 * It binds a [Control] object to a DOM element.
 *
 * Used internally by Angular forms.
 */
abstract class NgControl extends AbstractControlDirective {
  String name = null;
  ControlValueAccessor valueAccessor = null;
  ValidatorFn get validator {
    return (unimplemented() as ValidatorFn);
  }

  AsyncValidatorFn get asyncValidator {
    return (unimplemented() as AsyncValidatorFn);
  }

  void viewToModelUpdate(dynamic newValue);
}
