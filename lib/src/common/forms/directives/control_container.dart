import "abstract_control_directive.dart" show AbstractControlDirective;
import "form_interface.dart" show Form;

/**
 * A directive that contains multiple [NgControl]s.
 *
 * Only used by the forms module.
 */
class ControlContainer extends AbstractControlDirective {
  String name;
  /**
   * Get the form to which this container belongs.
   */
  Form get formDirective {
    return null;
  }

  /**
   * Get the path to this container.
   */
  @override
  List<String> get path {
    return null;
  }

  @override
  get control => null;
}
