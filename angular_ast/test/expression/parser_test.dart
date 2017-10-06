// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular_ast/src/expression/parser.dart';
import 'package:angular_ast/src/expression/visitor.dart';
import 'package:test/test.dart';

/// Usage of .toSource() directly on expression is not allowed when utilizing
/// AngularBased parsing to generate expression that can include
/// PipeExpressions. As a result, use [NgToSourceVisitor].
/// Problems occur in the recursive step when visitor recurses from a
/// pure Dart expression into a Pipe Expression.
String generateStringFromExpression(String expressionText) {
  final expression = parseExpression(expressionText,
      sourceUrl: '/test/expression/parser_test.dart#inline');
  final sourceVisitor = new NgToSourceVisitor();
  expression.accept(sourceVisitor);
  return sourceVisitor.toString();
}

void main() {
  test('should parse non-pipe expressions', () {
    const [
      'foo',
      'foo + bar',
      'foo(bar)',
      'foo ? bar : baz',
      'foo?.bar?.baz',
      'foo & bar',
      'foo ?? bar',
      'foo ??= bar',
      'foo == bar',
      'foo || bar',
    ].forEach((expression) {
      expect(
        parseExpression(
          expression,
          sourceUrl: '/test/expression/parser_test.dart#inline',
        )
            .toSource(),
        expression,
      );
    });
  });

  test('should parse a simple pipe', () {
    expect(generateStringFromExpression(r'foo | bar'), r'foo | bar');
  });

  test('should parse multiple occurring pipes', () {
    expect(
        generateStringFromExpression(r'foo | bar | baz'), r'foo | bar | baz');
  });

  test('should parse pipes used as part of a larger expression', () {
    expect(
        generateStringFromExpression(
            r'(getThing(foo) | bar) + (getThing(baz) | bar)'),
        r'(getThing(foo) | bar) + (getThing(baz) | bar)');
  });

  test('should parse pipes with arguments', () {
    expect(generateStringFromExpression(r'foo | bar:baz'), r'foo | bar:baz');
  });

  test('should parse pipes with multiple arguments', () {
    expect(generateStringFromExpression(r"foo | date:'YY/MM/DD':false"),
        r"foo | date:'YY/MM/DD':false");
  });

  test('should parse complex nested pipes', () {
    final expressionText =
        r"foo | pipe1:(bar | pipe2:10:true | pipe3):true | pipe4:true";
    expect(generateStringFromExpression(expressionText), expressionText);
  });
}
