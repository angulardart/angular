library angular2.src.compiler.schema.element_schema_registry;

import "package:angular2/src/core/security.dart";

abstract class ElementSchemaRegistry {
  bool hasProperty(String tagName, String propName);
  String getMappedPropName(String propName);
  TemplateSecurityContext securityContext(String tagName, String propName);
}
