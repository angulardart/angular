// @dart=2.9

import 'package:test/test.dart';
import 'package:_tests/test_util.dart';
import 'package:angular_compiler/v1/src/compiler/compile_metadata.dart'
    show CompileIdentifierMetadata;
import 'package:angular_compiler/v1/src/compiler/expression_parser/ast.dart'
    show ASTWithSource, Interpolation, PropertyRead;
import 'package:angular_compiler/v1/src/compiler/expression_parser/parser.dart'
    show ParseException, ExpressionParser;
import 'package:angular_compiler/v2/context.dart';

import 'unparser.dart' show Unparser;

Matcher throwsWithMatch(RegExp regExp) =>
    throwsA(predicate((e) => regExp.hasMatch(e.toString())));

final _throwsParseException = throwsA(TypeMatcher<ParseException>());

void main() {
  CompileContext.overrideForTesting();

  group('ExpressionParser', () {
    _runTests(() => ExpressionParser());
  });
}

void _runTests(ExpressionParser Function() createParser) {
  ASTWithSource parseAction(String text, [String location]) {
    return createParser().parseAction(text, location, []);
  }

  ASTWithSource parseBinding(String text, [String location]) {
    return createParser().parseBinding(text, location, []);
  }

  ASTWithSource parseInterpolation(String text, [String location]) {
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

  void expectInterpolationError(String text, Object matcher) {
    expect(() => parseInterpolation(text), matcher);
  }

  void expectActionError(String text, Object matcher) {
    expect(() => parseAction(text), matcher);
  }

  void expectBindingError(String text, Object matcher) {
    expect(() => parseBinding(text), matcher);
  }

  group('parser', () {
    group('parseAction', () {
      test('should parse numbers', () {
        checkAction('1');
      });
      test('should parse strings', () {
        checkAction("'1'", '\"1\"');
        checkAction('\"1\"');
      });
      test('should require escaping \$ in strings', () {
        expectActionError(r"'$100 USD'", _throwsParseException);
      });
      test('should not support string interpolations', () {
        expectActionError(r"'${foo()}'", _throwsParseException);
      });
      test('should parse null', () {
        checkAction('null');
      });
      test('should parse unary - expressions', () {
        // TODO(b/159912942): Just parse as -1.
        checkAction('-1', '0 - 1');
      });
      test('should fail to parse unary + expressions', () {
        expectActionError(
          '+1',
          _throwsParseException,
        );
      });
      test('should parse unary ! expressions', () {
        checkAction('!true');
        checkAction('!!true');
        checkAction('!!!true');
      });
      test('should parse multiplicative expressions', () {
        checkAction('3*4/2%5', '3 * 4 / 2 % 5');
      });
      test('should parse additive expressions', () {
        checkAction('3 + 6 - 2');
      });
      test('should parse relational expressions', () {
        checkAction('2 < 3');
        checkAction('2 > 3');
        checkAction('2 <= 2');
        checkAction('2 >= 2');
      });
      test('should parse equality expressions', () {
        checkAction('2 == 3');
        checkAction('2 != 3');
      });
      test('should parse expressions', () {
        checkAction('true && true');
        checkAction('true || false');
      });
      test('should parse grouped expressions by ignoring they are grouped', () {
        // TODO(b/159912942): Parse correctly.
        checkAction('(1 + 2) * 3', '1 + 2 * 3');
      });
      test('should fail on comments in expressions', () {
        expectActionError('a //comment', _throwsParseException);
      });
      test('should retain // in string literals', () {
        checkAction(
          '''"http://www.google.com"''',
          '''"http://www.google.com"''',
        );
      });
      test('should parse an empty string', () {
        // TODO(b/159912942): Decide whether to keep this.
        checkAction('');
      });
      group('member access', () {
        test('should parse field access', () {
          checkAction('a');
          checkAction('a.a');
        });
        test('should only allow identifier or keyword as member names', () {
          expectActionError('x.(', _throwsParseException);
          expectActionError('x. 1234', _throwsParseException);
          expectActionError('x.\"foo\"', _throwsParseException);
        });
        test('should parse safe field access', () {
          checkAction('a?.a');
          checkAction('a.a?.a');
        });
      });
      group('method calls', () {
        test('should parse method calls', () {
          checkAction('fn()');
          checkAction('add(1, 2)');
          checkAction('a.add(1, 2)');
          checkAction('fn().add(1, 2)');
          checkAction('fn(a: 1)');
        });
        test('should parse named argument that collides with an export', () {
          final parser = createParser();
          final text = 'fn(a: 1)';
          final export = CompileIdentifierMetadata(name: 'a');
          final ast = parser.parseAction(text, null, [export]);
          expect(unparse(ast), text);
        });
      });
      group('functional calls', () {
        test('should parse nested function calls', () {
          checkAction('fn()(1, 2)');
          checkAction('fn()(a: 1)');
        });
      });
      group('conditional', () {
        test('should parse ternary/conditional expressions', () {
          checkAction('7 == 3 + 4 ? 10 : 20');
          checkAction('false ? 10 : 20');
        });
        test('should throw on incorrect ternary operator syntax', () {
          expectActionError('true?1', _throwsParseException);
        });
      });
      group('ifNull', () {
        test('should parse if null expressions', () {
          checkAction('null ?? 0');
          checkAction('fn() ?? 0');
        });
        test('should throw on missing null case', () {
          expectActionError('null ??', _throwsParseException);
        });
      });
      group('assignment', () {
        test('should support field assignments', () {
          checkAction('a = 12');
          checkAction('a.a.a = 123');
        });
        test('should throw on safe field assignments', () {
          expectActionError('a?.a = 123', _throwsParseException);
        });
        test('should support array updates', () {
          checkAction('a[0] = 200');
        });
      });
      test('should error when using pipes', () {
        expectActionError(r'$pipe.blah(x)', _throwsParseException);
      });
      test('should store the source in the result', () {
        expect(parseAction('someExpr').source, 'someExpr');
      });
      test('should store the passed-in location', () {
        expect(parseAction('someExpr', 'location').location, 'location');
      });
      test('should throw when encountering interpolation', () {
        expectActionError(
            '{{a()}}',
            throwsWith(
                'Got interpolation ({{}}) where expression was expected'));
      });
      test('should not support multiple statements', () {
        expect(
          () => parseAction('1;2'),
          _throwsParseException,
        );
      });
    });
    group('general error handling', () {
      test('should throw on an unexpected token', () {
        expectActionError(
          'f(1,2) trac',
          _throwsParseException,
        );
      });
      test('should throw a reasonable error for unconsumed tokens', () {
        expectActionError(')', _throwsParseException);
      });
      test('should throw on missing expected token', () {
        expectActionError('a(b', _throwsParseException);
      });
      test('should not crash when encountering an invalid event', () {
        // Template validator should prevent from ever getting here, but just
        // in case lets avoid an NPE error that is impossible to debug.
        expectActionError(null, throwsWith('Blank expressions are not'));
      });
      test('should throw on a lexer error', () {
        expectActionError('a = 1E-', _throwsParseException);
      });
    });
    group('parseBinding', () {
      group('pipes', () {
        test('should parse pipes with the new function call syntax', () {
          final pipe = r'$pipe';
          checkBinding('a($pipe.c(b))', 'a($pipe.c(b))');
          checkBinding('$pipe.f(a.b(c.d(e)))', '$pipe.f(a.b(c.d(e)))');
          checkBinding('$pipe.c(a[b])', '$pipe.c(a[b])');
          checkBinding('$pipe.c(a?.b)', '$pipe.c(a?.b)');
          checkBinding('$pipe.a(true)', '$pipe.a(true)');
          checkBinding('$pipe.d($pipe.b(a, c))', '$pipe.d($pipe.b(a, c))');
          checkBinding('$pipe.b(a, $pipe.d(c))', '$pipe.b(a, $pipe.d(c))');
        });

        test('should refuse prefixes that are not single identifiers', () {
          expectBindingError('a + b:c', _throwsParseException);
          expectBindingError('1:c', _throwsParseException);
        });
      });
      test('should store the source in the result', () {
        expect(parseBinding('someExpr').source, 'someExpr');
      });
      test('should store the passed-in location', () {
        expect(parseBinding('someExpr', 'location').location, 'location');
      });
      test('should throw on multiple statements', () {
        expect(
          () => parseBinding('1;2'),
          _throwsParseException,
        );
      });
      test('should throw on assignment', () {
        expect(() => parseBinding('a=2'), _throwsParseException);
      });
      test('should throw when encountering interpolation', () {
        expectBindingError(
            '{{a.b}}',
            throwsWith(
                'Got interpolation ({{}}) where expression was expected'));
      });
      test('should parse conditional expression', () {
        checkBinding('a < b ? a : b');
      });
      test('should fail on comments in bindings', () {
        expectBindingError('a //comment', _throwsParseException);
      });
      test('should retain // in string literals', () {
        checkBinding(
            '''"http://www.google.com"''', '''"http://www.google.com"''');
      });
    });
    group('parseInterpolation', () {
      test('should return null if no interpolation', () {
        expect(parseInterpolation('nothing'), isNull);
      });
      test('should parse no prefix/suffix interpolation', () {
        var ast = parseInterpolation('{{a}}').ast as Interpolation;
        expect(ast.strings, ['', '']);
        expect(ast.expressions.length, 1);
        expect((ast.expressions[0] as PropertyRead).name, 'a');
      });
      test('should parse prefix/suffix with multiple interpolation', () {
        var originalExp = 'before {{ a }} middle {{ b }} after';
        var ast = parseInterpolation(originalExp);
        expect(Unparser().unparse(ast), originalExp);
      });
      test('should throw on empty interpolation expressions', () {
        expect(
            () => parseInterpolation('{{}}'),
            throwsWith(
                'Parser Error: Blank expressions are not allowed in interpolated strings'));
        expect(
            () => parseInterpolation('foo {{  }}'),
            throwsWith(
                'Parser Error: Blank expressions are not allowed in interpolated strings'));
      });
      test('should parse conditional expression', () {
        checkInterpolation('{{ a < b ? a : b }}');
      });
      test('should parse expression with newline characters', () {
        checkInterpolation('''{{ \'foo\' +
 \'bar\' +
 \'baz\' }}''', '''{{ "foo" + "bar" + "baz" }}''');
      });
      group('non-comment slashes should parse in', () {
        test('single quote strings', () {
          checkInterpolation(
            "{{ \'http://www.google.com\' }}",
            '{{ \"http://www.google.com\" }}',
          );
        });
        test('double quote strings', () {
          checkInterpolation(
            '{{ "http://www.google.com" }}',
            '{{ "http://www.google.com" }}',
          );
        });
      });

      group('comments should fail in', () {
        test('interpolation expressions', () {
          expectInterpolationError(
            '{{a //comment}}',
            _throwsParseException,
          );
        });

        test('after string literals', () {
          expectInterpolationError(
            '{{ "a//b" //comment }}',
            _throwsParseException,
          );
        });
        test('complex strings', () {
          expectInterpolationError(
            '''{{"//a\'//b`//c`//d\'//e" //comment}}''',
            _throwsParseException,
          );
        });
        test('nested, unterminated strings', () {
          expectInterpolationError(
            '''{{ "a\'b`" //comment}}''',
            _throwsParseException,
          );
        });
      });
    });
  });
}
