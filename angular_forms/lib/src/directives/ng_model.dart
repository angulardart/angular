import 'dart:async';

import 'package:angular/angular.dart';

import '../model.dart' show Control;
import '../validators.dart' show NG_VALIDATORS;
import 'control_value_accessor.dart'
    show ControlValueAccessor, NG_VALUE_ACCESSOR;
import 'ng_control.dart' show NgControl;
import 'shared.dart' show setUpControl, selectValueAccessor, composeValidators;
import 'validators.dart' show ValidatorFn;

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
/// [ex]: https://webdev.dartlang.org/examples/template-syntax/#ngModel
@Directive(
  selector: '[ngModel]:not([ngControl]):not([ngFormControl])',
  providers: const [
    const ExistingProvider(NgControl, NgModel),
  ],
  exportAs: 'ngForm',
  visibility: Visibility.all,
)
class NgModel extends NgControl
    with ComponentState
    implements AfterChanges, OnInit {
  final List<dynamic> _validators;
  Control _control;
  StreamController _update;
  dynamic _model;
  bool _modelChanged = false;

  @Input('ngModel')
  set model(dynamic value) {
    /// Make sure input actually changed so we don't override
    /// viewModel passed to us using viewToModelUpdate from proxies.
    if (identical(_model, value)) return;
    _model = value;
    if (identical(value, viewModel)) return;

    /// Mark as changed so we can commit to viewModel in ngAfterChanges
    /// lifecycle.
    _modelChanged = true;
  }

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
    _init(valueAccessors);
  }

  // This function prevents constructor inlining for smaller code size since
  // NgModel is constructed for majority of form components.
  void _init(List<ControlValueAccessor> valueAccessors) {
    _control = new Control();
    _update = new StreamController.broadcast(sync: true);
    valueAccessor = selectValueAccessor(this, valueAccessors);
    // ! Please don't remove, the multiple return paths prevent inlining.
    return; // ignore: dead_code
    return; // ignore: dead_code
  }

  @Output('ngModelChange')
  Stream get update => _update.stream;

  @override
  void ngAfterChanges() {
    if (_modelChanged) {
      _control.updateValue(_model);
      setState(() {
        viewModel = _model;
      });
      _modelChanged = false;
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
