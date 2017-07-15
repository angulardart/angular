@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:async';

import 'package:test/test.dart';
import 'package:_tests/test_util.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/compiler/compile_metadata.dart'
    show CompileTypeMetadata, CompileTemplateMetadata;
import 'package:angular/src/compiler/directive_normalizer.dart'
    show DirectiveNormalizer;
import 'package:angular/src/compiler/html_parser.dart';
import 'package:angular/src/compiler/xhr_mock.dart' show MockXHR;
import 'package:angular/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular_test/angular_test.dart';

void main() {
  CompileTypeMetadata dirType;
  CompileTypeMetadata dirTypeWithHttpUrl;
  group('DirectiveNormalizer', () {
    setUp(() {
      dirType = new CompileTypeMetadata(
          moduleUrl: 'package:some/module/a.js', name: 'SomeComp');
      dirTypeWithHttpUrl = new CompileTypeMetadata(
          moduleUrl: 'http://some/module/a.js', name: 'SomeComp');
    });

    tearDown(disposeAnyRunningTest);

    group('load inline template', () {
      test('should store the template', () async {
        var normalizer = await getNormalizer();
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
        });
      });
      test("should resolve styles on the annotation against the moduleUrl",
          () async {
        var normalizer = await getNormalizer();
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
        });
      });
      test("should resolve styles in the template against the moduleUrl",
          () async {
        var normalizer = await getNormalizer();
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
        });
      });
    });
    group("load from templateUrl", () {
      test(
          'should load a template from a url that is resolved '
          'against moduleUrl', () async {
        var data = await getNormalizerAndXHR();
        var normalizer = data.normalizer;
        var xhr = data.xhr;
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
        });
        xhr.flush();
      });
      test("should resolve styles on the annotation against the moduleUrl",
          () async {
        var data = await getNormalizerAndXHR();
        var normalizer = data.normalizer;
        var xhr = data.xhr;
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
        });
        xhr.flush();
      });
      test("should resolve styles in the template against the templateUrl",
          () async {
        var data = await getNormalizerAndXHR();
        var normalizer = data.normalizer;
        var xhr = data.xhr;
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
        });
        xhr.flush();
      });
      test("should throw if no template was specified", () async {
        var normalizer = await getNormalizer();
        expect(
            () => normalizer.normalizeTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null, styles: [], styleUrls: [])),
            throwsWith("No template specified for component SomeComp"));
      });
    });
    group("normalizeLoadedTemplate", () {
      test("should store the viewEncapsulationin the result", () async {
        var viewEncapsulation = ViewEncapsulation.Native;
        var normalizer = await getNormalizer();
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: viewEncapsulation, styles: [], styleUrls: []),
            "",
            "package:some/module/",
            true);
        expect(template.encapsulation, viewEncapsulation);
      });
      test("should keep the template as html", () async {
        var normalizer = await getNormalizer();
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "a",
            "package:some/module/",
            true);
        expect(template.template, "a");
      });
      test("should collect ngContent", () async {
        var normalizer = await getNormalizer();
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<ng-content select=\"a\"></ng-content>",
            "package:some/module/",
            true);
        expect(template.ngContentSelectors, ["a"]);
      });
      test("should normalize ngContent wildcard selector", () async {
        var normalizer = await getNormalizer();
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
      test("should collect top level styles in the template", () async {
        var normalizer = await getNormalizer();
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<style>a</style>",
            "package:some/module/",
            true);
        expect(template.styles, ["a"]);
      });
      test("should collect styles inside in elements", () async {
        var normalizer = await getNormalizer();
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<div><style>a</style></div>",
            "package:some/module/",
            true);
        expect(template.styles, ["a"]);
      });
      test("should collect styleUrls in the template", () async {
        var normalizer = await getNormalizer();
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<link rel=\"stylesheet\" href=\"aUrl\">",
            "package:some/module/",
            true);
        expect(template.styleUrls, ["package:some/module/aUrl"]);
      });
      test("should collect styleUrls in elements", () async {
        var normalizer = await getNormalizer();
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<div><link rel=\"stylesheet\" href=\"aUrl\"></div>",
            "package:some/module/",
            true);
        expect(template.styleUrls, ["package:some/module/aUrl"]);
      });
      test("should ignore link elements with non stylesheet rel attribute",
          () async {
        var normalizer = await getNormalizer();
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<link href=\"b\" rel=\"a\">",
            "package:some/module/",
            true);
        expect(template.styleUrls, []);
      });
      test(
          'should ignore link elements with absolute urls but '
          'non package: scheme', () async {
        var normalizer = await getNormalizer();
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<link href=\"http://some/external.css\" rel=\"stylesheet\">",
            "package:some/module/",
            true);
        expect(template.styleUrls, []);
      });
      test("should extract @import style urls into styleAbsUrl", () async {
        var normalizer = await getNormalizer();
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
      test("should not resolve relative urls in inline styles", () async {
        var normalizer = await getNormalizer();
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
      test("should resolve relative style urls in styleUrls", () async {
        var normalizer = await getNormalizer();
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
      test(
          'should resolve relative style urls in styleUrls with '
          'http directive url', () async {
        var normalizer = await getNormalizer();
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
      test(
          'should normalize ViewEncapsulation.Emulated to ViewEncapsulation. '
          'None if there are no styles nor stylesheets', () async {
        var normalizer = await getNormalizer();
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
      test("should ignore ng-content in elements with ngNonBindable", () async {
        var normalizer = await getNormalizer();
        var template = normalizer.normalizeLoadedTemplate(
            dirType,
            new CompileTemplateMetadata(
                encapsulation: null, styles: [], styleUrls: []),
            "<div ngNonBindable><ng-content select=\"a\"></ng-content></div>",
            "package:some/module/",
            true);
        expect(template.ngContentSelectors, []);
      });
      test("should still collect <style> in elements with ngNonBindable",
          () async {
        var normalizer = await getNormalizer();
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

@Component(selector: 'test', template: '')
class DirectiveNormalizerTest {
  DirectiveNormalizer directiveNormalizer;
  final xhr = new MockXHR();

  DirectiveNormalizerTest() {
    directiveNormalizer = new DirectiveNormalizer(
      xhr,
      new UrlResolver(),
      new HtmlParser(),
    );
  }
}

Future<DirectiveNormalizer> getNormalizer() async {
  var fixture = await new NgTestBed<DirectiveNormalizerTest>().create();
  DirectiveNormalizer normalizer;
  await fixture.update((DirectiveNormalizerTest component) {
    normalizer = component.directiveNormalizer;
  });
  return normalizer;
}

class NormalizerAndXHR {
  final DirectiveNormalizer normalizer;
  final MockXHR xhr;

  NormalizerAndXHR(this.normalizer, this.xhr);
}

Future<NormalizerAndXHR> getNormalizerAndXHR() async {
  var fixture = await new NgTestBed<DirectiveNormalizerTest>().create();
  NormalizerAndXHR result;
  await fixture.update((DirectiveNormalizerTest component) {
    result = new NormalizerAndXHR(component.directiveNormalizer, component.xhr);
  });
  return result;
}
