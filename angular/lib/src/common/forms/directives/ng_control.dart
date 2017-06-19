import 'abstract_control_directive.dart' show AbstractControlDirective;
import 'control_value_accessor.dart' show ControlValueAccessor;
import 'validators.dart' show ValidatorFn;

/// A base class that all control directive extend.
/// It binds a [Control] object to a DOM element.
///
/// Used internally by Angular forms.
abstract class NgControl extends AbstractControlDirective {
  String name;
  ControlValueAccessor valueAccessor;
  ValidatorFn get validator;

  void viewToModelUpdate(dynamic newValue);
}
