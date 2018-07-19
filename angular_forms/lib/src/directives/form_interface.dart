import '../model.dart' show Control, AbstractControlGroup;
import 'ng_control.dart' show NgControl;
import 'ng_control_group.dart' show NgControlGroup;

/// An interface that [NgFormModel] and [NgForm] implement.
///
/// Only used by the forms package.
abstract class Form {
  /// Add a control to this form.
  void addControl(NgControl dir);

  /// Remove a control from this form.
  void removeControl(NgControl dir);

  /// Look up the [Control] associated with a particular [NgControl].
  Control getControl(NgControl dir);

  /// Add a group of controls to this form.
  void addControlGroup(NgControlGroup dir);

  /// Remove a group of controls from this form.
  void removeControlGroup(NgControlGroup dir);

  /// Look up the [AbstractControlGroup] associated with a particular
  /// [NgControlGroup].
  AbstractControlGroup getControlGroup(NgControlGroup dir);

  /// Update the model for a particular control with a new value.
  void updateModel(NgControl dir, dynamic value);
}
