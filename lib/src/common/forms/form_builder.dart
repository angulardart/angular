library angular2.src.common.forms.form_builder;

import "package:angular2/core.dart" show Injectable;
import "package:angular2/src/facade/collection.dart" show StringMapWrapper;
import "package:angular2/src/facade/lang.dart" show isPresent, isArray, Type;
import "model.dart" as modelModule;
import "directives/validators.dart" show ValidatorFn, AsyncValidatorFn;

/**
 * Creates a form object from a user-specified configuration.
 *
 * ### Example ([live demo](http://plnkr.co/edit/ENgZo8EuIECZNensZCVr?p=preview))
 *
 * ```typescript
 * @Component({
 *   selector: 'my-app',
 *   viewBindings: [FORM_BINDINGS]
 *   template: `
 *     <form [ngFormModel]="loginForm">
 *       <p>Login <input ngControl="login"></p>
 *       <div ngControlGroup="passwordRetry">
 *         <p>Password <input type="password" ngControl="password"></p>
 *         <p>Confirm password <input type="password" ngControl="passwordConfirmation"></p>
 *       </div>
 *     </form>
 *     <h3>Form value:</h3>
 *     <pre>{{value}}</pre>
 *   `,
 *   directives: [FORM_DIRECTIVES]
 * })
 * export class App {
 *   loginForm: ControlGroup;
 *
 *   constructor(builder: FormBuilder) {
 *     this.loginForm = builder.group({
 *       login: ["", Validators.required],
 *       passwordRetry: builder.group({
 *         password: ["", Validators.required],
 *         passwordConfirmation: ["", Validators.required, asyncValidator]
 *       })
 *     });
 *   }
 *
 *   get value(): string {
 *     return JSON.stringify(this.loginForm.value, null, 2);
 *   }
 * }
 * ```
 */
@Injectable()
class FormBuilder {
  /**
   * Construct a new [ControlGroup] with the given map of configuration.
   * Valid keys for the `extra` parameter map are `optionals` and `validator`.
   *
   * See the [ControlGroup] constructor for more details.
   */
  modelModule.ControlGroup group(Map<String, dynamic> controlsConfig,
      [Map<String, dynamic> extra = null]) {
    var controls = this._reduceControls(controlsConfig);
    var optionals = ((isPresent(extra)
        ? StringMapWrapper.get(extra, "optionals")
        : null) as Map<String, bool>);
    ValidatorFn validator =
        isPresent(extra) ? StringMapWrapper.get(extra, "validator") : null;
    AsyncValidatorFn asyncValidator =
        isPresent(extra) ? StringMapWrapper.get(extra, "asyncValidator") : null;
    return new modelModule.ControlGroup(
        controls, optionals, validator, asyncValidator);
  }

  /**
   * Construct a new [Control] with the given `value`,`validator`, and `asyncValidator`.
   */
  modelModule.Control control(Object value,
      [ValidatorFn validator = null, AsyncValidatorFn asyncValidator = null]) {
    return new modelModule.Control(value, validator, asyncValidator);
  }

  /**
   * Construct an array of [Control]s from the given `controlsConfig` array of
   * configuration, with the given optional `validator` and `asyncValidator`.
   */
  modelModule.ControlArray array(List<dynamic> controlsConfig,
      [ValidatorFn validator = null, AsyncValidatorFn asyncValidator = null]) {
    var controls = controlsConfig.map((c) => this._createControl(c)).toList();
    return new modelModule.ControlArray(controls, validator, asyncValidator);
  }

  /** @internal */
  Map<String, modelModule.AbstractControl> _reduceControls(
      Map<String, dynamic> controlsConfig) {
    Map<String, modelModule.AbstractControl> controls = {};
    StringMapWrapper.forEach(controlsConfig,
        (dynamic controlConfig, String controlName) {
      controls[controlName] = this._createControl(controlConfig);
    });
    return controls;
  }

  /** @internal */
  modelModule.AbstractControl _createControl(dynamic controlConfig) {
    if (controlConfig is modelModule.Control ||
        controlConfig is modelModule.ControlGroup ||
        controlConfig is modelModule.ControlArray) {
      return controlConfig;
    } else if (isArray(controlConfig)) {
      var value = controlConfig[0];
      ValidatorFn validator =
          controlConfig.length > 1 ? controlConfig[1] : null;
      AsyncValidatorFn asyncValidator =
          controlConfig.length > 2 ? controlConfig[2] : null;
      return this.control(value, validator, asyncValidator);
    } else {
      return this.control(controlConfig);
    }
  }
}
