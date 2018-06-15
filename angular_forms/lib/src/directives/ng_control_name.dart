import 'dart:async';

import 'package:angular/angular.dart';

import '../model.dart' show Control;
import '../validators.dart' show NG_VALIDATORS;
import 'control_container.dart' show ControlContainer;
import 'control_value_accessor.dart' show ControlValueAccessor, ngValueAccessor;
import 'form_interface.dart' show Form;
import 'ng_control.dart' show NgControl;
import 'shared.dart' show controlPath;

/// Creates and binds a control with a specified name to a DOM element.
///
/// This directive can only be used as a child of [NgForm] or [NgFormModel].
///
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
  providers: [
    ExistingProvider(NgControl, NgControlName),
  ],
  exportAs: 'ngForm',
)
class NgControlName extends NgControl implements AfterChanges, OnDestroy {
  final ControlContainer _parent;
  final _update = StreamController.broadcast();

  bool _modelChanged = false;
  dynamic _model;
  @Input('ngModel')
  set model(dynamic value) {
    _modelChanged = true;
    _model = value;
  }

  dynamic get model => _model;
  dynamic viewModel;
  var _added = false;

  bool _isDisabled = false;
  bool _disabledChanged = false;

  NgControlName(
      @SkipSelf()
          this._parent,
      @Optional()
      @Self()
      @Inject(NG_VALIDATORS)
          List validators,
      @Optional()
      @Self()
      @Inject(ngValueAccessor)
          List<ControlValueAccessor> valueAccessors)
      : super(valueAccessors, validators);

  @Input('ngControl')
  @override
  set name(String value) {
    super.name = value;
  }

  @Input('ngDisabled')
  set disabled(bool isDisabled) {
    _isDisabled = isDisabled;
    _disabledChanged = true;
  }

  @Output('ngModelChange')
  Stream get update => _update.stream;

  @override
  ngAfterChanges() {
    // Call model changed before added so that the control already has the
    // correct value at initialization.
    if (_modelChanged) {
      _modelChanged = false;
      if (!identical(_model, viewModel)) {
        viewModel = _model;
        formDirective.updateModel(this, _model);
      }
    }
    if (!_added) {
      formDirective.addControl(this);
      _added = true;
    }
    if (_disabledChanged) {
      scheduleMicrotask(() {
        _disabledChanged = false;
        toggleDisabled(_isDisabled);
      });
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
  Control get control => formDirective.getControl(this);
}
