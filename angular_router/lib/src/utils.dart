import 'package:angular/angular.dart' show ComponentFactory, ComponentResolver;

class TouchMap {
  Map<String, String> map = {};
  Map<String, bool> keys = {};
  TouchMap(Map<String, dynamic> map) {
    if (map != null) {
      map.forEach((key, value) {
        this.map[key] = value?.toString();
        this.keys[key] = true;
      });
    }
  }
  String get(String key) {
    keys.remove(key);
    return this.map[key];
  }

  Map<String, dynamic> getUnused() {
    Map<String, dynamic> unused = {};
    for (var key in keys.keys) {
      unused[key] = map[key];
    }
    return unused;
  }
}

String normalizeString(Object obj) => obj?.toString();

List<dynamic> getComponentAnnotations(
  Object componentOrType,
  ComponentResolver resolver,
) {
  if (componentOrType == null) {
    return const [];
  }
  ComponentFactory component;
  if (componentOrType is ComponentFactory) {
    component = componentOrType;
  } else if (componentOrType is Type) {
    component = resolver.resolveComponentSync(componentOrType);
  } else {
    throw new ArgumentError('Expected ComponentFactory or Type for '
        '"componentOrType", got: ${componentOrType.runtimeType}');
  }
  return component.metadata;
}

Type getComponentType(dynamic /* Type | ComponentFactory */ comp) {
  return comp is ComponentFactory ? comp.componentType : comp;
}

// TODO(matanl): Remove; this feature is no longer supported.
@deprecated
Function getCanActivateHook(_) => null;
