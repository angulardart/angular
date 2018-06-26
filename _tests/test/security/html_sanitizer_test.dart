@TestOn('browser')
library angular2.test.security.html_sanitizer_test;

import 'package:test/test.dart';
import 'package:angular/src/security/html_sanitizer.dart';

void _testSanitize(String input, String expectedOutput, bool knownFailure) {
  String output;
  try {
    output = sanitizeHtmlInternal(input);
  } on TypeError catch (e) {
    if ('$e' == "type 'JavaScriptFunction' is not a subtype of type 'Node'" &&
        knownFailure) {
      print("known failure on Chrome and Firefox - "
          "See https://github.com/dart-lang/angular2/issues/80");
      return;
    }
    rethrow;
  }
  expect(output, expectedOutput);
}

void main() {
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
    group('supports namespaced attributes', () {
      var inputs = [
        '<a xlink:href="something">t</a>',
        '<a xlink:evil="something">t</a>',
        '<a xlink:href="javascript:foo()">t</a>'
      ];

      for (var input in inputs) {
        test(input, () {
          _testSanitize(input, '<a>t</a>', false);
        });
      }
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
      group('elements', () {
        var dangerousTags = <String>[
          'frameset',
          'param',
          'embed',
          'link',
          'base',
          'basefont'
        ];
        for (String tag in dangerousTags) {
          test(tag, () {
            String testInput = '<$tag>evil!</$tag>';
            _testSanitize(testInput, 'evil!', tag == 'embed');
          });
        }
      });
      group('Swallows tag & content', () {
        var dangerousTags = <String>[
          'object',
          'script',
          'style',
        ];

        for (String tag in dangerousTags) {
          test(tag, () {
            String testInput = '<$tag>evil!</$tag>';
            _testSanitize(testInput, '', tag == 'object');
          });
        }
      });
      test('swallows frame entirely', () {
        String testInput = '<frame>evil!</frame>';
        expect(sanitizeHtmlInternal(testInput).contains('<frame>'), false);
      });
    });
    test('should strip style attribute', () {
      var dangerousAttrs = ['style'];
      for (var attrName in dangerousAttrs) {
        String testInput = '<a $attrName="x">evil!</a>';
        expect(sanitizeHtmlInternal(testInput), '<a>evil!</a>');
      }
    });
  });
}
