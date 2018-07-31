@TestOn('vm')
import 'package:test/test.dart';
import 'package:_tests/test_util.dart';
import 'package:angular/src/compiler/expression_parser/lexer.dart'
    show Lexer, Token;

List<Token> lex(String text) {
  return Lexer().tokenize(text);
}

void expectToken(token, index) {
  expect(token is Token, true);
  expect(token.index, index);
}

void expectCharacterToken(token, index, character) {
  expect(character, hasLength(1));
  expectToken(token, index);
  expect(token.isCharacter(character.codeUnitAt(0)), true);
}

void expectOperatorToken(token, index, operator) {
  expectToken(token, index);
  expect(token.isOperator(operator), true);
}

void expectNumberToken(token, index, n) {
  expectToken(token, index);
  expect(token.isNumber, true);
  expect(token.toNumber(), n);
}

void expectStringToken(token, index, str) {
  expectToken(token, index);
  expect(token.isString, true);
  expect(token.toString(), str);
}

void expectIdentifierToken(Token token, int index, identifier) {
  expectToken(token, index);
  expect(token.isIdentifier, true);
  expect(token.toString(), identifier);
}

void expectKeywordToken(token, index, keyword) {
  expectToken(token, index);
  expect(token.isKeyword, true);
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
        expect(tokens[0].isKeywordUndefined, true);
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
      test('should tokenize unicode {} escapes', () {
        // U+22     "
        // U+9      TAB
        // U+1F389  PARTY POPPER
        final tokens = lex(r'"\u{22}\u{9}\u{1f389}"');
        expect(tokens, hasLength(1));
        expect(tokens[0].toString(), '"\t\u{1f389}');
      });
      test('should tokenize unicode interspersed in string', () {
        final tokens = lex(r'"cat \u{1f431} and dog \u{1f436} emojis!"');
        expect(tokens, hasLength(1));
        expect(tokens[0].toString(), 'cat \u{1f431} and dog \u{1f436} emojis!');
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
        expect(
            () => lex(r'"\u{110000}"'),
            throwsWith(r'Lexer Error: Invalid unicode escape [\u110000] at '
                r'column 2 in expression ["\u{110000}"]'));
      });
      test('should throw error on incomplete unicode escapes', () {
        expect(
            () => lex(r'"\u1"'),
            throwsWith('Lexer Error: Expected four hexadecimal digits at '
                r'column 3 in expression ["\u1"]'));
        expect(
            () => lex(r'"\u{1"'),
            throwsWith('Lexer Error: Incomplete escape sequence at column 2 in '
                r'expression ["\u{1"]'));
      });
      test('should throw error on unicode escape with too many digits', () {
        expect(
            () => lex(r"'\u{1234567}'"),
            throwsWith("Lexer Error: Expected '}' at column 10 in expression "
                r"['\u{1234567}']"));
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
