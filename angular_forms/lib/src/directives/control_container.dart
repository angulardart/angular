import '../model.dart' show AbstractControlGroup;
import 'abstract_control_directive.dart' show AbstractControlDirective;
import 'form_interface.dart' show Form;

/// A directive that contains multiple [NgControl]s contained in a
/// [AbstractControlGroup].
///
/// Only used by the forms package.
abstract class ControlContainer<T extends AbstractControlGroup>
    extends AbstractControlDirective<T> {
  /// Get the form to which this container belongs.
  Form get formDirective;
}
