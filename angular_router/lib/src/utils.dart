import 'package:angular/angular.dart' show ComponentFactory, reflector;

import 'lifecycle/lifecycle_annotations.dart' show CanActivate;

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
    dynamic /* Type | ComponentFactory */ comp) {
  if (comp is ComponentFactory) {
    return comp.metadata;
  } else {
    return reflector.annotations(comp);
  }
}

Type getComponentType(dynamic /* Type | ComponentFactory */ comp) {
  return comp is ComponentFactory ? comp.componentType : comp;
}

Function getCanActivateHook(component) {
  var annotations = getComponentAnnotations(component);
  for (var i = 0; i < annotations.length; i += 1) {
    var annotation = annotations[i];
    if (annotation is CanActivate) {
      return annotation.fn;
    }
  }
  return null;
}
