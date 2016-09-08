import "package:angular2/core.dart"
    show
        OnChanges,
        OnDestroy,
        SimpleChange,
        Directive,
        SkipSelf,
        Provider,
        Inject,
        Optional,
        Self;
import "package:angular2/src/facade/async.dart" show EventEmitter;

import "../model.dart" show Control;
import "../validators.dart" show NG_VALIDATORS, NG_ASYNC_VALIDATORS;
import "control_container.dart" show ControlContainer;
import "control_value_accessor.dart"
    show ControlValueAccessor, NG_VALUE_ACCESSOR;
import "ng_control.dart" show NgControl;
import "shared.dart"
    show
        controlPath,
        composeValidators,
        composeAsyncValidators,
        isPropertyUpdated,
        selectValueAccessor;
import "validators.dart" show ValidatorFn, AsyncValidatorFn;

const controlNameBinding =
    const Provider(NgControl, useExisting: NgControlName);

/// Creates and binds a control with a specified name to a DOM element.
///
/// This directive can only be used as a child of [NgForm] or [NgFormModel].

/// ### Example
///
/// In this example, we create the login and password controls.
/// We can work with each control separately: check its validity, get its value, listen to its
/// changes.
///
/// ```dart
/// @Component(
///      selector: "login-comp",
///      directives: const [FORM_DIRECTIVES],
///      template: '''
///        <form #f="ngForm" (submit)='onLogIn(f.value)'>
///          Login <input type='text' ngControl='login' #l="form">
///          <div *ngIf="!l.valid">Login is invalid</div>
///
///          Password <input type='password' ngControl='password'>
///          <button type='submit'>Log in!</button>
///        </form>
///      ''')
/// class LoginComp {
///  void onLogIn(value) {
///    // value === {'login': 'some login', 'password': 'some password'}
///  }
/// }
/// ```
///
/// We can also use ngModel to bind a domain model to the form.
///
/// ```dart
/// @Component(
///      selector: "login-comp",
///      directives: [FORM_DIRECTIVES],
///      template: '''
///        <form (submit)='onLogIn()'>
///          Login <input type='text' ngControl='login' [(ngModel)]="credentials.login">
///          Password <input type='password' ngControl='password'
///                          [(ngModel)]="credentials.password">
///          <button type='submit'>Log in!</button>
///        </form>
///      ''')
/// class LoginComp {
///  credentials: {login:string, password:string};
///
///  onLogIn(): void {
///    // this.credentials.login === "some login"
///    // this.credentials.password === "some password"
///  }
/// }
/// ```
@Directive(
    selector: "[ngControl]",
    providers: const [controlNameBinding],
    inputs: const ["name: ngControl", "model: ngModel"],
    outputs: const ["update: ngModelChange"],
    exportAs: "ngForm")
class NgControlName extends NgControl implements OnChanges, OnDestroy {
  ControlContainer _parent;
  /* Array<Validator|Function> */ List<dynamic> _validators;
  /* Array<Validator|Function> */ List<dynamic> _asyncValidators;
  var update = new EventEmitter();
  dynamic model;
  dynamic viewModel;
  var _added = false;
  NgControlName(
      @SkipSelf()
          this._parent,
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
  ngOnChanges(Map<String, SimpleChange> changes) {
    if (!this._added) {
      this.formDirective.addControl(this);
      this._added = true;
    }
    if (isPropertyUpdated(changes, this.viewModel)) {
      this.viewModel = this.model;
      this.formDirective.updateModel(this, this.model);
    }
  }

  void ngOnDestroy() {
    this.formDirective.removeControl(this);
  }

  void viewToModelUpdate(dynamic newValue) {
    this.viewModel = newValue;
    this.update.add(newValue);
  }

  List<String> get path {
    return controlPath(this.name, this._parent);
  }

  dynamic get formDirective {
    return this._parent.formDirective;
  }

  ValidatorFn get validator {
    return composeValidators(this._validators);
  }

  AsyncValidatorFn get asyncValidator {
    return composeAsyncValidators(this._asyncValidators);
  }

  Control get control {
    return this.formDirective.getControl(this);
  }
}
