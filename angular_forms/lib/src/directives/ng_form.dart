import 'dart:async';

import 'package:meta/meta.dart';
import 'package:angular/angular.dart';

import '../model.dart'
    show AbstractControl, AbstractControlGroup, ControlGroup, Control;
import '../validators.dart' show NG_VALIDATORS;
import 'abstract_form.dart' show AbstractForm;
import 'control_container.dart' show ControlContainer;
import 'ng_control.dart' show NgControl;
import 'ng_control_group.dart' show NgControlGroup;
import 'shared.dart' show setUpControl, setUpControlGroup, composeValidators;

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
  selector: 'form:not([ngNoForm]):not([ngFormModel]):not([memorizedForm]),'
      'ngForm,[ngForm]',
  providers: [
    ExistingProvider(ControlContainer, NgForm),
  ],
  exportAs: 'ngForm',
  visibility: Visibility.all,
)
class NgForm extends AbstractNgForm<ControlGroup> {
  NgForm(@Optional() @Self() @Inject(NG_VALIDATORS) List<dynamic> validators) {
    form = ControlGroup({}, composeValidators(validators));
  }

  @override
  ControlGroup createGroup(NgControlGroup _) => ControlGroup({});
}

/// Abstract class to easily create forms that are template driven.
///
/// This allows an implementing form to easily specify how to create control
/// groups, and controls. Allowing for infrastructure to create form systems
/// that are backed by different types such as protos.
abstract class AbstractNgForm<T extends AbstractControlGroup>
    extends AbstractForm<T> {
  T form;

  @Input('ngDisabled')
  set disabled(bool isDisabled) {
    toggleDisabled(isDisabled);
  }

  Map<String, AbstractControl> get controls => form.controls;

  T createGroup(NgControlGroup dir);
  // This is separate to allow clients to override the logic if they wish.
  Control createControl(NgControl _) => Control();

  @override
  void addControl(NgControl dir) {
    var container = findContainer(dir.path);
    var ctrl = createControl(dir);
    container.addControl(dir.name, ctrl);
    scheduleMicrotask(() {
      setUpControl(ctrl, dir);
      ctrl.updateValueAndValidity(emitEvent: false);
    });
  }

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
    var group = createGroup(dir);
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
  void updateModel(NgControl dir, dynamic value) {
    scheduleMicrotask(() {
      super.updateModel(dir, value);
    });
  }

  @protected
  T findContainer(List<String> path) {
    path.removeLast();
    return path.isEmpty ? form : (form.findPath(path) as T);
  }
}
