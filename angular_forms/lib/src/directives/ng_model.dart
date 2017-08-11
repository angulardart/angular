import 'dart:async';

import 'package:angular/angular.dart'
    show
        Directive,
        Inject,
        OnChanges,
        OnInit,
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
        isPropertyUpdated,
        selectValueAccessor,
        composeValidators;
import 'validators.dart' show ValidatorFn;

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
/// Learn more about `ngModel` in the [Forms][] and [Template Syntax][TS] pages.
///
/// [Forms]: https://webdev.dartlang.org/angular/guide/forms#ngModel
/// [TS]: https://webdev.dartlang.org/angular/guide/template-syntax#ngModel
///
/// ### Examples
///
/// <?code-excerpt "docs/template-syntax/lib/app_component.html (NgModel-1)"?>
/// ```html
/// <input [(ngModel)]="currentHero.name">
/// ```
///
/// This is equivalent to having separate bindings:
///
/// <?code-excerpt "docs/template-syntax/lib/app_component.html (NgModel-3)"?>
/// ```html
/// <input
///   [ngModel]="currentHero.name"
///   (ngModelChange)="currentHero.name=$event">
/// ```
///
/// Try the [live example][ex].
///
/// [ex]: http://angular-examples.github.io/template-syntax/#ngModel
@Directive(
    selector: '[ngModel]:not([ngControl]):not([ngFormControl])',
    providers: const [formControlBinding],
    inputs: const ['model: ngModel'],
    exportAs: 'ngForm')
class NgModel extends NgControl implements OnChanges, OnInit {
  final List<dynamic> _validators;
  final _control = new Control();
  final _update = new StreamController.broadcast(sync: true);
  dynamic model;
  dynamic viewModel;

  NgModel(
      @Optional()
      @Self()
      @Inject(NG_VALIDATORS)
          this._validators,
      @Optional()
      @Self()
      @Inject(NG_VALUE_ACCESSOR)
          List<ControlValueAccessor> valueAccessors)
      : super() {
    valueAccessor = selectValueAccessor(this, valueAccessors);
  }

  @Output('ngModelChange')
  Stream get update => _update.stream;

  @override
  void ngOnChanges(Map<String, SimpleChange> changes) {
    if (isPropertyUpdated(changes, viewModel)) {
      _control.updateValue(model);
      viewModel = model;
    }
  }

  @override
  ngOnInit() {
    setUpControl(_control, this);
    _control.updateValueAndValidity(emitEvent: false);
  }

  Control get control => _control;

  @override
  List<String> get path => [];

  @override
  ValidatorFn get validator => composeValidators(_validators);

  @override
  void viewToModelUpdate(dynamic newValue) {
    viewModel = newValue;
    _update.add(newValue);
  }
}
