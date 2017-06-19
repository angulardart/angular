@TestOn('browser')
library angular2.test.security.style_sanitizer_test;

import 'package:test/test.dart';
import 'package:angular/src/security/style_sanitizer.dart';

void main() {
  group('Style sanitizer', () {
    test('sanitizes values', () {
      expect(internalSanitizeStyle('abc'), 'abc');
      expect(internalSanitizeStyle('50px'), '50px');
      expect(internalSanitizeStyle('rgb(255, 0, 0)'), 'rgb(255, 0, 0)');
    });
    test('sanitizes style binding', () {
      expect(internalSanitizeStyle('width: 10px'), 'width: 10px');
      expect(internalSanitizeStyle('z-index: 1001'), 'z-index: 1001');
      expect(internalSanitizeStyle('z-index : 1001'), 'z-index : 1001');
      expect(internalSanitizeStyle('z-index: expression(haha)'), 'unsafe');
      expect(internalSanitizeStyle('z-index : expression(haha)'), 'unsafe');
      expect(internalSanitizeStyle('transform: translateX(10px);width: 10px'),
          'transform: translateX(10px);width: 10px');
      expect(
          internalSanitizeStyle(
              'transform: translateX(10px);width: expression(haha)'),
          'unsafe');
      String bindingValue = 'z-index: 1002;left: -1000px;width: 1000px;';
      expect(internalSanitizeStyle(bindingValue), bindingValue);
    });
    test('rejects unbalanced quotes', () {
      expect(internalSanitizeStyle('"value" "'), 'unsafe');
    });
    test('sanitizes functions', () {
      expect(internalSanitizeStyle('expression(haha)'), 'unsafe');
    });
    test('accepts transform functions', () {
      expect(internalSanitizeStyle('rotate(90deg)'), 'rotate(90deg)');
      expect(internalSanitizeStyle('rotate(javascript:evil())'), 'unsafe');
      expect(internalSanitizeStyle('translateX(12px, -5px)'),
          'translateX(12px, -5px)');
      expect(internalSanitizeStyle('translateX(12px) scaleX(1.5)'),
          'translateX(12px) scaleX(1.5)');
      expect(internalSanitizeStyle('scale3d(1, 1, 2)'), 'scale3d(1, 1, 2)');
    });
    test('sanitizes urls', () {
      expect(internalSanitizeStyle('url(foo/bar.png)'), 'url(foo/bar.png)');
      expect(internalSanitizeStyle('url(javascript:evil())'), 'unsafe');
      expect(internalSanitizeStyle('url(strangeprotocol:evil)'), 'unsafe');
    });
  });
}
