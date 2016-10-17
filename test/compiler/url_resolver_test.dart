@TestOn('browser')
library angular2.test.compiler.url_resolver_test;

import "package:angular2/src/compiler/url_resolver.dart"
    show UrlResolver, createOfflineCompileUrlResolver;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void main() {
  group("UrlResolver", () {
    var resolver = new UrlResolver();
    group("absolute base url", () {
      test("should add a relative path to the base url", () {
        expect(resolver.resolve("http://www.foo.com", "bar"),
            "http://www.foo.com/bar");
        expect(resolver.resolve("http://www.foo.com/", "bar"),
            "http://www.foo.com/bar");
        expect(resolver.resolve("http://www.foo.com", "./bar"),
            "http://www.foo.com/bar");
        expect(resolver.resolve("http://www.foo.com/", "./bar"),
            "http://www.foo.com/bar");
      });
      test("should replace the base path", () {
        expect(resolver.resolve("http://www.foo.com/baz", "bar"),
            "http://www.foo.com/bar");
        expect(resolver.resolve("http://www.foo.com/baz", "./bar"),
            "http://www.foo.com/bar");
      });
      test("should append to the base path", () {
        expect(resolver.resolve("http://www.foo.com/baz/", "bar"),
            "http://www.foo.com/baz/bar");
        expect(resolver.resolve("http://www.foo.com/baz/", "./bar"),
            "http://www.foo.com/baz/bar");
      });
      test("should support \"..\" in the path", () {
        expect(resolver.resolve("http://www.foo.com/baz/", "../bar"),
            "http://www.foo.com/bar");
        expect(resolver.resolve("http://www.foo.com/1/2/3/", "../../bar"),
            "http://www.foo.com/1/bar");
        expect(resolver.resolve("http://www.foo.com/1/2/3/", "../biz/bar"),
            "http://www.foo.com/1/2/biz/bar");
        expect(resolver.resolve("http://www.foo.com/1/2/baz", "../../bar"),
            "http://www.foo.com/bar");
      });
      test("should ignore the base path when the url has a scheme", () {
        expect(resolver.resolve("http://www.foo.com", "http://www.bar.com"),
            "http://www.bar.com");
      });
      test("should support absolute urls", () {
        expect(resolver.resolve("http://www.foo.com", "/bar"),
            "http://www.foo.com/bar");
        expect(resolver.resolve("http://www.foo.com/", "/bar"),
            "http://www.foo.com/bar");
        expect(resolver.resolve("http://www.foo.com/baz", "/bar"),
            "http://www.foo.com/bar");
        expect(resolver.resolve("http://www.foo.com/baz/", "/bar"),
            "http://www.foo.com/bar");
      });
    });
    group("relative base url", () {
      test("should add a relative path to the base url", () {
        expect(resolver.resolve("foo/", "./bar"), "foo/bar");
        expect(resolver.resolve("foo/baz", "./bar"), "foo/bar");
        expect(resolver.resolve("foo/baz", "bar"), "foo/bar");
      });
      test("should support \"..\" in the path", () {
        expect(resolver.resolve("foo/baz", "../bar"), "bar");
        expect(resolver.resolve("foo/baz", "../biz/bar"), "biz/bar");
      });
      test("should support absolute urls", () {
        expect(resolver.resolve("foo/baz", "/bar"), "/bar");
        expect(resolver.resolve("foo/baz/", "/bar"), "/bar");
      });
      test(
          'should not resolve urls against the baseUrl when the url '
          'contains a scheme', () {
        resolver = new UrlResolver("my_packages_dir");
        expect(
            resolver.resolve("base/", "package:file"), "my_packages_dir/file");
        expect(resolver.resolve("base/", "http:super_file"), "http:super_file");
        expect(resolver.resolve("base/", "./mega_file"), "base/mega_file");
      });
    });
    group("packages", () {
      test("should resolve a url based on the application package", () {
        resolver = new UrlResolver("my_packages_dir");
        expect(resolver.resolve(null, "package:some/dir/file.txt"),
            "my_packages_dir/some/dir/file.txt");
        expect(
            resolver.resolve(null, "some/dir/file.txt"), "some/dir/file.txt");
      });
      test(
          'should contain a default value of "/packages" when nothing is '
          'provided for DART', () async {
        return inject([UrlResolver], (UrlResolver resolver) {
          expect(resolver.resolve(null, "package:file"), "/packages/file");
        });
      });
      test("should resolve a package value when present within the baseurl",
          () {
        resolver = new UrlResolver("/my_special_dir");
        expect(resolver.resolve("package:some_dir/", "matias.html"),
            "/my_special_dir/some_dir/matias.html");
      });
    });
    group("asset urls", () {
      UrlResolver resolver;
      setUp(() {
        resolver = createOfflineCompileUrlResolver();
      });
      test("should resolve package: urls into asset: urls", () {
        expect(resolver.resolve(null, "package:somePkg/somePath"),
            "asset:somePkg/lib/somePath");
      });
    });
    group("corner and error cases", () {
      test("should encode URLs before resolving", () {
        expect(
            resolver.resolve(
                "foo/baz",
                '''<p #p>Hello
        </p>'''),
            "foo/%3Cp%20#p%3EHello%0A%20%20%20%20%20%20%20%20%3C/p%3E");
      });
    });
  });
}
