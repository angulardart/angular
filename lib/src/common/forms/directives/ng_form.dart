import 'dart:async';

import "package:angular2/core.dart"
    show Directive, Provider, Optional, Inject, Self;
import "package:angular2/src/facade/async.dart" show EventEmitter;

import "../model.dart" show AbstractControl, ControlGroup, Control;
import "../validators.dart" show NG_VALIDATORS, NG_ASYNC_VALIDATORS;
import "control_container.dart" show ControlContainer;
import "form_interface.dart" show Form;
import "ng_control.dart" show NgControl;
import "ng_control_group.dart" show NgControlGroup;
import "shared.dart"
    show
        setUpControl,
        setUpControlGroup,
        composeValidators,
        composeAsyncValidators;

const formDirectiveProvider =
    const Provider(ControlContainer, useExisting: NgForm);

/// If `NgForm` is bound in a component, `<form>` elements in that component
/// will be upgraded to use the Angular form system.
///
/// ### Typical Use
///
/// Include `FORM_DIRECTIVES` in the `directives` section of a [View] annotation
/// to use `NgForm` and its associated controls.
///
/// ### Structure
///
/// An Angular form is a collection of `Control`s in some hierarchy.
/// `Control`s can be at the top level or can be organized in `ControlGroup`s
/// or `ControlArray`s. This hierarchy is reflected in the form's `value`, a
/// JSON object that mirrors the form structure.
///
/// ### Submission
///
/// The `ngSubmit` event signals when the user triggers a form submission.
///
/// ### Example
///
/// ```dart
/// @Component(
///   selector: 'my-app',
///   template: '''
///     <div>
///       <p>Submit the form to see the data object Angular builds</p>
///       <h2>NgForm demo</h2>
///       <form #f="ngForm" (ngSubmit)="onSubmit(f.value)">
///         <h3>Control group: credentials</h3>
///         <div ngControlGroup="credentials">
///           <p>Login: <input type="text" ngControl="login"></p>
///           <p>Password: <input type="password" ngControl="password"></p>
///         </div>
///         <h3>Control group: person</h3>
///         <div ngControlGroup="person">
///           <p>First name: <input type="text" ngControl="firstName"></p>
///           <p>Last name: <input type="text" ngControl="lastName"></p>
///         </div>
///         <button type="submit">Submit Form</button>
///       <p>Form data submitted:</p>
///       </form>
///       <pre>{{data}}</pre>
///     </div>''',
///   directives: const [CORE_DIRECTIVES, FORM_DIRECTIVES]
/// })
/// class App {
///
///   String data;
///
///   void onSubmit(data) {
///     this.data = JSON.encode(data);
///   }
/// }
/// ```
@Directive(
    selector: "form:not([ngNoForm]):not([ngFormModel]),ngForm,[ngForm]",
    providers: const [formDirectiveProvider],
    host: const {"(submit)": "onSubmit()"},
    outputs: const ["ngSubmit", "ngBeforeSubmit"],
    exportAs: "ngForm")
class NgForm extends ControlContainer implements Form {
  ControlGroup form;
  var ngSubmit = new EventEmitter<ControlGroup>(false);
  var ngBeforeSubmit = new EventEmitter<ControlGroup>(false);
  NgForm(
      @Optional()
      @Self()
      @Inject(NG_VALIDATORS)
          List<dynamic> validators,
      @Optional()
      @Self()
      @Inject(NG_ASYNC_VALIDATORS)
          List<dynamic> asyncValidators) {
    this.form = new ControlGroup({}, null, composeValidators(validators),
        composeAsyncValidators(asyncValidators));
  }
  @override
  Form get formDirective {
    return this;
  }

  @override
  ControlGroup get control {
    return this.form;
  }

  @override
  List<String> get path {
    return [];
  }

  Map<String, AbstractControl> get controls {
    return this.form.controls;
  }

  @override
  void addControl(NgControl dir) {
    var container = _findContainer(dir.path);
    var ctrl = new Control();
    container.addControl(dir.name, ctrl);
    scheduleMicrotask(() {
      setUpControl(ctrl, dir);
      ctrl.updateValueAndValidity(emitEvent: false);
    });
  }

  @override
  Control getControl(NgControl dir) {
    return (this.form.find(dir.path) as Control);
  }

  @override
  void removeControl(NgControl dir) {
    scheduleMicrotask(() {
      var container = this._findContainer(dir.path);
      if (container != null) {
        container.removeControl(dir.name);
        container.updateValueAndValidity(emitEvent: false);
      }
    });
  }

  @override
  void addControlGroup(NgControlGroup dir) {
    var container = _findContainer(dir.path);
    var group = new ControlGroup({});
    container.addControl(dir.name, group);
    scheduleMicrotask(() {
      setUpControlGroup(group, dir);
      group.updateValueAndValidity(emitEvent: false);
    });
  }

  @override
  void removeControlGroup(NgControlGroup dir) {
    scheduleMicrotask(() {
      var container = this._findContainer(dir.path);
      if (container != null) {
        container.removeControl(dir.name);
        container.updateValueAndValidity(emitEvent: false);
      }
    });
  }

  @override
  ControlGroup getControlGroup(NgControlGroup dir) {
    return (this.form.find(dir.path) as ControlGroup);
  }

  @override
  void updateModel(NgControl dir, dynamic value) {
    scheduleMicrotask(() {
      var ctrl = (this.form.find(dir.path) as Control);
      ctrl.updateValue(value);
    });
  }

  bool onSubmit() {
    ngBeforeSubmit.add(form);
    ngSubmit.add(form);
    return false;
  }

  ControlGroup _findContainer(List<String> path) {
    path.removeLast();
    return path.isEmpty ? this.form : (this.form.find(path) as ControlGroup);
  }
}
