// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular_ast/src/simple_tokenizer.dart';
import 'package:angular_ast/src/token/tokens.dart';
import 'package:test/test.dart';

void main() {
  Iterable<NgSimpleToken> tokenize(String html) =>
      const NgSimpleTokenizer().tokenize(html);
  String untokenize(Iterable<NgSimpleToken> tokens) => tokens
      .fold(StringBuffer(), (buffer, token) => buffer..write(token.lexeme))
      .toString();

  test('should tokenize plain text', () {
    expect(tokenize('Hello World'), [
      NgSimpleToken.text(0, 'Hello World'),
      NgSimpleToken.EOF(11),
    ]);
  });

  test('should tokenize multiline text', () {
    expect(tokenize('Hello\nWorld'), [
      NgSimpleToken.text(0, 'Hello\nWorld'),
      NgSimpleToken.EOF(11),
    ]);
  });

  test('should tokenize an HTML element', () {
    expect(tokenize('''<div></div>'''), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'div'),
      NgSimpleToken.tagEnd(4),
      NgSimpleToken.closeTagStart(5),
      NgSimpleToken.identifier(7, 'div'),
      NgSimpleToken.tagEnd(10),
      NgSimpleToken.EOF(11),
    ]);
  });

  test('should tokenize an HTML element with dash', () {
    expect(tokenize('''<my-tag></my-tag>'''), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'my-tag'),
      NgSimpleToken.tagEnd(7),
      NgSimpleToken.closeTagStart(8),
      NgSimpleToken.identifier(10, 'my-tag'),
      NgSimpleToken.tagEnd(16),
      NgSimpleToken.EOF(17),
    ]);
  });

  test('should tokenize an HTML element with local variable', () {
    expect(tokenize('''<div #myDiv></div>'''), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'div'),
      NgSimpleToken.whitespace(4, ' '),
      NgSimpleToken.hash(5),
      NgSimpleToken.identifier(6, 'myDiv'),
      NgSimpleToken.tagEnd(11),
      NgSimpleToken.closeTagStart(12),
      NgSimpleToken.identifier(14, 'div'),
      NgSimpleToken.tagEnd(17),
      NgSimpleToken.EOF(18),
    ]);
  });

  test('should tokenize an HTML element with void', () {
    expect(tokenize('<hr/>'), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'hr'),
      NgSimpleToken.voidCloseTag(3),
      NgSimpleToken.EOF(5),
    ]);
  });

  test('should tokenize nested HTML elements', () {
    expect(tokenize('<div><span></span></div>'), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'div'),
      NgSimpleToken.tagEnd(4),
      NgSimpleToken.openTagStart(5),
      NgSimpleToken.identifier(6, 'span'),
      NgSimpleToken.tagEnd(10),
      NgSimpleToken.closeTagStart(11),
      NgSimpleToken.identifier(13, 'span'),
      NgSimpleToken.tagEnd(17),
      NgSimpleToken.closeTagStart(18),
      NgSimpleToken.identifier(20, 'div'),
      NgSimpleToken.tagEnd(23),
      NgSimpleToken.EOF(24),
    ]);
  });

  test('should tokenize HTML elements mixed with plain text', () {
    expect(tokenize('<div>Hello this is text</div>'), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'div'),
      NgSimpleToken.tagEnd(4),
      NgSimpleToken.text(5, 'Hello this is text'),
      NgSimpleToken.closeTagStart(23),
      NgSimpleToken.identifier(25, 'div'),
      NgSimpleToken.tagEnd(28),
      NgSimpleToken.EOF(29),
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
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'button'),
      NgSimpleToken.whitespace(7, ' '),
      NgSimpleToken.identifier(8, 'title'),
      NgSimpleToken.equalSign(13),
      NgSimpleQuoteToken.doubleQuotedText(14, '"Submit \"quoted text\""', true),
      NgSimpleToken.tagEnd(38),
      NgSimpleToken.closeTagStart(39),
      NgSimpleToken.identifier(41, 'button'),
      NgSimpleToken.tagEnd(47),
      NgSimpleToken.EOF(48),
    ]);
  });

  test('should tokenize an HTML element with bracket and period in decorator',
      () {
    expect(tokenize('''<my-tag [attr.x]="y"></my-tag>'''), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'my-tag'),
      NgSimpleToken.whitespace(7, ' '),
      NgSimpleToken.openBracket(8),
      NgSimpleToken.identifier(9, 'attr'),
      NgSimpleToken.period(13),
      NgSimpleToken.identifier(14, 'x'),
      NgSimpleToken.closeBracket(15),
      NgSimpleToken.equalSign(16),
      NgSimpleQuoteToken.doubleQuotedText(17, '"y"', true),
      NgSimpleToken.tagEnd(20),
      NgSimpleToken.closeTagStart(21),
      NgSimpleToken.identifier(23, 'my-tag'),
      NgSimpleToken.tagEnd(29),
      NgSimpleToken.EOF(30),
    ]);
  });

  test(
      'should tokenize an HTML element with bracket, period, percentage, and backSlash',
      () {
    expect(tokenize(r'''<div [style.he\ight.%>'''), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'div'),
      NgSimpleToken.whitespace(4, ' '),
      NgSimpleToken.openBracket(5),
      NgSimpleToken.identifier(6, 'style'),
      NgSimpleToken.period(11),
      NgSimpleToken.identifier(12, 'he'),
      NgSimpleToken.backSlash(14),
      NgSimpleToken.identifier(15, 'ight'),
      NgSimpleToken.period(19),
      NgSimpleToken.percent(20),
      NgSimpleToken.tagEnd(21),
      NgSimpleToken.EOF(22),
    ]);
  });

  test('should tokenize an HTML element with banana open and close', () {
    expect(tokenize('''<my-tag [(banana)]>'''), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'my-tag'),
      NgSimpleToken.whitespace(7, ' '),
      NgSimpleToken.openBanana(8),
      NgSimpleToken.identifier(10, 'banana'),
      NgSimpleToken.closeBanana(16),
      NgSimpleToken.tagEnd(18),
      NgSimpleToken.EOF(19),
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
      NgSimpleToken.commentBegin(0),
      NgSimpleToken.text(4, 'Hello World'),
      NgSimpleToken.commentEnd(15),
      NgSimpleToken.EOF(18),
    ]);
  });

  test('should tokenize copyright comments', () {
    expect(
      tokenize(''
          '<!--\n'
          '  Copyright (c) 2016, the Dart project authors.\n'
          '-->'),
      [
        NgSimpleToken.commentBegin(0),
        NgSimpleToken.text(
          4,
          '\n  Copyright (c) 2016, the Dart project authors.\n',
        ),
        NgSimpleToken.commentEnd(53),
        NgSimpleToken.EOF(56),
      ],
    );
  });

  test('should tokenize asterisks', () {
    expect(tokenize('<span *ngIf="some bool"></span>'), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'span'),
      NgSimpleToken.whitespace(5, ' '),
      NgSimpleToken.star(6),
      NgSimpleToken.identifier(7, 'ngIf'),
      NgSimpleToken.equalSign(11),
      NgSimpleQuoteToken.doubleQuotedText(12, '"some bool"', true),
      NgSimpleToken.tagEnd(23),
      NgSimpleToken.closeTagStart(24),
      NgSimpleToken.identifier(26, 'span'),
      NgSimpleToken.tagEnd(30),
      NgSimpleToken.EOF(31),
    ]);
  });

  test('should tokenize at signs', () {
    expect(tokenize('<div @deferred></div>'), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'div'),
      NgSimpleToken.whitespace(4, ' '),
      NgSimpleToken.atSign(5),
      NgSimpleToken.identifier(6, 'deferred'),
      NgSimpleToken.tagEnd(14),
      NgSimpleToken.closeTagStart(15),
      NgSimpleToken.identifier(17, 'div'),
      NgSimpleToken.tagEnd(20),
      NgSimpleToken.EOF(21),
    ]);
  });

  //Error cases

  test('should tokenize unclosed comments', () {
    expect(
        tokenize(''
            '<!--\n'
            '  Copyright (c) 2016, the Dart project authors.\n'),
        [
          NgSimpleToken.commentBegin(0),
          NgSimpleToken.text(
            4,
            '\n  Copyright (c) 2016, the Dart project authors.\n',
          ),
          NgSimpleToken.EOF(53),
        ]);
  });

  test('should tokenize unclosed element tag hitting EOF', () {
    expect(tokenize('<div '), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'div'),
      NgSimpleToken.whitespace(4, ' '),
      NgSimpleToken.EOF(5),
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
          NgSimpleToken.openTagStart(0),
          NgSimpleToken.identifier(1, 'div'),
          NgSimpleToken.tagEnd(4),
          NgSimpleToken.text(5, ' some text stuff here '),
          NgSimpleToken.openTagStart(27),
          NgSimpleToken.identifier(28, 'span'),
          NgSimpleToken.closeTagStart(32),
          NgSimpleToken.identifier(34, 'div'),
          NgSimpleToken.tagEnd(37),
          NgSimpleToken.EOF(38),
        ]);
  });

  test('should tokenize dangling double quote', () {
    expect(tokenize('''<div [someInput]=" (someEvent)='do something'>'''), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'div'),
      NgSimpleToken.whitespace(4, ' '),
      NgSimpleToken.openBracket(5),
      NgSimpleToken.identifier(6, 'someInput'),
      NgSimpleToken.closeBracket(15),
      NgSimpleToken.equalSign(16),
      NgSimpleQuoteToken.doubleQuotedText(
          17, '" (someEvent)=\'do something\'>', false),
      NgSimpleToken.EOF(46),
    ]);
  });

  test('should tokenize dangling single quote', () {
    expect(tokenize('''<div [someInput]=' (someEvent)="do something">'''), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'div'),
      NgSimpleToken.whitespace(4, ' '),
      NgSimpleToken.openBracket(5),
      NgSimpleToken.identifier(6, 'someInput'),
      NgSimpleToken.closeBracket(15),
      NgSimpleToken.equalSign(16),
      NgSimpleQuoteToken.singleQuotedText(
          17, "' (someEvent)=\"do something\">", false),
      NgSimpleToken.EOF(46),
    ]);
  });

  test('should tokenize unclosed attr hitting EOF', () {
    expect(tokenize('<div someAttr '), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'div'),
      NgSimpleToken.whitespace(4, ' '),
      NgSimpleToken.identifier(5, 'someAttr'),
      NgSimpleToken.whitespace(13, ' '),
      NgSimpleToken.EOF(14),
    ]);
  });

  test('should tokenize unclosed attr value hitting EOF', () {
    expect(tokenize('<div someAttr ='), [
      NgSimpleToken.openTagStart(0),
      NgSimpleToken.identifier(1, 'div'),
      NgSimpleToken.whitespace(4, ' '),
      NgSimpleToken.identifier(5, 'someAttr'),
      NgSimpleToken.whitespace(13, ' '),
      NgSimpleToken.equalSign(14),
      NgSimpleToken.EOF(15),
    ]);
  });

  test('should tokenize text beginning with dangling close mustache', () {
    expect(tokenize('}} some text'), [
      NgSimpleToken.mustacheEnd(0),
      NgSimpleToken.text(2, ' some text'),
      NgSimpleToken.EOF(12),
    ]);
  });

  test('should tokenize mustaches despite incorrect ordering', () {
    expect(tokenize('blah {{ blah {{ blah }} blah }} blah {{ blah }}'), [
      NgSimpleToken.text(0, 'blah '),
      NgSimpleToken.mustacheBegin(5),
      NgSimpleToken.text(7, ' blah '),
      NgSimpleToken.mustacheBegin(13),
      NgSimpleToken.text(15, ' blah '),
      NgSimpleToken.mustacheEnd(21),
      NgSimpleToken.text(23, ' blah '),
      NgSimpleToken.mustacheEnd(29),
      NgSimpleToken.text(31, ' blah '),
      NgSimpleToken.mustacheBegin(37),
      NgSimpleToken.text(39, ' blah '),
      NgSimpleToken.mustacheEnd(45),
      NgSimpleToken.EOF(47),
    ]);
  });

  test('should tokenize only up to newline with dangling open mustache', () {
    expect(tokenize('{{ some mustache \n unclosed'), [
      NgSimpleToken.mustacheBegin(0),
      NgSimpleToken.text(2, ' some mustache '),
      NgSimpleToken.whitespace(17, '\n'),
      NgSimpleToken.text(18, ' unclosed'),
      NgSimpleToken.EOF(27),
    ]);
  });

  test('should tokenize only up to newline with dangling open mustache2', () {
    expect(tokenize('{{\n  blah'), [
      NgSimpleToken.mustacheBegin(0),
      NgSimpleToken.whitespace(2, '\n'),
      NgSimpleToken.text(3, '  blah'),
      NgSimpleToken.EOF(9),
    ]);
  });

  test(
      'should tokenize "<" as expression within '
      'mustache if it begins with "{{"', () {
    expect(tokenize('{{ 5 < 3 }}'), [
      NgSimpleToken.mustacheBegin(0),
      NgSimpleToken.text(2, ' 5 < 3 '),
      NgSimpleToken.mustacheEnd(9),
      NgSimpleToken.EOF(11),
    ]);
  });

  test(
      'should tokenize "<" as tag start if '
      'before dangling mustache close', () {
    expect(tokenize(' 5 < 3 }}'), [
      NgSimpleToken.text(0, ' 5 '),
      NgSimpleToken.openTagStart(3),
      NgSimpleToken.whitespace(4, ' '),
      NgSimpleToken.unexpectedChar(5, '3'),
      NgSimpleToken.whitespace(6, ' '),
      NgSimpleToken.unexpectedChar(7, '}'),
      NgSimpleToken.unexpectedChar(8, '}'),
      NgSimpleToken.EOF(9),
    ]);
  });

  test('should tokenize simple doctype declaration', () {
    expect(tokenize('<!DOCTYPE html>'), [
      NgSimpleToken.text(0, '<!DOCTYPE html>'),
      NgSimpleToken.EOF(15),
    ]);
  });

  test('should tokenize complicated doctype declaration', () {
    var html = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"'
        ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';
    expect(tokenize(html), [
      NgSimpleToken.text(0, html),
      NgSimpleToken.EOF(109),
    ]);
  });

  test('should tokenize long html with doctype', () {
    const html = r'''
<!DOCTYPE html>
<div>
</div>''';
    expect(tokenize(html), [
      NgSimpleToken.text(0, '<!DOCTYPE html>'),
      NgSimpleToken.text(15, '\n'),
      NgSimpleToken.openTagStart(16),
      NgSimpleToken.identifier(17, 'div'),
      NgSimpleToken.tagEnd(20),
      NgSimpleToken.text(21, '\n'),
      NgSimpleToken.closeTagStart(22),
      NgSimpleToken.identifier(24, 'div'),
      NgSimpleToken.tagEnd(27),
      NgSimpleToken.EOF(28),
    ]);
  });

  test('should escape named entities', () {
    expect(tokenize('&lt;div&gt;'), [
      NgSimpleToken.text(0, '<div>'),
      NgSimpleToken.EOF(11),
    ]);
  });

  test('should escape dec values', () {
    expect(tokenize('&#8721;'), [
      NgSimpleToken.text(0, '∑'),
      NgSimpleToken.EOF(7),
    ]);
  });

  test('should escape hex values', () {
    expect(tokenize('&#x2211;'), [
      NgSimpleToken.text(0, '∑'),
      NgSimpleToken.EOF(8),
    ]);
  });
}
