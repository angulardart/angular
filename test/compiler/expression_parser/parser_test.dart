@TestOn('browser')
library angular2.test.compiler.expression_parser.parser_test;

import "package:angular2/src/compiler/expression_parser/ast.dart"
    show BindingPipe, AST;
import "package:angular2/src/compiler/expression_parser/lexer.dart" show Lexer;
import "package:angular2/src/compiler/expression_parser/parser.dart"
    show Parser;
import "package:angular2/testing_internal.dart";
import "package:test/test.dart";

import "unparser.dart" show Unparser;

void main() {
  Parser createParser() {
    return new Parser(new Lexer());
  }

  dynamic parseAction(text, [location = null]) {
    return createParser().parseAction(text, location);
  }

  dynamic parseBinding(text, [location = null]) {
    return createParser().parseBinding(text, location);
  }

  dynamic parseTemplateBindings(text, [location = null]) {
    return createParser()
        .parseTemplateBindings(text, location)
        .templateBindings;
  }

  dynamic parseInterpolation(text, [location = null]) {
    return createParser().parseInterpolation(text, location);
  }

  dynamic parseSimpleBinding(text, [location = null]) {
    return createParser().parseSimpleBinding(text, location);
  }

  String unparse(AST ast) {
    return new Unparser().unparse(ast);
  }

  void checkInterpolation(String exp, [String expected]) {
    var ast = parseInterpolation(exp);
    expected ??= exp;
    expect(unparse(ast), expected);
  }

  void checkBinding(String exp, [String expected]) {
    var ast = parseBinding(exp);
    expected ??= exp;
    expect(unparse(ast), expected);
  }

  void checkAction(String exp, [String expected]) {
    var ast = parseAction(exp);
    expected ??= exp;
    expect(unparse(ast), expected);
  }

  void expectActionError(text, matcher) {
    expect(() => parseAction(text), matcher);
  }

  void expectBindingError(text, matcher) {
    expect(() => parseBinding(text), matcher);
  }

  group("parser", () {
    group("parseAction", () {
      test("should parse numbers", () {
        checkAction("1");
      });
      test("should parse strings", () {
        checkAction("'1'", "\"1\"");
        checkAction("\"1\"");
      });
      test("should parse null", () {
        checkAction("null");
      });
      test("should parse unary - expressions", () {
        checkAction("-1", "0 - 1");
        checkAction("+1", "1");
      });
      test("should parse unary ! expressions", () {
        checkAction("!true");
        checkAction("!!true");
        checkAction("!!!true");
      });
      test("should parse multiplicative expressions", () {
        checkAction("3*4/2%5", "3 * 4 / 2 % 5");
      });
      test("should parse additive expressions", () {
        checkAction("3 + 6 - 2");
      });
      test("should parse relational expressions", () {
        checkAction("2 < 3");
        checkAction("2 > 3");
        checkAction("2 <= 2");
        checkAction("2 >= 2");
      });
      test("should parse equality expressions", () {
        checkAction("2 == 3");
        checkAction("2 != 3");
      });
      test("should parse strict equality expressions", () {
        checkAction("2 === 3");
        checkAction("2 !== 3");
      });
      test("should parse expressions", () {
        checkAction("true && true");
        checkAction("true || false");
      });
      test("should parse grouped expressions", () {
        checkAction("(1 + 2) * 3", "1 + 2 * 3");
      });
      test("should ignore comments in expressions", () {
        checkAction("a //comment", "a");
      });
      test("should retain // in string literals", () {
        checkAction(
            '''"http://www.google.com"''', '''"http://www.google.com"''');
      });
      test("should parse an empty string", () {
        checkAction("");
      });
      group("literals", () {
        test("should parse array", () {
          checkAction("[1][0]");
          checkAction("[[1]][0][0]");
          checkAction("[]");
          checkAction("[].length");
          checkAction("[1, 2].length");
        });
        test("should parse map", () {
          checkAction("{}");
          checkAction("{a: 1}[2]");
          checkAction("{}[\"a\"]");
        });
        test("should only allow identifier, string, or keyword as map key", () {
          expectActionError(
              "{(:0}",
              throwsWith(
                  new RegExp("expected identifier, keyword, or string")));
          expectActionError(
              "{1234:0}",
              throwsWith(
                  new RegExp("expected identifier, keyword, or string")));
        });
      });
      group("member access", () {
        test("should parse field access", () {
          checkAction("a");
          checkAction("a.a");
        });
        test("should only allow identifier or keyword as member names", () {
          expectActionError(
              "x.(", throwsWith(new RegExp("identifier or keyword")));
          expectActionError(
              "x. 1234", throwsWith(new RegExp("identifier or keyword")));
          expectActionError(
              "x.\"foo\"", throwsWith(new RegExp("identifier or keyword")));
        });
        test("should parse safe field access", () {
          checkAction("a?.a");
          checkAction("a.a?.a");
        });
      });
      group("method calls", () {
        test("should parse method calls", () {
          checkAction("fn()");
          checkAction("add(1, 2)");
          checkAction("a.add(1, 2)");
          checkAction("fn().add(1, 2)");
        });
      });
      group("functional calls", () {
        test("should parse function calls", () {
          checkAction("fn()(1, 2)");
        });
      });
      group("conditional", () {
        test("should parse ternary/conditional expressions", () {
          checkAction("7 == 3 + 4 ? 10 : 20");
          checkAction("false ? 10 : 20");
        });
        test("should throw on incorrect ternary operator syntax", () {
          expectActionError(
              "true?1",
              throwsWith(new RegExp(
                  "Parser Error: Conditional expression true\\?1 requires all 3 expressions")));
        });
      });
      group("ifNull", () {
        test("should parse if null expressions", () {
          checkAction("null ?? 0");
          checkAction("fn() ?? 0");
        });
        test("should throw on missing null case", () {
          expectActionError(
              "null ??",
              throwsWith(new RegExp(
                  "Parser Error: Unexpected end of expression: null \\?\\?")));
        });
      });
      group("assignment", () {
        test("should support field assignments", () {
          checkAction("a = 12");
          checkAction("a.a.a = 123");
          checkAction("a = 123; b = 234;");
        });
        test("should throw on safe field assignments", () {
          expectActionError("a?.a = 123",
              throwsWith(new RegExp("cannot be used in the assignment")));
        });
        test("should support array updates", () {
          checkAction("a[0] = 200");
        });
      });
      test("should error when using pipes", () {
        expectActionError(
            "x|blah", throwsWith(new RegExp("Cannot have a pipe")));
      });
      test("should store the source in the result", () {
        expect(parseAction("someExpr").source, "someExpr");
      });
      test("should store the passed-in location", () {
        expect(parseAction("someExpr", "location").location, "location");
      });
      test("should throw when encountering interpolation", () {
        expectActionError(
            "{{a()}}",
            throwsWith(
                "Got interpolation ({{}}) where expression was expected"));
      });
    });
    group("general error handling", () {
      test("should throw on an unexpected token", () {
        expectActionError(
            "[1,2] trac", throwsWith(new RegExp("Unexpected token 'trac'")));
      });
      test("should throw a reasonable error for unconsumed tokens", () {
        expectActionError(
            ")",
            throwsWith(
                new RegExp("Unexpected token \\) at column 1 in \\[\\)\\]")));
      });
      test("should throw on missing expected token", () {
        expectActionError(
            "a(b",
            throwsWith(new RegExp(
                "Missing expected \\) at the end of the expression \\[a\\(b\\]")));
      });
    });
    group("parseBinding", () {
      group("pipes", () {
        test("should parse pipes", () {
          checkBinding("a(b | c)", "a((b | c))");
          checkBinding("a.b(c.d(e) | f)", "a.b((c.d(e) | f))");
          checkBinding("[1, 2, 3] | a", "([1, 2, 3] | a)");
          checkBinding("{a: 1} | b", "({a: 1} | b)");
          checkBinding("a[b] | c", "(a[b] | c)");
          checkBinding("a?.b | c", "(a?.b | c)");
          checkBinding("true | a", "(true | a)");
          checkBinding("a | b:c | d", "((a | b:c) | d)");
          checkBinding("a | b:(c | d)", "(a | b:(c | d))");
        });
        test("should only allow identifier or keyword as formatter names", () {
          expectBindingError(
              "\"Foo\"|(", throwsWith(new RegExp("identifier or keyword")));
          expectBindingError(
              "\"Foo\"|1234", throwsWith(new RegExp("identifier or keyword")));
          expectBindingError("\"Foo\"|\"uppercase\"",
              throwsWith(new RegExp("identifier or keyword")));
        });
        test("should parse quoted expressions", () {
          checkBinding("a:b", "a:b");
        });
        test("should not crash when prefix part is not tokenizable", () {
          checkBinding("\"a:b\"", "\"a:b\"");
        });
        test("should ignore whitespace around quote prefix", () {
          checkBinding(" a :b", "a:b");
        });
        test("should refuse prefixes that are not single identifiers", () {
          expectBindingError("a + b:c", throws);
          expectBindingError("1:c", throws);
        });
      });
      test("should store the source in the result", () {
        expect(parseBinding("someExpr").source, "someExpr");
      });
      test("should store the passed-in location", () {
        expect(parseBinding("someExpr", "location").location, "location");
      });
      test("should throw on chain expressions", () {
        expect(() => parseBinding("1;2"),
            throwsWith(new RegExp("contain chained expression")));
      });
      test("should throw on assignment", () {
        expect(() => parseBinding("a=2"),
            throwsWith(new RegExp("contain assignments")));
      });
      test("should throw when encountering interpolation", () {
        expectBindingError(
            "{{a.b}}",
            throwsWith(
                "Got interpolation ({{}}) where expression was expected"));
      });
      test("should parse conditional expression", () {
        checkBinding("a < b ? a : b");
      });
      test("should ignore comments in bindings", () {
        checkBinding("a //comment", "a");
      });
      test("should retain // in string literals", () {
        checkBinding(
            '''"http://www.google.com"''', '''"http://www.google.com"''');
      });
      test("should retain // in : microsyntax", () {
        checkBinding("one:a//b", "one:a//b");
      });
    });
    group("parseTemplateBindings", () {
      List keys(List<dynamic> templateBindings) {
        return templateBindings.map((binding) => binding.key).toList();
      }

      List keyValues(List<dynamic> templateBindings) {
        return templateBindings.map((binding) {
          if (binding.keyIsVar) {
            return "let " +
                binding.key +
                (binding.name == null ? "=null" : "=" + binding.name);
          } else {
            return binding.key +
                (binding.expression == null
                    ? ""
                    : '''=${ binding . expression}''');
          }
        }).toList();
      }

      List exprSources(List<dynamic> templateBindings) {
        return templateBindings
            .map((binding) =>
                binding.expression != null ? binding.expression.source : null)
            .toList();
      }

      test("should parse an empty string", () {
        expect(parseTemplateBindings(""), []);
      });
      test("should parse a string without a value", () {
        expect(keys(parseTemplateBindings("a")), ["a"]);
      });
      test(
          "should only allow identifier, string, or keyword including dashes as keys",
          () {
        var bindings = parseTemplateBindings("a:'b'");
        expect(keys(bindings), ["a"]);
        bindings = parseTemplateBindings("'a':'b'");
        expect(keys(bindings), ["a"]);
        bindings = parseTemplateBindings("\"a\":'b'");
        expect(keys(bindings), ["a"]);
        bindings = parseTemplateBindings("a-b:'c'");
        expect(keys(bindings), ["a-b"]);
        expect(() {
          parseTemplateBindings("(:0");
        }, throwsWith(new RegExp("expected identifier, keyword, or string")));
        expect(() {
          parseTemplateBindings("1234:0");
        }, throwsWith(new RegExp("expected identifier, keyword, or string")));
      });
      test("should detect expressions as value", () {
        var bindings = parseTemplateBindings("a:b");
        expect(exprSources(bindings), ["b"]);
        bindings = parseTemplateBindings("a:1+1");
        expect(exprSources(bindings), ["1+1"]);
      });
      test("should detect names as value", () {
        var bindings = parseTemplateBindings("a:let b");
        expect(keyValues(bindings), ["a", "let b=\$implicit"]);
      });
      test("should allow space and colon as separators", () {
        var bindings = parseTemplateBindings("a:b");
        expect(keys(bindings), ["a"]);
        expect(exprSources(bindings), ["b"]);
        bindings = parseTemplateBindings("a b");
        expect(keys(bindings), ["a"]);
        expect(exprSources(bindings), ["b"]);
      });
      test("should allow multiple pairs", () {
        var bindings = parseTemplateBindings("a 1 b 2");
        expect(keys(bindings), ["a", "aB"]);
        expect(exprSources(bindings), ["1 ", "2"]);
      });
      test("should store the sources in the result", () {
        var bindings = parseTemplateBindings("a 1,b 2");
        expect(bindings[0].expression.source, "1");
        expect(bindings[1].expression.source, "2");
      });
      test("should store the passed-in location", () {
        var bindings = parseTemplateBindings("a 1,b 2", "location");
        expect(bindings[0].expression.location, "location");
      });
      test("should support var notation with a deprecation warning", () {
        var bindings = createParser().parseTemplateBindings("var i", null);
        expect(keyValues(bindings.templateBindings), ["let i=\$implicit"]);
        expect(bindings.warnings, [
          "\"var\" inside of expressions is deprecated. Use \"let\" instead!"
        ]);
      });
      test("should support # notation with a deprecation warning", () {
        var bindings = createParser().parseTemplateBindings("#i", null);
        expect(keyValues(bindings.templateBindings), ["let i=\$implicit"]);
        expect(bindings.warnings, [
          "\"#\" inside of expressions is deprecated. Use \"let\" instead!"
        ]);
      });
      test("should support let notation", () {
        var bindings = parseTemplateBindings("let i");
        expect(keyValues(bindings), ["let i=\$implicit"]);
        bindings = parseTemplateBindings("let i");
        expect(keyValues(bindings), ["let i=\$implicit"]);
        bindings = parseTemplateBindings("let a; let b");
        expect(keyValues(bindings), ["let a=\$implicit", "let b=\$implicit"]);
        bindings = parseTemplateBindings("let a; let b;");
        expect(keyValues(bindings), ["let a=\$implicit", "let b=\$implicit"]);
        bindings = parseTemplateBindings("let i-a = k-a");
        expect(keyValues(bindings), ["let i-a=k-a"]);
        bindings = parseTemplateBindings("keyword let item; let i = k");
        expect(
            keyValues(bindings), ["keyword", "let item=\$implicit", "let i=k"]);
        bindings = parseTemplateBindings("keyword: let item; let i = k");
        expect(
            keyValues(bindings), ["keyword", "let item=\$implicit", "let i=k"]);
        bindings = parseTemplateBindings(
            "directive: let item in expr; let a = b", "location");
        expect(keyValues(bindings), [
          "directive",
          "let item=\$implicit",
          "directiveIn=expr in location",
          "let a=b"
        ]);
      });
      test("should parse pipes", () {
        var bindings = parseTemplateBindings("key value|pipe");
        var ast = bindings[0].expression.ast;
        expect(ast, new isInstanceOf<BindingPipe>());
      });
    });
    group("parseInterpolation", () {
      test("should return null if no interpolation", () {
        expect(parseInterpolation("nothing"), isNull);
      });
      test("should parse no prefix/suffix interpolation", () {
        var ast = parseInterpolation("{{a}}").ast;
        expect(ast.strings, ["", ""]);
        expect(ast.expressions.length, 1);
        expect(ast.expressions[0].name, "a");
      });
      test("should parse prefix/suffix with multiple interpolation", () {
        var originalExp = "before {{ a }} middle {{ b }} after";
        var ast = parseInterpolation(originalExp).ast;
        expect(new Unparser().unparse(ast), originalExp);
      });
      test("should throw on empty interpolation expressions", () {
        expect(
            () => parseInterpolation("{{}}"),
            throwsWith(
                "Parser Error: Blank expressions are not allowed in interpolated strings"));
        expect(
            () => parseInterpolation("foo {{  }}"),
            throwsWith(
                "Parser Error: Blank expressions are not allowed in interpolated strings"));
      });
      test("should parse conditional expression", () {
        checkInterpolation("{{ a < b ? a : b }}");
      });
      test("should parse expression with newline characters", () {
        checkInterpolation(
            '''{{ \'foo\' +
 \'bar\' +
 \'baz\' }}''',
            '''{{ "foo" + "bar" + "baz" }}''');
      });
      group("comments", () {
        test("should ignore comments in interpolation expressions", () {
          checkInterpolation("{{a //comment}}", "{{ a }}");
        });
        test("should retain // in single quote strings", () {
          checkInterpolation('''{{ \'http://www.google.com\' }}''',
              '''{{ "http://www.google.com" }}''');
        });
        test("should retain // in double quote strings", () {
          checkInterpolation('''{{ "http://www.google.com" }}''',
              '''{{ "http://www.google.com" }}''');
        });
        test("should ignore comments after string literals", () {
          checkInterpolation('''{{ "a//b" //comment }}''', '''{{ "a//b" }}''');
        });
        test("should retain // in complex strings", () {
          checkInterpolation('''{{"//a\'//b`//c`//d\'//e" //comment}}''',
              '''{{ "//a\'//b`//c`//d\'//e" }}''');
        });
        test("should retain // in nested, unterminated strings", () {
          checkInterpolation('''{{ "a\'b`" //comment}}''', '''{{ "a\'b`" }}''');
        });
      });
    });
    group("parseSimpleBinding", () {
      test("should parse a field access", () {
        var p = parseSimpleBinding("name");
        expect(unparse(p), "name");
      });
      test("should parse a constant", () {
        var p = parseSimpleBinding("[1, 2]");
        expect(unparse(p), "[1, 2]");
      });
      test("should throw when the given expression is not just a field name",
          () {
        expect(
            () => parseSimpleBinding("name + 1"),
            throwsWith(
                "Host binding expression can only contain field access and constants"));
      });
      test("should throw when encountering interpolation", () {
        expect(
            () => parseSimpleBinding("{{exp}}"),
            throwsWith(
                "Got interpolation ({{}}) where expression was expected"));
      });
    });
    group("wrapLiteralPrimitive", () {
      test("should wrap a literal primitive", () {
        expect(unparse(createParser().wrapLiteralPrimitive("foo", null)),
            "\"foo\"");
      });
    });
  });
}
