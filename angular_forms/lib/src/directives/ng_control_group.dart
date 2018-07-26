import 'dart:async';

import 'package:angular/angular.dart';

import '../model.dart' show AbstractControlGroup;
import '../validators.dart' show NG_VALIDATORS;
import 'control_container.dart' show ControlContainer;
import 'form_interface.dart' show Form;
import 'shared.dart' show controlPath, composeValidators;
import 'validators.dart' show ValidatorFn;

/// Creates and binds a control group to a DOM element.
///
/// This directive can only be used as a child of [NgForm] or [NgFormModel].
///
/// ### Example:
///
/// ```dart
/// @Component(
///   selector: 'my-app',
///   directives: const [formDirectives],
///   template: '''
///     <div>
///       <h2>Angular2 Control &amp; AbstractControlGroup Example</h2>
///       <form #f="ngForm">
///         <div ngControlGroup="name" #cg-name="form">
///           <h3>Enter your name:</h3>
///           <p>First: <input ngControl="first" required></p>
///           <p>Middle: <input ngControl="middle"></p>
///           <p>Last: <input ngControl="last" required></p>
///         </div>
///         <h3>Name value:</h3>
///         <pre>{{valueOf(cgName)}}</pre>
///         <p>Name is {{cgName?.control?.valid ? "valid" : "invalid"}}</p>
///         <h3>What's your favorite food?</h3>
///         <p><input ngControl="food"></p>
///         <h3>Form value</h3>
///         <pre>{{valueOf(f)}}</pre>
///       </form>
///     </div>
///   '''
/// })
/// class App {
///   String valueOf(NgControlGroup cg) {
///     if (cg.control == null) {
///       return null;
///     }
///     return JSON.encode(cg.control.value, null, 2);
///   }
/// }
/// ```
///
/// This example declares a control group for a user's name. The value and
/// validation state of this group can be accessed separately from the overall
/// form.
@Directive(
  selector: '[ngControlGroup]',
  providers: [
    ExistingProvider(ControlContainer, NgControlGroup),
  ],
  exportAs: 'ngForm',
)
class NgControlGroup extends ControlContainer<AbstractControlGroup>
    implements OnInit, OnDestroy {
  final ValidatorFn validator;
  final ControlContainer _parent;

  bool _isDisabled = false;
  bool _disabledChanged = false;

  NgControlGroup(@SkipSelf() this._parent,
      @Optional() @Self() @Inject(NG_VALIDATORS) List validators)
      : validator = composeValidators(validators);

  @Input('ngControlGroup')
  @override
  set name(String value) {
    super.name = value;
  }

  @Input('ngDisabled')
  set disabled(bool isDisabled) {
    _isDisabled = isDisabled;
    if (control != null) {
      _disabledChanged = false;
      toggleDisabled(isDisabled);
    } else {
      _disabledChanged = true;
    }
  }

  @override
  void ngOnInit() {
    formDirective.addControlGroup(this);
    if (_disabledChanged) {
      scheduleMicrotask(() {
        _disabledChanged = false;
        toggleDisabled(_isDisabled);
      });
    }
  }

  @override
  void ngOnDestroy() {
    formDirective.removeControlGroup(this);
  }

  /// Get the [AbstractControlGroup] backing this binding.
  @override
  AbstractControlGroup get control => formDirective.getControlGroup(this);

  /// Get the path to this control group.
  @override
  List<String> get path => controlPath(name, _parent);

  /// Get the [Form] to which this group belongs.
  @override
  Form get formDirective => _parent.formDirective;
}
