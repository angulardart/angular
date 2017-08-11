import 'dart:async';

import 'package:angular/angular.dart'
    show
        Directive,
        Inject,
        OnChanges,
        Optional,
        Output,
        Provider,
        Self,
        SimpleChange;

import '../model.dart' show Control;
import '../validators.dart' show NG_VALIDATORS;
import 'control_value_accessor.dart'
    show ControlValueAccessor, NG_VALUE_ACCESSOR;
import 'ng_control.dart' show NgControl;
import 'shared.dart'
    show
        setUpControl,
        composeValidators,
        isPropertyUpdated,
        selectValueAccessor;
import 'validators.dart' show ValidatorFn;

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
///   directives: const [CORE_DIRECTIVES, formDirectives]
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
///      directives: const [formDirectives],
///      template: "<input type='text' [ngFormControl]='loginControl' [(ngModel)]='login'>"
///      )
/// class LoginComp {
///  Control loginControl = new Control('');
///  String login;
/// }
/// ```
@Directive(
    selector: '[ngFormControl]',
    providers: const [formControlBinding],
    inputs: const ['form: ngFormControl', 'model: ngModel'],
    exportAs: 'ngForm')
class NgFormControl extends NgControl implements OnChanges {
  final /* Array<Validator|Function> */ List<dynamic> _validators;
  Control form;
  final _update = new StreamController.broadcast();
  dynamic model;
  dynamic viewModel;

  NgFormControl(
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
  void ngOnChanges(Map<String, SimpleChange> changes) {
    if (_isControlChanged(changes)) {
      setUpControl(form, this);
      form.updateValueAndValidity(emitEvent: false);
    }
    if (isPropertyUpdated(changes, viewModel)) {
      form.updateValue(model);
      viewModel = model;
    }
  }

  @override
  List<String> get path => [];

  @override
  ValidatorFn get validator => composeValidators(_validators);

  @override
  Control get control => form;

  @override
  void viewToModelUpdate(dynamic newValue) {
    viewModel = newValue;
    _update.add(newValue);
  }

  bool _isControlChanged(Map<String, dynamic> changes) =>
      changes.containsKey('form');
}
