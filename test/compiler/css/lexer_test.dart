library angular2.test.compiler.css.lexer_test;

import 'package:angular2/src/compiler/css/lexer.dart'
    show CssToken, CssScannerError, CssLexer, CssLexerMode, CssTokenType;
import 'package:angular2/src/facade/lang.dart' show isPresent;
import 'package:test/test.dart';

main() {
  List<CssToken> tokenize(code,
      [bool trackComments = false, CssLexerMode mode = CssLexerMode.ALL]) {
    var scanner = new CssLexer().scan(code, trackComments);
    scanner.setMode(mode);
    var tokens = [];
    var output = scanner.scan();
    while (output != null) {
      var error = output.error;
      if (isPresent(error)) {
        throw new CssScannerError(error.token, error.rawMessage);
      }
      tokens.add(output.token);
      output = scanner.scan();
    }
    return tokens;
  }
  group('CssLexer', () {
    test(
        'should lex newline characters as whitespace when '
        'whitespace mode is on', () {
      var newlines = ['\n', '\r\n', '\r', '\f'];
      newlines.forEach((line) {
        var token = tokenize(line, false, CssLexerMode.ALL_TRACK_WS)[0];
        expect(token.type, CssTokenType.Whitespace);
      });
    });
    test(
        'should combined newline characters as one newline token when '
        'whitespace mode is on', () {
      var newlines = ['\n', '\r\n', '\r', '\f'].join('');
      var tokens = tokenize(newlines, false, CssLexerMode.ALL_TRACK_WS);
      expect(tokens.length, 1);
      expect(tokens[0].type, CssTokenType.Whitespace);
    });
    test(
        'should not consider whitespace or newline values at all when '
        'whitespace mode is off', () {
      var newlines = ['\n', '\r\n', '\r', '\f'].join('');
      var tokens = tokenize(newlines);
      expect(tokens.length, 0);
    });
    test('should lex simple selectors and their inner properties', () {
      var cssCode = '\n' + '  .selector { my-prop: my-value; }\n';
      var tokens = tokenize(cssCode);
      expect(tokens[0].type, CssTokenType.Character);
      expect(tokens[0].strValue, '.');
      expect(tokens[1].type, CssTokenType.Identifier);
      expect(tokens[1].strValue, 'selector');
      expect(tokens[2].type, CssTokenType.Character);
      expect(tokens[2].strValue, '{');
      expect(tokens[3].type, CssTokenType.Identifier);
      expect(tokens[3].strValue, 'my-prop');
      expect(tokens[4].type, CssTokenType.Character);
      expect(tokens[4].strValue, ':');
      expect(tokens[5].type, CssTokenType.Identifier);
      expect(tokens[5].strValue, 'my-value');
      expect(tokens[6].type, CssTokenType.Character);
      expect(tokens[6].strValue, ';');
      expect(tokens[7].type, CssTokenType.Character);
      expect(tokens[7].strValue, '}');
    });
    test('should capture the column and line values for each token', () {
      var cssCode = '#id {\n  prop:value;\n}';
      var tokens = tokenize(cssCode);
      // #
      expect(tokens[0].type, CssTokenType.Character);
      expect(tokens[0].column, 0);
      expect(tokens[0].line, 0);
      // id
      expect(tokens[1].type, CssTokenType.Identifier);
      expect(tokens[1].column, 1);
      expect(tokens[1].line, 0);
      // {
      expect(tokens[2].type, CssTokenType.Character);
      expect(tokens[2].column, 4);
      expect(tokens[2].line, 0);
      // prop
      expect(tokens[3].type, CssTokenType.Identifier);
      expect(tokens[3].column, 2);
      expect(tokens[3].line, 1);
      // :
      expect(tokens[4].type, CssTokenType.Character);
      expect(tokens[4].column, 6);
      expect(tokens[4].line, 1);
      // value
      expect(tokens[5].type, CssTokenType.Identifier);
      expect(tokens[5].column, 7);
      expect(tokens[5].line, 1);
      // ;
      expect(tokens[6].type, CssTokenType.Character);
      expect(tokens[6].column, 12);
      expect(tokens[6].line, 1);
      // }
      expect(tokens[7].type, CssTokenType.Character);
      expect(tokens[7].column, 0);
      expect(tokens[7].line, 2);
    });
    test('should lex quoted strings and escape accordingly', () {
      var cssCode = 'prop: \'some { value } \\\' that is quoted\'';
      var tokens = tokenize(cssCode);
      expect(tokens[0].type, CssTokenType.Identifier);
      expect(tokens[1].type, CssTokenType.Character);
      expect(tokens[2].type, CssTokenType.String);
      expect(tokens[2].strValue, "'some { value } \\' that is quoted'");
    });
    test('should treat attribute operators as regular characters', () {
      tokenize('^|~+*').forEach((token) {
        expect(token.type, CssTokenType.Character);
      });
    });
    test('should lex numbers properly and set them as numbers', () {
      var cssCode = '0 1 -2 3.0 -4.001';
      var tokens = tokenize(cssCode);
      expect(tokens[0].type, CssTokenType.Number);
      expect(tokens[0].strValue, '0');
      expect(tokens[1].type, CssTokenType.Number);
      expect(tokens[1].strValue, '1');
      expect(tokens[2].type, CssTokenType.Number);
      expect(tokens[2].strValue, '-2');
      expect(tokens[3].type, CssTokenType.Number);
      expect(tokens[3].strValue, '3.0');
      expect(tokens[4].type, CssTokenType.Number);
      expect(tokens[4].strValue, '-4.001');
    });
    test('should lex @keywords', () {
      var cssCode = '@import()@something';
      var tokens = tokenize(cssCode);
      expect(tokens[0].type, CssTokenType.AtKeyword);
      expect(tokens[0].strValue, '@import');
      expect(tokens[1].type, CssTokenType.Character);
      expect(tokens[1].strValue, '(');
      expect(tokens[2].type, CssTokenType.Character);
      expect(tokens[2].strValue, ')');
      expect(tokens[3].type, CssTokenType.AtKeyword);
      expect(tokens[3].strValue, '@something');
    });
    test('should still lex a number even if it has a dimension suffix', () {
      var cssCode = '40% is 40 percent';
      var tokens = tokenize(cssCode);
      expect(tokens[0].type, CssTokenType.Number);
      expect(tokens[0].strValue, '40');
      expect(tokens[1].type, CssTokenType.Character);
      expect(tokens[1].strValue, '%');
      expect(tokens[2].type, CssTokenType.Identifier);
      expect(tokens[2].strValue, 'is');
      expect(tokens[3].type, CssTokenType.Number);
      expect(tokens[3].strValue, '40');
    });
    test(
        'should allow escaped character and unicode character-strings in '
        'CSS selectors', () {
      var cssCode = '\\123456 .some\\thing {}';
      var tokens = tokenize(cssCode);
      expect(tokens[0].type, CssTokenType.Identifier);
      expect(tokens[0].strValue, '\\123456');
      expect(tokens[1].type, CssTokenType.Character);
      expect(tokens[2].type, CssTokenType.Identifier);
      expect(tokens[2].strValue, 'some\\thing');
    });
    test('should distinguish identifiers and numbers from special characters',
        () {
      var cssCode = 'one*two=-4+three-4-equals_value\$';
      var tokens = tokenize(cssCode);
      expect(tokens[0].type, CssTokenType.Identifier);
      expect(tokens[0].strValue, 'one');
      expect(tokens[1].type, CssTokenType.Character);
      expect(tokens[1].strValue, '*');
      expect(tokens[2].type, CssTokenType.Identifier);
      expect(tokens[2].strValue, 'two');
      expect(tokens[3].type, CssTokenType.Character);
      expect(tokens[3].strValue, '=');
      expect(tokens[4].type, CssTokenType.Number);
      expect(tokens[4].strValue, '-4');
      expect(tokens[5].type, CssTokenType.Character);
      expect(tokens[5].strValue, '+');
      expect(tokens[6].type, CssTokenType.Identifier);
      expect(tokens[6].strValue, 'three-4-equals_value');
      expect(tokens[7].type, CssTokenType.Character);
      expect(tokens[7].strValue, '\$');
    });
    test('should filter out comments and whitespace by default', () {
      var cssCode = '.selector /* comment */ { /* value */ }';
      var tokens = tokenize(cssCode);
      expect(tokens[0].strValue, '.');
      expect(tokens[1].strValue, 'selector');
      expect(tokens[2].strValue, '{');
      expect(tokens[3].strValue, '}');
    });
    test('should track comments when the flag is set to true', () {
      var cssCode = '.selector /* comment */ { /* value */ }';
      var trackComments = true;
      var tokens = tokenize(cssCode, trackComments, CssLexerMode.ALL_TRACK_WS);
      expect(tokens[0].strValue, '.');
      expect(tokens[1].strValue, 'selector');
      expect(tokens[2].strValue, ' ');
      expect(tokens[3].type, CssTokenType.Comment);
      expect(tokens[3].strValue, '/* comment */');
      expect(tokens[4].strValue, ' ');
      expect(tokens[5].strValue, '{');
      expect(tokens[6].strValue, ' ');
      expect(tokens[7].type, CssTokenType.Comment);
      expect(tokens[7].strValue, '/* value */');
    });
    group('Selector Mode', () {
      test(
          'should throw an error if a selector is being parsed while in the '
          'wrong mode', () {
        var cssCode = '.class > tag';
        String capturedMessage;
        try {
          tokenize(cssCode, false, CssLexerMode.STYLE_BLOCK);
        } catch (e) {
          capturedMessage = e.rawMessage;
        }
        expect(
            new RegExp(
                    r'Unexpected character \[\>\] at column 0:7 in expression')
                .allMatches(capturedMessage),
            isNotEmpty);
        capturedMessage = null;
        try {
          tokenize(cssCode, false, CssLexerMode.SELECTOR);
        } catch (e) {
          capturedMessage = e.rawMessage;
        }
        expect(capturedMessage, null);
      });
    });
    group('Attribute Mode', () {
      test(
          'should consider attribute selectors as valid input and throw when '
          'an invalid modifier is used', () {
        tokenizeAttr(modifier) {
          var cssCode = 'value' + modifier + '=\'something\'';
          return tokenize(cssCode, false, CssLexerMode.ATTRIBUTE_SELECTOR);
        }
        expect(tokenizeAttr('*').length, 4);
        expect(tokenizeAttr('|').length, 4);
        expect(tokenizeAttr('^').length, 4);
        expect(tokenizeAttr('\$').length, 4);
        expect(tokenizeAttr('~').length, 4);
        expect(tokenizeAttr('').length, 3);
        expect(() {
          tokenizeAttr('+');
        }, throws);
      });
    });
    group('Media Query Mode', () {
      test(
          'should validate media queries with'
          ' a reduced subset of valid characters', () {
        tokenizeQuery(code) {
          return tokenize(code, false, CssLexerMode.MEDIA_QUERY);
        }
        // the reason why the numbers are so high is because MediaQueries keep

        // track of the whitespace values
        expect(tokenizeQuery('(prop: value)'), hasLength(5));
        expect(
            tokenizeQuery('(prop: value) and (prop2: value2)'), hasLength(11));
        expect(tokenizeQuery('tv and (prop: value)'), hasLength(7));
        expect(tokenizeQuery('print and ((prop: value) or (prop2: value2))'),
            hasLength(15));
        expect(tokenizeQuery('(content: \'something \$ crazy inside &\')'),
            hasLength(5));
        expect(() {
          tokenizeQuery('(max-height: 10 + 20)');
        }, throws);
        expect(() {
          tokenizeQuery('(max-height: fifty < 100)');
        }, throws);
      });
    });
    group('Pseudo Selector Mode', () {
      test(
          'should validate pseudo selector identifiers with a reduced subset '
          'of valid characters', () {
        tokenizePseudo(code) {
          return tokenize(code, false, CssLexerMode.PSEUDO_SELECTOR);
        }
        expect(tokenizePseudo('lang(en-us)').length, 4);
        expect(tokenizePseudo('hover').length, 1);
        expect(tokenizePseudo('focus').length, 1);
        expect(() {
          tokenizePseudo('lang(something:broken)');
        }, throws);
        expect(() {
          tokenizePseudo('not(.selector)');
        }, throws);
      });
    });
    group('Pseudo Selector Mode', () {
      test(
          'should validate pseudo selector identifiers with a reduced subset '
          'of valid characters', () {
        tokenizePseudo(code) {
          return tokenize(code, false, CssLexerMode.PSEUDO_SELECTOR);
        }
        expect(tokenizePseudo('lang(en-us)').length, 4);
        expect(tokenizePseudo('hover').length, 1);
        expect(tokenizePseudo('focus').length, 1);
        expect(() {
          tokenizePseudo('lang(something:broken)');
        }, throws);
        expect(() {
          tokenizePseudo('not(.selector)');
        }, throws);
      });
    });
    group('Style Block Mode', () {
      test('should style blocks with a reduced subset of valid characters', () {
        tokenizeStyles(code) {
          return tokenize(code, false, CssLexerMode.STYLE_BLOCK);
        }
        expect(tokenizeStyles('''
          key: value;
          prop: 100;
          style: value3!important;
        ''').length, 14);
        expect(() => tokenizeStyles(''' key\$: value; '''), throws);
        expect(() => tokenizeStyles(''' key: value\$; '''), throws);
        expect(() => tokenizeStyles(''' key: value + 10; '''), throws);
        expect(() => tokenizeStyles(''' key: &value; '''), throws);
      });
    });
  });
}
