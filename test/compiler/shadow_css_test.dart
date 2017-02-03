@TestOn('browser')
library angular2.test.compiler.shadow_css_test;

import 'package:angular2/src/compiler/shadow_css.dart';
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

void main() {
  String shim(String css) => normalizeCSS(shimShadowCss(css, 'a', 'a-host'));

  test('should handle empty string', () => expect(shim(''), ''));

  test('should add a class to every rule', () {
    var css = 'one {color: red;} two {color: red;}';
    var expected = 'one.a {color:red;} two.a {color:red;}';
    expect(shim(css), expected);
  });

  test('should add a class to every selector', () {
    var css = 'one,two {color: red;}';
    var expected = 'one.a,two.a {color:red;}';
    expect(shim(css), expected);
  });

  test('should support newlines in the selector and content ', () {
    var css = 'one,\ntwo {\ncolor: red;}';
    var expected = 'one.a,two.a {color:red;}';
    expect(shim(css), expected);
  });

  test('should handle media rules', () {
    var css = '@media screen and (max-width:800px) {div {font-size:50px;}}';
    var expected =
        '@media screen AND (max-width:800px) {div.a {font-size:50px;}}';
    expect(shim(css), expected);
  });

  test('should handle page rules', () {
    var css = '@page {@top-left {color:red;} font-size:50px;}';
    expect(shim(css), css);
  });

  test('should handle media rules with simple rules', () {
    var css = '@media screen and (max-width: 800px) '
        '{div {font-size: 50px;}} div {}';
    var expected = '@media screen AND (max-width:800px) '
        '{div.a {font-size:50px;}} div.a {}';
    expect(shim(css), expected);
  });

  // Check that the browser supports unprefixed CSS animation
  test('should handle keyframes rules', () {
    var css = '@keyframes foo{0%{transform:translate(-50%) scaleX(0);}}';
    expect(shim(css), css);
  });

  test('should handle -webkit-keyframes rules', () {
    var css = '@-webkit-keyframes foo'
        '{0%{-webkit-transform:translate(-50%) scaleX(0);}}';
    expect(shim(css), css);
  });

  test('should handle complicated selectors', () {
    expect(shim('one::before {}'), 'one.a::before {}');
    expect(shim('one two {}'), 'one.a two.a {}');
    expect(shim('one > two {}'), 'one.a > two.a {}');
    expect(shim('one + two {}'), 'one.a + two.a {}');
    expect(shim('one ~ two {}'), 'one.a ~ two.a {}');
    expect(shim('.one.two > three {}'), '.one.two.a > three.a {}');
    expect(shim('one[attr="value"] {}'), 'one[attr="value"].a {}');
    expect(shim('one[attr=value] {}'), 'one[attr="value"].a {}');
    expect(shim('one[attr^="value"] {}'), 'one[attr^="value"].a {}');
    expect(shim('one[attr\$="value"] {}'), 'one[attr\$="value"].a {}');
    expect(shim('one[attr*="value"] {}'), 'one[attr*="value"].a {}');
    expect(shim('one[attr|="value"] {}'), 'one[attr|="value"].a {}');
    expect(shim('one[attr~="value"] {}'), 'one[attr~="value"].a {}');
    expect(shim('one[attr="va lue"] {}'), 'one[attr="va lue"].a {}');
    expect(shim('one[attr] {}'), 'one[attr].a {}');
    expect(shim('[is="one"] {}'), '[is="one"].a {}');
  });

  group(':host', () {
    test('should handle basic use', () {
      expect(shim(':host {}'), '.a-host {}');
    });

    test('should handle pseudo-element', () {
      expect(shim(':host::after {}'), '.a-host::after {}');
    });

    test('should handle compound selector', () {
      expect(shim(':host.x::before {}'), '.a-host.x::before {}');
    });
  });

  group(':host()', () {
    test('should handle tag selector argument', () {
      expect(shim(':host(ul) {}'), 'ul.a-host {}');
    });

    test('should handle name selector argument', () {
      expect(shim(':host(#x) {}'), '.a-host#x {}');
    });

    test('should handle class selector argument', () {
      expect(shim(':host(.x) {}'), '.a-host.x {}');
    });

    test('should handle attribute selector argument', () {
      expect(shim(':host([a="b"]) {}'), '.a-host[a="b"] {}');
      expect(shim(':host([a=b]) {}'), '.a-host[a="b"] {}');
    });

    test('should handle pseudo-class selector argument', () {
      var css = ':host(:nth-child(2n+1)) {}';
      var expected = '.a-host:nth-child(2n+1) {}';
      expect(shim(css), expected);
    });

    test('should handle pseudo-element selector argument', () {
      expect(shim(':host(::before) {}'), '.a-host::before {}');
    });

    test('should handle compound selector argument', () {
      expect(shim(':host(a.x:active) {}'), 'a.a-host.x:active {}');
    });

    test('should handle pseudo-element', () {
      expect(shim(':host(.x)::before {}'), '.a-host.x::before {}');
    });

    test('should handle complex selector', () {
      expect(shim(':host(.x) > .y {}'), '.a-host.x > .y.a {}');
    });

    test('should handle multiple selectors', () {
      expect(shim(':host(.x),:host(a) {}'), '.a-host.x,a.a-host {}');
    });
  });

  group(':host-context()', () {
    test('should handle tag selector argument', () {
      expect(shim(':host-context(div) {}'), 'div.a-host,div .a-host {}');
    });

    test('should handle name selector argument', () {
      expect(shim(':host-context(#x) {}'), '.a-host#x,#x .a-host {}');
    });

    test('should handle class selector argument', () {
      expect(shim(':host-context(.x) {}'), '.a-host.x,.x .a-host {}');
    });

    test('should handle attribute selector argument', () {
      var css = ':host-context([a="b"]) {}';
      var expected = '.a-host[a="b"],[a="b"] .a-host {}';
      expect(shim(css), expected);
    });

    test('should handle pseudo-class selector argument', () {
      var css = ':host-context(:nth-child(2n+1)) {}';
      var expected = '.a-host:nth-child(2n+1),:nth-child(2n+1) .a-host {}';
      expect(shim(css), expected);
    });

    test('should handle pseudo-element selector argument', () {
      var css = ':host-context(::before) {}';
      var expected = '.a-host::before,::before .a-host {}';
      expect(shim(css), expected);
    });

    test('should handle compound selector argument', () {
      var css = ':host-context(a.x:active) {}';
      var expected = 'a.a-host.x:active,a.x:active .a-host {}';
      expect(shim(css), expected);
    });

    test('should handle complex selector', () {
      var css = ':host-context(.x) > .y {}';
      var expected = '.a-host.x > .y.a,.x .a-host > .y.a {}';
      expect(shim(css), expected);
    });

    test('should handle multiple selectors', () {
      var css = ':host-context(.x),:host-context(.y) {}';
      var expected = '.a-host.x,.x .a-host,.a-host.y,.y .a-host {}';
      expect(shim(css), expected);
    });
  });

  // Each host selector contributes a host class. For now this duplication is
  // not a concern as it doesn't affect what the shimmed selector matches.
  group(':host-context():host()', () {
    test('should handle combination', () {
      var css = ':host-context(.x):host(.y) {}';
      var expected = '.a-host.a-host.x.y,.x .a-host.a-host.y {}';
      expect(shim(css), expected);
    });

    test('should handle combination reversed', () {
      var css = ':host(.y):host-context(.x) {}';
      var expected = '.a-host.a-host.y.x,.x .a-host.a-host.y {}';
      expect(shim(css), expected);
    });

    test('should handle non-trivial combination', () {
      var css = ':host(div::scrollbar:vertical):host-context(.foo:hover) {}';
      var expected = 'div.a-host.a-host.foo:hover::scrollbar:vertical,'
          '.foo:hover div.a-host.a-host::scrollbar:vertical {}';
      expect(shim(css), expected);
    });
  });

  test('should support polyfill-next-selector', () {
    var css = "polyfill-next-selector {content: 'x > y';} z {}";
    expect(shim(css), 'x.a > y.a {}');
    css = 'polyfill-next-selector {content: "x > y";} z {}';
    expect(shim(css), 'x.a > y.a {}');
    css = 'polyfill-next-selector {content: \'button[priority="1"]\';} z {}';
    expect(shim(css), 'button[priority="1"].a {}');
  });

  test('should support polyfill-unscoped-rule', () {
    var css = "polyfill-unscoped-rule {content: '#menu > .bar';color: blue;}";
    expect(shim(css), '#menu > .bar {color:blue;}');
    css = 'polyfill-unscoped-rule {content: "#menu > .bar";color: blue;}';
    expect(shim(css), '#menu > .bar {color:blue;}');
    css = 'polyfill-unscoped-rule {content: \'button[priority="1"]\';}';
    expect(shim(css), 'button[priority="1"] {}');
  });

  test('should support multiple instances polyfill-unscoped-rule', () {
    var css = 'polyfill-unscoped-rule {content: "foo";color: blue;}' +
        'polyfill-unscoped-rule {content: "bar";color: red;}';
    expect(shim(css), 'foo {color:blue;} bar {color:red;}');
  });

  test('should handle ::content', () {
    var css = shim('x::content > y {}');
    expect(css, 'x.a > y.a {}');
  });

  test('should handle ::shadow', () {
    var css = shim('x::shadow > y {}');
    expect(css, 'x.a > y.a {}');
  });

  test('should handle /deep/', () {
    var css = 'x /deep/ y {}';
    expect(shim(css), 'x.a y {}');
    css = '/deep/ x {}';
    expect(shim(css), 'x {}');
  });

  test('should handle >>>', () {
    var css = 'x >>> y {}';
    expect(shim(css), 'x.a y {}');
    css = '>>> y {}';
    expect(shim(css), 'y {}');
  });

  test('should handle sequential shadow piercing combinators', () {
    // Current SASS practices cause frequent occurrences of duplicate shadow
    // piercing combinators in the generated CSS.
    var css = 'x /deep/ /deep/ y {}';
    expect(shim(css), 'x.a y {}');
    css = 'x >>> >>> y {}';
    expect(shim(css), 'x.a y {}');
    css = 'x /deep/ >>> y {}';
    expect(shim(css), 'x.a y {}');
  });

  test('should pass through @import directives', () {
    var styleStr =
        '@import url("https://fonts.googleapis.com/css?family=Roboto");';
    var css = shim(styleStr);
    expect(css, styleStr);
  });

  test('should shim rules after @import', () {
    var styleStr = '@import url("a"); div {}';
    var css = shim(styleStr);
    expect(css, '@import url("a"); div.a {}');
  });

  test('should leave calc() unchanged', () {
    var styleStr = 'div {height:calc(100% - 55px);}';
    var css = shim(styleStr);
    expect(css, 'div.a {height:calc(100% - 55px);}');
  });

  test('should strip comments', () {
    expect(shim('/* x */b {}'), 'b.a {}');
  });

  test('should ignore special characters in comments', () {
    expect(shim('/* {;, */b {}'), 'b.a {}');
  });

  test('should support multiline comments', () {
    expect(shim('/* \n */b {}'), 'b.a {}');
  });

  test("should handle pseudo element's pseudo class", () {
    var css = '::-webkit-scrollbar-thumb:vertical {}';
    var expected = '.a::-webkit-scrollbar-thumb:vertical {}';
    expect(shim(css), expected);
  });
}
