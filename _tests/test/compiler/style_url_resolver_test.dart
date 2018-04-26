@TestOn('vm')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/src/compiler/style_url_resolver.dart'
    show extractStyleUrls, isStyleUrlResolvable;
import 'package:angular_compiler/angular_compiler.dart';

void main() {
  group("extractStyleUrls", () {
    test("should not resolve \"url()\" urls", () {
      var css = '''
      .foo {
        background-image: url("double.jpg");
        background-image: url(\'simple.jpg\');
        background-image: url(noquote.jpg);
      }''';
      var resolvedCss = extractStyleUrls("http://ng.io", css).style;
      expect(resolvedCss, css);
    });
    test("should extract \"@import\" urls", () {
      var css = '''
      @import \'1.css\';
      @import "2.css";
      ''';
      var styleWithImports = extractStyleUrls("http://ng.io", css);
      expect(styleWithImports.style.trim(), "");
      expect(styleWithImports.styleUrls,
          ["http://ng.io/1.css", "http://ng.io/2.css"]);
    });
    test("should extract \"@import url()\" urls", () {
      var css = '''
      @import url(\'3.css\');
      @import url("4.css");
      @import url(5.css);
      ''';
      var styleWithImports = extractStyleUrls("http://ng.io", css);
      expect(styleWithImports.style.trim(), "");
      expect(styleWithImports.styleUrls,
          ["http://ng.io/3.css", "http://ng.io/4.css", "http://ng.io/5.css"]);
    });
    test("should extract \"@import urls and keep rules in the same line", () {
      var css = '''@import url(\'some.css\');div {color: red};''';
      var styleWithImports = extractStyleUrls("http://ng.io", css);
      expect(styleWithImports.style.trim(), "div {color: red};");
      expect(styleWithImports.styleUrls, ["http://ng.io/some.css"]);
    });
    test("should extract media query in \"@import\"", () {
      var css = '''
      @import \'print1.css\' print;
      @import url(print2.css) print;
      ''';
      var styleWithImports = extractStyleUrls("http://ng.io", css);
      expect(styleWithImports.style.trim(), "");
      expect(styleWithImports.styleUrls,
          ["http://ng.io/print1.css", "http://ng.io/print2.css"]);
    });
    test("should leave absolute non-package @import urls intact", () {
      var css = '''@import url(\'http://server.com/some.css\');''';
      var styleWithImports = extractStyleUrls("http://ng.io", css);
      expect(styleWithImports.style.trim(),
          '''@import url(\'http://server.com/some.css\');''');
      expect(styleWithImports.styleUrls, []);
    });
    test("should resolve package @import urls", () {
      var css = '''@import url(\'package:a/b/some.css\');''';
      var styleWithImports = extractStyleUrls("http://ng.io", css);
      expect(styleWithImports.style.trim(), '''''');
      expect(styleWithImports.styleUrls, ["package:a/b/some.css"]);
    });
  });
  group("isStyleUrlResolvable", () {
    test("should resolve relative urls", () {
      expect(isStyleUrlResolvable("someUrl.css"), true);
    });
    test("should resolve package: urls", () {
      expect(isStyleUrlResolvable("package:someUrl.css"), true);
    });
    test("should resolve asset: urls", () {
      expect(isStyleUrlResolvable("asset:someUrl.css"), true);
    });
    test("should not resolve empty urls", () {
      expect(isStyleUrlResolvable(null), false);
      expect(isStyleUrlResolvable(""), false);
    });
    test("should not resolve urls with other schema", () {
      expect(isStyleUrlResolvable("http://otherurl"), false);
    });
    test("should not resolve urls with absolute paths", () {
      expect(isStyleUrlResolvable("/otherurl"), false);
      expect(isStyleUrlResolvable("//otherurl"), false);
    });
  });
}

/// The real thing behaves differently between Dart and JS for package URIs.
class FakeAssetReader extends NgAssetReader {
  String resolve(String baseUrl, String url) {
    return "fake_resolved_url";
  }

  @override
  Future<String> readText(String url) async => '';

  @override
  Future<bool> canRead(String url) async => true;
}
