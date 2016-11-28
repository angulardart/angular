import "package:angular2/core.dart"
    show OnChanges, SimpleChange, Directive, Provider, Inject, Optional, Self;
import "package:angular2/src/facade/async.dart" show EventEmitter;

import "../model.dart" show Control;
import "../validators.dart" show NG_VALIDATORS, NG_ASYNC_VALIDATORS;
import "control_value_accessor.dart"
    show ControlValueAccessor, NG_VALUE_ACCESSOR;
import "ng_control.dart" show NgControl;
import "shared.dart"
    show
        setUpControl,
        composeValidators,
        composeAsyncValidators,
        isPropertyUpdated,
        selectValueAccessor;
import "validators.dart" show ValidatorFn, AsyncValidatorFn;

const formControlBinding =
    const Provider(NgControl, useExisting: NgFormControl);

/// Binds an existing [Control] to a DOM element.
///
/// ### Example
///
/// In this example, we bind the control to an input element. When the value of the input element
/// changes, the value of the control will reflect that change. Likewise, if the value of the
/// control changes, the input element reflects that change.
///
/// ```dart
/// @Component(
///   selector: 'my-app',
///   template: '''
///     <div>
///       <h2>NgFormControl Example</h2>
///       <form>
///         <p>Element with existing control:
///           <input type="text" [ngFormControl]="loginControl">
///         </p>
///         <p>Value of existing control: {{loginControl.value}}</p>
///       </form>
///     </div>
///   ''',
///   directives: const [CORE_DIRECTIVES, FORM_DIRECTIVES]
/// )
/// class App {
///   Control loginControl = new Control('');
/// }
/// ```
///
/// ### ngModel
///
/// We can also use `ngModel` to bind a domain model to the form.
///
/// ### Example
///
/// ```dart
/// @Component(
///      selector: "login-comp",
///      directives: const [FORM_DIRECTIVES],
///      template: "<input type='text' [ngFormControl]='loginControl' [(ngModel)]='login'>"
///      )
/// class LoginComp {
///  Control loginControl = new Control('');
///  String login;
/// }
/// ```
@Directive(
    selector: "[ngFormControl]",
    providers: const [formControlBinding],
    inputs: const ["form: ngFormControl", "model: ngModel"],
    outputs: const ["update: ngModelChange"],
    exportAs: "ngForm")
class NgFormControl extends NgControl implements OnChanges {
  /* Array<Validator|Function> */ List<dynamic> _validators;
  /* Array<Validator|Function> */ List<dynamic> _asyncValidators;
  Control form;
  var update = new EventEmitter();
  dynamic model;
  dynamic viewModel;
  NgFormControl(
      @Optional()
      @Self()
      @Inject(NG_VALIDATORS)
          this._validators,
      @Optional()
      @Self()
      @Inject(NG_ASYNC_VALIDATORS)
          this._asyncValidators,
      @Optional()
      @Self()
      @Inject(NG_VALUE_ACCESSOR)
          List<ControlValueAccessor> valueAccessors) {
    this.valueAccessor = selectValueAccessor(this, valueAccessors);
  }
  @override
  void ngOnChanges(Map<String, SimpleChange> changes) {
    if (this._isControlChanged(changes)) {
      setUpControl(this.form, this);
      this.form.updateValueAndValidity(emitEvent: false);
    }
    if (isPropertyUpdated(changes, this.viewModel)) {
      this.form.updateValue(this.model);
      this.viewModel = this.model;
    }
  }

  @override
  List<String> get path {
    return [];
  }

  @override
  ValidatorFn get validator {
    return composeValidators(this._validators);
  }

  @override
  AsyncValidatorFn get asyncValidator {
    return composeAsyncValidators(this._asyncValidators);
  }

  @override
  Control get control {
    return this.form;
  }

  @override
  void viewToModelUpdate(dynamic newValue) {
    this.viewModel = newValue;
    this.update.add(newValue);
  }

  bool _isControlChanged(Map<String, dynamic> changes) =>
      changes.containsKey('form');
}
