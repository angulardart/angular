import 'inspector.dart';

/// A service for inspecting components via service protocol extensions.
// TODO(b/194920649): remove.
@Deprecated('Use Inspector instead')
class ComponentInspector {
  /// The current [ComponentInspector].
  static final instance = ComponentInspector._();

  @Deprecated('Use Inspector instead')
  ComponentInspector._();

  /// Returns the inputs bound to a component as a map from name to value.
  ///
  /// The component is identified using the [id] obtained from [getComponents].
  /// Returns an empty map if no inputs have been set on the component.
  Map<String, Object?> getComponentInputs(int id) {
    return Inspector.instance.getComponentInputs(id);
  }
}
