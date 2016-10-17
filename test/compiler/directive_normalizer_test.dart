@TestOn('browser')
library angular2.test.compiler.directive_normalizer_test;

import 'package:angular2/src/compiler/compile_metadata.dart'
    show CompileTypeMetadata, CompileTemplateMetadata;
import 'package:angular2/src/compiler/directive_normalizer.dart'
    show DirectiveNormalizer;
import 'package:angular2/src/compiler/xhr.dart' show XHR;
import 'package:angular2/src/compiler/xhr_mock.dart' show MockXHR;
import 'package:angular2/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

import 'test_bindings.dart' show TEST_PROVIDERS;

void main() {
  CompileTypeMetadata dirType;
  CompileTypeMetadata dirTypeWithHttpUrl;
  group('DirectiveNormalizer', () {
    beforeEachProviders(() => TEST_PROVIDERS);
    setUp(() {
      dirType = new CompileTypeMetadata(
          moduleUrl: 'package:some/module/a.js', name: 'SomeComp');
      dirTypeWithHttpUrl = new CompileTypeMetadata(
          moduleUrl: 'http://some/module/a.js', name: 'SomeComp');
    });
    group('load inline template', () {
      test('should store the template', () async {
        return inject([AsyncTestCompleter, DirectiveNormalizer],
            (AsyncTestCompleter completer, DirectiveNormalizer normalizer) {
          normalizer
              .normalizeTemplate(
                  dirType,
                  new CompileTemplateMetadata(
                      encapsulation: null,
                      template: "a",
                      templateUrl: null,
                      styles: [],
                      styleUrls: ["test.css"]))
              .then((CompileTemplateMetadata template) {
            expect(template.template, "a");
            expect(template.templateUrl, "package:some/module/a.js");
            completer.done();
          });
        });
      });
      test("should resolve styles on the annotation against the moduleUrl",
          () async {
        return inject([AsyncTestCompleter, DirectiveNormalizer],
            (AsyncTestCompleter completer, DirectiveNormalizer normalizer) {
          normalizer
              .normalizeTemplate(
                  dirType,
                  new CompileTemplateMetadata(
                      encapsulation: null,
                      template: "",
                      templateUrl: null,
                      styles: [],
                      styleUrls: ["test.css"]))
              .then((CompileTemplateMetadata template) {
            expect(template.styleUrls, ["package:some/module/test.css"]);
            completer.done();
          });
        });
      });
      test("should resolve styles in the template against the moduleUrl",
          () async {
        return inject([AsyncTestCompleter, DirectiveNormalizer],
            (AsyncTestCompleter completer, DirectiveNormalizer normalizer) {
          normalizer
              .normalizeTemplate(
                  dirType,
                  new CompileTemplateMetadata(
                      encapsulation: null,
                      template: "<style>@import test.css</style>",
                      templateUrl: null,
                      styles: [],
                      styleUrls: []))
              .then((CompileTemplateMetadata template) {
            expect(template.styleUrls, ["package:some/module/test.css"]);
            completer.done();
          });
        });
      });
    });
    group("load from templateUrl", () {
      test(
          'should load a template from a url that is resolved '
          'against moduleUrl', () async {
        return inject([AsyncTestCompleter, DirectiveNormalizer, XHR],
            (AsyncTestCompleter completer, DirectiveNormalizer normalizer,
                MockXHR xhr) {
          xhr.expect("package:some/module/sometplurl.html", "a");
          normalizer
              .normalizeTemplate(
                  dirType,
                  new CompileTemplateMetadata(
                      encapsulation: null,
                      template: null,
                      templateUrl: "sometplurl.html",
                      styles: [],
                      styleUrls: ["test.css"]))
              .then((CompileTemplateMetadata template) {
            expect(template.template, "a");
            expect(template.templateUrl, "package:some/module/sometplurl.html");
            completer.done();
          });
          xhr.flush();
        });
      });
      test("should resolve styles on the annotation against the moduleUrl",
          () async {
        return inject([AsyncTestCompleter, DirectiveNormalizer, XHR],
            (AsyncTestCompleter completer, DirectiveNormalizer normalizer,
                MockXHR xhr) {
          xhr.expect("package:some/module/tpl/sometplurl.html", "");
          normalizer
              .normalizeTemplate(
                  dirType,
                  new CompileTemplateMetadata(
                      encapsulation: null,
                      template: null,
                      templateUrl: "tpl/sometplurl.html",
                      styles: [],
                      styleUrls: ["test.css"]))
              .then((CompileTemplateMetadata template) {
            expect(template.styleUrls, ["package:some/module/test.css"]);
            completer.done();
          });
          xhr.flush();
        });
      });
      test("should resolve styles in the template against the templateUrl",
          () async {
        return inject([AsyncTestCompleter, DirectiveNormalizer, XHR],
            (AsyncTestCompleter completer, DirectiveNormalizer normalizer,
                MockXHR xhr) {
          xhr.expect("package:some/module/tpl/sometplurl.html",
              "<style>@import test.css</style>");
          normalizer
              .normalizeTemplate(
                  dirType,
                  new CompileTemplateMetadata(
                      encapsulation: null,
                      template: null,
                      templateUrl: "tpl/sometplurl.html",
                      styles: [],
                      styleUrls: []))
              .then((CompileTemplateMetadata template) {
            expect(template.styleUrls, ["package:some/module/tpl/test.css"]);
            completer.done();
          });
          xhr.flush();
        });
      });
    });
    test("should throw if no template was specified", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        expect(
            () => normalizer.normalizeTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null, styles: [], styleUrls: [])),
            throwsWith("No template specified for component SomeComp"));
      });
    });
  });
  group("normalizeLoadedTemplate", () {
    test("should store the viewEncapsulationin the result", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var viewEncapsulation = ViewEncapsulation.Native;
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: viewEncapsulation, styles: [], styleUrls: []),
            "",
            "package:some/module/",
            true);
        expect(template.encapsulation, viewEncapsulation);
      });
    });
    test("should keep the template as html", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "a",
            "package:some/module/",
            true);
        expect(template.template, "a");
      });
    });
    test("should collect ngContent", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<ng-content select=\"a\"></ng-content>",
            "package:some/module/",
            true);
        expect(template.ngContentSelectors, ["a"]);
      });
    });
    test("should normalize ngContent wildcard selector", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            '<ng-content></ng-content><ng-content select></ng-content>'
            '<ng-content select="*"></ng-content>',
            'package:some/module/',
            true);
        expect(template.ngContentSelectors, ["*", "*", "*"]);
      });
    });
    test("should collect top level styles in the template", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<style>a</style>",
            "package:some/module/",
            true);
        expect(template.styles, ["a"]);
      });
    });
    test("should collect styles inside in elements", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<div><style>a</style></div>",
            "package:some/module/",
            true);
        expect(template.styles, ["a"]);
      });
    });
    test("should collect styleUrls in the template", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<link rel=\"stylesheet\" href=\"aUrl\">",
            "package:some/module/",
            true);
        expect(template.styleUrls, ["package:some/module/aUrl"]);
      });
    });
    test("should collect styleUrls in elements", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<div><link rel=\"stylesheet\" href=\"aUrl\"></div>",
            "package:some/module/",
            true);
        expect(template.styleUrls, ["package:some/module/aUrl"]);
      });
    });
    test("should ignore link elements with non stylesheet rel attribute",
        () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<link href=\"b\" rel=\"a\">",
            "package:some/module/",
            true);
        expect(template.styleUrls, []);
      });
    });
    test(
        'should ignore link elements with absolute urls but '
        'non package: scheme', () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<link href=\"http://some/external.css\" rel=\"stylesheet\">",
            "package:some/module/",
            true);
        expect(template.styleUrls, []);
      });
    });
    test("should extract @import style urls into styleAbsUrl", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null,
                styles: ["@import \"test.css\";"],
                styleUrls: []),
            "",
            "package:some/module/id",
            true);
        expect(template.styles, [""]);
        expect(template.styleUrls, ["package:some/module/test.css"]);
      });
    });
    test("should not resolve relative urls in inline styles", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null,
                styles: [".foo{background-image: url('double.jpg');"],
                styleUrls: []),
            "",
            "package:some/module/id",
            true);
        expect(template.styles, [".foo{background-image: url('double.jpg');"]);
      });
    });
    test("should resolve relative style urls in styleUrls", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: ["test.css"]),
            "",
            "package:some/module/id",
            true);
        expect(template.styles, []);
        expect(template.styleUrls, ["package:some/module/test.css"]);
      });
    });
    test(
        'should resolve relative style urls in styleUrls with '
        'http directive url', () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirTypeWithHttpUrl,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: ["test.css"]),
            "",
            "http://some/module/id",
            true);
        expect(template.styles, []);
        expect(template.styleUrls, ["http://some/module/test.css"]);
      });
    });
    test(
        'should normalize ViewEncapsulation.Emulated to ViewEncapsulation. '
        'None if there are no styles nor stylesheets', () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: ViewEncapsulation.Emulated,
                styles: [],
                styleUrls: []),
            "",
            "package:some/module/id",
            true);
        expect(template.encapsulation, ViewEncapsulation.None);
      });
    });
    test("should ignore ng-content in elements with ngNonBindable", () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<div ngNonBindable><ng-content select=\"a\"></ng-content></div>",
            "package:some/module/",
            true);
        expect(template.ngContentSelectors, []);
      });
    });
    test("should still collect <style> in elements with ngNonBindable",
        () async {
      return inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<div ngNonBindable><style>div {color:red}</style></div>",
            "package:some/module/",
            true);
        expect(template.styles, ["div {color:red}"]);
      });
    });
  });
}
