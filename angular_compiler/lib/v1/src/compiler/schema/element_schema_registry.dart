import 'package:angular_compiler/v1/src/compiler/security.dart';

abstract class ElementSchemaRegistry {
  bool hasProperty(String tagName, String propName);
  bool hasAttribute(String tagName, String attributeName);
  bool hasEvent(String tagName, String eventName);
  String getMappedPropName(String propName);
  TemplateSecurityContext securityContext(String tagName, String propName);
}
