import 'dart:async';

import 'package:angular/angular.dart'
    show
        Directive,
        Inject,
        OnChanges,
        OnDestroy,
        Optional,
        Output,
        Provider,
        Self,
        SimpleChange,
        SkipSelf;

import '../model.dart' show Control;
import '../validators.dart' show NG_VALIDATORS;
import 'control_container.dart' show ControlContainer;
import 'control_value_accessor.dart'
    show ControlValueAccessor, NG_VALUE_ACCESSOR;
import 'form_interface.dart' show Form;
import 'ng_control.dart' show NgControl;
import 'shared.dart'
    show controlPath, composeValidators, isPropertyUpdated, selectValueAccessor;
import 'validators.dart' show ValidatorFn;

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
///      directives: const [formDirectives],
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
///      directives: [formDirectives],
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
///    // credentials.login === "some login"
///    // credentials.password === "some password"
///  }
/// }
/// ```
@Directive(
    selector: '[ngControl]',
    providers: const [controlNameBinding],
    inputs: const ['name: ngControl', 'model: ngModel'],
    exportAs: 'ngForm')
class NgControlName extends NgControl implements OnChanges, OnDestroy {
  final ControlContainer _parent;
  final /* Array<Validator|Function> */ List<dynamic> _validators;
  final _update = new StreamController.broadcast();
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
      @Inject(NG_VALUE_ACCESSOR)
          List<ControlValueAccessor> valueAccessors) {
    valueAccessor = selectValueAccessor(this, valueAccessors);
  }

  @Output('ngModelChange')
  Stream get update => _update.stream;

  @override
  ngOnChanges(Map<String, SimpleChange> changes) {
    if (!_added) {
      formDirective.addControl(this);
      _added = true;
    }
    if (isPropertyUpdated(changes, viewModel)) {
      viewModel = model;
      formDirective.updateModel(this, model);
    }
  }

  @override
  void ngOnDestroy() {
    formDirective.removeControl(this);
  }

  @override
  void viewToModelUpdate(dynamic newValue) {
    viewModel = newValue;
    _update.add(newValue);
  }

  @override
  List<String> get path => controlPath(name, _parent);

  Form get formDirective => _parent.formDirective;

  @override
  ValidatorFn get validator => composeValidators(_validators);

  @override
  Control get control => formDirective.getControl(this);
}
