import 'dart:async';

import 'package:angular/angular.dart';

import '../model.dart' show Control;
import '../validators.dart' show NG_VALIDATORS;
import 'control_value_accessor.dart' show ControlValueAccessor, ngValueAccessor;
import 'ng_control.dart' show NgControl;
import 'shared.dart' show setUpControl;

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
  providers: [
    ExistingProvider(NgControl, NgFormControl),
  ],
  exportAs: 'ngForm',
)
class NgFormControl extends NgControl implements AfterChanges {
  bool _formChanged = false;
  Control _form;
  @Input('ngFormControl')
  set form(Control value) {
    _form = value;
    _formChanged = true;
  }

  Control get form => _form;
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

  NgFormControl(
      @Optional()
      @Self()
      @Inject(NG_VALIDATORS)
          List validators,
      @Optional()
      @Self()
      @Inject(ngValueAccessor)
          List<ControlValueAccessor> valueAccessors)
      : super(valueAccessors, validators);

  @Output('ngModelChange')
  Stream get update => _update.stream;

  @override
  void ngAfterChanges() {
    if (_formChanged) {
      _formChanged = false;
      setUpControl(form, this);
      form.updateValueAndValidity(emitEvent: false);
    }
    if (_modelChanged) {
      _modelChanged = false;
      if (!identical(_model, viewModel)) {
        form.updateValue(model);
        viewModel = model;
      }
    }
  }

  @override
  List<String> get path => [];

  @override
  Control get control => form;

  @override
  void viewToModelUpdate(dynamic newValue) {
    viewModel = newValue;
    _update.add(newValue);
  }
}
