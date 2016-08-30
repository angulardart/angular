@TestOn('browser')
library angular2.test.security.html_sanitizer_test;

import "package:angular2/src/platform/browser/browser_adapter.dart"
    show BrowserDomAdapter;
import 'package:angular2/src/security/html_sanitizer.dart';
import 'package:test/test.dart';

main() {
  BrowserDomAdapter.makeCurrent();
  group('HTML sanitizer', () {
    test('serializes nested structures', () {
      String inputHtml =
          '<div alt="x"><p>a</p>b<b>c<a alt="more">d</a></b>e</div>';
      String expected = '<div><p>a</p>b<b>c<a>d</a></b>e</div>';
      expect(sanitizeHtmlInternal(inputHtml), expected);
    });

    test('serializes self closing elements', () {
      String inputHtml = '<p>Hello <br> World</p>';
      String expected = '<p>Hello <br> World</p>';
      expect(sanitizeHtmlInternal(inputHtml), expected);
    });

    test('supports namespaced elements', () {
      String inputHtml = 'a<my:hr></my:hr><div>b</div>c';
      String expected = 'a<div>b</div>c';
      expect(sanitizeHtmlInternal(inputHtml), expected);
    });
    test('supports namespaced attributes', () {
      String testInput = '<a xlink:href="something">t</a>';
      String expected = '<a>t</a>';
      expect(sanitizeHtmlInternal(testInput), expected);

      testInput = '<a xlink:evil="something">t</a>';
      expected = '<a>t</a>';
      expect(sanitizeHtmlInternal(testInput), expected);

      testInput = '<a xlink:href="javascript:foo()">t</a>';
      expected = '<a>t</a>';
      expect(sanitizeHtmlInternal(testInput), expected);
    });
    test('supports sanitizing plain text', () {
      String testInput = 'Hello, World';
      String expected = 'Hello, World';
      expect(sanitizeHtmlInternal(testInput), expected);
    });
    test('supports non-element, non-attribute nodes', () {
      String testInput = '<!-- comments? -->no.';
      String expected = '<!-- comments? -->no.';
      expect(sanitizeHtmlInternal(testInput), expected);
      testInput = '<?pi nodes?>no.';
      expected = '<!--?pi nodes?-->no.';
      expect(sanitizeHtmlInternal(testInput), expected);
    });
    test('escaped entities', () {
      String testInput = '<p>Hello &lt; World</p>';
      String expected = '<p>Hello &lt; World</p>';
      expect(sanitizeHtmlInternal(testInput), expected);
      testInput = '<img alt="% &amp; &quot; !">Hello';
      expected = '<img alt="% &amp; &quot; !">Hello';
      expect(sanitizeHtmlInternal(testInput), expected);
    });
    group('should strip dangerous', () {
      test('elements', () {
        var dangerousTags = <String>[
          'frameset',
          'param',
          'embed',
          'link',
          'base',
          'basefont'
        ];
        for (String tag in dangerousTags) {
          String testInput = '<$tag>evil!</$tag>';
          String expected = 'evil!';
          expect(
              '$tag: ' + sanitizeHtmlInternal(testInput), '$tag: ' + expected);
        }
      });
      test('Swallows tag & content', () {
        var dangerousTags = <String>[
          'object',
          'script',
          'style',
        ];
        for (String tag in dangerousTags) {
          String testInput = '<$tag>evil!</$tag>';
          String expected = '';
          expect(
              '$tag: ' + sanitizeHtmlInternal(testInput), '$tag: ' + expected);
        }
      });
      test('swallows frame entirely', () {
        String testInput = '<frame>evil!</frame>';
        expect(sanitizeHtmlInternal(testInput).contains('<frame>'), isFalse);
      });
    });
    test('should strip style attribute', () {
      var dangerousAttrs = ['style'];
      for (var attrName in dangerousAttrs) {
        String testInput = '<a ${attrName}="x">evil!</a>';
        expect(sanitizeHtmlInternal(testInput), '<a>evil!</a>');
      }
    });
    test('should prevent mXSS attacks', () {
      String testInput = '<a href="&#x3000;javascript:alert(1)">CLICKME</a>';
      String expected = '<a>CLICKME</a>';
      expect(sanitizeHtmlInternal(testInput), expected);
    });
  });
}
