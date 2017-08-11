import 'dart:async';
import 'dart:html' show Event;

import 'package:meta/meta.dart';
import 'package:angular/angular.dart'
    show Directive, Inject, Optional, Output, Provider, Self;

import '../model.dart' show AbstractControl, ControlGroup, Control;
import '../validators.dart' show NG_VALIDATORS;
import 'control_container.dart' show ControlContainer;
import 'form_interface.dart' show Form;
import 'ng_control.dart' show NgControl;
import 'ng_control_group.dart' show NgControlGroup;
import 'shared.dart' show setUpControl, setUpControlGroup, composeValidators;

const formDirectiveProvider =
    const Provider(ControlContainer, useExisting: NgForm);

/// If `NgForm` is bound in a component, `<form>` elements in that component
/// will be upgraded to use the Angular form system.
///
/// ### Typical Use
///
/// Include `formDirectives` in the `directives` section of a [View] annotation
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
///   directives: const [CORE_DIRECTIVES, formDirectives]
/// })
/// class App {
///
///   String data;
///
///   void onSubmit(data) {
///     data = JSON.encode(data);
///   }
/// }
/// ```
@Directive(
    selector: 'form:not([ngNoForm]):not([ngFormModel]),ngForm,[ngForm]',
    providers: const [formDirectiveProvider],
    host: const {'(submit)': 'onSubmit(\$event)'},
    exportAs: 'ngForm')
class NgForm extends ControlContainer implements Form {
  ControlGroup form;
  final _ngSubmit = new StreamController<ControlGroup>.broadcast(sync: true);
  final _ngBeforeSubmit =
      new StreamController<ControlGroup>.broadcast(sync: true);

  NgForm(@Optional() @Self() @Inject(NG_VALIDATORS) List<dynamic> validators) {
    form = new ControlGroup({}, null, composeValidators(validators));
  }

  @Output()
  Stream<ControlGroup> get ngSubmit => _ngSubmit.stream;
  @Output()
  Stream<ControlGroup> get ngBeforeSubmit => _ngBeforeSubmit.stream;

  @override
  Form get formDirective => this;

  @override
  ControlGroup get control => form;

  @override
  List<String> get path => [];

  Map<String, AbstractControl> get controls => form.controls;

  @override
  void addControl(NgControl dir) {
    var container = findContainer(dir.path);
    var ctrl = new Control();
    container.addControl(dir.name, ctrl);
    scheduleMicrotask(() {
      setUpControl(ctrl, dir);
      ctrl.updateValueAndValidity(emitEvent: false);
    });
  }

  @override
  Control getControl(NgControl dir) => (form.find(dir.path) as Control);

  @override
  void removeControl(NgControl dir) {
    scheduleMicrotask(() {
      var container = findContainer(dir.path);
      if (container != null) {
        container.removeControl(dir.name);
        container.updateValueAndValidity(emitEvent: false);
      }
    });
  }

  @override
  void addControlGroup(NgControlGroup dir) {
    var container = findContainer(dir.path);
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
      var container = findContainer(dir.path);
      if (container != null) {
        container.removeControl(dir.name);
        container.updateValueAndValidity(emitEvent: false);
      }
    });
  }

  @override
  ControlGroup getControlGroup(NgControlGroup dir) =>
      (form.find(dir.path) as ControlGroup);

  @override
  void updateModel(NgControl dir, dynamic value) {
    scheduleMicrotask(() {
      Control ctrl = form.find(dir.path);
      ctrl?.updateValue(value);
    });
  }

  void onSubmit(Event event) {
    _ngBeforeSubmit.add(form);
    _ngSubmit.add(form);
    event?.preventDefault();
  }

  @protected
  ControlGroup findContainer(List<String> path) {
    path.removeLast();
    return path.isEmpty ? form : (form.find(path) as ControlGroup);
  }
}
