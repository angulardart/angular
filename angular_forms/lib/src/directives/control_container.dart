import '../model.dart' show ControlGroup;
import 'abstract_control_directive.dart' show AbstractControlDirective;
import 'form_interface.dart' show Form;

/// A directive that contains multiple [NgControl]s contained in a
/// [ControlGroup].
///
/// Only used by the forms package.
abstract class ControlContainer extends AbstractControlDirective<ControlGroup> {
  /// Get the form to which this container belongs.
  Form get formDirective;
}
