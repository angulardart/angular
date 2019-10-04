@TestOn('vm')
import 'package:test/test.dart';
import 'package:_tests/test_util.dart';
import 'package:angular/src/compiler/compile_metadata.dart'
    show CompileIdentifierMetadata;
import 'package:angular/src/compiler/expression_parser/ast.dart'
    show ASTWithSource, Interpolation, PropertyRead;
import 'package:angular/src/compiler/expression_parser/lexer.dart' show Lexer;
import 'package:angular/src/compiler/expression_parser/parser.dart' show Parser;

import 'unparser.dart' show Unparser;

throwsWithMatch(RegExp regExp) =>
    throwsA(predicate((e) => regExp.hasMatch(e.toString())));

void main() {
  Parser createParser() {
    return Parser(Lexer(), supportNewPipeSyntax: true);
  }

  ASTWithSource parseAction(text, [location]) {
    return createParser().parseAction(text, location, []);
  }

  ASTWithSource parseBinding(text, [location]) {
    return createParser().parseBinding(text, location, []);
  }

  ASTWithSource parseInterpolation(text, [location]) {
    return createParser().parseInterpolation(text, location, []);
  }

  String unparse(ASTWithSource ast) {
    return Unparser().unparse(ast);
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
      });
      group("member access", () {
        test("should parse field access", () {
          checkAction("a");
          checkAction("a.a");
        });
        test("should only allow identifier or keyword as member names", () {
          expectActionError("x.(", throwsWith("identifier or keyword"));
          expectActionError("x. 1234", throwsWith("identifier or keyword"));
          expectActionError("x.\"foo\"", throwsWith("identifier or keyword"));
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
          checkAction("fn(a: 1)");
        });
        test("should parse named argument that collides with an export", () {
          final parser = createParser();
          final text = "fn(a: 1)";
          final export = CompileIdentifierMetadata(name: "a");
          final ast = parser.parseAction(text, null, [export]);
          expect(unparse(ast), text);
        });
      });
      group("functional calls", () {
        test("should parse function calls", () {
          checkAction("fn()(1, 2)");
          checkAction("fn()(a: 1)");
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
              throwsWithMatch(RegExp(
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
              throwsWithMatch(RegExp(
                  "Parser Error: Unexpected end of expression: null \\?\\?")));
        });
      });
      group("assignment", () {
        test("should support field assignments", () {
          checkAction("a = 12");
          checkAction("a.a.a = 123");
        });
        test("should throw on safe field assignments", () {
          expectActionError(
              "a?.a = 123", throwsWith("cannot be used in the assignment"));
        });
        test("should support array updates", () {
          checkAction("a[0] = 200");
        });
      });
      test("should error when using pipes", () {
        expectActionError("x|blah", throwsWith("Cannot have a pipe"));
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
      test("should not support multiple statements", () {
        expect(
          () => parseAction("1;2"),
          throwsWith("Event bindings no longer support multiple statements"),
        );
      });
    });
    group("general error handling", () {
      test("should throw on an unexpected token", () {
        expectActionError("[1,2] trac", throwsWith("Unexpected token 'trac'"));
      });
      test("should throw a reasonable error for unconsumed tokens", () {
        expectActionError(
            ")",
            throwsWithMatch(
                RegExp("Unexpected token \\) at column 1 in \\[\\)\\]")));
      });
      test("should throw on missing expected token", () {
        expectActionError(
            "a(b",
            throwsWithMatch(RegExp(
                "Missing expected \\) at the end of the expression \\[a\\(b\\]")));
      });
      test("should not crash when encountering an invalid event", () {
        // Template validator should prevent from ever getting here, but just
        // in case lets avoid an NPE error that is impossible to debug.
        expectActionError(null, throwsWith('Blank expressions are not'));
      });
      test("should throw on a lexer error", () {
        expectActionError("a = 1E-",
            throwsWith("Invalid exponent at offset 6 of expression"));
      });
    });
    group("parseBinding", () {
      group("pipes", () {
        test("should parse pipes", () {
          checkBinding("a(b | c)", "a((b | c))");
          checkBinding("a.b(c.d(e) | f)", "a.b((c.d(e) | f))");
          checkBinding("[1, 2, 3] | a", "([1, 2, 3] | a)");
          checkBinding("a[b] | c", "(a[b] | c)");
          checkBinding("a?.b | c", "(a?.b | c)");
          checkBinding("true | a", "(true | a)");
          checkBinding("a | b:c | d", "((a | b:c) | d)");
          checkBinding("a | b:(c | d)", "(a | b:(c | d))");
          checkBinding("a(n: (b | c))");
          checkBinding("a(n: (a | b:c | d))", "a(n: ((a | b:c) | d))");
          checkBinding("f(value | pipe:x:y)", "f((value | pipe:x:y))");
        });

        // TODO(b/133512917): Change un-parser when old syntax is removed.
        test("should parse pipes with the new function call syntax", () {
          final pipe = r'$pipe';
          checkBinding("a($pipe.c(b))", "a((b | c))");
          checkBinding("$pipe.f(a.b(c.d(e)))", "(a.b(c.d(e)) | f)");
          checkBinding("$pipe.a([1, 2, 3])", "([1, 2, 3] | a)");
          checkBinding("$pipe.c(a[b])", "(a[b] | c)");
          checkBinding("$pipe.c(a?.b)", "(a?.b | c)");
          checkBinding("$pipe.a(true)", "(true | a)");
          checkBinding("$pipe.d($pipe.b(a, c))", "((a | b:c) | d)");
          checkBinding("$pipe.b(a, $pipe.d(c))", "(a | b:(c | d))");
        });

        test("should only allow identifier or keyword as formatter names", () {
          expectBindingError("\"Foo\"|(", throwsWith("identifier or keyword"));
          expectBindingError(
              "\"Foo\"|1234", throwsWith("identifier or keyword"));
          expectBindingError(
              "\"Foo\"|\"uppercase\"", throwsWith("identifier or keyword"));
        });
        test("should refuse prefixes that are not single identifiers", () {
          expectBindingError("a + b:c", throwsWith("Unexpected token"));
          expectBindingError(
              "1:c", throwsWith("Parser Error: Unexpected token"));
        });
      });
      test("should store the source in the result", () {
        expect(parseBinding("someExpr").source, "someExpr");
      });
      test("should store the passed-in location", () {
        expect(parseBinding("someExpr", "location").location, "location");
      });
      test("should throw on multiple statements", () {
        expect(
          () => parseBinding("1;2"),
          throwsWith("Expression binding cannot contain multiple statements"),
        );
      });
      test("should throw on assignment", () {
        expect(() => parseBinding("a=2"), throwsWith("contain assignments"));
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
    });
    group("parseInterpolation", () {
      test("should return null if no interpolation", () {
        expect(parseInterpolation("nothing"), isNull);
      });
      test("should parse no prefix/suffix interpolation", () {
        var ast = parseInterpolation("{{a}}").ast as Interpolation;
        expect(ast.strings, ["", ""]);
        expect(ast.expressions.length, 1);
        expect((ast.expressions[0] as PropertyRead).name, "a");
      });
      test("should parse prefix/suffix with multiple interpolation", () {
        var originalExp = "before {{ a }} middle {{ b }} after";
        var ast = parseInterpolation(originalExp);
        expect(Unparser().unparse(ast), originalExp);
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
        checkInterpolation('''{{ \'foo\' +
 \'bar\' +
 \'baz\' }}''', '''{{ "foo" + "bar" + "baz" }}''');
      });
      group("comments", () {
        test("should ignore comments in interpolation expressions", () {
          checkInterpolation("{{a //comment}}", "{{ a }}");
        });
        test("should retain // in single quote strings", () {
          checkInterpolation("{{ \'http://www.google.com\' }}",
              '{{ "http://www.google.com" }}');
        });
        test("should retain // in double quote strings", () {
          checkInterpolation(
              '{{ "http://www.google.com" }}', '{{ "http://www.google.com" }}');
        });
        test("should ignore comments after string literals", () {
          checkInterpolation('{{ "a//b" //comment }}', '{{ "a//b" }}');
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
    group("wrapLiteralPrimitive", () {
      test("should wrap a literal primitive", () {
        expect(unparse(createParser().wrapLiteralPrimitive("foo", null)),
            "\"foo\"");
      });
    });
  });
}
