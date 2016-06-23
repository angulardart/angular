library angular2.src.common.forms.directives.ng_form;

import "package:angular2/src/facade/async.dart"
    show PromiseWrapper, ObservableWrapper, EventEmitter, PromiseCompleter;
import "package:angular2/src/facade/collection.dart"
    show StringMapWrapper, ListWrapper;
import "package:angular2/src/facade/lang.dart" show isPresent, isBlank;
import "package:angular2/core.dart"
    show Directive, Provider, Optional, Inject, Self;
import "ng_control.dart" show NgControl;
import "form_interface.dart" show Form;
import "ng_control_group.dart" show NgControlGroup;
import "control_container.dart" show ControlContainer;
import "../model.dart" show AbstractControl, ControlGroup, Control;
import "shared.dart"
    show
        setUpControl,
        setUpControlGroup,
        composeValidators,
        composeAsyncValidators;
import "../validators.dart" show Validators, NG_VALIDATORS, NG_ASYNC_VALIDATORS;

const formDirectiveProvider =
    const Provider(ControlContainer, useExisting: NgForm);

/**
 * If `NgForm` is bound in a component, `<form>` elements in that component will be
 * upgraded to use the Angular form system.
 *
 * ### Typical Use
 *
 * Include `FORM_DIRECTIVES` in the `directives` section of a [View] annotation
 * to use `NgForm` and its associated controls.
 *
 * ### Structure
 *
 * An Angular form is a collection of `Control`s in some hierarchy.
 * `Control`s can be at the top level or can be organized in `ControlGroup`s
 * or `ControlArray`s. This hierarchy is reflected in the form's `value`, a
 * JSON object that mirrors the form structure.
 *
 * ### Submission
 *
 * The `ngSubmit` event signals when the user triggers a form submission.
 *
 * ### Example ([live demo](http://plnkr.co/edit/ltdgYj4P0iY64AR71EpL?p=preview))
 *
 *  ```typescript
 * @Component({
 *   selector: 'my-app',
 *   template: `
 *     <div>
 *       <p>Submit the form to see the data object Angular builds</p>
 *       <h2>NgForm demo</h2>
 *       <form #f="ngForm" (ngSubmit)="onSubmit(f.value)">
 *         <h3>Control group: credentials</h3>
 *         <div ngControlGroup="credentials">
 *           <p>Login: <input type="text" ngControl="login"></p>
 *           <p>Password: <input type="password" ngControl="password"></p>
 *         </div>
 *         <h3>Control group: person</h3>
 *         <div ngControlGroup="person">
 *           <p>First name: <input type="text" ngControl="firstName"></p>
 *           <p>Last name: <input type="text" ngControl="lastName"></p>
 *         </div>
 *         <button type="submit">Submit Form</button>
 *       <p>Form data submitted:</p>
 *       </form>
 *       <pre>{{data}}</pre>
 *     </div>
 * `,
 *   directives: [CORE_DIRECTIVES, FORM_DIRECTIVES]
 * })
 * export class App {
 *   constructor() {}
 *
 *   data: string;
 *
 *   onSubmit(data) {
 *     this.data = JSON.stringify(data, null, 2);
 *   }
 * }
 *  ```
 */
@Directive(
    selector: "form:not([ngNoForm]):not([ngFormModel]),ngForm,[ngForm]",
    bindings: const [formDirectiveProvider],
    host: const {"(submit)": "onSubmit()"},
    outputs: const ["ngSubmit"],
    exportAs: "ngForm")
class NgForm extends ControlContainer implements Form {
  ControlGroup form;
  var ngSubmit = new EventEmitter();
  NgForm(
      @Optional()
      @Self()
      @Inject(NG_VALIDATORS)
          List<dynamic> validators,
      @Optional()
      @Self()
      @Inject(NG_ASYNC_VALIDATORS)
          List<dynamic> asyncValidators)
      : super() {
    /* super call moved to initializer */;
    this.form = new ControlGroup({}, null, composeValidators(validators),
        composeAsyncValidators(asyncValidators));
  }
  Form get formDirective {
    return this;
  }

  ControlGroup get control {
    return this.form;
  }

  List<String> get path {
    return [];
  }

  Map<String, AbstractControl> get controls {
    return this.form.controls;
  }

  void addControl(NgControl dir) {
    PromiseWrapper.scheduleMicrotask(() {
      var container = this._findContainer(dir.path);
      var ctrl = new Control();
      setUpControl(ctrl, dir);
      container.addControl(dir.name, ctrl);
      ctrl.updateValueAndValidity(emitEvent: false);
    });
  }

  Control getControl(NgControl dir) {
    return (this.form.find(dir.path) as Control);
  }

  void removeControl(NgControl dir) {
    PromiseWrapper.scheduleMicrotask(() {
      var container = this._findContainer(dir.path);
      if (isPresent(container)) {
        container.removeControl(dir.name);
        container.updateValueAndValidity(emitEvent: false);
      }
    });
  }

  void addControlGroup(NgControlGroup dir) {
    PromiseWrapper.scheduleMicrotask(() {
      var container = this._findContainer(dir.path);
      var group = new ControlGroup({});
      setUpControlGroup(group, dir);
      container.addControl(dir.name, group);
      group.updateValueAndValidity(emitEvent: false);
    });
  }

  void removeControlGroup(NgControlGroup dir) {
    PromiseWrapper.scheduleMicrotask(() {
      var container = this._findContainer(dir.path);
      if (isPresent(container)) {
        container.removeControl(dir.name);
        container.updateValueAndValidity(emitEvent: false);
      }
    });
  }

  ControlGroup getControlGroup(NgControlGroup dir) {
    return (this.form.find(dir.path) as ControlGroup);
  }

  void updateModel(NgControl dir, dynamic value) {
    PromiseWrapper.scheduleMicrotask(() {
      var ctrl = (this.form.find(dir.path) as Control);
      ctrl.updateValue(value);
    });
  }

  bool onSubmit() {
    ObservableWrapper.callEmit(this.ngSubmit, null);
    return false;
  }

  /** @internal */
  ControlGroup _findContainer(List<String> path) {
    path.removeLast();
    return ListWrapper.isEmpty(path)
        ? this.form
        : (this.form.find(path) as ControlGroup);
  }
}
