library angular2.test.compiler.html_lexer_test;

import "package:angular2/src/compiler/html_lexer.dart"
    show tokenizeHtml, HtmlToken, HtmlTokenType, HtmlTokenError;
import "package:angular2/src/compiler/parse_util.dart"
    show ParseSourceSpan, ParseLocation, ParseSourceFile;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import 'package:test/test.dart';

main() {
  group("HtmlLexer", () {
    group("line/column numbers", () {
      test("should work without newlines", () {
        expect(tokenizeAndHumanizeLineColumn("<t>a</t>"), [
          [HtmlTokenType.TAG_OPEN_START, "0:0"],
          [HtmlTokenType.TAG_OPEN_END, "0:2"],
          [HtmlTokenType.TEXT, "0:3"],
          [HtmlTokenType.TAG_CLOSE, "0:4"],
          [HtmlTokenType.EOF, "0:8"]
        ]);
      });
      test("should work with one newline", () {
        expect(tokenizeAndHumanizeLineColumn("<t>\na</t>"), [
          [HtmlTokenType.TAG_OPEN_START, "0:0"],
          [HtmlTokenType.TAG_OPEN_END, "0:2"],
          [HtmlTokenType.TEXT, "0:3"],
          [HtmlTokenType.TAG_CLOSE, "1:1"],
          [HtmlTokenType.EOF, "1:5"]
        ]);
      });
      test("should work with multiple newlines", () {
        expect(tokenizeAndHumanizeLineColumn("<t\n>\na</t>"), [
          [HtmlTokenType.TAG_OPEN_START, "0:0"],
          [HtmlTokenType.TAG_OPEN_END, "1:0"],
          [HtmlTokenType.TEXT, "1:1"],
          [HtmlTokenType.TAG_CLOSE, "2:1"],
          [HtmlTokenType.EOF, "2:5"]
        ]);
      });
      test("should work with CR and LF", () {
        expect(tokenizeAndHumanizeLineColumn("<t\n>\r\na\r</t>"), [
          [HtmlTokenType.TAG_OPEN_START, "0:0"],
          [HtmlTokenType.TAG_OPEN_END, "1:0"],
          [HtmlTokenType.TEXT, "1:1"],
          [HtmlTokenType.TAG_CLOSE, "2:1"],
          [HtmlTokenType.EOF, "2:5"]
        ]);
      });
    });
    group("comments", () {
      test("should parse comments", () {
        expect(tokenizeAndHumanizeParts("<!--t\ne\rs\r\nt-->"), [
          [HtmlTokenType.COMMENT_START],
          [HtmlTokenType.RAW_TEXT, "t\ne\ns\nt"],
          [HtmlTokenType.COMMENT_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should store the locations", () {
        expect(tokenizeAndHumanizeSourceSpans("<!--t\ne\rs\r\nt-->"), [
          [HtmlTokenType.COMMENT_START, "<!--"],
          [HtmlTokenType.RAW_TEXT, "t\ne\rs\r\nt"],
          [HtmlTokenType.COMMENT_END, "-->"],
          [HtmlTokenType.EOF, ""]
        ]);
      });
      test("should report <!- without -", () {
        expect(tokenizeAndHumanizeErrors("<!-a"), [
          [HtmlTokenType.COMMENT_START, "Unexpected character \"a\"", "0:3"]
        ]);
      });
      test("should report missing end comment", () {
        expect(tokenizeAndHumanizeErrors("<!--"), [
          [HtmlTokenType.RAW_TEXT, "Unexpected character \"EOF\"", "0:4"]
        ]);
      });
    });
    group("doctype", () {
      test("should parse doctypes", () {
        expect(tokenizeAndHumanizeParts("<!doctype html>"), [
          [HtmlTokenType.DOC_TYPE, "doctype html"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should store the locations", () {
        expect(tokenizeAndHumanizeSourceSpans("<!doctype html>"), [
          [HtmlTokenType.DOC_TYPE, "<!doctype html>"],
          [HtmlTokenType.EOF, ""]
        ]);
      });
      test("should report missing end doctype", () {
        expect(tokenizeAndHumanizeErrors("<!"), [
          [HtmlTokenType.DOC_TYPE, "Unexpected character \"EOF\"", "0:2"]
        ]);
      });
    });
    group("CDATA", () {
      test("should parse CDATA", () {
        expect(tokenizeAndHumanizeParts("<![CDATA[t\ne\rs\r\nt]]>"), [
          [HtmlTokenType.CDATA_START],
          [HtmlTokenType.RAW_TEXT, "t\ne\ns\nt"],
          [HtmlTokenType.CDATA_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should store the locations", () {
        expect(tokenizeAndHumanizeSourceSpans("<![CDATA[t\ne\rs\r\nt]]>"), [
          [HtmlTokenType.CDATA_START, "<![CDATA["],
          [HtmlTokenType.RAW_TEXT, "t\ne\rs\r\nt"],
          [HtmlTokenType.CDATA_END, "]]>"],
          [HtmlTokenType.EOF, ""]
        ]);
      });
      test("should report <![ without CDATA[", () {
        expect(tokenizeAndHumanizeErrors("<![a"), [
          [HtmlTokenType.CDATA_START, "Unexpected character \"a\"", "0:3"]
        ]);
      });
      test("should report missing end cdata", () {
        expect(tokenizeAndHumanizeErrors("<![CDATA["), [
          [HtmlTokenType.RAW_TEXT, "Unexpected character \"EOF\"", "0:9"]
        ]);
      });
    });
    group("open tags", () {
      test("should parse open tags without prefix", () {
        expect(tokenizeAndHumanizeParts("<test>"), [
          [HtmlTokenType.TAG_OPEN_START, null, "test"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse namespace prefix", () {
        expect(tokenizeAndHumanizeParts("<ns1:test>"), [
          [HtmlTokenType.TAG_OPEN_START, "ns1", "test"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse void tags", () {
        expect(tokenizeAndHumanizeParts("<test/>"), [
          [HtmlTokenType.TAG_OPEN_START, null, "test"],
          [HtmlTokenType.TAG_OPEN_END_VOID],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should allow whitespace after the tag name", () {
        expect(tokenizeAndHumanizeParts("<test >"), [
          [HtmlTokenType.TAG_OPEN_START, null, "test"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should store the locations", () {
        expect(tokenizeAndHumanizeSourceSpans("<test>"), [
          [HtmlTokenType.TAG_OPEN_START, "<test"],
          [HtmlTokenType.TAG_OPEN_END, ">"],
          [HtmlTokenType.EOF, ""]
        ]);
      });
    });
    group("attributes", () {
      test("should parse attributes without prefix", () {
        expect(tokenizeAndHumanizeParts("<t a>"), [
          [HtmlTokenType.TAG_OPEN_START, null, "t"],
          [HtmlTokenType.ATTR_NAME, null, "a"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse attributes with prefix", () {
        expect(tokenizeAndHumanizeParts("<t ns1:a>"), [
          [HtmlTokenType.TAG_OPEN_START, null, "t"],
          [HtmlTokenType.ATTR_NAME, "ns1", "a"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse attributes whose prefix is not valid", () {
        expect(tokenizeAndHumanizeParts("<t (ns1:a)>"), [
          [HtmlTokenType.TAG_OPEN_START, null, "t"],
          [HtmlTokenType.ATTR_NAME, null, "(ns1:a)"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse attributes with single quote value", () {
        expect(tokenizeAndHumanizeParts("<t a='b'>"), [
          [HtmlTokenType.TAG_OPEN_START, null, "t"],
          [HtmlTokenType.ATTR_NAME, null, "a"],
          [HtmlTokenType.ATTR_VALUE, "b"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse attributes with double quote value", () {
        expect(tokenizeAndHumanizeParts("<t a=\"b\">"), [
          [HtmlTokenType.TAG_OPEN_START, null, "t"],
          [HtmlTokenType.ATTR_NAME, null, "a"],
          [HtmlTokenType.ATTR_VALUE, "b"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse attributes with unquoted value", () {
        expect(tokenizeAndHumanizeParts("<t a=b>"), [
          [HtmlTokenType.TAG_OPEN_START, null, "t"],
          [HtmlTokenType.ATTR_NAME, null, "a"],
          [HtmlTokenType.ATTR_VALUE, "b"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should allow whitespace", () {
        expect(tokenizeAndHumanizeParts("<t a = b >"), [
          [HtmlTokenType.TAG_OPEN_START, null, "t"],
          [HtmlTokenType.ATTR_NAME, null, "a"],
          [HtmlTokenType.ATTR_VALUE, "b"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse attributes with entities in values", () {
        expect(tokenizeAndHumanizeParts("<t a=\"&#65;&#x41;\">"), [
          [HtmlTokenType.TAG_OPEN_START, null, "t"],
          [HtmlTokenType.ATTR_NAME, null, "a"],
          [HtmlTokenType.ATTR_VALUE, "AA"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should not decode entities without trailing \";\"", () {
        expect(tokenizeAndHumanizeParts("<t a=\"&amp\" b=\"c&&d\">"), [
          [HtmlTokenType.TAG_OPEN_START, null, "t"],
          [HtmlTokenType.ATTR_NAME, null, "a"],
          [HtmlTokenType.ATTR_VALUE, "&amp"],
          [HtmlTokenType.ATTR_NAME, null, "b"],
          [HtmlTokenType.ATTR_VALUE, "c&&d"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse attributes with \"&\" in values", () {
        expect(tokenizeAndHumanizeParts("<t a=\"b && c &\">"), [
          [HtmlTokenType.TAG_OPEN_START, null, "t"],
          [HtmlTokenType.ATTR_NAME, null, "a"],
          [HtmlTokenType.ATTR_VALUE, "b && c &"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse values with CR and LF", () {
        expect(tokenizeAndHumanizeParts("<t a='t\ne\rs\r\nt'>"), [
          [HtmlTokenType.TAG_OPEN_START, null, "t"],
          [HtmlTokenType.ATTR_NAME, null, "a"],
          [HtmlTokenType.ATTR_VALUE, "t\ne\ns\nt"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should store the locations", () {
        expect(tokenizeAndHumanizeSourceSpans("<t a=b>"), [
          [HtmlTokenType.TAG_OPEN_START, "<t"],
          [HtmlTokenType.ATTR_NAME, "a"],
          [HtmlTokenType.ATTR_VALUE, "b"],
          [HtmlTokenType.TAG_OPEN_END, ">"],
          [HtmlTokenType.EOF, ""]
        ]);
      });
    });
    group("closing tags", () {
      test("should parse closing tags without prefix", () {
        expect(tokenizeAndHumanizeParts("</test>"), [
          [HtmlTokenType.TAG_CLOSE, null, "test"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse closing tags with prefix", () {
        expect(tokenizeAndHumanizeParts("</ns1:test>"), [
          [HtmlTokenType.TAG_CLOSE, "ns1", "test"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should allow whitespace", () {
        expect(tokenizeAndHumanizeParts("</ test >"), [
          [HtmlTokenType.TAG_CLOSE, null, "test"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should store the locations", () {
        expect(tokenizeAndHumanizeSourceSpans("</test>"), [
          [HtmlTokenType.TAG_CLOSE, "</test>"],
          [HtmlTokenType.EOF, ""]
        ]);
      });
      test("should report missing name after </", () {
        expect(tokenizeAndHumanizeErrors("</"), [
          [HtmlTokenType.TAG_CLOSE, "Unexpected character \"EOF\"", "0:2"]
        ]);
      });
      test("should report missing >", () {
        expect(tokenizeAndHumanizeErrors("</test"), [
          [HtmlTokenType.TAG_CLOSE, "Unexpected character \"EOF\"", "0:6"]
        ]);
      });
    });
    group("entities", () {
      test("should parse named entities", () {
        expect(tokenizeAndHumanizeParts("a&amp;b"), [
          [HtmlTokenType.TEXT, "a&b"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse hexadecimal entities", () {
        expect(tokenizeAndHumanizeParts("&#x41;&#X41;"), [
          [HtmlTokenType.TEXT, "AA"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse decimal entities", () {
        expect(tokenizeAndHumanizeParts("&#65;"), [
          [HtmlTokenType.TEXT, "A"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should store the locations", () {
        expect(tokenizeAndHumanizeSourceSpans("a&amp;b"), [
          [HtmlTokenType.TEXT, "a&amp;b"],
          [HtmlTokenType.EOF, ""]
        ]);
      });
      test("should report malformed/unknown entities", () {
        expect(tokenizeAndHumanizeErrors("&tbo;"), [
          [
            HtmlTokenType.TEXT,
            "Unknown entity \"tbo\" - use the \"&#<decimal>;\" or  \"&#x<hex>;\" syntax",
            "0:0"
          ]
        ]);
        expect(tokenizeAndHumanizeErrors("&#asdf;"), [
          [HtmlTokenType.TEXT, "Unexpected character \"s\"", "0:3"]
        ]);
        expect(tokenizeAndHumanizeErrors("&#xasdf;"), [
          [HtmlTokenType.TEXT, "Unexpected character \"s\"", "0:4"]
        ]);
        expect(tokenizeAndHumanizeErrors("&#xABC"), [
          [HtmlTokenType.TEXT, "Unexpected character \"EOF\"", "0:6"]
        ]);
      });
    });
    group("regular text", () {
      test("should parse text", () {
        expect(tokenizeAndHumanizeParts("a"), [
          [HtmlTokenType.TEXT, "a"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should handle CR & LF", () {
        expect(tokenizeAndHumanizeParts("t\ne\rs\r\nt"), [
          [HtmlTokenType.TEXT, "t\ne\ns\nt"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse entities", () {
        expect(tokenizeAndHumanizeParts("a&amp;b"), [
          [HtmlTokenType.TEXT, "a&b"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should parse text starting with \"&\"", () {
        expect(tokenizeAndHumanizeParts("a && b &"), [
          [HtmlTokenType.TEXT, "a && b &"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should store the locations", () {
        expect(tokenizeAndHumanizeSourceSpans("a"), [
          [HtmlTokenType.TEXT, "a"],
          [HtmlTokenType.EOF, ""]
        ]);
      });
      test("should allow \"<\" in text nodes", () {
        expect(tokenizeAndHumanizeParts("{{ a < b ? c : d }}"), [
          [HtmlTokenType.TEXT, "{{ a < b ? c : d }}"],
          [HtmlTokenType.EOF]
        ]);
        expect(tokenizeAndHumanizeSourceSpans("<p>a<b</p>"), [
          [HtmlTokenType.TAG_OPEN_START, "<p"],
          [HtmlTokenType.TAG_OPEN_END, ">"],
          [HtmlTokenType.TEXT, "a<b"],
          [HtmlTokenType.TAG_CLOSE, "</p>"],
          [HtmlTokenType.EOF, ""]
        ]);
        expect(tokenizeAndHumanizeParts("< a>"), [
          [HtmlTokenType.TEXT, "< a>"],
          [HtmlTokenType.EOF]
        ]);
      });
      // TODO(vicb): make the lexer aware of Angular expressions

      // see https://github.com/angular/angular/issues/5679
      test("should parse valid start tag in interpolation", () {
        expect(tokenizeAndHumanizeParts("{{ a <b && c > d }}"), [
          [HtmlTokenType.TEXT, "{{ a "],
          [HtmlTokenType.TAG_OPEN_START, null, "b"],
          [HtmlTokenType.ATTR_NAME, null, "&&"],
          [HtmlTokenType.ATTR_NAME, null, "c"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.TEXT, " d }}"],
          [HtmlTokenType.EOF]
        ]);
      });
    });
    group("raw text", () {
      test("should parse text", () {
        expect(tokenizeAndHumanizeParts('''<script>t
e
s
t</script>'''), [
          [HtmlTokenType.TAG_OPEN_START, null, "script"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.RAW_TEXT, "t\ne\ns\nt"],
          [HtmlTokenType.TAG_CLOSE, null, "script"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should not detect entities", () {
        expect(tokenizeAndHumanizeParts('''<script>&amp;</SCRIPT>'''), [
          [HtmlTokenType.TAG_OPEN_START, null, "script"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.RAW_TEXT, "&amp;"],
          [HtmlTokenType.TAG_CLOSE, null, "script"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should ignore other opening tags", () {
        expect(tokenizeAndHumanizeParts('''<script>a<div></script>'''), [
          [HtmlTokenType.TAG_OPEN_START, null, "script"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.RAW_TEXT, "a<div>"],
          [HtmlTokenType.TAG_CLOSE, null, "script"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should ignore other closing tags", () {
        expect(tokenizeAndHumanizeParts('''<script>a</test></script>'''), [
          [HtmlTokenType.TAG_OPEN_START, null, "script"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.RAW_TEXT, "a</test>"],
          [HtmlTokenType.TAG_CLOSE, null, "script"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should store the locations", () {
        expect(tokenizeAndHumanizeSourceSpans('''<script>a</script>'''), [
          [HtmlTokenType.TAG_OPEN_START, "<script"],
          [HtmlTokenType.TAG_OPEN_END, ">"],
          [HtmlTokenType.RAW_TEXT, "a"],
          [HtmlTokenType.TAG_CLOSE, "</script>"],
          [HtmlTokenType.EOF, ""]
        ]);
      });
    });
    group("escapable raw text", () {
      test("should parse text", () {
        expect(tokenizeAndHumanizeParts('''<title>t
e
s
t</title>'''), [
          [HtmlTokenType.TAG_OPEN_START, null, "title"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.ESCAPABLE_RAW_TEXT, "t\ne\ns\nt"],
          [HtmlTokenType.TAG_CLOSE, null, "title"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should detect entities", () {
        expect(tokenizeAndHumanizeParts('''<title>&amp;</title>'''), [
          [HtmlTokenType.TAG_OPEN_START, null, "title"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.ESCAPABLE_RAW_TEXT, "&"],
          [HtmlTokenType.TAG_CLOSE, null, "title"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should ignore other opening tags", () {
        expect(tokenizeAndHumanizeParts('''<title>a<div></title>'''), [
          [HtmlTokenType.TAG_OPEN_START, null, "title"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.ESCAPABLE_RAW_TEXT, "a<div>"],
          [HtmlTokenType.TAG_CLOSE, null, "title"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should ignore other closing tags", () {
        expect(tokenizeAndHumanizeParts('''<title>a</test></title>'''), [
          [HtmlTokenType.TAG_OPEN_START, null, "title"],
          [HtmlTokenType.TAG_OPEN_END],
          [HtmlTokenType.ESCAPABLE_RAW_TEXT, "a</test>"],
          [HtmlTokenType.TAG_CLOSE, null, "title"],
          [HtmlTokenType.EOF]
        ]);
      });
      test("should store the locations", () {
        expect(tokenizeAndHumanizeSourceSpans('''<title>a</title>'''), [
          [HtmlTokenType.TAG_OPEN_START, "<title"],
          [HtmlTokenType.TAG_OPEN_END, ">"],
          [HtmlTokenType.ESCAPABLE_RAW_TEXT, "a"],
          [HtmlTokenType.TAG_CLOSE, "</title>"],
          [HtmlTokenType.EOF, ""]
        ]);
      });
    });
    group("expansion forms", () {
      test("should parse an expansion form", () {
        expect(
            tokenizeAndHumanizeParts(
                "{one.two, three, =4 {four} =5 {five} }", true),
            [
              [HtmlTokenType.EXPANSION_FORM_START],
              [HtmlTokenType.RAW_TEXT, "one.two"],
              [HtmlTokenType.RAW_TEXT, "three"],
              [HtmlTokenType.EXPANSION_CASE_VALUE, "4"],
              [HtmlTokenType.EXPANSION_CASE_EXP_START],
              [HtmlTokenType.TEXT, "four"],
              [HtmlTokenType.EXPANSION_CASE_EXP_END],
              [HtmlTokenType.EXPANSION_CASE_VALUE, "5"],
              [HtmlTokenType.EXPANSION_CASE_EXP_START],
              [HtmlTokenType.TEXT, "five"],
              [HtmlTokenType.EXPANSION_CASE_EXP_END],
              [HtmlTokenType.EXPANSION_FORM_END],
              [HtmlTokenType.EOF]
            ]);
      });
      test("should parse an expansion form with text elements surrounding it",
          () {
        expect(
            tokenizeAndHumanizeParts(
                "before{one.two, three, =4 {four}}after", true),
            [
              [HtmlTokenType.TEXT, "before"],
              [HtmlTokenType.EXPANSION_FORM_START],
              [HtmlTokenType.RAW_TEXT, "one.two"],
              [HtmlTokenType.RAW_TEXT, "three"],
              [HtmlTokenType.EXPANSION_CASE_VALUE, "4"],
              [HtmlTokenType.EXPANSION_CASE_EXP_START],
              [HtmlTokenType.TEXT, "four"],
              [HtmlTokenType.EXPANSION_CASE_EXP_END],
              [HtmlTokenType.EXPANSION_FORM_END],
              [HtmlTokenType.TEXT, "after"],
              [HtmlTokenType.EOF]
            ]);
      });
      test("should parse an expansion forms with elements in it", () {
        expect(
            tokenizeAndHumanizeParts(
                "{one.two, three, =4 {four <b>a</b>}}", true),
            [
              [HtmlTokenType.EXPANSION_FORM_START],
              [HtmlTokenType.RAW_TEXT, "one.two"],
              [HtmlTokenType.RAW_TEXT, "three"],
              [HtmlTokenType.EXPANSION_CASE_VALUE, "4"],
              [HtmlTokenType.EXPANSION_CASE_EXP_START],
              [HtmlTokenType.TEXT, "four "],
              [HtmlTokenType.TAG_OPEN_START, null, "b"],
              [HtmlTokenType.TAG_OPEN_END],
              [HtmlTokenType.TEXT, "a"],
              [HtmlTokenType.TAG_CLOSE, null, "b"],
              [HtmlTokenType.EXPANSION_CASE_EXP_END],
              [HtmlTokenType.EXPANSION_FORM_END],
              [HtmlTokenType.EOF]
            ]);
      });
      test("should parse an expansion forms with interpolation in it", () {
        expect(
            tokenizeAndHumanizeParts("{one.two, three, =4 {four {{a}}}}", true),
            [
              [HtmlTokenType.EXPANSION_FORM_START],
              [HtmlTokenType.RAW_TEXT, "one.two"],
              [HtmlTokenType.RAW_TEXT, "three"],
              [HtmlTokenType.EXPANSION_CASE_VALUE, "4"],
              [HtmlTokenType.EXPANSION_CASE_EXP_START],
              [HtmlTokenType.TEXT, "four {{a}}"],
              [HtmlTokenType.EXPANSION_CASE_EXP_END],
              [HtmlTokenType.EXPANSION_FORM_END],
              [HtmlTokenType.EOF]
            ]);
      });
      test("should parse nested expansion forms", () {
        expect(
            tokenizeAndHumanizeParts(
                '''{one.two, three, =4 { {xx, yy, =x {one}} }}''', true),
            [
              [HtmlTokenType.EXPANSION_FORM_START],
              [HtmlTokenType.RAW_TEXT, "one.two"],
              [HtmlTokenType.RAW_TEXT, "three"],
              [HtmlTokenType.EXPANSION_CASE_VALUE, "4"],
              [HtmlTokenType.EXPANSION_CASE_EXP_START],
              [HtmlTokenType.EXPANSION_FORM_START],
              [HtmlTokenType.RAW_TEXT, "xx"],
              [HtmlTokenType.RAW_TEXT, "yy"],
              [HtmlTokenType.EXPANSION_CASE_VALUE, "x"],
              [HtmlTokenType.EXPANSION_CASE_EXP_START],
              [HtmlTokenType.TEXT, "one"],
              [HtmlTokenType.EXPANSION_CASE_EXP_END],
              [HtmlTokenType.EXPANSION_FORM_END],
              [HtmlTokenType.TEXT, " "],
              [HtmlTokenType.EXPANSION_CASE_EXP_END],
              [HtmlTokenType.EXPANSION_FORM_END],
              [HtmlTokenType.EOF]
            ]);
      });
    });
    group("errors", () {
      test("should include 2 lines of context in message", () {
        var src = "111\n222\n333\nE\n444\n555\n666\n";
        var file = new ParseSourceFile(src, "file://");
        var location = new ParseLocation(file, 12, 123, 456);
        var span = new ParseSourceSpan(location, location);
        var error = new HtmlTokenError("**ERROR**", null, span);
        expect(
            error.toString(),
            '''**ERROR** ("
222
333
[ERROR ->]E
444
555
"): file://@123:456''');
      });
    });
    group("unicode characters", () {
      test("should support unicode characters", () {
        expect(tokenizeAndHumanizeSourceSpans('''<p>İ</p>'''), [
          [HtmlTokenType.TAG_OPEN_START, "<p"],
          [HtmlTokenType.TAG_OPEN_END, ">"],
          [HtmlTokenType.TEXT, "İ"],
          [HtmlTokenType.TAG_CLOSE, "</p>"],
          [HtmlTokenType.EOF, ""]
        ]);
      });
    });
  });
}

List<HtmlToken> tokenizeWithoutErrors(String input,
    [bool tokenizeExpansionForms = false]) {
  var tokenizeResult = tokenizeHtml(input, "someUrl", tokenizeExpansionForms);
  if (tokenizeResult.errors.length > 0) {
    var errorString = tokenizeResult.errors.join("\n");
    throw new BaseException('''Unexpected parse errors:
${ errorString}''');
  }
  return tokenizeResult.tokens;
}

List<dynamic> tokenizeAndHumanizeParts(String input,
    [bool tokenizeExpansionForms = false]) {
  return tokenizeWithoutErrors(input, tokenizeExpansionForms)
      .map((token) =>
          (new List.from([(token.type as dynamic)])..addAll(token.parts)))
      .toList();
}

List<dynamic> tokenizeAndHumanizeSourceSpans(String input) {
  return tokenizeWithoutErrors(input)
      .map((token) => [(token.type as dynamic), token.sourceSpan.toString()])
      .toList();
}

String humanizeLineColumn(ParseLocation location) {
  return '''${ location . line}:${ location . col}''';
}

List<dynamic> tokenizeAndHumanizeLineColumn(String input) {
  return tokenizeWithoutErrors(input)
      .map((token) =>
          [(token.type as dynamic), humanizeLineColumn(token.sourceSpan.start)])
      .toList();
}

List<dynamic> tokenizeAndHumanizeErrors(String input) {
  return tokenizeHtml(input, "someUrl")
      .errors
      .map((tokenError) => [
            (tokenError.tokenType as dynamic),
            tokenError.msg,
            humanizeLineColumn(tokenError.span.start)
          ])
      .toList();
}
