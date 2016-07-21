library angular2.test.compiler.schema_registry_mock;

import 'package:angular2/src/compiler/schema/element_schema_registry.dart';
import 'package:angular2/src/core/security.dart';

class MockSchemaRegistry implements ElementSchemaRegistry {
  Map<String, bool> existingProperties;
  Map<String, String> attrPropMapping;
  MockSchemaRegistry(this.existingProperties, this.attrPropMapping);

  @override
  bool hasProperty(String tagName, String property) =>
      existingProperties[property] ?? true;

  @override
  String getMappedPropName(String attrName) =>
      this.attrPropMapping[attrName] ?? attrName;

  @override
  TemplateSecurityContext securityContext(String tagName, String property) {
    return TemplateSecurityContext.none;
  }
}
