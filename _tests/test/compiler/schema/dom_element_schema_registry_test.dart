@TestOn('vm')
import 'package:test/test.dart';
import 'package:angular/src/compiler/schema/dom_element_schema_registry.dart'
    show DomElementSchemaRegistry;
import 'package:angular/src/compiler/security.dart';

void main() {
  group('DOMElementSchema', () {
    DomElementSchemaRegistry registry;
    setUp(() {
      registry = DomElementSchemaRegistry();
    });
    test('should detect properties on regular elements', () {
      expect(registry.hasProperty('div', 'id'), true);
      expect(registry.hasProperty('div', 'title'), true);
      expect(registry.hasProperty('h1', 'align'), true);
      expect(registry.hasProperty('h2', 'align'), true);
      expect(registry.hasProperty('h3', 'align'), true);
      expect(registry.hasProperty('h4', 'align'), true);
      expect(registry.hasProperty('h5', 'align'), true);
      expect(registry.hasProperty('h6', 'align'), true);
      expect(registry.hasProperty('h7', 'align'), false);
      expect(registry.hasProperty('textarea', 'disabled'), true);
      expect(registry.hasProperty('input', 'disabled'), true);
      expect(registry.hasProperty('div', 'unknown'), false);
    });
    test('should detect different kinds of types', () {
      // inheritance: video => media => *
      expect(registry.hasProperty('video', 'className'), true);
      expect(registry.hasProperty('video', 'id'), true);
      expect(registry.hasProperty('video', 'scrollLeft'), true);
      expect(registry.hasProperty('video', 'height'), true);
      expect(registry.hasProperty('video', 'autoplay'), true);
      expect(registry.hasProperty('video', 'classList'), true);
      // from *; but events are not properties
      expect(registry.hasProperty('video', 'click'), false);
    });
    test('should return false for custom-like elements', () {
      expect(registry.hasProperty('custom-like', 'unknown'), false);
    });
    test('should re-map property names that are specified in DOM facade', () {
      expect(registry.getMappedPropName('readonly'), 'readOnly');
    });
    test(
        'should not re-map property names that are not specified in DOM facade',
        () {
      expect(registry.getMappedPropName('title'), 'title');
      expect(registry.getMappedPropName('exotic-unknown'), 'exotic-unknown');
    });
    test('should return security contexts for elements', () {
      expect(
          registry.securityContext('a', 'href'), TemplateSecurityContext.url);
    });
    test('should detect properties on namespaced elements', () {
      expect(registry.hasProperty('@svg:g', 'id'), true);
    });
  });
}
