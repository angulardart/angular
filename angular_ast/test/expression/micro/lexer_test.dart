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
      .fold(new StringBuffer(), (buffer, token) => buffer..write(token.lexeme))
      .toString();

  test('should tokenize a single let', () {
    expect(
      tokenize('let foo'),
      [
        new NgMicroToken.letKeyword(0, 'let'),
        new NgMicroToken.letKeywordAfter(3, ' '),
        new NgMicroToken.letIdentifier(4, 'foo'),
      ],
    );
  });

  test('should tokenize multiple lets', () {
    expect(
      tokenize('let foo; let bar;let baz'),
      [
        new NgMicroToken.letKeyword(0, 'let'),
        new NgMicroToken.letKeywordAfter(3, ' '),
        new NgMicroToken.letIdentifier(4, 'foo'),
        new NgMicroToken.endExpression(7, '; '),
        new NgMicroToken.letKeyword(9, 'let'),
        new NgMicroToken.letKeywordAfter(12, ' '),
        new NgMicroToken.letIdentifier(13, 'bar'),
        new NgMicroToken.endExpression(16, ';'),
        new NgMicroToken.letKeyword(17, 'let'),
        new NgMicroToken.letKeywordAfter(20, ' '),
        new NgMicroToken.letIdentifier(21, 'baz'),
      ],
    );
  });

  test('should tokenize a let assignment', () {
    expect(
      tokenize('let foo = bar'),
      [
        new NgMicroToken.letKeyword(0, 'let'),
        new NgMicroToken.letKeywordAfter(3, ' '),
        new NgMicroToken.letIdentifier(4, 'foo'),
        new NgMicroToken.letAssignmentBefore(7, ' = '),
        new NgMicroToken.letAssignment(10, 'bar'),
      ],
    );
  });

  test('should tokenize multiple let assignments', () {
    expect(
      tokenize('let aaa = bbb; let ccc = ddd'),
      [
        new NgMicroToken.letKeyword(0, 'let'),
        new NgMicroToken.letKeywordAfter(3, ' '),
        new NgMicroToken.letIdentifier(4, 'aaa'),
        new NgMicroToken.letAssignmentBefore(7, ' = '),
        new NgMicroToken.letAssignment(10, 'bbb'),
        new NgMicroToken.endExpression(13, '; '),
        new NgMicroToken.letKeyword(15, 'let'),
        new NgMicroToken.letKeywordAfter(18, ' '),
        new NgMicroToken.letIdentifier(19, 'ccc'),
        new NgMicroToken.letAssignmentBefore(22, ' = '),
        new NgMicroToken.letAssignment(25, 'ddd'),
      ],
    );
  });

  test('should tokenize a let with an implicit bind', () {
    expect(
      tokenize('let item of items'),
      [
        new NgMicroToken.letKeyword(0, 'let'),
        new NgMicroToken.letKeywordAfter(3, ' '),
        new NgMicroToken.letIdentifier(4, 'item'),
        new NgMicroToken.endExpression(8, ' '),
        new NgMicroToken.bindIdentifier(9, 'of'),
        new NgMicroToken.bindExpressionBefore(11, ' '),
        new NgMicroToken.bindExpression(12, 'items'),
      ],
    );
  });

  test('should tokenize a let with multiple implicit binds', () {
    expect(
      tokenize('let item of items; trackBy: byID'),
      [
        new NgMicroToken.letKeyword(0, 'let'),
        new NgMicroToken.letKeywordAfter(3, ' '),
        new NgMicroToken.letIdentifier(4, 'item'),
        new NgMicroToken.endExpression(8, ' '),
        new NgMicroToken.bindIdentifier(9, 'of'),
        new NgMicroToken.bindExpressionBefore(11, ' '),
        new NgMicroToken.bindExpression(12, 'items'),
        new NgMicroToken.endExpression(17, ' '),
        new NgMicroToken.bindIdentifier(19, 'trackBy'),
        new NgMicroToken.bindExpressionBefore(26, ': '),
        new NgMicroToken.bindExpression(28, 'byID'),
      ],
    );
  });

  test('should tokenize a complex micro expression', () {
    var expression = 'let item of items; trackBy: byId; let i = index';
    expect(untokenize(tokenize(expression)), expression);
  });

  test('should tokenize multiple bindings', () {
    expect(tokenize('templateRef; context: templateContext'), [
      new NgMicroToken.bindExpression(0, 'templateRef'),
      new NgMicroToken.endExpression(11, '; '),
      new NgMicroToken.bindIdentifier(13, 'context'),
      new NgMicroToken.bindExpressionBefore(20, ': '),
      new NgMicroToken.bindExpression(22, 'templateContext'),
    ]);
  });
}
