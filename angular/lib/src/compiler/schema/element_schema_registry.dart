import "package:angular/src/core/security.dart";

abstract class ElementSchemaRegistry {
  bool hasProperty(String tagName, String propName);
  String getMappedPropName(String propName);
  TemplateSecurityContext securityContext(String tagName, String propName);
}
