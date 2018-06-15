import 'dart:async';

import 'package:angular/angular.dart';

import '../model.dart' show ControlGroup, Control;
import '../validators.dart' show NG_VALIDATORS;
import 'control_container.dart' show ControlContainer;
import 'ng_control.dart' show NgControl;
import 'ng_control_group.dart' show NgControlGroup;
import 'ng_form.dart' show NgForm;
import 'shared.dart' show setUpControl, setUpControlGroup;

/// A form that will not remove controls if the control is taken out of the
/// view for example with a [NgIf].
@Directive(
  selector: '[memorizedForm]',
  providers: [
    Provider(ControlContainer, useExisting: MemorizedForm),
    Provider(NgForm, useExisting: MemorizedForm)
  ],
  exportAs: 'ngForm',
)
class MemorizedForm extends NgForm {
  MemorizedForm(
      @Optional() @Self() @Inject(NG_VALIDATORS) List<dynamic> validators)
      : super(validators);

  /// Add a control if it isn't already found in the container.
  @override
  void addControl(NgControl dir) {
    var container = findContainer(dir.path);
    var ctrl = container.find(dir.name);
    if (ctrl == null) {
      ctrl = Control();
      container.addControl(dir.name, ctrl);
    }

    // Binding values may change of of directive due to adding control value.
    // Perform the update in the next event loop.
    scheduleMicrotask(() {
      setUpControl(ctrl, dir);
      ctrl.updateValueAndValidity(emitEvent: false);
    });
  }

  /// Add a control group if it isn't already found in the container.
  @override
  void addControlGroup(NgControlGroup dir) {
    var container = findContainer(dir.path);
    var group = container.find(dir.name);
    if (group == null) {
      group = ControlGroup({});
      container.addControl(dir.name, group);
    }

    // Binding values may change of of directive due to adding control value.
    // Perform the update in the next event loop.
    scheduleMicrotask(() {
      setUpControlGroup(group, dir);
      group.updateValueAndValidity(emitEvent: false);
    });
  }

  @override
  void removeControl(NgControl ctrl) {
    // We will not remove the control if it is dropped, but we need to cleanup
    // any validators that may have been added.
    ctrl?.control?.validator = null;
  }

  @override
  void removeControlGroup(NgControlGroup ctrl) {
    // We will not remove the control group if it is dropped, but we need to cleanup
    // any validators that may have been added.
    ctrl?.control?.validator = null;
  }
}
