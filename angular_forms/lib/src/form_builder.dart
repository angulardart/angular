import 'package:angular/angular.dart' show Injectable;

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
@Injectable()
class FormBuilder {
  /// Construct a new [ControlGroup] with the given map of configuration.
  /// Valid keys for the `extra` parameter map are [optionals] and [validator].
  ///
  /// See the [ControlGroup] constructor for more details.
  model_module.ControlGroup group(Map<String, dynamic> controlsConfig,
      [Map<String, dynamic> extra]) {
    var controls = _reduceControls(controlsConfig);
    var optionals =
        ((extra != null ? extra['optionals'] : null) as Map<String, bool>);
    ValidatorFn validator =
        extra != null ? extra['validator'] as ValidatorFn : null;
    return new model_module.ControlGroup(controls, optionals, validator);
  }

  /// Construct a new [Control] with the given [value], and [validator].
  model_module.Control control(Object value, [ValidatorFn validator]) {
    return new model_module.Control(value, validator);
  }

  /// Construct an array of [Control]s from the given [controlsConfig] array of
  /// configuration, with the given optional [validator].
  model_module.ControlArray array(List<dynamic> controlsConfig,
      [ValidatorFn validator]) {
    var controls = controlsConfig.map((c) => _createControl(c)).toList();
    return new model_module.ControlArray(controls, validator);
  }

  Map<String, model_module.AbstractControl> _reduceControls(
      Map<String, dynamic> controlsConfig) {
    Map<String, model_module.AbstractControl> controls = {};
    controlsConfig.forEach((String controlName, dynamic controlConfig) {
      controls[controlName] = _createControl(controlConfig);
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
      return control(value, validator);
    } else {
      return control(controlConfig);
    }
  }
}
