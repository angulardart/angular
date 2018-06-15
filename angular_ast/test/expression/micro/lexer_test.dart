// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular_ast/src/expression/micro/lexer.dart';
import 'package:angular_ast/src/expression/micro/token.dart';
import 'package:test/test.dart';

void main() {
  // Returns the html parsed as a series of tokens.
  Iterable<NgMicroToken> tokenize(String html) {
    return const NgMicroLexer().tokenize(html);
  }

  // Returns the html parsed as a series of tokens, then back to html.
  String untokenize(Iterable<NgMicroToken> tokens) => tokens
      .fold(StringBuffer(), (buffer, token) => buffer..write(token.lexeme))
      .toString();

  test('should tokenize a single let', () {
    expect(
      tokenize('let foo'),
      [
        NgMicroToken.letKeyword(0, 'let'),
        NgMicroToken.letKeywordAfter(3, ' '),
        NgMicroToken.letIdentifier(4, 'foo'),
      ],
    );
  });

  test('should tokenize multiple lets', () {
    expect(
      tokenize('let foo; let bar;let baz'),
      [
        NgMicroToken.letKeyword(0, 'let'),
        NgMicroToken.letKeywordAfter(3, ' '),
        NgMicroToken.letIdentifier(4, 'foo'),
        NgMicroToken.endExpression(7, '; '),
        NgMicroToken.letKeyword(9, 'let'),
        NgMicroToken.letKeywordAfter(12, ' '),
        NgMicroToken.letIdentifier(13, 'bar'),
        NgMicroToken.endExpression(16, ';'),
        NgMicroToken.letKeyword(17, 'let'),
        NgMicroToken.letKeywordAfter(20, ' '),
        NgMicroToken.letIdentifier(21, 'baz'),
      ],
    );
  });

  test('should tokenize a let assignment', () {
    expect(
      tokenize('let foo = bar'),
      [
        NgMicroToken.letKeyword(0, 'let'),
        NgMicroToken.letKeywordAfter(3, ' '),
        NgMicroToken.letIdentifier(4, 'foo'),
        NgMicroToken.letAssignmentBefore(7, ' = '),
        NgMicroToken.letAssignment(10, 'bar'),
      ],
    );
  });

  test('should tokenize multiple let assignments', () {
    expect(
      tokenize('let aaa = bbb; let ccc = ddd'),
      [
        NgMicroToken.letKeyword(0, 'let'),
        NgMicroToken.letKeywordAfter(3, ' '),
        NgMicroToken.letIdentifier(4, 'aaa'),
        NgMicroToken.letAssignmentBefore(7, ' = '),
        NgMicroToken.letAssignment(10, 'bbb'),
        NgMicroToken.endExpression(13, '; '),
        NgMicroToken.letKeyword(15, 'let'),
        NgMicroToken.letKeywordAfter(18, ' '),
        NgMicroToken.letIdentifier(19, 'ccc'),
        NgMicroToken.letAssignmentBefore(22, ' = '),
        NgMicroToken.letAssignment(25, 'ddd'),
      ],
    );
  });

  test('should tokenize a let with an implicit bind', () {
    expect(
      tokenize('let item of items'),
      [
        NgMicroToken.letKeyword(0, 'let'),
        NgMicroToken.letKeywordAfter(3, ' '),
        NgMicroToken.letIdentifier(4, 'item'),
        NgMicroToken.endExpression(8, ' '),
        NgMicroToken.bindIdentifier(9, 'of'),
        NgMicroToken.bindExpressionBefore(11, ' '),
        NgMicroToken.bindExpression(12, 'items'),
      ],
    );
  });

  test('should tokenize a let with multiple implicit binds', () {
    expect(
      tokenize('let item of items; trackBy: byID'),
      [
        NgMicroToken.letKeyword(0, 'let'),
        NgMicroToken.letKeywordAfter(3, ' '),
        NgMicroToken.letIdentifier(4, 'item'),
        NgMicroToken.endExpression(8, ' '),
        NgMicroToken.bindIdentifier(9, 'of'),
        NgMicroToken.bindExpressionBefore(11, ' '),
        NgMicroToken.bindExpression(12, 'items'),
        NgMicroToken.endExpression(17, ' '),
        NgMicroToken.bindIdentifier(19, 'trackBy'),
        NgMicroToken.bindExpressionBefore(26, ': '),
        NgMicroToken.bindExpression(28, 'byID'),
      ],
    );
  });

  test('should tokenize a complex micro expression', () {
    var expression = 'let item of items; trackBy: byId; let i = index';
    expect(untokenize(tokenize(expression)), expression);
  });

  test('should tokenize multiple bindings', () {
    expect(tokenize('templateRef; context: templateContext'), [
      NgMicroToken.bindExpression(0, 'templateRef'),
      NgMicroToken.endExpression(11, '; '),
      NgMicroToken.bindIdentifier(13, 'context'),
      NgMicroToken.bindExpressionBefore(20, ': '),
      NgMicroToken.bindExpression(22, 'templateContext'),
    ]);
  });

  test('should handle newline after identifier', () {
    expect(tokenize('let item of\n items'), [
      NgMicroToken.letKeyword(0, 'let'),
      NgMicroToken.letKeywordAfter(3, ' '),
      NgMicroToken.letIdentifier(4, 'item'),
      NgMicroToken.endExpression(8, ' '),
      NgMicroToken.bindIdentifier(9, 'of'),
      NgMicroToken.bindExpressionBefore(11, '\n '),
      NgMicroToken.bindExpression(13, 'items'),
    ]);
  });
}
