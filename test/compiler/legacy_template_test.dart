library angular2.test.compiler.legacy_template_test;

import "package:angular2/src/compiler/html_ast.dart";
import "package:angular2/src/compiler/legacy_template.dart"
    show LegacyHtmlAstTransformer;
import 'package:test/test.dart';

main() {
  group("Support for legacy template", () {
    group("Template rewriting", () {
      var visitor;
      setUp(() {
        visitor = new LegacyHtmlAstTransformer(["yes-mapped"]);
      });
      group("non template elements", () {
        test("should rewrite event binding", () {
          var fixtures = [
            {"from": "on-dash-case", "to": "on-dashCase"},
            {"from": "ON-dash-case", "to": "on-dashCase"},
            {"from": "bindon-dash-case", "to": "bindon-dashCase"},
            {"from": "(dash-case)", "to": "(dashCase)"},
            {"from": "[(dash-case)]", "to": "[(dashCase)]"},
            {"from": "on-camelCase", "to": "on-camelCase"},
            {"from": "bindon-camelCase", "to": "bindon-camelCase"},
            {"from": "(camelCase)", "to": "(camelCase)"},
            {"from": "[(camelCase)]", "to": "[(camelCase)]"}
          ];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst(f["from"], "expression", null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, f["to"]);
            expect(attr.value, "expression");
          });
        });
        test("should not rewrite style binding", () {
          var fixtures = [
            {
              "from": "[style.background-color]",
              "to": "[style.background-color]"
            },
            {"from": "[style.margin-top.px]", "to": "[style.margin-top.px]"},
            {"from": "[style.camelCase]", "to": "[style.camelCase]"},
            {"from": "[STYLE.camelCase]", "to": "[style.camelCase]"}
          ];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst(f["from"], "expression", null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, f["to"]);
            expect(attr.value, "expression");
          });
        });
        test("should not rewrite attribute bindings", () {
          var fixtures = [
            {"from": "[attr.my-attr]", "to": "[attr.my-attr]"},
            {"from": "[ATTR.my-attr]", "to": "[attr.my-attr]"}
          ];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst(f["from"], "expression", null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, f["to"]);
            expect(attr.value, "expression");
          });
        });
        test("should not rewrite class bindings", () {
          var fixtures = [
            {"from": "[class.my-class]", "to": "[class.my-class]"},
            {"from": "[CLASS.my-class]", "to": "[class.my-class]"}
          ];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst(f["from"], "expression", null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, f["to"]);
            expect(attr.value, "expression");
          });
        });
        test("should rewrite variables", () {
          var fixtures = [
            {"from": "#dash-case", "to": "#dashCase"},
            {"from": "var-dash-case", "to": "var-dashCase"},
            {"from": "VAR-dash-case", "to": "var-dashCase"},
            {"from": "VAR-camelCase", "to": "var-camelCase"}
          ];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst(f["from"], "expression", null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, f["to"]);
            expect(attr.value, "expression");
          });
        });
        test("should rewrite variable values", () {
          var fixtures = [
            {"from": "dash-case", "to": "dashCase"},
            {"from": "lower", "to": "lower"},
            {"from": "camelCase", "to": "camelCase"}
          ];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst("#a", f["from"], null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, "#a");
            expect(attr.value, f["to"]);
            legacyAttr = new HtmlAttrAst("var-a", f["from"], null);
            attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, "var-a");
            expect(attr.value, f["to"]);
          });
        });
        test("should rewrite variables in template bindings", () {
          var fixtures = [
            {"from": "dir: #a-b", "to": "dir: #aB"},
            {"from": "dir: var a-b", "to": "dir: var aB"},
            {"from": "dir: VAR a-b;", "to": "dir: var aB;"},
            {"from": "dir: VAR a-b; #c-d=e", "to": "dir: var aB; #cD=e"},
            {"from": "dir: VAR aB; #cD=e", "to": "dir: var aB; #cD=e"}
          ];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst("template", f["from"], null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.value, f["to"]);
          });
        });
        test("should lowercase the \"template\" attribute", () {
          var fixtures = ["Template", "TEMPLATE", "template"];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst(f, "expression", null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, "template");
            expect(attr.value, "expression");
          });
        });
        test("should rewrite property binding", () {
          var fixtures = [
            {"from": "[my-prop]", "to": "[myProp]"},
            {"from": "bind-my-prop", "to": "bind-myProp"}
          ];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst(f["from"], "expression", null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, f["to"]);
            expect(attr.value, "expression");
          });
        });
        test("should rewrite structural directive selectors template=\"...\"",
            () {
          var legacyAttr = new HtmlAttrAst("TEMPLATE", "ng-if condition", null);
          var attr = visitor.visitAttr(legacyAttr, null);
          expect(attr.name, "template");
          expect(attr.value, "ngIf condition");
        });
        test("should rewrite *-selectors", () {
          var legacyAttr =
              new HtmlAttrAst("*ng-for", "#my-item of myItems", null);
          var attr = visitor.visitAttr(legacyAttr, null);
          expect(attr.name, "*ngFor");
          expect(attr.value, "#myItem of myItems");
        });
        test("should rewrite directive special cases", () {
          var fixtures = [
            {"from": "ng-non-bindable", "to": "ngNonBindable"},
            {"from": "yes-mapped", "to": "yesMapped"},
            {"from": "no-mapped", "to": "no-mapped"}
          ];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst(f["from"], "expression", null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, f["to"]);
            expect(attr.value, "expression");
          });
        });
        test("should not rewrite random attributes", () {
          var fixtures = [
            {"from": "custom-attr", "to": "custom-attr"},
            {"from": "ng-if", "to": "ng-if"}
          ];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst(f["from"], "expression", null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, f["to"]);
            expect(attr.value, "expression");
          });
        });
        test("should rewrite interpolation", () {
          var fixtures = [
            {"from": "dash-case", "to": "dashCase"},
            {"from": "lcase", "to": "lcase"},
            {"from": "camelCase", "to": "camelCase"},
            {"from": "attr.dash-case", "to": "attr.dash-case"},
            {"from": "class.dash-case", "to": "class.dash-case"},
            {"from": "style.dash-case", "to": "style.dash-case"}
          ];
          fixtures.forEach((f) {
            var legacyAttr = new HtmlAttrAst(f["from"], "{{ exp }}", null);
            var attr = visitor.visitAttr(legacyAttr, null);
            expect(attr.name, f["to"]);
            expect(attr.value, "{{ exp }}");
          });
        });
      });
    });
    group("template elements", () {
      var visitor;
      setUp(() {
        visitor = new LegacyHtmlAstTransformer();
        visitor.visitingTemplateEl = true;
      });
      test("should rewrite angular constructs", () {
        var fixtures = [
          {"from": "on-dash-case", "to": "on-dashCase"},
          {"from": "ON-dash-case", "to": "on-dashCase"},
          {"from": "bindon-dash-case", "to": "bindon-dashCase"},
          {"from": "(dash-case)", "to": "(dashCase)"},
          {"from": "[(dash-case)]", "to": "[(dashCase)]"},
          {"from": "on-camelCase", "to": "on-camelCase"},
          {"from": "bindon-camelCase", "to": "bindon-camelCase"},
          {"from": "(camelCase)", "to": "(camelCase)"},
          {"from": "[(camelCase)]", "to": "[(camelCase)]"}
        ];
        fixtures.forEach((f) {
          var legacyAttr = new HtmlAttrAst(f["from"], "expression", null);
          var attr = visitor.visitAttr(legacyAttr, null);
          expect(attr.name, f["to"]);
          expect(attr.value, "expression");
        });
      });
      test("should rewrite all attributes", () {
        var fixtures = [
          {"from": "custom-attr", "to": "customAttr"},
          {"from": "ng-if", "to": "ngIf"}
        ];
        fixtures.forEach((f) {
          var legacyAttr = new HtmlAttrAst(f["from"], "expression", null);
          var attr = visitor.visitAttr(legacyAttr, null);
          expect(attr.name, f["to"]);
          expect(attr.value, "expression");
        });
      });
    });
  });
}
