import "package:angular2/di.dart" show Injectable;

import "directives/validators.dart";
import "model.dart" as model_module;

/// Creates a form object from a user-specified configuration.
///
/// ```dart
/// @Component(
///   selector: 'my-app',
///   viewBindings: const [FORM_BINDINGS]
///   template: '''
///     <form [ngFormModel]="loginForm">
///       <p>Login <input ngControl="login"></p>
///       <div ngControlGroup="passwordRetry">
///         <p>Password <input type="password" ngControl="password"></p>
///         <p>Confirm password <input type="password"
///            ngControl="passwordConfirmation"></p>
///       </div>
///     </form>
///     <h3>Form value:</h3>
///     <pre>{{value}}</pre>
///   ''',
///   directives: const [FORM_DIRECTIVES]
/// )
/// class App {
///   ControlGroup loginForm;
///
///   App(FormBuilder builder) {
///     this.loginForm = builder.group({
///       "login": ["", Validators.required],
///       "passwordRetry": builder.group({
///         "password": ["", Validators.required],
///         "passwordConfirmation": ["", Validators.required, asyncValidator]
///       })
///     });
///   }
///
///   String get value {
///     return JSON.encode(this.loginForm.value);
///   }
/// }
/// ```
@Injectable()
class FormBuilder {
  /// Construct a new [ControlGroup] with the given map of configuration.
  /// Valid keys for the `extra` parameter map are [optionals] and [validator].
  ///
  /// See the [ControlGroup] constructor for more details.
  model_module.ControlGroup group(Map<String, dynamic> controlsConfig,
      [Map<String, dynamic> extra = null]) {
    var controls = this._reduceControls(controlsConfig);
    var optionals =
        ((extra != null ? extra['optionals'] : null) as Map<String, bool>);
    ValidatorFn validator =
        extra != null ? extra['validator'] as ValidatorFn : null;
    AsyncValidatorFn asyncValidator =
        extra != null ? extra['asyncValidator'] as AsyncValidatorFn : null;
    return new model_module.ControlGroup(
        controls, optionals, validator, asyncValidator);
  }

  /// Construct a new [Control] with the given [value], [validator], and
  /// [asyncValidator].
  model_module.Control control(Object value,
      [ValidatorFn validator = null, AsyncValidatorFn asyncValidator = null]) {
    return new model_module.Control(value, validator, asyncValidator);
  }

  /// Construct an array of [Control]s from the given [controlsConfig] array of
  /// configuration, with the given optional [validator] and [asyncValidator].
  model_module.ControlArray array(List<dynamic> controlsConfig,
      [ValidatorFn validator = null, AsyncValidatorFn asyncValidator = null]) {
    var controls = controlsConfig.map((c) => this._createControl(c)).toList();
    return new model_module.ControlArray(controls, validator, asyncValidator);
  }

  Map<String, model_module.AbstractControl> _reduceControls(
      Map<String, dynamic> controlsConfig) {
    Map<String, model_module.AbstractControl> controls = {};
    controlsConfig.forEach((String controlName, dynamic controlConfig) {
      controls[controlName] = this._createControl(controlConfig);
    });
    return controls;
  }

  model_module.AbstractControl _createControl(dynamic controlConfig) {
    if (controlConfig is model_module.Control ||
        controlConfig is model_module.ControlGroup ||
        controlConfig is model_module.ControlArray) {
      return controlConfig;
    } else if (controlConfig is List) {
      var value = controlConfig[0];
      ValidatorFn validator =
          controlConfig.length > 1 ? controlConfig[1] as ValidatorFn : null;
      AsyncValidatorFn asyncValidator = controlConfig.length > 2
          ? controlConfig[2] as AsyncValidatorFn
          : null;
      return this.control(value, validator, asyncValidator);
    } else {
      return this.control(controlConfig);
    }
  }
}
