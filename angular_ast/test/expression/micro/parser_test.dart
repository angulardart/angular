// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular_ast/angular_ast.dart';
import 'package:angular_ast/src/ast.dart';
import 'package:angular_ast/src/expression/micro/ast.dart';
import 'package:angular_ast/src/expression/micro/parser.dart';
import 'package:test/test.dart';

void main() {
  NgMicroAst parse(String directive, String expression, int offset) {
    return const NgMicroParser().parse(
      directive,
      expression,
      offset,
      sourceUrl: '/test/expression/micro/parser_test.dart#inline',
    );
  }

  test('should parse a simple let', () {
    expect(
      parse('ngThing', 'let foo', 0),
      NgMicroAst(
        letBindings: [
          LetBindingAst('foo'),
        ],
        properties: [],
      ),
    );
  });

  test('should parse a let assignment', () {
    expect(
      parse('ngThing', 'let foo = bar; let baz', 0),
      NgMicroAst(
        letBindings: [
          LetBindingAst('foo', 'bar'),
          LetBindingAst('baz'),
        ],
        properties: [],
      ),
    );
  });

  test('should parse a simple let and a let assignment', () {
    expect(
      parse('ngThing', 'let baz; let foo = bar', 0),
      NgMicroAst(
        letBindings: [
          LetBindingAst('baz'),
          LetBindingAst('foo', 'bar'),
        ],
        properties: [],
      ),
    );
  });

  test('should parse a simple let and a let assignment with extra spaces', () {
    expect(
      parse('ngThing', 'let baz; let foo = bar ', 0),
      NgMicroAst(
        letBindings: [
          LetBindingAst('baz'),
          LetBindingAst('foo', 'bar'),
        ],
        properties: [],
      ),
    );
  });

  test('should parse a let with a full Dart expression', () {
    expect(
      parse('ngFor', 'let x of items.where(filter)', 0),
      NgMicroAst(
        letBindings: [
          LetBindingAst('x'),
        ],
        properties: [
          PropertyAst(
            'ngForOf',
            'items.where(filter)',
          ),
        ],
      ),
    );
  });

  test('should parse a let/bind pair', () {
    expect(
      parse('ngFor', 'let item of items; trackBy: byId', 0),
      NgMicroAst(
        letBindings: [
          LetBindingAst('item'),
        ],
        properties: [
          PropertyAst(
            'ngForOf',
            'items',
          ),
          PropertyAst(
            'ngForTrackBy',
            'byId',
          ),
        ],
      ),
    );
  });

  test('should parse multiple binds', () {
    expect(
      parse('ngTemplateOutlet', 'templateRef; context: templateContext', 0),
      NgMicroAst(
        letBindings: [],
        properties: [
          PropertyAst(
            'ngTemplateOutlet',
            'templateRef',
          ),
          PropertyAst(
            'ngTemplateOutletContext',
            'templateContext',
          ),
        ],
      ),
    );
  });

  test('should throw a parser error on trailing semi-colon', () {
    expect(
      () => parse('ngFor', 'let item of items;', 0),
      throwsA(TypeMatcher<AngularParserException>()),
    );
  });
}
