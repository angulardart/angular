import '../model.dart' show AbstractControl;
import 'abstract_control_directive.dart' show AbstractControlDirective;
import 'form_interface.dart' show Form;

/// A directive that contains multiple [NgControl]s.
///
/// Only used by the forms package.
class ControlContainer<T extends AbstractControl>
    extends AbstractControlDirective<T> {
  String name;

  /// Get the form to which this container belongs.
  Form get formDirective => null;

  /// Get the path to this container.
  @override
  List<String> get path => null;

  @override
  T get control => null;
}
