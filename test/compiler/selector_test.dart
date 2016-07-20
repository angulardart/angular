@TestOn('browser')
library angular2.test.compiler.selector_test;

import 'package:angular2/src/compiler/selector.dart' show SelectorMatcher;
import 'package:angular2/src/compiler/selector.dart' show CssSelector;
import 'package:angular2/src/platform/browser/browser_adapter.dart'
    show BrowserDomAdapter;
import 'package:angular2/src/platform/dom/dom_adapter.dart' show DOM;
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

main() {
  BrowserDomAdapter.makeCurrent();
  group('SelectorMatcher', () {
    var matcher, selectableCollector, s1, s2, s3, s4;
    List<dynamic> matched;
    reset() {
      matched = [];
    }
    setUp(() {
      reset();
      s1 = s2 = s3 = s4 = null;
      selectableCollector = (selector, context) {
        matched.add(selector);
        matched.add(context);
      };
      matcher = new SelectorMatcher();
    });
    test('should select by element name case sensitive', () {
      matcher.addSelectables(s1 = CssSelector.parse('someTag'), 1);
      expect(
          matcher.match(
              CssSelector.parse('SOMEOTHERTAG')[0], selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(CssSelector.parse('SOMETAG')[0], selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(CssSelector.parse('someTag')[0], selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1]);
    });
    test('should select by class name case insensitive', () {
      matcher.addSelectables(s1 = CssSelector.parse('.someClass'), 1);
      matcher.addSelectables(s2 = CssSelector.parse('.someClass.class2'), 2);
      expect(
          matcher.match(
              CssSelector.parse('.SOMEOTHERCLASS')[0], selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(
              CssSelector.parse('.SOMECLASS')[0], selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1]);
      reset();
      expect(
          matcher.match(
              CssSelector.parse('.someClass.class2')[0], selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1, s2[0], 2]);
    });
    test('should select by attr name case sensitive independent of the value',
        () {
      matcher.addSelectables(s1 = CssSelector.parse('[someAttr]'), 1);
      matcher.addSelectables(
          s2 = CssSelector.parse('[someAttr][someAttr2]'), 2);
      expect(
          matcher.match(
              CssSelector.parse('[SOMEOTHERATTR]')[0], selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(
              CssSelector.parse('[SOMEATTR]')[0], selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(CssSelector.parse('[SOMEATTR=someValue]')[0],
              selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(CssSelector.parse('[someAttr][someAttr2]')[0],
              selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1, s2[0], 2]);
      reset();
      expect(
          matcher.match(CssSelector.parse('[someAttr=someValue][someAttr2]')[0],
              selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1, s2[0], 2]);
      reset();
      expect(
          matcher.match(CssSelector.parse('[someAttr2][someAttr=someValue]')[0],
              selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1, s2[0], 2]);
      reset();
      expect(
          matcher.match(CssSelector.parse('[someAttr2=someValue][someAttr]')[0],
              selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1, s2[0], 2]);
    });
    test('should select by attr name only once if the value is from the DOM',
        () {
      matcher.addSelectables(s1 = CssSelector.parse('[some-decor]'), 1);
      var elementSelector = new CssSelector();
      var element = el('<div attr></div>');
      var empty = DOM.getAttribute(element, 'attr');
      elementSelector.addAttribute('some-decor', empty);
      matcher.match(elementSelector, selectableCollector);
      expect(matched, [s1[0], 1]);
    });
    test('should select by attr name case sensitive and value case insensitive',
        () {
      matcher.addSelectables(s1 = CssSelector.parse('[someAttr=someValue]'), 1);
      expect(
          matcher.match(CssSelector.parse('[SOMEATTR=SOMEOTHERATTR]')[0],
              selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(CssSelector.parse('[SOMEATTR=SOMEVALUE]')[0],
              selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(CssSelector.parse('[someAttr=SOMEVALUE]')[0],
              selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1]);
    });
    test(
        'should select by element name, class name and attribute name with value',
        () {
      matcher.addSelectables(
          s1 = CssSelector.parse('someTag.someClass[someAttr=someValue]'), 1);
      expect(
          matcher.match(
              CssSelector.parse("someOtherTag.someOtherClass[someOtherAttr]")[
                  0],
              selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(
              CssSelector.parse("someTag.someOtherClass[someOtherAttr]")[0],
              selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(
              CssSelector.parse("someTag.someClass[someOtherAttr]")[0],
              selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(CssSelector.parse("someTag.someClass[someAttr]")[0],
              selectableCollector),
          isFalse);
      expect(matched, []);
      expect(
          matcher.match(
              CssSelector.parse("someTag.someClass[someAttr=someValue]")[0],
              selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1]);
    });
    test("should select by many attributes and independent of the value", () {
      matcher.addSelectables(
          s1 = CssSelector.parse("input[type=text][control]"), 1);
      var cssSelector = new CssSelector();
      cssSelector.setElement("input");
      cssSelector.addAttribute("type", "text");
      cssSelector.addAttribute("control", "one");
      expect(matcher.match(cssSelector, selectableCollector), true);
      expect(matched, [s1[0], 1]);
    });
    test("should select independent of the order in the css selector", () {
      matcher.addSelectables(s1 = CssSelector.parse("[someAttr].someClass"), 1);
      matcher.addSelectables(s2 = CssSelector.parse(".someClass[someAttr]"), 2);
      matcher.addSelectables(s3 = CssSelector.parse(".class1.class2"), 3);
      matcher.addSelectables(s4 = CssSelector.parse(".class2.class1"), 4);
      expect(
          matcher.match(CssSelector.parse("[someAttr].someClass")[0],
              selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1, s2[0], 2]);
      reset();
      expect(
          matcher.match(CssSelector.parse(".someClass[someAttr]")[0],
              selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1, s2[0], 2]);
      reset();
      expect(
          matcher.match(
              CssSelector.parse(".class1.class2")[0], selectableCollector),
          isTrue);
      expect(matched, [s3[0], 3, s4[0], 4]);
      reset();
      expect(
          matcher.match(
              CssSelector.parse(".class2.class1")[0], selectableCollector),
          isTrue);
      expect(matched, [s4[0], 4, s3[0], 3]);
    });
    test("should not select with a matching :not selector", () {
      matcher.addSelectables(CssSelector.parse("p:not(.someClass)"), 1);
      matcher.addSelectables(CssSelector.parse("p:not([someAttr])"), 2);
      matcher.addSelectables(CssSelector.parse(":not(.someClass)"), 3);
      matcher.addSelectables(CssSelector.parse(":not(p)"), 4);
      matcher.addSelectables(CssSelector.parse(":not(p[someAttr])"), 5);
      expect(
          matcher.match(CssSelector.parse("p.someClass[someAttr]")[0],
              selectableCollector),
          isFalse);
      expect(matched, []);
    });
    test("should select with a non matching :not selector", () {
      matcher.addSelectables(s1 = CssSelector.parse("p:not(.someClass)"), 1);
      matcher.addSelectables(
          s2 = CssSelector.parse("p:not(.someOtherClass[someAttr])"), 2);
      matcher.addSelectables(s3 = CssSelector.parse(":not(.someClass)"), 3);
      matcher.addSelectables(
          s4 = CssSelector.parse(":not(.someOtherClass[someAttr])"), 4);
      expect(
          matcher.match(CssSelector.parse("p[someOtherAttr].someOtherClass")[0],
              selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1, s2[0], 2, s3[0], 3, s4[0], 4]);
    });
    test("should match with multiple :not selectors", () {
      matcher.addSelectables(
          s1 = CssSelector.parse("div:not([a]):not([b])"), 1);
      expect(matcher.match(CssSelector.parse("div[a]")[0], selectableCollector),
          isFalse);
      expect(matcher.match(CssSelector.parse("div[b]")[0], selectableCollector),
          isFalse);
      expect(matcher.match(CssSelector.parse("div[c]")[0], selectableCollector),
          isTrue);
    });
    test("should select with one match in a list", () {
      matcher.addSelectables(
          s1 = CssSelector.parse("input[type=text], textbox"), 1);
      expect(
          matcher.match(CssSelector.parse("textbox")[0], selectableCollector),
          isTrue);
      expect(matched, [s1[1], 1]);
      reset();
      expect(
          matcher.match(
              CssSelector.parse("input[type=text]")[0], selectableCollector),
          isTrue);
      expect(matched, [s1[0], 1]);
    });
    test("should not select twice with two matches in a list", () {
      matcher.addSelectables(s1 = CssSelector.parse("input, .someClass"), 1);
      expect(
          matcher.match(
              CssSelector.parse("input.someclass")[0], selectableCollector),
          isTrue);
      expect(matched.length, 2);
      expect(matched, [s1[0], 1]);
    });
  });
  group("CssSelector.parse", () {
    test("should detect element names", () {
      var cssSelector = CssSelector.parse("sometag")[0];
      expect(cssSelector.element, "sometag");
      expect(cssSelector.toString(), "sometag");
    });
    test("should detect class names", () {
      var cssSelector = CssSelector.parse(".someClass")[0];
      expect(cssSelector.classNames, ["someclass"]);
      expect(cssSelector.toString(), ".someclass");
    });
    test("should detect attr names", () {
      var cssSelector = CssSelector.parse("[attrname]")[0];
      expect(cssSelector.attrs, ["attrname", ""]);
      expect(cssSelector.toString(), "[attrname]");
    });
    test("should detect attr values", () {
      var cssSelector = CssSelector.parse("[attrname=attrvalue]")[0];
      expect(cssSelector.attrs, ["attrname", "attrvalue"]);
      expect(cssSelector.toString(), "[attrname=attrvalue]");
    });
    test("should detect multiple parts", () {
      var cssSelector =
          CssSelector.parse("sometag[attrname=attrvalue].someclass")[0];
      expect(cssSelector.element, "sometag");
      expect(cssSelector.attrs, ["attrname", "attrvalue"]);
      expect(cssSelector.classNames, ["someclass"]);
      expect(cssSelector.toString(), "sometag.someclass[attrname=attrvalue]");
    });
    test("should detect multiple attributes", () {
      var cssSelector = CssSelector.parse("input[type=text][control]")[0];
      expect(cssSelector.element, "input");
      expect(cssSelector.attrs, ["type", "text", "control", ""]);
      expect(cssSelector.toString(), "input[type=text][control]");
    });
    test("should detect :not", () {
      var cssSelector =
          CssSelector.parse("sometag:not([attrname=attrvalue].someclass)")[0];
      expect(cssSelector.element, "sometag");
      expect(cssSelector.attrs.length, 0);
      expect(cssSelector.classNames.length, 0);
      var notSelector = cssSelector.notSelectors[0];
      expect(notSelector.element, null);
      expect(notSelector.attrs, ["attrname", "attrvalue"]);
      expect(notSelector.classNames, ["someclass"]);
      expect(cssSelector.toString(),
          "sometag:not(.someclass[attrname=attrvalue])");
    });
    test("should detect :not without truthy", () {
      var cssSelector =
          CssSelector.parse(":not([attrname=attrvalue].someclass)")[0];
      expect(cssSelector.element, "*");
      var notSelector = cssSelector.notSelectors[0];
      expect(notSelector.attrs, ["attrname", "attrvalue"]);
      expect(notSelector.classNames, ["someclass"]);
      expect(cssSelector.toString(), "*:not(.someclass[attrname=attrvalue])");
    });
    test("should throw when nested :not", () {
      expect(() {
        CssSelector.parse("sometag:not(:not([attrname=attrvalue].someclass))")[
            0];
      }, throwsWith("Nesting :not is not allowed in a selector"));
    });
    test("should throw when multiple selectors in :not", () {
      expect(() {
        CssSelector.parse("sometag:not(a,b)");
      }, throwsWith("Multiple selectors in :not are not supported"));
    });
    test("should detect lists of selectors", () {
      var cssSelectors =
          CssSelector.parse(".someclass,[attrname=attrvalue], sometag");
      expect(cssSelectors.length, 3);
      expect(cssSelectors[0].classNames, ["someclass"]);
      expect(cssSelectors[1].attrs, ["attrname", "attrvalue"]);
      expect(cssSelectors[2].element, "sometag");
    });
    test("should detect lists of selectors with :not", () {
      var cssSelectors = CssSelector
          .parse("input[type=text], :not(textarea), textbox:not(.special)");
      expect(cssSelectors.length, 3);
      expect(cssSelectors[0].element, "input");
      expect(cssSelectors[0].attrs, ["type", "text"]);
      expect(cssSelectors[1].element, "*");
      expect(cssSelectors[1].notSelectors[0].element, "textarea");
      expect(cssSelectors[2].element, "textbox");
      expect(cssSelectors[2].notSelectors[0].classNames, ["special"]);
    });
  });
  group("CssSelector.getMatchingElementTemplate", () {
    test(
        'should create an element with a tagName, classes, '
        'and attributes with the correct casing', () {
      var selector =
          CssSelector.parse("Blink.neon.hotpink[Sweet][Dismissable=false]")[0];
      var template = selector.getMatchingElementTemplate();
      expect(template,
          "<Blink class=\"neon hotpink\" Sweet Dismissable=\"false\"></Blink>");
    });
    test("should create an element without a tag name", () {
      var selector = CssSelector.parse("[fancy]")[0];
      var template = selector.getMatchingElementTemplate();
      expect(template, "<div fancy></div>");
    });
    test("should ignore :not selectors", () {
      var selector = CssSelector.parse("grape:not(.red)")[0];
      var template = selector.getMatchingElementTemplate();
      expect(template, "<grape></grape>");
    });
  });
}
