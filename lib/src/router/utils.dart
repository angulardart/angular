library angular2.src.router.utils;

import "package:angular2/src/facade/lang.dart" show isPresent, isBlank;
import "package:angular2/src/facade/collection.dart" show StringMapWrapper;

class TouchMap {
  Map<String, String> map = {};
  Map<String, bool> keys = {};
  TouchMap(Map<String, dynamic> map) {
    if (isPresent(map)) {
      StringMapWrapper.forEach(map, (value, key) {
        this.map[key] = isPresent(value) ? value.toString() : null;
        this.keys[key] = true;
      });
    }
  }
  String get(String key) {
    StringMapWrapper.delete(this.keys, key);
    return this.map[key];
  }

  Map<String, dynamic> getUnused() {
    Map<String, dynamic> unused = {};
    var keys = StringMapWrapper.keys(this.keys);
    keys.forEach((key) => unused[key] = StringMapWrapper.get(this.map, key));
    return unused;
  }
}

String normalizeString(dynamic obj) {
  if (isBlank(obj)) {
    return null;
  } else {
    return obj.toString();
  }
}
