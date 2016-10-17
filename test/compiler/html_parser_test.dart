library angular2.test.compiler.html_parser_test;

import "package:angular2/src/compiler/html_ast.dart";
import "package:angular2/src/compiler/html_lexer.dart" show HtmlTokenType;
import "package:angular2/src/compiler/html_parser.dart"
    show HtmlParser, HtmlParseTreeResult, HtmlTreeError;
import "package:angular2/src/compiler/parse_util.dart" show ParseError;
import 'package:test/test.dart';

import "html_ast_spec_utils.dart"
    show humanizeDom, humanizeDomSourceSpans, humanizeLineColumn;

void main() {
  group("HtmlParser", () {
    HtmlParser parser;
    setUp(() {
      parser = new HtmlParser();
    });
    group("parse", () {
      group("text nodes", () {
        test("should parse root level text nodes", () {
          expect(humanizeDom(parser.parse("a", "TestComp")), [
            [HtmlTextAst, "a", 0]
          ]);
        });
        test("should parse text nodes inside regular elements", () {
          expect(humanizeDom(parser.parse("<div>a</div>", "TestComp")), [
            [HtmlElementAst, "div", 0],
            [HtmlTextAst, "a", 1]
          ]);
        });
        test("should parse text nodes inside template elements", () {
          expect(
              humanizeDom(parser.parse("<template>a</template>", "TestComp")), [
            [HtmlElementAst, "template", 0],
            [HtmlTextAst, "a", 1]
          ]);
        });
        test("should parse CDATA", () {
          expect(humanizeDom(parser.parse("<![CDATA[text]]>", "TestComp")), [
            [HtmlTextAst, "text", 0]
          ]);
        });
      });
      group("elements", () {
        test("should parse root level elements", () {
          expect(humanizeDom(parser.parse("<div></div>", "TestComp")), [
            [HtmlElementAst, "div", 0]
          ]);
        });
        test("should parse elements inside of regular elements", () {
          expect(
              humanizeDom(parser.parse("<div><span></span></div>", "TestComp")),
              [
                [HtmlElementAst, "div", 0],
                [HtmlElementAst, "span", 1]
              ]);
        });
        test("should parse elements inside of template elements", () {
          expect(
              humanizeDom(parser.parse(
                  "<template><span></span></template>", "TestComp")),
              [
                [HtmlElementAst, "template", 0],
                [HtmlElementAst, "span", 1]
              ]);
        });
        test("should support void elements", () {
          expect(
              humanizeDom(parser.parse(
                  "<link rel=\"author license\" href=\"/about\">", "TestComp")),
              [
                [HtmlElementAst, "link", 0],
                [HtmlAttrAst, "rel", "author license"],
                [HtmlAttrAst, "href", "/about"]
              ]);
        });
        test("should not error on void elements from HTML5 spec", () {
          // <base> - it can be present in head only
          // <meta> - it can be present in head only
          // <command> - obsolete
          // <keygen> - obsolete
          [
            "<map><area></map>",
            "<div><br></div>",
            "<colgroup><col></colgroup>",
            "<div><embed></div>",
            "<div><hr></div>",
            "<div><img></div>",
            "<div><input></div>",
            "<object><param>/<object>",
            "<audio><source></audio>",
            "<audio><track></audio>",
            "<p><wbr></p>"
          ].forEach((html) {
            expect(parser.parse(html, "TestComp").errors, []);
          });
        });
        test("should close void elements on text nodes", () {
          expect(
              humanizeDom(parser.parse("<p>before<br>after</p>", "TestComp")), [
            [HtmlElementAst, "p", 0],
            [HtmlTextAst, "before", 1],
            [HtmlElementAst, "br", 1],
            [HtmlTextAst, "after", 1]
          ]);
        });
        test("should support optional end tags", () {
          expect(humanizeDom(parser.parse("<div><p>1<p>2</div>", "TestComp")), [
            [HtmlElementAst, "div", 0],
            [HtmlElementAst, "p", 1],
            [HtmlTextAst, "1", 2],
            [HtmlElementAst, "p", 1],
            [HtmlTextAst, "2", 2]
          ]);
        });
        test("should support nested elements", () {
          expect(
              humanizeDom(parser.parse(
                  "<ul><li><ul><li></li></ul></li></ul>", "TestComp")),
              [
                [HtmlElementAst, "ul", 0],
                [HtmlElementAst, "li", 1],
                [HtmlElementAst, "ul", 2],
                [HtmlElementAst, "li", 3]
              ]);
        });
        test("should add the requiredParent", () {
          expect(
              humanizeDom(parser.parse(
                  '<table><thead><tr head></tr></thead><tr noparent></tr>'
                  '<tbody><tr body></tr></tbody><tfoot><tr foot>'
                  '</tr></tfoot></table>',
                  'TestComp')),
              [
                [HtmlElementAst, "table", 0],
                [HtmlElementAst, "thead", 1],
                [HtmlElementAst, "tr", 2],
                [HtmlAttrAst, "head", ""],
                [HtmlElementAst, "tbody", 1],
                [HtmlElementAst, "tr", 2],
                [HtmlAttrAst, "noparent", ""],
                [HtmlElementAst, "tbody", 1],
                [HtmlElementAst, "tr", 2],
                [HtmlAttrAst, "body", ""],
                [HtmlElementAst, "tfoot", 1],
                [HtmlElementAst, "tr", 2],
                [HtmlAttrAst, "foot", ""]
              ]);
        });
        test("should not add the requiredParent when the parent is a template",
            () {
          expect(
              humanizeDom(
                  parser.parse("<template><tr></tr></template>", "TestComp")),
              [
                [HtmlElementAst, "template", 0],
                [HtmlElementAst, "tr", 1]
              ]);
        });
        test("should support explicit mamespace", () {
          expect(
              humanizeDom(parser.parse("<myns:div></myns:div>", "TestComp")), [
            [HtmlElementAst, "@myns:div", 0]
          ]);
        });
        test("should support implicit mamespace", () {
          expect(humanizeDom(parser.parse("<svg></svg>", "TestComp")), [
            [HtmlElementAst, "@svg:svg", 0]
          ]);
        });
        test("should propagate the namespace", () {
          expect(
              humanizeDom(
                  parser.parse("<myns:div><p></p></myns:div>", "TestComp")),
              [
                [HtmlElementAst, "@myns:div", 0],
                [HtmlElementAst, "@myns:p", 1]
              ]);
        });
        test("should match closing tags case sensitive", () {
          var errors = parser.parse("<DiV><P></p></dIv>", "TestComp").errors;
          expect(errors.length, 2);
          expect(humanizeErrors(errors), [
            ["p", "Unexpected closing tag \"p\"", "0:8"],
            ["dIv", "Unexpected closing tag \"dIv\"", "0:12"]
          ]);
        });
        test("should support self closing void elements", () {
          expect(humanizeDom(parser.parse("<input />", "TestComp")), [
            [HtmlElementAst, "input", 0]
          ]);
        });
        test("should support self closing foreign elements", () {
          expect(humanizeDom(parser.parse("<math />", "TestComp")), [
            [HtmlElementAst, "@math:math", 0]
          ]);
        });
        test("should ignore LF immediately after textarea, pre and listing",
            () {
          expect(
              humanizeDom(parser.parse(
                  '<p>\n</p><textarea>\n</textarea><pre>'
                  '\n\n</pre><listing>\n\n</listing>',
                  "TestComp")),
              [
                [HtmlElementAst, "p", 0],
                [HtmlTextAst, "\n", 1],
                [HtmlElementAst, "textarea", 0],
                [HtmlElementAst, "pre", 0],
                [HtmlTextAst, "\n", 1],
                [HtmlElementAst, "listing", 0],
                [HtmlTextAst, "\n", 1]
              ]);
        });
      });
      group("attributes", () {
        test("should parse attributes on regular elements case sensitive", () {
          expect(
              humanizeDom(
                  parser.parse("<div kEy=\"v\" key2=v2></div>", "TestComp")),
              [
                [HtmlElementAst, "div", 0],
                [HtmlAttrAst, "kEy", "v"],
                [HtmlAttrAst, "key2", "v2"]
              ]);
        });
        test("should parse attributes without values", () {
          expect(humanizeDom(parser.parse("<div k></div>", "TestComp")), [
            [HtmlElementAst, "div", 0],
            [HtmlAttrAst, "k", ""]
          ]);
        });
        test("should parse attributes on svg elements case sensitive", () {
          expect(
              humanizeDom(
                  parser.parse("<svg viewBox=\"0\"></svg>", "TestComp")),
              [
                [HtmlElementAst, "@svg:svg", 0],
                [HtmlAttrAst, "viewBox", "0"]
              ]);
        });
        test("should parse attributes on template elements", () {
          expect(
              humanizeDom(
                  parser.parse("<template k=\"v\"></template>", "TestComp")),
              [
                [HtmlElementAst, "template", 0],
                [HtmlAttrAst, "k", "v"]
              ]);
        });
        test("should support namespace", () {
          expect(
              humanizeDom(
                  parser.parse("<svg:use xlink:href=\"Port\" />", "TestComp")),
              [
                [HtmlElementAst, "@svg:use", 0],
                [HtmlAttrAst, "@xlink:href", "Port"]
              ]);
        });
      });
      group("comments", () {
        test("should preserve comments", () {
          expect(
              humanizeDom(
                  parser.parse("<!-- comment --><div></div>", "TestComp")),
              [
                [HtmlCommentAst, "comment", 0],
                [HtmlElementAst, "div", 0]
              ]);
        });
      });
      group("expansion forms", () {
        test("should parse out expansion forms", () {
          var parsed = parser.parse(
              '<div>before{messages.length, plural, =0 {You have <b>no</b> '
              'messages} =1 {One {{message}}}}after</div>',
              "TestComp",
              true);
          expect(humanizeDom(parsed), [
            [HtmlElementAst, "div", 0],
            [HtmlTextAst, "before", 1],
            [HtmlExpansionAst, "messages.length", "plural"],
            [HtmlExpansionCaseAst, "0"],
            [HtmlExpansionCaseAst, "1"],
            [HtmlTextAst, "after", 1]
          ]);
          var cases = (parsed.rootNodes[0] as dynamic).children[1].cases;
          expect(
              humanizeDom(new HtmlParseTreeResult(cases[0].expression, [])), [
            [HtmlTextAst, "You have ", 0],
            [HtmlElementAst, "b", 0],
            [HtmlTextAst, "no", 1],
            [HtmlTextAst, " messages", 0]
          ]);
          expect(
              humanizeDom(new HtmlParseTreeResult(cases[1].expression, [])), [
            [HtmlTextAst, "One {{message}}", 0]
          ]);
        });
        test("should parse out nested expansion forms", () {
          var parsed = parser.parse(
              '{messages.length, plural, =0 { {p.gender, gender, =m {m}} }}',
              "TestComp",
              true);
          expect(humanizeDom(parsed), [
            [HtmlExpansionAst, "messages.length", "plural"],
            [HtmlExpansionCaseAst, "0"]
          ]);
          var firstCase = (parsed.rootNodes[0] as dynamic).cases[0];
          expect(
              humanizeDom(new HtmlParseTreeResult(firstCase.expression, [])), [
            [HtmlExpansionAst, "p.gender", "gender"],
            [HtmlExpansionCaseAst, "m"],
            [HtmlTextAst, " ", 0]
          ]);
        });
        test("should error when expansion form is not closed", () {
          var p = parser.parse(
              '''{messages.length, plural, =0 {one}''', "TestComp", true);
          expect(humanizeErrors(p.errors), [
            [null, "Invalid expansion form. Missing '}'.", "0:34"]
          ]);
        });
        test("should error when expansion case is not closed", () {
          var p = parser.parse(
              '''{messages.length, plural, =0 {one''', "TestComp", true);
          expect(humanizeErrors(p.errors), [
            [null, "Invalid expansion form. Missing '}'.", "0:29"]
          ]);
        });
        test("should error when invalid html in the case", () {
          var p = parser.parse(
              '''{messages.length, plural, =0 {<b/>}''', "TestComp", true);
          expect(humanizeErrors(p.errors), [
            [
              "b",
              "Only void and foreign elements can be self closed \"b\"",
              "0:30"
            ]
          ]);
        });
      });
      group("source spans", () {
        test("should store the location", () {
          expect(
              humanizeDomSourceSpans(parser.parse(
                  '<div [prop]="v1" (e)="do()" attr="v2" noValue>\na\n</div>',
                  'TestComp')),
              [
                [
                  HtmlElementAst,
                  "div",
                  0,
                  "<div [prop]=\"v1\" (e)=\"do()\" attr=\"v2\" noValue>"
                ],
                [HtmlAttrAst, "[prop]", "v1", "[prop]=\"v1\""],
                [HtmlAttrAst, "(e)", "do()", "(e)=\"do()\""],
                [HtmlAttrAst, "attr", "v2", "attr=\"v2\""],
                [HtmlAttrAst, "noValue", "", "noValue"],
                [HtmlTextAst, "\na\n", 1, "\na\n"]
              ]);
        });
        test("should set the start and end source spans", () {
          var node = (parser.parse("<div>a</div>", "TestComp").rootNodes[0]
              as HtmlElementAst);
          expect(node.startSourceSpan.start.offset, 0);
          expect(node.startSourceSpan.end.offset, 5);
          expect(node.endSourceSpan.start.offset, 6);
          expect(node.endSourceSpan.end.offset, 12);
        });
      });
      group("errors", () {
        test("should report unexpected closing tags", () {
          var errors = parser.parse("<div></p></div>", "TestComp").errors;
          expect(errors.length, 1);
          expect(humanizeErrors(errors), [
            ["p", "Unexpected closing tag \"p\"", "0:5"]
          ]);
        });
        test("should report closing tag for void elements", () {
          var errors = parser.parse("<input></input>", "TestComp").errors;
          expect(errors.length, 1);
          expect(humanizeErrors(errors), [
            ["input", "Void elements do not have end tags \"input\"", "0:7"]
          ]);
        });
        test("should report self closing html element", () {
          var errors = parser.parse("<p />", "TestComp").errors;
          expect(errors.length, 1);
          expect(humanizeErrors(errors), [
            [
              "p",
              "Only void and foreign elements can be self closed \"p\"",
              "0:0"
            ]
          ]);
        });
        test("should report self closing custom element", () {
          var errors = parser.parse("<my-cmp />", "TestComp").errors;
          expect(errors.length, 1);
          expect(humanizeErrors(errors), [
            [
              "my-cmp",
              "Only void and foreign elements can be self closed \"my-cmp\"",
              "0:0"
            ]
          ]);
        });
        test("should also report lexer errors", () {
          var errors =
              parser.parse("<!-err--><div></p></div>", "TestComp").errors;
          expect(errors.length, 2);
          expect(humanizeErrors(errors), [
            [HtmlTokenType.COMMENT_START, "Unexpected character \"e\"", "0:3"],
            ["p", "Unexpected closing tag \"p\"", "0:14"]
          ]);
        });
      });
    });
  });
}

List<dynamic> humanizeErrors(List<ParseError> errors) {
  return errors.map((error) {
    if (error is HtmlTreeError) {
      // Parser errors
      return [
        (error.elementName as dynamic),
        error.msg,
        humanizeLineColumn(error.span.start)
      ];
    }
    // Tokenizer errors
    return [
      ((error as dynamic)).tokenType,
      error.msg,
      humanizeLineColumn(error.span.start)
    ];
  }).toList();
}
