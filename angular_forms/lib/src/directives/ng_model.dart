import 'dart:async';

import 'package:angular/angular.dart';
import 'package:meta/dart2js.dart' as dart2js;

import '../model.dart' show Control;
import '../validators.dart' show NG_VALIDATORS;
import 'control_value_accessor.dart' show ControlValueAccessor, ngValueAccessor;
import 'ng_control.dart' show NgControl;
import 'shared.dart' show setUpControl;

/// Creates a form [NgControl] instance from a domain model and binds it to a
/// form control element. The form [NgControl] instance tracks the value,
/// user interaction, and validation status of the control and keeps the view
/// synced with the model.
///
/// This directive is intended to be used as a stand-alone value. If you would
/// like to use it as part of a larger form, then it must be assigned a
/// name using `ngControl="name". See [NgControlName] directive
/// for more details.
///
/// All you need is the `ngModel` selector to activate it. For a
/// two-way binding, use the `[(ngModel)]` syntax to ensure the model
/// updates in both directions.
///
/// Learn more about `ngModel` in the [Forms][] and [Template Syntax][TS] pages.
///
/// [Forms]:  https://angulardart.dev/angular/guide/forms#ngModel
/// [TS]:  https://angulardart.dev/angular/guide/template-syntax#ngModel
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
/// [ex]:  https://angulardart.dev/examples/template-syntax/#ngModel
@Directive(
  selector: '[ngModel]:not([ngControl]):not([ngFormControl])',
  providers: [
    ExistingProvider(NgControl, NgModel),
  ],
  exportAs: 'ngForm',
  visibility: Visibility.all,
)
class NgModel extends NgControl implements AfterChanges, OnInit {
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
          List validators,
      @Optional()
      @Self()
      @Inject(ngValueAccessor)
          List<ControlValueAccessor> valueAccessors)
      : super(valueAccessors, validators) {
    _init(valueAccessors);
  }

  @Input('ngDisabled')
  set disabled(bool isDisabled) {
    toggleDisabled(isDisabled);
  }

  // This function prevents constructor inlining for smaller code size since
  // NgModel is constructed for majority of form components.
  @dart2js.noInline
  void _init(List<ControlValueAccessor> valueAccessors) {
    _control = Control();
    _update = StreamController.broadcast(sync: true);
    // ! Please don't remove, the multiple return paths prevent inlining.
  }

  @Output('ngModelChange')
  Stream get update => _update.stream;

  @override
  void ngAfterChanges() {
    if (_modelChanged) {
      _control.updateValue(_model);
      viewModel = _model;
      _modelChanged = false;
    }
  }

  @override
  void ngOnInit() {
    setUpControl(_control, this);
    _control.updateValueAndValidity(emitEvent: false);
  }

  Control get control => _control;

  @override
  List<String> get path => [];

  @override
  void viewToModelUpdate(dynamic newValue) {
    viewModel = newValue;
    _update.add(newValue);
  }
}
