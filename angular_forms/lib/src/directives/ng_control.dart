import '../model.dart' show Control;
import 'abstract_control_directive.dart' show AbstractControlDirective;
import 'control_value_accessor.dart' show ControlValueAccessor;
import 'shared.dart' show composeValidators, selectValueAccessor;
import 'validators.dart' show ValidatorFn;

/// A base class that all control directive extend.
/// It binds a [Control] object to a DOM element.
///
/// Used internally by Angular forms.
abstract class NgControl extends AbstractControlDirective<Control> {
  ControlValueAccessor<dynamic>? valueAccessor;

  final ValidatorFn? validator;

  void viewToModelUpdate(dynamic newValue);

  /// Updates from the view itself.
  ///
  /// Equivalent to the ngModelChange Output.
  Stream<dynamic> get update;

  NgControl(
    List<ControlValueAccessor<dynamic>>? valueAccessors,
    List<dynamic>? validators,
  )   : valueAccessor = selectValueAccessor(valueAccessors),
        validator = composeValidators(validators);
}
