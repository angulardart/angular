@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/src/security/dom_sanitization_service.dart';
import 'package:angular/src/security/dom_sanitization_service_impl.dart';

void main() {
  final DomSanitizationService sanitizer = DomSanitizationServiceImpl();
  const safeHtml = '<p>poodle power</p>';
  const unsafeHtml = 'a <script>alert("hi")</script> b';

  group('sanitizeHtml', () {
    test('passes null through', () {
      expect(sanitizer.sanitizeHtml(null), null);
    });

    test('passes safe strings through untouched', () {
      expect(sanitizer.sanitizeHtml(safeHtml), safeHtml);
    });

    test('removes unsafe tags', () {
      expect(sanitizer.sanitizeHtml(unsafeHtml), 'a  b');
    });

    test('passes SafeHtml through untouched', () {
      expect(
          sanitizer.sanitizeHtml(sanitizer.bypassSecurityTrustHtml(unsafeHtml)),
          unsafeHtml);
    });

    test('rejects other SafeValues', () {
      expect(
          () => sanitizer.sanitizeHtml(
              sanitizer.bypassSecurityTrustUrl('https://google.com')),
          throwsUnsupportedError);
    });
  });

  group('sanitizeStyle', () {
    const safeStyle = 'color: red;';
    const unsafeStyle = 'background-image: url("javascript:uh-oh")';

    test('passes null through', () {
      expect(sanitizer.sanitizeStyle(null), null);
    });

    test('passes normal styles untouched', () {
      expect(sanitizer.sanitizeStyle(safeStyle), safeStyle);
    });

    test('rejects unsafe styles', () {
      expect(
          sanitizer.sanitizeStyle(unsafeStyle), isNot(contains('javascript')));
    });

    test('passes SafeStyle through untouched', () {
      expect(
          sanitizer
              .sanitizeStyle(sanitizer.bypassSecurityTrustStyle(unsafeStyle)),
          unsafeStyle);
    });

    test('rejects other SafeValues', () {
      expect(
          () => sanitizer.sanitizeStyle(
              sanitizer.bypassSecurityTrustUrl('https://google.com')),
          throwsUnsupportedError);
    });
  });

  group('sanitizeUrl', () {
    const safeUrl = 'https://google.com';
    const unsafeUrl = 'javascript:alert("arghhhh")';

    test('passes null through', () {
      expect(sanitizer.sanitizeUrl(null), null);
    });

    test('passes normal URLs untouched', () {
      expect(sanitizer.sanitizeUrl(safeUrl), safeUrl);
    });

    test('rejects unsafe URLs', () {
      expect(sanitizer.sanitizeUrl(unsafeUrl), isNot(contains('javascript')));
    });

    test('passes SafeUrl through untouched', () {
      expect(sanitizer.sanitizeUrl(sanitizer.bypassSecurityTrustUrl(unsafeUrl)),
          unsafeUrl);
    });

    test('rejects other SafeValues', () {
      expect(
          () => sanitizer
              .sanitizeUrl(sanitizer.bypassSecurityTrustHtml('<p>egg</p>')),
          throwsUnsupportedError);
    });
  });

  group('sanitizeResourceUrl', () {
    const resourceUrl = 'https://google.com/some_script.js';

    test('passes null through', () {
      expect(sanitizer.sanitizeResourceUrl(null), null);
    });

    test('rejects all strings', () {
      expect(() => sanitizer.sanitizeResourceUrl(resourceUrl),
          throwsUnsupportedError);
    });

    test('passes SafeResourceUrl through untouched', () {
      expect(
          sanitizer.sanitizeResourceUrl(
              sanitizer.bypassSecurityTrustResourceUrl(resourceUrl)),
          resourceUrl);
    });

    test('rejects other SafeValues', () {
      expect(
          () => sanitizer.sanitizeResourceUrl(
              sanitizer.bypassSecurityTrustUrl('https://google.com')),
          throwsUnsupportedError);
    });
  });
}
