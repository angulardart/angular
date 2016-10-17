@TestOn('browser')
library angular2.test.compiler.expression_parser.lexer_test;

import "package:angular2/src/compiler/expression_parser/lexer.dart"
    show Lexer, Token;
import "package:angular2/testing_internal.dart";
import "package:test/test.dart";

List<Token> lex(String text) {
  return new Lexer().tokenize(text);
}

void expectToken(token, index) {
  expect(token is Token, isTrue);
  expect(token.index, index);
}

void expectCharacterToken(token, index, character) {
  expect(character, hasLength(1));
  expectToken(token, index);
  expect(token.isCharacter(character.codeUnitAt(0)), isTrue);
}

void expectOperatorToken(token, index, operator) {
  expectToken(token, index);
  expect(token.isOperator(operator), isTrue);
}

void expectNumberToken(token, index, n) {
  expectToken(token, index);
  expect(token.isNumber(), isTrue);
  expect(token.toNumber(), n);
}

void expectStringToken(token, index, str) {
  expectToken(token, index);
  expect(token.isString(), isTrue);
  expect(token.toString(), str);
}

void expectIdentifierToken(Token token, int index, identifier) {
  expectToken(token, index);
  expect(token.isIdentifier(), isTrue);
  expect(token.toString(), identifier);
}

void expectKeywordToken(token, index, keyword) {
  expectToken(token, index);
  expect(token.isKeyword(), isTrue);
  expect(token.toString(), keyword);
}

