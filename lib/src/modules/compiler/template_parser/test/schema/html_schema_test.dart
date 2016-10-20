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
  });

  test('should not support unknown elements', () {
    expect(html5Schema.hasElement('paper-button'), isFalse);
  });
}
