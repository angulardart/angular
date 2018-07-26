import 'directives/validators.dart';
import 'model.dart' as model_module;

/// Creates a form object from a user-specified configuration.
///
/// ```dart
/// @Component(
///   selector: 'my-app',
///   viewProviders: const [FORM_BINDINGS]
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
///   directives: const [formDirectives]
/// )
/// class App {
///   ControlGroup loginForm;
///
///   App() {
///     final builder = new FormBuilder();
///     loginForm = builder.group({
///       "login": ["", Validators.required],
///       "passwordRetry": builder.group({
///         "password": ["", Validators.required],
///         "passwordConfirmation": ["", Validators.required]
///       })
///     });
///   }
///
///   String get value {
///     return JSON.encode(loginForm.value);
///   }
/// }
/// ```
class FormBuilder {
  /// Construct a new [ControlGroup] with the given map of configuration.
  /// Valid keys for the `extra` parameter map are [optionals] and [validator].
  ///
  /// See the [ControlGroup] constructor for more details.
  static model_module.ControlGroup controlGroup(
      Map<String, dynamic> controlsConfig,
      {ValidatorFn validator}) {
    var controls = _reduceControls(controlsConfig);
    return model_module.ControlGroup(controls, validator);
  }

  /// Construct an array of [Control]s from the given [controlsConfig] array of
  /// configuration, with the given optional [validator].
  static model_module.ControlArray controlArray(List<dynamic> controlsConfig,
      [ValidatorFn validator]) {
    var controls = controlsConfig.map(_createControl).toList();
    return model_module.ControlArray(controls, validator);
  }

  static Map<String, model_module.AbstractControl> _reduceControls(
          Map<String, dynamic> controlsConfig) =>
      controlsConfig.map((controlName, controlConfig) =>
          MapEntry(controlName, _createControl(controlConfig)));

  static model_module.AbstractControl _createControl(dynamic controlConfig) {
    if (controlConfig is model_module.AbstractControl) {
      return controlConfig;
    } else if (controlConfig is List) {
      var value = controlConfig[0];
      ValidatorFn validator =
          controlConfig.length > 1 ? controlConfig[1] as ValidatorFn : null;
      return model_module.Control(value, validator);
    } else {
      return model_module.Control(controlConfig, null);
    }
  }

  // Prevents instantiating this class.
  FormBuilder._();
}
