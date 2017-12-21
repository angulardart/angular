// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular_ast/src/simple_tokenizer.dart';
import 'package:angular_ast/src/token/tokens.dart';
import 'package:test/test.dart';

void main() {
  Iterable<NgSimpleToken> tokenize(String html) =>
      new NgSimpleTokenizer().tokenize(html);
  String untokenize(Iterable<NgSimpleToken> tokens) => tokens
      .fold(new StringBuffer(), (buffer, token) => buffer..write(token.lexeme))
      .toString();

  test('should tokenize plain text', () {
    expect(tokenize('Hello World'), [
      new NgSimpleToken.text(0, 'Hello World'),
      new NgSimpleToken.EOF(11),
    ]);
  });

  test('should tokenize multiline text', () {
    expect(tokenize('Hello\nWorld'), [
      new NgSimpleToken.text(0, 'Hello\nWorld'),
      new NgSimpleToken.EOF(11),
    ]);
  });

  test('should tokenize an HTML element', () {
    expect(tokenize('''<div></div>'''), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'div'),
      new NgSimpleToken.tagEnd(4),
      new NgSimpleToken.closeTagStart(5),
      new NgSimpleToken.identifier(7, 'div'),
      new NgSimpleToken.tagEnd(10),
      new NgSimpleToken.EOF(11),
    ]);
  });

  test('should tokenize an HTML element with dash', () {
    expect(tokenize('''<my-tag></my-tag>'''), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'my-tag'),
      new NgSimpleToken.tagEnd(7),
      new NgSimpleToken.closeTagStart(8),
      new NgSimpleToken.identifier(10, 'my-tag'),
      new NgSimpleToken.tagEnd(16),
      new NgSimpleToken.EOF(17),
    ]);
  });

  test('should tokenize an HTML element with local variable', () {
    expect(tokenize('''<div #myDiv></div>'''), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'div'),
      new NgSimpleToken.whitespace(4, ' '),
      new NgSimpleToken.hash(5),
      new NgSimpleToken.identifier(6, 'myDiv'),
      new NgSimpleToken.tagEnd(11),
      new NgSimpleToken.closeTagStart(12),
      new NgSimpleToken.identifier(14, 'div'),
      new NgSimpleToken.tagEnd(17),
      new NgSimpleToken.EOF(18),
    ]);
  });

  test('should tokenize an HTML element with void', () {
    expect(tokenize('<hr/>'), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'hr'),
      new NgSimpleToken.voidCloseTag(3),
      new NgSimpleToken.EOF(5),
    ]);
  });

  test('should tokenize nested HTML elements', () {
    expect(tokenize('<div><span></span></div>'), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'div'),
      new NgSimpleToken.tagEnd(4),
      new NgSimpleToken.openTagStart(5),
      new NgSimpleToken.identifier(6, 'span'),
      new NgSimpleToken.tagEnd(10),
      new NgSimpleToken.closeTagStart(11),
      new NgSimpleToken.identifier(13, 'span'),
      new NgSimpleToken.tagEnd(17),
      new NgSimpleToken.closeTagStart(18),
      new NgSimpleToken.identifier(20, 'div'),
      new NgSimpleToken.tagEnd(23),
      new NgSimpleToken.EOF(24),
    ]);
  });

  test('should tokenize HTML elements mixed with plain text', () {
    expect(tokenize('<div>Hello this is text</div>'), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'div'),
      new NgSimpleToken.tagEnd(4),
      new NgSimpleToken.text(5, 'Hello this is text'),
      new NgSimpleToken.closeTagStart(23),
      new NgSimpleToken.identifier(25, 'div'),
      new NgSimpleToken.tagEnd(28),
      new NgSimpleToken.EOF(29),
    ]);
  });

  test('should tokenize an HTML template and untokenize back', () {
    const html = r'''
      <div>
        <span>Hello World</span>
        <ul>
          <li>1</li>
          <li>2</li>
          <li>
            <strong>3</strong>
          </li>
        </ul>
      </div>
    ''';
    expect(untokenize(tokenize(html)), html);
  });

  test('should tokenize an element with a decorator with a value', () {
    expect(tokenize(r'<button title="Submit \"quoted text\""></button>'), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'button'),
      new NgSimpleToken.whitespace(7, ' '),
      new NgSimpleToken.identifier(8, 'title'),
      new NgSimpleToken.equalSign(13),
      new NgSimpleQuoteToken.doubleQuotedText(
          14, '"Submit \"quoted text\""', true),
      new NgSimpleToken.tagEnd(38),
      new NgSimpleToken.closeTagStart(39),
      new NgSimpleToken.identifier(41, 'button'),
      new NgSimpleToken.tagEnd(47),
      new NgSimpleToken.EOF(48),
    ]);
  });

  test('should tokenize an HTML element with bracket and period in decorator',
      () {
    expect(tokenize('''<my-tag [attr.x]="y"></my-tag>'''), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'my-tag'),
      new NgSimpleToken.whitespace(7, ' '),
      new NgSimpleToken.openBracket(8),
      new NgSimpleToken.identifier(9, 'attr'),
      new NgSimpleToken.period(13),
      new NgSimpleToken.identifier(14, 'x'),
      new NgSimpleToken.closeBracket(15),
      new NgSimpleToken.equalSign(16),
      new NgSimpleQuoteToken.doubleQuotedText(17, '"y"', true),
      new NgSimpleToken.tagEnd(20),
      new NgSimpleToken.closeTagStart(21),
      new NgSimpleToken.identifier(23, 'my-tag'),
      new NgSimpleToken.tagEnd(29),
      new NgSimpleToken.EOF(30),
    ]);
  });

  test(
      'should tokenize an HTML element with bracket, period, percentage, and backSlash',
      () {
    expect(tokenize(r'''<div [style.he\ight.%>'''), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'div'),
      new NgSimpleToken.whitespace(4, ' '),
      new NgSimpleToken.openBracket(5),
      new NgSimpleToken.identifier(6, 'style'),
      new NgSimpleToken.period(11),
      new NgSimpleToken.identifier(12, 'he'),
      new NgSimpleToken.backSlash(14),
      new NgSimpleToken.identifier(15, 'ight'),
      new NgSimpleToken.period(19),
      new NgSimpleToken.percent(20),
      new NgSimpleToken.tagEnd(21),
      new NgSimpleToken.EOF(22),
    ]);
  });

  test('should tokenize an HTML element with banana open and close', () {
    expect(tokenize('''<my-tag [(banana)]>'''), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'my-tag'),
      new NgSimpleToken.whitespace(7, ' '),
      new NgSimpleToken.openBanana(8),
      new NgSimpleToken.identifier(10, 'banana'),
      new NgSimpleToken.closeBanana(16),
      new NgSimpleToken.tagEnd(18),
      new NgSimpleToken.EOF(19),
    ]);
  });

  test('should tokenize a HTML template with decorator values and back', () {
    const html = r'''
      <div>
        <span hidden>Hello World</span>
        <a href="www.somelink.com/index.html">Click me!</a>
        <!-- some random comment inserted here -->
        <ul>
          <li>1</li>
          <li>
            <textarea disabled name="box" readonly>Test</textarea>
          </li>
          <li>
            <myTag myAttr="some value "literal""></myTag>
            <button disabled [attr.x]="y">3</button>
          </li>
        </ul>
      </div>
    ''';
    expect(untokenize(tokenize(html)), html);
  });

  test('should tokenize a comment', () {
    expect(tokenize('<!--Hello World-->'), [
      new NgSimpleToken.commentBegin(0),
      new NgSimpleToken.text(4, 'Hello World'),
      new NgSimpleToken.commentEnd(15),
      new NgSimpleToken.EOF(18),
    ]);
  });

  test('should tokenize copyright comments', () {
    expect(
      tokenize(''
          '<!--\n'
          '  Copyright (c) 2016, the Dart project authors.\n'
          '-->'),
      [
        new NgSimpleToken.commentBegin(0),
        new NgSimpleToken.text(
          4,
          '\n  Copyright (c) 2016, the Dart project authors.\n',
        ),
        new NgSimpleToken.commentEnd(53),
        new NgSimpleToken.EOF(56),
      ],
    );
  });

  test('should tokenize asterisks', () {
    expect(tokenize('<span *ngIf="some bool"></span>'), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'span'),
      new NgSimpleToken.whitespace(5, ' '),
      new NgSimpleToken.star(6),
      new NgSimpleToken.identifier(7, 'ngIf'),
      new NgSimpleToken.equalSign(11),
      new NgSimpleQuoteToken.doubleQuotedText(12, '"some bool"', true),
      new NgSimpleToken.tagEnd(23),
      new NgSimpleToken.closeTagStart(24),
      new NgSimpleToken.identifier(26, 'span'),
      new NgSimpleToken.tagEnd(30),
      new NgSimpleToken.EOF(31),
    ]);
  });

  test('should tokenize at signs', () {
    expect(tokenize('<div @deferred></div>'), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'div'),
      new NgSimpleToken.whitespace(4, ' '),
      new NgSimpleToken.atSign(5),
      new NgSimpleToken.identifier(6, 'deferred'),
      new NgSimpleToken.tagEnd(14),
      new NgSimpleToken.closeTagStart(15),
      new NgSimpleToken.identifier(17, 'div'),
      new NgSimpleToken.tagEnd(20),
      new NgSimpleToken.EOF(21),
    ]);
  });

  //Error cases

  test('should tokenize unclosed comments', () {
    expect(
        tokenize(''
            '<!--\n'
            '  Copyright (c) 2016, the Dart project authors.\n'),
        [
          new NgSimpleToken.commentBegin(0),
          new NgSimpleToken.text(
            4,
            '\n  Copyright (c) 2016, the Dart project authors.\n',
          ),
          new NgSimpleToken.EOF(53),
        ]);
  });

  test('should tokenize unclosed element tag hitting EOF', () {
    expect(tokenize('<div '), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'div'),
      new NgSimpleToken.whitespace(4, ' '),
      new NgSimpleToken.EOF(5),
    ]);
  });

  test('should tokenize unclosed element tags', () {
    expect(
        tokenize(''
            '<div>'
            ' some text stuff here '
            '<span'
            '</div>'),
        [
          new NgSimpleToken.openTagStart(0),
          new NgSimpleToken.identifier(1, 'div'),
          new NgSimpleToken.tagEnd(4),
          new NgSimpleToken.text(5, ' some text stuff here '),
          new NgSimpleToken.openTagStart(27),
          new NgSimpleToken.identifier(28, 'span'),
          new NgSimpleToken.closeTagStart(32),
          new NgSimpleToken.identifier(34, 'div'),
          new NgSimpleToken.tagEnd(37),
          new NgSimpleToken.EOF(38),
        ]);
  });

  test('should tokenize dangling double quote', () {
    expect(tokenize('''<div [someInput]=" (someEvent)='do something'>'''), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'div'),
      new NgSimpleToken.whitespace(4, ' '),
      new NgSimpleToken.openBracket(5),
      new NgSimpleToken.identifier(6, 'someInput'),
      new NgSimpleToken.closeBracket(15),
      new NgSimpleToken.equalSign(16),
      new NgSimpleQuoteToken.doubleQuotedText(
          17, '" (someEvent)=\'do something\'>', false),
      new NgSimpleToken.EOF(46),
    ]);
  });

  test('should tokenize dangling single quote', () {
    expect(tokenize('''<div [someInput]=' (someEvent)="do something">'''), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'div'),
      new NgSimpleToken.whitespace(4, ' '),
      new NgSimpleToken.openBracket(5),
      new NgSimpleToken.identifier(6, 'someInput'),
      new NgSimpleToken.closeBracket(15),
      new NgSimpleToken.equalSign(16),
      new NgSimpleQuoteToken.singleQuotedText(
          17, "' (someEvent)=\"do something\">", false),
      new NgSimpleToken.EOF(46),
    ]);
  });

  test('should tokenize unclosed attr hitting EOF', () {
    expect(tokenize('<div someAttr '), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'div'),
      new NgSimpleToken.whitespace(4, ' '),
      new NgSimpleToken.identifier(5, 'someAttr'),
      new NgSimpleToken.whitespace(13, ' '),
      new NgSimpleToken.EOF(14),
    ]);
  });

  test('should tokenize unclosed attr value hitting EOF', () {
    expect(tokenize('<div someAttr ='), [
      new NgSimpleToken.openTagStart(0),
      new NgSimpleToken.identifier(1, 'div'),
      new NgSimpleToken.whitespace(4, ' '),
      new NgSimpleToken.identifier(5, 'someAttr'),
      new NgSimpleToken.whitespace(13, ' '),
      new NgSimpleToken.equalSign(14),
      new NgSimpleToken.EOF(15),
    ]);
  });

  test('should tokenize text beginning with dangling close mustache', () {
    expect(tokenize('}} some text'), [
      new NgSimpleToken.mustacheEnd(0),
      new NgSimpleToken.text(2, ' some text'),
      new NgSimpleToken.EOF(12),
    ]);
  });

  test('should tokenize mustaches despite incorrect ordering', () {
    expect(tokenize('blah {{ blah {{ blah }} blah }} blah {{ blah }}'), [
      new NgSimpleToken.text(0, 'blah '),
      new NgSimpleToken.mustacheBegin(5),
      new NgSimpleToken.text(7, ' blah '),
      new NgSimpleToken.mustacheBegin(13),
      new NgSimpleToken.text(15, ' blah '),
      new NgSimpleToken.mustacheEnd(21),
      new NgSimpleToken.text(23, ' blah '),
      new NgSimpleToken.mustacheEnd(29),
      new NgSimpleToken.text(31, ' blah '),
      new NgSimpleToken.mustacheBegin(37),
      new NgSimpleToken.text(39, ' blah '),
      new NgSimpleToken.mustacheEnd(45),
      new NgSimpleToken.EOF(47),
    ]);
  });

  test('should tokenize only up to newline with dangling open mustache', () {
    expect(tokenize('{{ some mustache \n unclosed'), [
      new NgSimpleToken.mustacheBegin(0),
      new NgSimpleToken.text(2, ' some mustache '),
      new NgSimpleToken.whitespace(17, '\n'),
      new NgSimpleToken.text(18, ' unclosed'),
      new NgSimpleToken.EOF(27),
    ]);
  });

  test('should tokenize only up to newline with dangling open mustache2', () {
    expect(tokenize('{{\n  blah'), [
      new NgSimpleToken.mustacheBegin(0),
      new NgSimpleToken.whitespace(2, '\n'),
      new NgSimpleToken.text(3, '  blah'),
      new NgSimpleToken.EOF(9),
    ]);
  });

  test(
      'should tokenize "<" as expression within '
      'mustache if it begins with "{{"', () {
    expect(tokenize('{{ 5 < 3 }}'), [
      new NgSimpleToken.mustacheBegin(0),
      new NgSimpleToken.text(2, ' 5 < 3 '),
      new NgSimpleToken.mustacheEnd(9),
      new NgSimpleToken.EOF(11),
    ]);
  });

  test(
      'should tokenize "<" as tag start if '
      'before dangling mustache close', () {
    expect(tokenize(' 5 < 3 }}'), [
      new NgSimpleToken.text(0, ' 5 '),
      new NgSimpleToken.openTagStart(3),
      new NgSimpleToken.whitespace(4, ' '),
      new NgSimpleToken.unexpectedChar(5, '3'),
      new NgSimpleToken.whitespace(6, ' '),
      new NgSimpleToken.unexpectedChar(7, '}'),
      new NgSimpleToken.unexpectedChar(8, '}'),
      new NgSimpleToken.EOF(9),
    ]);
  });

  test('should tokenize simple doctype declaration', () {
    expect(tokenize('<!DOCTYPE html>'), [
      new NgSimpleToken.text(0, '<!DOCTYPE html>'),
      new NgSimpleToken.EOF(15),
    ]);
  });

  test('should tokenize complicated doctype declaration', () {
    var html = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"'
        ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';
    expect(tokenize(html), [
      new NgSimpleToken.text(0, html),
      new NgSimpleToken.EOF(109),
    ]);
  });

  test('should tokenize long html with doctype', () {
    const html = r'''
<!DOCTYPE html>
<div>
</div>''';
    expect(tokenize(html), [
      new NgSimpleToken.text(0, '<!DOCTYPE html>'),
      new NgSimpleToken.text(15, '\n'),
      new NgSimpleToken.openTagStart(16),
      new NgSimpleToken.identifier(17, 'div'),
      new NgSimpleToken.tagEnd(20),
      new NgSimpleToken.text(21, '\n'),
      new NgSimpleToken.closeTagStart(22),
      new NgSimpleToken.identifier(24, 'div'),
      new NgSimpleToken.tagEnd(27),
      new NgSimpleToken.EOF(28),
    ]);
  });

  test('should escape named entities', () {
    expect(tokenize('&lt;div&gt;'), [
      new NgSimpleToken.text(0, '<div>'),
      new NgSimpleToken.EOF(11),
    ]);
  });

  test('should escape dec values', () {
    expect(tokenize('&#8721;'), [
      new NgSimpleToken.text(0, '∑'),
      new NgSimpleToken.EOF(7),
    ]);
  });

  test('should escape hex values', () {
    expect(tokenize('&#x2211;'), [
      new NgSimpleToken.text(0, '∑'),
      new NgSimpleToken.EOF(8),
    ]);
  });
}
