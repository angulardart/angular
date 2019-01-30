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

export 'src/directives.dart'
    show
        composeValidators,
        setUpControl,
        setUpControlGroup,
        formDirectives,
        AbstractControlDirective,
        AbstractNgForm,
        ChangeFunction,
        CheckboxControlValueAccessor,
        ControlContainer,
        ControlValueAccessor,
        DefaultValueAccessor,
        Form,
        MaxLengthValidator,
        MemorizedForm,
        MinLengthValidator,
        NgControl,
        NgControlGroup,
        NgControlName,
        NgControlStatus,
        NgForm,
        NgFormControl,
        NgFormModel,
        NgModel,
        NgSelectOption,
        ngValueAccessor,
        NumberValueAccessor,
        PatternValidator,
        RadioControlValueAccessor,
        RadioButtonState,
        RequiredValidator,
        SelectControlValueAccessor,
        TouchFunction,
        Validator,
        ValidatorFn;
export 'src/form_builder.dart' show FormBuilder;
export 'src/model.dart'
    show
        AbstractControl,
        Control,
        AbstractControlGroup,
        ControlGroup,
        ControlArray;
export 'src/validators.dart' show NG_VALIDATORS, Validators;

/// Shorthand set of providers used for building Angular forms.
///
/// ### Example
///
/// ```dart
/// bootstrap(MyApp, [FORM_PROVIDERS]);
/// ````
const List<Type> FORM_PROVIDERS = [RadioControlRegistry];

/// See [FORM_PROVIDERS] instead.
const FORM_BINDINGS = FORM_PROVIDERS;
