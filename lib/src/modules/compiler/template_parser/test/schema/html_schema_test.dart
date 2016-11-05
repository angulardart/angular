import 'package:angular2_template_parser/template_parser.dart';
import 'package:test/test.dart';

void main() {
  group('div', () {
    test('should be supported', () {
      expect(html5Schema.hasElement('div'), isTrue);
    });

    test('should support the title property', () {
      expect(html5Schema.elements['div'].hasProperty('title'), isTrue);
    });

    test('should support the click event', () {
      expect(html5Schema.elements['div'].hasEvent('click'), isTrue);
    });

    test('should not support unknown properties', () {
      expect(html5Schema.elements['div'].hasProperty('titel'), isFalse);
    });

    test('should not support unknown events', () {
      expect(html5Schema.elements['div'].hasEvent('clikc'), isFalse);
    });

    test('should support aria- labels', () {
      expect(html5Schema.elements['div'].hasProperty('aria-foo'), isTrue);
    });
  });

  group('input', () {
    test('should be supported', () {
      expect(html5Schema.hasElement('input'), isTrue);
    });
    test('should support the autofocus property', () {
      expect(html5Schema.elements['input'].hasProperty('autofocus'), isTrue);
    });

    test('should support the change event', () {
      expect(html5Schema.elements['input'].hasEvent('change'), isTrue);
    });

    test('should not support unknown properties', () {
      expect(html5Schema.elements['input'].hasProperty('klass'), isFalse);
    });

    test('should not support unknown events', () {
      expect(html5Schema.elements['input'].hasEvent('clikc'), isFalse);
    });
  });

  group('button', () {
    test('should be supported', () {
      expect(html5Schema.hasElement('button'), isTrue);
    });

    test('should support the autofocus property', () {
      expect(html5Schema.elements['button'].hasProperty('autofocus'), isTrue);
    });

    test('should support the click event', () {
      expect(html5Schema.elements['button'].hasEvent('click'), isTrue);
    });

    test('should not support unknown properties', () {
      expect(html5Schema.elements['button'].hasProperty('titel'), isFalse);
    });

    test('should not support unknown events', () {
      expect(html5Schema.elements['button'].hasEvent('onmosedown'), isFalse);
    });
  });

  test('should not support unknown elements', () {
    expect(html5Schema.hasElement('paper-button'), isFalse);
  });
}
