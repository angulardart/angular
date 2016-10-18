@TestOn('browser')
library angular2.test.compiler.shadow_css_test;

import "package:angular2/src/compiler/shadow_css.dart"
    show ShadowCss, processRules, CssRule;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

void main() {
  group("ShadowCss", () {
    String s(String css, String contentAttr, [String hostAttr = ""]) {
      var shadowCss = new ShadowCss();
      var shim = shadowCss.shimCssText(css, contentAttr, hostAttr);
      var nlRegexp = new RegExp(r'\n');
      return normalizeCSS(shim.replaceAll(nlRegexp, ""));
    }

    test("should handle empty string", () {
      expect(s("", "a"), "");
    });
    test("should add an attribute to every rule", () {
      var css = "one {color: red;}two {color: red;}";
      var expected = "one[a] {color:red;}two[a] {color:red;}";
      expect(s(css, "a"), expected);
    });
    test("should handle invalid css", () {
      var css = "one {color: red;}garbage";
      var expected = "one[a] {color:red;}garbage";
      expect(s(css, "a"), expected);
    });
    test("should add an attribute to every selector", () {
      var css = "one, two {color: red;}";
      var expected = "one[a], two[a] {color:red;}";
      expect(s(css, "a"), expected);
    });
    test("should support newlines in the selector and content ", () {
      var css = "one, \ntwo {\ncolor: red;}";
      var expected = "one[a], two[a] {color:red;}";
      expect(s(css, "a"), expected);
    });
    test("should handle media rules", () {
      var css = '@media screen and (max-width:800px, '
          'max-height:100%) {div {font-size:50px;}}';
      var expected = '@media screen and (max-width:800px, '
          'max-height:100%) {div[a] {font-size:50px;}}';
      expect(s(css, "a"), expected);
    });
    test("should handle media rules with simple rules", () {
      var css = '@media screen and (max-width: 800px) '
          '{div {font-size: 50px;}} div {}';
      var expected = '@media screen and (max-width:800px) '
          '{div[a] {font-size:50px;}} div[a] {}';
      expect(s(css, "a"), expected);
    });
    // Check that the browser supports unprefixed CSS animation
    test("should handle keyframes rules", () {
      var css = "@keyframes foo {0% {transform:translate(-50%) scaleX(0);}}";
      expect(s(css, "a"), css);
    });
    test("should handle -webkit-keyframes rules", () {
      var css = '@-webkit-keyframes foo {0% {-webkit-transform:translate(-50%) '
          'scaleX(0);}}';
      expect(s(css, "a"), css);
    });
    test("should handle complicated selectors", () {
      expect(s("one::before {}", "a"), "one[a]::before {}");
      expect(s("one two {}", "a"), "one[a] two[a] {}");
      expect(s("one > two {}", "a"), "one[a] > two[a] {}");
      expect(s("one + two {}", "a"), "one[a] + two[a] {}");
      expect(s("one ~ two {}", "a"), "one[a] ~ two[a] {}");
      var res = s(".one.two > three {}", "a");
      expect(
          res == ".one.two[a] > three[a] {}" ||
              res == ".two.one[a] > three[a] {}",
          isTrue);
      expect(s("one[attr=\"value\"] {}", "a"), "one[attr=\"value\"][a] {}");
      expect(s("one[attr=value] {}", "a"), "one[attr=\"value\"][a] {}");
      expect(s("one[attr^=\"value\"] {}", "a"), "one[attr^=\"value\"][a] {}");
      expect(s("one[attr\$=\"value\"] {}", "a"), "one[attr\$=\"value\"][a] {}");
      expect(s("one[attr*=\"value\"] {}", "a"), "one[attr*=\"value\"][a] {}");
      expect(s("one[attr|=\"value\"] {}", "a"), "one[attr|=\"value\"][a] {}");
      expect(s("one[attr] {}", "a"), "one[attr][a] {}");
      expect(s("[is=\"one\"] {}", "a"), "[is=\"one\"][a] {}");
    });
    test("should handle :host", () {
      expect(s(":host {}", "a", "a-host"), "[a-host] {}");
      expect(s(":host(.x,.y) {}", "a", "a-host"), "[a-host].x, [a-host].y {}");
      expect(s(":host(.x,.y) > .z {}", "a", "a-host"),
          "[a-host].x > .z, [a-host].y > .z {}");
    });
    test("should handle :host-context", () {
      expect(s(":host-context(.x) {}", "a", "a-host"),
          "[a-host].x, .x [a-host] {}");
      expect(s(":host-context(.x) > .y {}", "a", "a-host"),
          "[a-host].x > .y, .x [a-host] > .y {}");
    });
    test("should support polyfill-next-selector", () {
      var css = s("polyfill-next-selector {content: 'x > y'} z {}", "a");
      expect(css, "x[a] > y[a]{}");
      css = s("polyfill-next-selector {content: \"x > y\"} z {}", "a");
      expect(css, "x[a] > y[a]{}");
    });
    test("should support polyfill-unscoped-rule", () {
      var css = s(
          "polyfill-unscoped-rule {content: '#menu > .bar';color: blue;}", "a");
      expect(css.contains("#menu > .bar {;color:blue;}"), isTrue);
      css = s("polyfill-unscoped-rule {content: \"#menu > .bar\";color: blue;}",
          "a");
      expect(css.contains("#menu > .bar {;color:blue;}"), isTrue);
    });
    test("should support multiple instances polyfill-unscoped-rule", () {
      var css = s(
          "polyfill-unscoped-rule {content: 'foo';color: blue;}" +
              "polyfill-unscoped-rule {content: 'bar';color: blue;}",
          "a");
      expect(css.contains("foo {;color:blue;}"), isTrue);
      expect(css.contains("bar {;color:blue;}"), isTrue);
    });
    test("should support polyfill-rule", () {
      var css = s("polyfill-rule {content: ':host.foo .bar';color: blue;}", "a",
          "a-host");
      expect(css, "[a-host].foo .bar {;color:blue;}");
      css = s("polyfill-rule {content: \":host.foo .bar\";color:blue;}", "a",
          "a-host");
      expect(css, "[a-host].foo .bar {;color:blue;}");
    });
    test("should handle ::shadow", () {
      var css = s("x::shadow > y {}", "a");
      expect(css, "x[a] > y[a] {}");
    });
    test("should handle /deep/", () {
      var css = s("x /deep/ y {}", "a");
      expect(css, "x[a] y {}");
    });
    test("should handle >>>", () {
      var css = s("x >>> y {}", "a");
      expect(css, "x[a] y {}");
    });
    test("should pass through @import directives", () {
      var styleStr =
          "@import url(\"https://fonts.googleapis.com/css?family=Roboto\");";
      var css = s(styleStr, "a");
      expect(css, styleStr);
    });
    test("should shim rules after @import", () {
      var styleStr = "@import url(\"a\"); div {}";
      var css = s(styleStr, "a");
      expect(css, "@import url(\"a\"); div[a] {}");
    });
    test("should leave calc() unchanged", () {
      var styleStr = "div {height:calc(100% - 55px);}";
      var css = s(styleStr, "a");
      expect(css, "div[a] {height:calc(100% - 55px);}");
    });
    test("should strip comments", () {
      expect(s("/* x */b {c}", "a"), "b[a] {c}");
    });
    test("should ignore special characters in comments", () {
      expect(s("/* {;, */b {c}", "a"), "b[a] {c}");
    });
    test("should support multiline comments", () {
      expect(s("/* \n */b {c}", "a"), "b[a] {c}");
    });
  });
  group("processRules", () {
    group("parse rules", () {
      List<CssRule> captureRules(String input) {
        var result = <CssRule>[];
        processRules(input, (cssRule) {
          result.add(cssRule);
          return cssRule;
        });
        return result;
      }

      test("should work with empty css", () {
        expect(captureRules(""), []);
      });
      test("should capture a rule without body", () {
        expect(
            captureRules("a;").first.selector, new CssRule("a", "").selector);
        expect(captureRules("a;").first.content, new CssRule("a", "").content);
      });
      test("should capture css rules with body", () {
        expect(captureRules("a {b}").first.selector,
            new CssRule("a", "b").selector);
        expect(
            captureRules("a {b}").first.content, new CssRule("a", "b").content);
      });
      test("should capture css rules with nested rules", () {
        expect(captureRules("a {b {c}} d {e}")[0].selector,
            new CssRule("a", "b {c}").selector);
        expect(captureRules("a {b {c}} d {e}")[0].content,
            new CssRule("a", "b {c}").content);
        expect(captureRules("a {b {c}} d {e}")[1].selector,
            new CssRule("d", "e").selector);
        expect(captureRules("a {b {c}} d {e}")[1].content,
            new CssRule("d", "e").content);
      });
      test("should capture multiple rules where some have no body", () {
        expect(captureRules("@import a ; b {c}")[0].selector,
            new CssRule("@import a", "").selector);
        expect(captureRules("@import a ; b {c}")[0].content,
            new CssRule("@import a", "").content);
        expect(captureRules("@import a ; b {c}")[1].selector,
            new CssRule("b", "c").selector);
        expect(captureRules("@import a ; b {c}")[1].content,
            new CssRule("b", "c").content);
      });
    });
    group("modify rules", () {
      test("should allow to change the selector while preserving whitespaces",
          () {
        expect(
            processRules(
                "@import a; b {c {d}} e {f}",
                (cssRule) =>
                    new CssRule(cssRule.selector + "2", cssRule.content)),
            "@import a2; b2 {c {d}} e2 {f}");
      });
      test("should allow to change the content", () {
        expect(
            processRules(
                "a {b}",
                (cssRule) =>
                    new CssRule(cssRule.selector, cssRule.content + "2")),
            "a {b2}");
      });
    });
  });
}
