library angular2.test.compiler.style_url_resolver_test;

import "package:angular2/src/compiler/style_url_resolver.dart"
    show extractStyleUrls, isStyleUrlResolvable;
import "package:angular2/src/compiler/url_resolver.dart" show UrlResolver;
import 'package:test/test.dart';

void main() {
  group("extractStyleUrls", () {
    var urlResolver;
    setUp(() {
      urlResolver = new UrlResolver();
    });
    test("should not resolve \"url()\" urls", () {
      var css = '''
      .foo {
        background-image: url("double.jpg");
        background-image: url(\'simple.jpg\');
        background-image: url(noquote.jpg);
      }''';
      var resolvedCss =
          extractStyleUrls(urlResolver, "http://ng.io", css).style;
      expect(resolvedCss, css);
    });
    test("should extract \"@import\" urls", () {
      var css = '''
      @import \'1.css\';
      @import "2.css";
      ''';
      var styleWithImports = extractStyleUrls(urlResolver, "http://ng.io", css);
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
      var styleWithImports = extractStyleUrls(urlResolver, "http://ng.io", css);
      expect(styleWithImports.style.trim(), "");
      expect(styleWithImports.styleUrls,
          ["http://ng.io/3.css", "http://ng.io/4.css", "http://ng.io/5.css"]);
    });
    test("should extract \"@import urls and keep rules in the same line", () {
      var css = '''@import url(\'some.css\');div {color: red};''';
      var styleWithImports = extractStyleUrls(urlResolver, "http://ng.io", css);
      expect(styleWithImports.style.trim(), "div {color: red};");
      expect(styleWithImports.styleUrls, ["http://ng.io/some.css"]);
    });
    test("should extract media query in \"@import\"", () {
      var css = '''
      @import \'print1.css\' print;
      @import url(print2.css) print;
      ''';
      var styleWithImports = extractStyleUrls(urlResolver, "http://ng.io", css);
      expect(styleWithImports.style.trim(), "");
      expect(styleWithImports.styleUrls,
          ["http://ng.io/print1.css", "http://ng.io/print2.css"]);
    });
    test("should leave absolute non-package @import urls intact", () {
      var css = '''@import url(\'http://server.com/some.css\');''';
      var styleWithImports = extractStyleUrls(urlResolver, "http://ng.io", css);
      expect(styleWithImports.style.trim(),
          '''@import url(\'http://server.com/some.css\');''');
      expect(styleWithImports.styleUrls, []);
    });
    test("should resolve package @import urls", () {
      var css = '''@import url(\'package:a/b/some.css\');''';
      var styleWithImports =
          extractStyleUrls(new FakeUrlResolver(), "http://ng.io", css);
      expect(styleWithImports.style.trim(), '''''');
      expect(styleWithImports.styleUrls, ["fake_resolved_url"]);
    });
  });
  group("isStyleUrlResolvable", () {
    test("should resolve relative urls", () {
      expect(isStyleUrlResolvable("someUrl.css"), isTrue);
    });
    test("should resolve package: urls", () {
      expect(isStyleUrlResolvable("package:someUrl.css"), isTrue);
    });
    test("should resolve asset: urls", () {
      expect(isStyleUrlResolvable("asset:someUrl.css"), isTrue);
    });
    test("should not resolve empty urls", () {
      expect(isStyleUrlResolvable(null), isFalse);
      expect(isStyleUrlResolvable(""), isFalse);
    });
    test("should not resolve urls with other schema", () {
      expect(isStyleUrlResolvable("http://otherurl"), isFalse);
    });
    test("should not resolve urls with absolute paths", () {
      expect(isStyleUrlResolvable("/otherurl"), isFalse);
      expect(isStyleUrlResolvable("//otherurl"), isFalse);
    });
  });
}

/// The real thing behaves differently between Dart and JS for package URIs.
class FakeUrlResolver extends UrlResolver {
  FakeUrlResolver();
  String resolve(String baseUrl, String url) {
    return "fake_resolved_url";
  }
}
