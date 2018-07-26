import 'package:angular/angular.dart';

import '../model.dart' show AbstractControlGroup;
import '../validators.dart' show Validators, NG_VALIDATORS;
import 'abstract_form.dart' show AbstractForm;
import 'control_container.dart' show ControlContainer;
import 'ng_control.dart' show NgControl;
import 'ng_control_group.dart';
import 'shared.dart' show setUpControl, setUpControlGroup, composeValidators;
import 'validators.dart' show ValidatorFn;

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
///       <form [ngFormModel]='loginForm">
///         <p>Login: <input type="text" ngControl="login"></p>
///         <p>Password: <input type="password" ngControl="password"></p>
///       </form>
///       <p>Value:</p>
///       <pre>{{value}}</pre>
///     </div>
///   ''',
///   directives: const [formDirectives]
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
///      directives: const [formDirectives],
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
  providers: [
    ExistingProvider(ControlContainer, NgFormModel),
  ],
  exportAs: 'ngForm',
  visibility: Visibility.all,
)
class NgFormModel extends AbstractForm<AbstractControlGroup>
    implements AfterChanges {
  final ValidatorFn _validator;

  bool _formChanged = false;
  AbstractControlGroup _form;

  AbstractControlGroup get form => _form;

  @Input('ngFormModel')
  set form(AbstractControlGroup value) {
    _form = value;
    _formChanged = true;
  }

  List<NgControl> directives = [];

  NgFormModel(@Optional() @Self() @Inject(NG_VALIDATORS) List validators)
      : _validator = composeValidators(validators);

  @override
  void ngAfterChanges() {
    _checkFormPresent();
    if (_formChanged) {
      _formChanged = false;
      _form.validator = Validators.compose([_form.validator, _validator]);
      _form.updateValueAndValidity(onlySelf: true, emitEvent: false);
    }
    _updateDomValue();
  }

  @override
  void addControl(NgControl dir) {
    var ctrl = getControl(dir);
    setUpControl(ctrl, dir);
    ctrl.updateValueAndValidity(emitEvent: false);
    directives.add(dir);
  }

  @override
  void removeControl(NgControl dir) {
    directives.remove(dir);
  }

  @override
  void addControlGroup(NgControlGroup dir) {
    var ctrl = form.findPath(dir.path);
    setUpControlGroup(ctrl, dir);
    ctrl.updateValueAndValidity(emitEvent: false);
  }

  @override
  void removeControlGroup(NgControlGroup dir) {}

  void _updateDomValue() {
    for (var dir in directives) {
      var ctrl = form.findPath(dir.path);
      dir.valueAccessor.writeValue(ctrl.value);
    }
  }

  void _checkFormPresent() {
    if (form == null) {
      throw StateError(
          'ngFormModel expects a form. Please pass one in. Example: '
          '<form [ngFormModel]="myCoolForm">');
    }
  }
}
