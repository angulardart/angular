import 'directives/checkbox_value_accessor.dart'
    show CheckboxControlValueAccessor;
import 'directives/default_value_accessor.dart' show DefaultValueAccessor;
import 'directives/ng_control_group.dart' show NgControlGroup;
import 'directives/ng_control_name.dart' show NgControlName;
import 'directives/ng_form.dart' show NgForm;
import 'directives/ng_form_control.dart' show NgFormControl;
import 'directives/ng_form_model.dart' show NgFormModel;
import 'directives/ng_model.dart' show NgModel;
import 'directives/number_value_accessor.dart' show NumberValueAccessor;
import 'directives/radio_control_value_accessor.dart'
    show RadioControlValueAccessor;
import 'directives/select_control_value_accessor.dart'
    show SelectControlValueAccessor, NgSelectOption;
import 'directives/validators.dart'
    show
        RequiredValidator,
        MinLengthValidator,
        MaxLengthValidator,
        PatternValidator;

export 'directives/checkbox_value_accessor.dart'
    show CheckboxControlValueAccessor;
export 'directives/control_value_accessor.dart' show ControlValueAccessor;
export 'directives/default_value_accessor.dart' show DefaultValueAccessor;
export 'directives/ng_control.dart' show NgControl;
export 'directives/ng_control_group.dart' show NgControlGroup;
export 'directives/ng_control_name.dart' show NgControlName;
export 'directives/ng_control_status.dart' show NgControlStatus;
export 'directives/ng_form.dart' show NgForm;
export 'directives/ng_form_control.dart' show NgFormControl;
export 'directives/ng_form_model.dart' show NgFormModel;
export 'directives/ng_model.dart' show NgModel;
export 'directives/number_value_accessor.dart' show NumberValueAccessor;
export 'directives/radio_control_value_accessor.dart'
    show RadioControlValueAccessor, RadioButtonState;
export 'directives/select_control_value_accessor.dart'
    show SelectControlValueAccessor, NgSelectOption;
export 'directives/validators.dart'
    show
        RequiredValidator,
        MinLengthValidator,
        MaxLengthValidator,
        PatternValidator;

/// A list of all the form directives used as part of a `@Component` annotation.
///
///  This is a shorthand for importing them each individually.
///
/// ### Example
///
/// ```dart
/// @Component(
///   selector: 'my-app',
///   directives: const [formDirectives]
/// )
/// class MyApp {}
/// ```
const List<Type> formDirectives = const [
  NgControlName,
  NgControlGroup,
  NgFormControl,
  NgModel,
  NgFormModel,
  NgForm,
  NgSelectOption,
  DefaultValueAccessor,
  NumberValueAccessor,
  CheckboxControlValueAccessor,
  SelectControlValueAccessor,
  RadioControlValueAccessor,
  RequiredValidator,
  MinLengthValidator,
  MaxLengthValidator,
  PatternValidator
];
