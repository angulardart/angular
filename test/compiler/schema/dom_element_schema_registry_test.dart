library angular2.test.compiler.schema.dom_element_schema_registry_test;

import "package:angular2/src/compiler/schema/dom_element_schema_registry.dart"
    show DomElementSchemaRegistry;
import "package:angular2/src/core/security.dart";
import 'package:test/test.dart';

void main() {
  group("DOMElementSchema", () {
    DomElementSchemaRegistry registry;
    setUp(() {
      registry = new DomElementSchemaRegistry();
    });
    test("should detect properties on regular elements", () {
      expect(registry.hasProperty("div", "id"), isTrue);
      expect(registry.hasProperty("div", "title"), isTrue);
      expect(registry.hasProperty("h1", "align"), isTrue);
      expect(registry.hasProperty("h2", "align"), isTrue);
      expect(registry.hasProperty("h3", "align"), isTrue);
      expect(registry.hasProperty("h4", "align"), isTrue);
      expect(registry.hasProperty("h5", "align"), isTrue);
      expect(registry.hasProperty("h6", "align"), isTrue);
      expect(registry.hasProperty("h7", "align"), isFalse);
      expect(registry.hasProperty("textarea", "disabled"), isTrue);
      expect(registry.hasProperty("input", "disabled"), isTrue);
      expect(registry.hasProperty("div", "unknown"), isFalse);
    });
    test("should detect different kinds of types", () {
      // inheritance: video => media => *
      expect(registry.hasProperty("video", "className"), isTrue);
      expect(registry.hasProperty("video", "id"), isTrue);
      expect(registry.hasProperty("video", "scrollLeft"), isTrue);
      expect(registry.hasProperty("video", "height"), isTrue);
      expect(registry.hasProperty("video", "autoplay"), isTrue);
      expect(registry.hasProperty("video", "classList"), isTrue);
      // from *; but events are not properties
      expect(registry.hasProperty("video", "click"), isFalse);
    });
    test("should return true for custom-like elements", () {
      expect(registry.hasProperty("custom-like", "unknown"), isTrue);
    });
    test("should re-map property names that are specified in DOM facade", () {
      expect(registry.getMappedPropName("readonly"), "readOnly");
    });
    test(
        "should not re-map property names that are not specified in DOM facade",
        () {
      expect(registry.getMappedPropName("title"), "title");
      expect(registry.getMappedPropName("exotic-unknown"), "exotic-unknown");
    });
    test('should return security contexts for elements', () {
      expect(
          registry.securityContext('a', 'href'), TemplateSecurityContext.url);
    });
    test("should detect properties on namespaced elements", () {
      expect(registry.hasProperty("@svg:g", "id"), isTrue);
    });
  });
}
