import 'package:angular_compiler/v1/src/compiler/security.dart';

abstract class ElementSchemaRegistry {
  bool hasProperty(String tagName, String propName);
  String getMappedPropName(String propName);
  TemplateSecurityContext securityContext(String tagName, String propName);
}
