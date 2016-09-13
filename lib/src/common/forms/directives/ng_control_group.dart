import "package:angular2/core.dart"
    show
        OnInit,
        OnDestroy,
        Directive,
        Optional,
        Inject,
        SkipSelf,
        Provider,
        Self;

import "../model.dart" show ControlGroup;
import "../validators.dart" show NG_VALIDATORS, NG_ASYNC_VALIDATORS;
import "control_container.dart" show ControlContainer;
import "form_interface.dart" show Form;
import "shared.dart"
    show controlPath, composeValidators, composeAsyncValidators;
import "validators.dart" show AsyncValidatorFn, ValidatorFn;

const controlGroupProvider =
    const Provider(ControlContainer, useExisting: NgControlGroup);

/// Creates and binds a control group to a DOM element.
///
/// This directive can only be used as a child of [NgForm] or [NgFormModel].
///
/// ### Example:
///
/// ```dart
/// @Component(
///   selector: 'my-app',
///   directives: const [FORM_DIRECTIVES],
///   template: '''
///     <div>
///       <h2>Angular2 Control &amp; ControlGroup Example</h2>
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
    selector: "[ngControlGroup]",
    providers: const [controlGroupProvider],
    inputs: const ["name: ngControlGroup"],
    exportAs: "ngForm")
class NgControlGroup extends ControlContainer implements OnInit, OnDestroy {
  final List<dynamic> _validators;
  final List<dynamic> _asyncValidators;
  final ControlContainer _parent;
  NgControlGroup(
      @SkipSelf() this._parent,
      @Optional() @Self() @Inject(NG_VALIDATORS) this._validators,
      @Optional() @Self() @Inject(NG_ASYNC_VALIDATORS) this._asyncValidators);

  void ngOnInit() {
    this.formDirective.addControlGroup(this);
  }

  void ngOnDestroy() {
    this.formDirective.removeControlGroup(this);
  }

  /// Get the [ControlGroup] backing this binding.
  ControlGroup get control {
    return this.formDirective.getControlGroup(this);
  }

  /// Get the path to this control group.
  List<String> get path {
    return controlPath(this.name, this._parent);
  }

  /// Get the [Form] to which this group belongs.
  Form get formDirective {
    return this._parent.formDirective;
  }

  ValidatorFn get validator {
    return composeValidators(this._validators);
  }

  AsyncValidatorFn get asyncValidator {
    return composeAsyncValidators(this._asyncValidators);
  }
}
