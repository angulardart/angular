import 'package:test/test.dart';
import "package:angular/src/core/di/reflective_key.dart" show KeyRegistry;

void main() {
  group("key", () {
    KeyRegistry registry;
    setUp(() {
      registry = new KeyRegistry();
    });
    test("should be equal to another key if type is the same", () {
      expect(registry.get("car"), registry.get("car"));
    });
    test("should not be equal to another key if types are different", () {
      expect(registry.get("car") != registry.get("porsche"), true);
    });
    test("should return the passed in key", () {
      expect(registry.get(registry.get("car")), registry.get("car"));
    });
  });
}
