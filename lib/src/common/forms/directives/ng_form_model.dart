import 'package:angular2/core.dart'
    show SimpleChange, OnChanges, Directive, Provider, Inject, Optional, Self;
import 'package:angular2/src/facade/async.dart' show EventEmitter;
import 'package:angular2/src/facade/exceptions.dart' show BaseException;

import '../model.dart' show Control, ControlGroup;
import '../validators.dart' show Validators, NG_VALIDATORS, NG_ASYNC_VALIDATORS;
import 'control_container.dart' show ControlContainer;
import 'form_interface.dart' show Form;
import 'ng_control.dart' show NgControl;
import 'ng_control_group.dart';
import 'shared.dart'
    show
        setUpControl,
        setUpControlGroup,
        composeValidators,
        composeAsyncValidators;

const formDirectiveProvider =
    const Provider(ControlContainer, useExisting: NgFormModel);

/// Binds an existing control group to a DOM element.
///
/// ### Example
///
/// In this example, we bind the control group to the form element, and we bind
/// the login and password controls to the login and password elements.
///
/// ```dart
/// @Component(
///   selector: 'my-app',
///   template: '''
///     <div>
///       <h2>NgFormModel Example</h2>
///       <form [ngFormModel]="loginForm">
///         <p>Login: <input type="text" ngControl="login"></p>
///         <p>Password: <input type="password" ngControl="password"></p>
///       </form>
///       <p>Value:</p>
///       <pre>{{value}}</pre>
///     </div>
///   ''',
///   directives: const [FORM_DIRECTIVES]
/// })
/// class App {
///   ControlGroup loginForm;
///
///   App() {
///     loginForm = new ControlGroup({
///       login: new Control(""),
///       password: new Control("")
///     });
///   }
///
///   String get value {
///     return JSON.encode(loginForm.value);
///   }
/// }
/// ```
///
/// We can also use ngModel to bind a domain model to the form.
///
/// ```dart
/// @Component(
///      selector: "login-comp",
///      directives: const [FORM_DIRECTIVES],
///      template: '''
///        <form [ngFormModel]='loginForm'>
///          Login <input type='text' ngControl='login' [(ngModel)]='credentials.login'>
///          Password <input type='password' ngControl='password'
///                          [(ngModel)]='credentials.password'>
///          <button (click)="onLogin()">Login</button>
///        </form>'''
///      )
/// class LoginComp {
///  credentials: {login: string, password: string};
///  ControlGroup loginForm;
///
///  LoginComp() {
///    loginForm = new ControlGroup({
///      login: new Control(""),
///      password: new Control("")
///    });
///  }
///
///  void onLogin() {
///    // credentials.login === 'some login'
///    // credentials.password === 'some password'
///  }
/// }
/// ```
@Directive(
    selector: '[ngFormModel]',
    providers: const [formDirectiveProvider],
    inputs: const ['form: ngFormModel'],
    host: const {'(submit)': 'onSubmit()'},
    outputs: const ['ngSubmit', 'ngBeforeSubmit'],
    exportAs: 'ngForm')
class NgFormModel extends ControlContainer implements Form, OnChanges {
  List<dynamic> _validators;
  List<dynamic> _asyncValidators;
  ControlGroup form;
  List<NgControl> directives = [];
  var ngSubmit = new EventEmitter<ControlGroup>(false);
  var ngBeforeSubmit = new EventEmitter<ControlGroup>(false);

  NgFormModel(@Optional() @Self() @Inject(NG_VALIDATORS) this._validators,
      @Optional() @Self() @Inject(NG_ASYNC_VALIDATORS) this._asyncValidators);

  @override
  void ngOnChanges(Map<String, SimpleChange> changes) {
    _checkFormPresent();
    if (changes.containsKey('form')) {
      var sync = composeValidators(_validators);
      this.form.validator = Validators.compose([form.validator, sync]);
      var async = composeAsyncValidators(_asyncValidators);
      form.asyncValidator =
          Validators.composeAsync([form.asyncValidator, async]);
      form.updateValueAndValidity(onlySelf: true, emitEvent: false);
    }
    _updateDomValue();
  }

  @override
  Form get formDirective => this;

  @override
  ControlGroup get control => form;

  @override
  List<String> get path => [];

  @override
  void addControl(NgControl dir) {
    dynamic ctrl = form.find(dir.path);
    setUpControl(ctrl, dir);
    ctrl.updateValueAndValidity(emitEvent: false);
    directives.add(dir);
  }

  @override
  Control getControl(NgControl dir) {
    return (form.find(dir.path) as Control);
  }

  @override
  void removeControl(NgControl dir) {
    directives.remove(dir);
  }

  @override
  void addControlGroup(NgControlGroup dir) {
    dynamic ctrl = form.find(dir.path);
    setUpControlGroup(ctrl, dir);
    ctrl.updateValueAndValidity(emitEvent: false);
  }

  @override
  void removeControlGroup(NgControlGroup dir) {}

  @override
  ControlGroup getControlGroup(NgControlGroup dir) {
    return (form.find(dir.path) as ControlGroup);
  }

  @override
  void updateModel(NgControl dir, dynamic value) {
    var ctrl = (form.find(dir.path) as Control);
    ctrl.updateValue(value);
  }

  bool onSubmit() {
    ngBeforeSubmit.add(form);
    ngSubmit.add(form);
    return false;
  }

  void _updateDomValue() {
    directives.forEach((dir) {
      dynamic ctrl = form.find(dir.path);
      dir.valueAccessor.writeValue(ctrl.value);
    });
  }

  void _checkFormPresent() {
    if (form == null) {
      throw new BaseException(
          'ngFormModel expects a form. Please pass one in. Example: '
          '<form [ngFormModel]="myCoolForm">');
    }
  }
}
