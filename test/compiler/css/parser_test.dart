library angular2.test.compiler.css.parser_test;

import 'package:angular2/src/compiler/css/lexer.dart' show CssLexer;
import 'package:angular2/src/compiler/css/parser.dart';
import 'package:angular2/src/facade/exceptions.dart' show BaseException;
import 'package:test/test.dart';

Iterable<String> tokensToStringList(List<CssToken> tokens) =>
    tokens.map((t) => t.strValue);

void main() {
  group("CssParser", () {
    ParsedCssResult parse(css) {
      var lexer = new CssLexer();
      var scanner = lexer.scan(css);
      var parser = new CssParser(scanner, "some-fake-file-name.css");
      return parser.parse();
    }

    CssStyleSheetAST makeAST(css) {
      var output = parse(css);
      var errors = output.errors;
      if (errors.length > 0) {
        throw new BaseException(
            errors.map((CssParseError error) => error.msg).toList().join(", "));
      }
      return output.ast;
    }

    test("should parse CSS into a stylesheet AST", () {
      var styles = '''
        .selector {
          prop: value123;
        }
      ''';
      var ast = makeAST(styles);
      expect(ast.rules.length, 1);
      var rule = (ast.rules[0] as CssSelectorRuleAST);
      var selector = rule.selectors[0];
      expect(selector.strValue, ".selector");
      CssBlockAST block = rule.block;
      expect(block.entries.length, 1);
      var definition = (block.entries[0] as CssDefinitionAST);
      expect(definition.property.strValue, "prop");
      expect(definition.value.tokens[0].strValue, "value123");
    });
    test("should parse mutliple CSS selectors sharing the same set of styles",
        () {
      var styles = '''
        .class, #id, tag, [attr], key + value, * value, :-moz-any-link {
          prop: value123;
        }
      ''';
      var ast = makeAST(styles);
      expect(ast.rules.length, 1);
      var rule = (ast.rules[0] as CssSelectorRuleAST);
      expect(rule.selectors, hasLength(7));
      expect(tokensToStringList(rule.selectors[0].tokens), [".", "class"]);
      expect(tokensToStringList(rule.selectors[1].tokens), ["#", "id"]);
      expect(tokensToStringList(rule.selectors[2].tokens), ["tag"]);
      expect(tokensToStringList(rule.selectors[3].tokens), ["[", "attr", "]"]);
      expect(tokensToStringList(rule.selectors[4].tokens),
          ["key", " ", "+", " ", "value"]);
      expect(tokensToStringList(rule.selectors[5].tokens), ["*", " ", "value"]);
      expect(
          tokensToStringList(rule.selectors[6].tokens), [":", "-moz-any-link"]);
      var style1 = (rule.block.entries[0] as CssDefinitionAST);
      expect(style1.property.strValue, "prop");
      expect(tokensToStringList(style1.value.tokens), ["value123"]);
    });
    test("should parse keyframe rules", () {
      var styles = '''
        @keyframes rotateMe {
          from {
            transform: rotate(-360deg);
          }
          50% {
            transform: rotate(0deg);
          }
          to {
            transform: rotate(360deg);
          }
        }
      ''';
      var ast = makeAST(styles);
      expect(ast.rules.length, 1);
      var rule = (ast.rules[0] as CssKeyframeRuleAST);
      expect(rule.name.strValue, "rotateMe");
      var fromRule = (rule.block.entries[0] as CssKeyframeDefinitionAST);
      expect(fromRule.name.strValue, "from");
      var fromStyle = fromRule.block.entries[0] as CssDefinitionAST;
      expect(fromStyle.property.strValue, "transform");
      expect(tokensToStringList(fromStyle.value.tokens),
          ["rotate", "(", "-360deg", ")"]);
      var midRule = (rule.block.entries[1] as CssKeyframeDefinitionAST);
      expect(midRule.name.strValue, "50%");
      var midStyle = (midRule.block.entries[0] as CssDefinitionAST);
      expect(midStyle.property.strValue, "transform");
      expect(tokensToStringList(midStyle.value.tokens),
          ["rotate", "(", "0deg", ")"]);
      var toRule = (rule.block.entries[2] as CssKeyframeDefinitionAST);
      expect(toRule.name.strValue, "to");
      var toStyle = toRule.block.entries[0] as CssDefinitionAST;
      expect(toStyle.property.strValue, "transform");
      expect(tokensToStringList(toStyle.value.tokens),
          ["rotate", "(", "360deg", ")"]);
    });
    test("should parse media queries into a stylesheet AST", () {
      var styles = '''
        @media all and (max-width:100px) {
          .selector {
            prop: value123;
          }
        }
      ''';
      var ast = makeAST(styles);
      expect(ast.rules.length, 1);
      var rule = (ast.rules[0] as CssMediaQueryRuleAST);
      expect(tokensToStringList(rule.query),
          ["all", "and", "(", "max-width", ":", "100", "px", ")"]);
      expect(rule.block.entries.length, 1);
      var rule2 = rule.block.entries[0] as CssSelectorRuleAST;
      expect(rule2.selectors[0].strValue, ".selector");
      expect(rule2.block.entries.length, 1);
    });
    test("should parse inline CSS values", () {
      var styles = '''
        @import url(\'remote.css\');
        @charset "UTF-8";
        @namespace ng url(http://angular.io/namespace/ng);
      ''';
      var ast = makeAST(styles);
      var importRule = (ast.rules[0] as CssInlineRuleAST);
      expect(importRule.type, BlockType.Import);
      expect(tokensToStringList(importRule.value.tokens),
          ["url", "(", "\'remote.css\'", ")"]);
      var charsetRule = (ast.rules[1] as CssInlineRuleAST);
      expect(charsetRule.type, BlockType.Charset);
      expect(tokensToStringList(charsetRule.value.tokens), ['"UTF-8"']);
      var namespaceRule = (ast.rules[2] as CssInlineRuleAST);
      expect(namespaceRule.type, BlockType.Namespace);
      expect(tokensToStringList(namespaceRule.value.tokens),
          ["ng", "url", "(", "http://angular.io/namespace/ng", ")"]);
    });
    test(
        'should parse CSS values that contain functions and leave '
        'the inner function data untokenized', () {
      var styles = '''
        .class {
          background: url(matias.css);
          animation-timing-function: cubic-bezier(0.755, 0.050, 0.855, 0.060);
          height: calc(100% - 50px);
        }
      ''';
      var ast = makeAST(styles);
      expect(ast.rules.length, 1);
      var defs = ((ast.rules[0] as CssSelectorRuleAST)).block.entries;
      expect(defs.length, 3);
      expect(tokensToStringList(((defs[0] as CssDefinitionAST)).value.tokens),
          ["url", "(", "matias.css", ")"]);
      expect(tokensToStringList(((defs[1] as CssDefinitionAST)).value.tokens),
          ["cubic-bezier", "(", "0.755, 0.050, 0.855, 0.060", ")"]);
      expect(tokensToStringList(((defs[2] as CssDefinitionAST)).value.tokens),
          ["calc", "(", "100% - 50px", ")"]);
    });
    test("should parse un-named block-level CSS values", () {
      var styles = '''
        @font-face {
          font-family: "Matias";
          font-weight: bold;
          src: url(font-face.ttf);
        }
        @viewport {
          max-width: 100px;
          min-height: 1000px;
        }
      ''';
      var ast = makeAST(styles);
      var fontFaceRule = (ast.rules[0] as CssBlockRuleAST);
      expect(fontFaceRule.type, BlockType.FontFace);
      expect(fontFaceRule.block.entries.length, 3);
      var viewportRule = (ast.rules[1] as CssBlockRuleAST);
      expect(viewportRule.type, BlockType.Viewport);
      expect(viewportRule.block.entries.length, 2);
    });
    test("should parse multiple levels of semicolons", () {
      var styles = '''
        ;;;
        @import url(\'something something\')
        ;;;;;;;;
        ;;;;;;;;
        ;@font-face {
          ;src   :   url(font-face.ttf);;;;;;;;
          ;;;-webkit-animation:my-animation
        };;;
        @media all and (max-width:100px)
        {;
          .selector {prop: value123;};
          ;.selector2{prop:1}}
      ''';
      var ast = makeAST(styles);
      var importRule = (ast.rules[0] as CssInlineRuleAST);
      expect(importRule.type, BlockType.Import);
      expect(tokensToStringList(importRule.value.tokens),
          ["url", "(", "\'something something\'", ")"]);
      var fontFaceRule = (ast.rules[1] as CssBlockRuleAST);
      expect(fontFaceRule.type, BlockType.FontFace);
      expect(fontFaceRule.block.entries.length, 2);
      var mediaQueryRule = (ast.rules[2] as CssMediaQueryRuleAST);
      expect(tokensToStringList(mediaQueryRule.query),
          ["all", "and", "(", "max-width", ":", "100", "px", ")"]);
      expect(mediaQueryRule.block.entries.length, 2);
    });
    test("should throw an error if an unknown @value block rule is parsed", () {
      var styles = '''
        @matias { hello: there; }
      ''';
      expect(() {
        makeAST(styles);
      },
          throwsA(allOf(
              new isInstanceOf<Error>(),
              predicate(
                  (e) => e.message.contains('CSS Parse Error: The CSS "at" '
                      'rule "@matias" is not allowed')))));
    });
    test("should parse empty rules", () {
      var styles = '''
        .empty-rule { }
        .somewhat-empty-rule { /* property: value; */ }
        .non-empty-rule { property: value; }
      ''';
      var ast = makeAST(styles);
      var rules = ast.rules;
      expect(((rules[0] as CssSelectorRuleAST)).block.entries, hasLength(0));
      expect(((rules[1] as CssSelectorRuleAST)).block.entries, hasLength(0));
      expect(((rules[2] as CssSelectorRuleAST)).block.entries, hasLength(1));
    });
    test("should parse the @document rule", () {
      var styles = '''
        @document url(http://www.w3.org/),
                       url-prefix(http://www.w3.org/Style/),
                       domain(mozilla.org),
                       regexp("https:.*")
        {
          /* CSS rules here apply to:
             - The page "http://www.w3.org/".
             - Any page whose URL begins with "http://www.w3.org/Style/"
             - Any page whose URL\'s host is "mozilla.org" or ends with
               ".mozilla.org"
             - Any page whose URL starts with "https:" */

          /* make the above-mentioned pages really ugly */
          body {
            color: purple;
            background: yellow;
          }
        }
      ''';
      var ast = makeAST(styles);
      var rules = ast.rules;
      var documentRule = (rules[0] as CssBlockDefinitionRuleAST);
      expect(documentRule.type, BlockType.Document);
      var rule = (documentRule.block.entries[0] as CssSelectorRuleAST);
      expect(rule.strValue, "body");
    });
    test("should parse the @page rule", () {
      var styles = '''
        @page one {
          .selector { prop: value; }
        }
        @page two {
          .selector2 { prop: value2; }
        }
      ''';
      var ast = makeAST(styles);
      var rules = ast.rules;
      var pageRule1 = (rules[0] as CssBlockDefinitionRuleAST);
      expect(pageRule1.strValue, "one");
      expect(pageRule1.type, BlockType.Page);
      var pageRule2 = (rules[1] as CssBlockDefinitionRuleAST);
      expect(pageRule2.strValue, "two");
      expect(pageRule2.type, BlockType.Page);
      var selectorOne = (pageRule1.block.entries[0] as CssSelectorRuleAST);
      expect(selectorOne.strValue, ".selector");
      var selectorTwo = (pageRule2.block.entries[0] as CssSelectorRuleAST);
      expect(selectorTwo.strValue, ".selector2");
    });
    test("should parse the @supports rule", () {
      var styles = '''
        @supports (animation-name: "rotate") {
          a:hover { animation: rotate 1s; }
        }
      ''';
      var ast = makeAST(styles);
      var rules = ast.rules;
      var supportsRule = (rules[0] as CssBlockDefinitionRuleAST);
      expect(tokensToStringList(supportsRule.query),
          ["(", "animation-name", ":", '"rotate"', ")"]);
      expect(supportsRule.type, BlockType.Supports);
      var selectorOne = (supportsRule.block.entries[0] as CssSelectorRuleAST);
      expect(selectorOne.strValue, "a:hover");
    });
    test("should collect multiple errors during parsing", () {
      var styles = '''
        .class\$value { something: something }
        @custom { something: something }
        #id { cool^: value }
      ''';
      var output = parse(styles);
      expect(output.errors.length, 3);
    });
    test("should recover from selector errors and continue parsing", () {
      var styles = '''
        tag& { key: value; }
        .%tag { key: value; }
        #tag\$ { key: value; }
      ''';
      var output = parse(styles);
      var errors = output.errors;
      var ast = output.ast;
      expect(errors.length, 3);
      expect(ast.rules.length, 3);
      var rule1 = (ast.rules[0] as CssSelectorRuleAST);
      expect(rule1.selectors[0].strValue, "tag&");
      expect(rule1.block.entries.length, 1);
      var rule2 = (ast.rules[1] as CssSelectorRuleAST);
      expect(rule2.selectors[0].strValue, ".%tag");
      expect(rule2.block.entries.length, 1);
      var rule3 = (ast.rules[2] as CssSelectorRuleAST);
      expect(rule3.selectors[0].strValue, "#tag\$");
      expect(rule3.block.entries.length, 1);
    });
    test("should throw an error when parsing invalid CSS Selectors", () {
      var styles = ".class[[prop%=value}] { style: val; }";
      var output = parse(styles);
      var errors = output.errors;
      expect(errors.length, 3);
      expect(errors[0].msg,
          matches(new RegExp(r'Unexpected character \[\[\] at column 0:7')));
      expect(errors[1].msg,
          matches(new RegExp(r'Unexpected character \[%\] at column 0:12')));
      expect(errors[2].msg,
          matches(new RegExp(r'Unexpected character \[}\] at column 0:19')));
    });
    test(
        "should throw an error if an attribute selector is not closed properly",
        () {
      var styles = ".class[prop=value { style: val; }";
      var output = parse(styles);
      var errors = output.errors;
      expect(
          errors[0].msg,
          matches(
              new RegExp(r'Unbalanced CSS attribute selector at column 0:12')));
    });
    test(
        'should throw an error if a pseudo function '
        'selector is not closed properly', () {
      var styles = "body:lang(en { key:value; }";
      var output = parse(styles);
      var errors = output.errors;
      expect(
          errors[0].msg,
          matches(new RegExp(
              'Unbalanced pseudo selector function value at column 0:10')));
    });
    test(
        'should raise an error when a semi colon is missing from a CSS '
        'style/pair that isn\'t the last entry', () {
      var styles = '''.class {
        color: red
        background: blue
      }''';
      var output = parse(styles);
      var errors = output.errors;
      expect(errors.length, 1);
      expect(
          errors[0].msg,
          matches(new RegExp('The CSS key\/value definition did not '
              'end with a semicolon at column 1:15')));
    });
    test(
        'should parse the inner value of a :not() '
        'pseudo-selector as a CSS selector', () {
      var styles = '''div:not(.ignore-this-div) {
        prop: value;
      }''';
      var output = parse(styles);
      var errors = output.errors;
      var ast = output.ast;
      expect(errors.length, 0);
      var rule1 = (ast.rules[0] as CssSelectorRuleAST);
      expect(rule1.selectors.length, 1);
      var selector = rule1.selectors[0];
      expect(tokensToStringList(selector.tokens),
          ["div", ":", "not", "(", ".", "ignore-this-div", ")"]);
    });
    test("should raise parse errors when CSS key/value pairs are invalid", () {
      var styles = '''.class {
        background color: value;
        color: value
        font-size;
        font-weight
      }''';
      var output = parse(styles);
      var errors = output.errors;
      expect(errors.length, 4);
      expect(
          errors[0].msg,
          matches(new RegExp(
              r'Identifier does not match expected Character value \("color" should match ":"\) at column 1:19')));
      expect(
          errors[1].msg,
          matches(new RegExp(
              r'The CSS key\/value definition did not end with a semicolon at column 2:15')));
      expect(
          errors[2].msg,
          matches(new RegExp(
              r'The CSS property was not paired with a style value at column 3:8')));
      expect(
          errors[3].msg,
          matches(new RegExp(
              r'The CSS property was not paired with a style value at column 4:8')));
    });
    test("should recover from CSS key/value parse errors", () {
      var styles = '''
        .problem-class { background color: red; color: white; }
        .good-boy-class { background-color: red; color: white; }
       ''';
      var output = parse(styles);
      var ast = output.ast;
      expect(ast.rules.length, 2);
      var rule1 = (ast.rules[0] as CssSelectorRuleAST);
      expect(rule1.block.entries.length, 2);
      var style1 = (rule1.block.entries[0] as CssDefinitionAST);
      expect(style1.property.strValue, "background color");
      expect(tokensToStringList(style1.value.tokens), ["red"]);
      var style2 = (rule1.block.entries[1] as CssDefinitionAST);
      expect(style2.property.strValue, "color");
      expect(tokensToStringList(style2.value.tokens), ["white"]);
    });
    test("should parse minified CSS content properly", () {
      // this code was taken from the angular.io webpage's CSS code
      var styles = '''
.is-hidden{display:none!important}
.is-visible{display:block!important}
.is-visually-hidden{height:1px;width:1px;overflow:hidden;opacity:0.01;position:absolute;bottom:0;right:0;z-index:1}
.grid-fluid,.grid-fixed{margin:0 auto}
.grid-fluid .c1,.grid-fixed .c1,.grid-fluid .c2,.grid-fixed .c2,.grid-fluid .c3,.grid-fixed .c3,.grid-fluid .c4,.grid-fixed .c4,.grid-fluid .c5,.grid-fixed .c5,.grid-fluid .c6,.grid-fixed .c6,.grid-fluid .c7,.grid-fixed .c7,.grid-fluid .c8,.grid-fixed .c8,.grid-fluid .c9,.grid-fixed .c9,.grid-fluid .c10,.grid-fixed .c10,.grid-fluid .c11,.grid-fixed .c11,.grid-fluid .c12,.grid-fixed .c12{display:inline;float:left}
.grid-fluid .c1.grid-right,.grid-fixed .c1.grid-right,.grid-fluid .c2.grid-right,.grid-fixed .c2.grid-right,.grid-fluid .c3.grid-right,.grid-fixed .c3.grid-right,.grid-fluid .c4.grid-right,.grid-fixed .c4.grid-right,.grid-fluid .c5.grid-right,.grid-fixed .c5.grid-right,.grid-fluid .c6.grid-right,.grid-fixed .c6.grid-right,.grid-fluid .c7.grid-right,.grid-fixed .c7.grid-right,.grid-fluid .c8.grid-right,.grid-fixed .c8.grid-right,.grid-fluid .c9.grid-right,.grid-fixed .c9.grid-right,.grid-fluid .c10.grid-right,.grid-fixed .c10.grid-right,.grid-fluid .c11.grid-right,.grid-fixed .c11.grid-right,.grid-fluid .c12.grid-right,.grid-fixed .c12.grid-right{float:right}
.grid-fluid .c1.nb,.grid-fixed .c1.nb,.grid-fluid .c2.nb,.grid-fixed .c2.nb,.grid-fluid .c3.nb,.grid-fixed .c3.nb,.grid-fluid .c4.nb,.grid-fixed .c4.nb,.grid-fluid .c5.nb,.grid-fixed .c5.nb,.grid-fluid .c6.nb,.grid-fixed .c6.nb,.grid-fluid .c7.nb,.grid-fixed .c7.nb,.grid-fluid .c8.nb,.grid-fixed .c8.nb,.grid-fluid .c9.nb,.grid-fixed .c9.nb,.grid-fluid .c10.nb,.grid-fixed .c10.nb,.grid-fluid .c11.nb,.grid-fixed .c11.nb,.grid-fluid .c12.nb,.grid-fixed .c12.nb{margin-left:0}
.grid-fluid .c1.na,.grid-fixed .c1.na,.grid-fluid .c2.na,.grid-fixed .c2.na,.grid-fluid .c3.na,.grid-fixed .c3.na,.grid-fluid .c4.na,.grid-fixed .c4.na,.grid-fluid .c5.na,.grid-fixed .c5.na,.grid-fluid .c6.na,.grid-fixed .c6.na,.grid-fluid .c7.na,.grid-fixed .c7.na,.grid-fluid .c8.na,.grid-fixed .c8.na,.grid-fluid .c9.na,.grid-fixed .c9.na,.grid-fluid .c10.na,.grid-fixed .c10.na,.grid-fluid .c11.na,.grid-fixed .c11.na,.grid-fluid .c12.na,.grid-fixed .c12.na{margin-right:0}
       ''';
      var output = parse(styles);
      var errors = output.errors;
      expect(errors.length, 0);
      var ast = output.ast;
      expect(ast.rules.length, 8);
    });
    test("should parse a snippet of keyframe code from animate.css properly",
        () {
      // this code was taken from the angular.io webpage's CSS code
      var styles = '''
@charset "UTF-8";

/*!
 * animate.css -http://daneden.me/animate
 * Version - 3.5.1
 * Licensed under the MIT license - http://opensource.org/licenses/MIT
 *
 * Copyright (c) 2016 Daniel Eden
 */

.animated {
  -webkit-animation-duration: 1s;
  animation-duration: 1s;
  -webkit-animation-fill-mode: both;
  animation-fill-mode: both;
}

.animated.infinite {
  -webkit-animation-iteration-count: infinite;
  animation-iteration-count: infinite;
}

.animated.hinge {
  -webkit-animation-duration: 2s;
  animation-duration: 2s;
}

.animated.flipOutX,
.animated.flipOutY,
.animated.bounceIn,
.animated.bounceOut {
  -webkit-animation-duration: .75s;
  animation-duration: .75s;
}

@-webkit-keyframes bounce {
  from, 20%, 53%, 80%, to {
    -webkit-animation-timing-function: cubic-bezier(0.215, 0.610, 0.355, 1.000);
    animation-timing-function: cubic-bezier(0.215, 0.610, 0.355, 1.000);
    -webkit-transform: translate3d(0,0,0);
    transform: translate3d(0,0,0);
  }

  40%, 43% {
    -webkit-animation-timing-function: cubic-bezier(0.755, 0.050, 0.855, 0.060);
    animation-timing-function: cubic-bezier(0.755, 0.050, 0.855, 0.060);
    -webkit-transform: translate3d(0, -30px, 0);
    transform: translate3d(0, -30px, 0);
  }

  70% {
    -webkit-animation-timing-function: cubic-bezier(0.755, 0.050, 0.855, 0.060);
    animation-timing-function: cubic-bezier(0.755, 0.050, 0.855, 0.060);
    -webkit-transform: translate3d(0, -15px, 0);
    transform: translate3d(0, -15px, 0);
  }

  90% {
    -webkit-transform: translate3d(0,-4px,0);
    transform: translate3d(0,-4px,0);
  }
}
       ''';
      var output = parse(styles);
      var errors = output.errors;
      expect(errors.length, 0);
      var ast = output.ast;
      expect(ast.rules.length, 6);
      var finalRule = (ast.rules[ast.rules.length - 1] as CssBlockRuleAST);
      expect(finalRule.type, BlockType.Keyframes);
      expect(finalRule.block.entries.length, 4);
    });
  });
}
