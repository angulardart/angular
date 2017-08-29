/// This module is used for handling user input, by defining and building a
/// [ControlGroup] that consists of [Control] objects, and mapping them onto
/// the DOM. [Control] objects can then be used to read information from the
/// form DOM elements.
///
/// This module is not included in the `angular` module; you must import the
/// forms module explicitly.
library angular_forms; // name the library so we can run dartdoc on it by name.

import 'src/directives/radio_control_value_accessor.dart'
    show RadioControlRegistry;
import 'src/form_builder.dart' show FormBuilder;

export 'src/directives.dart' show formDirectives, RadioButtonState;
export 'src/directives/abstract_control_directive.dart'
    show AbstractControlDirective;
export 'src/directives/checkbox_value_accessor.dart'
    show CheckboxControlValueAccessor;
export 'src/directives/control_container.dart' show ControlContainer;
export 'src/directives/control_value_accessor.dart'
    show ControlValueAccessor, TouchFunction, ChangeFunction, NG_VALUE_ACCESSOR;
export 'src/directives/default_value_accessor.dart' show DefaultValueAccessor;
export 'src/directives/form_interface.dart' show Form;
export 'src/directives/ng_control.dart' show NgControl;
export 'src/directives/ng_control_group.dart' show NgControlGroup;
export 'src/directives/ng_control_name.dart' show NgControlName;
export 'src/directives/ng_control_status.dart' show NgControlStatus;
export 'src/directives/ng_form.dart' show NgForm;
export 'src/directives/ng_form_control.dart' show NgFormControl;
export 'src/directives/ng_form_model.dart' show NgFormModel;
export 'src/directives/ng_model.dart' show NgModel;
export 'src/directives/select_control_value_accessor.dart'
    show NgSelectOption, SelectControlValueAccessor;
export 'src/directives/shared.dart'
    show composeValidators, setUpControlGroup, setUpControl;
export 'src/directives/validators.dart'
    show
        RequiredValidator,
        MinLengthValidator,
        MaxLengthValidator,
        PatternValidator,
        Validator,
        ValidatorFn;
export 'src/form_builder.dart' show FormBuilder;
export 'src/model.dart'
    show AbstractControl, Control, ControlGroup, ControlArray;
export 'src/validators.dart' show NG_VALIDATORS, Validators;

/// Shorthand set of providers used for building Angular forms.
///
/// ### Example
///
/// ```dart
/// bootstrap(MyApp, [FORM_PROVIDERS]);
/// ````
const List<Type> FORM_PROVIDERS = const [FormBuilder, RadioControlRegistry];

/// See [FORM_PROVIDERS] instead.
const FORM_BINDINGS = FORM_PROVIDERS;