void main() {
  group("lexer", () {
    group("token", () {
      test("should tokenize a simple identifier", () {
        var tokens = lex("j");
        expect(tokens.length, 1);
        expectIdentifierToken(tokens[0], 0, "j");
      });
      test("should tokenize a dotted identifier", () {
        var tokens = lex("j.k");
        expect(tokens.length, 3);
        expectIdentifierToken(tokens[0], 0, "j");
        expectCharacterToken(tokens[1], 1, ".");
        expectIdentifierToken(tokens[2], 2, "k");
      });
      test("should tokenize an operator", () {
        var tokens = lex("j-k");
        expect(tokens.length, 3);
        expectOperatorToken(tokens[1], 1, "-");
      });
      test("should tokenize an indexed operator", () {
        var tokens = lex("j[k]");
        expect(tokens.length, 4);
        expectCharacterToken(tokens[1], 1, "[");
        expectCharacterToken(tokens[3], 3, "]");
      });
      test("should tokenize numbers", () {
        var tokens = lex("88");
        expect(tokens.length, 1);
        expectNumberToken(tokens[0], 0, 88);
      });
      test("should tokenize numbers within index ops", () {
        expectNumberToken(lex("a[22]")[2], 2, 22);
      });
      test("should tokenize simple quoted strings", () {
        expectStringToken(lex("\"a\"")[0], 0, "a");
      });
      test("should tokenize quoted strings with escaped quotes", () {
        expectStringToken(lex("\"a\\\"\"")[0], 0, "a\"");
      });
      test("should tokenize a string", () {
        List<Token> tokens = lex("j-a.bc[22]+1.3|f:'a\\'c':\"d\\\"e\"");
        expectIdentifierToken(tokens[0], 0, "j");
        expectOperatorToken(tokens[1], 1, "-");
        expectIdentifierToken(tokens[2], 2, "a");
        expectCharacterToken(tokens[3], 3, ".");
        expectIdentifierToken(tokens[4], 4, "bc");
        expectCharacterToken(tokens[5], 6, "[");
        expectNumberToken(tokens[6], 7, 22);
        expectCharacterToken(tokens[7], 9, "]");
        expectOperatorToken(tokens[8], 10, "+");
        expectNumberToken(tokens[9], 11, 1.3);
        expectOperatorToken(tokens[10], 14, "|");
        expectIdentifierToken(tokens[11], 15, "f");
        expectCharacterToken(tokens[12], 16, ":");
        expectStringToken(tokens[13], 17, "a'c");
        expectCharacterToken(tokens[14], 23, ":");
        expectStringToken(tokens[15], 24, "d\"e");
      });
      test("should tokenize undefined", () {
        List<Token> tokens = lex("undefined");
        expectKeywordToken(tokens[0], 0, "undefined");
        expect(tokens[0].isKeywordUndefined(), isTrue);
      });
      test("should ignore whitespace", () {
        List<Token> tokens = lex("a \t \n \r b");
        expectIdentifierToken(tokens[0], 0, "a");
        expectIdentifierToken(tokens[1], 8, "b");
      });
      test("should tokenize quoted string", () {
        var str = "['\\'', \"\\\"\"]";
        List<Token> tokens = lex(str);
        expectStringToken(tokens[1], 1, "'");
        expectStringToken(tokens[3], 7, "\"");
      });
      test("should tokenize escaped quoted string", () {
        var str = "\"\\\"\\n\\f\\r\\t\\v\\u00A0\"";
        List<Token> tokens = lex(str);
        expect(tokens.length, 1);
        expect(tokens[0].toString(), "\"\n\f\r\t\u000b ");
      });
      test("should tokenize unicode", () {
        List<Token> tokens = lex("\"\\u00A0\"");
        expect(tokens.length, 1);
        expect(tokens[0].toString(), " ");
      });
      test("should tokenize relation", () {
        List<Token> tokens = lex("! == != < > <= >= === !==");
        expectOperatorToken(tokens[0], 0, "!");
        expectOperatorToken(tokens[1], 2, "==");
        expectOperatorToken(tokens[2], 5, "!=");
        expectOperatorToken(tokens[3], 8, "<");
        expectOperatorToken(tokens[4], 10, ">");
        expectOperatorToken(tokens[5], 12, "<=");
        expectOperatorToken(tokens[6], 15, ">=");
        expectOperatorToken(tokens[7], 18, "===");
        expectOperatorToken(tokens[8], 22, "!==");
      });
      test("should tokenize statements", () {
        List<Token> tokens = lex("a;b;");
        expectIdentifierToken(tokens[0], 0, "a");
        expectCharacterToken(tokens[1], 1, ";");
        expectIdentifierToken(tokens[2], 2, "b");
        expectCharacterToken(tokens[3], 3, ";");
      });
      test("should tokenize function invocation", () {
        List<Token> tokens = lex("a()");
        expectIdentifierToken(tokens[0], 0, "a");
        expectCharacterToken(tokens[1], 1, "(");
        expectCharacterToken(tokens[2], 2, ")");
      });
      test("should tokenize simple method invocations", () {
        List<Token> tokens = lex("a.method()");
        expectIdentifierToken(tokens[2], 2, "method");
      });
      test("should tokenize method invocation", () {
        List<Token> tokens = lex("a.b.c (d) - e.f()");
        expectIdentifierToken(tokens[0], 0, "a");
        expectCharacterToken(tokens[1], 1, ".");
        expectIdentifierToken(tokens[2], 2, "b");
        expectCharacterToken(tokens[3], 3, ".");
        expectIdentifierToken(tokens[4], 4, "c");
        expectCharacterToken(tokens[5], 6, "(");
        expectIdentifierToken(tokens[6], 7, "d");
        expectCharacterToken(tokens[7], 8, ")");
        expectOperatorToken(tokens[8], 10, "-");
        expectIdentifierToken(tokens[9], 12, "e");
        expectCharacterToken(tokens[10], 13, ".");
        expectIdentifierToken(tokens[11], 14, "f");
        expectCharacterToken(tokens[12], 15, "(");
        expectCharacterToken(tokens[13], 16, ")");
      });
      test("should tokenize number", () {
        List<Token> tokens = lex("0.5");
        expectNumberToken(tokens[0], 0, 0.5);
      });
      // NOTE(deboer): NOT A LEXER TEST

      //    test('should tokenize negative number', () => {

      //      var tokens:Token[] = lex("-0.5");

      //      expectNumberToken(tokens[0], 0, -0.5);

      //    });
      test("should tokenize number with exponent", () {
        List<Token> tokens = lex("0.5E-10");
        expect(tokens.length, 1);
        expectNumberToken(tokens[0], 0, 0.5E-10);
        tokens = lex("0.5E+10");
        expectNumberToken(tokens[0], 0, 0.5E+10);
      });
      test("should throws exception for invalid exponent", () {
        expect(() {
          lex("0.5E-");
        },
            throwsWith(
                "Lexer Error: Invalid exponent at column 4 in expression [0.5E-]"));
        expect(() {
          lex("0.5E-A");
        },
            throwsWith(
                "Lexer Error: Invalid exponent at column 4 in expression [0.5E-A]"));
      });
      test("should tokenize number starting with a dot", () {
        List<Token> tokens = lex(".5");
        expectNumberToken(tokens[0], 0, 0.5);
      });
      test("should throw error on invalid unicode", () {
        expect(() {
          lex("'\\u1''bla'");
        },
            throwsWith("Lexer Error: Invalid unicode escape [\\u1''b] at "
                "column 2 in expression ['\\u1''bla']"));
      });
      test("should tokenize hash as operator", () {
        List<Token> tokens = lex("#");
        expectOperatorToken(tokens[0], 0, "#");
      });
      test("should tokenize ?. as operator", () {
        List<Token> tokens = lex("?.");
        expectOperatorToken(tokens[0], 0, "?.");
      });
      test("should tokenize ?? as operator", () {
        List<Token> tokens = lex("??");
        expectOperatorToken(tokens[0], 0, "??");
      });
    });
  });
}
