import "package:angular2/core.dart"
    show OnChanges, SimpleChange, Directive, Provider, Inject, Optional, Self;
import "package:angular2/src/facade/async.dart"
    show EventEmitter, ObservableWrapper;

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

/**
 * Binds a domain model to a form control.
 *
 * ### Usage
 *
 * `ngModel` binds an existing domain model to a form control. For a
 * two-way binding, use `[(ngModel)]` to ensure the model updates in
 * both directions.
 *
 * ### Example ([live demo](http://plnkr.co/edit/R3UX5qDaUqFO2VYR0UzH?p=preview))
 *  ```typescript
 * @Component({
 *      selector: "search-comp",
 *      directives: [FORM_DIRECTIVES],
 *      template: `<input type='text' [(ngModel)]="searchQuery">`
 *      })
 * class SearchComp {
 *  searchQuery: string;
 * }
 *  ```
 */
@Directive(
    selector: "[ngModel]:not([ngControl]):not([ngFormControl])",
    providers: const [formControlBinding],
    inputs: const ["model: ngModel"],
    outputs: const ["update: ngModelChange"],
    exportAs: "ngForm")
class NgModel extends NgControl implements OnChanges {
  List<dynamic> _validators;
  List<dynamic> _asyncValidators;
  /** @internal */
  var _control = new Control();
  /** @internal */
  var _added = false;
  var update = new EventEmitter();
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
    /* super call moved to initializer */;
    this.valueAccessor = selectValueAccessor(this, valueAccessors);
  }
  ngOnChanges(Map<String, SimpleChange> changes) {
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

  Control get control {
    return this._control;
  }

  List<String> get path {
    return [];
  }

  ValidatorFn get validator {
    return composeValidators(this._validators);
  }

  AsyncValidatorFn get asyncValidator {
    return composeAsyncValidators(this._asyncValidators);
  }

  void viewToModelUpdate(dynamic newValue) {
    this.viewModel = newValue;
    ObservableWrapper.callEmit(this.update, newValue);
  }
}
