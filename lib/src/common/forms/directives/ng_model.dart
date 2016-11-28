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
        isPropertyUpdated,
        selectValueAccessor,
        composeValidators,
        composeAsyncValidators;
import "validators.dart" show ValidatorFn, AsyncValidatorFn;

const formControlBinding = const Provider(NgControl, useExisting: NgModel);

/// Creates a form [NgControl] instance from a domain model and binds it to a
/// form control element. The form [NgControl] instance tracks the value,
/// user interaction, and validation status of the control and keeps the view
/// synced with the model. If used within a parent form, the directive will
/// also register itself with the form as a child control.
///
/// This directive can be used by itself or as part of a larger form. All you
/// need is the `ngModel` selector to activate it. For a two-way binding, use
/// the `[(ngModel)]` syntax to ensure the model updates in both directions.
///
/// Learn more about `ngModel` in the Guide [Forms](docs/guide/forms.html#ngModel)
/// and [Template Syntax](docs/guide/template-syntax.html#ngModel) pages.
///
/// ### Examples
///
/// {@example docs/template-syntax/lib/app_component.html region=NgModel-1}
///
/// This is equivalent to having separate bindings:
///
/// {@example docs/template-syntax/lib/app_component.html region=NgModel-3}
///
/// Try the [live example][ex].
/// [ex]: examples/template-syntax/#ngModel
@Directive(
    selector: "[ngModel]:not([ngControl]):not([ngFormControl])",
    providers: const [formControlBinding],
    inputs: const ["model: ngModel"],
    outputs: const ["update: ngModelChange"],
    exportAs: "ngForm")
class NgModel extends NgControl implements OnChanges {
  List<dynamic> _validators;
  List<dynamic> _asyncValidators;
  var _control = new Control();
  var _added = false;
  var update = new EventEmitter(false);
  dynamic model;
  dynamic viewModel;
  NgModel(
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
          List<ControlValueAccessor> valueAccessors)
      : super() {
    this.valueAccessor = selectValueAccessor(this, valueAccessors);
  }
  @override
  void ngOnChanges(Map<String, SimpleChange> changes) {
    if (!this._added) {
      setUpControl(this._control, this);
      this._control.updateValueAndValidity(emitEvent: false);
      this._added = true;
    }
    if (isPropertyUpdated(changes, this.viewModel)) {
      this._control.updateValue(this.model);
      this.viewModel = this.model;
    }
  }

  @override
  Control get control {
    return this._control;
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
  void viewToModelUpdate(dynamic newValue) {
    this.viewModel = newValue;
    this.update.add(newValue);
  }
}
