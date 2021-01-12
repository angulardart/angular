// @dart=2.9

import 'package:test/test.dart';
import 'package:angular_compiler/v1/src/compiler/expression_parser/analyzer_parser.dart';
import 'package:angular_compiler/v1/src/compiler/expression_parser/ast.dart'
    as ast;
import 'package:angular_compiler/v1/src/compiler/expression_parser/parser.dart';

import 'unparser.dart';

const _isParseException = TypeMatcher<ParseException>();
const _throwsParseException = Throws(_isParseException);

void main() {
  final parser = AnalyzerExpressionParser();
  final unparser = Unparser();

  String parse(String input, {bool allowAssignments}) {
    final wrapped = ast.ASTWithSource(
      parser.parseExpression(
        input,
        'analyzer_test.dart',
        allowAssignments: allowAssignments,
      ),
      input,
      'analyzer_test.dart',
    );
    return unparser.unparse(wrapped);
  }

  group('should parse literal', () {
    test('string', () {
      expect(parse('"Hello World"'), '"Hello World"');
    });

    test('number', () {
      expect(parse('5'), '5');
    });

    test('boolean', () {
      expect(parse('true'), 'true');
      expect(parse('false'), 'false');
    });

    test('null', () {
      expect(parse('null'), 'null');
    });
  });

  group('should prevent literal', () {
    test('set', () {
      expect(
        () => parser.parseExpression('{1}', 'analyzer_test.dart'),
        _throwsParseException,
      );
    });

    test('map', () {
      expect(
        () => parser.parseExpression('{1: 2}', 'analyzer_test.dart'),
        _throwsParseException,
      );
    });

    test('list', () {
      expect(
        () => parser.parseExpression('[1]', 'analyzer_test.dart'),
        _throwsParseException,
      );
    });

    test('adjacent strings', () {
      expect(
        () => parser.parseExpression('"foo" "bar"', 'analyzer_test.dart'),
        _throwsParseException,
      );
    });
  });

  group('should parse identifiers', () {
    test('simple', () {
      expect(parse('foo'), 'foo');
    });

    test('prefixed', () {
      expect(parse('foo.bar'), 'foo.bar');
    });

    test('property access [chained]', () {
      expect(parse('foo.bar.baz'), 'foo.bar.baz');
    });
  });

  test('should validate sub-expressions', () {
    expect(
      () => parser.parseExpression('(foo | bar).baz', 'analyzer_test.dart'),
      _throwsParseException,
      reason: 'We do not support "|", so this should throw.',
    );
  });

  test('should disallow cascaded properties', () {
    expect(
      () => parser.parseExpression('foo..bar', 'analyzer_test.dart'),
      _throwsParseException,
    );
  });

  group('should parse function calls', () {
    test('method', () {
      expect(parse('foo()'), 'foo()');
      expect(parse('foo(a)'), 'foo(a)');
      expect(parse('foo(a, b)'), 'foo(a, b)');
    });

    test('method [named args]', () {
      expect(parse('foo(a: 1)'), 'foo(a: 1)');
      expect(parse('foo(a: 1, b: 2)'), 'foo(a: 1, b: 2)');
    });

    test('method [chained]', () {
      expect(parse('foo.bar()'), 'foo.bar()');
      expect(parse('foo.bar.baz()'), 'foo.bar.baz()');
    });

    test('method [chained invocation] is allowed', () {
      expect(parse('foo.bar()()'), 'foo.bar()()');
    });
  });

  test('should reject generic type arguments', () {
    expect(
      () => parser.parseExpression('foo<String>()', 'analyzer_test.dart'),
      _throwsParseException,
    );
  });

  test('should parse conditionals', () {
    expect(parse('a ? b : c'), 'a ? b : c');
  });

  test('should parse addition', () {
    expect(parse('a + b'), 'a + b');
  });

  test('should parse subtraction', () {
    expect(parse('a - b'), 'a - b');
  });

  test('should parse multplication', () {
    expect(parse('a * b'), 'a * b');
  });

  test('should parse division', () {
    expect(parse('a / b'), 'a / b');
  });

  test('should parse equality', () {
    expect(parse('a == b'), 'a == b');
  });

  test('should parse and', () {
    expect(parse('a && b'), 'a && b');
  });

  test('should parse or', () {
    expect(parse('a || b'), 'a || b');
  });

  test('should support if-null', () {
    expect(parse('a ?? b'), 'a ?? b');
  });

  test('should support conditional property access', () {
    expect(parse('a?.b'), 'a?.b');
  });

  test('should parse bracket access [read]', () {
    expect(parse('a[b]'), 'a[b]');
  });

  test('should parse boolean negation', () {
    expect(parse('!a'), '!a');
  });

  test('should parse non-null assertion', () {
    expect(parse('a!'), 'a!');
  });

  group('[assignments]', () {
    test('should refuse normally', () {
      expect(
        () => parser.parseExpression('x = y', 'analyzer_test.dart'),
        _throwsParseException,
      );
    });

    test('should allow root assignments (conditionally)', () {
      expect(parse('x = y', allowAssignments: true), 'x = y');
    });

    test('should allow non-root assignments', () {
      expect(
        parse(
          'z(x = y)',
          allowAssignments: true,
        ),
        'z(x = y)',
      );
    });
  });
}
