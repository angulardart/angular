// @dart=2.9

import 'package:angular_compiler/v1/src/compiler/schema/element_schema_registry.dart';
import 'package:angular_compiler/v1/src/compiler/security.dart';

class MockSchemaRegistry implements ElementSchemaRegistry {
  final Map<String, bool> existingProperties;
  final Map<String, String> attrPropMapping;
  const MockSchemaRegistry(this.existingProperties, this.attrPropMapping);

  @override
  bool hasProperty(String tagName, String property) =>
      existingProperties[property] ?? true;

  // Allows any attribute name to avoid validation errors in tests.
  @override
  bool hasAttribute(String tagName, String attributeName) => true;

  // Allows any event name to avoid validation errors in tests.
  @override
  bool hasEvent(String tagName, String eventName) => true;

  @override
  String getMappedPropName(String attrName) =>
      attrPropMapping[attrName] ?? attrName;

  @override
  TemplateSecurityContext securityContext(String tagName, String property) {
    return TemplateSecurityContext.none;
  }
}
